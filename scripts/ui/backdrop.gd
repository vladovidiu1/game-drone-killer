extends Control

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)

func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("0b1722"))
 for i in range(0,int(size.x)+80,64):
  draw_line(Vector2(i,0),Vector2(i-size.y*0.3,size.y),Color(0.3,0.7,0.8,0.045))
 for j in range(0,int(size.y),64):
  draw_line(Vector2(0,j),Vector2(size.x,j),Color(0.3,0.7,0.8,0.045))
 var points := PackedVector2Array([Vector2(size.x*0.56,size.y),Vector2(size.x*0.75,size.y*0.23),Vector2(size.x*0.87,size.y*0.48),Vector2(size.x,size.y*0.1),size])
 draw_colored_polygon(points,Color("102a38"))
