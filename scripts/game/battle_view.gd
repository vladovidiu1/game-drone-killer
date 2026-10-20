extends Node2D
# Presentation only; battle owns simulation state and advances this view's effects.
const ASSETS := preload("res://scripts/visual/visual_assets.gd")
const BODY_FONT := preload("res://assets/ui/fonts/Barlow-Regular.ttf")
@onready var battle: Node2D = get_parent()
var effects: Array[Dictionary] = []
var base_flash := 0.0
var destruction := preload("res://scripts/visual/destruction_batch.gd").new()

var environment: Control
var telemetry: Node2D
var combat_fx: Node2D

func _ready() -> void:
 combat_fx = preload("res://scenes/effects/combat_effects.tscn").instantiate()
 add_child(combat_fx)
 environment = preload("res://scripts/visual/battle_environment.gd").new()
 environment.setup(battle.mission_data)
 add_child(environment)
 telemetry = preload("res://scripts/visual/boss_telemetry.gd").new()
 telemetry.battle = battle
 telemetry.z_index = 2
 add_child(telemetry)
 # Stable integration anchor retained for G1 tooling, now backed by the library.
 if battle.mission_id == 1:
  environment.name = "OutpostTerrain"

func effect(point: Vector2, kind: String, radius: float, tint: Color) -> void:
 var limit := mini(int(CampaignManager.combat.effect_limit),24 if combat_fx.reduced else 48 if int(combat_fx.profile.particles) <= 48 else 96)
 if kind == "blast":
  var blasts := 0
  var oldest := -1
  for index in effects.size():
   if effects[index].kind == "blast":
    blasts += 1
    if oldest < 0:
     oldest = index
  if blasts >= int(combat_fx.profile.explosions) and oldest >= 0:
   effects.remove_at(oldest)
 if kind == "hit":
  for item in effects:
   if item.kind == "hit" and Vector2(item.point).distance_squared_to(point) < 81:
    item.age = 0.0
    return
 while effects.size() >= limit:
  effects.pop_front()
 effects.append({"point":point,"kind":kind,"radius":radius,"tint":tint,"age":0.0,"duration":0.65 if kind in ["blast","pulse"] else 0.15 if kind == "hit" else 0.45})
 if kind == "pulse":
  combat_fx.pulse(point,radius,tint)
 queue_redraw()

func tick(delta: float) -> void:
 combat_fx.tick(delta)
 combat_fx.observe(battle,delta)
 preload("res://scripts/visual/combat_visuals.gd").advance(battle,delta)
 environment.tick(delta)
 telemetry.queue_redraw()
 destruction.tick(delta)
 base_flash = maxf(0.0,base_flash-delta)
 for i in range(effects.size()-1,-1,-1):
  effects[i].age += delta
  if effects[i].age >= float(effects[i].duration):
   effects.remove_at(i)
 queue_redraw()

func tick_outro(delta: float) -> void:
 combat_fx.tick(delta)
 telemetry.queue_redraw()
 destruction.tick(delta)
 for index in range(effects.size()-1,-1,-1):
  effects[index].age += delta
  if effects[index].age >= float(effects[index].duration):
   effects.remove_at(index)
 queue_redraw()

# Foreground effects are painted by the clipped scene above drone bodies,
# beneath boss telemetry and the native HUD. Rendering never resolves a hit.
func paint_effects(canvas: CanvasItem) -> void:
 for item in effects:
  var fraction: float = float(item.age)/float(item.duration)
  var tint: Color = item.tint
  tint.a = 1.0-fraction
  if item.kind == "blast":
   # Grid-interference/large tactical cues must not become field-covering
   # fireballs when impacts move to the foreground. Keep actors legible.
   if float(item.radius) > 160:
    var pulse_radius: float = float(item.radius)*(1.0 if combat_fx.motion else .4+fraction*.6)
    canvas.draw_arc(item.point,pulse_radius,0,TAU,64,Color(tint,tint.a*.45),2,true)
    continue
   if not combat_fx.smoke and fraction >= .5:
    continue
   var frame := ASSETS.explosion_frame(mini(5,int(fraction*6)))
   var diameter := maxf(28.0,float(item.radius)*2.5)
   canvas.draw_texture_rect(ASSETS.texture("effects/soft_shadow.svg"),Rect2(item.point-Vector2(diameter*.5,diameter*.15),Vector2(diameter,diameter*.4)),false,Color(1,1,1,1-fraction))
   canvas.draw_texture_rect(frame,Rect2(item.point-Vector2.ONE*diameter*.5,Vector2.ONE*diameter),false,Color(1,1,1,1.0-smoothstep(0.6,1.0,fraction)))
  elif item.kind == "pulse":
   var radius: float = float(item.radius)*(1.0 if combat_fx.motion else fraction)
   canvas.draw_arc(item.point,radius,0,TAU,64,tint,2.5*(1-fraction)+0.5)
   canvas.draw_arc(item.point,radius*.78,0,TAU,48,Color(tint,tint.a*.35),1)
  elif item.kind == "build":
   canvas.draw_arc(item.point,float(item.radius)*(1.0 if combat_fx.motion else 0.5+fraction),0,TAU,32,tint,2)
  else:
   for direction in [Vector2(1,1),Vector2(1,-1)]:
    var offset: Vector2 = direction*float(item.radius)*(0.4+fraction)
    canvas.draw_line(item.point-offset,item.point+offset,Color(1,0.85,0.63,1-fraction),2*(1-fraction))

