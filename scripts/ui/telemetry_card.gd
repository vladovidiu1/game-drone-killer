extends PanelContainer
const UI := preload("res://scripts/ui/ui_kit.gd")
var value: Label
var caption: Label
var meter: ProgressBar
var last_value := -1
var title_text := ""
var gain_remaining := 0.0
func setup(title: String, symbol: String, tint: Color = UI.CYAN) -> void:
 title_text = title
 set_process(false)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 size_flags_horizontal = Control.SIZE_EXPAND_FILL
 custom_minimum_size.y = 58
 var style := UI.theme().get_stylebox("panel","PanelContainer").duplicate() as StyleBoxFlat
 style.set_content_margin_all(6)
 style.border_color = Color(tint,.3)
 add_theme_stylebox_override("panel",style)
 var row := HBoxContainer.new()
 row.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(row)
 var icon := TextureRect.new()
 icon.texture = UI.icon(symbol)
 icon.modulate = tint
 icon.custom_minimum_size = Vector2(24,24)
 icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
 row.add_child(icon)
 var stack := VBoxContainer.new()
 stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 stack.add_theme_constant_override("separation",0)
 row.add_child(stack)
 caption = UI.label(title,12,UI.MUTED)
 caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stack.add_child(caption)
 value = UI.label("",20,UI.WHITE)
 value.add_theme_font_override("font",UI.MONO)
 value.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stack.add_child(value)
 meter = ProgressBar.new()
 meter.custom_minimum_size.y = 3
 meter.show_percentage = false
 meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stack.add_child(meter)
func update_value(text: String, amount: int = -1, fraction: float = -1) -> void:
 value.text = text
 meter.visible = fraction >= 0
 if fraction >= 0:
  meter.value = fraction*100
 if last_value >= 0 and amount > last_value:
  caption.text = "BATTLE CREDITS   +%d" % (amount-last_value)
  gain_remaining = .8
  set_process(true)
  UI.flash(self)
 last_value = amount

func _process(delta: float) -> void:
 gain_remaining = maxf(0,gain_remaining-delta)
 if gain_remaining == 0:
  caption.text = title_text
  set_process(false)
