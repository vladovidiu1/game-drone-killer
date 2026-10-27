extends Node
# Real movement/targeting/damage fixtures; neither invulnerability nor forced survivors.
const BATTLE := preload("res://scenes/gameplay.tscn")
const DIRECTOR := preload("res://scripts/game/tactical_attack_director.gd")
const PILOT := preload("res://tests/m1_pilot.gd")
var checks := 0
var failures := 0
var rows: Array[Dictionary] = []
var patterns_seen: Dictionary = {}

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("TACTICAL FAIL: "+message)

func _ready() -> void:
 run.call_deferred()

func arena(id: int, seed_value: int) -> Node2D:
 var battle := BATTLE.instantiate()
 battle.mission_id = id
 battle.attack_seed = seed_value
 add_child(battle)
 battle.set_physics_process(false)
 battle.player_turret.rng.seed = seed_value
 return battle

func layouts_and_plans() -> void:
 for id in range(1,26):
  var battle := arena(id,5100+id)
  var data: Dictionary = battle.mission_data
  var approaches: Dictionary = data.approaches
  var bounds := Rect2(approaches.movement_bounds[0],approaches.movement_bounds[1],approaches.movement_bounds[2],approaches.movement_bounds[3])
  check(data.paths.size() == approaches.sectors.size() and data.paths.size() == approaches.spawn_areas.size(),"M%d route metadata coverage" % id)
  for sector in DIRECTOR.SECTORS:
   check(approaches.sectors.has(sector),"M%d supports %s" % [id,sector])
  for index in data.paths.size():
   var route: Array = data.paths[index]
   var area: Array = approaches.spawn_areas[index]
   check(Rect2(area[0],area[1],area[2],area[3]).has_point(Vector2(route[0][0],route[0][1])),"spawn inside declared area")
   check(route.back() == approaches.target,"route reaches the declared defended objective")
   for waypoint in route.size():
    var point := Vector2(route[waypoint][0],route[waypoint][1])
    check(bounds.has_point(point),"M%d every route point inside movement bounds" % id)
    if waypoint > 0:
     check(point.y >= float(route[waypoint-1][1]) and point.distance_to(Vector2(route[waypoint-1][0],route[waypoint-1][1])) > 0,"forward, nonzero route segment")
   var intercept := DIRECTOR.point_at_y(route,460)
   check(intercept.distance_to(battle.player_turret.position) < battle.player_turret.definition.range,"manual cannon can intercept every approach")
   var enemy: Node2D = battle.spawn_enemy("scout",index)
   var old: Vector2 = enemy.position
   enemy.tick(.1)
   check(enemy.position != old and not enemy.ended,"route produces actual movement")
   enemy.hit(1000)
   check(enemy.ended,"every route enemy accepts ordinary damage")
  for pattern in DIRECTOR.CONFIG.patterns:
   for wave in data.waves.size():
    var director := DIRECTOR.new()
    director.configure(battle,8200+id+wave)
    director.forced_pattern = pattern
    var plan := director.prepare(wave,data.waves[wave])
    check(plan.spent <= plan.budget and plan.spent >= ceil(plan.budget*float(DIRECTOR.CONFIG.minimum_spent_ratio)),"budget bounded for every pattern/wave")
    check(plan.planned_bounty <= plan.bounty_cap,"composition cannot inflate economy")
    var actual := {"WEST":0,"CENTER":0,"EAST":0}
    for entry in plan.entries:
     actual[approaches.sectors[entry.path]] += 1
     check(entry.sector == approaches.sectors[entry.path],"warning uses exact scheduled route sector")
    check(actual == plan.sectors,"warning counts reflect frozen composition")
    check(plan.warning_seconds >= 5 and plan.warning_seconds <= 8,"fair default preparation window")
    var repeated := DIRECTOR.new()
    repeated.configure(battle,8200+id+wave)
    repeated.forced_pattern = pattern
    check(JSON.stringify(repeated.prepare(wave,data.waves[wave])) == JSON.stringify(plan),"same seed and state reproduce plan")
  # Sample natural selection (without forcing patterns), including capped adaptation.
  battle.select_slot(1)
  battle.build_turret("cannon")
  battle.close_build_mode()
  for seed_value in range(60):
   var director := DIRECTOR.new()
   director.configure(battle,seed_value)
   var plan := director.prepare(0,data.waves[0])
   patterns_seen[plan.pattern] = true
   if id <= 3:
    check(plan.pattern == DIRECTOR.CONFIG.tutorial_patterns[str(id)][0],"tutorial is independent of seed")
   if id <= 10:
    check(plan.pattern not in ["decoy","swarm","elite"],"advanced tactics respect chapter unlocks")
   if id < 16:
    check(not plan.adaptive,"no early adaptation")
   var stage := director.stage()
   for pattern in plan.weights:
    check(float(plan.weights[pattern]) <= float(stage.weights[pattern])*(1.0+float(stage.adaptation_cap)+float(stage.history_cap))+.001,"bounded weighted bias")
  battle.queue_free()
  await get_tree().process_frame
 check(patterns_seen.size() == 8,"natural seeded selection exercises all eight patterns")

