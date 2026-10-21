extends Node
# Synthetic accounting fixtures are explicit; live projectiles/actors are tested separately.
const RULES := preload("res://scripts/core/mission_performance.gd")
const BATTLE := preload("res://scenes/gameplay.tscn")
var checks := 0
var failures := 0
var rows: Array = []

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("PERFORMANCE: "+message)

func _ready() -> void:
 run.call_deferred()

func snapshot(id: int, ratio: float = .90) -> Dictionary:
 return {"version":1,"mission_id":id,"health":int(round(1000*ratio)),"max_health":1000,"kills":100,"manual_kills":40,"breaches":0,"manual_shots":100,"manual_hits":80,"manual_damage":600.0,"automatic_damage":400.0,"other_damage":0.0,"components":20,"armored_components":10,"generators":3,"weapons":4,"heavy_engines":3,"core_hits":10,"critical_hits":20,"defense_sectors":3,"base_damage":100,"final_wave_damage":0,"seconds":150.0}

func settle(id: int, victory: bool, data: Dictionary, mode: String = "frontline") -> Dictionary:
 var token := CampaignManager.begin_mission(id,mode)
 check(not token.is_empty(),"legitimate persisted deployment token")
 var receipt := CampaignManager.resolve(victory,id,token,{"health":data.health,"performance":data})
 check(not receipt.is_empty(),"valid token settles once")
 rows.append({"mission":id,"mode":receipt.get("mode"),"victory":victory,"stars":receipt.get("stars"),"reward":receipt.get("reward"),"star_reward":receipt.get("star_reward"),"frontline":SaveManager.state.frontline})
 return receipt

func arena(id: int = 1) -> Node2D:
 var battle := BATTLE.instantiate()
 battle.mission_id = id
 battle.attack_seed = 808
 add_child(battle)
 battle.set_physics_process(false)
 return battle

func run() -> void:
 if "--verify-performance" in OS.get_cmdline_user_args():
  var record: Dictionary = SaveManager.state.records["1"]
  check(record.best_stars == 3 and record.star_claims == [2,3],"fresh process retains best stars and consumed milestones")
  check(record.completed_secondary == ["m01_secondary"] and record.best_performance.war_credits > 0,"fresh process retains objective and coherent credited performance")
  check(SaveManager.state.frontline == 2 and record.fastest_seconds == 100,"fresh process retains frontier and best time")
  var bank: int = SaveManager.state.credits
  var result := settle(1,true,snapshot(1),"replay")
  check(result.reward == 15 and result.star_reward == 0 and SaveManager.state.credits == bank+15,"fresh process cannot recover a milestone/first clear")
  finish()
  return
 SaveManager.new_campaign()
 for pair in [[.20,1],[.599,1],[.60,2],[.849,2],[.85,3],[1.0,3]]:
  check(RULES.evaluate(1,true,snapshot(1,float(pair[0]))).stars == pair[1],"exact inclusive HP star boundary")
 var failed := snapshot(1)
 failed.manual_kills = 0
 check(RULES.evaluate(1,true,failed).stars == 2,"85% without secondary gives two stars")
 check(RULES.evaluate(1,false,snapshot(1)).stars == 0,"defeat receives zero attempt stars")
 check(RULES.evaluate(1,true,{}).stars == 1,"legacy result without denominators cannot invent bonus stars")
 var malformed := snapshot(1)
 malformed.manual_hits = 1000
 malformed.critical_hits = 1000
 malformed.manual_damage = NAN
 malformed.seconds = -100
 var normalized := RULES.clean(malformed,1)
 check(normalized.accuracy == 1 and normalized.critical_hits == 100 and normalized.manual_damage == 0 and normalized.seconds == 0,"invalid fields bounded; accuracy never exceeds 100 percent")
 var original: Dictionary = RULES.config(2).duplicate(true)
 RULES.DATA.missions["2"].two_star_hp = .7
 RULES.DATA.missions["2"].three_star_hp = .95
 check(RULES.evaluate(2,true,snapshot(2,.69)).stars == 1 and RULES.evaluate(2,true,snapshot(2,.94)).stars == 2,"mission-specific thresholds are authoritative")
 RULES.DATA.missions["2"] = original
 await catalog_contract()
 await combat_counters()
 await persistence_contract()
 finish()

