extends Control
const UI := preload("res://scripts/ui/ui_kit.gd")
const BATTLE := preload("res://scenes/gameplay.tscn")
const BATTLE_HUD := preload("res://scripts/ui/battle_hud.gd")
var background: Control
var content: MarginContainer
var battle: Node2D
var screen := ""
var hud: Control
var result_data: Dictionary = {}
var outro: Control
var seen_map_result := ""
var screen_tween: Tween

func _ready() -> void:
 theme = UI.theme()
 background = Control.new()
 background.set_script(preload("res://scripts/ui/backdrop.gd"))
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(background)
 content = MarginContainer.new()
 content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 content.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(content)
 resized.connect(_resize)
 _resize()
 _menu()

func _resize() -> void:
 if not is_instance_valid(content):
  return
 var margins := Vector4(36,24,36,24)
 if OS.has_feature("mobile"):
  var safe := DisplayServer.get_display_safe_area()
  var window := DisplayServer.window_get_size()
  if window.x > 0 and window.y > 0 and safe.size.x > 0:
   var factor := size / Vector2(window)
   margins.x = maxf(margins.x, safe.position.x * factor.x)
   margins.y = maxf(margins.y, safe.position.y * factor.y)
   margins.z = maxf(margins.z, (window.x-safe.end.x) * factor.x)
   margins.w = maxf(margins.w, (window.y-safe.end.y) * factor.y)
 content.add_theme_constant_override("margin_left",int(margins.x))
 content.add_theme_constant_override("margin_top",int(margins.y))
 content.add_theme_constant_override("margin_right",int(margins.z))
 content.add_theme_constant_override("margin_bottom",int(margins.w))
 if is_instance_valid(battle):
  battle.scale = Vector2.ONE*minf(size.x/1280.0,size.y/720.0)
  battle.position = (size-Vector2(1280,720)*battle.scale)*0.5

func _clear(next: String) -> void:
 if is_instance_valid(outro):
  outro.queue_free()
  outro = null
 screen = next
 if is_instance_valid(screen_tween):
  screen_tween.kill()
 content.modulate = Color.WHITE
 if next != "game" and not bool(SaveManager.settings.get("reduced_motion",false)):
  content.modulate.a = .65
  screen_tween = create_tween()
  screen_tween.tween_property(content,"modulate:a",1.0,.18)
 background.set_screen(next)
 for child in content.get_children():
  content.remove_child(child)
  child.queue_free()
 if is_instance_valid(battle):
  remove_child(battle)
  battle.queue_free()
  battle = null

func _column() -> VBoxContainer:
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",14)
 content.add_child(column)
 return column

func _header(column: VBoxContainer, title: String, subtitle: String) -> void:
 column.add_child(UI.label("SENTINEL COMMAND  /  ASTERIA",16,UI.CYAN))
 column.add_child(UI.label(title,34))
 column.add_child(UI.label(subtitle,18,UI.MUTED))

func _spacer(column: BoxContainer) -> void:
 var spacer := Control.new()
 spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
 spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 column.add_child(spacer)

func _menu() -> void:
 _clear("menu")
 var menu := preload("res://scripts/ui/main_menu.gd").new()
 content.add_child(menu)
 menu.setup(SaveManager.has_campaign())
 menu.new_requested.connect(_confirm_new)
 menu.continue_requested.connect(_map)
 menu.arsenal_requested.connect(_arsenal)
 menu.settings_requested.connect(_settings)
 menu.exit_requested.connect(func(): get_tree().quit())
 _save_error(menu)

func _save_error(col: VBoxContainer) -> void:
 if not SaveManager.recovery_notice.is_empty():
  var notice := UI.label(SaveManager.recovery_notice,17,Color("FF9C42"))
  notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  col.add_child(notice)
 if not SaveManager.last_error.is_empty():
  col.add_child(UI.label(SaveManager.last_error,18,Color.CORAL))