func text(at: Vector2, value: String, color: Color, font_size: int = 16) -> void:
 draw_string(BODY_FONT,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw() -> void:
 var terrain: Dictionary = battle.mission_data.get("terrain",{})
 draw_rect(Rect2(0,0,1280,88),Color("151B24"))
 draw_rect(Rect2(955,88,325,560),Color("151B24"))
 draw_rect(Rect2(0,648,1280,72),Color("151B24"))
 if not is_instance_valid(battle) or battle.mission_data.is_empty():
  return
 for path in battle.mission_data.paths:
  var line := PackedVector2Array()
  for point in path:
   line.append(Vector2(float(point[0]),float(point[1])))
  # Flight corridors remain exactly data-driven; subtle dashed telemetry
  # does not paint over the illustrated ground roads or imply ground collision.
  for index in range(1,line.size()):
   draw_dashed_line(line[index-1],line[index],Color(.82,.85,.83,.23),1.0,8.0)
  var entry: Vector2 = line[0]
  var heading := (line[1]-line[0]).angle()-PI/2
  draw_set_transform(entry,heading)
  draw_line(Vector2(-28,0),Vector2(28,0),Color("ee8f71"),3)
  draw_colored_polygon(PackedVector2Array([Vector2(-8,9),Vector2(8,9),Vector2(0,19)]),Color("ee8f71"))
  draw_set_transform(Vector2.ZERO)
 draw_rect(Rect2(26,98,320,54),Color(0.05,0.075,0.1,0.85))
 text(Vector2(38,118),str(terrain.get("label","VARKON AIR CORRIDORS")),Color("98acbb"),14)
 text(Vector2(38,142),"%s / %02d" % [str(battle.mission_data.name).to_upper(),int(battle.mission_id)],Color("E9F0F6"),18)
 for index in battle.slots.size():
  var point: Vector2 = battle.slots[index]
  var chosen: bool = index == battle.selected_slot
  var color := Color("37B7E5") if chosen else Color("9ca59e")
  if environment.assignment.type in ["bridge","harbor"]:
   # Raised steel emplacement decks keep unchanged river/quay slots legible.
   draw_texture_rect(preload("res://assets/environment/emplacement_deck.svg"),Rect2(point-Vector2(48,45),Vector2(96,90)),false)
  draw_texture_rect(ASSETS.texture("turrets/placement_pad.svg"),Rect2(point-Vector2(40,40),Vector2(80,80)),false)
  if chosen:
   draw_arc(point,39,0,TAU,40,color,2)
  if battle.placed[index] == null:
   draw_line(point+Vector2(-11,0),point+Vector2(11,0),color,3)
   draw_line(point+Vector2(0,-11),point+Vector2(0,11),color,3)
  draw_rect(Rect2(point+Vector2(-33,-29),Vector2(14,17)),Color("151B24"))
  text(point+Vector2(-30,-16),str(index+1),Color("E9F0F6"),13)
  if chosen and battle.placed[index] != null:
   var turret: Node2D = battle.placed[index]
   draw_circle(point,turret.range_value(),Color(0.216,0.718,0.898,0.05))
   draw_arc(point,turret.range_value(),0,TAU,80,Color(0.216,0.718,0.898,0.3),1.5)
   if is_instance_valid(turret.target) and not turret.target.ended:
    var target: Vector2 = turret.target.position
    draw_arc(target,25,0,TAU,24,Color("f5cf83"),1.5)
 # Base bunker at the bottom of the approach lanes.
 draw_texture_rect(ASSETS.sprite("command_bunker"),Rect2(400,564,320,86),false,Color(1,0.6,0.5) if base_flash > 0 else Color.WHITE)
 text(Vector2(442,621),"S-7",Color("d9eeee"),14)
 draw_rect(Rect2(430,635,260,6),Color("0b1b23"))
 draw_rect(Rect2(430,635,260*float(battle.health)/float(battle.max_health),6),Color("37B7E5"))
 destruction.draw(self)
 var condition: Dictionary = battle.mission_data.get("environment",{})
 if condition.get("kind") == "dust":
  text(Vector2(38,167),"DUST: AUTOMATIC RANGE -13% / MANUAL CANNON UNAFFECTED",Color("e7c58c"),13)
 var warning: float = battle.environment_warning()
 if warning > 0:
  text(Vector2(280,190),"GRID SURGE IN %.1fs / MANUAL CANNON REMAINS ONLINE" % warning,Color("f7ad7a"),16)
 if battle.build_mode:
  text(Vector2(42,550),"TACTICAL BUILD • 0.25x",Color("f6c777"),18)
 if battle.paused and not battle.finished:
  draw_rect(Rect2(0,88,950,560),Color(0.02,0.07,0.1,0.4))
  text(Vector2(440,350),"PAUSED",Color("e1eeee"),32)
