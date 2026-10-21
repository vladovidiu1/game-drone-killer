extends "res://tests/ui_capture.gd"
const MOCK := preload("res://scripts/ads/mock_ad_adapter.gd")

func has_text(node: Node, value: String) -> bool:
 if (node is Label or node is Button) and value in node.text:
  return true
 for child in node.get_children():
  if has_text(child,value):
   return true
 return false

func find_watch(node: Node) -> Button:
 for child in node.get_children():
  if child is Button and child.text.begins_with("Watch Ad"):
   return child
  var result := find_watch(child)
  if result != null:
   return result
 return null

func native_touch(button: Button) -> void:
 var viewport := button.get_viewport()
 for held in [true,false]:
  var event := InputEventScreenTouch.new()
  event.index = 71
  event.position = button.get_global_rect().get_center()
  event.pressed = held
  viewport.push_input(event,true)
  await get_tree().process_frame

func run() -> void:
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--output="):
   directory = argument.trim_prefix("--output=")
 if DisplayServer.get_name() == "headless":
  push_error("Rewarded UI capture needs a native display")
  get_tree().quit(1)
  return
 DirAccess.make_dir_recursive_absolute(directory)
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 SaveManager.new_campaign()
 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 await get_tree().process_frame
 app._map()
 await capture("campaign_ads_unavailable")
 check(find_watch(app).disabled,"Missing native SDK disables optional ad button")
 var mock := MOCK.new()
 mock.scenario = "manual"
 check(RewardedAdsManager.configure_development(mock),"native editor simulation is explicit")
 app._arsenal()
 await capture("arsenal_optional_offer")
 var watch := find_watch(app)
 check(watch != null and not watch.disabled,"Optional editor watch button is available")
 await native_touch(watch)
 await get_tree().process_frame
 check(is_instance_valid(mock.dialog) and RewardedAdsManager.phase == "showing","native touch opens explicitly labeled mock ad")
 await capture("editor_simulation_dialog")
 if is_instance_valid(mock.dialog):
  await native_touch(mock.dialog.get_cancel_button())
 check(SaveManager.state.credits == 0 and RewardedAdsManager.remaining() == 5,"canceled native dialog gives no reward")
 await native_touch(find_watch(app))
 await get_tree().process_frame
 if is_instance_valid(mock.dialog):
  await native_touch(mock.dialog.get_ok_button())
 await get_tree().process_frame
 check(SaveManager.state.credits == 50 and RewardedAdsManager.remaining() == 4,"earned callback credits 50 and updates native Arsenal")
 await capture("arsenal_reward_saved")
 app._map()
 await capture("campaign_reward_saved")
 check(has_text(app,"WAR CREDITS  /  50"),"campaign balance updates after reward")
 for dimensions in [Vector2i(1280,600),Vector2i(1600,720),Vector2i(1024,768)]:
  get_tree().root.size = dimensions
  await get_tree().process_frame
  app._arsenal()
  await capture("arsenal_ads_%dx%d" % [dimensions.x,dimensions.y])
  watch = find_watch(app)
  check(get_viewport().get_visible_rect().encloses(watch.get_global_rect()),"watch target fits native layout "+str(dimensions))
  app._map()
  await capture("campaign_ads_%dx%d" % [dimensions.x,dimensions.y])
  watch = find_watch(app)
  check(get_viewport().get_visible_rect().encloses(watch.get_global_rect()),"campaign watch target fits native layout "+str(dimensions))
 var file := FileAccess.open(directory.path_join("render_metrics.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"captures":samples,"failures":failures,"real_ads":false},"  "))
 print("NATIVE REWARDED UI: %d captures, %d failures" % [samples.size(),failures])
 app.queue_free()
 await get_tree().process_frame
 get_tree().quit(1 if failures else 0)
