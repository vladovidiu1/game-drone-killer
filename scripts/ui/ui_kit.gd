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
 node.pressed.connect(func(): AudioManager.combat_cue("click"))
 node.pressed.connect(action)
 return node

static func theme() -> Theme:
 return preload("res://assets/ui/frontline_theme.tres")

static func prepare_confirmation(dialog: ConfirmationDialog) -> void:
 # Engine-created dialog buttons also need native touch when mouse emulation is off.
 for control in [dialog.get_ok_button(),dialog.get_cancel_button()]:
  control.set_script(preload("res://scripts/ui/touch_button.gd"))
  control.custom_minimum_size = Vector2(160,54)

static func mission_image(id: int) -> TextureRect:
 # Screen-owned terrain frame: visiting briefings never fills the global cache.
 var library: Dictionary = preload("res://scripts/visual/environment_library.gd").DATA
 var kind: String = str(library.missions[str(id)].type)
 var entry: Dictionary = preload("res://scripts/visual/visual_assets.gd").catalog.sprites["terrain_"+kind]
 var texture: Texture2D = load("res://assets/"+str(entry.file))
 if entry.has("region"):
  var frame := AtlasTexture.new()
  frame.atlas = texture
  frame.region = Rect2(float(entry.region[0]),float(entry.region[1]),float(entry.region[2]),float(entry.region[3]))
  frame.filter_clip = true
  texture = frame
 var image := TextureRect.new()
 image.texture = texture
 image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 image.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return image

static func panel(accent: Color = CYAN, padding: int = 14) -> PanelContainer:
 var result := PanelContainer.new()
 var style := theme().get_stylebox("panel","PanelContainer").duplicate() as StyleBoxFlat
 style.bg_color = Color(.055,.08,.11,.94)
 style.border_color = Color(accent,.33)
 style.border_width_top = 2
 style.set_content_margin_all(padding)
 result.add_theme_stylebox_override("panel",style)
 return result

static func flash(node: Control, tint: Color = CYAN) -> void:
 var previous: Variant = node.get_meta("feedback_tween") if node.has_meta("feedback_tween") else null
 if previous is Tween and previous.is_valid():
  previous.kill()
 node.modulate = tint.lightened(.25)
 if not bool(SaveManager.settings.get("reduced_motion",false)):
  var animation := node.create_tween()
  node.set_meta("feedback_tween",animation)
  animation.tween_property(node,"modulate",Color.WHITE,.4)
 else:
  node.modulate = Color.WHITE

static func icon(name: String) -> Texture2D:
 return load("res://assets/ui/icon_"+name+".svg")
