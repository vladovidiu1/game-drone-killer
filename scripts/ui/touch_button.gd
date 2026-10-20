extends Button
# Native touch ownership per button: two fingers can use different controls.
# Mouse input remains handled by BaseButton. Mouse emulation is disabled in project.godot.
var touch_id := -1
var touch_origin := Vector2.ZERO
var previous_touch := Vector2.ZERO
var scrolling := false

func _gui_input(event: InputEvent) -> void:
 if disabled:
  return
 if event is InputEventScreenTouch:
  if event.pressed and touch_id == -1:
   touch_id = event.index
   touch_origin = event.position
   previous_touch = event.position
   scrolling = false
   if not toggle_mode:
    set_pressed_no_signal(true)
   button_down.emit()
   accept_event()
  elif not event.pressed and event.index == touch_id:
   touch_id = -1
   if not toggle_mode:
    set_pressed_no_signal(false)
   button_up.emit()
   if not scrolling and Rect2(Vector2.ZERO,size).has_point(event.position):
    if toggle_mode:
     set_pressed_no_signal(not button_pressed)
     toggled.emit(button_pressed)
    pressed.emit()
   accept_event()
 elif event is InputEventScreenDrag and event.index == touch_id:
  var ancestor := get_parent()
  while ancestor != null and not ancestor is ScrollContainer:
   ancestor = ancestor.get_parent()
  if ancestor is ScrollContainer and (scrolling or event.position.distance_to(touch_origin) > 12):
   scrolling = true
   var movement: Vector2 = event.relative if event.relative.length_squared() > 0 else event.position-previous_touch
   ancestor.scroll_vertical -= int(movement.y)
   if not toggle_mode:
    set_pressed_no_signal(false)
  elif not toggle_mode:
   set_pressed_no_signal(Rect2(Vector2.ZERO,size).has_point(event.position))
  previous_touch = event.position
  accept_event()

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and touch_id >= 0:
  touch_id = -1
  if not toggle_mode:
   set_pressed_no_signal(false)

func cancel_touch() -> void:
 if touch_id >= 0:
  touch_id = -1
  if not toggle_mode:
   set_pressed_no_signal(false)
  button_up.emit()
