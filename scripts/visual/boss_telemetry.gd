extends Node2D
# Tactical information stays above larger G3 silhouettes, independent of bodies.
const FONT := preload("res://assets/ui/fonts/Barlow-Regular.ttf")
var battle: Node2D

func text(at: Vector2, value: String, color: Color, pixels: int = 14) -> void:
 draw_string(FONT,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)

func _draw() -> void:
 if not is_instance_valid(battle) or not is_instance_valid(battle.drones):
  return
 for enemy in battle.drones.get_children():
  if enemy.ended or enemy.brain == null or not enemy.brain.boss:
   continue
  draw_rect(Rect2(250,174,470,84),Color(.03,.07,.12,.94))
  text(Vector2(265,190),"%s / PHASE %d / %s" % [enemy.display_name.to_upper(),enemy.brain.phase_index+1,str(enemy.brain.settings().name)],enemy.tint,13)
  draw_rect(Rect2(270,200,430,10),Color("101d2a"))
  draw_rect(Rect2(270,200,430*enemy.health/enemy.maximum_health,10),enemy.tint)
  text(Vector2(270,230),"%.0f / %.0f HP • AIM AT CYAN CORE" % [enemy.health,enemy.maximum_health],Color("a9eeee"),13)
  text(Vector2(270,248),"SIEGE CAPACITOR: %.0fs • BREAK THE CORE" % maxf(0,float(enemy.brain.data.overload_after)-enemy.brain.elapsed),Color("ffad83"),13)
