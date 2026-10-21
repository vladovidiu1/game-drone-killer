extends RefCounted
# Mission-scoped, seeded plans. No frame-by-frame defense tracking or stat changes.
static var CONFIG: Dictionary = preload("res://scripts/core/tactical_catalog.gd").DATA
const SECTORS := ["WEST","CENTER","EAST"]
var battle: Node2D
var seed_value := 0
var rng := RandomNumberGenerator.new()
var forced_pattern := ""
var plans: Array[Dictionary] = []
var debug_log := false

func configure(owner_battle: Node2D, seed: int) -> void:
 battle = owner_battle
 seed_value = seed
 rng.seed = seed
 debug_log = OS.is_debug_build() and "--attack-debug-log" in OS.get_cmdline_user_args()

func stage() -> Dictionary:
 for item in CONFIG.stages:
  if battle.mission_id <= int(item.through):
   return item
 return CONFIG.stages.back()

func coverage() -> Dictionary:
 var result := {"WEST":0.0,"CENTER":0.0,"EAST":0.0}
 var routes: Array = battle.mission_data.paths
 var sectors: Array = battle.mission_data.approaches.sectors
 for sector in SECTORS:
  var samples := 0
  for index in routes.size():
   if str(sectors[index]) != sector:
    continue
   for height in CONFIG.coverage_samples_y:
    var point := point_at_y(routes[index],float(height))
    samples += 1
    for turret in battle.turrets.get_children():
     if turret.position.distance_to(point) <= turret.range_value():
      # Approximate placement exposure only; no live aim, HP, ammo or money reads.
      result[sector] += turret.damage_value()*turret.fire_rate_value()
  if samples > 0:
   result[sector] = snappedf(float(result[sector])/samples,.01)
 return result

static func point_at_y(path: Array, height: float) -> Vector2:
 for index in range(1,path.size()):
  var a := Vector2(float(path[index-1][0]),float(path[index-1][1]))
  var b := Vector2(float(path[index][0]),float(path[index][1]))
  if height <= b.y:
   return a.lerp(b,clampf((height-a.y)/maxf(1.0,b.y-a.y),0,1))
 return Vector2(float(path.back()[0]),float(path.back()[1]))

func choose(wave: int, exposure: Dictionary) -> Dictionary:
 var settings := stage()
 var weights: Dictionary = settings.weights.duplicate(true)
 var weakest := "CENTER"
 for sector in SECTORS:
  if float(exposure[sector]) < float(exposure[weakest]):
   weakest = sector
 var adaptive: bool = battle.mission_id >= 16 and rng.randf() < float(settings.adaptation_chance)
 for pattern in weights:
  var bonus := 0.0
  if adaptive and pattern == {"WEST":"west_flank","CENTER":"center_breakthrough","EAST":"east_flank"}[weakest]:
   bonus += float(settings.adaptation_cap)
  if battle.mission_id >= 16:
   var historical := 0.0
   for prior in plans:
    if prior.pattern == pattern and bool(prior.get("complete",false)):
     historical += int(prior.breaches)*.02
   bonus += minf(float(settings.history_cap),historical)
  weights[pattern] = float(weights[pattern])*(1.0+minf(bonus,float(settings.adaptation_cap)+float(settings.history_cap)))
 var chosen := "balanced"
 if not forced_pattern.is_empty() and CONFIG.patterns.has(forced_pattern):
  chosen = forced_pattern
 elif CONFIG.tutorial_patterns.has(str(battle.mission_id)):
  chosen = str(CONFIG.tutorial_patterns[str(battle.mission_id)][wave])
 else:
  var total := 0.0
  for weight in weights.values():
   total += float(weight)
  var roll := rng.randf()*total
  for pattern in weights:
   roll -= float(weights[pattern])
   if roll <= 0:
    chosen = str(pattern)
    break
 return {"pattern":chosen,"weights":weights,"adaptive":adaptive,"weakest":weakest}

func threat(entries: Array) -> int:
 var value := 0
 for entry in entries:
  value += int(CONFIG.enemy_costs[str(entry.enemy)])
 return value

func bounty(entries: Array) -> int:
 var value := 0
 for entry in entries:
  value += int(CampaignManager.enemies[str(entry.enemy)].reward)
 return value

