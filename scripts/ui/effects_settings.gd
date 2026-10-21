extends VBoxContainer
const UI := preload("res://scripts/ui/ui_kit.gd")
var preset_buttons: Dictionary = {}
var status: Label

func setup() -> void:
 add_theme_constant_override("separation",12)
 add_child(UI.label("GRAPHICS & ACCESSIBILITY",24,UI.CYAN))
 add_child(UI.label("Graphics preset",20,UI.WHITE))
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",8)
 add_child(row)
 for level in ["low","medium","high"]:
  var button := UI.button(str(level).capitalize(),_select_preset.bind(str(level)),Vector2(0,54))
  button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  row.add_child(button)
  preset_buttons[level] = button
 _refresh_presets()
 status = UI.label("",16,UI.ORANGE)
 status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 add_child(status)
 var preset_help := UI.label("Low: fewer particles, no extra shadows or animated weather. Medium: balanced detail. High: all available effects. Applies on the next mission.",17,UI.MUTED)
 preset_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 add_child(preset_help)
 for option in [["reduced_effects","Reduced combat effects"],["reduced_motion","Reduced motion"],["effects_smoke","Smoke trails and bursts"],["effects_debris","Metal debris"],["effects_lighting","Soft impact lighting"],["effects_shake","Subtle impact shake"]]:
  toggle(str(option[0]),str(option[1]))
 var description := UI.label("Reduced effects limits particles and disables smoke, debris, lighting and shake. Reduced motion disables shake and flying debris, and holds rotor/hover and expanding effects still, and stops moving weather. Hit, area and reload indicators remain visible.",17,UI.MUTED)
 description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 add_child(description)

func toggle(key: String, title: String) -> void:
 var button := UI.button(title,func(): pass)
 button.toggle_mode = true
 button.button_pressed = bool(SaveManager.settings.get(key,false))
 button.text = title+": "+("ON" if button.button_pressed else "OFF")
 button.toggled.connect(func(value: bool):
  button.text = title+": "+("ON" if value else "OFF")
  SaveManager.settings[key] = value
  SaveManager.save_settings())
 add_child(button)

func _select_preset(id: String) -> void:
 var previous := SaveManager.settings.duplicate(true)
 SaveManager.settings.effects_quality = id
 if not SaveManager.save_settings():
  SaveManager.settings = previous
  status.text = SaveManager.last_error
 else:
  status.text = id.capitalize()+" selected • applies next mission"
 _refresh_presets()

func _refresh_presets() -> void:
 for id in preset_buttons:
  preset_buttons[id].theme_type_variation = &"TacticalPrimary" if id == SaveManager.settings.get("effects_quality","medium") else &"Button"
