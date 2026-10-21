extends Node
signal saved
const PATH := "user://campaign.json"
const SETTINGS_PATH := "user://settings.json"
const VERSION := 3
const FLOORS := [1,5,10,15,20]
const DEFAULT_SETTINGS := {"volume":0.6,"muted":false,"reduced_motion":false,"reduced_environment_effects":false,"reduced_effects":false,"effects_quality":"medium","effects_smoke":true,"effects_debris":true,"effects_lighting":true,"effects_shake":true}
var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/progression.json"))
var state: Dictionary = {}
var settings: Dictionary = DEFAULT_SETTINGS.duplicate()
var last_error := ""
var recovery_notice := ""

func _ready() -> void:
 reload_from_disk()

func integer(value: Variant, fallback: int, low: int, high: int) -> int:
 if (value is int or value is float) and is_finite(float(value)):
  return int(clampf(float(value),float(low),float(high)))
 return fallback

func fresh_state() -> Dictionary:
 return {"version":VERSION,"frontline":1,"highest":1,"checkpoint":1,"checkpoints":[1],"credits":0,"damage_level":0,"wins":0,"records":{},"active_run":{},"last_result":{},"research":{},"unlocks":[],"equipped_ammo":"standard","weapon_schema":1,"ammo_loadout":["standard"],"turret_specializations":{},"claimed_objectives":[],"campaign_complete":false}

func validate_campaign(value: Variant) -> Dictionary:
 if not value is Dictionary:
  return {}
 var version := integer(value.get("version"),0,0,1000)
 if version not in [1,2,VERSION] or value.get("version") != version or not value.has("frontline") or not (value.frontline is int or value.frontline is float):
  return {}
 var result := fresh_state()
 result.frontline = integer(value.frontline,1,1,25)
 result.highest = maxi(result.frontline,integer(value.get("highest"),result.frontline,1,25))
 result.credits = integer(value.get("credits"),0,0,1000000000)
 result.damage_level = integer(value.get("damage_level"),0,0,5)
 result.wins = integer(value.get("wins"),0,0,1000000)
 if version == 1:
  var old_floor := integer(value.get("checkpoint"),1,1,result.highest)
  if old_floor in [6,11,16,21]:
   old_floor -= 1
  for floor_index in FLOORS:
   if floor_index > 1 and floor_index <= old_floor:
    result.checkpoints.append(floor_index)
 else:
  var secured: Variant = value.get("checkpoints",[1])
  if secured is Array:
   for candidate in secured:
    var floor_index := integer(candidate,0,0,25)
    if floor_index in FLOORS and floor_index <= result.highest and not result.checkpoints.has(floor_index):
     result.checkpoints.append(floor_index)
 result.checkpoints.sort()
 result.checkpoint = int(result.checkpoints.back())
 result.frontline = maxi(result.frontline,result.checkpoint)
 var records: Variant = value.get("records",{})
 if records is Dictionary:
  for id in range(1,26):
   var entry: Variant = records.get(str(id))
   if not entry is Dictionary:
    continue
   result.records[str(id)] = {"victories":integer(entry.get("victories"),0,0,1000000),"defeats":integer(entry.get("defeats"),0,0,1000000),"best_health":integer(entry.get("best_health"),0,0,10000000),"rewards":integer(entry.get("rewards"),0,0,1000000000),"last_outcome":"victory" if entry.get("last_outcome") == "victory" else "defeat"}
 result.campaign_complete = value.get("campaign_complete") is bool and value.campaign_complete == true and result.frontline == 25 and int(result.records.get("25",{}).get("victories",0)) > 0
 var research: Variant = value.get("research",{})
 for key in catalog.upgrades:
  result.research[key] = integer(research.get(key),0,0,catalog.upgrades[key].costs.size()) if research is Dictionary else 0
 for field in ["unlocks","claimed_objectives"]:
  var entries: Variant = value.get(field,[])
  var known: Dictionary = catalog.unlocks if field == "unlocks" else catalog.objectives
  if entries is Array:
   for key in entries:
    if key is String and known.has(key) and not result[field].has(key):
     result[field].append(key)
 var ammo: Variant = value.get("equipped_ammo","standard")
 if ammo is String and catalog.ammunition.has(ammo) and (ammo == "standard" or result.unlocks.has(ammo)):
  result.equipped_ammo = ammo
 # Additive weapon-schema migration keeps v1/v2/v3 campaign transactions intact.
 var loadout: Variant = value.get("ammo_loadout")
 result.ammo_loadout = []
 if loadout is Array:
  for id in loadout:
   if result.ammo_loadout.size() < 3 and id is String and catalog.ammunition.has(id) and (id == "standard" or result.unlocks.has(id)) and not result.ammo_loadout.has(id):
    result.ammo_loadout.append(id)
 else:
  # Old active preference plus the two legacy purchases retain their loadout.
  result.ammo_loadout.append(result.equipped_ammo)
  for id in ["standard","armor_piercing","explosive"]:
   if result.ammo_loadout.size() < 3 and (id == "standard" or result.unlocks.has(id)) and not result.ammo_loadout.has(id):
    result.ammo_loadout.append(id)
 if result.ammo_loadout.is_empty():
  result.ammo_loadout = ["standard"]
 if not result.ammo_loadout.has(result.equipped_ammo):
  result.equipped_ammo = result.ammo_loadout[0]
 var choices: Variant = value.get("turret_specializations",{})
 if choices is Dictionary:
  for kind in catalog.turret_specializations:
   var choice: Variant = choices.get(kind)
   if choice is String and catalog.turret_specializations[kind].has(choice) and int(result.research.get(catalog.turret_specializations[kind][choice].research,0)) > 0:
    result.turret_specializations[kind] = choice
 var active: Variant = value.get("active_run",{})
 if active is Dictionary and valid_token(active.get("id")):
  var mission_id := integer(active.get("mission_id"),0,0,25)
  if mission_id >= 1 and mission_id <= result.frontline:
   result.active_run = {"id":active.id,"mission_id":mission_id,"frontline":result.frontline}
 var outcome: Variant = value.get("last_result",{})
 if outcome is Dictionary and valid_token(outcome.get("run_id")):
  result.last_result = {"run_id":outcome.run_id,"mission_id":integer(outcome.get("mission_id"),1,1,25),"victory":outcome.get("victory") == true,"reward":integer(outcome.get("reward"),0,0,1000000000),"mission_reward":integer(outcome.get("mission_reward",outcome.get("reward")),0,0,1000000000),"objective_reward":integer(outcome.get("objective_reward"),0,0,1000000000),"from":integer(outcome.get("from"),1,1,25),"to":integer(outcome.get("to"),1,1,25),"message":str(outcome.get("message","")).left(500)}
 return result

