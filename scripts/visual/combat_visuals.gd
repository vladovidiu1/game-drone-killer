extends RefCounted
# Adapter reads snapshots only. No gameplay method is called from UnitVisual.
static func advance(battle: Node2D, delta: float) -> void:
 for enemy in battle.drones.get_children():
  if enemy.ended or not is_instance_valid(enemy.art):
   continue
  var phase := 0
  var actions := 0
  if enemy.brain != null:
   phase = enemy.brain.phase_index
   actions = enemy.brain.actions
  enemy.art.advance(delta,enemy.health/enemy.maximum_health,actions,1,false,1.0,phase)
  enemy.art.sync(0.0,enemy.hit_flash,enemy.brain != null and enemy.brain.cloaked(),enemy.disable_remaining > 0)
 for turret in battle.turrets.get_children():
  turret.art.advance(delta,1.0,turret.shots_fired,turret.level)
  turret.art.sync(turret.barrel_angle+PI/2,0,false,turret.disabled_remaining > 0)
 var cannon: Node2D = battle.player_turret
 var art: Node2D = cannon.get_node("Artwork").art
 var score := 0
 for key in ["cannon_damage","cannon_rate","magazine","reload"]:
  score += int(battle.research_levels.get(key,0))
 art.advance(delta,1.0,cannon.shots_fired,1+mini(2,score/5),cannon.reload_remaining > 0,cannon.reload_progress())
 art.sync(cannon.barrel_angle+PI/2,0,false,false,cannon.recoil)
