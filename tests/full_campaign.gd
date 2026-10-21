extends Node
# Deterministic assisted-play simulation. Uses real purchases, shots, movement and results.
# It establishes reachability/economy, not human difficulty or Android performance.
var failures := 0
var checks := 0
var rows: Array = []
var battle: Node2D
var outcome: Dictionary = {}
var deployments: Dictionary = {}

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("FAIL: "+message)

func _ready() -> void:
 run.call_deferred()

func purchase_research() -> void:
 # Spend earned WC on deployed weapons rather than buying unused unlocks.
 for unlock in ["armor_piercing"]:
  if EconomyManager.purchase_state(unlock).allowed:
   EconomyManager.purchase(unlock,0)
 for level in range(5):
  for key in ["turret_damage","turret_range","cannon_damage","cannon_rate","reload","starting_credits","base_health","turret_rate"]:
   if EconomyManager.research_level(key) == level and EconomyManager.purchase_state(key).allowed:
    EconomyManager.purchase(key,level)
 if EconomyManager.unlocked("armor_piercing"):
  EconomyManager.equip_ammunition("armor_piercing")

func build_defenses() -> void:
 var reserve := int(SaveManager.catalog.abilities.repair.cost) if battle.health < battle.max_health else 0
 for index in battle.slots.size():
  if battle.placed[index] == null:
   var kind := "missile" if index%3 == 2 else "machine_gun" if index < 2 else "cannon"
   if battle.credits-int(CampaignManager.turrets[kind].cost) >= reserve:
    battle.select_slot(index)
    battle.build_turret(kind)
 for index in battle.slots.size():
  if battle.placed[index] != null and battle.credits-battle.placed[index].upgrade_cost() >= reserve:
   battle.select_slot(index)
   battle.upgrade_selected()
 battle.close_build_mode()

func aim() -> void:
 var selected: Node2D = null
 var priority := -INF
 for enemy in battle.drones.get_children():
  if enemy.ended or enemy.position.distance_to(battle.player_turret.position) > 395:
   continue
  var score: float = 1000-enemy.distance_remaining
  if enemy.brain.boss:
   score += 700
  elif enemy.brain.charging:
   score += 450
  elif enemy.brain.data.has("aura_radius"):
   score += 350
  if score > priority:
   selected = enemy
   priority = score
 if selected != null:
  # Counter the visible target rather than spending AP's slower fire on scouts.
  if battle.player_turret.reload_remaining <= 0:
   var armored: bool = selected.armored or selected.brain.boss
   var desired := "armor_piercing" if armored and EconomyManager.unlocked("armor_piercing") else "standard"
   if battle.player_turret.ammunition_type != desired:
    battle.player_turret.select_ammunition(desired)
  var point: Vector2 = selected.brain.weakpoint() if selected.brain.boss else selected.position
  if not selected.brain.boss and selected.waypoint < selected.route.size():
   point += selected.position.direction_to(selected.route[selected.waypoint])*selected.speed*selected.position.distance_to(battle.player_turret.position)/850.0
  battle.player_controls.aim_at(point)
 battle.player_controls.set_fire(&"simulation",selected != null)