func _confirm_new() -> void:
 if not SaveManager.has_campaign():
  if SaveManager.new_campaign():
   _map()
  else:
   _menu()
  return
 var dialog := ConfirmationDialog.new()
 UI.prepare_confirmation(dialog)
 dialog.title = "Replace campaign?"
 dialog.dialog_text = "This replaces your campaign progress and permanent upgrades."
 dialog.confirmed.connect(func():
  if SaveManager.new_campaign():
   _map()
  else:
   _menu())
 dialog.canceled.connect(dialog.queue_free)
 dialog.confirmed.connect(dialog.queue_free)
 add_child(dialog)
 dialog.popup_centered()

func _map() -> void:
 _clear("map")
 var map := preload("res://scenes/ui/campaign_map.tscn").instantiate()
 var result: Dictionary = SaveManager.state.get("last_result",{})
 var result_id := str(result.get("run_id",""))
 if result_id != seen_map_result:
  map.transition = result.duplicate(true)
  seen_map_result = result_id
 content.add_child(map)
 map.mission_requested.connect(_briefing)
 map.menu_requested.connect(_menu)
 map.arsenal_requested.connect(_arsenal)
 _save_error(map)

func _briefing(id: int) -> void:
 _clear("briefing")
 var briefing := preload("res://scripts/ui/mission_briefing.gd").new()
 content.add_child(briefing)
 briefing.setup(id)
 briefing.deploy_requested.connect(_play)
 briefing.back_requested.connect(_map)

func _arsenal() -> void:
 _clear("arsenal")
 var arsenal := preload("res://scripts/ui/arsenal.gd").new()
 content.add_child(arsenal)
 arsenal.back_requested.connect(_menu)

func _settings() -> void:
 _clear("settings")
 var col := _column()
 _header(col,"SETTINGS","Saved locally on this device • visual changes apply next mission")
 var outer := col
 var scroll := ScrollContainer.new()
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 outer.add_child(scroll)
 col = VBoxContainer.new()
 col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 col.add_theme_constant_override("separation",12)
 scroll.add_child(col)
 col.add_child(UI.label("Master volume",22))
 var slider := HSlider.new()
 slider.min_value = 0
 slider.max_value = 1
 slider.step = 0.05
 slider.value = float(SaveManager.settings.volume)
 slider.custom_minimum_size.y = 48
 slider.value_changed.connect(func(value: float):
  SaveManager.settings.volume = value
  AudioManager.apply_settings()
  SaveManager.save_settings())
 slider.gui_input.connect(func(event: InputEvent):
  if event is InputEventScreenTouch and event.pressed or event is InputEventScreenDrag:
   slider.value = clampf(event.position.x/slider.size.x,0.0,1.0)
   slider.accept_event())
 col.add_child(slider)
 var mute := UI.button("Mute audio",func(): pass)
 mute.toggle_mode = true
 mute.text = "Mute audio"
 mute.button_pressed = bool(SaveManager.settings.muted)
 mute.toggled.connect(func(value: bool):
  SaveManager.settings.muted = value
  AudioManager.apply_settings()
  SaveManager.save_settings())
 col.add_child(mute)
 col.add_child(UI.button("Test sound",func(): AudioManager.cue(true)))
 var reduced := UI.button("Reduced environment effects",func(): pass)
 reduced.toggle_mode = true
 reduced.button_pressed = bool(SaveManager.settings.get("reduced_environment_effects",false))
 reduced.text = "Reduced environment effects: "+("ON" if reduced.button_pressed else "OFF")
 reduced.toggled.connect(func(value: bool):
  reduced.text = "Reduced environment effects: "+("ON" if value else "OFF")
  SaveManager.settings.reduced_environment_effects = value
  SaveManager.save_settings())
 col.add_child(reduced)
 col.add_child(UI.label("Disables rain, moving haze, embers and light sweeps. Applied next mission.",16))
 var visual_settings := preload("res://scripts/ui/effects_settings.gd").new()
 col.add_child(visual_settings)
 visual_settings.setup()
 _spacer(col)
 outer.add_child(UI.button("Main menu",_menu))
 _save_error(col)

