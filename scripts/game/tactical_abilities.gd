extends Node
# All times consume the same simulated delta as shots, reloads and drone movement.
var battle: Node2D
var cooldowns: Dictionary = {"repair":0.0,"emp_blast":0.0,"overclock":0.0}
var overclock_remaining := 0.0

func configure(owner_battle: Node2D) -> void:
 battle = owner_battle

func tick(delta: float) -> void:
 for id in cooldowns:
  cooldowns[id] = maxf(0.0,float(cooldowns[id])-delta)
 var was_overclocked := overclock_remaining > 0
 overclock_remaining = maxf(0.0,overclock_remaining-delta)
 if was_overclocked and overclock_remaining == 0:
  _rescale_weapon_cooldowns(float(SaveManager.catalog.abilities.overclock.multiplier))

func fire_multiplier() -> float:
 return float(SaveManager.catalog.abilities.overclock.multiplier) if overclock_remaining > 0 else 1.0

func cooldown_value(id: String) -> float:
 var data: Dictionary = SaveManager.catalog.abilities[id]
 return float(data.cooldown)*(1.0+EconomyManager.modifier(str(data.mastery),battle.research_levels))

func can_activate(id: String) -> bool:
 if not cooldowns.has(id) or battle.paused or battle.finished or float(cooldowns[id]) > 0:
  return false
 var data: Dictionary = SaveManager.catalog.abilities[id]
 return battle.credits >= int(data.cost) and (id != "repair" or battle.health < battle.max_health)

func activate(id: String) -> bool:
 if not can_activate(id):
  return false
 var data: Dictionary = SaveManager.catalog.abilities[id]
 # Consume currency/cooldown before applying effects; repeated touch callbacks are inert.
 battle.credits -= int(data.cost)
 cooldowns[id] = cooldown_value(id)
 var color := Color(str(data.color))
 if id == "repair":
  var healing := int(float(data.heal)*(1.0+EconomyManager.modifier("repair_efficiency",battle.research_levels)))
  battle.health = mini(battle.max_health,battle.health+healing)
  battle.view.effect(Vector2(560,595),"build",90,color)
 elif id == "emp_blast":
  var center := Vector2(490,345)
  for enemy in battle.drones.get_children():
   if not enemy.ended and enemy.position.distance_to(center) <= float(data.radius):
    enemy.apply_disable(float(data.duration))
  battle.view.effect(center,"blast",float(data.radius),color)
 else:
  _rescale_weapon_cooldowns(1.0/float(data.multiplier))
  overclock_remaining = float(data.duration)
  battle.view.effect(battle.player_turret.position,"build",95,color)
  for turret in battle.turrets.get_children():
   battle.view.effect(turret.position,"build",45,color)
 battle.status_changed.emit()
 return true

func _rescale_weapon_cooldowns(ratio: float) -> void:
 if is_instance_valid(battle.player_turret):
  battle.player_turret.cooldown *= ratio
 for turret in battle.turrets.get_children():
  turret.cooldown *= ratio
