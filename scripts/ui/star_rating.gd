extends Control
# Lightweight authored UI glyphs, never a reward or campaign animation callback.
var rating := 0
var reveal := false
var age := 0.0
func _ready() -> void:
 custom_minimum_size = Vector2(174,52)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_process(reveal and not SaveManager.settings.get("reduced_motion",false))
func _process(delta: float) -> void:
 age += delta
 if age >= .65:
  set_process(false)
 queue_redraw()
func _draw() -> void:
 var visible_rating := rating
 if reveal and is_processing():
  visible_rating = mini(rating,int(age/.16))
 for index in 3:
  var points := PackedVector2Array()
  var center := Vector2(25+index*58,25)
  for point in 10:
   points.append(center+Vector2.from_angle(-PI/2+point*PI/5)*(22 if point%2 == 0 else 10))
  draw_colored_polygon(points,Color("FF9C42") if index < visible_rating else Color("303D4C"))
  points.append(points[0])
  draw_polyline(points,Color("f2d9ad") if index < visible_rating else Color("5c7181"),1.2,true)
