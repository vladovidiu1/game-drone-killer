extends Node2D
# Fixed reusable particle slots. All events are cosmetic snapshots; never retain
# enemies/projectiles or consume gameplay RNG. Time is supplied by BattleView.
const ASSETS := preload("res://scripts/visual/visual_assets.gd")
static var PROFILES: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/effects/quality.json"))
const HARD_LIMIT := 192
const FIELD := Rect2(0,88,955,560)
var profile: Dictionary = {}
var reduced := false
var motion := false
var smoke := true
var debris := true
var lighting := true
var shake_enabled := true
var slots: Array[Dictionary] = []
var free_slots: Array[int] = []
var active: Array[int] = []
var clock := 0.0
var serial := 0
var emitted := 0
var dropped := 0
var peak := 0
var laser_timer := 0.0
var damage_age := 0.0
var critical_base := false
var shake_remaining := 0.0
var shake_strength := 0.0
var shake_offset := Vector2.ZERO
var banner := ""
var banner_age := 0.0
var victory := false
var disabled_points: Array[Vector2] = []
var last_reload := false
var ready_age := 0.0
var reload_fraction := -1.0
@onready var painter: Node2D = $FieldClip/Particles
@onready var feedback: Node2D = $ScreenFeedback

func _ready() -> void:
 configure(SaveManager.settings)
 for index in HARD_LIMIT:
  slots.append({})
  free_slots.append(index)

func configure(settings: Dictionary) -> void:
 profile = preload("res://scripts/visual/graphics_profile.gd").resolve(settings)
 reduced = bool(profile.reduced)
 motion = bool(profile.motion)
 smoke = bool(profile.smoke_enabled)
 debris = bool(profile.debris_enabled)
 lighting = bool(profile.lighting_enabled)
 shake_enabled = bool(profile.shake_enabled)
 # Live reconfiguration is also safe, although normal UI applies next mission.
 for index in range(active.size()-1,-1,-1):
  var slot: Dictionary = slots[active[index]]
  if active.size() > int(profile.particles) or (slot.kind == "smoke" and not smoke) or (slot.kind == "debris" and not debris) or (slot.kind == "light" and not lighting):
   release(index)
 if not shake_enabled:
  shake_offset = Vector2.ZERO
  shake_remaining = 0

func count_kind(kind: String) -> int:
 var count := 0
 for index in active:
  if slots[index].kind == kind:
   count += 1
 return count

func release(index: int) -> void:
 var slot: int = active[index]
 slots[slot].clear()
 free_slots.append(slot)
 active.remove_at(index)

func particle(kind: String, point: Vector2, velocity: Vector2, duration: float, size: float, tint: Color) -> void:
 if not FIELD.grow(30).has_point(point):
  return
 if (kind == "smoke" and not smoke) or (kind == "debris" and not debris) or (kind == "light" and not lighting):
  return
 var cap := int(profile.get({"smoke":"smoke","debris":"debris","light":"lights"}.get(kind,"particles"),profile.particles))
 if active.size() >= int(profile.particles) or emitted >= int(profile.emissions_per_tick) or free_slots.is_empty() or (kind in ["smoke","debris","light"] and count_kind(kind) >= cap):
  dropped += 1
  return
 var index: int = free_slots.pop_back()
 serial += 1
 slots[index].merge({"kind":kind,"point":point,"velocity":velocity if not motion else Vector2.ZERO,"duration":maxf(.05,duration),"age":0.0,"size":size,"tint":tint,"angle":serial*2.39996},true)
 active.append(index)
 emitted += 1
 peak = maxi(peak,active.size())

func burst(point: Vector2, count: int, force: float, tint: Color, heavy: bool = false) -> void:
 for index in mini(count,int(profile.burst)):
  var heading := float(index)*2.39996+serial*.17
  particle("spark",point,Vector2.from_angle(heading)*force*(.55+float(index%4)*.15),.22+float(index%3)*.07,2.4 if heavy else 1.4,tint)
 particle("light",point,Vector2.ZERO,.12,32 if heavy else 15,tint)

func shot(point: Vector2, heading: Vector2, kind: String, tint: Color) -> void:
 if kind in ["machine_gun","cannon","heavy_aa","missile"]:
  tint = Color("ffd29a")
 if kind in ["cannon","heavy_aa","standard","armor_piercing","explosive"]:
  particle("smoke",point,heading*25+Vector2(0,-9),.55,16 if kind in ["cannon","heavy_aa"] else 10,Color("b5b6b1"))
 particle("light",point,Vector2.ZERO,.055,20 if kind == "machine_gun" else 30,tint)