func catalog_contract() -> void:
 var components: Dictionary = preload("res://scripts/game/drone_components.gd").CONFIG
 for id in range(1,26):
  var data := RULES.config(id)
  check(float(data.two_star_hp) <= float(data.three_star_hp) and data.secondary.rules.size() > 0,"all 25 missions define ordered thresholds and meaningful objectives")
  var assessment := RULES.evaluate(id,true,snapshot(id))
  check(assessment.stars == 3 and assessment.secondary.complete,"all objectives have an explicit attainable accounting witness")
  var kinds: Array[String] = []
  for wave in CampaignManager.mission(id).waves:
   for group in wave.groups:
    if not kinds.has(str(group.enemy)):
     kinds.append(str(group.enemy))
  for condition in data.secondary.rules:
   if condition in ["components","armored_components","generators","weapons","heavy_engines","core_hits"]:
    var count := 0
    for wave in CampaignManager.mission(id).waves:
     for group in wave.groups:
      for part in components.loadouts.get(str(group.enemy),[]):
       if id < int(part.from_mission):
        continue
       var eligible: bool = condition == "components" or condition == "armored_components" and id >= 16 or condition == "generators" and part.type == "shield" or condition == "weapons" and part.type == "weapon" or condition == "heavy_engines" and group.enemy == "heavy" and part.type == "engine" or condition == "core_hits" and part.type == "core"
       if eligible:
        count += int(group.count)*(100 if condition == "core_hits" else 1)
    check(count >= int(data.secondary.rules[condition]),"objective components actually exist in configured waves, not random support")
  var impossible := snapshot(id)
  for key in data.secondary.rules:
   var rule: Variant = data.secondary.rules[key]
   impossible[key] = 1000000 if rule is Dictionary else 0
  check(not RULES.evaluate(id,true,impossible).secondary.complete,"missed objective is explained, not assumed from a win")
 await get_tree().process_frame

