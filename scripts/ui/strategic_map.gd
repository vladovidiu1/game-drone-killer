extends Control
signal mission_selected(id: int)
const UI := preload("res://scripts/ui/ui_kit.gd")
static var LAYOUT: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/campaign_layout.json"))
var world: Control
var nodes: Array[Button] = []
var pan := Vector2.ZERO
var pan_target := Vector2.ZERO
var dragging := false
var pointer := -1
var origin := Vector2.ZERO
var previous := Vector2.ZERO
var moved := false
var clock := 0.0
var transition: Dictionary = {}
var transition_age := 2.0
var recenter_pending := true
var caption: Label
func _ready() -> void:
 clip_contents = true
 mouse_filter = Control.MOUSE_FILTER_STOP
 custom_minimum_size = Vector2(0,280)
 world = Control.new()
 world.mouse_filter = Control.MOUSE_FILTER_IGNORE
 world.size = Vector2(1600,900)
 add_child(world)
 var terrain := TextureRect.new()
 terrain.texture = preload("res://assets/ui/asteria_strategy.svg")
 terrain.size = world.size
 terrain.mouse_filter = Control.MOUSE_FILTER_IGNORE
 world.add_child(terrain)
 var overlay := Control.new()
 overlay.set_script(preload("res://scripts/ui/map_overlay.gd"))
 overlay.map = self
 overlay.size = world.size
 overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 world.add_child(overlay)
 for item in LAYOUT.territories:
  var node := preload("res://scripts/ui/map_node.gd").new()
  node.setup(int(item.id))
  node.position = Vector2(float(item.position[0]),float(item.position[1]))-Vector2(27,32)
  node.pressed.connect(func():
   if not moved:
    mission_selected.emit(int(node.mission_id)))
  node.gui_input.connect(_node_input.bind(node))
  node.focus_entered.connect(_focus_node.bind(int(item.id)))
  world.add_child(node)
  nodes.append(node)
 caption = UI.label("DRAG TO PAN  /  25 OPERATIONS",12,UI.WHITE)
 caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
 caption.add_theme_color_override("font_shadow_color",Color.BLACK)
 caption.add_theme_constant_override("shadow_outline_size",4)
 add_child(caption)
 resized.connect(func():
  recenter_pending = true
  caption.position = Vector2(16,size.y-29))
func _focus_node(id: int) -> void:
 var rect := Rect2(pan+point(id)-Vector2(27,32),Vector2(190,64))
 if not Rect2(Vector2.ZERO,size).encloses(rect):
  pan_target = bounded(size*.5-point(id)-Vector2(45,0))

func point(id: int) -> Vector2:
 var position_data: Array = LAYOUT.territories[clampi(id,1,25)-1].position
 return Vector2(float(position_data[0]),float(position_data[1]))
func focus_current(immediate: bool = false) -> void:
 pan_target = bounded(size*.5-point(int(SaveManager.state.get("frontline",1)))-Vector2(45,0))
 if immediate or SaveManager.settings.reduced_motion:
  pan = pan_target
  world.position = pan
func bounded(value: Vector2) -> Vector2:
 return Vector2(clampf(value.x,minf(0,size.x-1600),0),clampf(value.y,minf(0,size.y-900),0))
func _process(delta: float) -> void:
 if recenter_pending:
  recenter_pending = false
  focus_current(true)
 clock += delta
 transition_age = minf(2.0,transition_age+delta)
 pan = pan.move_toward(pan_target,delta*1100) if SaveManager.settings.reduced_motion else pan.lerp(pan_target,1-exp(-delta*15))
 world.position = pan.round()
 world.get_child(1).queue_redraw()
 for node in nodes:
  node.clock = clock
  if node.current:
   node.queue_redraw()
 queue_redraw()
func _node_input(event: InputEvent, node: Button) -> void:
 if event is InputEventScreenTouch or event is InputEventScreenDrag:
  _pointer_input(event,node.global_position)
 elif event is InputEventMouseButton or event is InputEventMouseMotion:
  _pointer_input(event,node.global_position)
func _gui_input(event: InputEvent) -> void:
 _pointer_input(event,global_position)
func _pointer_input(event: InputEvent, offset: Vector2) -> void:
 if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
  pan_target = bounded(pan_target+Vector2(0,100 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -100))
 elif event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
  var event_id: int = event.index if event is InputEventScreenTouch else -2
  if event.pressed and pointer == -1:
   pointer = event_id
   origin = event.position+offset
   previous = origin
   dragging = true
   moved = false
  elif not event.pressed and pointer == event_id:
   dragging = false
   pointer = -1
   _clear_drag.call_deferred()
 elif event is InputEventScreenDrag or event is InputEventMouseMotion:
  var event_id: int = event.index if event is InputEventScreenDrag else -2
  if dragging and pointer == event_id:
   var position_now: Vector2 = event.position+offset
   if moved or position_now.distance_to(origin) > 12:
    moved = true
    pan_target = bounded(pan_target+(position_now-previous))
    pan = pan_target
   previous = position_now
func _input(event: InputEvent) -> void:
 # Observe only release outside the clipped map, never steal other controls.
 if dragging and ((event is InputEventScreenTouch and not event.pressed and event.index == pointer) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed)):
  dragging = false
  pointer = -1
  _clear_drag.call_deferred()
func _clear_drag() -> void:
 moved = false
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("151B24"),false,2)
 draw_string(UI.MONO,Vector2(16,size.y-15),"ASTERIA / STRATEGIC OVERVIEW  •  DRAG TO PAN",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("b4c8cf"))