func valid_token(value: Variant) -> bool:
 return value is String and value.length() == 32 and value.is_valid_hex_number(false)

func validate_settings(value: Variant) -> Dictionary:
 if not value is Dictionary:
  return {}
 var source: Variant = value
 if value.has("version"):
  var settings_version := integer(value.version,0,0,1000)
  if settings_version not in [2,VERSION] or value.version != settings_version or value.version is bool or not value.get("settings") is Dictionary:
   return {}
  source = value.settings
 # Legacy settings were an unwrapped dictionary.
 var recognized := false
 for key in DEFAULT_SETTINGS:
  recognized = recognized or source.has(key)
 if not recognized:
  return {}
 var result := DEFAULT_SETTINGS.duplicate()
 var volume: Variant = source.get("volume")
 if (volume is int or volume is float) and is_finite(float(volume)):
  result.volume = clampf(float(volume),0.0,1.0)
 for key in ["muted","reduced_motion","reduced_environment_effects","reduced_effects","effects_smoke","effects_debris","effects_lighting","effects_shake"]:
  if source.get(key) is bool:
   result[key] = source[key]
 if source.get("effects_quality") is String and source.effects_quality in ["low","medium","high"]:
  result.effects_quality = source.effects_quality
 return result

func _read(path: String) -> Variant:
 if not FileAccess.file_exists(path):
  return null
 var file := FileAccess.open(path,FileAccess.READ)
 if file == null or file.get_length() > 4*1024*1024:
  return null
 var parser := JSON.new()
 if parser.parse(file.get_as_text()) != OK:
  return null
 return parser.data

func _valid(path: String, value: Variant) -> Dictionary:
 return validate_settings(value) if path == SETTINGS_PATH else validate_campaign(value)

func _recover(path: String) -> Dictionary:
 var loaded := _valid(path,_read(path))
 if not loaded.is_empty():
  return loaded
 var backup := _valid(path,_read(path+".bak"))
 if not backup.is_empty():
  recovery_notice += "Recovered %s from its last valid backup. " % path.get_file()
  return backup
 if FileAccess.file_exists(path) or FileAccess.file_exists(path+".bak"):
  recovery_notice += "Invalid %s preserved; using safe defaults. " % path.get_file()
 return {}

func reload_from_disk() -> void:
 recovery_notice = ""
 state = _recover(PATH)
 settings = DEFAULT_SETTINGS.duplicate()
 settings.merge(_recover(SETTINGS_PATH),true)

func has_campaign() -> bool:
 return not state.is_empty()

func new_campaign() -> bool:
 var previous := state.duplicate(true)
 state = fresh_state()
 if not persist():
  state = previous
  return false
 return true

func _write(path: String, value: Dictionary) -> bool:
 var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file == null:
  last_error = "Cannot write save: "+error_string(FileAccess.get_open_error())
  return false
 file.store_string(JSON.stringify(value))
 file.flush()
 var write_error := file.get_error()
 file.close()
 if write_error != OK or _valid(path,_read(path+".tmp")).is_empty():
  last_error = "Save verification failed; previous save retained."
  return false
 if FileAccess.file_exists(path):
  if not _valid(path,_read(path)).is_empty():
   var backup_error := DirAccess.copy_absolute(path,path+".bak.tmp")
   if backup_error == OK:
    backup_error = DirAccess.rename_absolute(path+".bak.tmp",path+".bak")
   if backup_error != OK:
    last_error = "Cannot preserve previous save: "+error_string(backup_error)
    return false
  else:
   # Keep corrupt/future-version data for recovery instead of replacing it blindly.
   var archive := path+".invalid-"+str(Time.get_unix_time_from_system()).replace(".","-")
   if DirAccess.copy_absolute(path,archive) != OK:
    last_error = "Cannot preserve invalid save; replacement cancelled."
    return false
 var error := DirAccess.rename_absolute(path+".tmp",path)
 if error != OK:
  last_error = "Cannot replace save: "+error_string(error)
  return false
 last_error = ""
 saved.emit()
 return true

func persist() -> bool:
 var validated := validate_campaign(state)
 if validated.is_empty():
  last_error = "Invalid campaign state; previous save retained."
  return false
 if not _write(PATH,validated):
  return false
 state = validated
 return true

func save_settings() -> bool:
 var validated := validate_settings(settings)
 if validated.is_empty():
  last_error = "Invalid settings; previous settings retained."
  return false
 if not _write(SETTINGS_PATH,{"version":VERSION,"settings":validated}):
  return false
 settings = validated
 return true
