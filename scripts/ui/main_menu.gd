extends VBoxContainer
signal new_requested
signal continue_requested
signal arsenal_requested
signal settings_requested
signal exit_requested
const UI := preload("res://scripts/ui/ui_kit.gd")

func setup(has_save: bool) -> void:
 add_theme_constant_override("separation",16)
 var identity := HBoxContainer.new()
 identity.add_theme_constant_override("separation",12)
 add_child(identity)
 var badge := TextureRect.new()
 badge.texture = preload("res://assets/ui/sentinel_badge.svg")
 badge.custom_minimum_size = Vector2(48,48)
 badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 identity.add_child(badge)
 var signature := VBoxContainer.new()
 signature.add_theme_constant_override("separation",0)
 identity.add_child(signature)
 signature.add_child(UI.label("SENTINEL COMMAND",18,UI.WHITE))
 signature.add_child(UI.label("ASTERIA  /  DEFENSE OPERATIONS",13,UI.MUTED))
 var layout := HBoxContainer.new()
 layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
 layout.add_theme_constant_override("separation",24)
 add_child(layout)
 var left := VBoxContainer.new()
 left.custom_minimum_size.x = 440
 left.add_theme_constant_override("separation",10)
 layout.add_child(left)
 left.add_child(UI.label("DRONE KILLER",82,UI.WHITE))
 left.add_child(UI.label("F R O N T L I N E",32,UI.ORANGE))
 var line := HSeparator.new()
 left.add_child(line)
 var description := UI.label("Command the defense.\nTake back Asteria.",23,UI.WHITE)
 left.add_child(description)
 var gap := Control.new()
 gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
 left.add_child(gap)
 left.add_child(UI.label("01 / THE INVASION",15,UI.MUTED))
 var begin := UI.button("New Campaign",func(): new_requested.emit(),Vector2(440,58))
 begin.theme_type_variation = &"TacticalPrimary"
 begin.icon = preload("res://assets/ui/icon_play.svg")
 left.add_child(begin)
 var resume := UI.button("Continue Campaign",func(): continue_requested.emit(),Vector2(440,58))
 resume.disabled = not has_save
 resume.icon = preload("res://assets/ui/icon_shield.svg")
 left.add_child(resume)
 var tools := HBoxContainer.new()
 tools.add_theme_constant_override("separation",10)
 left.add_child(tools)
 for item in [["Arsenal","arsenal"],["Settings","settings"]]:
  var action: Callable = func(): arsenal_requested.emit()
  if item[1] == "settings":
   action = func(): settings_requested.emit()
  var button := UI.button(str(item[0]),action,Vector2(215,54))
  button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  button.icon = load("res://assets/ui/icon_%s.svg" % item[1])
  tools.add_child(button)
 var right := VBoxContainer.new()
 right.mouse_filter = Control.MOUSE_FILTER_IGNORE
 right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 layout.add_child(right)
 var operation := UI.label("CAMPAIGN OPERATIONS  /  25 SECTORS",14,UI.MUTED)
 operation.add_theme_color_override("font_shadow_color",Color(0,0,0,0.95))
 operation.add_theme_constant_override("shadow_offset_y",1)
 operation.add_theme_constant_override("shadow_offset_x",0)
 operation.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 var operation_panel := PanelContainer.new()
 operation_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 operation_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
 var panel_style := UI.theme().get_stylebox("panel","PanelContainer").duplicate() as StyleBoxFlat
 panel_style.bg_color = Color(0.06,0.09,0.125,0.85)
 panel_style.set_content_margin_all(8)
 operation_panel.add_theme_stylebox_override("panel",panel_style)
 right.add_child(operation_panel)
 operation_panel.add_child(operation)
 var space := Control.new()
 space.mouse_filter = Control.MOUSE_FILTER_IGNORE
 space.size_flags_vertical = Control.SIZE_EXPAND_FILL
 right.add_child(space)
 var unit := UI.label("SENTINEL-7",34,UI.WHITE)
 unit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 right.add_child(unit)
 var role := UI.label("MOBILE AIR DEFENSE PLATFORM",14,UI.MUTED)
 role.add_theme_color_override("font_shadow_color",Color(0,0,0,0.95))
 role.add_theme_constant_override("shadow_offset_y",1)
 role.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 right.add_child(role)
 var footer := HBoxContainer.new()
 footer.add_theme_constant_override("separation",16)
 add_child(footer)
 var status := UI.label("OFFLINE CAMPAIGN   /   5 CHAPTERS   /   25 TERRITORIES",13,UI.MUTED)
 status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 footer.add_child(status)
 if not OS.has_feature("mobile"):
  footer.add_child(UI.button("Exit",func(): exit_requested.emit(),Vector2(110,44)))
