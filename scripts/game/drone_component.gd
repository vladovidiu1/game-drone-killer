extends Node2D
# Local independently damageable surface. Pose is inherited from the actual art mount.
signal destroyed(component: Node2D)
var rig: RefCounted
var definition: Dictionary
var binding: Dictionary
var id := ""
var kind := ""
var last_source: StringName = &"other"
var last_direct := false
var stored_health := 0.0
var stored_maximum := 0.0
var health: float:
 get:
  return rig.enemy.health if kind == "body" and rig != null else stored_health
 set(value):
  if kind == "body" and rig != null:
   rig.enemy.health = value
  else:
   stored_health = value
var maximum_health: float:
 get:
  return rig.enemy.maximum_health if kind == "body" and rig != null else stored_maximum
 set(value):
  stored_maximum = value
var radius := 1.0
var broken := false
var flash := 0.0

func configure(owner_rig: RefCounted, data: Dictionary, mount: Dictionary) -> void:
 rig = owner_rig
 definition = data
 binding = mount
 id = str(data.id)
 kind = str(data.type)
 if kind != "body":
  health = float(data.health)
  maximum_health = health
 radius = float(mount.radius)
 var pivot: Array = rig.enemy.art.entry.pivot
 position = Vector2(float(mount.point[0])-float(pivot[0]),float(mount.point[1])-float(pivot[1]))

func point() -> Vector2:
 return rig.enemy.brain.battle.to_local(global_position)

func live_health() -> float:
 return rig.enemy.health if kind == "body" else health

func live_maximum() -> float:
 return rig.enemy.maximum_health if kind == "body" else maximum_health

func open() -> bool:
 if kind != "core" or broken:
  return true
 if rig.shield_operational():
  return false
 var window: Dictionary = rig.CONFIG.core_windows
 if rig.mission_id < int(window.from_mission):
  return true
 return fmod(rig.clock,float(window.period)) < float(window.open_seconds)

func collider_enabled() -> bool:
 return not broken or bool(definition.get("wreck_vulnerable",false))

func segment(start: Vector2, finish: Vector2) -> float:
 var battle: Node2D = rig.enemy.brain.battle
 var a := to_local(battle.to_global(start))
 var d := to_local(battle.to_global(finish))-a
 var length := d.length_squared()
 if length <= .000001:
  return 0.0 if a.length_squared() <= radius*radius else INF
 var b := a.dot(d)
 var c := a.length_squared()-radius*radius
 var discriminant := b*b-length*c
 if discriminant < 0:
  return INF
 var entry := (-b-sqrt(discriminant))/length
 var exit_value := (-b+sqrt(discriminant))/length
 if exit_value < 0 or entry > 1:
  return INF
 return maxf(0,entry)*start.distance_to(finish)

func receive(amount: float, direct: bool, armor_piercing: bool, traits: Dictionary, source: StringName = &"other") -> void:
 if amount <= 0 or not is_finite(amount) or rig.enemy.ended or rig.falling:
  return
 if kind == "body":
  rig.enemy.hit(amount,direct,armor_piercing,Vector2.INF,traits,source)
  return
 if rig.enemy.ended or (broken and not bool(definition.get("wreck_vulnerable",false))):
  return
 var bypass := 1.0 if armor_piercing else clampf(float(traits.get("armor_bypass",0)),0,1)
 amount *= 1.0-float(definition.get("armor",0))*(1.0-bypass)
 amount *= rig.enemy.brain.shield_multiplier(armor_piercing,traits)
 if direct and kind == "core" and open():
  amount *= maxf(float(definition.damage_multiplier),float(rig.enemy.brain.settings().get("weakpoint_multiplier",0)))
  rig.enemy.brain.battle.weakpoint_hits += 1
 elif kind != "core":
  amount *= float(definition.damage_multiplier)
 elif direct and rig.enemy.brain.boss:
  amount *= float(rig.enemy.brain.settings().manual_hull_multiplier)
 last_source = source
 last_direct = direct
 flash = .15
 if not broken:
  health = maxf(0,health-amount)
  if health <= 0:
   broken = true # consume destruction ownership before consequences/re-entrant signals
   destroyed.emit(self)
 rig.enemy.apply_body_damage(amount*float(definition.hull_transfer),source)
 rig.hit_feedback(self,direct)
