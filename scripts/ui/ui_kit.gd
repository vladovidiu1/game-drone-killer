extends RefCounted
const CYAN := Color("37B7E5")
const WHITE := Color("E9F0F6")
const ORANGE := Color("FF9C42")
const HEADING := preload("res://assets/ui/fonts/BarlowCondensed-Bold.ttf")
const MONO := preload("res://assets/ui/fonts/DejaVuSansMono.ttf")
const MUTED := Color("98acbb")

static func label(text: String, size: int = 20, color: Color = WHITE) -> Label:
 var node := Label.new()
 node.text = text
 if size >= 28:
  node.add_theme_font_override("font",HEADING)
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
 return preload("res://assets/ui/frontline_theme.tres")

static func prepare_confirmation(dialog: ConfirmationDialog) -> void:
 # Engine-created dialog buttons also need native touch when mouse emulation is off.
 for control in [dialog.get_ok_button(),dialog.get_cancel_button()]:
  control.set_script(preload("res://scripts/ui/touch_button.gd"))
  control.custom_minimum_size = Vector2(160,54)
