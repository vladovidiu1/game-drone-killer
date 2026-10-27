extends Node
const APP := preload("res://scenes/main.tscn")
var app: Control
var checks := 0
var failures := 0
var records: Array = []
var directory := ""
var native_frames: Array = []
var archived_stats: Dictionary = {}

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("TUTORIAL: "+message)

func _ready() -> void:
 run.call_deferred()

func buttons(node: Node) -> Array[Button]:
 var result: Array[Button] = []
 for child in node.get_children():
  if child is Button:
   result.append(child)
  result.append_array(buttons(child))
 return result

func action(text: String) -> Button:
 for button in buttons(app):
  if button.text == text:
   return button
 return null

func frames() -> void:
 await get_tree().process_frame
 await get_tree().process_frame

func touch(index: int, point: Vector2, pressed: bool) -> void:
 var event := InputEventScreenTouch.new()
 event.index = index
 event.position = point
 event.pressed = pressed
 get_viewport().push_input(event,true)
 await frames()

func tap(button: Button) -> void:
 await frames()
 await touch(13,button.get_global_rect().get_center(),true)
 await touch(13,button.get_global_rect().get_center(),false)

func mouse(point: Vector2, pressed: bool = false, motion: bool = true) -> void:
 var event: InputEvent = InputEventMouseMotion.new() if motion else InputEventMouseButton.new()
 event.position = point
 if not motion:
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = pressed
 get_viewport().push_input(event,true)
 await frames()

func aim_world(point: Vector2) -> void:
 await mouse(app.battle.get_global_transform_with_canvas()*point)

func start() -> void:
 SaveManager.new_campaign()
 SaveManager.settings.tutorial_status = "unseen"
 SaveManager.save_settings()
 app._briefing(1)
 await frames()
 await tap(action("Start Mission"))
 app.battle.set_physics_process(false)
 await frames()

