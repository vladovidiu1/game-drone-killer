extends Node
# Synthetic campaign accounting fixtures + real battle purchase/reward lifecycle.
# Connected full_campaign.gd separately verifies earned-budget combat reachability.
const CONFIG := preload("res://scripts/core/economy_config.gd")
var checks := 0
var failures := 0
var report: Dictionary = {"scenarios":[]}

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("FAIL: "+message)

func victory(id: int) -> Dictionary:
 var token := CampaignManager.begin_mission(id)
 check(not token.is_empty(),"valid deployment %d" % id)
 var result := CampaignManager.resolve(true,id,token,{"health":900})
 check(not result.is_empty(),"accounting fixture resolves %d" % id)
 var saved := SaveManager.state.duplicate(true)
 check(CampaignManager.resolve(true,id,token).is_empty() and SaveManager.state == saved,"duplicate victory inert %d" % id)
 SaveManager.reload_from_disk()
 check(CampaignManager.resolve(true,id,token).is_empty() and SaveManager.state == saved,"disk reload cannot re-award %d" % id)
 return result

func _ready() -> void:
 run.call_deferred()

func run() -> void:
 if "--verify-economy" in OS.get_cmdline_user_args():
  check(SaveManager.state.credits == 343 and SaveManager.state.research.cannon_damage == 1,"fresh process preserves earnings, purchases and replay ledger")
  check(EconomyManager.victory_quote(1).reward == 15 and EconomyManager.victory_quote(2).reward == 18,"fresh process cannot reclassify replays as first clears")
  check(CampaignManager.resolve(true,2,str(SaveManager.state.last_result.run_id)).is_empty(),"fresh-process duplicate callback blocked")
  finish()
  return
 var raw_definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/definitions.json"))
 var raw_progression: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/progression.json"))
 for mission in raw_definitions.missions:
  check(not mission.has("reward") and not mission.has("starting_credits"),"no duplicate mission economy authority")
 for id in CampaignManager.enemies:
  check(int(CampaignManager.enemies[id].reward) > 0 and not raw_definitions.enemies[id].has("reward"),"central positive bounty "+id)
 for id in SaveManager.catalog.upgrades:
  var costs: Array = SaveManager.catalog.upgrades[id].costs
  for i in costs.size():
   check(int(costs[i]) > 0 and (i == 0 or int(costs[i]) > int(costs[i-1])),"strict positive cost curve "+id)
  check(not raw_progression.upgrades[id].has("costs"),"one price authority "+id)
 SaveManager.new_campaign()
 check(EconomyManager.victory_quote(1).reward == 100 and EconomyManager.victory_quote(2).reward == 120 and EconomyManager.victory_quote(3).reward == 140,"first three first-clear quotes")
 # Real temporary economy: no WC conversion or restart salvage.
 var battle := preload("res://scenes/gameplay.tscn").instantiate()
 add_child(battle)
 battle.set_physics_process(false)
 battle.spawner.timer = 10000
 check(battle.credits == 500,"no-upgrade beginner retains viable 500 BC opening")
 battle.select_slot(0)
 check(battle.build_turret("machine_gun"),"opening machine gun affordable")
 battle.select_slot(1)
 check(battle.build_turret("cannon"),"opening cannon affordable")
 battle.select_slot(2)
 check(not battle.build_turret("missile") and battle.credits == 200,"opening cannot buy all three designs")
 battle.credits = 0
 check(not battle.build_turret("machine_gun") and not battle.abilities.activate("repair") and battle.credits == 0,"BC never goes negative from failed purchase")
 var enemy: Node2D = battle.spawn_enemy("scout")
 enemy.hit(10000)
 var payout: int = battle.credits
 # Repeat both damage and callback before deferred destruction.
 enemy.hit(10000)
 battle._destroyed(int(enemy.reward),enemy)
 check(payout == 7 and battle.credits == 7 and battle.kills == 1,"one bounty per actor even on repeated callback")
 check(SaveManager.state.credits == 0,"BC never becomes persistent WC")
 battle.queue_free()
 await get_tree().process_frame
 battle = preload("res://scenes/gameplay.tscn").instantiate()
 add_child(battle)
 battle.set_physics_process(false)
 check(battle.credits == 500 and battle.earned == 0 and battle.kills == 0,"restart replaces temporary economy; no bounty carryover")
 battle.queue_free()
 await get_tree().process_frame
 # Complete accounting-only campaign; no injected money, no ads, no purchases.
 var total := 0
 for id in range(1,26):
  var result := victory(id)
  check(result.mission_reward == 100+20*(id-1),"gradual first-clear progression %d" % id)
  total += int(result.reward)
 check(total == 8640 and SaveManager.state.credits == 8640,"25 first clears + two once-only objectives = 8640 WC")
 report.scenarios.append({"name":"unspent no-ad accounting campaign","first_clear_and_objective_income":total,"injected_currency":0,"combat":"separate full-campaign suite"})
 var before: int = SaveManager.state.credits
 for i in 8:
  var replay := victory(1)
  check(replay.mission_reward == 15 and replay.objective_reward == 0,"replays never restore first-clear or claimed objectives")
 check(SaveManager.state.credits == before+120,"eight full replay victories earn 120, not 800")
 report.scenarios.append({"name":"eight completed mission-1 replays","income":120})
 # Loss streaks cannot charge entry fees, remove purchases or reward abandoned runs.
 check(EconomyManager.purchase("cannon_damage",0) and EconomyManager.purchase("base_health",0),"earned balance buys moderate progression")
 before = int(SaveManager.state.credits)
 var research: Dictionary = SaveManager.state.research.duplicate(true)
 var previous_run := CampaignManager.begin_mission(25)
 var replacement := CampaignManager.begin_mission(25)
 check(CampaignManager.resolve(true,25,previous_run).is_empty(),"restarting invalidates abandoned deployment token")
 check(SaveManager.state.credits == before,"restarting awards no money")
 CampaignManager.resolve(false,25,replacement)
 for i in 8:
  var id := int(SaveManager.state.frontline)
  CampaignManager.resolve(false,id,CampaignManager.begin_mission(id))
  SaveManager.reload_from_disk()
 check(SaveManager.state.frontline == 20 and SaveManager.state.credits == before and SaveManager.state.research == research,"nine defeats respect floor and retain moderate research and bank")
 report.scenarios.append({"name":"nine defeats with purchased upgrades","war_loss":0,"floor":20,"research_retained":true})
 # Legacy records and implicit old frontline both identify previously cleared land.
 var legacy := SaveManager.validate_campaign({"version":2,"frontline":3,"highest":4,"credits":12345,"damage_level":4,"records":{"2":{"victories":1}},"unlocks":["armor_piercing"],"research":{"magazine":3}})
 SaveManager.state = legacy
 check(EconomyManager.victory_quote(2).reward == 18 and EconomyManager.victory_quote(1).reward == 15 and EconomyManager.victory_quote(3).reward == 21,"legacy explicit and implicit clear history cannot gain another first reward")
 check(SaveManager.state.credits == 12345 and SaveManager.state.damage_level == 4 and SaveManager.state.research.magazine == 3 and EconomyManager.unlocked("armor_piercing"),"repricing preserves legacy bank, upgrades and unlocks")
 check(SaveManager.validate_campaign({"version":3,"frontline":1,"credits":-100}).credits == 0,"negative saved balance clamps to zero")
 # Outcome write failure must roll back reward, first-clear ledger, token and territory.
 SaveManager.new_campaign()
 var token := CampaignManager.begin_mission(1)
 var snapshot := SaveManager.state.duplicate(true)
 DirAccess.make_dir_absolute(SaveManager.PATH+".tmp")
 check(CampaignManager.resolve(true,1,token).is_empty() and SaveManager.state == snapshot,"failed outcome write rolls back the entire reward transaction")
 DirAccess.remove_absolute(SaveManager.PATH+".tmp")
 check(CampaignManager.resolve(true,1,token).mission_reward == 100,"same token may retry a failed write exactly once")
 SaveManager.reload_from_disk()
 check(SaveManager.state.credits == 100 and EconomyManager.victory_quote(1).reward == 15,"successful retry has durable first-clear ledger")
 # Final durable moderate-budget scenario, loaded in an independent process next.
 SaveManager.new_campaign()
 victory(1)
 check(EconomyManager.purchase("cannon_damage",0) and SaveManager.state.credits == 40,"new player can afford one early upgrade after first win")
 check(not EconomyManager.purchase("armor_piercing",0) and SaveManager.state.credits == 40,"cannot buy advanced unlock with insufficient funds")
 victory(2)
 var bank: int = SaveManager.state.credits
 for i in 3:
  var id := int(SaveManager.state.frontline)
  CampaignManager.resolve(false,id,CampaignManager.begin_mission(id))
 check(SaveManager.state.credits == bank and SaveManager.state.research.cannon_damage == 1,"early defeat streak has no economic death spiral")
 victory(1) # Replay, restores frontier to 2.
 victory(2) # Replay, restores frontier to 3.
 victory(3) # First clear.
 check(SaveManager.state.credits == 393,"loss/reconquest accounting includes only reduced replay income")
 # Leave an exact known bank while retaining first-clear history for fresh-process check.
 check(EconomyManager.purchase("velocity",0),"earned reconquest bank affords another optional upgrade")
 check(SaveManager.state.credits == 343,"second research debits its configured price")
 SaveManager.persist()
 report.checks = checks
 report.failures = failures
 var file := FileAccess.open("user://economy_scenarios.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "))
 finish()

func finish() -> void:
 print("ECONOMY: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