func fight(id: int, defend: bool, manual: bool = true, expected_win: int = -1, build_enabled: bool = true) -> void:
 outcome = {}
 battle = preload("res://scenes/gameplay.tscn").instantiate()
 battle.mission_id = id
 battle.attack_seed = 1000+id+100*int(deployments.get(id,0))
 deployments[id] = int(deployments.get(id,0))+1
 battle.run_id = CampaignManager.begin_mission(id)
 check(not battle.run_id.is_empty(),"deployment token for %d" % id)
 add_child(battle)
 battle.set_physics_process(false)
 battle.player_turret.rng.seed = battle.attack_seed
 battle.completed.connect(func(_victory: bool, stats: Dictionary): outcome = stats)
 if defend and build_enabled:
  build_defenses()
 # Wait normal intermissions: durations include the preparation offered to humans.
 for frame in range(60*600):
  if battle.finished:
   break
  if defend and frame%60 == 0:
   if battle.health <= battle.max_health-250:
    battle.abilities.activate("repair")
   if build_enabled:
    build_defenses()
   if manual and battle.living_count() >= 8 and battle.credits >= int(SaveManager.catalog.abilities.emp_blast.cost)+int(SaveManager.catalog.abilities.repair.cost):
    battle.abilities.activate("emp_blast")
   if manual and battle.living_count() >= 10 and battle.credits >= int(SaveManager.catalog.abilities.overclock.cost)+int(SaveManager.catalog.abilities.repair.cost):
    battle.abilities.activate("overclock")
  if defend and manual:
   aim()
  if battle.spawner.wave < 0 and battle.spawner.timer <= 0 and battle.spawner.warning_remaining <= 0:
   battle.start_wave()
  battle.simulate(1.0/60.0)
  if frame%8 == 0:
   await get_tree().process_frame
 check(battle.finished,"mission %d terminates within ten simulated minutes" % id)
 var expected := defend if expected_win < 0 else bool(expected_win)
 if expected_win != -2:
  check(bool(outcome.get("victory",false)) == expected,"mission %d expected %s" % [id,"victory" if expected else "defeat"])
 else:
  check(not outcome.is_empty() and bool(outcome.victory) == (battle.health > 0),"mission %d outcome agrees with real base state" % id)
 if defend and bool(outcome.get("victory",false)):
  check(battle.earned > 0 and battle.credits >= 0,"mission %d real bounty economy" % id)
  if not manual:
   check(battle.player_turret.shots_fired == 0,"primary stays silent without input")
  if battle.mission_data.has("boss"):
   check(battle.weakpoint_hits > 0,"mission %d boss weakpoint was actually hit" % id)
   check(battle.enemy_actions > 0,"mission %d boss uses live abilities" % id)
 var row := {"id":id,"mode":"hybrid" if defend and manual and build_enabled else "manual_only" if defend and manual else "automatic" if defend else "undefended","victory":outcome.get("victory",false),"seconds":snappedf(battle.elapsed,.1),"health":battle.health,"kills":battle.kills,"battle_earned":battle.earned,"manual_shots":battle.player_turret.shots_fired,"manual_hits":battle.player_turret.hits,"weakpoint_hits":battle.weakpoint_hits,"component_hits":battle.component_hits,"component_destructions":battle.component_destructions,"enemy_actions":battle.enemy_actions,"support_spawned":battle.support_spawned,"environmental_pulses":battle.environmental_pulses,"research":battle.research_levels.duplicate(),"war_balance":SaveManager.state.credits}
 var resolved := CampaignManager.resolve(bool(outcome.get("victory",false)),id,battle.run_id,outcome)
 row.attack_seed = battle.attack_seed
 row.tactical_plans = battle.director.plans.duplicate(true)
 for plan in row.tactical_plans:
  plan.entry_fingerprint = JSON.stringify(plan.entries).sha256_text()
  plan.erase("entries")
 row.starting_battle_credits = int(battle.mission_data.starting_credits)+int(EconomyManager.modifier("starting_credits",battle.research_levels))
 row.battle_remaining = battle.credits
 row.battle_spent = row.starting_battle_credits+battle.earned-battle.credits
 row.war_reward = int(resolved.get("reward",0))
 row.war_balance_after = int(SaveManager.state.credits)
 rows.append(row)
 var summary: Dictionary = row.duplicate()
 summary.erase("tactical_plans")
 print("BALANCE: "+JSON.stringify(summary))
 check(not resolved.is_empty(),"mission %d result persisted" % id)
 check(CampaignManager.resolve(true,id,battle.run_id,outcome).is_empty(),"mission %d duplicate result rejected" % id)
 battle.queue_free()
 await get_tree().process_frame

