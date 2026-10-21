extends Node
# Comparison fixtures use chapter-tier research, ordinary battle funds and real combat.
# No assertions of human difficulty; output records wins AND losses.
const PILOT := preload("res://tests/m1_pilot.gd")
var rows: Array[Dictionary] = []
var directory := "/tmp/frontline-m1"
var failures := 0
func _ready() -> void:
 run.call_deferred()
func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--output="):
   directory = arg.trim_prefix("--output=")
 DirAccess.make_dir_recursive_absolute(directory)
 for id in range(1,26):
  var strategies: Array = ["two_mixed"]
  if id in [1,5,10,15,20,25]:
   strategies = ["two_mg","two_cannon","two_mixed","automatic","manual_only","hybrid"]
  for strategy in strategies:
   SaveManager.new_campaign()
   SaveManager.state.frontline = id
   SaveManager.state.highest = id
   SaveManager.state.unlocks = ["armor_piercing","explosive","laser","emp_tower","heavy_aa"] if id >= 6 else []
   SaveManager.state.ammo_loadout = ["standard","armor_piercing","explosive"] if id >= 6 else ["standard"]
   SaveManager.state.equipped_ammo = "armor_piercing" if id >= 6 else "standard"
   var tier := mini(5,id/5)
   for key in SaveManager.state.research:
    SaveManager.state.research[key] = tier
   var battle := preload("res://scenes/gameplay.tscn").instantiate()
   battle.mission_id = id
   add_child(battle)
   battle.set_physics_process(false)
   battle.player_turret.rng.seed = 1000+id
   var peak := 0
   var breached := 0
   battle.drones.child_entered_tree.connect(func(enemy: Node): enemy.breached.connect(func(_damage: int): battle.set_meta("breaches",int(battle.get_meta("breaches",0))+1)))
   for frame in range(60*600):
    if battle.finished:
     break
    if frame%60 == 0:
     if strategy != "manual_only":
      PILOT.build(battle,strategy)
     if strategy in ["hybrid","automatic","manual_only"] and battle.health < battle.max_health-250:
      battle.abilities.activate("repair")
    if strategy in ["hybrid","manual_only"]:
     PILOT.aim(battle)
    battle.simulate(1.0/60.0)
    peak = maxi(peak,battle.living_count())
    if frame%32 == 0:
     await get_tree().process_frame
   breached = int(battle.get_meta("breaches",0))
   if not battle.finished:
    failures += 1
   var row := {"id":id,"strategy":strategy,"seed":1000+id,"research_tier":tier,"victory":battle.finished and battle.health > 0,"finished":battle.finished,"seconds":snappedf(battle.elapsed,.1),"health":battle.health,"kills":battle.kills,"breaches":breached,"peak_enemies":peak,"credits":battle.credits,"earned":battle.earned,"manual_shots":battle.player_turret.shots_fired,"manual_hits":battle.player_turret.hits,"weakpoint_hits":battle.weakpoint_hits,"enemy_actions":battle.enemy_actions,"turrets":battle.turrets.get_child_count()}
   rows.append(row)
   print("M1: "+JSON.stringify(row))
   battle.queue_free()
   await get_tree().process_frame
 var file := FileAccess.open(directory.path_join("balance.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"fixture":"chapter-tier research; normal funds; deterministic input policy; dt 1/60; repairs for full automatic/hybrid/manual only; two-turret cases no abilities; slots 2 and 3; no early starts","rows":rows,"failures":failures},"  "))
 print("M1 BALANCE: %d simulations, %d unfinished" % [rows.size(),failures])
 get_tree().quit(1 if failures else 0)
