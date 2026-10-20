extends Node2D
# Automatic target acquisition; battle resolves all impacts and rewards.
const ASSETS := preload("res://scripts/visual/visual_assets.gd")
var art: Node2D
var battle: Node2D
var kind := "machine_gun"
var definition: Dictionary = {}
var level := 1
var cooldown := 0.0
var target: Node2D
var barrel_angle := -PI/2
var muzzle := 0.0
var shots_fired := 0
var disabled_remaining := 0.0

func apply_disable(duration: float) -> void:
 disabled_remaining = maxf(disabled_remaining,duration)

func configure(owner_battle: Node2D, type: String) -> void:
 battle = owner_battle
 kind = type
 definition = CampaignManager.turrets[kind]
 art = preload("res://scripts/visual/unit_visual.gd").new()
 art.configure(str(ASSETS.catalog.turret_aliases[kind]))
 add_child(art)

func damage_value() -> float:
 return float(definition.damage) * pow(float(CampaignManager.combat.upgrade_damage_multiplier),level-1) * (1.0 + int(SaveManager.state.get("damage_level",0))*float(CampaignManager.combat.permanent_damage_step)) * (1.0+EconomyManager.modifier("turret_damage",battle.research_levels))

func range_value() -> float:
 return (float(definition.range) + (level-1)*float(CampaignManager.combat.upgrade_range_step))*(1.0+EconomyManager.modifier("turret_range",battle.research_levels))*battle.visibility_multiplier()

func fire_rate_value() -> float:
 return float(definition.fire_rate)*(1.0+EconomyManager.modifier("turret_rate",battle.research_levels))*battle.abilities.fire_multiplier()

func upgrade_cost() -> int:
 return int(ceil(float(definition.cost)*float(CampaignManager.combat.upgrade_cost_multiplier)*level))

func tick(delta: float) -> void:
 disabled_remaining = maxf(0.0,disabled_remaining-delta)
 if disabled_remaining > 0:
  target = null
  muzzle = 0.0
  queue_redraw()
  return
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
    battle.view.effect(position,"pulse",range_value(),Color(str(definition.color)))
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
  if enemy.ended or not enemy.automatically_targetable() or position.distance_squared_to(enemy.position) > range_value()*range_value():
   continue
  if selected == null or enemy.distance_remaining < selected.distance_remaining or (is_equal_approx(enemy.distance_remaining,selected.distance_remaining) and enemy.spawn_id < selected.spawn_id):
   selected = enemy
 return selected

func _draw() -> void:
 var color := Color(str(definition.get("color","65e0c0")))
 if disabled_remaining > 0:
  draw_arc(Vector2.ZERO,33,0,TAU,32,Color("ba9aff"),4)
  draw_string(ThemeDB.fallback_font,Vector2(-25,-38),"OFF %.1fs" % disabled_remaining,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ddbbff"))
 if is_instance_valid(art):
  art.sync(barrel_angle+PI/2,0.0,false,disabled_remaining > 0)
 preload("res://scripts/visual/weapon_effects.gd").flash(self,kind,barrel_angle,clampf(muzzle/.08,0,1))
 if kind == "laser" and muzzle > 0 and is_instance_valid(target) and not target.ended:
  draw_line(Vector2.ZERO,target.position-position,Color(color,0.3),7)
  draw_line(Vector2.ZERO,target.position-position,color,2)
 for i in level:
  draw_circle(Vector2(-8+i*8,20),2.5,color)
