extends Node
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func _ready() -> void:
 run.call_deferred()
func run() -> void:
 SaveManager.new_campaign()
 var battle := preload("res://scenes/gameplay.tscn").instantiate()
 add_child(battle)
 battle.set_physics_process(false)
 battle.spawner.timer = 10000
 check(Engine.time_scale == 1 and not battle.has_method("toggle_speed"),"No global time-scale trick or selectable speed API")
 check(battle.effective_speed() == 1,"Mission begins at standardized normal speed")
 battle.select_slot(0)
 battle.build_turret("machine_gun")
 var gun: Node2D = battle.placed[0]
 check(battle.effective_speed() == 1.0,"Building a turret keeps normal speed")
 battle.close_build_mode()
 check(battle.effective_speed() == 1,"Closing build UI restores normal")
 var scout: Node2D = battle.spawn_enemy("scout")
 scout.speed = 0
 scout.position = gun.position+Vector2(140,0)
 var angle: float = gun.barrel_angle
 gun.tick(.05)
 check(gun.target == scout and gun.shots_fired == 0 and gun.acquisition_remaining > 0,"Acquisition has a real nonzero delay")
 check(absf(angle_difference(angle,gun.barrel_angle)) <= deg_to_rad(float(gun.definition.turn_degrees))*.05+.0001,"Tracking rotation is physically rate limited")
 for frame in 6:
  gun.tick(1.0/60)
 check(gun.shots_fired == 0,"Acquired but unaligned weapon waits for barrel direction")
 for frame in 25:
  gun.tick(1.0/60)
 check(gun.shots_fired > 0 and battle.projectiles.get_child_count() > 0,"Aligned target receives actual projectiles")
 var before: int = gun.shots_fired
 scout.position = gun.position+Vector2(-140,0)
 gun.tick(.05)
 check(gun.shots_fired == before,"Cross-lane movement cannot be followed by instantaneous fire")
 scout.queue_free()
 await get_tree().process_frame
 gun.tick(.05)
 check(gun.target == null,"Freed target clears safely before typed validation")
 var stealth: Node2D = battle.spawn_enemy("stealth")
 stealth.position = gun.position+Vector2(0,-100)
 gun.tick(.2)
 check(gun.target == null,"Cloaked drone evades acquisition")
 stealth.apply_disable(1)
 gun.tick(.05)
 check(gun.target == stealth,"EMP reveals stealth but still requires acquisition")
 stealth.queue_free()
 await get_tree().process_frame
 for kind in CampaignManager.enemies:
  var unit: Node2D = battle.spawn_enemy(str(kind))
  var expected := minf(float(CampaignManager.balance.maximum_drone_speed),float(CampaignManager.enemies[kind].speed)*float(CampaignManager.balance.movement_multiplier))
  check(is_equal_approx(unit.speed,expected),"Central movement tuning applies to "+str(kind))
  unit.tick(.1)
  check(not unit.ended and is_finite(unit.position.x),"Every enemy class moves with valid AI: "+str(kind))
  unit.queue_free()
 await get_tree().process_frame
 var burst: Node2D = battle.spawn_enemy("scout")
 var integral: float = burst.brain.movement_time(0,8)
 var partitioned := 0.0
 for index in 480:
  partitioned += burst.brain.movement_time(index/60.0,(index+1)/60.0)
 check(is_equal_approx(integral,partitioned) and integral > 8,"Acceleration integrates identically over partitioned simulation time")
 burst.brain.elapsed = 1.2
 check(burst.brain.burst_warning(),"Short acceleration is telegraphed before the burst")
 burst.apply_disable(1)
 check(not burst.brain.burst_warning(),"EMP suppresses acceleration warning while disabled")
 var heavy: Node2D = battle.spawn_enemy("heavy")
 heavy.position = Vector2(600,350)
 heavy.hit(100,true,false)
 var standard_damage: float = 300-heavy.health
 heavy.hit(100,true,true)
 check(standard_damage == 80 and heavy.health == 120,"Heavy armor reduces standard damage; AP bypasses armor deterministically")
 battle.queue_free()
 await get_tree().process_frame
 var spawner := preload("res://scripts/game/wave_spawner.gd").new()
 add_child(spawner)
 spawner.configure([{"interval":1.0,"burst_size":3,"burst_gap":.1,"groups":[{"enemy":"scout","count":3,"formation":"pincer"}]}],15,3)
 var routes: Array[int] = []
 spawner.spawn_requested.connect(func(_kind: String,path: int): routes.append(path))
 spawner.start_early()
 spawner.tick(.21,0)
 check(routes == [0,2,0] and spawner.total_spawned == 3,"Burst scheduler creates concurrent pincer threats on opposite routes")
 spawner.tick(.1,0)
 check(spawner.finished,"Burst scheduler completes after real live count reaches zero")
 spawner.queue_free()
 await get_tree().process_frame
 print("M1 MECHANICS: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
