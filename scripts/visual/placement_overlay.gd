extends Node2D
# Clipped presentation only. Uses exactly the same geometry as actual targeting.
const RULES := preload("res://scripts/game/placement_rules.gd")
const DIRECTOR := preload("res://scripts/game/tactical_attack_director.gd")
const FONT := preload("res://assets/ui/fonts/Barlow-Regular.ttf")
var battle: Node2D
var redraw_timer := 0.0

func tick(delta: float) -> void:
 redraw_timer -= delta
 if redraw_timer <= 0:
  redraw_timer = .1
  queue_redraw()

func paint_arc(origin: Vector2, radius: float, bearing: float, degrees: float, tint: Color) -> void:
 var half := deg_to_rad(degrees*.5)
 var points := PackedVector2Array([origin])
 var edge := PackedVector2Array()
 for index in 49:
  var point := origin+Vector2.from_angle(bearing-half+half*2*index/48.0)*radius
  points.append(point)
  edge.append(point)
 draw_colored_polygon(points,Color(tint,.045))
 draw_polyline(edge,Color(tint,.55),1.4,true)
 if degrees < 360:
  draw_line(origin,edge[0],Color(tint,.4),1,true)
  draw_line(origin,edge[-1],Color(tint,.4),1,true)
 draw_line(origin,origin+Vector2.from_angle(bearing)*42,tint,2,true)

func point_coverage(point: Vector2) -> Dictionary:
 var result := {"weapons":0,"support":0}
 for turret in battle.turrets.get_children():
  if not turret.covers_point(point) or turret.disabled_remaining > 0:
   continue
  result["support" if turret.kind == "emp_tower" else "weapons"] += 1
 return result

func _draw() -> void:
 if not is_instance_valid(battle.movement):
  return
 var moving: RefCounted = battle.movement
 for index in battle.slots.size():
  var turret: Node2D = battle.placed[index]
  if is_instance_valid(turret) and (battle.coverage_visible or index == battle.selected_slot):
   paint_arc(turret.position,turret.range_value(),turret.bearing,float(turret.definition.traverse_degrees),Color("768997") if turret.redeploying or turret.disabled_remaining > 0 else Color("37b7e5"))
  if moving.source >= 0 and not moving.active and moving.valid_destination(index):
   draw_arc(battle.slots[index],43,0,TAU,36,Color("8bd8b6"),2,true)
   draw_string(FONT,battle.slots[index]+Vector2(-28,59),"MOVE",HORIZONTAL_ALIGNMENT_LEFT,65,14,Color("8bd8b6"))
  if str(battle.mission_data.emplacements[index].role) == "elevated":
   draw_line(battle.slots[index]+Vector2(-28,31),battle.slots[index]+Vector2(28,31),Color("ff9c42"),3,true)
   draw_string(FONT,battle.slots[index]+Vector2(20,-28),"+%.0f%%" % ((float(battle.mission_data.emplacements[index].range_multiplier)-1)*100),HORIZONTAL_ALIGNMENT_LEFT,42,12,Color("ff9c42"))
 if moving.source >= 0 and moving.destination >= 0 and is_instance_valid(moving.actor):
  var from: Vector2 = battle.slots[moving.source]
  var to: Vector2 = battle.slots[moving.destination]
  var data: Dictionary = battle.mission_data.emplacements[moving.destination]
  var radius: float = moving.actor.range_value()/moving.actor.range_multiplier*float(data.range_multiplier)
  paint_arc(to,radius,deg_to_rad(float(data.bearing_degrees)),float(moving.actor.definition.traverse_degrees),Color("ff9c42"))
  draw_dashed_line(from,to,Color("ff9c42"),2,9)
  draw_arc(to,43,0,TAU,36,Color("ff9c42"),3,true)
  if moving.active:
   var progress: float = clampf(moving.elapsed/moving.duration(),0,1)
   draw_circle(from.lerp(to,progress),5,Color("ff9c42"))
   draw_arc(from,45,-PI/2,-PI/2+TAU*progress,36,Color("ff9c42"),3,true)
 if not battle.coverage_visible:
  return
 var uncovered := {"WEST":0,"CENTER":0,"EAST":0}
 for index in battle.mission_data.paths.size():
  for height in RULES.CONFIG.coverage_samples_y:
   var point := DIRECTOR.point_at_y(battle.mission_data.paths[index],float(height))
   var reach := point_coverage(point)
   var covered: bool = int(reach.weapons) > 0
   if not covered:
    uncovered[str(battle.mission_data.approaches.sectors[index])] += 1
   draw_circle(point,4,Color("37b7e5") if covered else Color("ff9c42"))
   if int(reach.support) > 0:
    draw_arc(point,8,0,TAU,12,Color("a9baff"),1.5,true)
 draw_rect(Rect2(22,564,350,62),Color("151b24e8"))
 draw_string(FONT,Vector2(32,583),"SECONDARY REACH / NOT A KILL GUARANTEE",HORIZONTAL_ALIGNMENT_LEFT,330,13,Color("e9f0f6"))
 draw_string(FONT,Vector2(32,605),"GAPS  W %d · C %d · E %d  /  PURPLE: SUPPORT" % [uncovered.WEST,uncovered.CENTER,uncovered.EAST],HORIZONTAL_ALIGNMENT_LEFT,330,13,Color("ff9c42"))
