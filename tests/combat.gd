extends Node
const BATTLE := preload("res://scenes/gameplay.tscn")
var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
 checks += 1
 if condition:
  print("PASS: "+message)
 else:
  failures += 1
  push_error("FAIL: "+message)

func arena() -> Node2D:
 var battle = BATTLE.instantiate()
 add_child(battle)
 battle.set_physics_process(false)
 battle.spawner.timer = 10000.0
 return battle

func _ready() -> void:
 run.call_deferred()

func run() -> void:
 SaveManager.new_campaign()
 var battle := arena()
 check(battle.health == 1000 and battle.slots.size() == 5, "1000 HP base and five turret slots")
 check(not battle.build_turret("machine_gun"), "purchase requires selected slot")
 battle.select_slot(0)
 check(not battle.build_turret("unknown"), "unknown turret rejected")
 check(battle.build_turret("machine_gun") and battle.credits == 400, "Machine Gun costs 100")
 check(not battle.build_turret("cannon") and battle.credits == 400, "occupied slot cannot be purchased twice")
 var turret: Node2D = battle.placed[0]
 check(is_equal_approx(turret.damage_value(),10) and is_equal_approx(turret.range_value(),230), "Machine Gun base stats match specification")
 var first: Node2D = battle.spawn_enemy("scout")
 var second: Node2D = battle.spawn_enemy("scout")
 first.position = Vector2(360,250)
 second.position = Vector2(365,250)
 first.distance_remaining = 300
 second.distance_remaining = 100
 check(turret.acquire_target() == second, "target most advanced enemy within range")
 first.distance_remaining = 100
 check(turret.acquire_target() == first, "spawn order breaks targeting ties")
 first.position = Vector2(950,100)
 check(turret.acquire_target() == second, "out-of-range enemies excluded")
 turret.tick(0.25)
 check(battle.projectiles.get_child_count() == 1 and turret.shots_fired == 1, "target acquisition fires a real projectile")
 var shot: Node2D = battle.projectiles.get_child(0)
 shot.tick(0.2)
 check(shot.consumed and second.health == 30, "swept projectile hit applies 10 damage")
 shot.tick(0.2)
 shot.impact()
 check(second.health == 30 and battle.impacts == 1, "consumed projectile cannot damage twice")
 var before: int = battle.credits
 second.hit(100)
 second.hit(100)
 check(battle.credits == before+7 and battle.kills == 1, "Scout reward paid once after destruction")
 check(battle.upgrade_selected() and turret.level == 2 and battle.credits == before+7-65, "upgrade deducts credits and increments level")
 check(is_equal_approx(turret.damage_value(),13.5) and turret.range_value() == 242, "upgrade improves damage and range")
 check(battle.upgrade_selected() and turret.level == 3, "second upgrade reaches level cap")
 check(not battle.upgrade_selected(), "maximum level prevents further upgrades")
 battle.select_slot(1)
 check(not battle.build_turret("missile"), "unaffordable turret rejected")
 check(battle.build_turret("cannon") and battle.placed[1].definition.damage == 50, "Cannon builds for 200 with configured damage")
 battle.queue_free()
 await get_tree().process_frame

 battle = arena()
 battle.select_slot(0)
 check(battle.build_turret("missile") and battle.credits == 150, "Missile Launcher costs 350")
 var heavy: Node2D = battle.spawn_enemy("heavy")
 var scout: Node2D = battle.spawn_enemy("scout")
 var outside: Node2D = battle.spawn_enemy("assault")
 heavy.position = Vector2(350,250)
 scout.position = Vector2(390,250)
 outside.position = Vector2(450,250)
 battle.launch_projectile(battle.placed[0],heavy)
 shot = battle.projectiles.get_child(0)
 shot.tick(0.2)
 check(heavy.health == 240 and scout.ended and outside.health == 100, "missile splash damages each enemy inside 75 radius only once")
 shot.impact()
 check(heavy.health == 240 and battle.kills == 1 and battle.credits == 157, "missile direct target and kill reward are not duplicated")
 heavy.hit(500)
 outside.hit(500)
 check(battle.credits == 210, "Heavy and Assault rewards are 40 and 13")
 check(battle.view.effects.size() > 0, "hits and destruction create combat effects")
 battle.queue_free()
 await get_tree().process_frame

 battle = arena()
 var enemy: Node2D = battle.spawn_enemy("scout",0)
 var start: Vector2 = enemy.position
 var remaining: float = enemy.distance_remaining
 enemy.tick(0.25)
 check(is_equal_approx(remaining-enemy.distance_remaining,45), "Scout travels 180 nominal path units per second")
 check(enemy.position.y > start.y, "enemies enter from the top and move down")
 battle.set_paused(true)
 var frozen: Vector2 = enemy.position
 var timer: float = battle.spawner.timer
 battle._physics_process(0.25)
 check(enemy.position == frozen and battle.spawner.timer == timer, "pause freezes movement and wave scheduler")
 check(not battle.start_wave(), "paused battle cannot start waves")
 battle.select_slot(0)
 check(not battle.build_turret("machine_gun"), "paused battle cannot purchase")
 battle.set_paused(false)
 remaining = enemy.distance_remaining
 battle._physics_process(0.25)
 check(battle.effective_speed() == 1 and is_equal_approx(remaining-enemy.distance_remaining,45), "normal speed uses unscaled movement")
 check(is_equal_approx(timer-battle.spawner.timer,0.25), "normal speed uses the same wave delta")
 check(not battle.has_method("toggle_speed"), "combat speed selection API removed")
 enemy.tick(20)
 var hp: int = battle.health
 enemy.tick(20)
 check(hp == 975 and battle.health == hp, "Scout breach deals 25 base damage once")
 var assault: Node2D = battle.spawn_enemy("assault")
 var tank: Node2D = battle.spawn_enemy("heavy")
 assault.tick(20)
 tank.tick(30)
 check(battle.health == 825, "Assault and Heavy breaches deal 50 and 100")
 battle.queue_free()
 await get_tree().process_frame

 battle = arena()
 check(not battle.start_wave(), "early start cannot skip radar warning")
 battle.spawner.tick(6,0)
 check(battle.start_wave() and battle.spawner.wave == 0, "early start begins first wave")
 check(not battle.start_wave(), "early start cannot overlap active wave")
 var order: Array[String] = []
 var seen_paths: Array[int] = []
 battle.spawner.spawn_requested.connect(func(kind: String, path_index: int):
  order.append(kind)
  seen_paths.append(path_index))
 for i in 20000:
  if battle.finished:
   break
  if battle.spawner.intermission:
   battle.start_wave()
  # Eliminate through the ordinary damage/reward lifecycle to isolate scheduling.
  for drone in battle.drones.get_children():
   drone.hit(1000)
  battle.simulate(1.0/60.0)
  await get_tree().process_frame
 check(battle.finished and battle.health == 1000, "wave scheduler completes all waves")
 var expected_count := 0
 var expected_reward := 0
 for wave in battle.mission_data.waves:
  for group in wave.groups:
   expected_count += int(group.count)
   expected_reward += int(group.count)*int(CampaignManager.enemies[str(group.enemy)].reward)
 check(order.size() == expected_count, "all configured M1 wave enemies spawn exactly once")
 check(seen_paths.has(0) and seen_paths.has(1) and seen_paths.has(2), "wave spawns use all configured entry paths")
 check(battle.earned == expected_reward, "full enemy roster pays configured bounty exactly once")
 battle.queue_free()
 await get_tree().process_frame
 print("COMBAT: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
