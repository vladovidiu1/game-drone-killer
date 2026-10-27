extends ScrollContainer
# Mouse emulation is disabled: own a native swipe even when it starts on text,
# artwork or a nested panel. Buttons keep deliberate taps and other fingers.
var touch_id := -1
var origin := Vector2.ZERO
var initial_scroll := 0
var dragging := false

func _ready() -> void:
 horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
 scroll_deadzone = 12

func _input(event: InputEvent) -> void:
 if not is_visible_in_tree():
  _reset()
  return
 if event is InputEventScreenTouch:
  if event.pressed and touch_id == -1 and get_global_rect().has_point(event.position) and not _on_slider(self,event.position):
   touch_id = event.index
   origin = event.position
   initial_scroll = scroll_vertical
   dragging = false
  elif not event.pressed and event.index == touch_id:
   if dragging:
    _cancel_buttons(self)
    get_viewport().set_input_as_handled()
   _reset()
 elif event is InputEventScreenDrag and event.index == touch_id:
  if not dragging and event.position.distance_to(origin) > scroll_deadzone:
   dragging = true
   _cancel_buttons(self)
  if dragging:
   # Absolute displacement avoids jumps as controls move under the finger.
   scroll_vertical = initial_scroll+int(origin.y-event.position.y)
   get_viewport().set_input_as_handled()

func _on_slider(node: Node, point: Vector2) -> bool:
 for child in node.get_children():
  if child is Slider and child.is_visible_in_tree() and child.get_global_rect().has_point(point):
   return true
  if _on_slider(child,point):
   return true
 return false

func _cancel_buttons(node: Node) -> void:
 for child in node.get_children():
  if child is Button and child.has_method("cancel_touch") and child.get("touch_id") == touch_id:
   child.cancel_touch()
  _cancel_buttons(child)

func _reset() -> void:
 touch_id = -1
 dragging = false

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
  _cancel_buttons(self)
  _reset()