func warning_contract() -> void:
 var battle := arena(12,777)
 var frozen := JSON.stringify(battle.spawner.plan)
 check(not battle.start_wave(),"cannot bypass announced preparation")
 battle.select_slot(1)
 battle.build_turret("cannon")
 var timer: float = battle.spawner.warning_remaining
 battle._physics_process(1)
 check(is_equal_approx(timer-battle.spawner.warning_remaining,1.0),"radar keeps normal speed after construction")
 battle.set_paused(true)
 timer = battle.spawner.warning_remaining
 battle.simulate(3)
 check(battle.spawner.warning_remaining == timer,"pause freezes preparation")
 battle.set_paused(false)
 battle.spawner.tick(timer,0)
 check(JSON.stringify(battle.spawner.plan) == frozen,"building never changes the announced plan")
 check(battle.start_wave(),"early start after complete preparation")
 var expected: Array = battle.spawner.plan.entries
 var emitted: Array[Dictionary] = []
 battle.spawner.spawn_requested.connect(func(kind: String, route: int): emitted.append({"enemy":kind,"path":route}))
 for tick in range(100):
  battle.spawner.tick(.25,999)
 check(emitted.size() == expected.size(),"entire frozen wave emitted")
 for index in mini(emitted.size(),expected.size()):
  check(emitted[index].enemy == expected[index].enemy and emitted[index].path == expected[index].path,"legacy formations cannot override announced paths")
 battle.queue_free()
 await get_tree().process_frame

func support_budget_contract() -> void:
 var battle := arena(20,899)
 var director := DIRECTOR.new()
 director.configure(battle,899)
 for index in 20:
  director.plans.append({"pattern":"swarm","complete":true,"breaches":50})
 var selected: Dictionary = director.choose(0,{"WEST":0.0,"CENTER":0.0,"EAST":0.0})
 check(float(selected.weights.swarm) <= float(director.stage().weights.swarm)*(1.0+float(director.stage().history_cap))+.001,"history cap applies across all previous waves")
 var parent: Node2D = battle.spawn_enemy("carrier",0)
 parent.set_meta("attack_wave",0)
 parent.set_meta("attack_sector","WEST")
 parent.position = Vector2(40,100)
 battle.director.plans[0].support_budget = 3
 var plan: Dictionary = battle.director.plans[0]
 for index in 5:
  var child: Node2D = battle.spawn_support("scout",parent)
  check((child != null) == (index < 3),"carrier support obeys finite threat reserve")
  if child != null:
   check(child.position.x >= 40 and child.position.y >= 88,"support spawn clamps to movement bounds")
   check(child.get_meta("attack_sector") == "WEST","support inherits wave/sector outcome ownership")
 check(plan.support_spent == 3 and plan.supports == 3,"reserve debited only for spawned supports")
 check(plan.support_spent <= plan.support_budget,"recursive support cannot exceed wave threat budget")
 battle._finish(false)
 check(plan.terminated and not plan.victory and plan.base_after == battle.health,"defeat produces a tactical debug outcome")
 battle.queue_free()
 await get_tree().process_frame