func native_capture(label: String) -> void:
 if directory.is_empty():
  return
 if label.begins_with("ratings_") or label == "actual_m1_stars":
  await get_tree().create_timer(.75).timeout
 await frames()
 await RenderingServer.frame_post_draw
 var picture := get_viewport().get_texture().get_image()
 check(picture.save_png(directory.path_join(label+".png")) == OK,"native viewport saved")
 native_frames.append({"capture":label,"size":[get_tree().root.size.x,get_tree().root.size.y],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
 print("TUTORIAL CAPTURE: "+label)

func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--output="):
   directory = arg.trim_prefix("--output=")
 if not directory.is_empty():
  if DisplayServer.get_name() == "headless":
   push_error("Tutorial native capture requires a real display")
   get_tree().quit(1)
   return
  DirAccess.make_dir_recursive_absolute(directory)
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 if "--verify-tutorial" in OS.get_cmdline_user_args():
  check(SaveManager.settings.tutorial_status == "skipped","fresh process remembers skip")
  check(SaveManager.state.credits == 0 and SaveManager.state.frontline == 1,"fresh process keeps practice financially inert")
  app = APP.instantiate()
  add_child(app)
  await frames()
  check(not app._tutorial_due(1),"completed/skipped installation is not forced through another campaign tutorial")
  app.queue_free()
  await frames()
  finish()
  return
 app = APP.instantiate()
 add_child(app)
 await frames()
 await start()
 var battle: Node2D = app.battle
 var guide: Node = battle.tutorial
 var token: String = battle.run_id
 check(battle.guided and guide.phase == 0 and app.tutorial_overlay != null,"fresh campaign Start button creates actual composed drill and short introduction")
 check(guide.description().title == "ASTERIA DEFENSE COMMAND" and app.tutorial_overlay.skip_button.visible,"cinematic story identity and visible skip")
 await native_capture("intro")
 await tap(app.tutorial_overlay.next_button)
 check(guide.phase == 1,"intro skip moves into guidance without marking tutorial skipped")
 await native_capture("aim")
 battle.player_controls.aim_at(Vector2(280,460)) # fixture origin, not human input
 for index in 4:
  await aim_world(Vector2(281+index,460))
 battle.simulate(.01)
 check(guide.phase == 1,"sub-threshold movement alone does not complete AIM")
 for index in 5:
  await aim_world(Vector2(285+index,460))
 battle.simulate(.01)
 check(guide.phase == 2 and battle.player_controls.human_aim_movements > 0,"fine-grained desktop motion accumulates into a valid AIM action")
 await native_capture("fire")
 await mouse(battle.get_global_transform_with_canvas()*Vector2(500,420),true,false)
 for index in 180:
  battle.simulate(1.0/60)
  if guide.phase >= 3:
   break
  if index%20 == 0:
   await frames()
 await mouse(Vector2.ZERO,false,false)
 check(guide.practice_hit and guide.phase == 3,"real continuous mouse fire damages the actual training drone")
 check(battle.earned == 0 and battle.kills == 0 and battle.performance.snapshot().manual_damage == 0,"practice actors never fund bounties, manual damage or mission stars")
 await native_capture("reload")
 var key := InputEventKey.new()
 key.keycode = KEY_R
 key.pressed = true
 get_viewport().push_input(key,true)
 await frames()
 check(battle.player_turret.reload_remaining > 0,"actual R starts controlled normal reload")
 battle.set_paused(true)
 var clock: float = guide.clock
 var reload_time: float = battle.player_turret.reload_remaining
 battle._physics_process(1)
 check(guide.clock == clock and battle.player_turret.reload_remaining == reload_time,"pause freezes guided progression and reload")
 battle.set_paused(false)
 for index in 150:
  battle.simulate(1.0/60)
 check(guide.phase == 4 and battle.player_turret.reloads_completed > 0,"completion of the real reload advances the guide")
 await native_capture("build")
 # Real two-finger aim/FIRE + independent construction touch.
 var aim_point: Vector2 = battle.get_global_transform_with_canvas()*Vector2(230,450)
 await touch(7,aim_point,true)
 await touch(8,app.hud.player_panel.fire_button.get_global_rect().get_center(),true)
 var slot: Vector2 = battle.get_global_transform_with_canvas()*battle.slots[0]
 await touch(9,slot,true)
 await touch(9,slot,false)
 await tap(app.hud.build_buttons.machine_gun)
 check(battle.placed[0] != null and battle.player_controls.aim_finger == 7 and battle.player_turret.trigger_held,"independent third touch builds while aim and FIRE remain owned")
 battle.simulate(.01)
 check(guide.phase == 5 and not battle.build_mode and guide.group_spawned,"paid construction begins a different-sector group and restores normal speed")
 await native_capture("sectors")
 var group_sectors: Array = []
 for unit in battle.drones.get_children():
  if unit.has_meta("tutorial_sector"):
   group_sectors.append(unit.get_meta("tutorial_sector"))
 check(group_sectors.size() == 3 and not group_sectors.has(str(battle.mission_data.emplacements[0].sector)),"actual group comes from the opposite defended sector")
 await touch(8,app.hud.player_panel.fire_button.get_global_rect().get_center(),false)
 await touch(7,aim_point,false)
 for index in 1500:
  for unit in battle.drones.get_children():
   if not unit.ended and unit.has_meta("tutorial_group") and unit.get_meta("tutorial_group") and unit.position.distance_to(battle.player_turret.position) < 380:
    battle.player_controls.aim_at(unit.position)
    battle.player_controls.set_fire(&"fixture",true)
    break
  battle.simulate(1.0/60)
  if guide.phase >= 6:
   break
  if index%30 == 0:
   await frames()
 battle.player_controls.clear()
 check(guide.phase == 6,"real group combat advances the flank lesson")
 await touch(9,slot,true)
 await touch(9,slot,false)
 check(battle.build_mode and battle.effective_speed() == 1.0,"selecting the real turret keeps normal speed")
 await native_capture("upgrade")
 await tap(app.hud.upgrade_button)
 battle.simulate(.01)
 check(battle.placed[0].level == 2 and guide.phase == 7 and not battle.build_mode,"actual paid upgrade advances objective lesson and closes the upgrade panel")
 check(battle.spawner.wave == -1 and battle.elapsed == 0 and battle.health == battle.max_health,"guide does not consume normal waves/time or damage the live base")
 await native_capture("objective")
 var guided_time: float = guide.clock
 await tap(app.tutorial_overlay.next_button)
 await frames()
 check(not app.battle.guided and app.battle.run_id == token and not is_instance_valid(app.tutorial_overlay),"complete guide cleans UI and resumes the original persisted mission token")
 check(SaveManager.settings.tutorial_status == "completed" and app.battle.credits == 500 and app.battle.turrets.get_child_count() == 0 and app.battle.player_turret.ammo == 60,"practice supply, layout and magazine reset to ordinary M1 balance")
 check(app.battle.performance.snapshot().manual_shots == 0 and SaveManager.state.credits == 0 and SaveManager.state.records.is_empty(),"practice leaves no rating, record, War Credit or live accuracy carry-over")
 SaveManager.reload_from_disk()
 check(SaveManager.settings.tutorial_status == "completed" and not app._tutorial_due(1),"completed status survives disk reload before any mission victory")
 # Actual ordinary mission follows the guide, with ordinary supply and earned credits.
 battle = app.battle
 battle.set_physics_process(false)
 for index in 20000:
  if battle.finished:
   break
  if index%60 == 0:
   preload("res://tests/m1_pilot.gd").build(battle,"hybrid")
  preload("res://tests/m1_pilot.gd").aim(battle)
  if battle.spawner.intermission:
   battle.start_wave()
  battle.simulate(1.0/60)
  if index%20 == 0:
   await frames()
 await frames()
 check(app.screen == "results" and SaveManager.state.frontline == 2 and SaveManager.state.records["1"].victories == 1,"normal five-wave M1 progression follows guidance through the real result transaction")
 var bank: int = SaveManager.state.credits
 check(bank >= 100 and bank <= 125 and CampaignManager.resolve(true,1,token).is_empty(),"live rewards settle once; no tutorial reward duplication")
 archived_stats = app.result_data.duplicate(true)
 await native_capture("actual_m1_stars")
 # Settings replay is a separate practice session and preserves every campaign field.
 var retained := SaveManager.state.duplicate(true)
 app._settings()
 await frames()
 await tap(action("Replay Tutorial"))
 app.battle.set_physics_process(false)
 check(app.training_only and app.battle.run_id.is_empty(),"Settings replays a reward-free practice mode")
 await tap(app.tutorial_overlay.skip_button)
 check(app.screen == "training_results" and SaveManager.state == retained,"practice skip never settles campaign, first clears or star rewards")
 # Restart before completion creates a fresh drill, with no restart income.
 await start()
 battle = app.battle
 token = battle.run_id
 battle.credits = 0
 battle.tutorial.enter(4)
 battle.simulate(.01)
 check(battle.credits >= 100,"temporary reserve guarantees the first tutorial weapon is affordable")
 app._play(1,"frontline",true)
 app.battle.set_physics_process(false)
 check(app.battle.tutorial.phase == 0 and app.battle.credits == 500 and app.battle.kills == 0 and app.battle.run_id != token,"restart resets the drill and invalidates the old deployment token")
 check(CampaignManager.resolve(true,1,token).is_empty() and SaveManager.state.credits == 0,"abandoned drill token cannot claim a reward")
 var current_identity: int = app.battle.get_instance_id()
 app._guide_finished("completed",null)
 check(app.battle.get_instance_id() == current_identity,"stale tutorial completion cannot replace a newer drill")
 app.battle.simulate(8.01)
 check(app.battle.tutorial.phase == 1,"short cinematic introduction advances automatically")
 # Early construction/upgrade/aim/reload is remembered rather than soft-locking later steps.
 battle = app.battle
 battle.select_slot(0)
 battle.build_turret("machine_gun")
 battle.upgrade_selected()
 battle.close_build_mode()
 var slow_touch_origin := battle.get_global_transform_with_canvas()*Vector2(230,450)
 await touch(7,slow_touch_origin,true)
 for index in 12:
  var drag := InputEventScreenDrag.new()
  drag.index = 7
  drag.position = slow_touch_origin+Vector2(index+1,0)*battle.scale
  get_viewport().push_input(drag,true)
  await frames()
 await touch(7,slow_touch_origin,false)
 check(battle.player_controls.human_aim_movements > 0,"fine-grained owned touch drags also accumulate AIM movement")
 battle.player_turret.ammo = 58
 battle.player_turret.request_reload()
 for index in 130:
  battle.simulate(1.0/60)
 if battle.tutorial.phase == 0:
  battle.tutorial.skip_intro()
 battle.simulate(.01)
 check(battle.tutorial.phase == 2 and battle.placed[0].level == 2 and battle.player_turret.reloads_completed == 1,"valid actions before their instructions remain recorded")
 var old_settings: Dictionary = SaveManager.settings.duplicate(true)
 DirAccess.make_dir_absolute(SaveManager.SETTINGS_PATH+".tmp")
 check(not battle.tutorial.finish("skipped") and battle.tutorial.active and SaveManager.settings == old_settings,"failed status save keeps guidance and offers retry without losing state")
 DirAccess.remove_absolute(SaveManager.SETTINGS_PATH+".tmp")
 await tap(app.tutorial_overlay.skip_button)
 check(not app.battle.guided and app.battle.credits == 500 and SaveManager.settings.tutorial_status == "skipped","skip discards assistance/early purchases and returns normal supply")
 SaveManager.reload_from_disk()
 check(SaveManager.settings.tutorial_status == "skipped" and not app._tutorial_due(1),"skip persists and prevents forced repetition")
 var final_campaign: Dictionary = SaveManager.state.duplicate(true)
 SaveManager.state = {}
 app._replay_tutorial()
 app.battle.set_physics_process(false)
 check(app.battle.guided and app.training_only and SaveManager.state.is_empty(),"Settings tutorial works without starting a campaign")
 await tap(app.tutorial_overlay.skip_button)
 check(SaveManager.state.is_empty() and app.screen == "training_results","no-campaign practice creates no save or rewards")
 SaveManager.state = final_campaign
 SaveManager.persist()
 records.append({"guided_simulated_seconds":guided_time,"normal_m1_reward":bank,"fixture":"actual desktop events, three independent touches, real actors/reload/purchases, then assisted normal-budget five-wave M1; early-action/restart fixtures; no physical Android"})
 if not directory.is_empty():
  var final_state: Dictionary = SaveManager.state.duplicate(true)
  SaveManager.state = retained.duplicate(true)
  SaveManager.persist()
  for dimensions in [Vector2i(1280,720),Vector2i(1600,720),Vector2i(1280,600),Vector2i(1024,768)]:
   get_tree().root.size = dimensions
   app._replay_tutorial()
   app.battle.set_physics_process(false)
   for phase in [0,1,2,4,6]:
    if phase == 6:
     app.battle.select_slot(0)
     app.battle.build_turret("machine_gun")
     app.battle.select_slot(0)
    app.battle.tutorial.enter(phase)
    await frames()
    var overlay: Control = app.tutorial_overlay
    check(get_viewport().get_visible_rect().encloses(overlay.skip_button.get_global_rect()),"skip stays inside native viewport")
    check(not overlay.panel.get_global_rect().intersects(app.hud.player_panel.fire_button.get_global_rect()),"instruction panel never hides FIRE")
    await native_capture("layout_%dx%d_step%d" % [dimensions.x,dimensions.y,phase])
   app._show_results(true,int(archived_stats.campaign.reward),archived_stats)
   await frames()
   await native_capture("ratings_%dx%d" % [dimensions.x,dimensions.y])
   app._briefing(1,true)
   await native_capture("star_requirements_%dx%d" % [dimensions.x,dimensions.y])
   app._map()
   await native_capture("stars_map_%dx%d" % [dimensions.x,dimensions.y])
  SaveManager.state = final_state
  SaveManager.persist()
  var metrics := FileAccess.open(directory.path_join("metrics.json"),FileAccess.WRITE)
  metrics.store_string(JSON.stringify({"checks":checks,"failures":failures,"renderer":RenderingServer.get_video_adapter_name(),"frames":native_frames,"fixture":"actual guided input/actors then ordinary-budget M1 victory; archived receipt re-presented on four layouts, staged tutorial phases for layout coverage; practice supply never funds campaign; fixed attack seed808; no physical Android"},"  "))
 app.queue_free()
 await frames()
 finish()

func finish() -> void:
 if not records.is_empty():
  var file := FileAccess.open("user://tutorial_scenarios.json",FileAccess.WRITE)
  file.store_string(JSON.stringify({"checks":checks,"failures":failures,"cases":records},"  "))
 print("MISSION TUTORIAL: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
