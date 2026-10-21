extends RefCounted
# Test-only reproducible input policy. Never loaded by playable scenes.
static func build(battle: Node2D, strategy: String) -> void:
 var indices: Array = [2,3] if strategy.begins_with("two_") else range(battle.slots.size())
 for index in indices:
  if battle.placed[index] == null:
   battle.select_slot(index)
   var kind := "machine_gun"
   if strategy == "two_cannon" or (strategy == "two_mixed" and index == 3):
    kind = "cannon"
   elif not strategy.begins_with("two_"):
    kind = "missile" if index%3 == 2 else "machine_gun" if index < 2 else "cannon"
   battle.build_turret(kind)
 for index in indices:
  if battle.placed[index] != null:
   battle.select_slot(index)
   battle.upgrade_selected()
 battle.close_build_mode()

static func aim(battle: Node2D) -> void:
 var selected: Node2D = null
 var priority := -INF
 for enemy in battle.drones.get_children():
  if enemy.ended or enemy.position.distance_to(battle.player_turret.position) > 395:
   continue
  var score: float = 1000-enemy.distance_remaining
  if enemy.brain.boss:
   score += 700
  elif enemy.brain.charging:
   score += 450
  elif enemy.brain.data.has("aura_radius"):
   score += 350
  if score > priority:
   selected = enemy
   priority = score
 if selected != null:
  var point: Vector2 = selected.brain.weakpoint() if selected.brain.boss else selected.position
  if not selected.brain.boss and selected.waypoint < selected.route.size():
   point += selected.position.direction_to(selected.route[selected.waypoint])*selected.speed*selected.position.distance_to(battle.player_turret.position)/850.0
  battle.player_controls.aim_at(point)
 battle.player_controls.set_fire(&"simulation",selected != null)