func has_text(node: Node, value: String) -> bool:
 if (node is Label or node is Button) and value in node.text:
  return true
 for child in node.get_children():
  if has_text(child,value):
   return true
 return false

func run() -> void:
 if "--compare" in OS.get_cmdline_user_args():
  var snapshot: Dictionary = SaveManager.state.duplicate(true)
  check(bool(snapshot.get("campaign_complete",false)),"Comparison uses earned endgame research")
  await fight(25,true,false,0)
  SaveManager.state = snapshot.duplicate(true)
  SaveManager.persist()
  await fight(25,true,true,0,false)
  SaveManager.state = snapshot
  SaveManager.persist()
  var report := FileAccess.open("user://campaign_comparison.json",FileAccess.WRITE)
  report.store_string(JSON.stringify(rows,"  "))
  finish()
  return
 if "--verify-full" in OS.get_cmdline_user_args():
  check(SaveManager.state.frontline == 25 and SaveManager.state.campaign_complete,"final liberation survives fresh process")
  check(CampaignManager.territory_state(25) == "CONTROLLED","final territory controlled")
  check(SaveManager.state.checkpoints == [1,5,10,15,20],"all permanent checkpoint floors persisted")
  var app := preload("res://scenes/main.tscn").instantiate()
  add_child(app)
  await get_tree().process_frame
  app._show_results(true,int(SaveManager.state.last_result.reward),{"campaign":SaveManager.state.last_result,"kills":200,"health":1000,"earned":3000})
  await get_tree().process_frame
  check(app.screen == "results" and has_text(app,"ASTERIA LIBERATED"),"Saved final result presents the liberation ending")
  check(has_text(app,"CAMPAIGN COMPLETE") and has_text(app,"Replay The Hive Core"),"Ending keeps final mission replay available")
  app._map()
  await get_tree().process_frame
  check(app.screen == "map" and has_text(app,"25  The Hive Core"),"Ending returns to the full campaign map")
  app.queue_free()
  await get_tree().process_frame
  for id in range(1,26):
   check(SaveManager.state.records.has(str(id)) and int(SaveManager.state.records[str(id)].victories) >= 1,"mission %d victory persisted" % id)
  finish()
  return
 check(SaveManager.new_campaign(),"start clean campaign")
 # A tactical campaign may include real losses. Follow the persisted frontline,
 # retain strict completion/checkpoint/boss/save assertions, and bound recovery.
 for attempt in range(60):
  if SaveManager.state.campaign_complete or failures > 0:
   break
  purchase_research()
  await fight(int(SaveManager.state.frontline),true,true,-2)
 check(SaveManager.state.campaign_complete and CampaignManager.territory_state(25) == "CONTROLLED","Hive campaign reachable within 60 real earned-budget deployments")
 if failures == 0:
  check(SaveManager.state.checkpoints == [1,5,10,15,20],"all five chapters interconnected through real combat")
  var retained: Dictionary = SaveManager.state.research.duplicate(true)
  await fight(25,false)
  check(SaveManager.state.frontline == 24 and not SaveManager.state.campaign_complete,"final replay defeat returns territory 24 to contest")
  check(SaveManager.state.research == retained,"late-campaign defeat retains permanent research")
  for recovery in range(16):
   if SaveManager.state.campaign_complete or failures > 0:
    break
   purchase_research()
   await fight(int(SaveManager.state.frontline),true,true,-2)
  check(SaveManager.state.campaign_complete,"final territories reconquered within 16 real recovery deployments")
 for id in range(1,26):
  check(SaveManager.state.records.has(str(id)) and int(SaveManager.state.records[str(id)].victories) >= 1,"mission %d has a real persisted victory" % id)
 var file := FileAccess.open("user://campaign_balance.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(rows,"  "))
 print("BALANCE_REPORT: "+ProjectSettings.globalize_path("user://campaign_balance.json"))
 finish()

func finish() -> void:
 print("FULL CAMPAIGN: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
