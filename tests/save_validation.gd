extends Node
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
 checks += 1
 if value:
  print("PASS: "+message)
 else:
  failures += 1
  push_error("FAIL: "+message)

func raw_write(path: String, text: String) -> void:
 var file := FileAccess.open(path,FileAccess.WRITE)
 file.store_string(text)
 file.close()

func apply(victory: bool, id: int) -> Dictionary:
 var token := CampaignManager.begin_mission(id)
 return CampaignManager.resolve(victory,id,token,{"health":500})

func _ready() -> void:
 run.call_deferred()

func run() -> void:
 for path in [SaveManager.PATH,SaveManager.PATH+".bak",SaveManager.SETTINGS_PATH,SaveManager.SETTINGS_PATH+".bak"]:
  if FileAccess.file_exists(path):
   DirAccess.remove_absolute(path)
 SaveManager.reload_from_disk()
 check(not SaveManager.has_campaign() and SaveManager.settings == SaveManager.DEFAULT_SETTINGS,"missing files recover to no campaign and default settings")
 for value in [null,[],"text",{"version":99,"frontline":1},{"version":2.5,"frontline":1},{"version":2,"frontline":"three"}]:
  check(SaveManager.validate_campaign(value).is_empty(),"unsupported or malformed campaign shape rejected: "+str(value))
 var legacy := {"version":1,"frontline":6,"checkpoint":6,"credits":345,"damage_level":3,"wins":5}
 var migrated := SaveManager.validate_campaign(legacy)
 check(migrated.version == 3 and migrated.checkpoint == 5 and migrated.checkpoints == [1,5],"legacy chapter-start checkpoint migrates to completed mission floor")
 check(migrated.credits == 345 and migrated.damage_level == 3 and migrated.highest == 6,"migration retains existing credits, upgrades and reached frontline")
 raw_write(SaveManager.PATH,JSON.stringify(legacy))
 SaveManager.reload_from_disk()
 check(SaveManager.state.version == 3 and SaveManager.persist(),"legacy file migrates and is saved in current schema")
 var malformed := SaveManager.fresh_state()
 malformed.frontline = 2
 malformed.highest = 3
 malformed.credits = "invalid"
 malformed.damage_level = 500
 malformed.checkpoints = [null,"5",5,20,-1,{},1]
 malformed.records = {"2":{"victories":"bad","defeats":-20,"best_health":null},"99":{"victories":5}}
 malformed.active_run = {"id":123,"mission_id":2}
 var sanitized := SaveManager.validate_campaign(malformed)
 check(sanitized.credits == 0 and sanitized.damage_level == 5,"wrong value types default safely and upgrades are bounded")
 check(sanitized.checkpoints == [1] and sanitized.frontline == 2,"unreached or malformed checkpoint values cannot unlock territory")
 check(sanitized.records["2"].victories == 0 and not sanitized.records.has("99") and sanitized.active_run.is_empty(),"malformed records and active runs sanitized")
 check(SaveManager.validate_settings({"volume":2,"muted":"true"}).volume == 1 and not SaveManager.validate_settings({"volume":2,"muted":"true"}).muted,"settings ranges and boolean types validated")
 check(SaveManager.validate_settings({"version":99,"settings":{}}).is_empty(),"future settings schema rejected")
 raw_write(SaveManager.SETTINGS_PATH,JSON.stringify({"volume":0.4,"muted":true}))
 SaveManager.reload_from_disk()
 check(SaveManager.settings.muted and is_equal_approx(float(SaveManager.settings.volume),0.4),"legacy settings migrate without resetting preferences")
 check(SaveManager.save_settings(),"migrated settings can be persisted")
 SaveManager.new_campaign()
 SaveManager.state.credits = 333
 SaveManager.state.damage_level = 2
 SaveManager.persist()
 SaveManager.persist()
 raw_write(SaveManager.PATH,"{broken JSON")
 SaveManager.reload_from_disk()
 check(SaveManager.state.credits == 333 and SaveManager.state.damage_level == 2 and not SaveManager.recovery_notice.is_empty(),"corrupt primary recovers last known-good backup with progression intact")
 check(SaveManager.persist() and SaveManager.last_error.is_empty(),"recovered campaign can be saved while preserving corrupt original")
 raw_write(SaveManager.PATH,"[]")
 raw_write(SaveManager.PATH+".bak","null")
 SaveManager.reload_from_disk()
 check(not SaveManager.has_campaign(),"two invalid saves safely disable Continue instead of crashing")
 SaveManager.new_campaign()
 check(SaveManager.state.frontline == 1 and SaveManager.state.credits == 0,"new campaign works after invalid-data recovery")
 SaveManager.settings.volume = 0.2
 SaveManager.save_settings()
 SaveManager.save_settings()
 raw_write(SaveManager.SETTINGS_PATH,"{bad")
 SaveManager.reload_from_disk()
 check(is_equal_approx(float(SaveManager.settings.volume),0.2),"settings corruption also recovers its backup")
 # Synthetic transaction fixtures complement the full 25-mission real-combat suite.
 SaveManager.new_campaign()
 SaveManager.state.damage_level = 2
 SaveManager.state.credits = 500
 SaveManager.persist()
 for id in range(1,6):
  apply(true,id)
 check(SaveManager.state.frontline == 6 and SaveManager.state.checkpoint == 5 and SaveManager.state.checkpoints == [1,5],"win mission 5 secures floor 5 and advances to 6")
 var credits: int = SaveManager.state.credits
 apply(false,6)
 check(SaveManager.state.frontline == 5 and SaveManager.state.credits == credits,"lose mission 6 retreats to checkpoint 5 with no reward")
 apply(false,5)
 check(SaveManager.state.frontline == 5 and SaveManager.state.damage_level == 2,"losing at checkpoint 5 cannot retreat to 4 or remove upgrades")
 SaveManager.reload_from_disk()
 check(SaveManager.state.frontline == 5 and SaveManager.state.checkpoints == [1,5],"checkpoint floor survives disk reload")
 for id in range(5,21):
  apply(true,id)
 check(SaveManager.state.checkpoints == [1,5,10,15,20] and SaveManager.state.checkpoint == 20 and SaveManager.state.frontline == 21,"all four chapter checkpoints secure at completed mission indices")
 apply(false,21)
 apply(false,20)
 check(SaveManager.state.frontline == 20 and SaveManager.state.highest == 21,"latest checkpoint and highest survive repeated defeat")
 var token := CampaignManager.begin_mission(20)
 check(CampaignManager.resolve(true,19,token).is_empty(),"mismatched mission result cannot settle an active attempt")
 var outcome := CampaignManager.resolve(true,20,token)
 var snapshot := SaveManager.state.duplicate(true)
 SaveManager.reload_from_disk()
 check(not outcome.is_empty() and CampaignManager.resolve(true,20,token).is_empty() and SaveManager.state == snapshot,"duplicate reward remains blocked after restarting from disk")
 var current := CampaignManager.begin_mission(20)
 check(CampaignManager.resolve(false,20,token).is_empty() and SaveManager.state.active_run.id == current,"stale result cannot consume a newer deployment")
 check(not CampaignManager.resolve(false,20,current).is_empty() and SaveManager.state.frontline == 20,"replay defeat obeys the same checkpoint-bounded retreat rule")
 # A directory at the temporary-file path simulates a real write failure.
 var retry_token := CampaignManager.begin_mission(20)
 var retained := SaveManager.state.duplicate(true)
 check(DirAccess.make_dir_absolute(SaveManager.PATH+".tmp") == OK,"write-failure fixture created in isolated user data")
 check(not SaveManager.new_campaign() and SaveManager.state == retained,"failed new-campaign write retains the old campaign")
 check(not EconomyManager.buy_damage() and SaveManager.state == retained,"failed upgrade write rolls back credits and permanent upgrade")
 check(CampaignManager.begin_mission(20).is_empty() and SaveManager.state == retained,"failed deployment write cannot replace active attempt")
 check(CampaignManager.resolve(true,20,retry_token).is_empty() and SaveManager.state == retained,"failed result write rolls back progression and leaves attempt retryable")
 DirAccess.remove_absolute(SaveManager.PATH+".tmp")
 check(not CampaignManager.resolve(true,20,retry_token).is_empty() and SaveManager.last_error.is_empty(),"retrying after write recovery completes the original result once")
 SaveManager.new_campaign()
 print("SAVE/RULES: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
