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
 screen = next
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
 var col := _column()
 _header(col,"ASTERIA / CAMPAIGN","Blue: controlled  •  Orange: frontline  •  Red: enemy  •  ◆: secured checkpoint")
 var scroll := ScrollContainer.new()
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 col.add_child(scroll)
 var chapters := VBoxContainer.new()
 chapters.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 chapters.add_theme_constant_override("separation",12)
 scroll.add_child(chapters)
 var frontline := int(SaveManager.state.get("frontline",1))
 var checkpoint := int(SaveManager.state.get("checkpoint",1))
 for chapter in 5:
  chapters.add_child(UI.label("0%d  /  %s" % [chapter+1,CampaignManager.CHAPTERS[chapter].to_upper()],18,UI.MUTED))
  var row := HBoxContainer.new()
  row.add_theme_constant_override("separation",10)
  chapters.add_child(row)
  for offset in 5:
   var id := chapter*5+offset+1
   var mission := CampaignManager.mission(id)
   var status := CampaignManager.territory_state(id)
   if mission.has("boss"):
    status += " • BOSS"
   if not bool(mission.playable):
    status += " • DEV"
   if SaveManager.state.get("checkpoints",[1]).has(id):
    status += " ◆"
   var btn := UI.button("%02d  %s\n%s" % [id,mission.name,status],_briefing.bind(id),Vector2(0,60))
   btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   btn.add_theme_font_size_override("font_size",14)
   var tint := Color("37B7E5") if status.begins_with("CONTROLLED") else (Color("FF9C42") if id == frontline else Color("F04B45"))
   btn.add_theme_color_override("font_color",tint)
   row.add_child(btn)
 var nav := HBoxContainer.new()
 col.add_child(nav)
 nav.add_child(UI.button("Main menu",_menu))
 nav.add_child(UI.button("Arsenal",_arsenal))
 col.add_child(UI.label("Frontline: %02d   /   Highest: %02d   /   Checkpoint: %02d   /   War Credits: %d" % [frontline,int(SaveManager.state.get("highest",1)),checkpoint,int(SaveManager.state.get("credits",0))],18,UI.CYAN))
 var feedback := UI.label(str(SaveManager.state.get("last_result",{}).get("message","Secure Asteria, one territory at a time.")),18,UI.CYAN)
 feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 col.add_child(feedback)
 _save_error(col)

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
 _header(col,"SETTINGS","Saved locally on this device")
 _spacer(col)
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
 _spacer(col)
 col.add_child(UI.button("Main menu",_menu))
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
 _clear("results")
 var col := _column()
 var outcome: Dictionary = stats.campaign
 var id := int(outcome.mission_id)
 _header(col,("ASTERIA LIBERATED" if id == 25 else "TERRITORY SECURED") if victory else "DEFENSE LOST",str(CampaignManager.mission(id).name))
 var feedback := UI.label(str(outcome.message),23,UI.CYAN)
 feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 col.add_child(feedback)
 _spacer(col)
 col.add_child(UI.label("%d DRONES DESTROYED   /   %d BASE HP REMAINING" % [int(stats.kills),int(stats.health)],24))
 col.add_child(UI.label("+%d War Credits • Frontline: %02d • Highest: %02d" % [reward,int(SaveManager.state.frontline),int(SaveManager.state.highest)],22))
 col.add_child(UI.label("Battle bounties: %d credits (temporary). Permanent research retained." % int(stats.get("earned",0)),18,UI.MUTED))
 if int(outcome.get("objective_reward",0)) > 0:
  col.add_child(UI.label("Includes +%d War Credits for a completed campaign objective." % int(outcome.objective_reward),18,UI.CYAN))
 _spacer(col)
 var next := int(SaveManager.state.frontline)
 if victory and id == 25:
  col.add_child(UI.label("CAMPAIGN COMPLETE • All five chapters cleared. Replay from the map.",20,UI.CYAN))
 elif CampaignManager.can_play(next):
  col.add_child(UI.button(("Next: " if victory else "Retry ")+str(CampaignManager.mission(next).name),_briefing.bind(next)))
 else:
  col.add_child(UI.label("Mission %02d is locked. Reconquer the current frontline to advance." % next,18,UI.MUTED))
 var nav := HBoxContainer.new()
 nav.add_theme_constant_override("separation",10)
 col.add_child(nav)
 nav.add_child(UI.button("Campaign map",_map))
 nav.add_child(UI.button("Arsenal",_arsenal))
 if victory and CampaignManager.can_play(id):
  nav.add_child(UI.button("Replay "+str(CampaignManager.mission(id).name),_play.bind(id)))
 _save_error(col)

func _unhandled_key_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):
  if screen == "game":
   _pause()
  else:
   _menu()

func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_GO_BACK_REQUEST:
  if screen == "game":
   _pause()
  else:
   _menu()
