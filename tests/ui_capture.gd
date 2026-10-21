extends Node
# Native gameplay UI; progression/funds used for art coverage are explicit fixtures.
const UI := preload("res://scripts/ui/ui_kit.gd")
var app: Control
var directory := "/tmp/frontline-g5-captures"
var failures := 0
var samples: Array[Dictionary] = []
func check(condition: bool, message: String) -> void:
 if not condition:
  failures += 1
  push_error(message)
func _ready() -> void:
 run.call_deferred()
func capture(name: String) -> void:
 await get_tree().process_frame
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var picture := get_viewport().get_texture().get_image()
 check(picture != null and not picture.is_empty(),"Native UI renderer supplies pixels")
 if picture != null and not picture.is_empty():
  check(picture.save_png(directory.path_join(name+".png")) == OK,"Native UI frame saved")
 samples.append({"capture":name,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"size":[get_tree().root.size.x,get_tree().root.size.y]})
 print("CAPTURE: "+name)
func click(button: Button) -> void:
 for held in [true,false]:
  var event := InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = held
  event.position = button.get_global_rect().get_center()
  get_viewport().push_input(event,true)
  await get_tree().process_frame
func run() -> void:
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--output="):
   directory = argument.trim_prefix("--output=")
 if DisplayServer.get_name() == "headless":
  push_error("UI capture requires X11/Wayland and Compatibility renderer")
  get_tree().quit(1)
  return
 DirAccess.make_dir_recursive_absolute(directory)
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 await get_tree().process_frame
 await capture("main_menu_no_save")
 SaveManager.new_campaign()
 app._menu()
 await capture("main_menu_campaign")
 app._map()
 await capture("campaign_outpost")
 var strategic: Control = app.content.get_child(0).strategic
 await click(strategic.nodes[0])
 check(app.screen == "briefing","Actual map mouse click opens mission briefing")
 await capture("mission_briefing")
 # Actual result transaction, staged outcome (not a claimed earned battle win).
 var token := CampaignManager.begin_mission(1)
 var result := CampaignManager.resolve(true,1,token,{"health":900})
 app._map()
 await get_tree().create_timer(.35).timeout
 await capture("campaign_conquest")
 # Checkpoint-bound retreat is a real saved result, with fixture access to mission 6.
 SaveManager.state.frontline = 6
 SaveManager.state.highest = 6
 SaveManager.state.checkpoints = [1,5]
 SaveManager.state.checkpoint = 5
 SaveManager.persist()
 token = CampaignManager.begin_mission(6)
 result = CampaignManager.resolve(false,6,token,{"health":0})
 check(result.to == 5 and SaveManager.state.checkpoint == 5,"Actual retreat respects secured floor")
 app._map()
 await get_tree().create_timer(.35).timeout
 await capture("campaign_counterattack")
 SaveManager.state.frontline = 25
 SaveManager.state.highest = 25
 SaveManager.state.credits = 15000
 SaveManager.persist()
 app._map()
 await capture("campaign_final_offensive")
 app._arsenal()
 await capture("arsenal_primary")
 var arsenal: Control = app.content.get_child(0)
 for tab in ["automatic","research","abilities"]:
  arsenal.select_tab(tab)
  await capture("arsenal_"+tab)
 arsenal.select_tab("primary")
 arsenal.confirm("cannon_damage",0)
 await capture("research_confirmation")
 for child in arsenal.get_children():
  if child is ConfirmationDialog:
   child.confirmed.emit()
 await capture("research_purchased")
 check(EconomyManager.research_level("cannon_damage") == 1,"Real reviewed purchase persists")
 app._settings()
 await capture("settings")
 app._play(1)
 await get_tree().process_frame
 var battle: Node2D = app.battle
 battle.set_physics_process(false)
 for item in [[2,"machine_gun"],[3,"cannon"],[4,"machine_gun"]]:
  battle.select_slot(int(item[0]))
  check(battle.build_turret(str(item[1])),"Actual budget buys demo defense")
 battle.close_build_mode()
 battle.start_wave()
 for frame in 600:
  var target: Node2D = null
  for enemy in battle.drones.get_children():
   if not enemy.ended and enemy.position.distance_to(battle.player_turret.position) < 395:
    target = enemy
    break
  if target != null:
   battle.player_controls.aim_at(target.position)
  battle.player_controls.set_fire(&"capture",target != null)
  battle.simulate(1.0/60)
  await get_tree().process_frame
  if battle.player_turret.shots_fired > 3 and battle.kills > 0:
   break
 check(battle.player_turret.shots_fired > 0 and battle.shots_fired > battle.player_turret.shots_fired,"Actual simultaneous manual/automatic combat runs under new HUD")
 await capture("battle_hud_live")
 battle.select_slot(0)
 await capture("battle_hud_build")
 battle.select_slot(2)
 await capture("battle_hud_upgrade")
 battle.close_build_mode()
 battle.player_controls.set_fire(&"capture",false)
 check(battle.player_turret.request_reload(),"HUD reload reads actual cannon")
 battle.simulate(.3)
 await capture("battle_hud_reload")
 check(battle.abilities.activate("overclock"),"Actual Overclock activates and spends battle credits")
 await capture("battle_hud_overclock")
 check(app.hud.side_panel.size.x <= 302,"Active ability labels keep sidebar compact")
 await click(app.hud.pause_button)
 check(battle.paused and not battle.player_turret.trigger_held,"Native pause click still clears fire")
 await capture("battle_hud_pause")
 battle.set_paused(false)
 for dimensions in [Vector2i(1600,720),Vector2i(1280,600),Vector2i(1024,768)]:
  get_tree().root.size = dimensions
  await get_tree().process_frame
  battle.select_slot(0)
  await capture("battle_build_%dx%d" % [dimensions.x,dimensions.y])
  var viewport := get_viewport().get_visible_rect()
  for control in [app.hud.player_panel.fire_button,app.hud.ability_buttons.repair,app.hud.close_button]:
   check(viewport.encloses(control.get_global_rect()),"Battle controls remain within native viewport %s" % dimensions)
  battle.close_build_mode()
 get_tree().root.size = Vector2i(1280,720)
 # Results use the real transaction; no synthetic reward animation writes saves.
 var run_token: String = battle.run_id
 battle._finish(false)
 await get_tree().process_frame
 await capture("defeat_results")
 check(SaveManager.state.active_run.is_empty() and CampaignManager.resolve(false,1,run_token,{}).is_empty(),"Results cannot pay/settle a run twice")
 app._map()
 await capture("campaign_after_defeat")
 token = CampaignManager.begin_mission(int(SaveManager.state.frontline))
 result = CampaignManager.resolve(true,int(SaveManager.state.frontline),token,{"health":900})
 app._show_results(true,int(result.reward),{"campaign":result,"kills":51,"health":900,"earned":710})
 await capture("victory_results")
 for dimensions in [Vector2i(1600,720),Vector2i(1280,600),Vector2i(1024,768)]:
  get_tree().root.size = dimensions
  app._map()
  await capture("campaign_%dx%d" % [dimensions.x,dimensions.y])
  app._arsenal()
  await capture("arsenal_%dx%d" % [dimensions.x,dimensions.y])
  app._menu()
  await capture("menu_%dx%d" % [dimensions.x,dimensions.y])
 SaveManager.settings.reduced_motion = true
 app._map()
 await capture("campaign_reduced_motion")
 app.queue_free()
 await get_tree().process_frame
 var output := FileAccess.open(directory.path_join("render_metrics.json"),FileAccess.WRITE)
 output.store_string(JSON.stringify(samples,"  "))
 print("NATIVE G5 UI: %d captures, %d failures" % [samples.size(),failures])
 get_tree().quit(1 if failures else 0)
