extends Node2D
# Presentation only; battle owns simulation state and advances this view's effects.
@onready var battle: Node2D = get_parent()
var effects: Array[Dictionary] = []
var base_flash := 0.0

func effect(point: Vector2, kind: String, radius: float, tint: Color) -> void:
 if effects.size() >= int(CampaignManager.combat.effect_limit):
  effects.pop_front()
 effects.append({"point":point,"kind":kind,"radius":radius,"tint":tint,"age":0.0})
 queue_redraw()

func tick(delta: float) -> void:
 base_flash = maxf(0.0,base_flash-delta)
 for i in range(effects.size()-1,-1,-1):
  effects[i].age += delta
  if effects[i].age >= 0.45:
   effects.remove_at(i)
 queue_redraw()

func text(at: Vector2, value: String, color: Color, font_size: int = 16) -> void:
 draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw() -> void:
 draw_rect(Rect2(0,0,1280,720),Color("152730"))
 var terrain: Dictionary = battle.mission_data.get("terrain",{})
 draw_rect(Rect2(0,88,955,560),Color(str(terrain.get("ground","1c343a"))))
 draw_landmarks(str(terrain.get("kind","dry")))
 for i in 70:
  var point := Vector2(25+fmod(i*139.0,900),125+fmod(i*97.0,480))
  draw_circle(point,3+(i%4),Color("294147"))
 for x in range(0,960,48):
  draw_line(Vector2(x,90),Vector2(x,648),Color(0.5,0.7,0.7,0.035))
 for y in range(100,650,48):
  draw_line(Vector2(0,y),Vector2(950,y),Color(0.5,0.7,0.7,0.035))
 if not is_instance_valid(battle) or battle.mission_data.is_empty():
  return
 for path in battle.mission_data.paths:
  var line := PackedVector2Array()
  for point in path:
   line.append(Vector2(float(point[0]),float(point[1])))
  draw_polyline(line,Color(str(terrain.get("edge","0f222b"))),66,true)
  draw_polyline(line,Color(str(terrain.get("road","35484b"))),54,true)
  draw_polyline(line,Color("526365"),2,true)
  var entry: Vector2 = line[0]
  var heading := (line[1]-line[0]).angle()-PI/2
  draw_set_transform(entry,heading)
  draw_line(Vector2(-28,0),Vector2(28,0),Color("ee8f71"),3)
  draw_colored_polygon(PackedVector2Array([Vector2(-8,9),Vector2(8,9),Vector2(0,19)]),Color("ee8f71"))
  draw_set_transform(Vector2.ZERO)
 text(Vector2(38,118),str(terrain.get("label","VARKON AIR CORRIDORS")),Color("c1917f"),14)
 text(Vector2(38,142),"%s / %02d" % [str(battle.mission_data.name).to_upper(),int(battle.mission_id)],Color("88adaf"),18)
 for index in battle.slots.size():
  var point: Vector2 = battle.slots[index]
  var chosen: bool = index == battle.selected_slot
  var color := Color("71e5cd") if chosen else Color("547a80")
  draw_circle(point+Vector2(0,8),38,Color(0,0,0,0.2))
  draw_circle(point,35,Color("1b2d37"))
  draw_arc(point,35,0,TAU,36,color,3 if chosen else 2)
  if battle.placed[index] == null:
   draw_line(point+Vector2(-11,0),point+Vector2(11,0),color,3)
   draw_line(point+Vector2(0,-11),point+Vector2(0,11),color,3)
  text(point+Vector2(-4,53),str(index+1),color,14)
  if chosen and battle.placed[index] != null:
   var turret: Node2D = battle.placed[index]
   draw_circle(point,turret.range_value(),Color(0.4,0.9,0.8,0.04))
   draw_arc(point,turret.range_value(),0,TAU,80,Color(0.4,0.9,0.8,0.28),1.5)
   if is_instance_valid(turret.target) and not turret.target.ended:
    var target: Vector2 = turret.target.position
    draw_arc(target,25,0,TAU,24,Color("f5cf83"),1.5)
 # Base bunker at the bottom of the approach lanes.
 draw_rect(Rect2(418,588,284,52),Color(0,0,0,0.3))
 draw_rect(Rect2(430,573,260,56),Color("354b5c"))
 draw_rect(Rect2(440,566,240,44),Color("ff796b") if base_flash > 0 else Color("536e7b"))
 for x in range(450,680,32):
  draw_rect(Rect2(x,571,16,8),Color("a2c9ca"))
 text(Vector2(442,621),"S-7",Color("d9eeee"),14)
 draw_rect(Rect2(430,635,260,6),Color("0b1b23"))
 draw_rect(Rect2(430,635,260*float(battle.health)/float(battle.max_health),6),Color("69dfba"))
 # A left-thumb guide does not intercept input or cover a placement slot.
 text(Vector2(42,580),"LEFT: DRAG TO AIM",Color("6b999f"),15)
 text(Vector2(42,602),"MOUSE: AIM + HOLD LMB / R: RELOAD",Color("6b999f"),12)
 for item in effects:
  var fraction: float = float(item.age)/0.45
  var tint: Color = item.tint
  tint.a = 1.0-fraction
  if item.kind == "blast":
   draw_circle(item.point,float(item.radius)*fraction,Color(tint,0.18*(1-fraction)))
   draw_arc(item.point,float(item.radius)*fraction,0,TAU,24,tint,3*(1-fraction)+1)
   for j in 6:
    var direction := Vector2.from_angle(j*TAU/6)
    draw_line(item.point+direction*fraction*float(item.radius)*0.5,item.point+direction*fraction*float(item.radius),tint,2)
  elif item.kind == "build":
   draw_arc(item.point,float(item.radius)*(0.5+fraction),0,TAU,32,tint,2)
  else:
   draw_circle(item.point,float(item.radius)*(1-fraction),tint)
 if battle.build_mode:
  text(Vector2(42,550),"TACTICAL BUILD • 0.25x",Color("f6c777"),18)
 if battle.paused:
  draw_rect(Rect2(0,88,950,560),Color(0.02,0.07,0.1,0.4))
  text(Vector2(440,350),"PAUSED",Color("e1eeee"),32)

