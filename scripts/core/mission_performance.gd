extends RefCounted
# Pure mission rules/validation. No currency, save writes, scenes or combat mutation.
static var DATA: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/mission_performance.json"))
const INTEGERS := ["kills","breaches","manual_shots","manual_hits","manual_kills","components","generators","weapons","heavy_engines","armored_components","core_hits","critical_hits","defense_sectors"]
const FLOATS := ["manual_damage","automatic_damage","other_damage","final_wave_damage","base_damage"]
const LABELS := {"manual_kills":"Manual kills","accuracy":"Primary accuracy","manual_shots":"Primary shots","defense_sectors":"Simultaneous sectors","heavy_engines":"Direct Heavy engine kills","core_hits":"Direct core hits","breaches":"Drones breached","generators":"Generators destroyed","weapons":"Weapons destroyed","components":"Components destroyed","armored_components":"Armored parts destroyed","final_wave_damage":"Final-wave base damage","manual_share":"Manual hull damage share"}

static func number(value: Variant, fallback: float = 0, maximum: float = 1000000000.0) -> float:
 return clampf(float(value),0,maximum) if (value is int or value is float) and is_finite(float(value)) else fallback

static func config(id: int) -> Dictionary:
 return DATA.missions.get(str(id),DATA.missions["1"])

static func clean(value: Variant, id: int) -> Dictionary:
 if not value is Dictionary or value.get("version") is bool or value.get("mission_id") is bool or value.get("version") != 1 or value.get("mission_id") != id:
  return {}
 var result := {"version":1,"mission_id":id}
 for key in INTEGERS:
  result[key] = int(number(value.get(key),0,1000000))
 for key in FLOATS:
  result[key] = number(value.get(key))
 result.health = int(number(value.get("health"),0,10000000))
 result.max_health = int(number(value.get("max_health"),0,10000000))
 if result.max_health <= 0:
  return {}
 result.health = mini(result.health,result.max_health)
 result.hp_ratio = float(result.health)/result.max_health
 result.manual_hits = mini(result.manual_hits,result.manual_shots)
 result.accuracy = float(result.manual_hits)/result.manual_shots if result.manual_shots > 0 else 0.0
 result.manual_share = result.manual_damage/maxf(.0001,result.manual_damage+result.automatic_damage+result.other_damage)
 result.seconds = number(value.get("seconds"),0,86400)
 result.defense_sectors = mini(3,result.defense_sectors)
 result.manual_kills = mini(result.manual_kills,result.kills)
 result.critical_hits = mini(result.critical_hits,result.manual_hits)
 return result

static func secondary(id: int, snapshot: Dictionary) -> Dictionary:
 var definition: Dictionary = config(id).secondary
 var complete := not snapshot.is_empty()
 var rows: Array = []
 for key in definition.rules:
  var rule: Variant = definition.rules[key]
  var actual := float(snapshot.get(key,0))
  var maximum: bool = rule is Dictionary
  var goal := float(rule.max) if maximum else float(rule)
  var met := not snapshot.is_empty() and (actual <= goal if maximum else actual+.000001 >= goal)
  complete = complete and met
  var unit := "%" if key in ["accuracy","manual_share"] else ""
  var factor := 100.0 if not unit.is_empty() else 1.0
  rows.append({"key":key,"label":LABELS.get(key,key),"actual":actual,"target":goal,"met":met,"text":"%s: %s %.0f%s / %.0f%s" % [LABELS.get(key,key),"≤" if maximum else "≥",actual*factor,unit,goal*factor,unit]})
 return {"id":str(definition.id),"name":str(definition.name),"description":str(definition.description),"complete":complete,"conditions":rows}

