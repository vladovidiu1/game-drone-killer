extends Node
# Actual runtime actors/projectiles, deterministic isolated funds/research fixtures.
const BATTLE := preload("res://scenes/gameplay.tscn")
const PROJECTILE := preload("res://scenes/projectile.tscn")
var checks := 0
var failures := 0
var records: Array = []

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("COMPONENTS: "+message)

func _ready() -> void:
 run.call_deferred()

func arena(mission: int = 20) -> Node2D:
 var battle := BATTLE.instantiate()
 battle.mission_id = mission
 battle.attack_seed = 707
 add_child(battle)
 battle.set_physics_process(false)
 return battle

func unit(battle: Node2D, kind: String = "heavy") -> Node2D:
 var enemy: Node2D = battle.spawn_enemy(kind)
 enemy.position = Vector2(560,360)
 enemy.speed = 0
 return enemy

func fire_at(battle: Node2D, part: Node2D, amount: float = 10) -> Node2D:
 var shot := PROJECTILE.instantiate()
 shot.configure_manual(battle,Vector2.UP)
 shot.position = part.point()+Vector2(0,20)
 shot.direction = Vector2.UP
 shot.damage = amount
 shot.splash_radius = 0
 shot.armor_multiplier = 1
 shot.payload = {}
 shot.penetration_remaining = 1
 shot.range_remaining = 45
 battle.projectiles.add_child(shot)
 shot.tick(.1)
 return shot

