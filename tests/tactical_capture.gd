extends Node
# Native Compatibility-renderer evidence; staged access/research, paid defenses and real attacks.
var app: Control
var directory := "/tmp/frontline-m5-native"
var failures := 0
var checks := 0
var metrics: Array = []

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("NATIVE TACTICAL: "+message)

func _ready() -> void:
 run.call_deferred()

func capture(name: String) -> void:
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var image := get_viewport().get_texture().get_image()
 check(image != null and not image.is_empty(),"renderer returns pixels")
 check(image.save_png(directory.path_join(name+".png")) == OK,"capture saved")
 metrics.append({"capture":name,"size":[get_tree().root.size.x,get_tree().root.size.y],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
 print("TACTICAL CAPTURE: "+name)

func touch(index: int, point: Vector2, held: bool) -> void:
 var event := InputEventScreenTouch.new()
 event.index = index
 event.position = point
 event.pressed = held
 get_viewport().push_input(event,true)
 await get_tree().process_frame

func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--output="):
   directory = arg.trim_prefix("--output=")
 if DisplayServer.get_name() == "headless":
  push_error("Native tactical capture requires a display")
  get_tree().quit(1)
  return
 DirAccess.make_dir_recursive_absolute(directory)
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 SaveManager.new_campaign()
 SaveManager.state.frontline = 12
 SaveManager.state.highest = 12
 for key in SaveManager.state.research:
  SaveManager.state.research[key] = 2
 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 for dimensions in [Vector2i(1280,720),Vector2i(1600,720),Vector2i(1280,600),Vector2i(1024,768)]:
  get_tree().root.size = dimensions
  app._play(12)
  await get_tree().process_frame
  var battle: Node2D = app.battle
  battle.set_physics_process(false)
  battle.attack_seed = 612
  battle.player_turret.rng.seed = 612
  battle.director.configure(battle,612)
  battle.director.forced_pattern = "west_flank"
  battle.director.plans.clear()
  battle.spawner.configure(battle.mission_data.waves,12,battle.mission_data.paths.size(),battle.director)
  app.hud.refresh()
  await capture("radar_%dx%d" % [dimensions.x,dimensions.y])
  var radar_rect: Rect2 = app.hud.radar.get_global_rect()
  check(not app.hud.blocks_pointer(radar_rect.get_center()),"radar does not capture battlefield aiming")
  check(app.hud.wave_button.disabled,"native wave control respects preparation")
  var aim_point: Vector2 = battle.get_global_transform_with_canvas()*Vector2(250,350)
  var fire: Vector2 = app.hud.player_panel.fire_button.get_global_rect().get_center()
  await touch(11,aim_point,true)
  await touch(12,fire,true)
  check(battle.player_controls.aim_finger == 11 and battle.player_turret.trigger_held,"independent aim and FIRE touches work simultaneously")
  var before: Vector2 = battle.player_turret.aim_point
  var drag := InputEventScreenDrag.new()
  drag.index = 11
  drag.position = aim_point+Vector2(50,-30)
  get_viewport().push_input(drag,true)
  await get_tree().process_frame
  check(battle.player_turret.aim_point != before and battle.player_turret.trigger_held,"drag keeps second finger firing")
  await touch(12,fire,false)
  await touch(11,aim_point,false)
  check(not battle.player_turret.trigger_held and battle.player_controls.aim_finger == -1,"release clears both touch owners")
  for index in [0,1,4]:
   battle.select_slot(index)
   check(battle.build_turret("machine_gun" if index == 4 else "cannon"),"native demonstration uses ordinary funds")
  battle.close_build_mode()
  battle.spawner.tick(battle.spawner.warning_remaining,0)
  check(battle.start_wave(),"launch after radar interval")
  for frame in range(60*12):
   preload("res://tests/m1_pilot.gd").aim(battle)
   battle.simulate(1.0/60)
   if frame%4 == 0:
    await get_tree().process_frame
   if battle.player_turret.hits > 1 and battle.shots_fired > battle.player_turret.shots_fired and battle.living_count() > 2:
    break
  check(battle.player_turret.hits > 0 and battle.shots_fired > battle.player_turret.shots_fired,"actual manual and secondary attacks under tactical HUD")
  await capture("contacts_%dx%d" % [dimensions.x,dimensions.y])
  var viewport := get_viewport().get_visible_rect()
  for control in [app.hud.player_panel.fire_button,app.hud.wave_button,app.hud.pause_button,app.hud.ability_buttons.repair]:
   check(viewport.encloses(control.get_global_rect()),"controls remain inside native viewport")
  battle.set_paused(true)
  check(not battle.player_turret.trigger_held,"pause clears firing after actual attacks")
  app._map()
  await get_tree().process_frame
 var file := FileAccess.open(directory.path_join("metrics.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"renderer":RenderingServer.get_video_adapter_name(),"fixture":"M12 access + tier2 research; ordinary battle funds; seeded west flank; injected two-finger native input; no Android hardware","checks":checks,"failures":failures,"frames":metrics},"  "))
 app.queue_free()
 await get_tree().process_frame
 print("NATIVE TACTICAL: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
