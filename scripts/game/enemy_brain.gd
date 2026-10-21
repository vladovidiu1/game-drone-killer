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
   battle.view.effect(enemy.position,"pulse",95,enemy.tint)
   cooldown = minf(cooldown,2.0)
  if enemy.position.distance_to(anchor()) > 4:
   var active_delta := maxf(0.0,delta-enemy.disable_remaining)
   enemy.position = enemy.position.move_toward(anchor(),enemy.effective_speed()*active_delta)
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
 if not config.has("attack") or (enemy.components != null and not enemy.components.attack_allowed(str(config.get("attack","")))):
  charging = false
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
 if enemy.components != null and enemy.components.disabled("sensor"):
  radius *= float(enemy.components.CONFIG.sensor_range_multiplier)
 var chosen: Node2D = null
 for turret in battle.turrets.get_children():
  if turret.position.distance_to(enemy.position) <= radius and (chosen == null or turret.position.distance_squared_to(enemy.position) < chosen.position.distance_squared_to(enemy.position)):
   chosen = turret
 return chosen

func execute(config: Dictionary) -> void:
 if enemy.components != null and not enemy.components.attack_allowed(str(config.attack)):
  return
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
  battle.view.effect(enemy.position,"pulse",boss_range(),Color("ada3ff"))
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
 return (enemy.components == null or not enemy.components.disabled("sensor")) and data.has("cloak_period") and enemy.disable_remaining <= 0 and fmod(elapsed,float(data.cloak_period)) < float(data.cloak_duration)

func weakpoint() -> Vector2:
 if not boss:
  return enemy.position
 if enemy.components != null:
  var core: Node2D = enemy.components.find("core")
  if core != null:
   return core.point()
 return enemy.position+Vector2(float(data.weakpoint[0]),float(data.weakpoint[1])).rotated(enemy.rotation)

func damage_multiplier(manual: bool, armor_piercing: bool, point: Vector2, traits: Dictionary = {}) -> float:
 var armor_bypass := 1.0 if armor_piercing else clampf(float(traits.get("armor_bypass",0)),0,1)
 var armor: float = enemy.resistance_value("armor")
 var multiplier := 1.0-armor*(1.0-armor_bypass)
 if boss:
  multiplier = float(settings().manual_hull_multiplier if manual else settings().automatic_hull_multiplier)
  multiplier *= 1.0-float(settings().armor_reduction)
  # A straight manual trajectory must actually intersect the lit core.
  if enemy.components == null and manual and point.distance_to(weakpoint()) <= float(data.weakpoint_radius):
   multiplier = float(settings().weakpoint_multiplier)
   battle.weakpoint_hits += 1
   battle.view.effect(weakpoint(),"hit",24,Color("69ffff"))
 return multiplier*shield_multiplier(armor_piercing,traits)

func shield_active() -> bool:
 return enemy.disable_remaining <= 0 and (enemy.components == null or (not enemy.components.falling and not enemy.components.disabled("shield")))

func shield_multiplier(armor_piercing: bool, traits: Dictionary = {}) -> float:
 var bypass := 1.0 if armor_piercing else clampf(float(traits.get("shield_bypass",0)),0,1)
 var own_shield: float = enemy.resistance_value("shield") if shield_active() else 0.0
 var multiplier := 1.0-own_shield*(1.0-bypass)
 if bypass < 1.0:
  for unit in battle.drones.get_children():
   if unit == enemy or unit.ended or unit.brain == null or not unit.brain.shield_active():
    continue
   var aura: Dictionary = unit.brain.data
   if aura.has("aura_radius") and unit.position.distance_to(enemy.position) <= float(aura.aura_radius):
    multiplier *= 1.0-float(aura.shield_reduction)*(1.0-bypass)
    break
 return multiplier

func movement_integral(time: float) -> float:
 # Integral in nominal-speed seconds, so bursts stay deterministic across dt.
 var mobility: Dictionary = data.get("mobility",{})
 if mobility.is_empty():
  return time
 var t := maxf(0.0,time-float(mobility.delay))
 var period := float(mobility.period)
 var boosted := floorf(t/period)*float(mobility.duration)+minf(fmod(t,period),float(mobility.duration))
 return time+(float(mobility.multiplier)-1.0)*boosted

func movement_time(start: float, end: float) -> float:
 return movement_integral(end)-movement_integral(start)

func burst_warning() -> bool:
 var mobility: Dictionary = data.get("mobility",{})
 if mobility.is_empty() or enemy.disable_remaining > 0:
  return false
 var t := elapsed-float(mobility.delay)
 return t < 0 and t >= -float(mobility.warning) or t >= 0 and (fmod(t,float(mobility.period)) < float(mobility.duration) or fmod(t,float(mobility.period)) > float(mobility.period)-float(mobility.warning))
