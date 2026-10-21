extends Node
# Explicit visual fixtures inside the real Gameplay/Main scenes. These are native
# viewport captures, not normal campaign progression/balance claims or mockups.
const ASSETS := preload("res://scripts/visual/visual_assets.gd")
var app: Control
var directory := "user://g3-captures"
var failures := 0
var metrics: Array[Dictionary] = []

func check(value: bool, message: String) -> void:
 if not value:
  failures += 1
  push_error(message)

func _ready() -> void:
 run.call_deferred()

func capture(filename: String) -> void:
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var picture := get_viewport().get_texture().get_image()
 check(picture != null and not picture.is_empty(),"Real renderer supplies native pixels")
 if picture != null and not picture.is_empty():
  check(picture.save_png(directory.path_join(filename+".png")) == OK,"Native image saved")
 metrics.append({"capture":filename,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"objects":Performance.get_monitor(Performance.OBJECT_COUNT)})
 print("CAPTURE: "+filename)

func deploy(id: int = 3) -> Node2D:
 app._play(id)
 var battle: Node2D = app.battle
 battle.set_physics_process(false)
 return battle

func annotate(text: String) -> void:
 var old := app.get_node_or_null("CaptureLabel")
 if old != null:
  app.remove_child(old)
  old.queue_free()
 var label := preload("res://scripts/ui/ui_kit.gd").label("VISUAL TEST FIXTURE / "+text,17)
 label.position = Vector2(app.size.x-326,260)
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.size = Vector2(275,110)
 label.z_index = 11 # Keep fixture disclosure above the production HUD.
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 app.add_child(label)
 label.name = "CaptureLabel"

func step(battle: Node2D, seconds: float) -> void:
 for frame in int(ceil(seconds*60)):
  battle.simulate(1.0/60.0)
  if frame%8 == 0:
   await get_tree().process_frame