func fit_budget(source: Array[Dictionary], budget: int) -> Array[Dictionary]:
 var result: Array[Dictionary] = source.duplicate(true)
 var remaining := threat(result)
 # Calibrate the new shorter flanks without HP inflation or deleting an archetype/boss.
 while remaining > budget:
  var counts: Dictionary = {}
  for entry in result:
   counts[entry.enemy] = int(counts.get(entry.enemy,0))+1
  var selected := ""
  var highest := -1
  for kind in counts:
   var score := int(counts[kind])*int(CONFIG.enemy_costs[kind])
   if int(counts[kind]) > 1 and not CampaignManager.enemies[kind].get("boss",false) and score > highest:
    selected = str(kind)
    highest = score
  if selected.is_empty():
   break
  for index in range(result.size()-1,-1,-1):
   if result[index].enemy == selected:
    result.remove_at(index)
    remaining -= int(CONFIG.enemy_costs[selected])
    break
 return result

func compose(source: Array[Dictionary], pattern: String, budget: int, reward_cap: int) -> Array[Dictionary]:
 var result: Array[Dictionary] = source.duplicate(true)
 if battle.mission_id <= 3:
  return result
 var allowed: Array = []
 for wave in battle.mission_data.waves:
  for group in wave.groups:
   if not allowed.has(str(group.enemy)) and not CampaignManager.enemies[str(group.enemy)].get("boss",false):
    allowed.append(str(group.enemy))
 for change in int(CONFIG.elite_composition_changes if pattern == "elite" else CONFIG.maximum_composition_changes):
  var candidate: Array[Dictionary] = result.duplicate(true)
  if pattern == "swarm":
   var replace := -1
   for index in candidate.size():
    if candidate[index].enemy in ["heavy","assault"]:
     replace = index
     break
   if replace < 0:
    break
   var count := mini(int(CONFIG.enemy_costs[candidate[replace].enemy]),int(float(CampaignManager.enemies[candidate[replace].enemy].reward)/float(CampaignManager.enemies.scout.reward)))
   candidate.remove_at(replace)
   for i in count:
    candidate.append({"enemy":"scout"})
  elif pattern == "elite":
   var kind := "emp" if change%2 == 0 and allowed.has("emp") else "heavy"
   if not allowed.has(kind):
    break
   var needed := int(CONFIG.enemy_costs[kind])
   var removed := 0
   for index in range(candidate.size()-1,-1,-1):
    if candidate[index].enemy == "scout" and removed < needed:
     candidate.remove_at(index)
     removed += 1
   if removed < needed:
    break
   candidate.append({"enemy":kind})
  else:
   break
  if candidate.size() <= int(ceil(source.size()*float(CONFIG.maximum_count_multiplier))) and threat(candidate) >= int(ceil(budget*float(CONFIG.minimum_spent_ratio))) and threat(candidate) <= budget and bounty(candidate) <= reward_cap:
   result = candidate
 return result

