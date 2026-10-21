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
# Presentation snapshots only; never used for hit, movement or damage decisions.
var visual_kind := "standard"
var visual_origin := Vector2.ZERO
var visual_trail_time := 0.0

func configure(owner_battle: Node2D, turret: Node2D, victim: Node2D) -> void:
 battle = owner_battle
 target = victim
 visual_kind = turret.kind
 position = turret.position
 visual_origin = position
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
 visual_kind = cannon.ammunition_type
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
 visual_trail_time -= delta
 if visual_trail_time <= 0:
  visual_trail_time = .065
  battle.view.combat_fx.trail(position,direction,visual_kind,tint)
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
 # Swept segment versus target circle avoids tunneling across long simulation steps.
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
 if not manual and position.distance_to(visual_origin) < 25:
  return
 var assets := preload("res://scripts/visual/visual_assets.gd")
 draw_set_transform(Vector2.ZERO,direction.angle())
 if splash_radius > 0 and not manual:
  draw_texture_rect(assets.texture("projectiles/missile.svg"),Rect2(-19,-6,32,12),false)
 else:
  var length := 54.0 if manual and visual_kind == "armor_piercing" else 25.0 if manual and visual_kind == "explosive" else 36.0
  var width := 9.0 if manual and visual_kind == "explosive" else 7.0 if visual_kind in ["cannon","heavy_aa"] else 5.0
  draw_texture_rect(assets.texture("projectiles/tracer.svg"),Rect2(-length+4,-width*.5,length,width),false,tint.lightened(.25) if manual else Color("e3caa1"))
  if manual and visual_kind == "armor_piercing":
   draw_line(Vector2(-39,-3),Vector2(-12,-3),Color(tint,.5),1)
   draw_line(Vector2(-39,3),Vector2(-12,3),Color(tint,.5),1)
 draw_set_transform(Vector2.ZERO)