func draw_landmarks(kind: String) -> void:
 if kind == "rural":
  for origin in [Vector2(100,220),Vector2(90,420),Vector2(790,470)]:
   draw_rect(Rect2(origin+Vector2(8,8),Vector2(100,65)),Color(0,0,0,0.2))
   draw_rect(Rect2(origin,Vector2(100,65)),Color("527348"))
   for i in 6:
    draw_line(origin+Vector2(i*17,0),origin+Vector2(i*17,65),Color("78915e"),3)
  for origin in [Vector2(170,300),Vector2(815,330)]:
   draw_rect(Rect2(origin+Vector2(6,7),Vector2(65,52)),Color("1b2e2b"))
   draw_rect(Rect2(origin,Vector2(65,44)),Color("94765c"))
   draw_colored_polygon(PackedVector2Array([origin+Vector2(-6,0),origin+Vector2(33,-28),origin+Vector2(71,0)]),Color("a96551"))
   draw_rect(Rect2(origin+Vector2(12,12),Vector2(15,14)),Color("c3d2af"))
 elif kind == "industrial":
  for origin in [Vector2(90,280),Vector2(670,115),Vector2(110,480)]:
   draw_rect(Rect2(origin+Vector2(8,9),Vector2(120,70)),Color("15212a"))
   draw_rect(Rect2(origin,Vector2(120,70)),Color("526675"))
   draw_rect(Rect2(origin+Vector2(5,5),Vector2(110,52)),Color("394f61"))
   for i in 6:
    draw_line(origin+Vector2(8+i*19,8),origin+Vector2(8+i*19,52),Color("6b7e8a"),2)
   for i in 8:
    draw_rect(Rect2(origin+Vector2(i*15,63),Vector2(8,5)),Color("e5af58"))
 else:
  for origin in [Vector2(135,250),Vector2(800,460),Vector2(110,420)]:
   for i in 4:
    draw_rect(Rect2(origin+Vector2(i*18,0),Vector2(16,12)),Color("8b8265"))
    draw_line(origin+Vector2(i*18,0),origin+Vector2(i*18+16,0),Color("b2a27b"),2)
  draw_rect(Rect2(155,165,100,48),Color("616b5e"))
  draw_line(Vector2(155,165),Vector2(255,165),Color("a3ad8d"),3)