func combat_counters() -> void:
 SaveManager.new_campaign()
 var battle := arena()
 # Two actual manual rounds: one misses; explosive round damages two actors.
 battle.launch_player_projectile(Vector2.LEFT)
 var miss: Node2D = battle.projectiles.get_child(0)
 miss.tick(1)
 var enemy: Node2D = battle.spawn_enemy("scout")
 enemy.position = Vector2(560,440)
 enemy.speed = 0
 var neighbor: Node2D = battle.spawn_enemy("scout")
 neighbor.position = Vector2(585,440)
 neighbor.speed = 0
 battle.launch_player_projectile(Vector2.UP)
 var shot: Node2D = battle.projectiles.get_child(battle.projectiles.get_child_count()-1)
 shot.damage = 100
 shot.splash_radius = 60
 shot.tick(.3)
 var data: Dictionary = battle.performance.snapshot()
 check(data.manual_shots == 2 and data.manual_hits == 1 and data.accuracy == .5,"explosive multi-kill counts one landed round; missed round stays in denominator")
 check(data.kills == 2 and data.manual_kills == 2 and data.manual_damage == 80,"explosion attributes two deaths but clamps effective hull damage to 80")
 shot.impact()
 check(battle.performance.snapshot().manual_damage == 80,"consumed impact cannot duplicate damage telemetry")
 var auto: Node2D = battle.spawn_enemy("assault")
 auto.hit(10,false,false,Vector2.INF,{},&"automatic")
 auto.hit(1000,false,false,Vector2.INF,{},&"automatic")
 check(battle.performance.snapshot().automatic_damage == 100 and battle.performance.snapshot().manual_kills == 2,"automatic damage is separate and clamps overkill")
 battle._breached(50) # barrage/siege is base damage, not a drone breach
 var arriving: Node2D = battle.spawn_enemy("scout")
 battle._drone_breached(25,arriving)
 battle._drone_breached(25,arriving)
 check(battle.health == 925 and battle.performance.snapshot().breaches == 1,"only actual once-owned arrival counts a breach; attack damage does not")
 battle.spawner.wave = battle.spawner.waves.size()-1
 battle._breached(40)
 battle.abilities.activate("repair")
 check(battle.performance.snapshot().final_wave_damage == 40 and battle.performance.snapshot().base_damage == 115,"repairs never undo objective damage history")
 battle.select_slot(0)
 battle.build_turret("machine_gun")
 battle.select_slot(1)
 battle.build_turret("machine_gun")
 battle.performance.tick()
 check(battle.performance.snapshot().defense_sectors == 2,"real simultaneous western/eastern defenses count")
 battle.queue_free()
 await get_tree().process_frame
 battle = arena(20)
 # Registered real rail: per-round accuracy/criticals, per-actor damage and falloff.
 var first: Node2D = battle.spawn_enemy("heavy")
 first.position = Vector2(560,450)
 first.speed = 0
 first.components.find("weapon").receive(55.001,true,true,{},&"manual")
 var second: Node2D = battle.spawn_enemy("scout")
 second.position = Vector2(560,350)
 second.speed = 0
 battle.launch_player_projectile(Vector2.UP)
 shot = battle.projectiles.get_child(0)
 shot.damage = 10
 shot.speed = 1000
 shot.critical = false
 shot.penetration_remaining = 2
 shot.penetration_falloff = .5
 shot.tick(.5)
 data = battle.performance.snapshot()
 check(data.manual_shots == 1 and data.manual_hits == 1 and data.accuracy == 1,"piercing round is one shot and one successful shot")
 check(data.core_hits == 1 and data.critical_hits == 1 and shot.hit_ids.size() == 2,"precision core grants one critical round even when rail hits another actor")
 var engine: Node2D = first.components.find("engine_left")
 engine.receive(100,true,true,{},&"manual")
 first.components.find("engine_right").receive(100,true,true,{},&"manual")
 first.tick(.81)
 data = battle.performance.snapshot()
 check(data.heavy_engines == 2 and data.components == 3 and data.manual_kills == 1,"direct Heavy engines and delayed crash preserve manual finishing ownership")
 check(is_equal_approx(data.manual_damage,305),"crash includes residual effective hull HP once, plus the rail's second-actor packet")
 battle.queue_free()
 await get_tree().process_frame
 battle = arena()
 check(battle.performance.snapshot().manual_shots == 0 and battle.performance.snapshot().components == 0 and battle.performance.snapshot().manual_damage == 0,"restart resets every temporary metric")
 battle.queue_free()
 await get_tree().process_frame

