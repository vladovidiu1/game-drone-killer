extends Control
const UI := preload("res://scripts/ui/ui_kit.gd")
var map: Control
func state_color(id: int, frontline: int) -> Color:
 return UI.CYAN if id < frontline or (id == 25 and SaveManager.state.get("campaign_complete",false)) else UI.ORANGE if id == frontline else Color("F04B45")
func _draw() -> void:
 var front := int(SaveManager.state.get("frontline",1))
 var progress := 1.0 if SaveManager.settings.reduced_motion else smoothstep(0,.95,map.transition_age)
 var before := int(map.transition.get("from",front))
 for item in map.LAYOUT.territories:
  var id := int(item.id)
  var tint := state_color(id,before).lerp(state_color(id,front),progress)
  var polygon := PackedVector2Array()
  for p in item.polygon:
   polygon.append(Vector2(float(p[0]),float(p[1])))
  draw_colored_polygon(polygon,Color(tint,.09 if id != front else .17))
  polygon.append(polygon[0])
  draw_polyline(polygon,Color(tint,.29),1.2,true)
  var at: Vector2 = map.point(id)
  if id < 25:
   draw_dashed_line(at,map.point(id+1),Color(tint,.4),2,9,true)
  if id%5 == 1:
   var chapter := (id-1)/5
   draw_string(UI.HEADING,Vector2(80+chapter*310,100),"0%d / %s" % [chapter+1,CampaignManager.CHAPTERS[chapter].to_upper()],HORIZONTAL_ALIGNMENT_LEFT,280,21,UI.WHITE)
  if not map.transition.is_empty() and id == int(map.transition.get("mission_id",0)) and progress < 1:
   draw_arc(at,35+progress*24,0,TAU,40,Color(tint,1-progress),2,true)
 var old_point: Vector2 = map.point(before)
 var current: Vector2 = map.point(front)
 var point := old_point.lerp(current,progress)
 var phase: float = 0.0 if SaveManager.settings.reduced_motion else map.clock*.25
 var line := PackedVector2Array([point+Vector2(-100,-55),point+Vector2(-55,-82),point+Vector2(20,-65),point+Vector2(85,-93)])
 var frontier_tint := UI.CYAN if SaveManager.state.get("campaign_complete",false) else UI.ORANGE
 draw_polyline(line,Color(frontier_tint,.17),8,true)
 draw_polyline(line,frontier_tint,2,true)
 if not SaveManager.settings.reduced_motion:
  draw_circle(line[0].lerp(line[3],fposmod(phase,1)),3,UI.WHITE)
