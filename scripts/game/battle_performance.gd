extends RefCounted
# Battle-owned event counters. No payout or persistence. Hull damage is effective,
# clamped damage (component HP is tracked separately), not raw shot energy.
const RULES := preload("res://scripts/core/mission_performance.gd")
var battle: Node2D
var counters: Dictionary = {}

func configure(owner_battle: Node2D) -> void:
 battle = owner_battle
 for key in RULES.INTEGERS+RULES.FLOATS:
  counters[key] = 0

func shot(projectile: Node2D) -> void:
 if battle.guided:
  return
 counters.manual_shots += 1
 projectile.telemetry_registered = true

func impact(projectile: Node2D, critical: bool) -> void:
 if battle.guided or not projectile.manual or not projectile.telemetry_registered:
  return
 if not projectile.accuracy_recorded:
  projectile.accuracy_recorded = true
  counters.manual_hits += 1
 if critical and not projectile.critical_recorded:
  projectile.critical_recorded = true
  counters.critical_hits += 1

func damage(source: StringName, amount: float) -> void:
 var key := "manual_damage" if source == &"manual" else "automatic_damage" if source == &"automatic" else "other_damage"
 counters[key] += amount

func component(part: Node2D) -> void:
 counters.components += 1
 if part.kind == "shield":
  counters.generators += 1
 if part.kind == "weapon":
  counters.weapons += 1
 if float(part.definition.get("armor",0)) > 0:
  counters.armored_components += 1
 if part.kind == "engine" and part.rig.enemy.enemy_type == "heavy" and part.last_source == &"manual" and part.last_direct:
  counters.heavy_engines += 1

func base_damage(amount: float) -> void:
 counters.base_damage += amount
 if battle.spawner.wave == battle.spawner.waves.size()-1:
  counters.final_wave_damage += amount

func tick() -> void:
 var sectors: Dictionary = {}
 for turret in battle.placed:
  if is_instance_valid(turret) and not turret.redeploying and turret.disabled_remaining <= 0:
   sectors[str(battle.mission_data.emplacements[turret.emplacement].sector)] = true
 counters.defense_sectors = maxi(int(counters.defense_sectors),sectors.size())

func snapshot() -> Dictionary:
 var result := counters.duplicate()
 result.version = 1
 result.mission_id = battle.mission_id
 result.health = battle.health
 result.max_health = battle.max_health
 result.seconds = battle.elapsed
 result.core_hits = battle.weakpoint_hits
 return RULES.clean(result,battle.mission_id)

func objective() -> Dictionary:
 return RULES.secondary(battle.mission_id,snapshot())
