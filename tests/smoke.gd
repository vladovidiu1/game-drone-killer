extends Node
var failures := 0
var checks := 0
var app: Control

func check(condition: bool, description: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error("FAIL: " + description)
 else:
  print("PASS: " + description)

func buttons(node: Node) -> Array[Button]:
 var result: Array[Button] = []
 for child in node.get_children():
  if child is Button:
   result.append(child)
  result.append_array(buttons(child))
 return result

func _ready() -> void:
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 run.call_deferred()

func run() -> void:
 if "--verify-save" in OS.get_cmdline_user_args():
  check(SaveManager.has_campaign(), "campaign restored in a fresh process")
  check(int(SaveManager.state.damage_level) == 1, "permanent upgrade restored")
  check(int(SaveManager.state.frontline) == 1, "retreat persisted")
  check(int(SaveManager.state.credits) == int(SaveManager.state.records["1"].get("star_claims",[]).reduce(func(total: int, tier: int): return total+int(preload("res://scripts/core/economy_config.gd").values.war.star_milestones[str(tier)]),0)), "earned one-time star economy persisted")
  finish()
  return
 SaveManager.new_campaign()
 check(CampaignManager.missions.size() == 25, "25 mission definitions retained")
 check(CampaignManager.mission(25).chapter == 4, "five campaign chapters")
 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 await get_tree().process_frame
 check(app.screen == "menu", "main scene starts on menu")
 var found_continue := false
 for button in buttons(app):
  if button.text == "Continue Campaign":
   found_continue = true
   check(not button.disabled, "Continue enabled for an existing save")
 check(found_continue, "Continue button exists")
 var current_campaign := SaveManager.state.duplicate(true)
 SaveManager.state = {}
 app._menu()
 var no_save_disabled := false
 for button in buttons(app):
  if button.text == "Continue Campaign":
   no_save_disabled = button.disabled
 check(no_save_disabled, "Continue disabled without a campaign")
 SaveManager.state = current_campaign
 app._map()
 await get_tree().process_frame
 check(app.content.get_child(0).strategic.nodes.size() == 25 and buttons(app).filter(func(button: Button): return button.text in ["Main menu","Arsenal"]).size() == 2, "25 interactive map nodes and working navigation remain alongside optional ads")
 app._briefing(25)
 await get_tree().process_frame
 check(buttons(app).size() == 2 and buttons(app)[0].disabled, "future mission is playable content but remains frontline-locked")
 app._settings()
 await get_tree().process_frame
 check(app.screen == "settings", "settings screen opens")
 app._arsenal()
 await get_tree().process_frame
 check(app.screen == "arsenal", "Arsenal opens")
 app._play()
 await get_tree().process_frame
 app.battle.set_physics_process(false)
 var visible := get_viewport().get_visible_rect()
 var build_rect: Rect2 = app.hud.side_panel.get_global_rect()
 check(visible.encloses(build_rect), "build controls fit the 1280x720 reference viewport")
 check(app.hud.get_child(1).get_child(1).get_global_rect().position.x > 814, "build sidebar leaves turret slots unobstructed")
 check(app.battle.health == 1000, "mission starts with 1000 base HP")
 check(app.battle.credits == 500 and app.battle.turrets.get_child_count() == 0, "deployment begins with build budget and empty slots")
 var mouse := InputEventMouseButton.new()
 mouse.button_index = MOUSE_BUTTON_LEFT
 mouse.position = app.battle.get_global_transform_with_canvas()*app.battle.slots[0]
 mouse.pressed = true
 get_viewport().push_input(mouse,true)
 await get_tree().process_frame
 check(app.battle.selected_slot == 0, "mouse selects turret slot through gameplay HUD")
 mouse.pressed = false
 get_viewport().push_input(mouse,true)
 await get_tree().process_frame
 var build: Button = app.hud.build_buttons.machine_gun
 check(not build.disabled, "selected slot exposes affordable build option")
 build.pressed.emit()
 check(app.battle.placed[0] != null and app.battle.credits == 400, "build button places a Machine Gun")
 var touch := InputEventScreenTouch.new()
 touch.index = 2
 touch.pressed = true
 touch.position = app.battle.get_global_transform_with_canvas()*app.battle.slots[1]
 get_viewport().push_input(touch,true)
 await get_tree().process_frame
 check(app.battle.selected_slot == 1, "touch selects another slot")
 app.hud.shop_scroll.ensure_control_visible(app.hud.build_buttons.cannon)
 await get_tree().process_frame
 # Keep one finger on the slot while a second finger presses a build control.
 var build_touch := InputEventScreenTouch.new()
 build_touch.index = 3
 build_touch.pressed = true
 build_touch.position = app.hud.build_buttons.cannon.get_global_rect().get_center()
 get_viewport().push_input(build_touch,true)
 await get_tree().process_frame
 build_touch.pressed = false
 get_viewport().push_input(build_touch,true)
 await get_tree().process_frame
 touch.pressed = false
 get_viewport().push_input(touch,true)
 await get_tree().process_frame
 check(app.battle.placed[1] != null and app.battle.credits == 200, "independent second finger builds Cannon through native touch button")
 app.battle.select_slot(2)
 app.hud.build_buttons.machine_gun.pressed.emit()
 app.hud.upgrade_button.pressed.emit()
 check(app.battle.placed[2].level == 2, "HUD upgrades selected turret")
 app.hud.pause_button.pressed.emit()
 var old_timer: float = app.battle.spawner.timer
 app.battle.simulate(1)
 check(app.battle.paused and app.battle.spawner.timer == old_timer, "pause button freezes simulation")
 app.hud.pause_button.pressed.emit()
 check(app.battle.effective_speed() == 1 and not app.battle.has_method("toggle_speed"), "pause/resume restores normal speed with no selector")
 check(app.hud.wave_button.disabled, "radar preparation prevents instant launch")
 app.battle.spawner.tick(6,0)
 app.hud.refresh()
 app.hud.wave_button.pressed.emit()
 check(not app.battle.spawner.intermission, "HUD starts wave early")
 for frame in 20000:
  if app.screen == "results":
   break
  if not is_instance_valid(app.battle):
   break
  var battle: Node2D = app.battle
  # Legitimate build/upgrade strategy using only earned battle credits.
  for slot in [3,4]:
   if battle.placed[slot] == null:
    battle.select_slot(slot)
    battle.build_turret("cannon" if slot == 3 else "machine_gun")
  for slot in [0,1,2,3,4]:
   if battle.placed[slot] != null:
    battle.select_slot(slot)
    battle.upgrade_selected()
  if battle.spawner.intermission:
   battle.start_wave()
  battle.close_build_mode()
  preload("res://tests/m1_pilot.gd").aim(battle)
  battle._physics_process(1.0/60.0)
  await get_tree().process_frame
 check(app.screen == "results" and bool(app.result_data.get("victory",false)), "hybrid defenses win full five-wave mission without direct damage injection")
 check(int(app.result_data.get("shots",0)) > 0 and int(app.result_data.get("kills",0)) > 0, "turrets fire and destroy enemies during real battle")
 check(int(app.result_data.get("waves",0)) == 5, "victory follows all five mission waves")
 check(int(SaveManager.state.frontline) == 2, "victory advances frontline")
 var star_bonus: int = app.result_data.campaign.star_reward
 check(int(SaveManager.state.credits) == 100+star_bonus, "victory saves base reward plus earned star milestones separately from BC")
 check(EconomyManager.buy_damage(), "permanent upgrade purchase succeeds")
 check(int(SaveManager.state.credits) == star_bonus, "permanent upgrade still costs exactly 100 credits")
 check(not EconomyManager.buy_damage(), "insufficient campaign credits rejected")
 app._play(2)
 await get_tree().process_frame
 app.battle.set_physics_process(false)
 check(app.battle.health == 1000 and app.battle.credits == 550 and app.battle.kills == 0, "restart resets health, budget and kills")
 check(app.battle.turrets.get_child_count() == 0 and app.battle.projectiles.get_child_count() == 0 and app.battle.effective_speed() == 1, "restart resets placements, projectiles and speed")
 for frame in 20000:
  if app.screen == "results":
   break
  if app.battle.spawner.intermission:
   app.battle.start_wave()
  app.battle.simulate(1.0/60.0)
  await get_tree().process_frame
 check(app.screen == "results" and not bool(app.result_data.get("victory",true)), "unattended battle reaches defeat through natural breaches")
 check(int(app.result_data.get("health",-1)) == 0, "base destroyed at zero HP")
 var has_retry := false
 for button in buttons(app):
  if button.text == "Retry Outpost Alpha":
   has_retry = true
 check(has_retry, "defeat screen provides retry")
 check(int(SaveManager.state.frontline) == 1, "defeat retreats frontline")
 check(int(SaveManager.state.damage_level) == 1, "permanent upgrade survives defeat")
 check(int(SaveManager.state.credits) == star_bonus, "defeat preserves prior star income and grants no new reward")
 check(SaveManager.last_error.is_empty(), "save writes succeeded")
 var snapshot := SaveManager.state.duplicate(true)
 SaveManager.state.frontline = 6
 SaveManager.state.highest = 6
 SaveManager.state.checkpoint = 5
 SaveManager.state.checkpoints = [1,5]
 CampaignManager.missions[5].playable = true
 var checkpoint_run := CampaignManager.begin_mission(6)
 CampaignManager.resolve(false,6,checkpoint_run)
 check(int(SaveManager.state.frontline) == 5, "retreat stops at the completed mission checkpoint")
 CampaignManager.missions[5].playable = false
 SaveManager.state = snapshot.duplicate(true)
 SaveManager.state.frontline = 2
 SaveManager.state.highest = 2
 var replay_run := CampaignManager.begin_mission(1)
 CampaignManager.resolve(true,1,replay_run)
 check(int(SaveManager.state.frontline) == 2, "replaying Outpost cannot advance beyond mission 2")
 SaveManager.state = snapshot.duplicate(true)
 SaveManager.persist()
 finish()

func finish() -> void:
 AudioManager.player.stop()
 AudioManager.player.stream = null
 print("SMOKE: %d checks, %d failures" % [checks, failures])
 if is_instance_valid(app):
  app.queue_free()
 await get_tree().process_frame
 get_tree().quit(1 if failures else 0)
