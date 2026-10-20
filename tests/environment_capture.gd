extends Node
# Real native Compatibility frames. Artificial deployment access is a visual-only
# fixture; complete campaign combat is tested separately by full_campaign.tscn.
var app: Control
var directory := "user://g2-captures"
var failures := 0
var shots := 0

func check(value: bool, message: String) -> void:
 if not value:
  failures += 1
  push_error(message)

func _ready() -> void:
 run.call_deferred()

func capture(filename: String) -> void:
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var picture := get_viewport().get_texture().get_image()
 check(picture != null and not picture.is_empty(),"Native real-renderer frame exists")
 if picture != null and not picture.is_empty():
  check(picture.save_png(directory.path_join(filename+".png")) == OK,"Capture writes successfully")
  print("CAPTURE: "+filename)

func run() -> void:
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--output="):
   directory = argument.trim_prefix("--output=")
 check(DisplayServer.get_name() != "headless","Native environment capture requires a display, not dummy headless")
 if failures:
  get_tree().quit(1)
  return
 DirAccess.make_dir_recursive_absolute(directory)
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 SaveManager.new_campaign()
 SaveManager.state.frontline = 25
 SaveManager.state.highest = 25
 SaveManager.settings.reduced_environment_effects = false
 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 await get_tree().process_frame
 for mission_id in range(1,26):
  app._play(mission_id)
  await get_tree().process_frame
  var battle: Node2D = app.battle
  check(battle != null and battle.mission_id == mission_id,"Native mission deployment %d" % mission_id)
  battle.set_physics_process(false)
  battle.select_slot(0)
  check(battle.build_turret("machine_gun"),"Native mission buys actual automatic defense")
  battle.close_build_mode()
  battle.start_wave()
  # Live wave simulation, actual damage/tracers, no composited sprites.
  for frame in range(230):
   for enemy in battle.drones.get_children():
    if not enemy.ended:
     battle.player_controls.aim_at(enemy.position)
     battle.player_controls.set_fire(&"capture",true)
     break
   battle.simulate(1.0/30.0)
   if frame%8 == 0:
    await get_tree().process_frame
   if frame > 100 and battle.living_count() >= 2 and battle.player_turret.shots_fired > 0:
    break
  check(battle.living_count() > 0 and battle.player_turret.shots_fired > 0,"Live drones and manual shots in environment %d" % mission_id)
  shots += battle.player_turret.shots_fired
  await capture("mission_%02d" % mission_id)
  if mission_id == 4:
   # Same art/geometry with reduced animated draw branch, shown explicitly.
   battle.view.environment.reduced = true
   battle.view.environment.queue_redraw()
   await capture("mission_04_low_effects")
  if mission_id == 5:
   battle.select_slot(0)
   await capture("mission_05_build")
   battle.close_build_mode()
  if mission_id == 9:
   get_tree().root.size = Vector2i(1600,720)
   await get_tree().process_frame
   await capture("mission_09_wide")
   check(is_equal_approx(battle.scale.x,battle.scale.y),"Wide camera preserves uniform battlefield scaling")
   get_tree().root.size = Vector2i(1280,720)
  battle.player_controls.clear()
 app._settings()
 await capture("settings")
 app.queue_free()
 await get_tree().process_frame
 print("NATIVE ENVIRONMENTS: 25 missions, %d real manual shots, %d failures" % [shots,failures])
 get_tree().quit(1 if failures else 0)
