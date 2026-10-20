extends Node2D
var battle: Node2D
var target: Node2D
var destination := Vector2.ZERO
var damage := 0.0
var speed := 0.0
var splash_radius := 0.0
var tint := Color.WHITE
var lifetime := 0.0
var consumed := false
var direction := Vector2.UP
var manual := false
var range_remaining := 0.0
var armor_multiplier := 1.0
var critical := false

func configure(owner_battle: Node2D, turret: Node2D, victim: Node2D) -> void:
 battle = owner_battle
 target = victim
 position = turret.position
 destination = victim.position
 damage = turret.damage_value()
 speed = float(turret.definition.projectile_speed)
 splash_radius = float(turret.definition.splash_radius)
 tint = Color(str(turret.definition.color))
 lifetime = float(CampaignManager.combat.projectile_lifetime)

func configure_manual(owner_battle: Node2D, heading: Vector2) -> void:
 battle = owner_battle
 manual = true
 var cannon: Node2D = battle.player_turret
 var data: Dictionary = cannon.definition
 direction = heading.normalized()
 position = cannon.position+direction*float(data.muzzle_offset)
 damage = cannon.damage_value()
 speed = float(data.projectile_speed)
 range_remaining = maxf(0.0,float(data.range)-float(data.muzzle_offset))
 var profile: Dictionary = cannon.ammunition()
 tint = Color(str(profile.color))
 armor_multiplier = float(profile.armor_multiplier)
 splash_radius = float(profile.splash_radius)
 critical = cannon.rng.randf() < float(data.critical_chance)
 if critical:
  damage *= float(data.critical_multiplier)
 lifetime = float(CampaignManager.combat.projectile_lifetime)

func damage_for(enemy: Node2D) -> float:
 return damage*(armor_multiplier if enemy.armored else 1.0)

func _tick_manual(delta: float) -> void:
 var travel := minf(speed*delta,range_remaining)
 var first_distance := travel+1.0
 var victim: Node2D = null
 var radius := float(CampaignManager.combat.hit_radius)
 for enemy in battle.drones.get_children():
  if enemy.ended:
   continue
  var relative: Vector2 = position-enemy.position
  var b := relative.dot(direction)
  var c: float = relative.length_squared()-pow(radius*enemy.body_scale,2)
  var discriminant := b*b-c
  if discriminant < 0:
   continue
  var entry := -b-sqrt(discriminant)
  var exit_distance := -b+sqrt(discriminant)
  if exit_distance < 0 or entry > travel:
   continue
  var distance := maxf(0.0,entry)
  if distance < first_distance:
   first_distance = distance
   victim = enemy
 if victim != null:
  position += direction*first_distance
  destination = position
  target = victim
  impact()
 else:
  position += direction*travel
  range_remaining -= travel
  if range_remaining <= 0.001:
   retire()
 queue_redraw()

func tick(delta: float) -> void:
 if consumed:
  return
 lifetime -= delta
 if lifetime <= 0:
  retire()
  return
 if manual:
  _tick_manual(delta)
  return
 if is_instance_valid(target) and not target.ended:
  destination = target.position
 elif splash_radius <= 0:
  retire()
  return
 var previous := position
 direction = (destination-position).normalized()
 position = position.move_toward(destination,speed*delta)
 # Swept segment versus target circle avoids tunneling at 2x speed.
 var closest := Geometry2D.get_closest_point_to_segment(destination,previous,position)
 if closest.distance_to(destination) <= float(CampaignManager.combat.hit_radius):
  impact()
 queue_redraw()

func impact() -> void:
 if consumed:
  return
 consumed = true
 battle.resolve_impact(self)
 queue_free()

func retire() -> void:
 consumed = true
 queue_free()

func _draw() -> void:
 if splash_radius > 0:
  draw_line(-direction*18,Vector2.ZERO,Color(1,0.7,0.3,0.5),5)
  draw_circle(Vector2.ZERO,5,tint)
  draw_circle(-direction*7,3,Color("fff2cc"))
 else:
  draw_line(-direction*(30 if manual else 12),direction*3,tint,3 if damage < 40 else 6)
  if manual:
   draw_circle(Vector2.ZERO,2.5,Color("f1fbff"))
