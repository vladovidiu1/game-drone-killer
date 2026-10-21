extends Node
# Reproducible native software-renderer diagnostics, never an Android FPS claim.
# 80 stationary drones and fixture funds are staged rendering stress, not tuning.
var directory := "/tmp/frontline-profile"
var failures := 0
var samples: Array[Dictionary] = []
var component_stress := false
func check(condition: bool, message: String) -> void:
 if not condition:
  failures += 1
  push_error(message)
func _ready() -> void:
 run.call_deferred()
func distribution(values: Array[float]) -> Dictionary:
 values.sort()
 return {"median":values[values.size()/2],"p95":values[mini(values.size()-1,int(values.size()*.95))],"maximum":values.back()}
func run() -> void:
 for argument in OS.get_cmdline_user_args():
  if argument == "--component-stress":
   component_stress = true
  if argument.begins_with("--output="):
   directory = argument.trim_prefix("--output=")
 if DisplayServer.get_name() == "headless":
  push_error("Profiling requires an actual display/Compatibility renderer")
  get_tree().quit(1)
  return
 DirAccess.make_dir_recursive_absolute(directory)
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 SaveManager.new_campaign()
 SaveManager.state.frontline = 25
 SaveManager.state.highest = 25
 SaveManager.state.unlocks = ["laser","emp_tower","heavy_aa","armor_piercing","explosive"]
 var app := preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 await get_tree().process_frame
 var expected: Array = []
 for quality in ["low","medium","high"]:
  SaveManager.settings = SaveManager.DEFAULT_SETTINGS.duplicate()
  SaveManager.settings.effects_quality = quality
  app._play(20 if component_stress else 4)
  await get_tree().process_frame
  var battle: Node2D = app.battle
  battle.set_physics_process(false)
  battle.spawner.timer = 10000
  battle.credits = 20000
  battle.player_turret.rng.seed = 6006
  var slot := 0
  for kind in CampaignManager.turrets:
   if slot >= battle.slots.size():
    break
   battle.select_slot(slot)
   check(battle.build_turret(str(kind)),"Stress fixture builds actual defenses")
   slot += 1
  battle.close_build_mode()
  var types := ["scout","assault","heavy","shield","emp","bomber","sniper","carrier","stealth"]
  for index in 80:
   var enemy: Node2D = battle.spawn_enemy(types[index%types.size()])
   enemy.position = Vector2(100+(index%10)*78,185+(index/10)*41)
   enemy.speed = 0
   if component_stress and enemy.components != null and index%3 == 0:
    var engine: Node2D = enemy.components.find("engine_left")
    if engine != null:
     engine.receive(engine.health+.001,true,true,{})
  var cpu: Array[float] = []
  var wall: Array[float] = []
  var calls: Array[float] = []
  var memory: Array[float] = []
  for frame in 240:
   var frame_start := Time.get_ticks_usec()
   for enemy in battle.drones.get_children():
    if not enemy.ended and enemy.position.distance_to(battle.player_turret.position) < 390:
     battle.player_controls.aim_at(enemy.position)
     battle.player_controls.set_fire(&"profile",true)
     break
   var simulation_start := Time.get_ticks_usec()
   battle.simulate(1.0/60)
   var simulation_ms := (Time.get_ticks_usec()-simulation_start)/1000.0
   await get_tree().process_frame
   await RenderingServer.frame_post_draw
   if frame >= 60:
    cpu.append(simulation_ms)
    wall.append((Time.get_ticks_usec()-frame_start)/1000.0)
    calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
    memory.append(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
  var state := [battle.health,battle.kills,battle.earned,battle.credits,battle.shots_fired,battle.player_turret.hits,battle.enemy_actions,battle.support_spawned]
  if expected.is_empty():
   expected = state
  check(expected == state,"Graphics preset cannot change deterministic stress combat outcomes")
  var picture := get_viewport().get_texture().get_image()
  check(picture.save_png(directory.path_join("stress_"+quality+".png")) == OK,"Native stress capture saved")
  samples.append({"preset":quality,"measured_frames":cpu.size(),"simulation_cpu_ms":distribution(cpu),"frame_wall_ms":distribution(wall),"draw_calls":distribution(calls),"renderer_texture_bytes":distribution(memory),"particle_peak":battle.view.combat_fx.peak,"environment_particles":battle.view.environment.particles.size(),"props":battle.view.environment.decorations.size(),"combat_signature":state})
  print("PROFILE: "+JSON.stringify(samples.back()))
  battle.player_controls.clear()
 app.queue_free()
 await get_tree().process_frame
 var report := FileAccess.open(directory.path_join("profile.json"),FileAccess.WRITE)
 report.store_string(JSON.stringify({"renderer":RenderingServer.get_video_adapter_name(),"godot":Engine.get_version_info().string,"fixture":"80 stationary drones; actual weapons/AI; seed6006; 60 warmup +180 measured frames at dt1/60; "+("M20 component stress with staged broken left engines" if component_stress else "M4 storm"),"samples":samples,"failures":failures},"  "))
 print("NATIVE PROFILE: %d presets, %d failures" % [samples.size(),failures])
 get_tree().quit(1 if failures else 0)
