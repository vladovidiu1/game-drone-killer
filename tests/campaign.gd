extends Node
var checks := 0
var failures := 0
var app: Control

func check(value: bool, message: String) -> void:
 checks += 1
 if value:
  print("PASS: "+message)
 else:
  failures += 1
  push_error("FAIL: "+message)

func _ready() -> void:
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 run.call_deferred()

func find_button(node: Node, text: String) -> Button:
 for child in node.get_children():
  if child is Button and child.text == text:
   return child
  var found := find_button(child,text)
  if found != null:
   return found
 return null

func fight(id: int, defend: bool) -> void:
 app._briefing(id)
 await get_tree().process_frame
 var deploy := find_button(app,"Start Mission")
 check(deploy != null and not deploy.disabled,"mission %d briefing enables Start Mission at the frontline" % id)
 if deploy == null or deploy.disabled:
  return
 deploy.pressed.emit()
 await get_tree().process_frame
 if app.screen != "game" or not is_instance_valid(app.battle):
  check(false,"mission %d can deploy" % id)
  return
 var battle: Node2D = app.battle
 battle.set_physics_process(false)
 check(battle.mission_id == id and battle.slots.size() == id+4 and battle.spawner.waves.size() == id+4,"mission %d loads its own slot and wave configuration" % id)
 if defend:
  for slot in [0,1,2]:
   battle.select_slot(slot)
   battle.build_turret("cannon" if slot == 1 else "machine_gun")
 for frame in 32000:
  if app.screen == "results":
   break
  if defend:
   for slot in range(3,battle.slots.size()):
    if battle.placed[slot] == null:
     battle.select_slot(slot)
     battle.build_turret("missile" if slot == 3 else "cannon")
   for slot in battle.slots.size():
    if battle.placed[slot] != null:
     battle.select_slot(slot)
     battle.upgrade_selected()
   var target: Node2D = null
   for enemy in battle.drones.get_children():
    if not enemy.ended and enemy.position.distance_to(battle.player_turret.position) < 400:
     if target == null or enemy.distance_remaining < target.distance_remaining:
      target = enemy
   if target != null:
    battle.player_controls.aim_at(target.position)
   battle.player_controls.set_fire(&"test",target != null)
  if battle.spawner.intermission:
   battle.start_wave()
  battle.simulate(1.0/60.0)
  await get_tree().process_frame
 check(app.screen == "results" and bool(app.result_data.get("victory",not defend)) == defend,"mission %d completes through real %s combat" % [id,"winning" if defend else "losing"])

func run() -> void:
 if "--verify-campaign" in OS.get_cmdline_user_args():
  check(SaveManager.state.frontline == 4 and SaveManager.state.highest == 4,"fresh process restores frontline and highest reached")
  check(SaveManager.state.damage_level == 1 and SaveManager.state.credits == 630,"fresh process restores permanent upgrade and exact rewards")
  check(SaveManager.state.records["2"].victories == 2,"fresh process retains reconquest mission record")
  check(SaveManager.state.records["3"].victories == 1 and SaveManager.state.records["3"].defeats == 1,"fresh process retains victory and defeat records")
  check(SaveManager.settings.muted and is_equal_approx(float(SaveManager.settings.volume),0.35),"fresh process restores versioned settings")
  finish()
  return
 SaveManager.new_campaign()
 check(SaveManager.state.frontline == 1 and SaveManager.state.highest == 1 and SaveManager.state.checkpoints == [1],"new campaign starts at mission 1 checkpoint")
 check(CampaignManager.can_play(1) and not CampaignManager.can_play(2),"future missions locked at campaign start")
 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 await get_tree().process_frame
 app._briefing(2)
 await get_tree().process_frame
 check(find_button(app,"Start Mission") != null and find_button(app,"Start Mission").disabled,"locked mission briefing cannot deploy")
 for id in [1,2,3]:
  var definition := CampaignManager.mission(id)
  check(not str(definition.location).is_empty() and not str(definition.story).is_empty() and not str(definition.intel).is_empty() and not str(definition.preparation).is_empty(),"mission %d has full briefing intelligence and preparation" % id)
 check(CampaignManager.mission(2).paths.size() == 2,"Red Hill has exactly two approach paths")
 check(CampaignManager.mission(3).paths[1][0][0] < 100 and CampaignManager.mission(3).paths[2][0][0] > 850,"depot includes opposing side approaches")
 await fight(1,true)
 check(SaveManager.state.frontline == 2 and SaveManager.state.highest == 2,"win mission 1 advances to 2")
 check(SaveManager.state.credits == 120 and CampaignManager.territory_state(1) == "CONTROLLED","mission 1 grants reward and controls its territory")
 var old: Dictionary = app.result_data.campaign.duplicate(true)
 var before := SaveManager.state.duplicate(true)
 check(CampaignManager.resolve(true,1,str(old.run_id)).is_empty() and SaveManager.state == before,"duplicate result cannot grant credits or advance twice")
 check(EconomyManager.buy_damage(),"permanent upgrade purchased before further campaigning")
 await fight(2,true)
 check(SaveManager.state.frontline == 3 and SaveManager.state.highest == 3,"win mission 2 advances to 3")
 check(SaveManager.state.credits == 200,"mission 2 grants its configured reward")
 await fight(3,false)
 check(SaveManager.state.frontline == 2 and SaveManager.state.highest == 3,"lose mission 3 retreats to 2 while keeping highest reached")
 check(CampaignManager.territory_state(2) == "CONTESTED FRONTLINE" and not CampaignManager.can_play(3),"previous territory becomes contested and lost advance is locked")
 check(SaveManager.state.credits == 200 and SaveManager.state.damage_level == 1,"defeat grants no rewards and preserves permanent progression")
 check(str(SaveManager.state.last_result.message).contains("Red Hill Village"),"retreat feedback names the lost territory")
 SaveManager.reload_from_disk()
 check(SaveManager.state.frontline == 2 and SaveManager.state.highest == 3,"save reload retains requested retreat position")
 app._briefing(2)
 await get_tree().process_frame
 check(not find_button(app,"Start Mission").disabled,"returned frontline briefing allows reconquest")
 await fight(2,true)
 check(SaveManager.state.frontline == 3 and SaveManager.state.credits == 380,"winning mission 2 again reconquers and rewards once")
 check(SaveManager.state.records["2"].victories == 2,"completed mission record retains both legitimate victories")
 SaveManager.reload_from_disk()
 check(SaveManager.state.frontline == 3 and CampaignManager.can_play(3),"reloaded reconquest unlocks mission 3 again")
 await fight(3,true)
 check(SaveManager.state.frontline == 4 and SaveManager.state.highest == 4,"all three playable missions link to mission 4 development frontier")
 check(SaveManager.state.credits == 630 and SaveManager.state.records["3"].best_health > 0,"depot victory grants reward and records best base health")
 check(not CampaignManager.can_play(4) and CampaignManager.can_play(1) and CampaignManager.can_play(3),"future content stays unavailable while controlled missions are replayable")
 var message: String = SaveManager.state.last_result.message
 app._map()
 await get_tree().process_frame
 check(app.screen == "map" and message.contains("East Supply Depot"),"results transition back to campaign with territory feedback")
 SaveManager.settings.volume = 0.35
 SaveManager.settings.muted = true
 check(SaveManager.save_settings(),"versioned settings saved independently of campaign")
 finish()

func finish() -> void:
 if is_instance_valid(app):
  app.queue_free()
 await get_tree().process_frame
 print("CAMPAIGN: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
