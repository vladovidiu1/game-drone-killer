extends Node
signal balance_changed
const MAX_LEVEL := 5

func add_credits(amount: int) -> void:
 SaveManager.state.credits = maxi(0, int(SaveManager.state.get("credits", 0)) + amount)
 balance_changed.emit()

func upgrade_cost() -> int:
 return 100 + int(SaveManager.state.get("damage_level", 0)) * 75

func buy_damage() -> bool:
 if not SaveManager.has_campaign() or int(SaveManager.state.damage_level) >= MAX_LEVEL:
  return false
 var cost := upgrade_cost()
 if int(SaveManager.state.credits) < cost:
  return false
 var previous := SaveManager.state.duplicate(true)
 SaveManager.state.credits -= cost
 SaveManager.state.damage_level += 1
 if not SaveManager.persist():
  SaveManager.state = previous
  return false
 balance_changed.emit()
 return true

func research_level(id: String, levels: Dictionary = {}) -> int:
 var source: Dictionary = SaveManager.state.get("research",{}) if levels.is_empty() else levels
 return int(source.get(id,0))

func unlocked(id: String) -> bool:
 return id in ["standard","machine_gun","cannon","missile"] or SaveManager.state.get("unlocks",[]).has(id)

func purchase_state(id: String) -> Dictionary:
 var catalog: Dictionary = SaveManager.catalog
 var item: Dictionary = catalog.upgrades.get(id,catalog.unlocks.get(id,{}))
 if item.is_empty() or not SaveManager.has_campaign():
  return {"allowed":false,"reason":"Start a campaign first","cost":0,"level":0}
 var is_upgrade: bool = catalog.upgrades.has(id)
 var level := research_level(id) if is_upgrade else (1 if unlocked(id) else 0)
 var maximum: int = item.costs.size() if is_upgrade else 1
 var cost := int(item.costs[level]) if is_upgrade and level < maximum else int(item.get("cost",0))
 var reason := "Available"
 if level >= maximum:
  reason = "MAXIMUM" if is_upgrade else "UNLOCKED"
 elif int(SaveManager.state.highest) < int(item.highest):
  reason = "Requires highest mission %d" % int(item.highest)
 elif int(SaveManager.state.credits) < cost:
  reason = "Insufficient War Credits (%d short)" % (cost-int(SaveManager.state.credits))
 return {"allowed":reason == "Available","reason":reason,"cost":cost,"level":level}

func purchase(id: String, expected_level: int) -> bool:
 var offer := purchase_state(id)
 if not offer.allowed or int(offer.level) != expected_level:
  return false
 var previous := SaveManager.state.duplicate(true)
 SaveManager.state.credits -= int(offer.cost)
 if SaveManager.catalog.upgrades.has(id):
  SaveManager.state.research[id] = expected_level+1
 else:
  SaveManager.state.unlocks.append(id)
 if not SaveManager.persist():
  SaveManager.state = previous
  return false
 balance_changed.emit()
 return true

func equip_ammunition(id: String) -> bool:
 if not SaveManager.has_campaign() or not SaveManager.catalog.ammunition.has(id) or not unlocked(id):
  return false
 if SaveManager.state.equipped_ammo == id:
  return true
 var previous := SaveManager.state.duplicate(true)
 SaveManager.state.equipped_ammo = id
 if not SaveManager.persist():
  SaveManager.state = previous
  return false
 return true

func modifier(id: String, levels: Dictionary = {}) -> float:
 return float(SaveManager.catalog.upgrades[id].per_level)*research_level(id,levels)

func primary_stats(levels: Dictionary = {}) -> Dictionary:
 var stats: Dictionary = CampaignManager.player_cannon.duplicate(true)
 stats.damage *= (1.0+int(SaveManager.state.get("damage_level",0))*float(CampaignManager.combat.permanent_damage_step))*(1.0+modifier("cannon_damage",levels))
 stats.fire_rate *= 1.0+modifier("cannon_rate",levels)
 stats.magazine_size = int(stats.magazine_size)+int(modifier("magazine",levels))
 stats.reload_time *= 1.0+modifier("reload",levels)
 stats.projectile_speed *= 1.0+modifier("velocity",levels)
 stats.critical_chance += modifier("crit_chance",levels)
 stats.critical_multiplier += modifier("crit_damage",levels)
 return stats

func grant_objectives() -> int:
 # Called only inside the campaign outcome transaction; caller persists everything.
 var reward := 0
 for id in SaveManager.catalog.objectives:
  var objective: Dictionary = SaveManager.catalog.objectives[id]
  if not SaveManager.state.claimed_objectives.has(id) and int(SaveManager.state.wins) >= int(objective.wins) and int(SaveManager.state.checkpoint) >= int(objective.checkpoint):
   SaveManager.state.claimed_objectives.append(id)
   reward += int(objective.reward)
 SaveManager.state.credits += reward
 return reward

func automatic_stats(kind: String) -> Dictionary:
 var stats: Dictionary = CampaignManager.turrets[kind].duplicate(true)
 stats.damage *= (1.0+int(SaveManager.state.get("damage_level",0))*float(CampaignManager.combat.permanent_damage_step))*(1.0+modifier("turret_damage"))
 stats.range *= 1.0+modifier("turret_range")
 stats.fire_rate *= 1.0+modifier("turret_rate")
 return stats
