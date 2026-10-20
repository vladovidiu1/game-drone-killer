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

func precision_point(enemy: Node2D) -> Vector2:
 if manual and enemy.brain != null and enemy.brain.boss:
  # Test the swept ray through the body, rather than only its outer collision edge.
  return Geometry2D.get_closest_point_to_segment(enemy.brain.weakpoint(),position-direction*100,position+direction*100)
 return destination

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
 var assets := preload("res://scripts/visual/visual_assets.gd")
 draw_set_transform(Vector2.ZERO,direction.angle())
 if splash_radius > 0 and not manual:
  draw_texture_rect(assets.texture("projectiles/missile.svg"),Rect2(-19,-6,32,12),false)
 else:
  draw_texture_rect(assets.texture("projectiles/tracer.svg"),Rect2(-32,-3,36,6),false,tint.lightened(0.25) if manual else Color("e3caa1"))
 draw_set_transform(Vector2.ZERO)
