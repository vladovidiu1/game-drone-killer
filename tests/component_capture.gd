extends Node
# Staged access/positions; actual input, cannon timing, swept projectiles and rewards.
var app: Control
var directory := "/tmp/frontline-components"
var checks := 0
var failures := 0
var frames: Array = []

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("NATIVE COMPONENTS: "+message)

func _ready() -> void:
 run.call_deferred()

func capture(name: String) -> void:
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var picture := get_viewport().get_texture().get_image()
 check(picture.save_png(directory.path_join(name+".png")) == OK,"native frame saved")
 frames.append({"capture":name,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"size":[get_tree().root.size.x,get_tree().root.size.y]})
 print("COMPONENT CAPTURE: "+name)

func mouse(battle: Node2D, point: Vector2, pressed: bool) -> void:
 var event := InputEventMouseButton.new()
 event.button_index = MOUSE_BUTTON_LEFT
 event.pressed = pressed
 event.position = battle.get_global_transform_with_canvas()*point
 get_viewport().push_input(event,true)
 await get_tree().process_frame

func shoot_component(battle: Node2D, part: Node2D) -> void:
 # Fixture steering supplies explicit mouse intentions, never gameplay auto aim.
 await mouse(battle,part.point(),true)
 check(battle.player_turret.trigger_held,"native field click holds real manual FIRE")
 for index in 400:
  if part.broken or battle.finished:
   break
  var motion := InputEventMouseMotion.new()
  var desired: Vector2 = part.point()
  var unit: Node2D = part.rig.enemy
  if unit.speed > 0 and unit.waypoint < unit.route.size():
   desired += unit.position.direction_to(unit.route[unit.waypoint])*unit.effective_speed()*desired.distance_to(battle.player_turret.position)/float(battle.player_turret.definition.projectile_speed)
  motion.position = battle.get_global_transform_with_canvas()*desired
  get_viewport().push_input(motion,true)
  battle.simulate(1.0/60)
  if index%12 == 0:
   await get_tree().process_frame
 await mouse(battle,part.point(),false)
 check(part.broken,"actual mouse-fired cannon destroys chosen visible component")
 check(not battle.player_turret.trigger_held,"native mouse release stops continuous fire")

func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--output="):
   directory = arg.trim_prefix("--output=")
 if DisplayServer.get_name() == "headless":
  push_error("Native component capture requires real Compatibility renderer")
  get_tree().quit(1)
  return
 DirAccess.make_dir_recursive_absolute(directory)
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 for dimensions in [Vector2i(1280,720),Vector2i(1600,720),Vector2i(1280,600),Vector2i(1024,768)]:
  get_tree().root.size = dimensions
  SaveManager.new_campaign()
  SaveManager.state.frontline = 20
  SaveManager.state.highest = 20
  app._play(20)
  await get_tree().process_frame
  var battle: Node2D = app.battle
  battle.set_physics_process(false)
  battle.player_turret.rng.seed = 707
  var enemy: Node2D = battle.spawn_enemy("heavy")
  enemy.position = Vector2(500,430)
  enemy.speed = 0
  var engine: Node2D = enemy.components.find("engine_left")
  battle.player_controls.aim_at(engine.point())
  await capture("target_%dx%d" % [dimensions.x,dimensions.y])
  await shoot_component(battle,engine)
  check(battle.component_hits > 0 and not enemy.components.falling,"real precision damage cripples one engine without forced kill")
  await capture("engine_disabled_%dx%d" % [dimensions.x,dimensions.y])
  await shoot_component(battle,enemy.components.find("engine_right"))
  check(enemy.components.falling and not enemy.ended,"second engine starts actual deferred crash")
  var credits: int = battle.credits
  await capture("crashing_%dx%d" % [dimensions.x,dimensions.y])
  battle.simulate(.85)
  check(battle.kills == 1 and battle.credits == credits+enemy.reward,"native crash earns normal reward once")
  await get_tree().process_frame
  # Paid secondary turret operates while manual cannon destroys generator.
  battle.select_slot(0)
  check(battle.build_turret("machine_gun"),"secondary defense still builds using ordinary mission credits")
  battle.close_build_mode()
  enemy = battle.spawn_enemy("shield")
  enemy.position = Vector2(650,430)
  enemy.speed = 0
  var scout: Node2D = battle.spawn_enemy("scout")
  scout.position = battle.placed[0].position+Vector2(0,-120)
  scout.speed = 0
  await shoot_component(battle,enemy.components.find("generator"))
  check(not enemy.brain.shield_active() and battle.placed[0].shots_fired > 0,"generator collapse and real automatic fire operate together")
  await capture("shield_destroyed_%dx%d" % [dimensions.x,dimensions.y])
  app._map()
  await get_tree().process_frame
 # Large real boss surface, actual core shot and phase-driven articulated armor.
 get_tree().root.size = Vector2i(1280,720)
 app._play(20)
 await get_tree().process_frame
 var battle: Node2D = app.battle
 battle.set_physics_process(false)
 var boss: Node2D = battle.spawn_enemy("assault_carrier")
 boss.position = Vector2(560,350)
 boss.speed = 0
 boss.health = boss.maximum_health*.60 # declared phase presentation fixture
 boss.tick(.01)
 var core: Node2D = boss.components.find("core")
 battle.player_controls.aim_at(core.point())
 await mouse(battle,core.point(),true)
 for index in 75:
  battle.simulate(1.0/60)
  if index%10 == 0:
   await get_tree().process_frame
 await mouse(battle,core.point(),false)
 check(battle.weakpoint_hits > 0 and boss.brain.phase_index == 1,"native direct core hits and actual boss phase remain functional")
 await capture("boss_core_open")
 boss.components.clock = 6.5
 battle.view.tick(.01)
 await capture("boss_core_closed")
 app._play(12)
 await get_tree().process_frame
 battle = app.battle
 battle.set_physics_process(false)
 var moving: Node2D = battle.spawn_enemy("heavy",0)
 moving.position = moving.route[moving.route.size()-2]
 moving.waypoint = moving.route.size()-1
 moving.rotation = .24 # explicit pose fixture; path/speed/controller stay real
 var before_position: Vector2 = moving.position
 await shoot_component(battle,moving.components.find("engine_left"))
 check(moving.position.distance_to(before_position) > 10 and not moving.ended,"native moving/rotated target receives actual precision collision")
 await capture("moving_rotated_engine")
 var file := FileAccess.open(directory.path_join("metrics.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures,"renderer":RenderingServer.get_video_adapter_name(),"frames":frames,"fixture":"M20 access and stationary units staged; no BC or research injection; real mouse intentions, manual magazine/projectiles, paid MG, real crash/reward; final boss HP set to60% for phase presentation; M12 Heavy follows actual final path segment at normal speed with staged0.24rad pose and assisted mouse lead; no Android hardware"},"  "))
 app.queue_free()
 await get_tree().process_frame
 print("NATIVE COMPONENTS: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
