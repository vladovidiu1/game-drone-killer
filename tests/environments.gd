extends Node
const ENV := preload("res://scripts/visual/battle_environment.gd")
const LIB := preload("res://scripts/visual/environment_library.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)

func _ready() -> void:
 run.call_deferred()

func run() -> void:
 if "--verify-environment-settings" in OS.get_cmdline_user_args():
  check(SaveManager.settings.reduced_environment_effects,"Reduced-effects preference persists in a fresh process")
  # Restore standard presentation before subsequent full-combat suites.
  SaveManager.settings.reduced_environment_effects = false
  check(SaveManager.save_settings(),"Verification restores normal effects for subsequent combat suites")
  finish()
  return
 SaveManager.new_campaign()
 var original: String = FileAccess.get_sha256("res://data/definitions.json")
 check(LIB.DATA.missions.size() == 25 and LIB.DATA.types.size() >= 10 and LIB.DATA.profiles.size() == 5,"Complete environment catalog")
 var first_five: Array[String] = []
 for mission_id in range(1,26):
  var data: Dictionary = CampaignManager.mission(mission_id).duplicate(true)
  var battle := preload("res://scenes/gameplay.tscn").instantiate()
  battle.mission_id = mission_id
  add_child(battle)
  battle.set_physics_process(false)
  var layer: Control = battle.view.environment
  check(layer.assignment == LIB.DATA.missions[str(mission_id)],"Mission uses its own identity %d" % mission_id)
  if mission_id <= 5:
   first_five.append(str(layer.assignment.type))
  check(layer.clip_contents and layer.position == Vector2(0,88) and layer.size == Vector2(955,560),"All environment drawing clips below HUD and within the battlefield")
  check(layer.mouse_filter == Control.MOUSE_FILTER_IGNORE and layer.show_behind_parent,"Environment never owns touch/mouse or covers actors")
  check(layer.get_child_count() == 1 and layer.decorations.size() <= ENV.MAX_PROPS and layer.particles.size() <= ENV.MAX_PARTICLES,"Bounded nodes, decorations and atmosphere work")
  check(layer.terrain.texture != null and layer.terrain.material.shader != null,"Terrain art and Compatibility grading resolve")
  verify_grading(layer,mission_id)
  check(not layer.decorations.is_empty(),"Layered prop composition exists")
  for item in layer.decorations:
   check(ENV.decoration_is_safe(item.point,float(item.radius),data),"Tall prop avoids flight routes, touch discs, base and briefing")
  check(float(layer.profile.haze) <= .07,"Atmosphere stays below units with bounded haze")
  check(battle.mission_data == data and battle.slots.size() == data.slots.size(),"Presentation leaves the entire mission definition intact")
  for index in battle.slots.size():
   check(battle.slots[index] == Vector2(float(data.slots[index][0]),float(data.slots[index][1])),"Placement position unchanged")
   battle.select_slot(index)
   check(battle.selected_slot == index,"All turret slots remain selectable")
  battle.close_build_mode()
  var time: float = layer.elapsed
  battle.set_paused(true)
  battle.simulate(1.0)
  check(layer.elapsed == time,"Pause freezes every environmental animation")
  battle.set_paused(false)
  battle.simulate(.1)
  check(is_equal_approx(layer.elapsed,time+.1),"Atmosphere uses shared simulated delta")
  var scout: Node2D = battle.spawn_enemy("scout")
  var start: Vector2 = scout.position
  scout.tick(.1)
  check(scout.position.distance_to(start) > 0 and scout.art.body.texture != null,"Existing enemies still move and draw above scenery")
  check(battle.visibility_multiplier() == float(data.get("environment",{}).get("range_multiplier",1)),"Visual weather does not change combat visibility stats")
  var terrain_reference: WeakRef = weakref(layer.terrain.texture)
  battle.queue_free()
  await get_tree().process_frame
  await get_tree().process_frame
  check(terrain_reference.get_ref() == null,"Unused terrain region releases with the deployed scene")
 check(first_five == ["outpost","village","depot","bridge","urban"],"Distinctive first five environments")
 check(FileAccess.get_sha256("res://data/definitions.json") == original,"Environment loading never rewrites gameplay data")
 check(not SaveManager.validate_settings({"volume":.6}).reduced_environment_effects,"Legacy settings receive safe default")
 check(not SaveManager.validate_settings({"volume":.6,"reduced_environment_effects":"true"}).reduced_environment_effects,"Untrusted quality flag requires a real boolean")
 SaveManager.settings.reduced_environment_effects = true
 check(SaveManager.save_settings(),"Reduced-effects flag saves using existing validated atomic settings path")
 var low := ENV.new()
 low.setup(CampaignManager.mission(4))
 add_child(low)
 check(low.reduced and low.terrain.texture != null,"Low effects keeps illustrated terrain and selects reduced draw branch")
 check(low.decorations.size() > 0,"Low effects retains landmark identity")
 low.queue_free()
 await get_tree().process_frame
 finish()

func finish() -> void:
 print("ENVIRONMENTS: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)

func verify_grading(layer: Control, mission_id: int) -> void:
 # Scope inspection temporaries to this function, rather than the suspended
 # test coroutine, so the memory-release assertion observes runtime ownership.
 var grade: ShaderMaterial = layer.terrain.material
 var uv: Vector4 = grade.get_shader_parameter("uv_rect")
 check(uv == Vector4(0,0,1,1) if mission_id == 1 else uv.z == .5 and uv.w == .5,"Grading normalizes each atlas cell independently")
