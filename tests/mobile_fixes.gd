extends Node
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func _ready() -> void:
 run.call_deferred()
func settle() -> void:
 for frame in 4:
  await get_tree().process_frame
func touch(point: Vector2, down: bool) -> void:
 var event := InputEventScreenTouch.new()
 event.index = 80
 event.position = point
 event.pressed = down
 get_viewport().push_input(event,true)
func swipe(point: Vector2) -> void:
 touch(point,true)
 var drag := InputEventScreenDrag.new()
 drag.index = 80
 drag.position = point+Vector2(0,-120)
 drag.relative = Vector2(0,-120)
 get_viewport().push_input(drag,true)
 touch(drag.position,false)
 await settle()
func scroll_in(node: Node) -> ScrollContainer:
 for child in node.get_children():
  if child is ScrollContainer:
   return child
  var result := scroll_in(child)
  if result != null:
   return result
 return null
func run() -> void:
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,600)
 SaveManager.new_campaign()
 var app := preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 await settle()
 app._settings()
 await settle()
 var scroll := scroll_in(app.content)
 var before: Dictionary = SaveManager.settings.duplicate(true)
 # Start on the volume heading, not a touch_button.
 var heading: Control = scroll.get_child(0).get_child(0)
 await swipe(heading.get_global_rect().get_center())
 check(scroll.scroll_vertical > 0,"Settings swipe starting on text scrolls content")
 check(SaveManager.settings == before,"Settings scrolling never changes mute/volume/preferences")
 scroll.scroll_vertical = 0
 await settle()
 var slider: Slider = scroll.get_child(0).get_child(1)
 var point := slider.get_global_rect().get_center()
 touch(point,true)
 touch(point,false)
 await settle()
 check(scroll.scroll_vertical == 0 and is_equal_approx(float(SaveManager.settings.volume),0.5),"Volume slider retains native touch ownership")
 app._arsenal()
 await settle()
 scroll = scroll_in(app.content)
 var arsenal: Control = app.content.get_child(0)
 arsenal.select_tab("research")
 await settle()
 # Long research paragraphs/panels previously swallowed native swipes.
 var balance: int = SaveManager.state.credits
 await swipe(scroll.get_global_rect().position+Vector2(30,70))
 check(scroll.scroll_vertical > 0 and SaveManager.state.credits == balance,"Research content scrolls without buying anything")
 app._play(1)
 await settle()
 app.battle.set_physics_process(false)
 app.battle.select_slot(0)
 check(app.battle.build_turret("machine_gun"),"Build with ordinary battle funds")
 await settle()
 check(app.battle.effective_speed() == 1.0,"Constructed turret never slows the battle")
 check(app.hud.upgrade_button.visible and app.hud.upgrade_button.size.y >= 64,"Upgrade action is prominent and stays outside the scroll")
 check(app.hud.build_panel.get_global_rect().encloses(app.hud.upgrade_button.get_global_rect()),"Upgrade remains inside expanded drawer")
 check(not app.hud.player_panel.fire_button.get_global_rect().intersects(app.hud.build_panel.get_global_rect()),"Upgrade drawer preserves FIRE control")
 var old_level: int = app.battle.placed[0].level
 app.hud.upgrade_button.pressed.emit()
 check(app.battle.placed[0].level == old_level+1 and app.battle.effective_speed() == 1.0,"Real upgrade purchase keeps normal speed")
 app.battle.select_slot(1)
 app.hud.build_buttons.machine_gun.pressed.emit()
 check(app.battle.placed[1] != null and not app.battle.build_mode and app.battle.effective_speed() == 1.0,"Successful shop placement closes the drawer and returns to normal combat")
 app.battle.select_slot(0)
 for dimensions in [Vector2i(1280,600),Vector2i(1024,768),Vector2i(1600,720),Vector2i(1280,720)]:
  get_tree().root.size = dimensions
  await settle()
  var bounds := get_viewport().get_visible_rect()
  check(bounds.encloses(app.hud.build_panel.get_global_rect()) and app.hud.build_panel.size.x >= 400,"Expanded upgrade drawer fits "+str(dimensions))
  check(app.hud.build_panel.get_global_rect().encloses(app.hud.upgrade_button.get_global_rect()),"Pinned upgrade remains reachable at "+str(dimensions))
  if DisplayServer.get_name() != "headless":
   await RenderingServer.frame_post_draw
   DirAccess.make_dir_recursive_absolute("/tmp/drone-mobile-captures")
   check(get_viewport().get_texture().get_image().save_png("/tmp/drone-mobile-captures/mobile_upgrade_%dx%d.png" % [dimensions.x,dimensions.y]) == OK,"Rendered mobile upgrade frame")
 for kind in ["shot","impact","explosion","build","click","reload","ready","hit","radar","victory","defeat"]:
  var wav: AudioStreamWAV = AudioManager.sound(kind)
  var peak := 0
  for i in range(0,wav.data.size(),2):
   peak = maxi(peak,absi(wav.data.decode_s16(i)))
  check(peak > 10000 and peak < 32767,"Non-silent unclipped PCM for "+kind)
 check(AudioManager.player.playback_type == AudioServer.PLAYBACK_TYPE_STREAM,"Runtime PCM uses explicit stream playback on Android")
 SaveManager.settings.muted = true
 AudioManager.apply_settings()
 check(AudioServer.is_bus_mute(0),"Audio still respects user's mute preference")
 SaveManager.settings = before
 AudioManager.apply_settings()
 app.queue_free()
 await settle()
 print("MOBILE FIXES: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
