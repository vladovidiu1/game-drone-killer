extends Node
const TECH := preload("res://scripts/core/weapon_technology.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func _ready() -> void:
 run.call_deferred()
func arena() -> Node2D:
 var battle := preload("res://scenes/gameplay.tscn").instantiate()
 add_child(battle)
 battle.set_physics_process(false)
 battle.spawner.timer = 10000
 return battle
func run() -> void:
 if "--verify-weapons" in OS.get_cmdline_user_args():
  check(SaveManager.state.weapon_schema == 1 and SaveManager.state.ammo_loadout == ["emp","cryo","railgun"],"Fresh process restores ordered three-slot advanced loadout")
  check(SaveManager.state.research.ammo_railgun == 3 and SaveManager.state.turret_specializations.machine_gun == "armor","Technology tiers and selected specialization survive process restart")
  var loaded := arena()
  check(loaded.player_turret.loadout == ["emp","cryo","railgun"] and loaded.player_turret.ammunition_profiles.railgun.penetration == 6,"Deployed weapon snapshots restored tiers")
  loaded.queue_free()
  await get_tree().process_frame
  finish()
  return
 SaveManager.new_campaign()
 var legacy: Dictionary = SaveManager.state.duplicate(true)
 legacy.erase("ammo_loadout")
 legacy.erase("weapon_schema")
 legacy.erase("turret_specializations")
 legacy.unlocks = ["armor_piercing","explosive"]
 legacy.equipped_ammo = "explosive"
 legacy.damage_level = 4
 legacy.research.cannon_damage = 2
 for version in [1,2,3]:
  legacy.version = version
  var migrated := SaveManager.validate_campaign(legacy)
  check(migrated.ammo_loadout == ["explosive","standard","armor_piercing"] and migrated.damage_level == 4 and migrated.research.cannon_damage == 2,"Legacy purchases/preference/research migrate without loss from v%d" % version)
 legacy.ammo_loadout = ["unknown",false,"railgun","standard","standard","armor_piercing","explosive"]
 legacy.turret_specializations = {"machine_gun":"unresearched","cannon":3}
 var cleaned := SaveManager.validate_campaign(legacy)
 check(cleaned.ammo_loadout == ["standard","armor_piercing","explosive"] and cleaned.turret_specializations.is_empty(),"Invalid/duplicate/locked entries are sanitized and loadout capped")
 SaveManager.state.credits = 100000
 check(not EconomyManager.purchase("emp",0),"EMP has a chapter gate")
 SaveManager.state.highest = 25
 check(not EconomyManager.purchase("emp",0) and not EconomyManager.purchase("railgun",0),"Research prerequisites block chapter-eligible technologies")
 check(EconomyManager.unlocked("standard") and SaveManager.catalog.projectile_technologies.standard.unlock_cost == 0,"Standard remains free and always available")
 for id in SaveManager.catalog.projectile_technologies:
  if id != "standard":
   check(EconomyManager.purchase(str(id),0),"Real atomic technology unlock: "+str(id))
  var previous := TECH.ammunition(str(id),SaveManager.state.research)
  for tier in 3:
   var before: int = SaveManager.state.credits
   check(EconomyManager.purchase("ammo_"+str(id),tier),"Purchase technology tier %d: %s" % [tier+1,id])
   check(SaveManager.state.credits == before-int(SaveManager.catalog.upgrades["ammo_"+str(id)].costs[tier]),"Tier purchase debits exact War Credits")
   var current := TECH.ammunition(str(id),SaveManager.state.research)
   check(current != previous and int(current.tier) == tier+1,"Every tier changes its role-specific real stats")
   check(not EconomyManager.purchase("ammo_"+str(id),tier),"Stale/double tier confirmation is inert")
   previous = current
  check(not EconomyManager.purchase("ammo_"+str(id),3),"Technology caps at three tiers")
 for id in ["laser","emp_tower","heavy_aa"]:
  check(EconomyManager.purchase(id,0),"Existing turret unlock retained")
 for kind in SaveManager.catalog.turret_specializations:
  for branch in SaveManager.catalog.turret_specializations[kind]:
   var id := str(SaveManager.catalog.turret_specializations[kind][branch].research)
   for tier in 3:
    check(EconomyManager.purchase(id,tier),"Branch tier purchase: "+id)
   check(EconomyManager.select_specialization(str(kind),str(branch)),"Equip one researched branch per design")
 # Explicit standard tuning must survive an upgrade to an already owned branch.
 SaveManager.state.research.spec_machine_gun_rapid = 1
 check(EconomyManager.select_specialization("machine_gun",""),"Standard tuning can be explicitly restored")
 check(EconomyManager.purchase("spec_machine_gun_rapid",1) and not SaveManager.state.turret_specializations.has("machine_gun"),"Improving an unequipped branch does not silently equip it")
 check(not EconomyManager.set_loadout(["standard","emp","cryo","railgun"]),"Fourth ammunition type is rejected")
 check(not EconomyManager.set_loadout([]) and not EconomyManager.set_loadout(["emp","emp"]),"Empty or duplicate loadouts rejected")
 check(EconomyManager.set_loadout(["railgun","standard","emp"]),"Any ordered set of three unlocked technologies can deploy")
 SaveManager.state.research.ammo_standard = 0
 SaveManager.state.research.spec_machine_gun_rapid = 0
 SaveManager.state.turret_specializations.erase("machine_gun")
 var snapshot := SaveManager.state.duplicate(true)
 DirAccess.make_dir_absolute(SaveManager.PATH+".tmp")
 check(not EconomyManager.purchase("ammo_standard",0) and SaveManager.state == snapshot,"Failed technology-tier write rolls back debit and grant")
 check(not EconomyManager.set_loadout(["standard"]) and SaveManager.state == snapshot,"Failed loadout write rolls back all fields")
 check(not EconomyManager.purchase("spec_machine_gun_rapid",0) and SaveManager.state == snapshot,"Failed first-branch write rolls back debit, tier and automatic selection")
 check(not EconomyManager.select_specialization("machine_gun","armor") and SaveManager.state == snapshot,"Failed branch write rolls back selected tuning")
 DirAccess.remove_absolute(SaveManager.PATH+".tmp")
 check(SaveManager.persist(),"Save recovers after write failure")
 var battle := arena()
 var cannon: Node2D = battle.player_turret
 cannon.ammo = 31
 cannon.cooldown = 1.2
 cannon.recoil = 4
 cannon.get_node("Artwork").art.heat = .7
 check(cannon.select_ammunition("standard") and cannon.ammo == 31 and cannon.cooldown >= 1.2 and cannon.recoil == 4 and cannon.get_node("Artwork").art.heat == .7,"Switching cannot refill, skip rail cooldown or reset heat/recoil")
 check(not cannon.select_ammunition("cryo"),"Unlocked but unequipped ammunition is unavailable in battle")
 check(cannon.request_reload(),"Shared magazine reload begins")
 var remaining: float = cannon.reload_remaining
 check(not cannon.select_ammunition("emp") and cannon.reload_remaining == remaining,"Switch cannot bypass or restart reload")
 battle.set_paused(true)
 battle.simulate(1)
 check(cannon.reload_remaining == remaining,"Pause freezes advanced ammunition reload")
 battle.set_paused(false)
 battle.simulate(remaining)
 check(cannon.ammo == 60,"Reload refills the shared 60-unit capacity exactly once")
 # A deployed profile does not read newly purchased tiers or loadout changes.
 var captured: Dictionary = cannon.ammunition_profiles.railgun.duplicate(true)
 SaveManager.state.research.ammo_railgun = 0
 check(cannon.ammunition_profiles.railgun == captured,"Research is snapshotted at deployment")
 battle.queue_free()
 await get_tree().process_frame
 # 6 technologies x 4 tier levels x all 14 archetypes; real swept impacts.
 for id in SaveManager.catalog.ammunition:
  for tier in 4:
   SaveManager.state.research = {}
   SaveManager.state.research["ammo_"+str(id)] = tier
   SaveManager.state.turret_specializations = {}
   SaveManager.state.ammo_loadout = [id]
   SaveManager.state.equipped_ammo = id
   for kind in CampaignManager.enemies:
    battle = arena()
    cannon = battle.player_turret
    cannon.definition.critical_chance = 1.0 if tier%2 == 1 else 0.0
    var enemy: Node2D = battle.spawn_enemy(str(kind))
    enemy.position = cannon.position+Vector2(0,-150)
    enemy.speed = 0
    var hp: float = enemy.health
    battle.launch_player_projectile(Vector2.UP)
    var shot: Node2D = battle.projectiles.get_child(0)
    var profile: Dictionary = cannon.ammunition().duplicate(true)
    check(shot.payload == profile and shot.visual_kind == id and shot.critical == (tier%2 == 1),"Snapshot tier/type/critical before flight")
    cannon.ammunition_type = str(id)
    shot.tick(.25)
    check(enemy.health < hp and battle.impacts == 1 and cannon.hits == 1,"Actual %s tier %d impacts %s exactly once" % [id,tier,kind])
    if id == "emp":
     var fireball := false
     for effect in battle.view.effects:
      fireball = fireball or effect.kind == "blast"
     check(not fireball,"EMP impact keeps electrical presentation without a high-explosive fireball")
    var after: float = enemy.health
    shot.impact()
    shot.tick(.1)
    check(enemy.health == after and battle.kills <= 1,"No repeated collider damage or duplicate reward")
    if id == "emp" and not enemy.ended:
     check(enemy.disable_remaining > 0 and enemy.disable_remaining <= float(profile.disable_duration),"EMP disruption applies with configured resistance")
     if enemy.brain.boss:
      check(is_equal_approx(enemy.disable_remaining,float(profile.disable_duration)*.25),"Boss EMP duration is reduced, never immune")
    if id == "cryo" and not enemy.ended:
     check(enemy.slow_remaining > 0 and enemy.slow_factor < 1 and enemy.slow_factor >= float(profile.slow_factor),"Cryo applies resisted speed control")
    battle.queue_free()
    await get_tree().process_frame
 # Trigger/magazine rules for every technology, including short partial loads.
 for id in SaveManager.catalog.ammunition:
  SaveManager.state.research = {}
  SaveManager.state.ammo_loadout = [id]
  SaveManager.state.equipped_ammo = id
  battle = arena()
  cannon = battle.player_turret
  var cost := int(cannon.ammunition().round_cost)
  cannon.ammo = cost
  battle.player_controls.set_fire(&"weapon-test",true)
  cannon.tick(.01)
  check(cannon.shots_fired == 1 and cannon.ammo == 0 and cannon.reload_remaining == 2.0,"Exactly one actual held shot consumes configured units and starts reload: "+str(id))
  cannon.tick(.5)
  check(cannon.shots_fired == 1 and cannon.ammo == 0,"Held trigger never fires through reload")
  battle.queue_free()
  await get_tree().process_frame
 # AP/shield/critical relationship, with hand-calculated baseline damage.
 for id in ["standard","armor_piercing"]:
  SaveManager.state.ammo_loadout = [id]
  SaveManager.state.equipped_ammo = id
  battle = arena()
  var shield: Node2D = battle.spawn_enemy("shield")
  shield.position = Vector2(600,450)
  var armored: Node2D = battle.spawn_enemy("heavy")
  armored.position = Vector2(560,450)
  battle.player_turret.definition.critical_chance = 1.0
  battle.launch_player_projectile(Vector2.UP)
  var round: Node2D = battle.projectiles.get_child(0)
  round.tick(.3)
  check(is_equal_approx(armored.health,291.9 if id == "standard" else 260.625),"Critical damage composes with armor/shield, AP bypasses both")
  battle.queue_free()
  await get_tree().process_frame
 # Penetration order, falloff, non-homing geometry, and per-target ownership.
 SaveManager.state.research = {}
 SaveManager.state.ammo_loadout = ["railgun","standard","emp"]
 SaveManager.state.equipped_ammo = "railgun"
 battle = arena()
 var targets: Array[Node2D] = []
 for y in [500,420,340,260]:
  var enemy: Node2D = battle.spawn_enemy("heavy")
  enemy.position = Vector2(560,y)
  targets.append(enemy)
 battle.launch_player_projectile(Vector2.UP)
 var rail: Node2D = battle.projectiles.get_child(0)
 rail.tick(.25)
 check(rail.consumed and rail.hit_ids.size() == 3 and targets[3].health == 300,"Rail penetrates three aligned targets, never the fourth")
 check(is_equal_approx(targets[0].health,216) and is_equal_approx(targets[1].health,300-84*.78) and is_equal_approx(targets[2].health,300-84*.78*.78),"Penetration damage falls deterministically per distinct impact")
 rail.tick(.5)
 check(battle.impacts == 3,"Consumed rail cannot reapply any hit")
 battle.queue_free()
 await get_tree().process_frame
 # Personal shield resistance and partial anti-shield tuning are configurable.
 SaveManager.state.equipped_ammo = "standard"
 SaveManager.state.ammo_loadout = ["standard"]
 battle = arena()
 var shielded: Node2D = battle.spawn_enemy("assault")
 shielded.resistances.shield = .4
 shielded.hit(10,false,false,Vector2.INF,{"shield_bypass":.5})
 check(is_equal_approx(shielded.health,92),"Partial shield bypass composes with configurable personal shield resistance")
 shielded.apply_slow(.5,2)
 shielded.apply_disable(.5)
 var position_before: Vector2 = shielded.position
 shielded.tick(.5)
 check(shielded.position == position_before and shielded.slow_remaining > 0,"EMP and Cryo coexist; disable expires without clearing slow")
 var distance_before: float = shielded.distance_remaining
 shielded.tick(.5)
 check(is_equal_approx(distance_before-shielded.distance_remaining,shielded.speed*.25),"Cryo resumes correct slowed movement after electronic disable")
 battle.queue_free()
 await get_tree().process_frame
 await test_specializations()
 # Persist advanced content for the runner's fresh-process verification.
 SaveManager.new_campaign()
 SaveManager.state.highest = 25
 SaveManager.state.unlocks = ["emp","cryo","railgun"]
 SaveManager.state.research.ammo_railgun = 3
 SaveManager.state.research.spec_machine_gun_armor = 2
 SaveManager.state.turret_specializations.machine_gun = "armor"
 check(EconomyManager.set_loadout(["emp","cryo","railgun"]),"Advanced loadout transaction persists")
 finish()

func test_specializations() -> void:
 SaveManager.state.unlocks = ["laser","emp_tower","heavy_aa","emp","cryo","railgun"]
 for kind in SaveManager.catalog.turret_specializations:
  for branch in SaveManager.catalog.turret_specializations[kind]:
   var data: Dictionary = SaveManager.catalog.turret_specializations[kind][branch]
   SaveManager.state.research[str(data.research)] = 3
   SaveManager.state.turret_specializations = {kind:branch}
   var battle := arena()
   battle.credits = 10000
   battle.select_slot(0)
   check(battle.build_turret(str(kind)),"Actual specialized turret purchases successfully")
   var gun: Node2D = battle.placed[0]
   check(gun.definition.get("specialization") == branch and gun.definition != CampaignManager.turrets[kind],"Only selected branch changes deployed definition")
   var enemy: Node2D = battle.spawn_enemy("heavy")
   enemy.position = gun.position+Vector2(0,-100)
   enemy.speed = 0
   var hp: float = enemy.health
   for frame in 50:
    gun.tick(1.0/60)
    for shot in battle.projectiles.get_children():
     shot.tick(1.0/60)
   check(gun.shots_fired > 0,"Every branch tracks and actually fires")
   if kind == "emp_tower":
    check(enemy.slow_remaining > 0,"Specialized EMP still controls real enemies")
    if branch == "duration":
     check(enemy.disable_remaining > 0,"Disruption branch actually disables electronics")
   else:
    check(enemy.health < hp,"Specialized damage reaches a real enemy")
   battle.queue_free()
   await get_tree().process_frame

func finish() -> void:
 print("WEAPON RESEARCH: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
