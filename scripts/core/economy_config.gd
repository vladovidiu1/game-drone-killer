extends RefCounted
# One editable source of currency values. Hydrate the existing runtime catalogs,
# keeping every UI, simulation and purchase path on the same authoritative prices.
static var values: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))

static func progression() -> Dictionary:
 var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/progression.json"))
 for id in catalog.upgrades:
  catalog.upgrades[id].costs = values.research_costs[id].duplicate()
 for id in catalog.unlocks:
  catalog.unlocks[id].cost = int(values.unlock_costs[id])
 for id in catalog.abilities:
  catalog.abilities[id].cost = int(values.battle.ability_costs[id])
 for id in catalog.objectives:
  catalog.objectives[id].reward = int(values.objective_rewards[id])
 return catalog

static func definitions() -> Dictionary:
 var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/definitions.json"))
 for mission in catalog.missions:
  mission.reward = int(values.war.first_clear[str(int(mission.id))])
  mission.starting_credits = int(values.battle.starting_credits[str(int(mission.id))])
 for id in catalog.enemies:
  catalog.enemies[id].reward = int(values.battle.bounties[id])
 for id in catalog.turrets:
  catalog.turrets[id].cost = int(values.battle.construction[id])
 catalog.combat.upgrade_cost_multiplier = float(values.battle.upgrade_cost_multiplier)
 return catalog
