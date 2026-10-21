extends Node2D
# Automatic target acquisition; battle resolves all impacts and rewards.
const ASSETS := preload("res://scripts/visual/visual_assets.gd")
const RULES := preload("res://scripts/game/placement_rules.gd")
var bearing := -PI/2
var emplacement := -1
var range_multiplier := 1.0
var redeploying := false
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
var acquisition_remaining := 0.0
var scan_remaining := 0.0

func apply_disable(duration: float) -> void:
 disabled_remaining = maxf(disabled_remaining,duration)

func configure(owner_battle: Node2D, type: String) -> void:
 battle = owner_battle
 kind = type
 definition = preload("res://scripts/core/weapon_technology.gd").turret(kind,battle.research_levels,battle.specializations)
 art = preload("res://scripts/visual/unit_visual.gd").new()
 art.configure(str(ASSETS.catalog.turret_aliases[kind]))
 add_child(art)

func damage_value() -> float:
 return float(definition.damage) * pow(float(CampaignManager.combat.upgrade_damage_multiplier),level-1) * (1.0 + int(SaveManager.state.get("damage_level",0))*float(CampaignManager.combat.permanent_damage_step)) * (1.0+EconomyManager.modifier("turret_damage",battle.research_levels))

func range_value() -> float:
 return (float(definition.range) + (level-1)*float(CampaignManager.combat.upgrade_range_step))*(1.0+EconomyManager.modifier("turret_range",battle.research_levels))*battle.visibility_multiplier()*range_multiplier

func fire_rate_value() -> float:
 return float(definition.fire_rate)*(1.0+EconomyManager.modifier("turret_rate",battle.research_levels))*battle.abilities.fire_multiplier()

func upgrade_cost() -> int:
 return int(ceil(float(definition.cost)*float(CampaignManager.combat.upgrade_cost_multiplier)*level))

func purchase_value() -> int:
 var value := int(definition.cost)
 for previous in range(1,level):
  value += int(ceil(float(definition.cost)*float(CampaignManager.combat.upgrade_cost_multiplier)*previous))
 return value

func set_emplacement(index: int) -> void:
 emplacement = index
 var data: Dictionary = battle.mission_data.emplacements[index]
 bearing = deg_to_rad(float(data.bearing_degrees))
 range_multiplier = float(data.range_multiplier)

func covers_point(point: Vector2) -> bool:
 return not redeploying and RULES.contains(position,point,range_value(),bearing,float(definition.traverse_degrees))

func rotate_bearing(steps: int) -> bool:
 if redeploying or battle.paused or battle.finished:
  return false
 bearing = wrapf(bearing+deg_to_rad(float(RULES.CONFIG.bearing_step_degrees))*steps,-PI,PI)
 target = null
 scan_remaining = 0.0
 battle.status_changed.emit()
 return true

func valid_target(unit: Node2D) -> bool:
 return is_instance_valid(unit) and not unit.ended and unit.automatically_targetable() and covers_point(unit.position)

func tick(delta: float) -> void:
 disabled_remaining = maxf(0.0,disabled_remaining-delta)
 muzzle = maxf(0.0,muzzle-delta)
 cooldown = maxf(0.0,cooldown-delta)
 if disabled_remaining > 0 or redeploying:
  target = null
  scan_remaining = 0
  acquisition_remaining = 0
  muzzle = 0.0
  queue_redraw()
  return
 scan_remaining -= delta
 if not is_instance_valid(target) or not valid_target(target):
  target = null
  scan_remaining = 0
 if scan_remaining <= 0:
  var candidate := acquire_target()
  # Stable lock: only a meaningfully closer threat interrupts a living target.
  if target != null and candidate != null and candidate != target and candidate.distance_remaining+float(CampaignManager.balance.target_switch_margin) >= target.distance_remaining:
   candidate = target
  if candidate != target:
   target = candidate
   acquisition_remaining = float(definition.acquisition_delay)
  scan_remaining = float(CampaignManager.balance.target_scan_interval)
 if is_instance_valid(target):
  var desired: float = (target.position-position).angle()
  var turn_rate := deg_to_rad(float(definition.turn_degrees))*(1.0+(level-1)*float(CampaignManager.balance.upgrade_turn_step))
  barrel_angle = rotate_toward(barrel_angle,desired,turn_rate*delta)
  acquisition_remaining = maxf(0.0,acquisition_remaining-delta)
  var aligned := absf(angle_difference(barrel_angle,desired)) <= deg_to_rad(float(definition.firing_arc_degrees))
  if acquisition_remaining <= 0 and aligned:
   var mode := str(definition.get("mode","projectile"))
   if mode == "laser":
    target.hit(damage_value()*delta*fire_rate_value()/float(definition.fire_rate),false,false,Vector2.INF,definition,&"automatic")
    muzzle = 0.06
   if cooldown <= 0:
    if mode == "emp":
     for enemy in battle.drones.get_children():
      if not enemy.ended and covers_point(enemy.position):
       enemy.apply_slow(float(definition.slow_factor),float(definition.status_duration))
       if float(definition.disable_duration) > 0:
        enemy.apply_disable(float(definition.disable_duration))
     battle.view.effect(position,"pulse",range_value(),Color(str(definition.color)))
    elif mode != "laser":
     battle.launch_projectile(self,target)
    cooldown = 1.0/fire_rate_value()
    muzzle = 0.08
    shots_fired += 1
 queue_redraw()

func acquire_target() -> Node2D:
 # Closest to the base by remaining path distance; spawn ID breaks ties.
 var selected: Node2D = null
 for enemy in battle.drones.get_children():
  if enemy.ended or not enemy.automatically_targetable() or not covers_point(enemy.position):
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
  art.sync(barrel_angle+PI/2,0.0,false,disabled_remaining > 0 or redeploying)
 preload("res://scripts/visual/weapon_effects.gd").flash(self,kind,barrel_angle,clampf(muzzle/.08,0,1))
 if kind == "laser" and muzzle > 0 and is_instance_valid(target) and not target.ended:
  draw_line(Vector2.from_angle(barrel_angle)*30,target.position-position,Color(color,0.19),8)
  draw_line(Vector2.from_angle(barrel_angle)*30,target.position-position,Color("f6eef5"),1.8)
 for i in level:
  draw_circle(Vector2(-8+i*8,20),2.5,color)
