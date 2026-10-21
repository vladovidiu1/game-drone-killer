extends Node
# Isolated mechanics use stated fixture unlocks/funds; real campaign is separate.
const BATTLE := preload("res://scenes/gameplay.tscn")
const RULES := preload("res://scripts/game/placement_rules.gd")
var checks := 0
var failures := 0
var records: Array[Dictionary] = []

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("PLACEMENT: "+message)

func _ready() -> void:
 run.call_deferred()

func arena(id: int = 1) -> Node2D:
 var battle := BATTLE.instantiate()
 battle.mission_id = id
 battle.attack_seed = 6000+id
 add_child(battle)
 battle.set_physics_process(false)
 return battle

func movement_contract() -> void:
 SaveManager.new_campaign()
 var battle := arena()
 battle.select_slot(0)
 check(battle.build_turret("machine_gun") and battle.upgrade_selected(),"source built/upgraded with ordinary funds")
 var turret: Node2D = battle.placed[0]
 var identity: int = turret.get_instance_id()
 var snapshot: Dictionary = turret.definition.duplicate(true)
 var damage: float = turret.damage_value()
 var rate: float = turret.fire_rate_value()
 var remaining: int = battle.credits
 check(battle.view.placement.point_coverage(Vector2(220,250)).weapons == 1 and battle.view.placement.point_coverage(Vector2(770,170)).weapons == 0,"source placement creates west reach and an eastern gap")
 check(turret.purchase_value() == 165 and battle.movement.quote(turret) == 58,"35 percent current invested value rounds up to integer BC")
 check(battle.movement.begin(0),"select existing turret for Move")
 check(not battle.movement.choose(0) and not battle.movement.choose(-1) and not battle.movement.choose(100),"source and invalid destinations rejected")
 check(battle.movement.choose(1),"empty destination accepted")
 check(battle.credits == remaining and not turret.redeploying,"intent remains free and source remains operational")
 battle.movement.cancel()
 check(battle.credits == remaining and battle.placed[0] == turret,"free selection cancellation keeps resources")
 battle.select_slot(2)
 battle.build_turret("machine_gun")
 check(battle.movement.begin(0) and not battle.movement.choose(2),"occupied destination rejected")
 check(battle.movement.choose(1) and battle.movement.confirm(),"explicit confirmation starts paid transaction")
 remaining -= 100+58
 check(battle.credits == remaining and battle.movement.active and turret.redeploying,"one debit and offline source")
 check(not battle.movement.confirm() and not battle.movement.begin(2),"duplicate confirm and concurrent relocation rejected")
 check(battle.placed[0] == turret and battle.placed[1] == null and battle.movement.reserved(1),"source retained, destination reserved without a second turret")
 battle.select_slot(1)
 check(not battle.build_turret("machine_gun"),"reserved destination cannot be built over")
 battle.select_slot(0)
 check(not battle.upgrade_selected() and not turret.rotate_bearing(1),"in-transit upgrades/orientation are locked")
 var enemy: Node2D = battle.spawn_enemy("heavy")
 enemy.position = turret.position+Vector2(0,-100)
 enemy.speed = 0
 var shots: int = turret.shots_fired
 for index in 30:
  turret.tick(1.0/60)
 check(turret.shots_fired == shots and turret.target == null,"transported turret cannot acquire/fire")
 battle.close_build_mode()
 battle.set_paused(true)
 var progress: float = battle.movement.elapsed
 battle._physics_process(1)
 check(battle.movement.elapsed == progress,"pause freezes transportation")
 battle.set_paused(false)
 battle.select_slot(2)
 battle._physics_process(1)
 check(is_equal_approx(battle.movement.elapsed-progress,.25),"tactical build uses shared quarter-speed movement clock")
 battle.close_build_mode()
 progress = battle.movement.elapsed
 battle._physics_process(.5)
 check(is_equal_approx(battle.movement.elapsed-progress,.5),"closing build restores normal move time")
 enemy.position = Vector2(560,450)
 battle.player_controls.aim_at(enemy.position)
 battle.player_controls.set_fire(&"fixture",true)
 for frame in 30:
  battle.simulate(1.0/60)
 check(battle.player_turret.shots_fired > 0 and battle.player_turret.hits > 0 and turret.shots_fired == shots,"manual cannon protects a real offline relocation")
 check(turret.art.cached_suppression == 1.0,"visual adapter consistently mutes transported weapon")
 battle.player_controls.clear()
 battle.movement.tick(battle.movement.duration())
 check(not battle.movement.active and battle.placed[0] == null and battle.placed[1] == turret,"completion transfers slot ownership exactly once")
 check(turret.get_instance_id() == identity and turret.position == battle.slots[1] and turret.level == 2,"same instance and level arrive at destination")
 check(turret.damage_value() == damage and turret.fire_rate_value() == rate and turret.definition == snapshot,"research/specialization profile and damage/rate survive relocation")
 check(battle.view.placement.point_coverage(Vector2(220,250)).weapons == 0 and battle.view.placement.point_coverage(Vector2(770,170)).weapons == 1,"redeployment trades west reach for east reach")
 preload("res://scripts/visual/combat_visuals.gd").advance(battle,.01)
 check(turret.art.cached_suppression == 0.0,"transport completion restores unit material state")
 check(not turret.redeploying and turret.target == null and battle.turrets.get_child_count() == 2,"no duplicate actor and fresh target acquisition")
 var count: int = battle.turrets.get_child_count()
 battle.movement.tick(100)
 check(battle.turrets.get_child_count() == count and battle.credits == remaining,"repeated finish tick cannot duplicate resources")
 battle.select_slot(1)
 battle.movement.begin(1)
 battle.movement.choose(3)
 check(battle.movement.confirm(),"second move starts")
 battle.movement.tick(.5)
 battle.movement.cancel()
 battle.movement.cancel()
 check(battle.credits == remaining and battle.placed[1] == turret and not battle.movement.reserved(3),"interruption refunds escrow once and keeps original slot")
 battle.movement.begin(1)
 battle.movement.choose(3)
 battle.credits = 0
 check(not battle.movement.confirm() and not turret.redeploying,"insufficient funds cannot start/disable turret")
 battle.movement.cancel()
 battle.queue_free()
 await get_tree().process_frame
 for victory in [false,true]:
  battle = arena()
  battle.select_slot(0)
  battle.build_turret("machine_gun")
  remaining = battle.credits
  battle.movement.begin(0)
  battle.movement.choose(1)
  battle.movement.confirm()
  battle._finish(victory)
  battle._finish(victory)
  battle.movement.cancel()
  check(battle.credits == remaining and not battle.movement.active and not battle.movement.reserved(1),"victory/defeat cancels in-flight move and refunds exactly once")
  battle.queue_free()
  await get_tree().process_frame
 battle = arena()
 battle.select_slot(0)
 battle.build_turret("machine_gun")
 remaining = battle.credits
 battle.movement.begin(0)
 battle.movement.choose(1)
 battle.movement.confirm()
 battle.placed[0].queue_free()
 await get_tree().process_frame
 battle.movement.tick(.1)
 check(battle.credits == remaining and battle.placed[0] == null and not battle.movement.active,"lost actor safely cancels transaction")
 battle.queue_free()
 await get_tree().process_frame
 battle = arena()
 battle.select_slot(0)
 battle.build_turret("machine_gun")
 remaining = battle.credits
 battle.movement.begin(0)
 battle.movement.choose(1)
 battle.movement.confirm()
 remove_child(battle)
 check(battle.credits == remaining and not battle.movement.active,"scene removal refunds before free without UI callbacks")
 battle.queue_free()
 await get_tree().process_frame

