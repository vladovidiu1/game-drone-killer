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
 elif not prerequisites_met(item.get("requires",{})):
  reason = "Requires "+prerequisite_text(item.get("requires",{}))
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
  var item: Dictionary = SaveManager.catalog.upgrades[id]
  if expected_level == 0 and item.has("specialization_for") and not SaveManager.state.turret_specializations.has(str(item.specialization_for)):
   SaveManager.state.turret_specializations[str(item.specialization_for)] = str(item.branch)
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
 if not SaveManager.state.ammo_loadout.has(id):
  if SaveManager.state.ammo_loadout.size() >= 3:
   return false
  SaveManager.state.ammo_loadout.append(id)
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
 var stats: Dictionary = preload("res://scripts/core/weapon_technology.gd").turret(kind,SaveManager.state.get("research",{}),SaveManager.state.get("turret_specializations",{}))
 stats.damage *= (1.0+int(SaveManager.state.get("damage_level",0))*float(CampaignManager.combat.permanent_damage_step))*(1.0+modifier("turret_damage"))
 stats.range *= 1.0+modifier("turret_range")
 stats.fire_rate *= 1.0+modifier("turret_rate")
 return stats

func prerequisites_met(requirements: Dictionary) -> bool:
 for id in requirements:
  var level := research_level(str(id)) if SaveManager.catalog.upgrades.has(id) else (1 if unlocked(str(id)) else 0)
  if level < int(requirements[id]):
   return false
 return true

func prerequisite_text(requirements: Dictionary) -> String:
 var labels: PackedStringArray = []
 for id in requirements:
  var item: Dictionary = SaveManager.catalog.upgrades.get(id,SaveManager.catalog.unlocks.get(id,{}))
  labels.append(str(item.get("name",id))+" L"+str(requirements[id]))
 return ", ".join(labels) if not labels.is_empty() else "None"

func set_loadout(ids: Array) -> bool:
 if not SaveManager.has_campaign() or ids.is_empty() or ids.size() > 3:
  return false
 var unique: Array = []
 for id in ids:
  if not id is String or not SaveManager.catalog.ammunition.has(id) or not unlocked(id) or unique.has(id):
   return false
  unique.append(id)
 var previous := SaveManager.state.duplicate(true)
 SaveManager.state.ammo_loadout = unique
 if not unique.has(SaveManager.state.equipped_ammo):
  SaveManager.state.equipped_ammo = unique[0]
 if not SaveManager.persist():
  SaveManager.state = previous
  return false
 return true

func select_specialization(kind: String, branch: String) -> bool:
 if not SaveManager.has_campaign() or not SaveManager.catalog.turret_specializations.has(kind):
  return false
 if not branch.is_empty():
  var branches: Dictionary = SaveManager.catalog.turret_specializations[kind]
  if not branches.has(branch) or research_level(str(branches[branch].research)) < 1:
   return false
 var previous := SaveManager.state.duplicate(true)
 SaveManager.state.turret_specializations[kind] = branch
 if not SaveManager.persist():
  SaveManager.state = previous
  return false
 balance_changed.emit()
 return true
