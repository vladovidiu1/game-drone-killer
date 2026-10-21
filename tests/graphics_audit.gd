extends Node
const GRAPHICS := preload("res://scripts/visual/graphics_profile.gd")
var checks := 0
var failures := 0
func check(condition: bool, message: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error(message)
func _ready() -> void:
 run.call_deferred()
func run() -> void:
 if "--verify-graphics" in OS.get_cmdline_user_args():
  var restored := preload("res://scenes/gameplay.tscn").instantiate()
  add_child(restored)
  restored.set_physics_process(false)
  check(SaveManager.settings.effects_quality == "low" and restored.view.environment.reduced and not restored.player_turret.get_node("Artwork").art.shadow.visible and restored.view.combat_fx.profile.particles == 48,"Fresh process applies saved Low to terrain, shadows and VFX together")
  restored.queue_free()
  await get_tree().process_frame
  SaveManager.settings = SaveManager.DEFAULT_SETTINGS.duplicate()
  check(SaveManager.save_settings(),"Restore balanced defaults for later suites")
  finish()
  return
 SaveManager.new_campaign()
 var originals := CampaignManager.missions.duplicate(true)
 var previous_particles := -1
 var previous_shadows := -1.0
 for quality in ["low","medium","high"]:
  SaveManager.settings = SaveManager.DEFAULT_SETTINGS.duplicate()
  SaveManager.settings.effects_quality = quality
  var preset := GRAPHICS.resolve(SaveManager.settings)
  check(int(preset.particles) > previous_particles and float(preset.shadow_strength) > previous_shadows,"Presets increase particle/shadow budgets predictably")
  previous_particles = int(preset.particles)
  previous_shadows = float(preset.shadow_strength)
  for id in range(1,26):
   var battle := preload("res://scenes/gameplay.tscn").instantiate()
   battle.mission_id = id
   add_child(battle)
   battle.set_physics_process(false)
   var environment: Control = battle.view.environment
   check(environment.terrain.texture != null and environment.terrain.material.shader != null,"Mission %d imports/render resources resolve at %s" % [id,quality])
   check(environment.particles.size() <= int(preset.environment_particles) and environment.decorations.size() <= int(preset.props),"Mission %d uses unified atmosphere/prop budgets at %s" % [id,quality])
   check(environment.reduced == not bool(preset.environment_animated),"Low selects static terrain fallback")
   check(battle.view.combat_fx.profile.particles == preset.particles,"Combat pool uses same quality choice as the environment")
   check(battle.player_turret.get_node("Artwork").art.shadow.visible == (float(preset.shadow_strength) > 0),"Primary extra shadow follows preset")
   check(battle.mission_data == originals[id-1],"Graphics profile never changes mission data, paths or economy")
   battle.select_slot(battle.slots.size()-1)
   check(battle.selected_slot == battle.slots.size()-1,"Last emplacement remains accessible in each mission/preset")
   battle.close_build_mode()
   if id == 1:
    for kind in CampaignManager.enemies:
     var enemy: Node2D = battle.spawn_enemy(str(kind))
     var health: float = enemy.health
     var position_before: Vector2 = enemy.position
     var art: Node2D = enemy.art
     art.advance(.12,.5,0,2,false,1,2)
     art.sync(0,.06,true,true)
     check(art.body.texture is AtlasTexture and art.shadow.visible == (quality != "low"),"Every enemy/boss preserves raster body and uses intended shadow mode")
     check(is_equal_approx(float(art.surface.get_shader_parameter("damage_amount")),.5) and is_equal_approx(float(art.surface.get_shader_parameter("visibility")),.38),"Cached uniforms preserve damage/cloak feedback")
     art.sync(0,0,false,false)
     check(is_equal_approx(float(art.surface.get_shader_parameter("hit_flash")),0) and float(art.surface.get_shader_parameter("visibility")) == 1,"Cached uniforms invalidate immediately on status recovery")
     check(enemy.health == health and enemy.position == position_before,"Visual animation/shader cache never changes HP or collision position")
     for panel in art.armor_panels:
      check(panel.material.get_shader_parameter("visibility") == 1,"Boss armor sections recover with body shader")
   var clock: float = environment.elapsed
   battle.set_paused(true)
   battle.simulate(.3)
   check(environment.elapsed == clock,"Pause freezes profile-driven environment timing")
   battle.queue_free()
   await get_tree().process_frame
 check(CampaignManager.missions == originals,"All 75 profile/mission loads leave catalog unchanged")
 var override: Dictionary = SaveManager.DEFAULT_SETTINGS.duplicate()
 override.effects_quality = "high"
 override.reduced_effects = true
 var reduced := GRAPHICS.resolve(override)
 check(reduced.particles == 48 and reduced.burst == 2 and reduced.environment_particles == 0 and reduced.shadow_strength == 0 and not reduced.smoke_enabled,"Reduced effects override High consistently")
 override.reduced_effects = false
 override.reduced_motion = true
 reduced = GRAPHICS.resolve(override)
 check(not reduced.environment_animated and not reduced.shake_enabled and not reduced.debris_enabled,"Reduced motion preserves essential cues without animated weather/shake/debris")
 check(GRAPHICS.resolve({"effects_quality":"unknown"}).particles == GRAPHICS.DATA.medium.particles,"Unknown quality falls back to Medium without changing save schema")
 # All preset choices use native touch buttons rather than a mouse-only dropdown.
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 var app := preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 app._settings()
 await get_tree().process_frame
 var options: Control
 for node in app.find_children("*","VBoxContainer",true,false):
  if node.get_script() == preload("res://scripts/ui/effects_settings.gd"):
   options = node
 check(options != null,"Graphics preferences remain reachable from actual Settings screen")
 for quality in ["low","medium","high"]:
  var button: Button = options.preset_buttons[quality]
  var scroll: ScrollContainer = button.get_parent().get_parent().get_parent().get_parent()
  scroll.ensure_control_visible(button)
  await get_tree().process_frame
  var center: Vector2 = button.get_global_rect().get_center()
  for held in [true,false]:
   var finger := InputEventScreenTouch.new()
   finger.index = 81
   finger.position = center
   finger.pressed = held
   get_viewport().push_input(finger,true)
  check(SaveManager.settings.effects_quality == quality,"Actual touch selects and persists "+quality)
 app.queue_free()
 await get_tree().process_frame
 SaveManager.settings.effects_quality = "low"
 check(SaveManager.save_settings(),"Saved Low is available for fresh-process graphics verification")
 finish()
func finish() -> void:
 print("GRAPHICS AUDIT: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