static func evaluate(id: int, victory: bool, value: Variant) -> Dictionary:
 var snapshot := clean(value,id)
 var objective := secondary(id,snapshot)
 var hp := float(snapshot.get("hp_ratio",0))
 var rules := config(id)
 var stars := 0
 if victory:
  stars = 1
  if hp+.000001 >= float(rules.two_star_hp):
   stars = 2
  if hp+.000001 >= float(rules.three_star_hp) and objective.complete:
   stars = 3
 var score := 0
 if victory and not snapshot.is_empty():
  var tuning: Dictionary = DATA.defaults.score.duplicate()
  tuning.merge(rules.get("score",{}),true)
  score = maxi(0,int(round(hp*float(tuning.health)))+int(snapshot.kills)*int(tuning.kill)+int(snapshot.manual_kills)*int(tuning.manual_kill)+int(snapshot.components)*int(tuning.component)+int(objective.complete)*int(tuning.secondary)-int(snapshot.breaches)*int(tuning.breach_penalty)+maxi(0,int(tuning.time_budget)-int(ceil(float(snapshot.seconds)*float(tuning.time_penalty_per_second)))))
 return {"stars":stars,"score":score,"secondary":objective,"snapshot":snapshot,"conditions":{"victory":victory,"two_hp":hp+.000001 >= float(rules.two_star_hp),"three_hp":hp+.000001 >= float(rules.three_star_hp),"secondary":bool(objective.complete)},"thresholds":{"two":float(rules.two_star_hp),"three":float(rules.three_star_hp)}}

static func record(entry: Dictionary, id: int, cleared: bool) -> Dictionary:
 var result := entry.duplicate(true)
 result.first_clear = cleared or entry.get("first_clear") == true
 result.best_stars = maxi(int(number(entry.get("best_stars"),0,3)),int(result.first_clear))
 result.best_hp_ratio = number(entry.get("best_hp_ratio"),0,1)
 result.fastest_seconds = number(entry.get("fastest_seconds"),0,86400)
 result.best_score = int(number(entry.get("best_score")))
 result.star_claims = []
 var claims: Variant = entry.get("star_claims",[])
 if claims is Array:
  for tier in [2,3]:
   for claimed in claims:
    if (claimed is int or claimed is float) and is_finite(float(claimed)) and float(claimed) == float(tier):
     result.star_claims.append(tier)
     result.best_stars = maxi(result.best_stars,tier)
     break
 result.completed_secondary = []
 var completed: Variant = entry.get("completed_secondary",[])
 if completed is Array and completed.has(str(config(id).secondary.id)):
  result.completed_secondary.append(str(config(id).secondary.id))
 var best: Variant = entry.get("best_performance",{})
 result.best_performance = {}
 if best is Dictionary:
  var parsed := evaluate(id,true,best.get("snapshot"))
  if not parsed.snapshot.is_empty():
   result.best_performance = {"stars":parsed.stars,"score":parsed.score,"snapshot":parsed.snapshot,"war_credits":int(number(best.get("war_credits")))}
   result.best_score = maxi(result.best_score,int(parsed.score))
 return result

static func improve(entry: Dictionary, id: int, attempt: Dictionary) -> Array[String]:
 var bests: Array[String] = []
 if int(attempt.stars) > int(entry.best_stars):
  entry.best_stars = int(attempt.stars)
  bests.append("STAR RATING")
 var snapshot: Dictionary = attempt.snapshot
 if snapshot.is_empty():
  return bests
 if float(snapshot.hp_ratio) > float(entry.best_hp_ratio):
  entry.best_hp_ratio = float(snapshot.hp_ratio)
  bests.append("BASE INTEGRITY")
 if entry.best_performance.is_empty() or float(snapshot.seconds) < float(entry.fastest_seconds):
  entry.fastest_seconds = float(snapshot.seconds)
  bests.append("COMPLETION TIME")
 if entry.best_performance.is_empty() or int(attempt.score) > int(entry.best_score):
  entry.best_score = int(attempt.score)
  entry.best_performance = {"stars":attempt.stars,"score":attempt.score,"snapshot":snapshot.duplicate(true),"war_credits":0}
  bests.append("SCORE")
 if attempt.secondary.complete and not entry.completed_secondary.has(str(attempt.secondary.id)):
  entry.completed_secondary.append(str(attempt.secondary.id))
  bests.append("SECONDARY OBJECTIVE")
 return bests

static func requirements(id: int) -> String:
 var data := config(id)
 return "1 STAR: victory • 2 STARS: ≥%.0f%% base HP • 3 STARS: ≥%.0f%% HP + secondary\n%s: %s" % [100*float(data.two_star_hp),100*float(data.three_star_hp),str(data.secondary.name),str(data.secondary.description)]
