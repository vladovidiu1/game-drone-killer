extends Button
# Native touch ownership per button: two fingers can use different controls.
# Mouse input remains handled by BaseButton. Mouse emulation is disabled in project.godot.
var touch_id := -1

func _gui_input(event: InputEvent) -> void:
 if disabled:
  return
 if event is InputEventScreenTouch:
  if event.pressed and touch_id == -1:
   touch_id = event.index
   if not toggle_mode:
    set_pressed_no_signal(true)
   button_down.emit()
   accept_event()
  elif not event.pressed and event.index == touch_id:
   touch_id = -1
   if not toggle_mode:
    set_pressed_no_signal(false)
   button_up.emit()
   if Rect2(Vector2.ZERO,size).has_point(event.position):
    if toggle_mode:
     set_pressed_no_signal(not button_pressed)
     toggled.emit(button_pressed)
    pressed.emit()
   accept_event()
 elif event is InputEventScreenDrag and event.index == touch_id:
  if not toggle_mode:
   set_pressed_no_signal(Rect2(Vector2.ZERO,size).has_point(event.position))
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
