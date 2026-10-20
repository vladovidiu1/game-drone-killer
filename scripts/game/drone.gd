extends Node2D
signal breached(damage: int)
signal destroyed(reward: int)
signal damaged(at: Vector2)
const ASSETS := preload("res://scripts/visual/visual_assets.gd")
var art: Node2D
var health := 40.0
var maximum_health := 40.0
var speed := 120.0
var reward := 10
var damage := 25
var tint := Color.CORAL
var phase := 0.0
var ended := false
var route: Array[Vector2] = []
var waypoint := 1
var distance_remaining := 0.0
var spawn_id := 0
var hit_flash := 0.0
var body_scale := 1.0
var armored := false
var slow_remaining := 0.0
var slow_factor := 1.0
var disable_remaining := 0.0
var brain: RefCounted
var is_support := false
var designation := ""
var display_name := ""

func configure(data: Dictionary, path: Array, identity: int) -> void:
 display_name = str(data.get("name","Hostile Drone"))
 health = float(data.health)
 maximum_health = health
 speed = float(data.speed)
 reward = int(data.reward)
 damage = int(data.damage)
 tint = Color(data.color)
 body_scale = float(data.size)
 armored = bool(data.get("armored",false))
 designation = "B" if str(data.get("name", "")) == "Bomber Drone" else ""
 if is_instance_valid(art):
  art.queue_free()
 art = preload("res://scripts/visual/unit_visual.gd").new()
 var sprite_id: String = ASSETS.catalog.enemy_aliases.get(str(data.get("name","")),"drone_heavy" if bool(data.get("armored",false)) or bool(data.get("boss",false)) else "drone_assault")
 art.configure(sprite_id,body_scale)
 art.clock = float(identity)*.19
 art.show_behind_parent = true
 add_child(art)
 spawn_id = identity
 route.clear()
 for point in path:
  route.append(Vector2(float(point[0]),float(point[1])))
 position = route[0]
 distance_remaining = 0.0
 for i in range(1,route.size()):
  distance_remaining += route[i-1].distance_to(route[i])

func tick(delta: float) -> void:
 if ended:
  return
 phase += delta * 15
 hit_flash = maxf(0.0,hit_flash-delta)
 if brain != null and brain.tick(delta):
  disable_remaining = maxf(0.0,disable_remaining-delta)
  slow_remaining = maxf(0.0,slow_remaining-delta)
  queue_redraw()
  return
 var disabled_time := minf(delta,disable_remaining)
 var moving_time := delta-disabled_time
 var slowed_time := minf(moving_time,maxf(0.0,slow_remaining-disabled_time))
 var travel := speed*(moving_time-slowed_time+slowed_time*slow_factor)
 disable_remaining = maxf(0.0,disable_remaining-delta)
 slow_remaining = maxf(0.0,slow_remaining-delta)
 if slow_remaining <= 0:
  slow_factor = 1.0
 while travel > 0 and waypoint < route.size():
  var distance := position.distance_to(route[waypoint])
  var step := minf(travel,distance)
  position = position.move_toward(route[waypoint],step)
  distance_remaining = maxf(0.0,distance_remaining-step)
  travel -= step
  if distance <= step + 0.001:
   waypoint += 1
 if waypoint >= route.size():
  ended = true
  breached.emit(damage)
  queue_free()
 queue_redraw()

func apply_slow(factor: float, duration: float) -> void:
 slow_factor = minf(slow_factor,clampf(factor,0.05,1.0))
 slow_remaining = maxf(slow_remaining,duration)

func apply_disable(duration: float) -> void:
 disable_remaining = maxf(disable_remaining,duration)

func automatically_targetable() -> bool:
 return brain == null or not brain.cloaked()

func hit(amount: float, manual: bool = false, armor_piercing: bool = false, point: Vector2 = Vector2.INF) -> void:
 if ended or amount <= 0:
  return
 if brain != null:
  amount *= brain.damage_multiplier(manual,armor_piercing,point)
 health = maxf(0.0,health-amount)
 hit_flash = 0.12
 damaged.emit(position)
 if health <= 0:
  ended = true
  destroyed.emit(reward)
  queue_free()
 queue_redraw()

func _draw() -> void:
 if is_instance_valid(art):
  art.sync(0.0,hit_flash,brain != null and brain.cloaked(),disable_remaining > 0)
 if brain != null:
  _draw_ability()
 if disable_remaining > 0 or slow_remaining > 0:
  draw_arc(Vector2.ZERO,34*body_scale,0,TAU,24,Color("acbbff"),2)
 if brain == null or not brain.boss:
  draw_rect(Rect2(-24,-32*body_scale,48,5),Color("0a1421"))
  draw_rect(Rect2(-23,-32*body_scale+1,46*health/maximum_health,3),Color("F04B45"))

func _draw_ability() -> void:
 if brain.data.has("aura_radius") and disable_remaining <= 0:
  draw_circle(Vector2.ZERO,float(brain.data.aura_radius),Color(0.3,0.9,1,0.06))
  draw_arc(Vector2.ZERO,float(brain.data.aura_radius),0,TAU,40,Color(0.3,0.9,1,0.35),2)
 if brain.boss:
  var core: Vector2 = brain.weakpoint()-position
  draw_circle(core,14,Color("102535"))
  draw_arc(core,14,0,TAU,24,Color("66ffff"),3)
  draw_circle(core,7,Color("ccffff"))
 else:
  var mark := designation
  if brain.data.has("attack"):
   mark = {"emp":"EMP","sniper":"SNP","spawn":"+"}.get(str(brain.data.attack),"")
  elif brain.data.has("cloak_period"):
   mark = "S"
  elif brain.data.has("aura_radius"):
   mark = "+"
  draw_string(ThemeDB.fallback_font,Vector2(-12,-40),mark,HORIZONTAL_ALIGNMENT_LEFT,-1,15,tint)
 if brain.charging:
  var config: Dictionary = brain.pending_attack
  var progress: float = 1.0-brain.charge/float(config.windup)
  draw_arc(Vector2.ZERO,38*body_scale,-PI/2,-PI/2+TAU*progress,36,Color("ff726b"),4)
  var destination := Vector2(560,590)
  if is_instance_valid(brain.target):
   destination = brain.target.position
  if str(config.attack) != "spawn":
   draw_dashed_line(Vector2.ZERO,destination-position,Color(1,0.4,0.3,0.55),2,10)