func arc_contract() -> void:
 SaveManager.new_campaign()
 SaveManager.state.unlocks = ["laser","emp_tower","heavy_aa"]
 for kind in CampaignManager.turrets:
  var battle := arena()
  battle.credits = 10000 # Explicit all-archetype mechanics fixture, never campaign evidence.
  battle.select_slot(0)
  battle.build_turret(str(kind))
  var turret: Node2D = battle.placed[0]
  var radius: float = turret.range_value()
  var width: float = turret.definition.traverse_degrees
  var front: Vector2 = turret.position+Vector2.UP*100
  var rear: Vector2 = turret.position+Vector2.DOWN*100
  check(turret.covers_point(front),"front inside "+str(kind)+" arc")
  check(turret.covers_point(rear) == (width == 360),"real rear restriction for "+str(kind))
  check(not turret.covers_point(turret.position+Vector2.UP*(radius+1)),"range clipping for "+str(kind))
  var edge: Vector2 = turret.position+Vector2.from_angle(turret.bearing+deg_to_rad(width*.5))*100
  check(turret.covers_point(edge),"inclusive firing arc boundary")
  var outside: Vector2 = turret.position+Vector2.from_angle(turret.bearing+deg_to_rad(width*.5+1))*100
  check(turret.covers_point(outside) == (width == 360),"outside arc rejected independently of range")
  var enemy: Node2D = battle.spawn_enemy("heavy")
  enemy.position = rear
  enemy.speed = 0
  check((turret.acquire_target() == enemy) == (width == 360),"target acquisition obeys mechanical arc")
  var before: int = turret.shots_fired
  for index in 60:
   turret.tick(1.0/60)
  check((turret.shots_fired > before) == (width == 360),"actual firing obeys arc")
  enemy.position = front
  for index in 120:
   turret.tick(1.0/60)
   for projectile in battle.projectiles.get_children():
    projectile.tick(1.0/60)
  check(turret.shots_fired > before,"forward targets receive actual weapon operation")
  check(enemy.health < enemy.maximum_health if kind != "emp_tower" else enemy.slow_remaining > 0,"projectile/laser/status still affects target")
  var heading: float = turret.bearing
  check(turret.rotate_bearing(1) and is_equal_approx(angle_difference(heading,turret.bearing),PI/4),"mount facing adjustable via configured step")
  for x in range(40,920,110):
   for y in range(100,620,100):
    var point := Vector2(x,y)
    var reach: Dictionary = battle.view.placement.point_coverage(point)
    check(int(reach.weapons)+int(reach.support) == int(turret.covers_point(point)),"overlay uses real range and firing arc")
  records.append({"kind":kind,"arc":width,"range":radius,"purchase_value":turret.purchase_value(),"move_cost":battle.movement.quote(turret)})
  battle.queue_free()
  await get_tree().process_frame