func _play(id: int = 1) -> void:
 var token := CampaignManager.begin_mission(id)
 if token.is_empty():
  return
 _clear("game")
 battle = BATTLE.instantiate()
 battle.mission_id = id
 battle.run_id = token
 add_child(battle)
 move_child(battle,1)
 _resize()
 battle.completed.connect(_results.bind(id,token))
 hud = BATTLE_HUD.new()
 content.add_child(hud)
 hud.setup(battle)
 hud.abort_requested.connect(_abort)

func _pause() -> void:
 if is_instance_valid(battle) and not battle.finished:
  battle.set_paused(not battle.paused)

func _abort() -> void:
 battle.set_paused(true)
 var dialog := ConfirmationDialog.new()
 UI.prepare_confirmation(dialog)
 dialog.title = "Abandon the outpost?"
 dialog.dialog_text = "Aborting counts as defeat and moves the frontline back to its checkpoint floor."
 dialog.confirmed.connect(func(): battle._finish(false))
 dialog.canceled.connect(func():
  if is_instance_valid(battle):
   battle.set_paused(false))
 dialog.confirmed.connect(dialog.queue_free)
 dialog.canceled.connect(dialog.queue_free)
 add_child(dialog)
 dialog.popup_centered()

func _results(victory: bool, stats: Dictionary, id: int, token: String) -> void:
 var outcome := CampaignManager.resolve(victory,id,token,stats)
 if outcome.is_empty():
  if not SaveManager.last_error.is_empty():
   var retry := ConfirmationDialog.new()
   UI.prepare_confirmation(retry)
   retry.title = "Result could not be saved"
   retry.dialog_text = SaveManager.last_error+" Retry saving to finish this mission."
   retry.get_ok_button().text = "Retry save"
   retry.confirmed.connect(_results.bind(victory,stats,id,token))
   retry.confirmed.connect(retry.queue_free)
   retry.canceled.connect(retry.queue_free)
   add_child(retry)
   retry.popup_centered()
  return
 AudioManager.cue(victory)
 result_data = stats.duplicate(true)
 result_data["campaign"] = outcome
 _show_results.call_deferred(victory,int(outcome.reward),result_data)

func _show_results(victory: bool, reward: int, stats: Dictionary) -> void:
 if victory and is_instance_valid(battle):
  battle.view.combat_fx.announce("TERRITORY SECURED",true)
 if victory and is_instance_valid(battle) and battle.finished and not battle.view.destruction.wrecks.is_empty():
  var has_boss := false
  for wreck in battle.view.destruction.wrecks:
   has_boss = has_boss or bool(wreck.boss)
  if has_boss:
   screen = "debrief"
   if is_instance_valid(hud):
    hud.pause_button.visible = false
   outro = preload("res://scripts/ui/combat_outro.gd").new()
   add_child(outro)
   outro.setup(battle.view)
   await outro.completed
 _clear("results")
 if victory:
  var celebration := Control.new()
  celebration.set_script(preload("res://scripts/visual/victory_effect.gd"))
  celebration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  content.add_child(celebration)
 var results := preload("res://scenes/ui/mission_results.tscn").instantiate()
 content.add_child(results)
 results.setup(victory,reward,stats)
 results.briefing_requested.connect(_briefing)
 results.replay_requested.connect(_play)
 results.map_requested.connect(_map)
 results.arsenal_requested.connect(_arsenal)
 _save_error(results)

func _unhandled_key_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):
  if screen == "debrief" and is_instance_valid(outro):
   outro.finish()
   return
  if screen == "game":
   _pause()
  else:
   _menu()

func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_GO_BACK_REQUEST:
  if screen == "debrief" and is_instance_valid(outro):
   outro.finish()
   return
  if screen == "game":
   _pause()
  else:
   _menu()
