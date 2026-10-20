extends Node2D
@onready var cannon: Node2D = get_parent()

func _draw() -> void:
 if cannon.definition.is_empty():
  return
 var tint := Color(str(cannon.ammunition().color))
 draw_circle(Vector2(0,9),32,Color(0,0,0,0.4))
 draw_circle(Vector2.ZERO,29,Color("112231"))
 draw_arc(Vector2.ZERO,29,0,TAU,40,tint,2)
 draw_rect(Rect2(-21,-17,42,34),Color("3c586d"))
 draw_rect(Rect2(-15,-12,30,24),Color("7393a5"))
 draw_set_transform(Vector2.ZERO,cannon.barrel_angle)
 var recoil: float = cannon.recoil
 draw_line(Vector2(-9,0),Vector2(36-recoil,0),Color("101e2d"),16)
 draw_line(Vector2(-6,0),Vector2(35-recoil,0),tint,9)
 draw_rect(Rect2(24-recoil,-7,13,14),Color("d3f6fc"))
 if cannon.muzzle_flash > 0:
  draw_colored_polygon(PackedVector2Array([Vector2(37,-10),Vector2(60,0),Vector2(37,10)]),Color("fff4be"))
 draw_set_transform(Vector2.ZERO)
 # Crosshair belongs to the player cannon, independent of turret selection.
 var crosshair: Vector2 = cannon.aim_point-cannon.position
 var color := (Color("ff6c7e") if cannon.last_critical else Color("fff1a0")) if cannon.hit_confirm > 0 else tint
 draw_arc(crosshair,13,0,TAU,32,color,2)
 for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
  draw_line(crosshair+direction*17,crosshair+direction*24,color,2)
 draw_circle(crosshair,2,color)
 if cannon.reload_remaining > 0:
  draw_arc(Vector2.ZERO,33,-PI/2,-PI/2+TAU*cannon.reload_progress(),40,Color("f6c777"),4)
