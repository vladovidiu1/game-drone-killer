extends RefCounted
# Reusable abilities. Definitions own timing/composition; Battle owns damage/rewards.
var enemy: Node2D
var battle: Node2D
var data: Dictionary
var boss := false
var phase_index := 0
var elapsed := 0.0
var cooldown := 3.0
var charge := 0.0
var charging := false
var pending_attack: Dictionary = {}
var target: Node2D
var actions := 0
var overload_timer := 0.0

func configure(unit: Node2D, owner_battle: Node2D, definition: Dictionary) -> void:
 enemy = unit
 battle = owner_battle
 data = definition.get("ai",{})
 boss = bool(definition.get("boss",false))
 cooldown = float(data.get("initial_delay",settings().get("attack_interval",4)))

func settings() -> Dictionary:
 return data.phases[phase_index] if boss else data

func tick(delta: float) -> bool:
 elapsed += delta
 if boss:
  var next_phase := 0
  for index in data.phases.size():
   if enemy.health/enemy.maximum_health <= float(data.phases[index].threshold):
    next_phase = index
  if next_phase != phase_index:
   phase_index = next_phase
   battle.view.effect(enemy.position,"blast",95,enemy.tint)
   cooldown = minf(cooldown,2.0)
  if enemy.position.distance_to(anchor()) > 4:
   var active_delta := maxf(0.0,delta-enemy.disable_remaining)
   enemy.position = enemy.position.move_toward(anchor(),enemy.speed*active_delta)
   enemy.distance_remaining = enemy.position.distance_to(Vector2(560,600))
   enemy.queue_redraw()
 if enemy.disable_remaining > 0:
  return boss
 if boss and elapsed >= float(data.overload_after):
  overload_timer -= delta
  if overload_timer <= 0:
   overload_timer += float(data.overload_interval)
   battle._breached(int(data.overload_damage))
   battle.enemy_actions += 1
   battle.view.effect(enemy.position,"blast",110,Color("ff6868"))
 var config := settings()
 if not config.has("attack"):
  return boss
 cooldown -= delta
 if charging:
  charge -= delta
  if charge <= 0:
   execute(pending_attack)
   charging = false
   cooldown = float(config.attack_interval)
 elif cooldown <= 0:
  target = closest_turret(float(config.get("attack_range",900)))
  if str(config.attack) == "spawn" or boss or target != null:
   charging = true
   pending_attack = config.duplicate(true)
   charge = float(pending_attack.windup)
 return boss

func anchor() -> Vector2:
 return Vector2(float(data.anchor[0]),float(data.anchor[1]))

func closest_turret(radius: float) -> Node2D:
 var chosen: Node2D = null
 for turret in battle.turrets.get_children():
  if turret.position.distance_to(enemy.position) <= radius and (chosen == null or turret.position.distance_squared_to(enemy.position) < chosen.position.distance_squared_to(enemy.position)):
   chosen = turret
 return chosen

func execute(config: Dictionary) -> void:
 actions += 1
 battle.enemy_actions += 1
 var attack := str(config.attack)
 if attack == "spawn":
  var count := 0
  for unit in battle.drones.get_children():
   if not unit.ended and unit.is_support:
    count += 1
  for kind in config.support:
   if count >= int(config.support_limit) or battle.living_count() >= 72:
    break
   battle.spawn_support(str(kind),enemy)
   count += 1
 elif attack == "emp":
  for turret in battle.turrets.get_children():
   if boss or turret == target:
    turret.apply_disable(float(config.disable_time))
  battle.view.effect(enemy.position,"blast",boss_range(),Color("ada3ff"))
 elif attack == "sniper":
  if is_instance_valid(target):
   target.apply_disable(float(config.disable_time))
   battle.view.effect(target.position,"blast",30,Color("ffe199"))
 elif attack == "barrage":
  battle._breached(int(config.base_damage))
  battle.view.effect(Vector2(560,590),"blast",90,enemy.tint)

func boss_range() -> float:
 return 340.0 if boss else 110.0

func cloaked() -> bool:
 return data.has("cloak_period") and enemy.disable_remaining <= 0 and fmod(elapsed,float(data.cloak_period)) < float(data.cloak_duration)

func weakpoint() -> Vector2:
 if not boss:
  return enemy.position
 return enemy.position+Vector2(float(data.weakpoint[0]),float(data.weakpoint[1]))

func damage_multiplier(manual: bool, armor_piercing: bool, point: Vector2) -> float:
 var multiplier := 1.0
 if boss:
  multiplier = float(settings().manual_hull_multiplier if manual else settings().automatic_hull_multiplier)
  multiplier *= 1.0-float(settings().armor_reduction)
  # A straight manual trajectory must actually intersect the lit core.
  if manual and point.distance_to(weakpoint()) <= float(data.weakpoint_radius):
   multiplier = float(settings().weakpoint_multiplier)
   battle.weakpoint_hits += 1
   battle.view.effect(weakpoint(),"hit",24,Color("69ffff"))
 if not armor_piercing:
  for unit in battle.drones.get_children():
   if unit == enemy or unit.ended or unit.brain == null:
    continue
   var aura: Dictionary = unit.brain.data
   if aura.has("aura_radius") and unit.disable_remaining <= 0 and unit.position.distance_to(enemy.position) <= float(aura.aura_radius):
    multiplier *= 1.0-float(aura.shield_reduction)
    break
 return multiplier
