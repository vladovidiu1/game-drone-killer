extends RefCounted
const CYAN := Color("65dce1")
const MUTED := Color("94adbc")

static func label(text: String, size: int = 20, color: Color = Color.WHITE) -> Label:
 var node := Label.new()
 node.text = text
 node.add_theme_font_size_override("font_size", size)
 node.add_theme_color_override("font_color", color)
 return node

static func button(text: String, action: Callable, minimum: Vector2 = Vector2(210,54)) -> Button:
 var node: Button = preload("res://scripts/ui/touch_button.gd").new()
 node.text = text
 node.custom_minimum_size = minimum
 node.add_theme_font_size_override("font_size", 19)
 node.pressed.connect(action)
 return node

static func theme() -> Theme:
 var result := Theme.new()
 result.default_font_size = 20
 for state in ["normal","hover","pressed","disabled","focus"]:
  var box := StyleBoxFlat.new()
  box.bg_color = Color("1c3546") if state == "normal" else Color("285065")
  if state == "disabled":
   box.bg_color = Color("182631")
  box.border_color = Color("345566") if state != "focus" else CYAN
  box.set_border_width_all(2 if state == "focus" else 1)
  box.set_corner_radius_all(6)
  box.content_margin_left = 16
  box.content_margin_right = 16
  result.set_stylebox(state,"Button",box)
 result.set_color("font_color","Button",Color("e3f0f4"))
 result.set_color("font_disabled_color","Button",Color("697f8d"))
 return result

static func prepare_confirmation(dialog: ConfirmationDialog) -> void:
 # Engine-created dialog buttons also need native touch when mouse emulation is off.
 for control in [dialog.get_ok_button(),dialog.get_cancel_button()]:
  control.set_script(preload("res://scripts/ui/touch_button.gd"))
  control.custom_minimum_size = Vector2(160,54)