func scenario(label: String, pattern: String, indices: Array, upgraded: bool, seed_value: int, id: int = 12, manual: bool = false) -> Dictionary:
 SaveManager.new_campaign()
 if upgraded:
  for key in SaveManager.state.research:
   SaveManager.state.research[key] = 2
 var battle := arena(id,seed_value)
 battle.mission_data = battle.mission_data.duplicate(true)
 # One real existing pressure wave, ordinary mission funds; progression is an explicit fixture.
 var wave_index := 3
 battle.mission_data.waves = [battle.mission_data.waves[wave_index].duplicate(true)]
 battle.mission_data.approaches.wave_budgets = [battle.mission_data.approaches.wave_budgets[wave_index]]
 for index in indices.size():
  battle.select_slot(indices[index])
  check(battle.build_turret("machine_gun" if label == "D" or index == 2 else "cannon"),"scenario construction uses real funds")
 if upgraded:
  for index in indices:
   battle.select_slot(index)
   check(battle.upgrade_selected(),"scenario upgrades use real funds")
 battle.close_build_mode()
 battle.director.plans.clear()
 battle.director.rng.seed = seed_value
 battle.director.forced_pattern = pattern
 battle.spawner.configure(battle.mission_data.waves,6,battle.mission_data.paths.size(),battle.director)
 var initial: int = battle.credits
 var plan: Dictionary = battle.spawner.plan
 var spawned := {"WEST":0,"CENTER":0,"EAST":0}
 battle.spawner.spawn_requested.connect(func(_kind: String, route: int): spawned[str(battle.mission_data.approaches.sectors[route])] += 1)
 for frame in range(60*180):
  if battle.finished:
   break
  if manual:
   PILOT.aim(battle)
  if battle.spawner.wave < 0 and battle.spawner.timer <= 0 and battle.spawner.warning_remaining <= 0:
   battle.start_wave()
  battle.simulate(1.0/60.0)
  if frame%120 == 0:
   await get_tree().process_frame
 check(battle.finished,"scenario pressure wave terminates normally")
 check(battle.kills > 0,"scenario turrets acquire, hit and destroy")
 for sector in DIRECTOR.SECTORS:
  check(spawned[sector] <= plan.sectors[sector],"no sector receives unannounced contacts")
 if battle.spawner.cursor == battle.spawner.pending.size():
  check(spawned == plan.sectors,"fully spawned gameplay wave matches radar counts")
 check(battle.credits == initial+battle.earned and battle.credits >= 0,"ordinary integer bounty accounting")
 var result := {"case":label,"mission":id,"seed":seed_value,"pattern":plan.pattern,"coverage":plan.coverage,"sectors":plan.sectors,"budget":plan.budget,"spent":plan.spent,"bounty_cap":plan.bounty_cap,"kills":battle.kills,"breaches":plan.breaches,"health":battle.health,"victory":battle.health > 0,"manual_shots":battle.player_turret.shots_fired,"manual_hits":battle.player_turret.hits,"battle_earned":battle.earned,"sector_outcomes":plan.sector_outcomes,"seconds":snappedf(battle.elapsed,.01),"research_tier":2 if upgraded else 0,"paid_turret_upgrades":upgraded,"placement":indices}
 rows.append(result)
 print("TACTICAL CASE: "+JSON.stringify(result))
 battle.queue_free()
 await get_tree().process_frame
 return result

func run() -> void:
 SaveManager.new_campaign()
 await layouts_and_plans()
 await warning_contract()
 await support_budget_contract()
 var east := await scenario("A","west_flank",[1,3,7],false,601)
 var west := await scenario("A-control","west_flank",[0,2,6],false,601)
 check(east.coverage.WEST < west.coverage.WEST,"concentrating east exposes west")
 check(east.breaches > west.breaches,"actual west defense prevents more west-flank breakthroughs")
 await scenario("B","split",[0,1,4],false,602)
 await scenario("C","split",[4,5],false,603)
 await scenario("D","center_breakthrough",[4,5],false,604)
 var improved := await scenario("E","west_flank",[0,1,4],true,605,12,true)
 check(improved.manual_hits > 0 and improved.kills > 0,"manual and upgraded automatic defense operate together")
 for seed_value in [701,702,703,704]:
  await scenario("F","",[0,1,4],true,seed_value,20,true)
 var repeated := await scenario("F-repeat","",[0,1,4],true,701,20,true)
 check(JSON.stringify(repeated).replace("F-repeat","F") == JSON.stringify(rows[rows.size()-5]),"same seed reproduces actual combat outcome")
 var file := FileAccess.open("user://tactical_scenarios.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"fixture":"single existing wave 4; ordinary starting funds; M12 / M20; paid construction; explicit research tier; no abilities or ad rewards; fixed 1/60 delta; assisted aim only E/F","checks":checks,"failures":failures,"rows":rows},"  "))
 print("TACTICAL DIRECTOR: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