func run() -> void:
 SaveManager.new_campaign()
 var persistent := SaveManager.state.duplicate(true)
 await progression_and_geometry()
 await damage_routes()
 await precision_feedback_contract()
 await consequences()
 await ammo_matrix()
 check(SaveManager.state == persistent,"component fixtures never write persistent credits/research/loadout/frontline")
 var file := FileAccess.open("user://component_scenarios.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures,"seed":707,"fixture":"isolated mission access; controlled damage/rays; ammo tiers snapshotted from existing profiles; no Android hardware","cases":records},"  "))
 print("DRONE COMPONENTS: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)

func progression_and_geometry() -> void:
 for mission in range(1,26):
  var battle := arena(mission)
  for kind in CampaignManager.enemies:
   var enemy := unit(battle,str(kind))
   var expected := 0
   for item in preload("res://scripts/game/drone_components.gd").CONFIG.loadouts.get(kind,[]):
    expected += int(mission >= int(item.from_mission))
   check((enemy.components != null) == (expected > 0),"progression match %s / mission %d" % [kind,mission])
   if enemy.components != null:
    var rig: RefCounted = enemy.components
    check(rig.parts.size() == expected+1 and rig.parts.size() <= 7,"bounded eligible parts including live body alias")
    check(rig.find("body").health == enemy.health,"body component aliases actual hull HP")
    enemy.position += Vector2(23,-17)
    enemy.rotation = .71
    enemy.scale = Vector2(1.2,.8)
    battle.scale = Vector2(.75,.75)
    battle.position = Vector2(19,5)
    rig.tick(.01)
    for part in rig.parts:
     var world_point: Vector2 = part.point()
     check(battle.to_global(world_point).distance_to(part.global_position) < .0001,"binding follows actor/canvas transform")
     var a: Vector2 = battle.to_local(part.to_global(Vector2(-part.radius*2,0)))
     var b: Vector2 = battle.to_local(part.to_global(Vector2(part.radius*2,0)))
     check(absf(part.segment(a,b)-a.distance_to(b)*.25) < .001,"analytic transformed ellipse entry")
     var miss_a: Vector2 = battle.to_local(part.to_global(Vector2(-part.radius*2,part.radius*1.1)))
     var miss_b: Vector2 = battle.to_local(part.to_global(Vector2(part.radius*2,part.radius*1.1)))
     check(is_inf(part.segment(miss_a,miss_b)),"near miss stays a miss after rotation/nonuniform scale")
    var first: Node2D = rig.parts[1]
    var old: Vector2 = first.point()
    enemy.position.x += 41
    check(first.point().distance_to(old+Vector2(41,0)) < .001,"live binding follows translation without one-frame lag")
    if enemy.brain.boss:
     enemy.health = enemy.maximum_health*.25
     enemy.brain.tick(.01)
     rig.tick(.5)
     check(enemy.brain.phase_index == 2 and rig.armor_open > 0,"boss damage phases drive simulated panel articulation")
     check(enemy.brain.weakpoint() == rig.find("core").point(),"boss aiming guidance uses actual local core")
   enemy.queue_free()
  records.append({"mission":mission,"archetypes":CampaignManager.enemies.size()})
  battle.queue_free()
  await get_tree().process_frame
 # Quality/shake/hover never moves live precision shapes.
 var battle := arena()
 var enemy := unit(battle)
 var part: Node2D = enemy.components.find("engine_left")
 var point: Vector2 = part.point()
 for quality in ["low","medium","high"]:
  SaveManager.settings.effects_quality = quality
  enemy.art.graphics = preload("res://scripts/visual/graphics_profile.gd").resolve(SaveManager.settings)
  for frame in 3:
   battle.view.tick(.05)
  check(part.point().distance_to(point) < .001,"graphics preset/hover leaves precision geometry stable")
 battle.queue_free()
 await get_tree().process_frame
 SaveManager.settings.effects_quality = "medium"

func damage_routes() -> void:
 var battle := arena(11)
 var enemy := unit(battle)
 var engine: Node2D = enemy.components.find("engine_left")
 var hp: float = enemy.health
 var before: float = engine.health
 engine.receive(-10,true,false,{})
 engine.receive(NAN,true,false,{})
 check(engine.health == before and enemy.health == hp,"invalid/negative damage cannot heal or poison component state")
 var shot := fire_at(battle,engine,10)
 check(shot.consumed and shot.hit_component == engine,"real swept manual shot hits visible engine")
 check(is_equal_approx(before-engine.health,10) and is_equal_approx(hp-enemy.health,2),"one part packet plus explicit 20% hull spill; no implicit second hull hit")
 shot.impact()
 shot.tick(1)
 check(is_equal_approx(before-engine.health,10) and battle.component_hits == 1,"repeated callbacks cannot duplicate precision damage")
 var weapon: Node2D = enemy.components.find("weapon")
 before = weapon.health
 hp = enemy.health
 enemy.hit(10,false)
 check(weapon.health == before and enemy.health < hp,"automatic direct/body API never selects components")
 var body: Node2D = enemy.components.find("body")
 hp = enemy.health
 body.receive(10,true,false,{})
 check(is_equal_approx(hp-enemy.health,10*(1.0-enemy.resistance_value("armor"))),"body aliases existing configured armor route")
 # A ray missing all surface parts still hits the coarse hull once.
 var contact: Dictionary = enemy.components.contact(enemy.position+Vector2(0,40),Vector2.UP,80)
 check(contact.component != null,"ordinary hull remains hittable")
 contact = enemy.components.contact(enemy.position+Vector2(17,40),Vector2.UP,80)
 check(contact.component == body,"ray missing mounted modules resolves actual hull contact")
 shot = PROJECTILE.instantiate()
 shot.configure_manual(battle,Vector2.UP)
 shot.position = enemy.position+Vector2(17,40)
 shot.damage = 10
 shot.armor_multiplier = 1
 shot.payload = {}
 shot.range_remaining = 80
 battle.projectiles.add_child(shot)
 hp = enemy.health
 before = weapon.health
 shot.tick(.1)
 check(shot.hit_component == body and is_equal_approx(hp-enemy.health,8) and weapon.health == before,"real manual side ray damages only hull once")
 # AoE: one hull packet plus independently clamped quarter-strength part packets.
 shot = PROJECTILE.instantiate()
 shot.configure_manual(battle,Vector2.UP)
 shot.damage = 12
 shot.payload = {}
 shot.armor_multiplier = 1
 shot.splash_radius = 90
 shot.destination = enemy.position
 shot.target = enemy
 battle.projectiles.add_child(shot)
 hp = enemy.health
 var snapshots: Dictionary = {}
 for part in enemy.components.parts:
  snapshots[part.id] = part.health
 shot.impact()
 var spill := 0.0
 for part in enemy.components.parts:
  if part.kind == "body":
   continue
  check(is_equal_approx(float(snapshots[part.id])-part.health,3),"blast gives exactly one 25% packet per live part")
  spill += 3*float(part.definition.hull_transfer)
 check(is_equal_approx(hp-enemy.health,12*(1.0-enemy.resistance_value("armor"))+spill),"splash replaces direct hit; explicit hull + part-spill model")
 battle.queue_free()
 await get_tree().process_frame
 # Rail: one surface per actor, penetration/falloff across actors, no part farming.
 battle = arena(11)
 var targets: Array[Node2D] = []
 var origins: Array[float] = []
 for y in [450,350,250,150]:
  enemy = unit(battle)
  enemy.position.y = y
  engine = enemy.components.find("engine_left")
  origins.append(engine.health)
  targets.append(enemy)
 shot = PROJECTILE.instantiate()
 shot.configure_manual(battle,Vector2.UP)
 shot.damage = 10
 shot.armor_multiplier = 1
 shot.payload = {}
 shot.penetration_remaining = 3
 shot.penetration_falloff = .78
 shot.position = targets[0].components.find("engine_left").point()+Vector2(0,45)
 shot.range_remaining = 500
 battle.projectiles.add_child(shot)
 shot.tick(1)
 check(shot.hit_ids.size() == 3 and shot.consumed,"rail penetrates exactly three distinct component-bearing actors")
 for index in 4:
  var expected: float = 10*pow(.78,index) if index < 3 else 0.0
  check(is_equal_approx(origins[index]-targets[index].components.find("engine_left").health,expected),"rail preserves distinct-actor falloff and fourth-actor immunity")
 battle.queue_free()
 await get_tree().process_frame

func precision_feedback_contract() -> void:
 var battle := arena(20)
 var enemy := unit(battle)
 enemy.position.y = 450
 var weapon: Node2D = enemy.components.find("weapon")
 weapon.receive(weapon.health+.001,true,true,{})
 var core: Node2D = enemy.components.find("core")
 var scout := unit(battle,"scout")
 scout.position.y = 350
 var shot := PROJECTILE.instantiate()
 shot.configure_manual(battle,Vector2.UP)
 shot.position = core.point()+Vector2(0,30)
 shot.damage = 10
 shot.speed = 200
 shot.armor_multiplier = 1
 shot.critical = false
 shot.payload = {}
 shot.penetration_remaining = 2
 shot.range_remaining = 400
 battle.projectiles.add_child(shot)
 shot.tick(.15)
 check(shot.hit_ids.size() == 1 and shot.precision_critical and battle.player_turret.last_critical,"rail core impact displays genuine per-hit precision confirmation")
 shot.tick(.5)
 check(shot.hit_ids.size() == 2 and shot.consumed and not shot.precision_critical and not battle.player_turret.last_critical,"subsequent ordinary rail hit does not inherit core critical feedback")
 check(is_equal_approx(scout.health,30),"feedback reset never changes subsequent ordinary damage")
 battle.queue_free()
 await get_tree().process_frame

func consequences() -> void:
 var battle := arena(11)
 var enemy := unit(battle)
 var credits: int = battle.credits
 var part: Node2D = enemy.components.find("engine_left")
 part.receive(part.health,true,true,{})
 check(part.broken and is_equal_approx(enemy.components.speed_multiplier(),.7),"one engine destruction reduces nominal speed by 30%")
 var damage_count: int = battle.component_destructions
 part.receive(part.health/float(part.definition.damage_multiplier)+.001,true,true,{})
 check(battle.component_destructions == damage_count and battle.credits == credits,"repeated part hit gives neither destruction event nor currency")
 enemy.speed = 40
 var distance: float = enemy.distance_remaining
 enemy.tick(.1)
 check(is_equal_approx(distance-enemy.distance_remaining,2.8),"crippled engine changes real path travel")
 check(absf(enemy.components.pose_angle) > 0,"crippled rig simulates subtle instability")
 part = enemy.components.find("engine_right")
 part.receive(part.health,true,true,{})
 check(enemy.components.falling and not enemy.ended and not enemy.automatically_targetable(),"all critical engines enter untargetable falling state")
 var position_before: Vector2 = enemy.position
 enemy.tick(.4)
 check(enemy.position == position_before and battle.living_count() == 1 and battle.credits == credits,"crash freezes navigation; wave waits without early bounty")
 enemy.tick(.41)
 check(enemy.ended and battle.living_count() == 0 and battle.credits == credits+enemy.reward and battle.kills == 1,"crash finishes with one normal bounty and clears wave ownership")
 enemy.die()
 check(battle.kills == 1 and battle.credits == credits+enemy.reward,"death/reward ownership remains idempotent")
 battle.queue_free()
 await get_tree().process_frame
 battle = arena(10)
 enemy = unit(battle,"shield")
 var protected := unit(battle,"heavy")
 protected.position.x += 40
 var resistance: float = protected.brain.shield_multiplier(false)
 part = enemy.components.find("generator")
 part.receive(part.health/float(part.definition.damage_multiplier)+.001,true,true,{})
 check(part.broken and not enemy.brain.shield_active() and protected.brain.shield_multiplier(false) > resistance,"destroyed generator removes actual nearby aura")
 battle.queue_free()
 await get_tree().process_frame
 battle = arena(11)
 battle.select_slot(0)
 battle.build_turret("machine_gun")
 enemy = unit(battle,"emp")
 enemy.position = battle.placed[0].position+Vector2(0,-50)
 enemy.brain.cooldown = 0
 enemy.brain.tick(.01)
 check(enemy.brain.charging,"real EMP begins attack before module damage")
 var actions: int = enemy.brain.actions
 var damage: int = enemy.damage
 part = enemy.components.find("weapon")
 part.receive(part.health/float(part.definition.damage_multiplier)+.001,true,true,{})
 enemy.brain.tick(10)
 check(not enemy.brain.charging and enemy.brain.actions == actions and enemy.damage == int(ceil(damage*.5)),"weapon destruction cancels real attack and halves remaining breach payload")
 enemy = unit(battle,"stealth")
 check(enemy.brain.cloaked(),"stealth sensor initially enables cloak")
 enemy.components.find("sensor").receive(enemy.components.find("sensor").health/1.1+.001,true,true,{})
 check(not enemy.brain.cloaked(),"sensor destruction permanently removes cloak ability")
 battle.queue_free()
 await get_tree().process_frame
 # Generator seal, timed exposure, core multiplier, finite breach and phase changes.
 battle = arena(25)
 enemy = unit(battle,"hive_core")
 var core: Node2D = enemy.components.find("core")
 check(not core.open(),"live boss generator seals precision bonus")
 enemy.components.find("generator").receive(enemy.components.find("generator").health/1.2+.001,true,true,{})
 check(not enemy.ended and core.open(),"generator destruction exposes core without instantly killing boss")
 var hp: float = enemy.health
 var core_hp: float = core.health
 core.receive(10,true,false,{})
 check(is_equal_approx(core_hp-core.health,25) and is_equal_approx(hp-enemy.health,25),"open core receives precise 2.5x damage once")
 enemy.components.clock = 6.5
 check(not core.open(),"late-game core respects closed vulnerability window")
 core_hp = core.health
 core.receive(10,true,false,{})
 check(is_equal_approx(core_hp-core.health,5.5),"closed boss core receives ordinary manual hull damage")
 enemy.components.clock = 8.1
 check(core.open(),"window reopens deterministically on simulation clock")
 enemy.health = enemy.maximum_health*.6
 enemy.brain.tick(.01)
 check(enemy.brain.phase_index == 1,"component body damage remains compatible with boss phases")
 core_hp = core.health
 core.receive(10,true,false,{})
 check(is_equal_approx(core_hp-core.health,27.5),"core reward respects configured phase multiplier")
 var clock: float = enemy.components.clock
 battle.set_paused(true)
 battle._physics_process(1)
 check(enemy.components.clock == clock,"pause freezes exposure and falling clocks")
 battle.set_paused(false)
 battle.select_slot(0)
 battle._physics_process(1)
 check(is_equal_approx(enemy.components.clock-clock,.25),"tactical slow motion advances component windows at shared quarter speed")
 battle.close_build_mode()
 clock = enemy.components.clock
 battle._physics_process(.1)
 check(is_equal_approx(enemy.components.clock-clock,.1),"closing build mode restores normal component time")
 battle.queue_free()
 await get_tree().process_frame
 # Last falling actor must not deadlock actual battle victory.
 battle = arena(11)
 enemy = unit(battle)
 battle.spawner.finished = true
 enemy.components.find("engine_left").receive(65,true,true,{})
 enemy.components.find("engine_right").receive(65,true,true,{})
 battle.simulate(.4)
 check(not battle.finished,"final falling actor delays result until crash completes")
 battle.simulate(.5)
 battle.simulate(.01)
 check(battle.finished and battle.kills == 1,"last crash completes the actual battle result")
 battle.queue_free()
 await get_tree().process_frame

func ammo_matrix() -> void:
 var count := 0
 for kind in CampaignManager.enemies:
  for ammo in SaveManager.catalog.ammunition:
   var battle := arena(20)
   var enemy := unit(battle,str(kind))
   var shot := PROJECTILE.instantiate()
   shot.configure_manual(battle,Vector2.UP)
   var profile: Dictionary = SaveManager.catalog.ammunition[ammo].duplicate(true)
   shot.payload = profile
   shot.visual_kind = str(ammo)
   shot.damage = 10
   shot.critical = true # damage was snapshotted at fire, never multiplied twice here
   shot.splash_radius = float(profile.splash_radius)
   shot.armor_multiplier = float(profile.armor_multiplier)
   shot.destination = enemy.position
   shot.target = enemy
   battle.projectiles.add_child(shot)
   var hp: float = enemy.health
   var levels: Array[float] = []
   if enemy.components != null:
    for part in enemy.components.parts:
     levels.append(part.health)
    shot.hit_component = enemy.components.find("engine_left")
    if shot.hit_component == null:
     shot.hit_component = enemy.components.parts[1]
   shot.impact()
   check(enemy.health < hp and not enemy.ended,"all six real ammunition payloads damage every archetype")
   if float(profile.get("disable_duration",0)) > 0:
    check(enemy.disable_remaining > 0,"EMP status survives precise component route and boss resistance")
   if float(profile.get("status_duration",0)) > 0:
    check(enemy.slow_remaining > 0,"Cryo status survives precise component route and boss resistance")
   if enemy.components != null:
    check(enemy.components.parts.size() <= 7,"projectile branches never create new component nodes")
    for index in levels.size():
     check(enemy.components.parts[index].health <= levels[index],"payload never heals hull or component")
   var after: float = enemy.health
   shot.impact()
   check(enemy.health == after,"every ammo consumes impact ownership before callback")
   count += 1
   battle.queue_free()
   await get_tree().process_frame
 records.append({"ammunition_archetype_pairs":count})
