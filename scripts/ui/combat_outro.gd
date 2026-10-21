extends Control
# Results have already been atomically settled before this optional boss outro.
# Only the detached visual batch advances; finished battle simulation stays frozen.
signal completed
const UI := preload("res://scripts/ui/ui_kit.gd")
var view: Node2D
var elapsed := 0.0
var done := false

func setup(source: Node2D) -> void:
 view = source
 z_index = 20
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_STOP
 var panel := MarginContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 panel.offset_top = -110
 panel.add_theme_constant_override("margin_left",36)
 panel.add_theme_constant_override("margin_right",36)
 panel.add_theme_constant_override("margin_bottom",24)
 add_child(panel)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",24)
 panel.add_child(row)
 var title := UI.label("HOSTILE COMMAND DESTROYED",34,UI.CYAN)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_child(title)
 row.add_child(UI.button("Continue",finish,Vector2(210,58)))

func _process(delta: float) -> void:
 if done:
  return
 elapsed += delta
 if is_instance_valid(view):
  view.tick_outro(delta)
 if elapsed >= 1.9:
  finish()

func finish() -> void:
 if done:
  return
 done = true
 completed.emit()
