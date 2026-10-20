extends Node2D
signal breached(damage: int)
signal destroyed(reward: int)
signal damaged(at: Vector2)
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

func configure(data: Dictionary, path: Array, identity: int) -> void:
 health = float(data.health)
 maximum_health = health
 speed = float(data.speed)
 reward = int(data.reward)
 damage = int(data.damage)
 tint = Color(data.color)
 body_scale = float(data.size)
 armored = bool(data.get("armored",false))
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

func hit(amount: float) -> void:
 if ended or amount <= 0:
  return
 health = maxf(0.0,health-amount)
 hit_flash = 0.12
 damaged.emit(position)
 if health <= 0:
  ended = true
  destroyed.emit(reward)
  queue_free()
 queue_redraw()

func _draw() -> void:
 draw_set_transform(Vector2(0,14),0,Vector2(1,0.4)*body_scale)
 draw_circle(Vector2.ZERO,24,Color(0,0,0,0.3))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE*body_scale)
 var color := Color.WHITE if hit_flash > 0 else tint
 for offset in [Vector2(-17,-12),Vector2(17,-12),Vector2(-17,12),Vector2(17,12)]:
  draw_line(Vector2.ZERO,offset,Color("131e2a"),6)
  draw_arc(offset,10,phase,phase+4.8,12,color,2)
 draw_colored_polygon(PackedVector2Array([Vector2(-14,0),Vector2(-8,-12),Vector2(8,-12),Vector2(14,0),Vector2(0,16)]),Color("121f2d"))
 draw_colored_polygon(PackedVector2Array([Vector2(-11,0),Vector2(-6,-9),Vector2(6,-9),Vector2(11,0),Vector2(0,12)]),color)
 draw_line(Vector2(-5,0),Vector2(5,0),Color("0e1a28"),3)
 draw_circle(Vector2(0,7),2.5,Color.WHITE)
 draw_set_transform(Vector2.ZERO)
 if disable_remaining > 0 or slow_remaining > 0:
  draw_arc(Vector2.ZERO,34*body_scale,0,TAU,24,Color("acbbff"),2)
 draw_rect(Rect2(-24,-32*body_scale,48,5),Color("0a1421"))
 draw_rect(Rect2(-23,-32*body_scale+1,46*health/maximum_health,3),Color("69e2b7"))
