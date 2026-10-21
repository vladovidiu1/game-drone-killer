extends Node
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
 if "--verify-effects" in OS.get_cmdline_user_args():
  check(SaveManager.settings.effects_quality == "low" and SaveManager.settings.reduced_effects and SaveManager.settings.reduced_motion and not SaveManager.settings.effects_smoke,"Fresh process retains validated presentation preferences")
  SaveManager.settings = SaveManager.DEFAULT_SETTINGS.duplicate()
  check(SaveManager.save_settings(),"Restore ordinary presentation defaults for subsequent suites")
  finish()
  return
 var legacy: Dictionary = SaveManager.validate_settings({"volume":.4,"muted":false})
 check(legacy.effects_quality == "medium" and not legacy.reduced_effects and legacy.effects_shake,"Legacy settings acquire safe optional v3 defaults")
 var invalid: Dictionary = SaveManager.validate_settings({"effects_quality":["high"],"reduced_effects":"true","effects_smoke":0,"effects_shake":1,"reduced_motion":{}})
 check(invalid == SaveManager.DEFAULT_SETTINGS,"Malformed types never enable accessibility/performance options accidentally")
 check(SaveManager.validate_settings({"effects_quality":"ultra"}).effects_quality == "medium","Unknown quality falls back to known preset")
 SaveManager.new_campaign()
 var battle := preload("res://scenes/gameplay.tscn").instantiate()
 add_child(battle)
 battle.set_physics_process(false)
 var fx: Node2D = battle.view.combat_fx
 check(fx.get_child_count() == 2 and fx.get_node("FieldClip").clip_contents and fx.get_node("FieldClip").mouse_filter == Control.MOUSE_FILTER_IGNORE,"Reusable scene clips batched world effects and never captures touch")
 var enemy: Node2D = battle.spawn_enemy("heavy")
 enemy.position = Vector2(500,350)
 var snapshot := [enemy.health,enemy.position,enemy.reward,battle.credits,battle.kills,battle.player_turret.rng.state,battle.impacts]
 for quality in ["low","medium","high"]:
  var settings: Dictionary = SaveManager.DEFAULT_SETTINGS.duplicate()
  settings.effects_quality = quality
  fx.configure(settings)
  for frame in 30:
   fx.tick(.001)
   for event in 20:
    fx.impact(enemy.position,"missile",Color.ORANGE,75,true)
    fx.destroyed(enemy)
    fx.trail(enemy.position,Vector2.UP,"missile",Color.WHITE)
   check(fx.active.size() <= int(fx.profile.particles),"Particle hard cap during a dense wave: "+quality)
   check(fx.count_kind("smoke") <= int(fx.profile.smoke) and fx.count_kind("debris") <= int(fx.profile.debris) and fx.count_kind("light") <= int(fx.profile.lights),"Independent overdraw/debris/light caps: "+quality)
   check(fx.emitted <= int(fx.profile.emissions_per_tick),"Burst work budget per simulation tick: "+quality)
  check(fx.dropped > 0,"Saturation drops cosmetic work instead of creating nodes")
  check(fx.active.size()+fx.free_slots.size() == fx.HARD_LIMIT,"Pool ownership remains complete under pressure")
  fx.tick(3)
  check(fx.active.is_empty() and fx.free_slots.size() == fx.HARD_LIMIT,"All detached particles retire and return their reusable slots")
 for event in 200:
  battle.view.effect(Vector2(450,300),"blast",40,Color.ORANGE)
  battle.view.effect(Vector2(520,300),"hit",12,Color.WHITE)
 var blast_count := 0
 var hit_count := 0
 for item in battle.view.effects:
  blast_count += 1 if item.kind == "blast" else 0
  hit_count += 1 if item.kind == "hit" else 0
 check(blast_count <= int(fx.profile.explosions) and hit_count == 1,"Explosion density is capped separately; sustained laser hits coalesce rather than stacking flashes")
 check(snapshot == [enemy.health,enemy.position,enemy.reward,battle.credits,battle.kills,battle.player_turret.rng.state,battle.impacts],"VFX stress cannot alter HP, positions, rewards, counters or critical RNG")
 fx.configure(SaveManager.DEFAULT_SETTINGS)
 fx.shot(Vector2(560,567),Vector2.UP,"cannon",Color.ORANGE)
 fx.shake(1.5)
 battle.view.tick(.02)
 var age: float = fx.clock
 var offset: Vector2 = fx.shake_offset
 var point: Vector2 = enemy.position
 check(offset.length() <= 2.13 and enemy.art.position == offset and enemy.position == point,"Shake is subtle artwork-only displacement, preserving collision and input coordinates")
 battle.set_paused(true)
 battle.simulate(.5)
 check(fx.clock == age and fx.shake_offset == offset,"Pause freezes particles, smoke and shake")
 battle.set_paused(false)
 battle._physics_process(.05)
 check(is_equal_approx(fx.clock-age,.05),"Combat effects share standardized normal simulation time")
 age = fx.clock
 battle.select_slot(0)
 battle._physics_process(.04)
 check(is_equal_approx(fx.clock-age,.01),"Build mode effects use the same 0.25x delta as projectiles")
 battle.close_build_mode()
 fx.tick(3)
 var switches: Dictionary = SaveManager.DEFAULT_SETTINGS.duplicate()
 switches.effects_smoke = false
 switches.effects_debris = false
 switches.effects_lighting = false
 switches.effects_shake = false
 fx.configure(switches)
 fx.destroyed(enemy)
 fx.trail(enemy.position,Vector2.UP,"missile",Color.ORANGE)
 fx.shake(2)
 check(fx.count_kind("smoke") == 0 and fx.count_kind("debris") == 0 and fx.count_kind("light") == 0 and fx.shake_offset == Vector2.ZERO,"Individual layer switches override the quality preset")
 fx.tick(3)
 var reduced: Dictionary = SaveManager.DEFAULT_SETTINGS.duplicate()
 reduced.reduced_effects = true
 reduced.reduced_motion = true
 SaveManager.settings = reduced.duplicate()
 fx.configure(reduced)
 var rotor_clock: float = enemy.art.clock
 enemy.art.advance(.4)
 check(enemy.art.clock == rotor_clock,"Reduced motion holds rotor and hovering artwork still")
 fx.destroyed(enemy)
 fx.impact(enemy.position,"explosive",Color.ORANGE,75,true)
 fx.shake(10)
 fx.tick(.02)
 fx.observe(battle,.02)
 check(fx.count_kind("smoke") == 0 and fx.count_kind("debris") == 0 and fx.count_kind("light") == 0,"Reduced effects suppress expensive layers")
 check(fx.shake_offset == Vector2.ZERO and enemy.art.position == Vector2.ZERO,"Reduced motion removes shake and clears previous displacement")
 for index in fx.active:
  check(fx.slots[index].velocity == Vector2.ZERO,"Reduced-motion particles do not fly across the field")
 check(fx.count_kind("area") == 1 and fx.count_kind("critical") == 1,"Accessibility preserves area and critical-hit information")
 fx.tick(3)
 SaveManager.settings = SaveManager.DEFAULT_SETTINGS.duplicate()
 fx.configure(SaveManager.DEFAULT_SETTINGS)
 fx.base_damaged(.2)
 check(fx.damage_age > 0 and fx.critical_base,"Base damage and low-health warning use bounded non-strobing feedback")
 fx.announce("HOSTILE COMMAND")
 check(fx.banner_age > 0 and not fx.victory,"Boss arrival is presentation-only and timed")
 fx.tick(3)
 check(fx.damage_age == 0 and fx.banner_age == 0 and fx.shake_remaining == 0,"Screen feedback and arrival automatically expire")
 # Real projectile lifecycle, not calling a damage method from the effects code.
 enemy.ended = true
 enemy.queue_free()
 await get_tree().process_frame
 var scout: Node2D = battle.spawn_enemy("scout")
 scout.position = Vector2(560,430)
 scout.speed = 0
 var original_hp: float = scout.health
 var cannon: Node2D = battle.player_turret
 cannon.barrel_angle = -PI/2
 cannon.set_aim(scout.position)
 cannon.set_trigger(true)
 for frame in 12:
  battle.simulate(1.0/60)
  await get_tree().process_frame
 cannon.set_trigger(false)
 check(cannon.shots_fired > 0 and scout.health < original_hp and cannon.hits > 0,"Actual manual round fires, emits VFX and damages the drone")
 check(battle.impacts == cannon.hits,"A consumed single-target round has one damage/hit event")
 cannon.ammo = 1
 check(cannon.request_reload(),"Actual cannon starts reload")
 battle.simulate(.05)
 check(fx.reload_fraction >= 0,"Reload progress is read from real cannon state")
 for frame in 150:
  battle.simulate(1.0/60)
  await get_tree().process_frame
 check(cannon.reload_remaining == 0 and fx.reload_fraction < 0,"Completion leaves no stale reload overlay")
 var children := battle.get_child_count()
 battle.queue_free()
 await get_tree().process_frame
 var restarted := preload("res://scenes/gameplay.tscn").instantiate()
 add_child(restarted)
 restarted.set_physics_process(false)
 check(restarted.view.combat_fx.active.is_empty() and restarted.view.combat_fx.clock == 0 and restarted.get_child_count() == children,"Restart resets transient VFX without growing the scene tree")
 restarted.queue_free()
 await get_tree().process_frame
 SaveManager.settings.effects_quality = "low"
 SaveManager.settings.reduced_effects = true
 SaveManager.settings.reduced_motion = true
 SaveManager.settings.effects_smoke = false
 check(SaveManager.save_settings(),"Visual options persist through validated atomic settings save")
 finish()
func finish() -> void:
 print("COMBAT VFX: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
