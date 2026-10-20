extends VBoxContainer
const UI := preload("res://scripts/ui/ui_kit.gd")

func setup() -> void:
 add_theme_constant_override("separation",12)
 add_child(UI.label("COMBAT PRESENTATION",24,UI.CYAN))
 var quality := OptionButton.new()
 quality.custom_minimum_size.y = 56
 for state in ["normal","hover","pressed","disabled","focus"]:
  quality.add_theme_stylebox_override(state,UI.theme().get_stylebox(state,"Button"))
 quality.add_theme_font_size_override("font_size",21)
 quality.get_popup().add_theme_stylebox_override("panel",UI.theme().get_stylebox("panel","PanelContainer"))
 quality.get_popup().add_theme_font_size_override("font_size",21)
 quality.get_popup().add_theme_constant_override("v_separation",20)
 for level in ["low","medium","high"]:
  quality.add_item("Particle quality: "+str(level).capitalize())
 quality.selected = ["low","medium","high"].find(str(SaveManager.settings.effects_quality))
 quality.item_selected.connect(func(index: int):
  SaveManager.settings.effects_quality = ["low","medium","high"][index]
  SaveManager.save_settings())
 add_child(quality)
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
