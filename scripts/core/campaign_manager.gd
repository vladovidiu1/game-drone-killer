extends Node
signal frontline_changed
const PERFORMANCE := preload("res://scripts/core/mission_performance.gd")
const CHAPTERS := ["The Invasion","Hold the Line","Counterattack","Enemy Territory","Final Offensive"]
var missions: Array = []
var enemies: Dictionary = {}
var turrets: Dictionary = {}
var combat: Dictionary = {}
var balance: Dictionary = {}
var player_cannon: Dictionary = {}

func _ready() -> void:
 var data: Dictionary = preload("res://scripts/core/economy_config.gd").definitions()
 missions = data.missions
 enemies = data.enemies
 turrets = data.turrets
 combat = data.combat
 balance = data.balance
 player_cannon = data.player_cannon

func mission(id: int) -> Dictionary:
 return missions[id-1] if id >= 1 and id <= missions.size() else {}

func can_play(id: int) -> bool:
 var definition := mission(id)
 return SaveManager.has_campaign() and not definition.is_empty() and bool(definition.playable) and (id <= int(SaveManager.state.frontline) or completed(id))

func territory_state(id: int) -> String:
 var frontline := int(SaveManager.state.get("frontline",1))
 if id == 25 and bool(SaveManager.state.get("campaign_complete",false)):
  return "CONTROLLED"
 if id == frontline:
  return "CONTESTED FRONTLINE"
 return "CONTROLLED" if id < frontline else "ENEMY / LOCKED"

func completed(id: int) -> bool:
 var entry: Dictionary = SaveManager.state.get("records",{}).get(str(id),{})
 return id >= 1 and id <= 25 and (entry.get("first_clear",false) or int(entry.get("victories",0)) > 0 or id < int(SaveManager.state.get("highest",1)))

func total_stars() -> int:
 var total := 0
 for entry in SaveManager.state.get("records",{}).values():
  total += int(entry.get("best_stars",0))
 return mini(75,total)

func begin_mission(id: int, mode: String = "frontline") -> String:
 if not can_play(id) or mode not in ["frontline","replay"]:
  return ""
 if id != int(SaveManager.state.frontline):
  mode = "replay"
 if mode == "replay" and not completed(id):
  return ""
 var previous := SaveManager.state.duplicate(true)
 var token := Crypto.new().generate_random_bytes(16).hex_encode()
 SaveManager.state.active_run = {"id":token,"mission_id":id,"frontline":int(SaveManager.state.frontline),"mode":mode}
 if not SaveManager.persist():
  SaveManager.state = previous
  return ""
 return token

func resolve(victory: bool, mission_id: int, run_id: String, stats: Dictionary = {}) -> Dictionary:
 var active: Dictionary = SaveManager.state.get("active_run",{})
 if run_id.is_empty() or active.get("id") != run_id or int(active.get("mission_id",0)) != mission_id:
  return {}
 var mode := str(active.get("mode","frontline"))
 if mode == "frontline" and mission_id != int(SaveManager.state.frontline):
  return {}
 var previous := SaveManager.state.duplicate(true)
 var before := int(SaveManager.state.frontline)
 var quote := EconomyManager.victory_quote(mission_id)
 var reward := int(quote.reward) if victory else 0
 var record: Dictionary = PERFORMANCE.record(SaveManager.state.records.get(str(mission_id),{"victories":0,"defeats":0,"best_health":0,"rewards":0,"last_outcome":"defeat"}),mission_id,completed(mission_id))
 var performance := PERFORMANCE.evaluate(mission_id,victory,stats.get("performance",{}))
 var new_bests: Array[String] = []
 var star_reward := 0
 if victory:
  new_bests = PERFORMANCE.improve(record,mission_id,performance)
  record.first_clear = true
  star_reward = EconomyManager.grant_star_milestones(record,int(performance.stars))
  record.victories += 1
  record.best_health = maxi(int(record.best_health),SaveManager.integer(performance.snapshot.get("health",stats.get("health")),0,0,10000000))
  record.rewards += reward+star_reward
  record.last_outcome = "victory"
  SaveManager.state.wins += 1
  SaveManager.state.credits += reward+star_reward
  if mode == "frontline" and mission_id == 25:
   SaveManager.state.campaign_complete = true
  if mode == "frontline" and mission_id == before:
   SaveManager.state.frontline = mini(25,before+1)
  if mode == "frontline" and mission_id in [5,10,15,20] and not SaveManager.state.checkpoints.has(mission_id):
   SaveManager.state.checkpoints.append(mission_id)
   SaveManager.state.checkpoints.sort()
   SaveManager.state.checkpoint = int(SaveManager.state.checkpoints.back())
 else:
  record.defeats += 1
  record.last_outcome = "defeat"
  if mode == "frontline":
   SaveManager.state.frontline = maxi(int(SaveManager.state.checkpoint),before-1)
 if int(SaveManager.state.frontline) < 25:
  SaveManager.state.campaign_complete = false
 SaveManager.state.records[str(mission_id)] = record
 SaveManager.state.highest = maxi(int(SaveManager.state.highest),int(SaveManager.state.frontline))
 var objective_reward := EconomyManager.grant_objectives() if victory else 0
 var after := int(SaveManager.state.frontline)
 var message := ""
 if mode == "replay":
  message = "Optional replay %s: %s. Frontline protected at %02d." % ["victory" if victory else "defeated",mission(mission_id).name,after]
 elif victory:
  message = "Territory gained: %s. Frontline %02d → %02d." % [mission(mission_id).name,before,after] if after > before else "Replay victory: %s. Frontline unchanged at %02d." % [mission(mission_id).name,after]
  if mode == "frontline" and mission_id in [5,10,15,20]:
   message += " Checkpoint %02d permanently secured." % mission_id
 elif after < before:
  message = "Territory lost: %s is contested again. Frontline %02d → %02d." % [mission(after).name,before,after]
 elif mission_id == before:
  message = "Checkpoint holds at %02d. No territory lost." % after
 else:
  message = "Replay defeated. Active frontline remains %02d." % after
 if victory:
  message += "\n%s: +%d War Credits." % ["First-clear reward" if quote.first_clear else "Replay reward",reward]
 if victory and not str(mission(mission_id).get("narrative","")).is_empty():
  message += "\n"+str(mission(mission_id).narrative)
 var result := {"run_id":run_id,"mission_id":mission_id,"victory":victory,"reward":reward+objective_reward+star_reward,"star_reward":star_reward,"mode":mode,"stars":performance.stars,"performance":performance,"new_bests":new_bests,"mission_reward":reward,"objective_reward":objective_reward,"from":before,"to":after,"message":message}
 if victory and star_reward > 0:
  result.message += "\nNew star milestones: +%d War Credits (once only)." % star_reward
 if victory and new_bests.has("SCORE"):
  record.best_performance.war_credits = int(result.reward)
 SaveManager.state.last_result = result
 SaveManager.state.active_run = {}
 if not SaveManager.persist():
  SaveManager.state = previous
  return {}
 EconomyManager.balance_changed.emit()
 frontline_changed.emit()
 return result
