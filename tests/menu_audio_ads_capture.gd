extends Node
var failures := 0
var app: Control
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func _ready() -> void:
 run.call_deferred()
func settle() -> void:
 for frame in 4:
  await get_tree().process_frame
func buttons(node: Node) -> Array[Button]:
 var found: Array[Button] = []
 for child in node.get_children():
  if child is Button:
   found.append(child)
  found.append_array(buttons(child))
 return found
func tap(button: Button) -> void:
 for down in [true,false]:
  var event := InputEventScreenTouch.new()
  event.index = 91
  event.position = button.get_global_rect().get_center()
  event.pressed = down
  button.get_viewport().push_input(event,true)
  await settle()
func capture(name: String, viewport: Viewport = null) -> void:
 await RenderingServer.frame_post_draw
 if viewport == null:
  viewport = get_viewport()
 check(viewport.get_texture().get_image().save_png("/tmp/drone-v3-captures/"+name+".png") == OK,"Rendered capture "+name)
func run() -> void:
 if DisplayServer.get_name() == "headless":
  push_error("This fixture requires a real renderer/X11")
  get_tree().quit(1)
  return
 DirAccess.make_dir_recursive_absolute("/tmp/drone-v3-captures")
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 SaveManager.new_campaign()
 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 await settle()
 app._settings()
 await settle()
 var music: Button
 for button in buttons(app):
  if button.text.begins_with("Menu music:"):
   music = button
 check(music != null and music.button_pressed,"Music setting is visible and defaults ON")
 if music != null:
  await tap(music)
  check(not SaveManager.settings.music_enabled,"Actual native touch disables music independently")
  await tap(music)
  check(SaveManager.settings.music_enabled,"Actual native touch restores music")
 await capture("music_settings")
 app._map()
 await settle()
 var info: Button
 for button in buttons(app):
  if button.text == "Ad information":
   info = button
 check(info != null and not info.disabled,"Information action is available on actual campaign screen")
 if info != null:
  var ancestor := info.get_parent()
  while ancestor != null and not ancestor is ScrollContainer:
   ancestor = ancestor.get_parent()
  if ancestor is ScrollContainer:
   ancestor.ensure_control_visible(info)
  await settle()
  await capture("ad_information_offer")
  var bank: int = SaveManager.state.credits
  await tap(info)
  var offer := info.get_parent().get_parent()
  var dialog := offer.get_node_or_null("AdsInformation")
  check(dialog is AcceptDialog and dialog.visible,"Native touch opens actual information dialog")
  if dialog is AcceptDialog:
   await capture("ad_information_dialog",dialog.get_viewport())
   await tap(dialog.get_ok_button())
   check(not is_instance_valid(dialog) or not dialog.visible,"Native touch closes the dialog")
  check(SaveManager.state.credits == bank,"Information dialog never grants money")
 app.queue_free()
 await settle()
 print("NATIVE MENU AUDIO / ADS: %d failures" % failures)
 get_tree().quit(1 if failures else 0)
