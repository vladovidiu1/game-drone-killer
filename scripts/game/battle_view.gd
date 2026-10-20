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
 draw_sector_details(terrain)
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
 var condition: Dictionary = battle.mission_data.get("environment",{})
 if condition.get("kind") == "dust":
  draw_rect(Rect2(0,88,950,560),Color(0.8,0.65,0.4,0.08))
  text(Vector2(38,167),"DUST: AUTOMATIC RANGE -13% / MANUAL CANNON UNAFFECTED",Color("e7c58c"),13)
 var warning: float = battle.environment_warning()
 if warning > 0:
  text(Vector2(280,190),"GRID SURGE IN %.1fs / MANUAL CANNON REMAINS ONLINE" % warning,Color("f7ad7a"),16)
 for enemy in battle.drones.get_children():
  if not enemy.ended and enemy.brain != null and enemy.brain.boss:
   var definition: Dictionary = CampaignManager.enemies[battle.mission_data.boss]
   draw_rect(Rect2(250,174,470,84),Color(0.03,0.07,0.12,0.88))
   text(Vector2(265,190),str(definition.name).to_upper()+" / "+str(enemy.brain.settings().name),enemy.tint,14)
   text(Vector2(270,248),"SIEGE CAPACITOR: %.0fs • BREAK THE CORE" % maxf(0,float(enemy.brain.data.overload_after)-enemy.brain.elapsed),Color("ffad83"),14)
   draw_rect(Rect2(270,200,430,10),Color("101d2a"))
   draw_rect(Rect2(270,200,430*enemy.health/enemy.maximum_health,10),enemy.tint)
   text(Vector2(270,230),"%.0f / %.0f HP • AIM AT CYAN CORE" % [enemy.health,enemy.maximum_health],Color("a9eeee"),13)
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

func draw_sector_details(terrain: Dictionary) -> void:
 var kind := str(terrain.get("kind","dry"))
 if kind in ["river","bridge","harbor"]:
  draw_rect(Rect2(35,310,880,85),Color("214958"))
  for y in range(318,390,15):
   draw_line(Vector2(35,y),Vector2(915,y),Color("3b6975"),2)
  for x in [270,700]:
   draw_rect(Rect2(x,290,95,130),Color("6b7170"))
 elif kind in ["highway","airbase"]:
  draw_rect(Rect2(65,205,835,95),Color("303d46"))
  for x in range(80,900,60):
   draw_rect(Rect2(x,249,30,4),Color("a4ae9c"))
 elif kind in ["ridge","valley","deadlands"]:
  for x in [80,780]:
   draw_colored_polygon(PackedVector2Array([Vector2(x,170),Vector2(x+110,250),Vector2(x+80,450),Vector2(x-35,390)]),Color("514c49"))
 elif kind in ["capital","metro","ruins"]:
  for x in [95,785]:
   for y in [190,420]:
    draw_rect(Rect2(x+8,y+8,100,115),Color("14212d"))
    draw_rect(Rect2(x,y,100,115),Color("536173"))
    for row in 4:
     for column in 3:
      draw_rect(Rect2(x+12+column*28,y+12+row*24,12,11),Color("9baaad"))
 elif kind in ["hive","factory","power","fortress"]:
  for x in [110,815]:
   draw_circle(Vector2(x,290),55,Color("273342"))
   draw_arc(Vector2(x,290),48,0,TAU,12,Color("9b6988") if kind == "hive" else Color("8ca3a3"),6)
   draw_line(Vector2(x,345),Vector2(x,490),Color("65767d"),12)
 for item in terrain.get("landmarks",[]):
  var rect: Array = item.rect
  var shape := Rect2(float(rect[0]),float(rect[1]),float(rect[2]),float(rect[3]))
  draw_rect(Rect2(shape.position+Vector2(7,9),shape.size),Color(0,0,0,0.25))
  draw_rect(shape,Color("4b5d66"))
  draw_rect(shape.grow(-7),Color("354955"))
  for x in range(int(shape.position.x)+10,int(shape.end.x)-8,20):
   draw_line(Vector2(x,shape.position.y+7),Vector2(x,shape.end.y-7),Color("6c7c81"),2)
