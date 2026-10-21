extends Node2D
# Three sector entry markers and the threatened objective; no gameplay state writes.
const FONT := preload("res://assets/ui/fonts/Barlow-Regular.ttf")
var battle: Node2D
var clock := 0.0
var redraw_timer := 0.0

func tick(delta: float) -> void:
 clock += delta
 redraw_timer -= delta
 if redraw_timer <= 0:
  redraw_timer = .1
  queue_redraw()

func _draw() -> void:
 if not is_instance_valid(battle.spawner) or battle.spawner.plan.is_empty():
  return
 var plan: Dictionary = battle.spawner.plan
 var prep: bool = battle.spawner.intermission
 var motion: bool = not SaveManager.settings.get("reduced_motion",false)
 var alpha := .8 if not motion else .68+.12*sin(clock*3)
 for sector in ["WEST","CENTER","EAST"]:
  if int(plan.sectors[sector]) == 0:
   continue
  for index in battle.mission_data.paths.size():
   if str(battle.mission_data.approaches.sectors[index]) != sector:
    continue
   var route: Array = battle.mission_data.paths[index]
   var point := Vector2(route[0][0],route[0][1])
   var direction := (Vector2(route[1][0],route[1][1])-point).normalized()
   var across := direction.orthogonal()*10
   var color := Color("ff9c42" if prep else "f04b45",alpha)
   var tip := point+direction*30
   draw_polyline(PackedVector2Array([tip-direction*12+across,tip,tip-direction*12-across]),color,2,true)
   draw_line(point,tip-direction*4,color,2,true)
   draw_string(FONT,point+Vector2(-12,-5),sector.substr(0,1),HORIZONTAL_ALIGNMENT_LEFT,30,14,color)
 draw_arc(Vector2(560,600),54,PI,TAU,24,Color("37b7e5",.65),1.5,true)