func layouts_contract() -> void:
 SaveManager.new_campaign()
 SaveManager.state.research.turret_damage = 2
 SaveManager.state.research.turret_range = 2
 for id in range(1,26):
  var battle := arena(id)
  battle.credits = 10000 # Fixture funds verify all slot pairs, not progression.
  check(battle.slots.size() == battle.mission_data.emplacements.size(),"every slot has strategic metadata")
  var sectors: Array = []
  for index in battle.slots.size():
   var data: Dictionary = battle.mission_data.emplacements[index]
   if not sectors.has(data.sector):
    sectors.append(data.sector)
   check(float(data.range_multiplier) >= 1 and float(data.range_multiplier) <= 1.1,"bounded specialized range bonus")
  check(sectors.size() == 3,"western, central and eastern defenses on every map")
  battle.spawner.tick(1000,0)
  check(battle.spawner.wave == -1 and battle.spawner.total_spawned == 0,"initial preparation never auto-launches")
  battle.select_slot(0)
  battle.build_turret("cannon")
  battle.upgrade_selected()
  var turret: Node2D = battle.placed[0]
  var damage: float = turret.damage_value()
  var base_range: float = turret.range_value()/turret.range_multiplier
  var total: int = battle.credits
  var spent := 0
  var source := 0
  for destination in range(1,battle.slots.size()):
   var price: int = battle.movement.quote(turret)
   check(battle.movement.begin(source) and battle.movement.choose(destination) and battle.movement.confirm(),"valid redeployment across every layout slot")
   battle.movement.tick(battle.movement.duration())
   spent += price
   check(battle.placed[destination] == turret and battle.placed[source] == null and battle.turrets.get_child_count() == 1,"single owner across all destinations")
   check(turret.level == 2 and turret.damage_value() == damage,"temporary level/permanent bonus preserved across all maps")
   check(is_equal_approx(turret.range_value(),base_range*float(battle.mission_data.emplacements[destination].range_multiplier)),"range/overlay adapt to destination elevation")
   source = destination
  check(battle.credits == total-spent,"all-layout movement accounting stays integer and nonnegative")
  check(battle.start_wave(),"player can launch after planning")
  battle.queue_free()
  await get_tree().process_frame

func specialization_contract() -> void:
 SaveManager.new_campaign()
 SaveManager.state.damage_level = 2
 SaveManager.state.research.turret_damage = 2
 SaveManager.state.research.turret_range = 2
 SaveManager.state.research.spec_machine_gun_armor = 2
 SaveManager.state.turret_specializations.machine_gun = "armor"
 var battle := arena(3)
 battle.select_slot(0)
 battle.build_turret("machine_gun")
 battle.upgrade_selected()
 var turret: Node2D = battle.placed[0]
 var snapshot: Dictionary = turret.definition.duplicate(true)
 var damage: float = turret.damage_value()
 var radius: float = turret.range_value()
 turret.cooldown = 1.7
 check(snapshot.armor_bypass > 0 and snapshot.armor_multiplier > 1,"specialization fixture has actual researched payload")
 battle.movement.begin(0)
 battle.movement.choose(6)
 battle.movement.confirm()
 battle.movement.tick(battle.movement.duration())
 check(turret.definition == snapshot and turret.damage_value() == damage and turret.level == 2,"legacy amplifier, research and specialization survive move unchanged")
 check(is_equal_approx(turret.range_value(),radius*1.08),"elevation adds only its documented range bonus")
 check(is_equal_approx(turret.cooldown,1.7),"arrival never resets weapon cooldown")
 battle.queue_free()
 await get_tree().process_frame

func run() -> void:
 await movement_contract()
 await arc_contract()
 await layouts_contract()
 await specialization_contract()
 var file := FileAccess.open("user://placement_scenarios.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures,"fixture":"mechanics/all-layout suites use explicit credits + unlock/research fixtures; first movement lifecycle uses ordinary M1 funds; no campaign victory or War Credits injected","weapons":records},"  "))
 print("PLACEMENT: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
