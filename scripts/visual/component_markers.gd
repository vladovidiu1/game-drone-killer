extends Node2D
# Batched component cues. No collision, damage, stat or movement decisions.
const FONT := preload("res://assets/ui/fonts/Barlow-Regular.ttf")
var rig: RefCounted
var timer := 0.0

func tick(delta: float) -> void:
 timer -= delta
 if timer <= 0:
  timer = 1.0/float(rig.enemy.art.graphics.unit_overlay_hz)
  queue_redraw()

func _draw() -> void:
 if rig == null or rig.enemy.ended:
  return
 var battle: Node2D = rig.enemy.brain.battle
 var aim: Vector2 = battle.player_turret.aim_point if is_instance_valid(battle.player_turret) else Vector2.INF
 var highlighted: Node2D = null
 var closest := 26.0
 for part in rig.parts:
  if part.kind == "body":
   continue
  var local := to_local(part.global_position)
  var edge := to_local(part.to_global(Vector2(part.radius,0)))
  var radius := maxf(3,edge.distance_to(local))
  var distance: float = aim.distance_to(part.point())
  if part.collider_enabled() and distance < closest:
   closest = distance
   highlighted = part
  var tint := Color("8ccfe4") if part.kind == "core" else Color("ff9c42")
  if part.broken:
   tint = Color("f48c4e") if part.kind == "core" else Color("85929a")
  if part.kind == "core":
   if not part.open():
    tint = Color("778896")
   draw_arc(local,radius,0,TAU,24,tint,1.8,true)
   draw_circle(local,maxf(2,radius*.35),Color(tint,.8))
  elif part.flash > 0:
   draw_arc(local,radius,0,TAU,16,Color(1,.9,.65),1.5,true)
  elif part.broken:
   draw_line(local-Vector2(4,4),local+Vector2(4,4),tint,1.5,true)
   draw_line(local+Vector2(-4,4),local+Vector2(4,-4),tint,1.5,true)
 if highlighted != null and not rig.falling:
  var point := to_local(highlighted.global_position)
  draw_arc(point,13,0,TAU,20,Color("ffcf83"),1.5,true)
  var label := str(highlighted.definition.name).to_upper()+" / %d%%" % int(100*highlighted.live_health()/maxf(1,highlighted.live_maximum()))
  if highlighted.kind == "core" and not highlighted.open():
   label += " / SEALED"
  draw_string(FONT,point+Vector2(-40,-20),label,HORIZONTAL_ALIGNMENT_LEFT,240,12,Color("e9f0f6"))
 if rig.feedback_time > 0:
  draw_string(FONT,Vector2(-70,-54*rig.enemy.body_scale),rig.feedback,HORIZONTAL_ALIGNMENT_LEFT,260,13,Color("ffcc82"))
 if rig.falling:
  draw_string(FONT,Vector2(-40,-36),"CRASHING",HORIZONTAL_ALIGNMENT_LEFT,120,13,Color("ff9c42"))
