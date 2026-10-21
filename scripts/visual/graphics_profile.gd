extends RefCounted
# Canonical graphics policy. Reuses the validated schema-v3 effects_quality key;
# gameplay definitions, timing, input and RNG never depend on this profile.
static var DATA: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/effects/quality.json"))
static func resolve(settings: Dictionary) -> Dictionary:
 var id := str(settings.get("effects_quality","medium"))
 if not DATA.has(id):
  id = "medium"
 var reduced := bool(settings.get("reduced_effects",false))
 var motion := bool(settings.get("reduced_motion",false))
 var result: Dictionary = DATA.low.duplicate(true) if reduced else DATA[id].duplicate(true)
 result.id = id
 result.reduced = reduced
 result.motion = motion
 result.smoke_enabled = bool(settings.get("effects_smoke",true)) and not reduced
 result.debris_enabled = bool(settings.get("effects_debris",true)) and not reduced and not motion
 result.lighting_enabled = bool(settings.get("effects_lighting",true)) and not reduced
 result.shake_enabled = bool(settings.get("effects_shake",true)) and not reduced and not motion
 result.environment_animated = int(result.environment_particles) > 0 and not bool(settings.get("reduced_environment_effects",false)) and not motion and not reduced
 if not result.environment_animated:
  result.environment_particles = 0
  result.haze_layers = 0
 if reduced:
  result.burst = 2
  result.shadow_strength = 0.0
  result.environment_lights = false
 return result