func trail(point: Vector2, heading: Vector2, kind: String, tint: Color) -> void:
 if kind == "missile":
  particle("smoke",point-heading*16,Vector2(0,-8),.65,12,Color("9c9b96"))
  particle("exhaust",point-heading*18,-heading*13,.10,17,Color("ffad67"))
 elif kind in ["armor_piercing","railgun"]:
  particle("streak",point,-heading*90,.12,26,tint)
 elif kind == "cryo":
  particle("spark",point,Vector2(0,-10),.2,3,tint)
 elif kind == "emp":
  particle("light",point,Vector2.ZERO,.07,8,tint)
 elif kind == "explosive":
  particle("smoke",point,Vector2(0,-9),.3,6,Color("c8b293"))

func impact(point: Vector2, kind: String, tint: Color, radius: float, critical: bool) -> void:
 if kind == "emp":
  pulse(point,maxf(22,radius),tint)
 elif kind == "cryo":
  particle("area",point,Vector2.ZERO,.3,22,tint)
  burst(point,4,40,tint)
 elif kind == "railgun":
  particle("streak",point,Vector2.UP*100,.16,50,tint)
 var heavy := kind in ["cannon","heavy_aa","missile","explosive"]
 if kind in ["machine_gun","cannon","heavy_aa","missile"]:
  tint = Color("ffcc8c")
 burst(point,12 if heavy else 5,145 if heavy else 90,tint.lightened(.3),heavy)
 if heavy:
  particle("smoke",point,Vector2(8,-23),.8,32,tint.darkened(.6))
 if radius > 0:
  particle("area",point,Vector2.ZERO,.42,radius,Color("FF9C42"))
  shake(.9 if kind == "explosive" else 1.2)
 if critical:
  particle("critical",point,Vector2.ZERO,.28,26,Color("ffcf83"))

func destroyed(enemy: Node2D) -> void:
 var boss: bool = enemy.brain != null and enemy.brain.boss
 var heavy: bool = boss or enemy.body_scale >= 1.3
 var scale := 2.2 if boss else 1.3 if heavy else .8
 burst(enemy.position,16 if heavy else 8,130*scale,Color("ffd29a"),heavy)
 particle("smoke",enemy.position,Vector2(8,-28),1.2 if boss else .85,40*scale,Color("555b60"))
 for index in (6 if boss else 4 if heavy else 2):
  var angle: float = index*2.39996+float(enemy.spawn_id)*.37
  particle("debris",enemy.position,Vector2.from_angle(angle)*65*scale,.8+index*.07,12 if boss else 7,Color("b6a28b"))
 if heavy:
  shake(1.5 if boss else .75)

func pulse(point: Vector2, radius: float, tint: Color) -> void:
 particle("electric",point,Vector2.ZERO,.45,radius,tint)

func shake(strength: float) -> void:
 if not shake_enabled:
  return
 shake_strength = minf(1.5,maxf(shake_strength,strength))
 shake_remaining = .18

func base_damaged(health_fraction: float) -> void:
 damage_age = .5
 critical_base = health_fraction <= .25
 shake(1.2)

func announce(title: String, success: bool = false) -> void:
 banner = title
 banner_age = 2.2
 victory = success
 if success:
  particle("area",Vector2(560,580),Vector2.ZERO,.7,95,Color("37B7E5"))

func observe(battle: Node2D, delta: float) -> void:
 disabled_points.clear()
 for enemy in battle.drones.get_children():
  if not enemy.ended and (enemy.disable_remaining > 0 or enemy.slow_remaining > 0) and disabled_points.size() < 24 and FIELD.has_point(enemy.position):
   disabled_points.append(enemy.position)
 laser_timer -= delta
 if laser_timer <= 0:
  laser_timer = .1
  for turret in battle.turrets.get_children():
   if turret.kind == "laser" and turret.muzzle > 0 and is_instance_valid(turret.target) and not turret.target.ended:
    particle("light",turret.target.position,Vector2.ZERO,.12,23,Color("9eddf1"))
 var cannon: Node2D = battle.player_turret
 var reloading: bool = cannon.reload_remaining > 0
 if last_reload and not reloading:
  ready_age = .4
 last_reload = reloading
 reload_fraction = cannon.reload_progress() if reloading else -1.0
 # Shake only artwork. Physics, input transforms, projectiles, HUD and reticle
 # stay fixed. Never move Battle, Camera2D or a gameplay controller.
 for enemy in battle.drones.get_children():
  enemy.art.position = shake_offset
 for turret in battle.turrets.get_children():
  turret.art.position = shake_offset
 cannon.get_node("Artwork").art.position = shake_offset
 battle.view.environment.terrain.position = shake_offset