func run() -> void:
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--output="):
   directory = argument.trim_prefix("--output=")
 if DisplayServer.get_name() == "headless":
  push_error("G3 capture requires a real display/Compatibility renderer")
  get_tree().quit(1)
  return
 DirAccess.make_dir_recursive_absolute(directory)
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 SaveManager.new_campaign()
 SaveManager.state.frontline = 25
 SaveManager.state.highest = 25
 SaveManager.state.unlocks = ["laser","emp_tower","heavy_aa","armor_piercing","explosive"]
 SaveManager.state.ammo_loadout = ["standard","armor_piercing","explosive"]
 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 await get_tree().process_frame
 var battle: Node2D = deploy()
 annotate("9 DISTINCT ENEMY SILHOUETTES")
 var index := 0
 for kind in ["scout","assault","heavy","shield","emp","bomber","sniper","carrier","stealth"]:
  var enemy: Node2D = battle.spawn_enemy(kind)
  enemy.position = Vector2(190+(index%3)*280,225+(index/3)*135)
  if kind == "stealth":
   enemy.brain.tick(3.1) # Actual cloak clock reaches its visible interval.
  enemy.art.advance(.5,1)
  enemy.art.sync(0)
  index += 1
 await capture("drone_catalog")
 # Damage/cloak use real controllers, retaining each unit's original hit rules.
 for enemy in battle.drones.get_children():
  enemy.hit(enemy.maximum_health*.25,true,true,enemy.position)
 battle.simulate(.06)
 await capture("drone_damage")
 for enemy in battle.drones.get_children():
  enemy.hit(enemy.maximum_health*10,true,true,enemy.position)
 battle.view.tick(.36)
 await capture("drone_destruction")
 app.get_node("CaptureLabel").queue_free()
 for kind in ["assault_carrier","emp_warship","border_guardian","factory_ship","hive_core"]:
  battle = deploy(5)
  annotate(str(CampaignManager.enemies[kind].name))
  var enemy: Node2D = battle.spawn_enemy(kind)
  enemy.position = enemy.brain.anchor()
  battle.simulate(.4)
  await capture("boss_"+kind)
  # Force phase thresholds through the real damage API; this is a visual fixture,
  # not an assisted-play victory. Full campaign tests cover earned outcomes.
  if enemy.components != null:
   enemy.components.find("core").receive(enemy.maximum_health*.30,true,true,{})
  else:
   enemy.hit(enemy.maximum_health*.30,true,true,enemy.brain.weakpoint())
  if not enemy.ended:
   await step(battle,.45)
   check(enemy.brain.phase_index == 2,"Boss enters actual third-phase presentation")
   await capture("boss_"+kind+"_phase3")
   enemy.hit(enemy.maximum_health*10,true,true,enemy.brain.weakpoint())
   battle.view.tick(.38)
   await capture("boss_"+kind+"_destroyed")
  app.get_node("CaptureLabel").queue_free()
 battle = deploy()
 annotate("ALL 6 SECONDARY WEAPONS / LEVEL 1")
 battle.credits = 10000 # Explicit shop/art coverage fixture.
 index = 0
 for kind in CampaignManager.turrets:
  battle.select_slot(index)
  check(battle.build_turret(str(kind)),"Build real weapon through battle shop")
  index += 1
 battle.close_build_mode()
 for point in [Vector2(270,205),Vector2(520,260),Vector2(800,240)]:
  var enemy: Node2D = battle.spawn_enemy("heavy")
  enemy.position = point
 await step(battle,.25)
 await capture("arsenal_level1")
 for slot in 6:
  battle.select_slot(slot)
  check(battle.upgrade_selected() and battle.upgrade_selected(),"Actual purchases drive level-three art")
 battle.research_levels.cannon_damage = 5
 battle.research_levels.cannon_rate = 5
 battle.close_build_mode()
 battle.simulate(.12)
 await capture("arsenal_level3")
 app.get_node("CaptureLabel").queue_free()
 battle = deploy()
 annotate("PRIMARY / ACTUAL HULL HITS, HEAT AND RELOAD")
 var boss: Node2D = battle.spawn_enemy("emp_warship")
 boss.position = boss.brain.anchor()
 battle.player_controls.aim_at(boss.position+Vector2(32,0))
 battle.player_controls.set_fire(&"capture",true)
 await step(battle,2.0)
 check(battle.player_turret.shots_fired > 0,"Primary actually fires")
 await capture("primary_standard_heat")
 battle.player_controls.set_fire(&"capture",false)
 for ammo in ["armor_piercing","explosive"]:
  check(battle.player_turret.select_ammunition(ammo),"Real ammunition switch")
  battle.player_controls.set_fire(&"capture",true)
  await step(battle,.65)
  await capture("primary_"+ammo)
  battle.player_controls.set_fire(&"capture",false)
 check(battle.player_turret.request_reload(),"Actual partial reload starts")
 await step(battle,.7)
 check(battle.player_turret.reload_remaining > 0,"Reload is in progress")
 await capture("primary_reload")
 battle.set_paused(true)
 var clock: float = battle.player_turret.get_node("Artwork").art.clock
 battle.simulate(2)
 check(battle.player_turret.get_node("Artwork").art.clock == clock,"Pause freezes mechanics")
 await capture("primary_pause")
 # Exercise a real terminal transaction + skippable boss destruction outro.
 battle = deploy(5)
 annotate("BOSS DESTRUCTION / SAVED RESULT")
 boss = battle.spawn_enemy("assault_carrier")
 boss.position = boss.brain.anchor()
 boss.hit(boss.maximum_health*10,true,true,boss.brain.weakpoint())
 var token: String = battle.run_id
 battle._finish(true)
 await get_tree().process_frame
 check(app.screen == "debrief" and is_instance_valid(app.outro),"Terminal boss destruction presents before results")
 await capture("boss_victory_outro")
 var paid: int = SaveManager.state.credits
 check(not SaveManager.state.last_result.is_empty() and SaveManager.state.active_run.is_empty(),"Campaign result is already persisted during the outro")
 check(CampaignManager.resolve(true,5,token,app.result_data).is_empty() and SaveManager.state.credits == paid,"Outro cannot duplicate rewards")
 var escape := InputEventKey.new()
 escape.keycode = KEY_ESCAPE
 escape.pressed = true
 get_viewport().push_input(escape,true)
 await get_tree().process_frame
 check(app.screen == "results","Skip goes to already-settled results")
 await capture("boss_victory_results")
 app.queue_free()
 await get_tree().process_frame
 var file := FileAccess.open(directory.path_join("render_metrics.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(metrics,"  "))
 print("NATIVE UNIT VISUALS: 14 enemy archetypes, 7 weapons, %d captures, %d failures" % [metrics.size(),failures])
 get_tree().quit(1 if failures else 0)
