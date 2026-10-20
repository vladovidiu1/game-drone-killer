extends Node2D
# Automatic target acquisition; battle resolves all impacts and rewards.
var battle: Node2D
var kind := "machine_gun"
var definition: Dictionary = {}
var level := 1
var cooldown := 0.0
var target: Node2D
var barrel_angle := -PI/2
var muzzle := 0.0
var shots_fired := 0

func configure(owner_battle: Node2D, type: String) -> void:
 battle = owner_battle
 kind = type
 definition = CampaignManager.turrets[kind]

func damage_value() -> float:
 return float(definition.damage) * pow(float(CampaignManager.combat.upgrade_damage_multiplier),level-1) * (1.0 + int(SaveManager.state.get("damage_level",0))*float(CampaignManager.combat.permanent_damage_step)) * (1.0+EconomyManager.modifier("turret_damage",battle.research_levels))

func range_value() -> float:
 return (float(definition.range) + (level-1)*float(CampaignManager.combat.upgrade_range_step))*(1.0+EconomyManager.modifier("turret_range",battle.research_levels))

func fire_rate_value() -> float:
 return float(definition.fire_rate)*(1.0+EconomyManager.modifier("turret_rate",battle.research_levels))*battle.abilities.fire_multiplier()

func upgrade_cost() -> int:
 return int(ceil(float(definition.cost)*float(CampaignManager.combat.upgrade_cost_multiplier)*level))

func tick(delta: float) -> void:
 muzzle = maxf(0.0,muzzle-delta)
 cooldown = maxf(-delta,cooldown-delta)
 target = acquire_target()
 if is_instance_valid(target):
  barrel_angle = (target.position-position).angle()
  var mode := str(definition.get("mode","projectile"))
  if mode == "laser":
   target.hit(damage_value()*delta*fire_rate_value()/float(definition.fire_rate))
   muzzle = 0.06
  if cooldown <= 0:
   if mode == "emp":
    for enemy in battle.drones.get_children():
     if not enemy.ended and enemy.position.distance_to(position) <= range_value():
      enemy.apply_slow(float(definition.slow_factor),float(definition.status_duration))
    battle.view.effect(position,"blast",range_value(),Color(str(definition.color)))
   elif mode != "laser":
    battle.launch_projectile(self,target)
   cooldown += 1.0/fire_rate_value()
   muzzle = 0.08
   shots_fired += 1
 else:
  cooldown = maxf(0.0,cooldown)
 queue_redraw()

func acquire_target() -> Node2D:
 # Closest to the base by remaining path distance; spawn ID breaks ties.
 var selected: Node2D = null
 for enemy in battle.drones.get_children():
  if enemy.ended or position.distance_squared_to(enemy.position) > range_value()*range_value():
   continue
  if selected == null or enemy.distance_remaining < selected.distance_remaining or (is_equal_approx(enemy.distance_remaining,selected.distance_remaining) and enemy.spawn_id < selected.spawn_id):
   selected = enemy
 return selected

func _draw() -> void:
 var color := Color(str(definition.get("color","65e0c0")))
 draw_circle(Vector2(0,8),30,Color(0,0,0,0.35))
 draw_circle(Vector2.ZERO,27,Color("14222e"))
 draw_arc(Vector2.ZERO,26,0,TAU,24,color.darkened(0.45),3)
 draw_rect(Rect2(-18,-18,36,36),Color("344959"))
 draw_set_transform(Vector2.ZERO,barrel_angle)
 if kind == "machine_gun":
  draw_line(Vector2(-5,-5),Vector2(32,-5),color,5)
  draw_line(Vector2(-5,5),Vector2(32,5),color,5)
 elif kind == "cannon" or kind == "heavy_aa":
  draw_line(Vector2(-10,0),Vector2(34,0),Color("101a26"),17)
  draw_line(Vector2(-8,0),Vector2(32,0),color,11)
 elif kind in ["laser","emp_tower"]:
  draw_circle(Vector2.ZERO,16,color.darkened(0.5))
  draw_circle(Vector2.ZERO,9,color)
  draw_line(Vector2.ZERO,Vector2(30,0),color,5)
 else:
  for y in [-9,9]:
   draw_rect(Rect2(-14,y-6,40,12),Color("16212f"))
   draw_line(Vector2(-10,y),Vector2(22,y),color,6)
 if muzzle > 0:
  draw_colored_polygon(PackedVector2Array([Vector2(32,-7),Vector2(48,0),Vector2(32,7)]),Color("fff4be"))
 draw_set_transform(Vector2.ZERO)
 if kind == "laser" and muzzle > 0 and is_instance_valid(target) and not target.ended:
  draw_line(Vector2.ZERO,target.position-position,Color(color,0.3),7)
  draw_line(Vector2.ZERO,target.position-position,color,2)
 for i in level:
  draw_circle(Vector2(-8+i*8,20),2.5,color)
