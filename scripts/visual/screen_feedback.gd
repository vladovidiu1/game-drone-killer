extends Node2D
const FONT := preload("res://assets/ui/fonts/BarlowCondensed-Bold.ttf")

func _draw() -> void:
 var fx: Node2D = get_parent()
 # Soft field-edge strips, no full-screen white flash or repeated strobing.
 if fx.damage_age > 0:
  var alpha: float = minf(.19,float(fx.damage_age)*.38)
  for index in 8:
   var tint := Color("F04B45")
   tint.a = alpha*(1.0-float(index)/8)*(.55 if fx.reduced else 1.0)
   var inset := float(index)*4
   draw_rect(Rect2(inset,88+inset,955-inset*2,560-inset*2),tint,false,4)
  if fx.critical_base:
   draw_string(FONT,Vector2(370,545),"CRITICAL BASE DAMAGE",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color(1,.55,.42,fx.damage_age*1.5))
 if fx.banner_age > 0:
  var alpha: float = minf(1.0,fx.banner_age*2)
  draw_rect(Rect2(365,98,550,58),Color(.05,.08,.11,.9*alpha))
  var tint := Color("37B7E5") if fx.victory else Color("FF9C42")
  tint.a = alpha
  draw_line(Vector2(365,98),Vector2(915,98),tint,2)
  var parts: PackedStringArray = str(fx.banner).split(" / ",true,1)
  if parts.size() == 2:
   draw_string(FONT,Vector2(383,118),parts[0],HORIZONTAL_ALIGNMENT_LEFT,514,14,tint)
   draw_string(FONT,Vector2(383,144),parts[1],HORIZONTAL_ALIGNMENT_LEFT,514,24,Color(.91,.94,.97,alpha))
  else:
   draw_string(FONT,Vector2(383,137),fx.banner,HORIZONTAL_ALIGNMENT_LEFT,514,24,tint)
 if fx.reload_fraction >= 0:
  draw_rect(Rect2(516,644,88,3),Color("303D4C"))
  draw_rect(Rect2(516,644,88*fx.reload_fraction,3),Color("FF9C42"))
 if fx.ready_age > 0:
  draw_string(FONT,Vector2(530,563),"READY",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(.22,.72,.9,minf(1,fx.ready_age*3)))
