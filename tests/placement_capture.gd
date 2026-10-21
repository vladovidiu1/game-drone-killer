extends Node
# Actual native controls/renderer. Mission access is staged; construction/moves use real funds.
var app: Control
var directory := "/tmp/frontline-m6-native"
var checks := 0
var failures := 0
var frames: Array = []

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("NATIVE PLACEMENT: "+message)

func _ready() -> void:
 run.call_deferred()

func capture(name: String) -> void:
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var image := get_viewport().get_texture().get_image()
 check(image != null and not image.is_empty(),"native renderer supplies pixels")
 check(image.save_png(directory.path_join(name+".png")) == OK,"native frame saved")
 frames.append({"capture":name,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"size":[get_tree().root.size.x,get_tree().root.size.y]})
 print("PLACEMENT CAPTURE: "+name)

func touch(index: int, point: Vector2, pressed: bool) -> void:
 var event := InputEventScreenTouch.new()
 event.index = index
 event.position = point
 event.pressed = pressed
 get_viewport().push_input(event,true)
 await get_tree().process_frame

func tap(button: Button) -> void:
 if app.hud.shop_scroll.is_ancestor_of(button):
  app.hud.shop_scroll.ensure_control_visible(button)
 await get_tree().process_frame
 await get_tree().process_frame
 var point := button.get_global_rect().get_center()
 await touch(3,point,true)
 await touch(3,point,false)

func slot(battle: Node2D, index: int) -> void:
 var point: Vector2 = battle.get_global_transform_with_canvas()*battle.slots[index]
 await touch(3,point,true)
 await touch(3,point,false)

func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--output="):
   directory = arg.trim_prefix("--output=")
 if DisplayServer.get_name() == "headless":
  push_error("Native placement requires a display")
  get_tree().quit(1)
  return
 DirAccess.make_dir_recursive_absolute(directory)
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 for dimensions in [Vector2i(1280,720),Vector2i(1600,720),Vector2i(1280,600),Vector2i(1024,768)]:
  get_tree().root.size = dimensions
  SaveManager.new_campaign()
  SaveManager.state.frontline = 3
  SaveManager.state.highest = 3
  app._briefing(3)
  await capture("briefing_%dx%d" % [dimensions.x,dimensions.y])
  app._play(3)
  await get_tree().process_frame
  var battle: Node2D = app.battle
  battle.set_physics_process(false)
  battle.player_turret.rng.seed = 606
  battle.select_slot(0)
  check(battle.build_turret("machine_gun") and battle.upgrade_selected(),"native scenario ordinary paid construction and upgrade")
  var turret: Node2D = battle.placed[0]
  var identity: int = turret.get_instance_id()
  battle.close_build_mode()
  await slot(battle,0)
  check(battle.selected_slot == 0,"native slot touch selects source")
  var controls: Control = app.hud.placement_controls
  await tap(controls.right_button)
  check(is_equal_approx(turret.bearing,-PI/4),"native orientation control changes real arc")
  await tap(controls.left_button)
  await tap(controls.move_button)
  check(battle.movement.source == 0 and not battle.movement.active,"native Move enters destination selection")
  await slot(battle,6)
  check(battle.movement.destination == 6 and not controls.confirm_button.disabled,"native empty-slot touch chooses destination")
  await capture("destination_%dx%d" % [dimensions.x,dimensions.y])
  var aim_point: Vector2 = battle.get_global_transform_with_canvas()*Vector2(160,240)
  var fire_point: Vector2 = app.hud.player_panel.fire_button.get_global_rect().get_center()
  await touch(1,aim_point,true)
  await touch(2,fire_point,true)
  check(battle.player_controls.aim_finger == 1 and battle.player_turret.trigger_held,"two-finger aim/fire active during selection")
  await tap(controls.confirm_button)
  check(battle.movement.active and turret.redeploying and battle.player_turret.trigger_held,"confirm transports source without dropping held FIRE")
  var enemy: Node2D = battle.spawn_enemy("heavy")
  enemy.position = Vector2(560,430)
  enemy.speed = 0
  var drag := InputEventScreenDrag.new()
  drag.index = 1
  var desired: Vector2 = (enemy.position-battle.player_turret.aim_point)/float(battle.player_turret.definition.touch_sensitivity)
  drag.position = aim_point+desired*battle.scale
  get_viewport().push_input(drag,true)
  await get_tree().process_frame
  battle.spawner.tick(battle.spawner.warning_remaining,0)
  battle.start_wave()
  for index in 60:
   battle.simulate(1.0/60)
   if index%4 == 0:
    await get_tree().process_frame
  check(battle.player_turret.hits > 0 and turret.shots_fired == 0,"manual rounds damage drones while source cannot fire")
  await tap(app.hud.coverage_button)
  check(battle.coverage_visible,"native tactical overlay toggles")
  await capture("transport_%dx%d" % [dimensions.x,dimensions.y])
  await tap(app.hud.pause_button)
  var elapsed: float = battle.movement.elapsed
  battle._physics_process(1)
  check(battle.paused and battle.movement.elapsed == elapsed and not battle.player_turret.trigger_held,"native pause freezes move and clears FIRE")
  await tap(app.hud.pause_button)
  await touch(2,fire_point,false)
  await touch(1,aim_point,false)
  for index in 200:
   battle.simulate(1.0/60)
   if index%4 == 0:
    await get_tree().process_frame
  check(not battle.movement.active and battle.placed[0] == null and battle.placed[6] == turret and turret.get_instance_id() == identity and turret.level == 2,"native move completes as one leveled turret")
  await slot(battle,6)
  await capture("elevated_%dx%d" % [dimensions.x,dimensions.y])
  var viewport := get_viewport().get_visible_rect()
  for control in [app.hud.player_panel.fire_button,app.hud.player_panel.reload_button,app.hud.ability_buttons.repair,app.hud.pause_button,app.hud.close_button,app.hud.coverage_button]:
   check(viewport.encloses(control.get_global_rect()),"controls stay inside native viewport")
  app._map()
  await get_tree().process_frame
 var file := FileAccess.open(directory.path_join("metrics.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures,"renderer":RenderingServer.get_video_adapter_name(),"fixture":"M3 access + one stationary Heavy staged for manual-hit coverage; real first wave running; no research or BC injection; paid MG L2 move 58 BC; three independent injected touches; no Android hardware","frames":frames},"  "))
 app.queue_free()
 await get_tree().process_frame
 print("NATIVE PLACEMENT: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
