extends Node
# Capture actual Compatibility-renderer frames, never composited mockups.
var app: Control
var directory := "user://g1-captures"
var failures := 0

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
 check(picture != null and not picture.is_empty(),"Native renderer must provide a real frame")
 if picture != null and not picture.is_empty():
  check(picture.save_png(directory.path_join(filename+".png")) == OK,"Native capture can be written")
  print("CAPTURE: "+directory.path_join(filename+".png"))

func run() -> void:
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--output="):
   directory = argument.trim_prefix("--output=")
 check(DisplayServer.get_name() != "headless","Visual capture requires X11/Wayland and a real renderer")
 if failures:
  get_tree().quit(1)
  return
 DirAccess.make_dir_recursive_absolute(directory)
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 SaveManager.new_campaign()
 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 await get_tree().process_frame
 await capture("main_menu")
 app._play(1)
 await get_tree().process_frame
 var battle: Node2D = app.battle
 battle.set_physics_process(false)
 for pair in [[2,"machine_gun"],[3,"cannon"],[4,"machine_gun"]]:
  battle.select_slot(int(pair[0]))
  check(battle.build_turret(str(pair[1])),"Demo defenses use the actual mission budget")
 battle.close_build_mode()
 battle.start_wave()
 for frame in range(1200):
  if battle.spawner.intermission:
   battle.start_wave()
  var target: Node2D = null
  for enemy in battle.drones.get_children():
   if not enemy.ended and enemy.position.distance_to(battle.player_turret.position) < 395:
    target = enemy
    break
  if target != null:
   battle.player_controls.aim_at(target.position)
  battle.player_controls.set_fire(&"capture",target != null)
  battle.simulate(1.0/60.0)
  await get_tree().process_frame
  if frame > 150 and battle.player_turret.shots_fired > 0 and battle.shots_fired > battle.player_turret.shots_fired and battle.living_count() >= 2 and battle.view.effects.size() > 0:
   break
 check(battle.player_turret.shots_fired > 0 and battle.living_count() > 0,"Demo is a live mission with real manual and automatic attacks")
 await capture("outpost_alpha")
 var explosion_seen := false
 for frame in range(240):
  if battle.spawner.intermission:
   battle.start_wave()
  for enemy in battle.drones.get_children():
   if not enemy.ended and enemy.position.distance_to(battle.player_turret.position) < 395:
    battle.player_controls.aim_at(enemy.position)
    battle.player_controls.set_fire(&"capture",true)
    break
  battle.simulate(1.0/60.0)
  await get_tree().process_frame
  for effect in battle.view.effects:
   if effect.kind == "blast" and float(effect.age) >= .15 and float(effect.age) <= .35:
    explosion_seen = true
    break
  if explosion_seen:
   break
 check(explosion_seen,"Explosion capture comes from an actual destroyed drone")
 await capture("outpost_alpha_fx")
 battle.select_slot(0)
 await capture("outpost_alpha_build")
 battle.close_build_mode()
 get_tree().root.size = Vector2i(1600,720)
 await get_tree().process_frame
 await capture("outpost_alpha_wide")
 check(is_equal_approx(battle.scale.x,battle.scale.y),"Wide displays preserve sprite proportions")
 var motion := InputEventMouseMotion.new()
 motion.position = battle.get_global_transform_with_canvas()*Vector2(560,300)
 get_viewport().push_input(motion,true)
 await get_tree().process_frame
 check(battle.player_turret.aim_point.distance_to(Vector2(560,300)) < 1.0,"Wide-screen mouse aiming uses the centered battlefield transform")
 for held in [true,false]:
  var click := InputEventMouseButton.new()
  click.button_index = MOUSE_BUTTON_LEFT
  click.position = app.hud.pause_button.get_global_rect().get_center()
  click.pressed = held
  get_viewport().push_input(click,true)
  await get_tree().process_frame
 check(battle.paused and not battle.player_turret.trigger_held,"Native pause UI remains clickable and clears held firing on wide screens")
 app.queue_free()
 await get_tree().process_frame
 print("NATIVE VISUAL CAPTURE: %d failures" % failures)
 get_tree().quit(1 if failures else 0)
