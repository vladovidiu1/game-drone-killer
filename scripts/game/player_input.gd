extends Node
# All input routes normalize into the same aim, trigger and reload operations.
# Only unhandled presses can start aiming/firing. Global releases prevent stuck fire.
var human_aim_movements := 0
var human_aim_distance := 0.0
var battle: Node2D
var fire_sources: Dictionary = {}
var aim_finger := -1
var touch_origin := Vector2.ZERO
var aim_origin := Vector2.ZERO
var ui_hit_test: Callable
const FIELD := Rect2(20,94,915,548)
const AIM_ZONE := Rect2(20,94,455,548)

func configure(owner_battle: Node2D) -> void:
 battle = owner_battle

func active() -> bool:
 return is_instance_valid(battle) and not battle.paused and not battle.finished

func aim_at(point: Vector2) -> void:
 if active():
  battle.player_turret.set_aim(point)

func human_aim(point: Vector2) -> void:
 if active():
  var previous: Vector2 = battle.player_turret.aim_point
  aim_at(point)
  # Fine mouse/touch samples must accumulate: a slow drag may never move eight
  # units in a single event, even though it is a valid deliberate aim movement.
  human_aim_distance += previous.distance_to(battle.player_turret.aim_point)
  if human_aim_distance >= float(preload("res://scripts/game/mission_tutorial.gd").DATA.aim_distance):
   human_aim_movements += 1
   human_aim_distance = 0.0

func set_fire(source: StringName, held: bool) -> void:
 if held and active():
  fire_sources[source] = true
 else:
  fire_sources.erase(source)
 if is_instance_valid(battle):
  battle.player_turret.set_trigger(not fire_sources.is_empty())

func reload() -> bool:
 return active() and battle.player_turret.request_reload()

func clear() -> void:
 fire_sources.clear()
 aim_finger = -1
 if is_instance_valid(battle.player_turret):
  battle.player_turret.set_trigger(false)

func local_point(canvas_point: Vector2) -> Vector2:
 return battle.get_global_transform_with_canvas().affine_inverse()*canvas_point

func blocked(canvas_point: Vector2) -> bool:
 return ui_hit_test.is_valid() and bool(ui_hit_test.call(canvas_point))

func _input(event: InputEvent) -> void:
 if not is_instance_valid(battle):
  return
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
  set_fire(&"mouse",false)
 if not active():
  return
 if event is InputEventMouseMotion and fire_sources.has(&"mouse") and (blocked(event.position) or not FIELD.has_point(local_point(event.position))):
  set_fire(&"mouse",false)
 if event is InputEventScreenDrag and event.index == aim_finger:
  var point := local_point(event.position)
  var desired := aim_origin+(point-touch_origin)*float(battle.player_turret.definition.touch_sensitivity)
  human_aim(desired.clamp(FIELD.position,FIELD.end))
  get_viewport().set_input_as_handled()
 elif event is InputEventScreenTouch and not event.pressed and event.index == aim_finger:
  aim_finger = -1
  get_viewport().set_input_as_handled()

func handle_unhandled(event: InputEvent) -> void:
 if not active():
  return
 if event is InputEventMouseMotion:
  if FIELD.has_point(local_point(event.position)) and not blocked(event.position):
   human_aim(local_point(event.position))
 elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
  var point := local_point(event.position)
  if FIELD.has_point(point) and not blocked(event.position):
   aim_at(point)
   set_fire(&"mouse",true)
   get_viewport().set_input_as_handled()
 elif event is InputEventScreenTouch and event.pressed and aim_finger == -1:
  var point := local_point(event.position)
  if AIM_ZONE.has_point(point) and not blocked(event.position):
   aim_finger = event.index
   touch_origin = point
   aim_origin = battle.player_turret.aim_point
   get_viewport().set_input_as_handled()
 elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
  reload()
  get_viewport().set_input_as_handled()
