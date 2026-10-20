extends Node
const BATTLE := preload("res://scenes/gameplay.tscn")
var checks := 0
var failures := 0
var app: Control

func check(value: bool, message: String) -> void:
 checks += 1
 if value:
  print("PASS: "+message)
 else:
  failures += 1
  push_error("FAIL: "+message)

func arena() -> Node2D:
 var battle = BATTLE.instantiate()
 add_child(battle)
 battle.set_physics_process(false)
 battle.spawner.timer = 10000
 return battle

func _ready() -> void:
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 run.call_deferred()

func run() -> void:
 if "--verify-research" in OS.get_cmdline_user_args():
  check(SaveManager.state.version == 3 and SaveManager.state.research.magazine == 5,"schema v3 and research survive fresh process")
  check(EconomyManager.unlocked("laser") and EconomyManager.unlocked("explosive"),"unlocks survive fresh process")
  check(SaveManager.state.equipped_ammo == "armor_piercing","equipped ammunition survives fresh process")
  var restored := arena()
  check(restored.player_turret.ammo == 110 and restored.max_health == 1500,"restored research is applied before combat begins")
  restored.queue_free()
  await get_tree().process_frame
  finish()
  return
 SaveManager.new_campaign()
 check(not EconomyManager.purchase("cannon_damage",0) and SaveManager.state.credits == 0,"insufficient War Credits cannot buy research")
 SaveManager.state.credits = 20000
 SaveManager.persist()
 check(not EconomyManager.purchase("laser",0),"weapon research enforces highest-mission requirement")
 var balance: int = SaveManager.state.credits
 check(EconomyManager.purchase("cannon_damage",0),"War Credits buy first permanent research level")
 check(SaveManager.state.credits == balance-60 and SaveManager.state.research.cannon_damage == 1,"research deducts exact configurable cost")
 balance = SaveManager.state.credits
 check(not EconomyManager.purchase("cannon_damage",0) and SaveManager.state.credits == balance,"duplicate purchase callback with stale level cannot charge again")
 check(EconomyManager.purchase_state("cannon_damage").cost == 100,"next research level has escalating cost")
 SaveManager.state.highest = 3
 SaveManager.persist()
 for id in SaveManager.catalog.upgrades:
  for level in range(EconomyManager.research_level(id),5):
   check(EconomyManager.purchase(id,level),"purchase %s level %d" % [id,level+1])
  check(not EconomyManager.purchase(id,5),"%s cannot exceed five levels" % id)
 # Prices are intentionally meaningful: refill the fixture bank only between test categories.
 SaveManager.state.credits = 10000
 SaveManager.persist()
 for id in SaveManager.catalog.unlocks:
  check(EconomyManager.purchase(id,0),"research unlocks "+id)
  balance = SaveManager.state.credits
  check(not EconomyManager.purchase(id,0) and SaveManager.state.credits == balance,"unlock cannot be purchased twice: "+id)
 var stats := EconomyManager.primary_stats()
 check(is_equal_approx(float(stats.damage),18.75),"five damage levels add 25% to existing primary damage")
 check(is_equal_approx(float(stats.fire_rate),7.2),"five fire-rate levels add 20%")
 check(stats.magazine_size == 110 and is_equal_approx(float(stats.reload_time),1.4),"capacity and reload research yield 110 rounds and 1.4 seconds")
 check(is_equal_approx(float(stats.projectile_speed),1062.5),"velocity research yields +25%")
 check(is_equal_approx(float(stats.critical_chance),0.1) and is_equal_approx(float(stats.critical_multiplier),2),"critical research yields 10% chance and 2x critical damage")
 var battle := arena()
 var gun: Node2D = battle.player_turret
 check(battle.max_health == 1500 and battle.credits == 750,"base health and starting Battle Credits are researched")
 check(gun.ammo == 110 and is_equal_approx(float(gun.definition.reload_time),1.4),"primary loads actual researched stats before first tick")
 battle.select_slot(0)
 battle.build_turret("machine_gun")
 var turret: Node2D = battle.placed[0]
 check(is_equal_approx(turret.damage_value(),12.5) and is_equal_approx(turret.range_value(),276) and is_equal_approx(turret.fire_rate_value(),4.8),"automatic damage, range and fire rate research affects actual turret")
 check(battle.credits == 650,"building spends only Battle Credits")
 balance = SaveManager.state.credits
 battle.health = 500
 check(battle.abilities.activate("repair") and battle.health == 812,"repair efficiency research increases real healed HP")
 check(battle.credits == 560 and SaveManager.state.credits == balance,"tactical advantage spends Battle Credits, preserving War Credits")
 check(not battle.abilities.activate("repair") and battle.health == 812,"duplicate repair activation cannot heal or charge twice")
 check(is_equal_approx(float(battle.abilities.cooldowns.repair),24),"ability mastery reduces actual cooldown")
 var enemy: Node2D = battle.spawn_enemy("assault")
 enemy.position = Vector2(560,400)
 check(battle.abilities.activate("emp_blast") and enemy.disable_remaining == 2.5,"EMP Blast disables live drones")
 check(is_equal_approx(float(battle.abilities.cooldowns.emp_blast),36),"EMP mastery reduces its cooldown to 36 seconds")
 var before: Vector2 = enemy.position
 enemy.tick(1)
 check(enemy.position == before,"disabled enemy cannot move")
 enemy.tick(2)
 check(enemy.position != before and enemy.disable_remaining == 0,"disabled enemy recovers with exact remaining movement time")
 var old_rate: float = gun.fire_rate_value()
 check(battle.abilities.activate("overclock") and is_equal_approx(gun.fire_rate_value(),old_rate*1.5) and is_equal_approx(turret.fire_rate_value(),7.2),"Overclock boosts primary and automatic firing rates together")
 check(is_equal_approx(float(battle.abilities.cooldowns.overclock),32),"Overclock mastery reduces its cooldown to 32 seconds")
 battle.set_paused(true)
 var clock: float = battle.abilities.overclock_remaining
 var cooldown: float = battle.abilities.cooldowns.emp_blast
 battle.simulate(2)
 check(battle.abilities.overclock_remaining == clock and battle.abilities.cooldowns.emp_blast == cooldown,"pause freezes ability duration and cooldown")
 check(not battle.abilities.activate("repair"),"paused battle rejects tactical activation")
 battle.set_paused(false)
 battle.abilities.tick(6)
 check(battle.abilities.overclock_remaining == 0 and is_equal_approx(gun.fire_rate_value(),old_rate),"Overclock expires and restores normal firing rates")
 # Tactical mode must be fixed at 25% normal and restore the existing 2x choice.
 battle.game_speed = 2
 battle.select_slot(0)
 check(battle.build_mode and battle.effective_speed() == 0.25,"opening a build/upgrade panel enters 0.25x")
 var timer: float = battle.spawner.timer
 var moving: Node2D = battle.spawn_enemy("scout")
 var remaining_distance: float = moving.distance_remaining
 battle.launch_player_projectile(Vector2.RIGHT)
 var slow_bullet: Node2D = battle.projectiles.get_child(battle.projectiles.get_child_count()-1)
 var bullet_origin: Vector2 = slow_bullet.position
 var ability_clock: float = battle.abilities.cooldowns.repair
 battle._physics_process(1)
 check(is_equal_approx(remaining_distance-moving.distance_remaining,30) and is_equal_approx(slow_bullet.position.distance_to(bullet_origin),float(gun.definition.projectile_speed)*0.25),"enemies and projectiles share tactical 0.25x time")
 check(is_equal_approx(ability_clock-battle.abilities.cooldowns.repair,0.25),"ability cooldowns share tactical 0.25x time")
 check(is_equal_approx(timer-battle.spawner.timer,0.25),"wave scheduler consumes tactical slow-motion time")
 battle.select_slot(1)
 check(battle.build_mode and battle.game_speed == 2,"selecting another slot reuses the same tactical mode")
 battle.close_build_mode()
 check(not battle.build_mode and battle.effective_speed() == 2,"closing tactical mode restores previous 2x speed")
 battle.select_slot(0)
 battle.set_paused(true)
 battle.set_paused(false)
 check(not battle.build_mode and battle.effective_speed() == 2,"pause/resume cannot leave tactical slow motion stuck")
 battle.queue_free()
 await get_tree().process_frame

 battle = arena()
 gun = battle.player_turret
 gun.ammo = 37
 check(gun.select_ammunition("armor_piercing") and gun.ammo == 37,"ammo switching preserves rounds instead of refilling")
 check(is_equal_approx(gun.fire_rate_value(),5.4),"armor-piercing ammunition pays the 25% fire-rate penalty")
 var armored: Node2D = battle.spawn_enemy("heavy")
 var scout: Node2D = battle.spawn_enemy("scout")
 armored.position = gun.position+Vector2(0,-100)
 scout.position = gun.position+Vector2(100,-100)
 battle.launch_player_projectile(Vector2.UP)
 var shot: Node2D = battle.projectiles.get_child(0)
 check(is_equal_approx(shot.damage_for(armored),shot.damage*1.75) and is_equal_approx(shot.damage_for(scout),shot.damage),"AP damage bonus applies only against armored drones")
 shot.tick(0.2)
 check(armored.health < 300,"armor-piercing projectile collides and damages armored target")
 check(gun.select_ammunition("explosive") and gun.ammo == 37,"switching to explosive ammo does not create rounds")
 armored.position = gun.position+Vector2(0,-100)
 scout.position = armored.position+Vector2(20,0)
 var hp: float = armored.health
 gun.cooldown = 0
 gun.barrel_angle = -PI/2
 gun.set_aim(gun.position+Vector2(0,-200))
 gun.set_trigger(true)
 gun.tick(0.01)
 shot = battle.projectiles.get_child(battle.projectiles.get_child_count()-1)
 shot.tick(0.2)
 check(gun.ammo == 34 and shot.splash_radius == 45,"explosive shot spends three rounds and carries configured splash")
 check(armored.health < hp and scout.health < 40,"explosive manual shot damages both nearby drones")
 hp = armored.health
 shot.impact()
 check(armored.health == hp,"explosive impact cannot deal area damage twice")
 gun.set_trigger(false)
 check(gun.request_reload() and not gun.select_ammunition("standard"),"ammo changes are blocked during reload")
 var reload_time: float = gun.reload_remaining
 gun.tick(reload_time)
 check(gun.ammo == 110,"researched magazine refills after reload")
 # Deterministic RNG fixture: real shots roll crit chance; every critical carries the bonus.
 gun.select_ammunition("standard")
 gun.rng.seed = 42
 var criticals := 0
 for i in 100:
  battle.launch_player_projectile(Vector2.LEFT)
  shot = battle.projectiles.get_child(battle.projectiles.get_child_count()-1)
  if shot.critical:
   criticals += 1
   check(is_equal_approx(shot.damage,gun.damage_value()*2),"critical projectile carries researched damage multiplier")
 check(criticals > 0 and criticals < 100,"critical chance affects actual shots without making all shots critical")
 battle.queue_free()
 await get_tree().process_frame

 battle = arena()
 battle.credits = 2000
 battle.select_slot(0)
 check(battle.build_turret("laser"),"researched Laser can be built")
 turret = battle.placed[0]
 enemy = battle.spawn_enemy("heavy")
 enemy.position = turret.position+Vector2(0,-100)
 hp = enemy.health
 turret.tick(0.5)
 check(enemy.health < hp and battle.projectiles.get_child_count() == 0,"Laser applies continuous accurate damage without projectile misses")
 battle.select_slot(1)
 check(battle.build_turret("emp_tower"),"researched EMP Tower can be built")
 var emp: Node2D = battle.placed[1]
 var slowed: Node2D = battle.spawn_enemy("scout")
 slowed.position = emp.position+Vector2(0,-100)
 emp.tick(0.1)
 var remaining: float = slowed.distance_remaining
 slowed.tick(0.5)
 check(is_equal_approx(remaining-slowed.distance_remaining,21),"EMP Tower area pulse slows Scout movement to 35%")
 battle.select_slot(2)
 check(battle.build_turret("heavy_aa"),"researched Heavy AA Cannon can be built")
 var heavy: Node2D = battle.placed[2]
 enemy.position = heavy.position+Vector2(0,-80)
 hp = enemy.health
 heavy.tick(0.1)
 shot = battle.projectiles.get_child(0)
 shot.tick(0.2)
 check(enemy.health < hp and heavy.damage_value() == 225,"Heavy AA deals high researched damage through a real projectile")
 battle.queue_free()
 await get_tree().process_frame

 # Mission objectives are part of the original single-result transaction.
 SaveManager.new_campaign()
 SaveManager.state.wins = 4
 SaveManager.persist()
 var token := CampaignManager.begin_mission(1)
 var outcome := CampaignManager.resolve(true,1,token)
 check(outcome.objective_reward == 150 and SaveManager.state.credits == 270,"fifth victory grants one persistent Veteran objective reward")
 check(CampaignManager.resolve(true,1,token).is_empty() and SaveManager.state.credits == 270,"duplicate result cannot re-award the mission or objective")
 SaveManager.reload_from_disk()
 check(SaveManager.state.claimed_objectives.has("veteran"),"objective claim survives reload")
 var legacy := SaveManager.validate_campaign({"version":2,"frontline":3,"highest":3,"credits":456,"damage_level":4,"checkpoints":[1],"records":{"2":{"victories":2}},"wins":3})
 check(legacy.version == 3 and legacy.credits == 456 and legacy.damage_level == 4 and legacy.records["2"].victories == 2,"schema v2 migration preserves money, legacy bonuses and campaign records")
 check(legacy.unlocks.is_empty() and legacy.research.magazine == 0,"old saves gain zero new research without losing existing bonuses")
 SaveManager.state = legacy
 SaveManager.state.credits = 10000
 SaveManager.persist()
 for id in SaveManager.catalog.upgrades:
  SaveManager.state.research[id] = 5
 for id in SaveManager.catalog.unlocks:
  SaveManager.state.unlocks.append(id)
 SaveManager.state.damage_level = 0
 SaveManager.state.equipped_ammo = "armor_piercing"
 SaveManager.persist()
 var retained := SaveManager.state.duplicate(true)
 token = CampaignManager.begin_mission(3)
 CampaignManager.resolve(false,3,token)
 check(SaveManager.state.frontline == 2 and SaveManager.state.research == retained.research and SaveManager.state.unlocks == retained.unlocks and SaveManager.state.credits == retained.credits,"all research, unlocks and War Credits survive defeat and territory regression")
 # Save failure cannot grant research for free or consume currency.
 retained = SaveManager.state.duplicate(true)
 SaveManager.state.research.cannon_damage = 0
 SaveManager.persist()
 retained = SaveManager.state.duplicate(true)
 DirAccess.make_dir_absolute(SaveManager.PATH+".tmp")
 check(not EconomyManager.purchase("cannon_damage",0) and SaveManager.state == retained,"failed research save rolls back level and War Credits")
 DirAccess.remove_absolute(SaveManager.PATH+".tmp")
 SaveManager.state.research.cannon_damage = 5
 SaveManager.persist()
 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 await get_tree().process_frame
 app._arsenal()
 await get_tree().process_frame
 var arsenal: Control = app.content.get_child(0)
 check(arsenal.current_tab == "primary","Arsenal opens on PRIMARY CANNON")
 for tab in ["automatic","research","abilities","primary"]:
  arsenal.select_tab(tab)
  await get_tree().process_frame
  check(arsenal.current_tab == tab and arsenal.body.get_child_count() > 0,"Arsenal tab renders actual data: "+tab)
 # Review and confirm a real research purchase; duplicate confirmations stay inert.
 SaveManager.state.research.cannon_damage = 0
 SaveManager.persist()
 arsenal.refresh()
 var reviewed_balance: int = SaveManager.state.credits
 arsenal.confirm("cannon_damage",0)
 var confirmation: ConfirmationDialog
 for child in arsenal.get_children():
  if child is ConfirmationDialog:
   confirmation = child
 check(confirmation != null and arsenal.pending,"Arsenal requires a concrete purchase confirmation")
 confirmation.confirmed.emit()
 confirmation.confirmed.emit()
 check(SaveManager.state.research.cannon_damage == 1 and SaveManager.state.credits == reviewed_balance-60,"confirming twice buys and charges only one research level")
 await get_tree().process_frame
 SaveManager.state.research.cannon_damage = 5
 SaveManager.persist()
 app._play(1)
 await get_tree().process_frame
 var live: Node2D = app.battle
 live.set_physics_process(false)
 check(live.player_turret.ammo == 110 and live.health == 1500,"mission restart applies persistent researched stats")
 var visible := get_viewport().get_visible_rect()
 check(visible.encloses(app.hud.player_panel.fire_button.get_global_rect()) and visible.encloses(app.hud.ability_buttons.repair.get_global_rect()),"expanded FIRE and ability controls fit reference layout")
 live.health = 1400
 live.status_changed.emit()
 var start_bank: int = live.credits
 var repair_center: Vector2 = app.hud.ability_buttons.repair.get_global_rect().get_center()
 for index in [50,51]:
  var finger := InputEventScreenTouch.new()
  finger.index = index
  finger.position = repair_center
  finger.pressed = true
  get_viewport().push_input(finger,true)
  finger.pressed = false
  get_viewport().push_input(finger,true)
 check(live.health == 1500 and live.credits == start_bank-90,"two rapid touch repair taps activate and charge once")
 live.select_slot(0)
 await get_tree().process_frame
 var shop_button: Button = app.hud.build_buttons.machine_gun
 var scroll_finger := InputEventScreenTouch.new()
 scroll_finger.index = 52
 scroll_finger.position = shop_button.get_global_rect().get_center()
 scroll_finger.pressed = true
 get_viewport().push_input(scroll_finger,true)
 var swipe := InputEventScreenDrag.new()
 swipe.index = 52
 swipe.position = scroll_finger.position+Vector2(0,-100)
 swipe.relative = Vector2(0,-100)
 get_viewport().push_input(swipe,true)
 scroll_finger.position = swipe.position
 scroll_finger.pressed = false
 get_viewport().push_input(scroll_finger,true)
 await get_tree().process_frame
 check(app.hud.shop_scroll.scroll_vertical > 0 and live.placed[0] == null,"touch swipe scrolls build designs without buying a turret")
 app.hud.close_button.pressed.emit()
 check(not live.build_mode and live.effective_speed() == 1,"Close button restores normal combat speed")
 app.queue_free()
 await get_tree().process_frame
 finish()

func finish() -> void:
 print("RESEARCH: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
