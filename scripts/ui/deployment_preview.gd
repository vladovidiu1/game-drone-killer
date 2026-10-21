extends Control
# Known terrain/routes/slots only: no director, RNG or surprise-wave access.
const UI := preload("res://scripts/ui/ui_kit.gd")
const FONT := preload("res://assets/ui/fonts/Barlow-Regular.ttf")
var data: Dictionary
var terrain: Texture2D

func setup(definition: Dictionary) -> void:
 data = definition
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 custom_minimum_size = Vector2(300,230)
 var image := UI.mission_image(int(data.id))
 terrain = image.texture
 image.free()
 resized.connect(queue_redraw)

func map_rect() -> Rect2:
 var scale_factor := minf(size.x/955.0,size.y/560.0)
 var dimensions := Vector2(955,560)*scale_factor
 return Rect2((size-dimensions)*.5,dimensions)

func project(point: Array) -> Vector2:
 var rect := map_rect()
 return rect.position+Vector2(float(point[0])/955.0,(float(point[1])-88)/560.0)*rect.size

func _draw() -> void:
 if data.is_empty() or terrain == null:
  return
 draw_texture_rect(terrain,map_rect(),false)
 for index in data.paths.size():
  var points := PackedVector2Array()
  for point in data.paths[index]:
   points.append(project(point))
  draw_polyline(points,Color("ff9c42"),1.5,true)
  draw_string(FONT,points[0]+Vector2(3,13),str(data.approaches.sectors[index]).substr(0,1),HORIZONTAL_ALIGNMENT_LEFT,30,13,Color.WHITE)
 for index in data.slots.size():
  var point := project(data.slots[index])
  var elevated: bool = data.emplacements[index].role == "elevated"
  draw_circle(point,10,Color("151b24"))
  draw_arc(point,10,0,TAU,20,Color("ff9c42" if elevated else "37b7e5"),1.5,true)
  draw_string(FONT,point+Vector2(-4,4),str(index+1),HORIZONTAL_ALIGNMENT_LEFT,18,12,Color.WHITE)
 var base := project(data.approaches.target)
 draw_rect(Rect2(base-Vector2(22,5),Vector2(44,11)),Color("37b7e5"))