func tick(delta: float) -> void:
 clock += delta
 emitted = 0
 damage_age = maxf(0,damage_age-delta)
 banner_age = maxf(0,banner_age-delta)
 ready_age = maxf(0,ready_age-delta)
 shake_remaining = maxf(0,shake_remaining-delta)
 shake_offset = Vector2(sin(clock*71),cos(clock*83))*shake_strength*(shake_remaining/.18) if shake_remaining > 0 else Vector2.ZERO
 if shake_remaining == 0:
  shake_strength = 0
 for index in range(active.size()-1,-1,-1):
  var item: Dictionary = slots[active[index]]
  item.age += delta
  if float(item.age) >= float(item.duration):
   release(index)
 painter.queue_redraw()
 feedback.queue_redraw()

func paint(canvas: CanvasItem) -> void:
 get_parent().paint_effects(canvas)
 for index in active:
  var item: Dictionary = slots[index]
  var t: float = float(item.age)/float(item.duration)
  var point: Vector2 = item.point+item.velocity*float(item.age)
  var tint: Color = item.tint
  tint.a *= (1.0-t)
  var size: float = item.size
  match str(item.kind):
   "spark":
    var velocity: Vector2 = item.velocity
    var end := point-velocity.normalized()*(5+size*2)*(1-t)
    canvas.draw_line(end,point,tint,size*(1-t)+.5,true)
   "smoke":
    var extent := size*(1+t*.9)
    canvas.draw_texture_rect(ASSETS.texture("environment/smoke_wisp.svg"),Rect2(point-Vector2.ONE*extent*.5,Vector2.ONE*extent),false,Color(tint,tint.a*.38))
   "light":
    canvas.draw_texture_rect(ASSETS.texture("environment/light_pool.svg"),Rect2(point-Vector2.ONE*size*.5,Vector2.ONE*size),false,Color(tint,tint.a*.35))
   "debris":
    if not motion:
     point.y += float(item.age)*float(item.age)*38
    canvas.draw_set_transform(point,float(item.angle)+(0 if motion else float(item.age)*4))
    canvas.draw_texture_rect(ASSETS.sprite("wreck_fragment"),Rect2(-size*.5,-size*.5,size,size),false,tint)
    canvas.draw_set_transform(Vector2.ZERO)
   "exhaust","streak":
    var velocity: Vector2 = item.velocity
    canvas.draw_set_transform(point,velocity.angle())
    canvas.draw_texture_rect(ASSETS.texture("projectiles/tracer.svg"),Rect2(-size*.5,-2,size,4),false,tint)
    canvas.draw_set_transform(Vector2.ZERO)
   "area":
    canvas.draw_arc(point,size*(1 if motion else .6+t*.4),0,TAU,48,Color(tint,tint.a*.5),1.3,true)
   "critical":
    canvas.draw_arc(point,size*(1 if motion else .5+t*.5),0,TAU,24,tint,1.5,true)
    canvas.draw_string(preload("res://assets/ui/fonts/BarlowCondensed-Bold.ttf"),point+Vector2(-15,-28),"CRIT",HORIZONTAL_ALIGNMENT_LEFT,-1,14,tint)
   "electric":
    var radius: float = size*(1.0 if motion else .25+t*.75)
    for arc in (2 if reduced else 5):
     var points := PackedVector2Array()
     for node in 6:
      var angle := arc*TAU/5+node*.13
      points.append(point+Vector2.from_angle(angle)*radius*(.96 if node%2 else 1.04))
     canvas.draw_polyline(points,Color(tint,tint.a*.7),1.4,true)
 for index in disabled_points.size():
  var point: Vector2 = disabled_points[index]
  var angle := 0.0 if motion else clock*2+index
  canvas.draw_arc(point,25,angle,angle+PI*.75,12,Color("b9c4f0"),1.4,true)
  canvas.draw_arc(point,27,angle+PI,angle+PI*1.75,12,Color(.7,.8,1,.5),1,true)
