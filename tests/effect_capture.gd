extends Node
# Staged scenarios in real Gameplay/Main scenes; direct spawns/damage and fixture
# funds are explicitly labeled. Normal-budget combat is captured separately.
const UI := preload("res://scripts/ui/ui_kit.gd")
var app: Control
var directory := "/tmp/frontline-g4-captures"
var failures := 0
var metrics: Array[Dictionary] = []
func check(value: bool, message: String) -> void:
 if not value:
  failures += 1
  push_error(message)
func _ready() -> void:
 run.call_deferred()
func annotate(text: String) -> void:
 var old := app.get_node_or_null("CaptureLabel")
 if old != null:
  app.remove_child(old)
  old.queue_free()
 var label := UI.label("VFX TEST FIXTURE / "+text,17)
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.position = Vector2(954,260)
 label.size = Vector2(275,150)
 label.z_index = 11 # Keep fixture disclosure above the production HUD.
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 app.add_child(label)
 label.name = "CaptureLabel"
func deploy() -> Node2D:
 app._play(3)
 var battle: Node2D = app.battle
 battle.set_physics_process(false)
 return battle
func step(battle: Node2D, seconds: float) -> void:
 for frame in int(ceil(seconds*60)):
  battle.simulate(1.0/60)
  await get_tree().process_frame
func capture(filename: String) -> void:
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var picture := get_viewport().get_texture().get_image()
 check(picture != null and not picture.is_empty(),"Native viewport supplies real pixels")
 if picture != null and not picture.is_empty():
  check(picture.save_png(directory.path_join(filename+".png")) == OK,"Save native capture")
 var fx: Node2D = app.battle.view.combat_fx if is_instance_valid(app.battle) else null
 metrics.append({"capture":filename,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"active_particles":fx.active.size() if fx != null else 0,"peak_particles":fx.peak if fx != null else 0,"dropped_emissions":fx.dropped if fx != null else 0,"smoke":fx.count_kind("smoke") if fx != null else 0,"debris":fx.count_kind("debris") if fx != null else 0,"lights":fx.count_kind("light") if fx != null else 0})
 print("CAPTURE: "+filename)
