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

func configure(data: Dictionary, path: Array, identity: int) -> void:
 health = float(data.health)
 maximum_health = health
 speed = float(data.speed)
 reward = int(data.reward)
 damage = int(data.damage)
 tint = Color(data.color)
 body_scale = float(data.size)
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
 var travel := speed * delta
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
 draw_rect(Rect2(-24,-32*body_scale,48,5),Color("0a1421"))
 draw_rect(Rect2(-23,-32*body_scale+1,46*health/maximum_health,3),Color("69e2b7"))
