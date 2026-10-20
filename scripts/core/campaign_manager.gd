extends Node
signal frontline_changed
const CHAPTERS := ["The Invasion","Hold the Line","Counterattack","Enemy Territory","Final Offensive"]
var missions: Array = []
var enemies: Dictionary = {}
var turrets: Dictionary = {}
var combat: Dictionary = {}
var player_cannon: Dictionary = {}

func _ready() -> void:
 var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/definitions.json"))
 missions = data.missions
 enemies = data.enemies
 turrets = data.turrets
 combat = data.combat
 player_cannon = data.player_cannon

func mission(id: int) -> Dictionary:
 return missions[id-1] if id >= 1 and id <= missions.size() else {}

func can_play(id: int) -> bool:
 var definition := mission(id)
 return SaveManager.has_campaign() and not definition.is_empty() and bool(definition.playable) and id <= int(SaveManager.state.frontline)

func territory_state(id: int) -> String:
 var frontline := int(SaveManager.state.get("frontline",1))
 if id == frontline:
  return "CONTESTED FRONTLINE"
 return "CONTROLLED" if id < frontline else "ENEMY / LOCKED"

func begin_mission(id: int) -> String:
 if not can_play(id):
  return ""
 var previous := SaveManager.state.duplicate(true)
 var token := Crypto.new().generate_random_bytes(16).hex_encode()
 SaveManager.state.active_run = {"id":token,"mission_id":id,"frontline":int(SaveManager.state.frontline)}
 if not SaveManager.persist():
  SaveManager.state = previous
  return ""
 return token

func resolve(victory: bool, mission_id: int, run_id: String, stats: Dictionary = {}) -> Dictionary:
 var active: Dictionary = SaveManager.state.get("active_run",{})
 if run_id.is_empty() or active.get("id") != run_id or int(active.get("mission_id",0)) != mission_id:
  return {}
 var previous := SaveManager.state.duplicate(true)
 var before := int(SaveManager.state.frontline)
 var reward := int(mission(mission_id).get("reward",0)) if victory else 0
 var record: Dictionary = SaveManager.state.records.get(str(mission_id),{"victories":0,"defeats":0,"best_health":0,"rewards":0,"last_outcome":"defeat"})
 if victory:
  record.victories += 1
  record.best_health = maxi(int(record.best_health),SaveManager.integer(stats.get("health"),0,0,10000000))
  record.rewards += reward
  record.last_outcome = "victory"
  SaveManager.state.wins += 1
  SaveManager.state.credits += reward
  if mission_id == before:
   SaveManager.state.frontline = mini(25,before+1)
  if mission_id in [5,10,15,20] and not SaveManager.state.checkpoints.has(mission_id):
   SaveManager.state.checkpoints.append(mission_id)
   SaveManager.state.checkpoints.sort()
   SaveManager.state.checkpoint = int(SaveManager.state.checkpoints.back())
 else:
  record.defeats += 1
  record.last_outcome = "defeat"
  SaveManager.state.frontline = maxi(int(SaveManager.state.checkpoint),before-1)
 SaveManager.state.records[str(mission_id)] = record
 SaveManager.state.highest = maxi(int(SaveManager.state.highest),int(SaveManager.state.frontline))
 var objective_reward := EconomyManager.grant_objectives() if victory else 0
 var after := int(SaveManager.state.frontline)
 var message := ""
 if victory:
  message = "Territory gained: %s. Frontline %02d → %02d." % [mission(mission_id).name,before,after] if after > before else "Replay victory: %s. Frontline unchanged at %02d." % [mission(mission_id).name,after]
  if mission_id in [5,10,15,20]:
   message += " Checkpoint %02d permanently secured." % mission_id
 elif after < before:
  message = "Territory lost: %s is contested again. Frontline %02d → %02d." % [mission(after).name,before,after]
 elif mission_id == before:
  message = "Checkpoint holds at %02d. No territory lost." % after
 else:
  message = "Replay defeated. Active frontline remains %02d." % after
 var result := {"run_id":run_id,"mission_id":mission_id,"victory":victory,"reward":reward+objective_reward,"mission_reward":reward,"objective_reward":objective_reward,"from":before,"to":after,"message":message}
 SaveManager.state.last_result = result
 SaveManager.state.active_run = {}
 if not SaveManager.persist():
  SaveManager.state = previous
  return {}
 EconomyManager.balance_changed.emit()
 frontline_changed.emit()
 return result