func run() -> void:
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--output="):
   directory = argument.trim_prefix("--output=")
 if DisplayServer.get_name() == "headless":
  push_error("VFX capture requires a real display and Compatibility renderer")
  get_tree().quit(1)
  return
 DirAccess.make_dir_recursive_absolute(directory)
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 SaveManager.new_campaign()
 SaveManager.state.frontline = 25
 SaveManager.state.highest = 25
 SaveManager.state.unlocks = ["laser","emp_tower","heavy_aa","armor_piercing","explosive"]
 SaveManager.settings.effects_quality = "high"
 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 await get_tree().process_frame
 if "--interference-only" in OS.get_cmdline_user_args():
  app._play(25)
  var grid_battle: Node2D = app.battle
  grid_battle.set_physics_process(false)
  annotate("MISSION 25 / REAL GRID SURGE / STAGED CLOCK / ACTORS REMAIN VISIBLE")
  grid_battle.credits = 10000
  grid_battle.select_slot(0)
  check(grid_battle.build_turret("cannon"),"Build actual cannon before grid surge")
  grid_battle.close_build_mode()
  var grid_enemy: Node2D = grid_battle.spawn_enemy("heavy")
  grid_enemy.position = Vector2(500,350)
  grid_battle.tick_environment(float(grid_battle.mission_data.environment.period))
  grid_battle.view.tick(.2)
  check(grid_battle.environmental_pulses == 1 and grid_battle.placed[0].disabled_remaining > 0,"Actual existing grid interference disables the weapon")
  check(grid_enemy.health == grid_enemy.maximum_health,"Interference presentation adds no drone damage")
  await capture("grid_interference")
  var grid_report := FileAccess.open(directory.path_join("render_metrics.json"),FileAccess.WRITE)
  grid_report.store_string(JSON.stringify(metrics,"  "))
  app.queue_free()
  await get_tree().process_frame
  print("NATIVE GRID VFX: 1 capture, %d failures" % failures)
  get_tree().quit(1 if failures else 0)
  return
 for kind in CampaignManager.turrets:
  var battle: Node2D = deploy()
  annotate(str(kind).to_upper()+" / REAL TURRET SHOT AND IMPACT")
  battle.credits = 10000
  battle.select_slot(2)
  check(battle.build_turret(str(kind)),"Build actual secondary "+str(kind))
  battle.close_build_mode()
  var turret: Node2D = battle.placed[2]
  var enemy: Node2D = battle.spawn_enemy("heavy")
  enemy.position = turret.position+Vector2(0,-140)
  enemy.speed = 0
  await step(battle,.05)
  check(turret.shots_fired > 0,"Actual automatic firing event")
  await capture("weapon_"+str(kind)+"_fire")
  if kind not in ["laser","emp_tower"]:
   for frame in 120:
    if battle.impacts > 0:
     break
    await step(battle,1.0/60)
   check(battle.impacts > 0,"Actual round reaches its victim")
  else:
   await step(battle,.15)
   check(enemy.health < enemy.maximum_health if kind == "laser" else enemy.slow_remaining > 0,"Beam damage / EMP slow uses actual combat")
  await capture("weapon_"+str(kind)+"_impact")
 for ammunition in ["standard","armor_piercing","explosive"]:
  var battle: Node2D = deploy()
  annotate("PRIMARY / "+ammunition.to_upper()+" / REAL PROJECTILE")
  var cannon: Node2D = battle.player_turret
  check(cannon.select_ammunition(ammunition),"Select actual ammunition")
  var enemy: Node2D = battle.spawn_enemy("heavy")
  enemy.position = Vector2(560,420)
  enemy.speed = 0
  cannon.barrel_angle = -PI/2
  battle.player_controls.aim_at(enemy.position)
  battle.player_controls.set_fire(&"capture",true)
  await step(battle,.22)
  await capture("primary_"+ammunition+"_flight")
  for frame in 60:
   if cannon.hits > 0:
    break
   await step(battle,1.0/60)
  check(cannon.hits > 0,"Manual projectile really hits")
  await capture("primary_"+ammunition+"_impact")
  battle.player_controls.set_fire(&"capture",false)
  if ammunition == "explosive":
   check(cannon.request_reload(),"Actual magazine reload")
   await step(battle,.65)
   await capture("primary_reload")
 SaveManager.state.credits = 10000
 check(EconomyManager.purchase("crit_chance",0),"Fixture buys real critical-chance research before deployment")
 var battle: Node2D = deploy()
 annotate("PRIMARY / RESEARCH + SEEDED CRITICAL / REAL COLLISION")
 var victim: Node2D = battle.spawn_enemy("heavy")
 victim.position = Vector2(560,420)
 victim.speed = 0
 var cannon: Node2D = battle.player_turret
 cannon.ammunition_type = "standard"
 var probe := RandomNumberGenerator.new()
 for seed_value in range(1,1000):
  probe.seed = seed_value
  if probe.randf() < float(cannon.definition.critical_chance):
   cannon.rng.seed = seed_value
   break
 cannon.barrel_angle = -PI/2
 battle.player_controls.aim_at(victim.position)
 battle.player_controls.set_fire(&"capture",true)
 for frame in 60:
  await step(battle,1.0/60)
  if cannon.hits > 0:
   break
 battle.player_controls.set_fire(&"capture",false)
 check(cannon.last_critical,"Seeded critical uses the unchanged critical-chance/shot path")
 await capture("primary_critical")
 for kind in ["scout","heavy","assault_carrier"]:
  battle = deploy()
  annotate(str(kind).to_upper()+" / ACTUAL DEATH LIFECYCLE / STAGED DAMAGE")
  var enemy: Node2D = battle.spawn_enemy(kind)
  enemy.position = Vector2(500,350)
  var before: int = battle.kills
  enemy.hit(enemy.maximum_health*10,true,true,enemy.position)
  check(enemy.ended and battle.kills == before+1,"Destruction leaves real reward/removal immediate")
  battle.view.tick(.04)
  await capture("destroy_"+kind+"_flash")
  battle.view.tick(.46)
  await capture("destroy_"+kind+"_smoke")
 battle = deploy()
 annotate("BASE HP / STAGED REAL BREACH / 20% WARNING")
 battle._breached(int(battle.max_health*.8))
 battle.view.tick(.06)
 await capture("critical_base_damage")
 battle = deploy()
 annotate("REAL BOSS SPAWN / ARRIVAL PRESENTATION")
 var boss: Node2D = battle.spawn_enemy("assault_carrier")
 boss.position = boss.brain.anchor()
 battle.view.tick(.1)
 await capture("boss_arrival")
 # Saturate actual destruction signals in one dense wave. Definitions, paths,
 # collision code and rewards are unchanged; the direct damage is a fixture.
 for quality in ["high","low"]:
  battle = deploy()
  annotate("80 REAL DEATH EVENTS / "+quality.to_upper()+" / STRESS FIXTURE")
  var settings: Dictionary = SaveManager.DEFAULT_SETTINGS.duplicate()
  settings.effects_quality = quality
  battle.view.combat_fx.configure(settings)
  for frame in 8:
   for index in 10:
    var enemy: Node2D = battle.spawn_enemy("scout")
    enemy.position = Vector2(90+(index%5)*165,250+(frame%3)*95)
    enemy.hit(1000,true,true,enemy.position)
   battle.view.tick(1.0/60)
   await get_tree().process_frame
  var fx: Node2D = battle.view.combat_fx
  check(fx.peak <= int(fx.profile.particles) and fx.dropped > 0,"Stress work is bounded and excess cosmetic emissions are dropped")
  await capture("stress_"+quality)
  battle.view.tick(4)
  check(fx.active.is_empty() and battle.view.effects.is_empty() and battle.view.destruction.wrecks.is_empty(),"All stress effects and wrecks automatically clean up")
 SaveManager.settings.reduced_effects = true
 SaveManager.settings.reduced_motion = true
 battle = deploy()
 annotate("REDUCED EFFECTS + MOTION / NO SMOKE, LIGHTING, DEBRIS OR SHAKE")
 var heavy: Node2D = battle.spawn_enemy("heavy")
 heavy.position = Vector2(500,350)
 heavy.hit(10000,true,true,heavy.position)
 battle.view.tick(.08)
 await capture("reduced_effects_motion")
 check(battle.view.combat_fx.count_kind("debris") == 0 and battle.view.combat_fx.shake_offset == Vector2.ZERO,"Reduced presentation remains static and bounded")
 SaveManager.settings = SaveManager.DEFAULT_SETTINGS.duplicate()
 if app.get_node_or_null("CaptureLabel") != null:
  app.get_node("CaptureLabel").queue_free()
 app._settings()
 await get_tree().process_frame
 await capture("settings_audio")
 var scroll: ScrollContainer = app.content.find_children("*","ScrollContainer",true,false)[0]
 scroll.scroll_vertical = 350
 await get_tree().process_frame
 await capture("settings_quality")
 scroll.scroll_vertical = 700
 await get_tree().process_frame
 await capture("settings_effects")
 # A saved boss result still settles once before the skippable presentation.
 app._play(5)
 battle = app.battle
 battle.set_physics_process(false)
 annotate("SAVED BOSS RESULT / OPTIONAL OUTRO / SKIP AVAILABLE")
 boss = battle.spawn_enemy("assault_carrier")
 boss.position = Vector2(500,350)
 boss.hit(100000,true,true,boss.position)
 var token: String = battle.run_id
 battle._finish(true)
 await get_tree().process_frame
 check(app.screen == "debrief","Optional destruction presentation follows successful transaction")
 await capture("victory_outro")
 var paid: int = SaveManager.state.credits
 check(CampaignManager.resolve(true,5,token,app.result_data).is_empty() and SaveManager.state.credits == paid,"VFX cannot duplicate rewards")
 app.outro.finish()
 await get_tree().process_frame
 check(app.screen == "results","Skip retains already-saved mission result")
 await capture("victory_results")
 app.queue_free()
 await get_tree().process_frame
 var report := FileAccess.open(directory.path_join("render_metrics.json"),FileAccess.WRITE)
 report.store_string(JSON.stringify(metrics,"  "))
 print("NATIVE COMBAT VFX: %d captures, %d failures" % [metrics.size(),failures])
 get_tree().quit(1 if failures else 0)