func prepare(wave: int, definition: Dictionary) -> Dictionary:
 var exposure := coverage()
 var selection := choose(wave,exposure)
 var pattern := str(selection.pattern)
 var source: Array[Dictionary] = []
 # Interleave groups so support, armor and light contacts form coordinated packets.
 var groups: Array = definition.groups.duplicate(true)
 while true:
  var added := false
  for group in groups:
   if int(group.count) > 0:
    source.append({"enemy":str(group.enemy)})
    group.count = int(group.count)-1
    added = true
  if not added:
   break
 var baseline_budget: int = battle.mission_data.approaches.wave_budgets[wave]
 var budget := int(floor(baseline_budget*float(stage().budget_multiplier)))
 var entries := compose(fit_budget(source,budget),pattern,budget,bounty(source))
 var weights: Array = CONFIG.patterns[pattern].weights
 var quota := [0,0,0]
 var sum := float(weights[0])+float(weights[1])+float(weights[2])
 for index in entries.size():
  var best := 0
  var score := -INF
  for sector_index in 3:
   var deficit: float = float(weights[sector_index])/sum*(index+1)-quota[sector_index]
   if deficit > score:
    score = deficit
    best = sector_index
  quota[best] += 1
 var counts := {"WEST":0,"CENTER":0,"EAST":0}
 var decoy_sector := "WEST" if rng.randi_range(0,1) == 0 else "EAST"
 var mixed: Array[Dictionary] = []
 # Consume quotas to bound random pressure; random choices only break route/order ties.
 for entry in entries:
  var kind := str(entry.enemy)
  var data: Dictionary = CampaignManager.enemies[kind]
  var chosen := 0
  var highest := -INF
  for sector_index in 3:
   var deficit := float(quota[sector_index])-int(counts[SECTORS[sector_index]])
   if deficit > highest:
    highest = deficit
    chosen = sector_index
  var sector: String = SECTORS[chosen]
  if bool(data.get("boss",false)) or (pattern == "center_breakthrough" and bool(data.get("armored",false))):
   sector = "CENTER"
  elif pattern == "decoy":
   sector = decoy_sector if bool(data.get("armored",false)) or kind in ["shield","emp"] else ("EAST" if decoy_sector == "WEST" else "WEST")
  var routes: Array[int] = []
  for route in battle.mission_data.approaches.sectors.size():
   if str(battle.mission_data.approaches.sectors[route]) == sector:
    routes.append(route)
  var route := routes[rng.randi_range(0,routes.size()-1)]
  counts[sector] += 1
  mixed.append({"enemy":kind,"path":route,"sector":sector,"directed":true,"formation":"column"})
 var support_budget := 0
 for entry in source:
  var enemy_data: Dictionary = CampaignManager.enemies[str(entry.enemy)]
  support_budget += int(CONFIG.support_reserve.boss) if enemy_data.get("boss",false) else int(CONFIG.support_reserve.carrier) if entry.enemy == "carrier" else 0
 var plan := {"support_budget":support_budget,"support_spent":0,"wave":wave+1,"seed":seed_value,"pattern":pattern,"name":str(CONFIG.patterns[pattern].name),"warning":str(CONFIG.patterns[pattern].warning),"warning_seconds":float(CONFIG.warning_seconds),"entries":mixed,"baseline_budget":baseline_budget,"budget":budget,"spent":threat(mixed),"bounty_cap":bounty(source),"planned_bounty":bounty(mixed),"sectors":counts,"sector_outcomes":{"WEST":{"kills":0,"breaches":0,"supports":0},"CENTER":{"kills":0,"breaches":0,"supports":0},"EAST":{"kills":0,"breaches":0,"supports":0}},"coverage":exposure,"weights":selection.weights,"adaptive":selection.adaptive,"weakest":selection.weakest,"kills":0,"breaches":0,"supports":0,"complete":false,"base_before":battle.health}
 plans.append(plan)
 if debug_log:
  print("TACTICAL PLAN: "+JSON.stringify(plan))
 return plan

func record(enemy: Node2D, event: String) -> void:
 var index := int(enemy.get_meta("attack_wave",-1))
 if index >= 0 and index < plans.size():
  plans[index][event] += 1
  var sector := str(enemy.get_meta("attack_sector","CENTER"))
  plans[index].sector_outcomes[sector][event] += 1

func complete(wave: int) -> void:
 if wave < 0 or wave >= plans.size() or plans[wave].complete:
  return
 plans[wave].complete = true
 plans[wave].base_after = battle.health
 if debug_log:
  print("TACTICAL OUTCOME: "+JSON.stringify(plans[wave]))

func reserve_support(kind: String, parent: Node2D) -> bool:
 var index := int(parent.get_meta("attack_wave",-1))
 if index < 0 or index >= plans.size():
  return true # Explicit fixtures/non-directed spawns retain their existing contract.
 var cost := int(CONFIG.enemy_costs[kind])
 if int(plans[index].support_spent)+cost > int(plans[index].support_budget):
  return false
 plans[index].support_spent += cost
 return true

func finish(victory: bool) -> void:
 if plans.is_empty():
  return
 var plan: Dictionary = plans.back()
 plan.terminated = true
 plan.victory = victory
 plan.base_after = battle.health
 if debug_log:
  print("TACTICAL RESULT: "+JSON.stringify(plan))