func persistence_contract() -> void:
 SaveManager.new_campaign()
 var low := snapshot(1,.6)
 low.manual_kills = 0
 var receipt := settle(1,true,low)
 check(receipt.stars == 2 and receipt.star_reward == 10 and SaveManager.state.credits == 110,"first 2-star clear pays configured 100+10 only")
 var good := snapshot(1)
 good.seconds = 100
 receipt = settle(1,true,good,"replay")
 check(receipt.stars == 3 and receipt.star_reward == 15 and receipt.reward == 30 and SaveManager.state.frontline == 2,"improved optional replay earns only outstanding milestone and reduced replay income")
 var state := SaveManager.state.duplicate(true)
 check(CampaignManager.resolve(true,1,str(receipt.run_id),{"performance":good}).is_empty() and SaveManager.state == state,"duplicate results cannot regrant milestones or mutate stars")
 var best: Dictionary = SaveManager.state.records["1"].duplicate(true)
 var worse := snapshot(1,.25)
 worse.seconds = 200
 receipt = settle(1,true,worse,"replay")
 check(receipt.star_reward == 0 and receipt.stars == 1 and SaveManager.state.records["1"].best_stars == 3,"worse victory cannot erase best stars or regrant milestones")
 for key in ["best_hp_ratio","fastest_seconds","best_score","best_performance","completed_secondary","star_claims"]:
  check(SaveManager.state.records["1"][key] == best[key],"worse successful attempt preserves each better record")
 var bank: int = SaveManager.state.credits
 receipt = settle(1,false,snapshot(1,0),"replay")
 check(receipt.stars == 0 and receipt.reward == 0 and SaveManager.state.frontline == 2 and SaveManager.state.credits == bank,"failed optional replay never retreats or rewards")
 check(SaveManager.state.records["1"].best_stars == 3 and CampaignManager.territory_state(1) == "CONTROLLED","failed replay preserves controlled territory and previous stars")
 SaveManager.reload_from_disk()
 check(CampaignManager.resolve(true,1,str(receipt.run_id),{"performance":good}).is_empty(),"restart cannot replay a consumed result")
 # Preserve this coherent state for the runner's fresh-process verification.
 var retained := SaveManager.state.duplicate(true)
 var legacy := SaveManager.validate_campaign({"version":1,"frontline":6,"checkpoint":6,"credits":345,"damage_level":3,"records":{"1":{"victories":1,"best_health":900}}})
 check(legacy.frontline == 6 and legacy.checkpoint == 5 and legacy.credits == 345 and legacy.damage_level == 3,"M8 migration preserves old currency/upgrades/checkpoint meanings")
 check(legacy.records["1"].best_stars == 1 and legacy.records["1"].star_claims.is_empty() and legacy.records["1"].best_performance.is_empty(),"historical clear proves one star, not invented HP/accuracy/objective bonuses")
 check(legacy.records["5"].first_clear and legacy.records["5"].best_stars == 1,"implicit cleared legacy territory migrates consistently")
 SaveManager.state.frontline = 6
 SaveManager.state.highest = 9
 SaveManager.state.checkpoints = [1,5]
 SaveManager.state.checkpoint = 5
 SaveManager.persist()
 check(CampaignManager.can_play(8) and not CampaignManager.can_play(9),"previously cleared lost territory can replay; unreached territory remains locked")
 settle(8,false,snapshot(8,0))
 check(SaveManager.state.frontline == 6,"non-frontline deployment is safely forced to replay")
 settle(6,false,snapshot(6,0))
 check(SaveManager.state.frontline == 5,"frontline defeat still retreats to chapter floor")
 settle(5,false,snapshot(5,0))
 check(SaveManager.state.frontline == 5,"frontline defeat cannot cross secured floor")
 settle(5,true,snapshot(5),"replay")
 check(SaveManager.state.frontline == 5,"explicit replay at current cleared frontline does not advance")
 settle(5,true,snapshot(5))
 check(SaveManager.state.frontline == 6,"frontline reconquest still advances after optional replay")
 # Atomic outcome failure rolls back bests, credit and milestone ledger together.
 SaveManager.new_campaign()
 var token := CampaignManager.begin_mission(1)
 var before := SaveManager.state.duplicate(true)
 DirAccess.make_dir_absolute(SaveManager.PATH+".tmp")
 check(CampaignManager.resolve(true,1,token,{"performance":snapshot(1)}).is_empty() and SaveManager.state == before,"failed save rolls back full performance/reward transaction")
 DirAccess.remove_absolute(SaveManager.PATH+".tmp")
 receipt = CampaignManager.resolve(true,1,token,{"performance":snapshot(1)})
 check(receipt.reward == 125 and receipt.star_reward == 25,"retry after write recovery grants both milestones exactly once")
 SaveManager.state = retained
 check(SaveManager.persist(),"persist coherent record for fresh process")

func finish() -> void:
 if not rows.is_empty() and "--verify-performance" not in OS.get_cmdline_user_args():
  var file := FileAccess.open("user://performance_scenarios.json",FileAccess.WRITE)
  file.store_string(JSON.stringify({"checks":checks,"failures":failures,"fixture":"synthetic star/transaction witnesses plus actual projectile/actor attribution; no Android hardware","cases":rows},"  "))
 print("MISSION PERFORMANCE: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
