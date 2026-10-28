extends Node2D
signal completed(victory: bool, stats: Dictionary)
signal status_changed
signal selection_changed
const DRONE := preload("res://scenes/drone.tscn")
const TURRET := preload("res://scenes/turret.tscn")
const PROJECTILE := preload("res://scenes/projectile.tscn")
const PLAYER_TURRET := preload("res://scenes/player_turret.tscn")
const PLAYER_INPUT := preload("res://scripts/game/player_input.gd")
const WAVES := preload("res://scripts/game/wave_spawner.gd")
var guided := false
var tutorial: Node
var tutorial_overlay: Control
var attack_seed := -1
var performance: RefCounted
var director: RefCounted
var mission_id := 1
var run_id := ""
var mission_data: Dictionary
var health := 1000
var max_health := 1000
var research_levels: Dictionary = {}
var specializations: Dictionary = {}
var movement: RefCounted
var coverage_visible := false
var abilities: Node
var build_mode := false
var credits := 0
var earned := 0
var kills := 0
var finished := false
var paused := false
var selected_slot := -1
var slots: Array[Vector2] = []
var placed: Array[Node2D] = []
var view: Node2D
var drones: Node2D
var turrets: Node2D
var projectiles: Node2D
var player_turret: Node2D
var player_controls: Node
var spawner: Node
var spawn_identity := 0
var refresh_timer := 0.0
var shots_fired := 0
var impacts := 0
var elapsed := 0.0
var enemy_actions := 0
var weakpoint_hits := 0
var component_hits := 0
var component_destructions := 0
var support_spawned := 0
var environmental_pulses := 0

func visibility_multiplier() -> float:
 return float(mission_data.get("environment",{}).get("range_multiplier",1.0))

func environment_warning() -> float:
 var condition: Dictionary = mission_data.get("environment",{})
 if condition.get("kind", "clear") != "interference":
  return 0.0
 var remaining := float(condition.period)-fmod(elapsed,float(condition.period))
 return remaining if remaining <= float(condition.warning) else 0.0

func tick_environment(delta: float) -> void:
 var condition: Dictionary = mission_data.get("environment",{})
 var before := elapsed
 elapsed += delta
 if condition.get("kind", "clear") == "interference" and int(elapsed/float(condition.period)) > int(before/float(condition.period)):
  environmental_pulses += 1
  for turret in turrets.get_children():
   turret.apply_disable(float(condition.duration))
  view.effect(Vector2(560,400),"blast",300,Color("9a96ff"))

func _ready() -> void:
 mission_data = CampaignManager.mission(mission_id)
 performance = preload("res://scripts/game/battle_performance.gd").new()
 performance.configure(self)
 research_levels = SaveManager.state.get("research",{}).duplicate(true)
 specializations = SaveManager.state.get("turret_specializations",{}).duplicate(true)
 max_health = int(mission_data.base_health)+int(EconomyManager.modifier("base_health",research_levels))
 health = max_health
 credits = int(mission_data.starting_credits)+int(EconomyManager.modifier("starting_credits",research_levels))
 for point in mission_data.slots:
  slots.append(Vector2(float(point[0]),float(point[1])))
 placed.resize(slots.size())
 movement = preload("res://scripts/game/turret_redeployment.gd").new()
 movement.configure(self)
 view = Node2D.new()
 view.set_script(preload("res://scripts/game/battle_view.gd"))
 add_child(view)
 drones = Node2D.new()
 drones.name = "Drones"
 add_child(drones)
 turrets = Node2D.new()
 turrets.name = "Turrets"
 add_child(turrets)
 projectiles = Node2D.new()
 projectiles.name = "Projectiles"
 add_child(projectiles)
 spawner = WAVES.new()
 spawner.hold_initial = true
 add_child(spawner)
 director = preload("res://scripts/game/tactical_attack_director.gd").new()
 if attack_seed < 0:
  attack_seed = int(Time.get_ticks_usec()) ^ int(Crypto.new().generate_random_bytes(4).decode_u32(0))
  for argument in OS.get_cmdline_user_args():
   if argument.begins_with("--attack-seed=") and argument.get_slice("=",1).is_valid_int():
    attack_seed = int(argument.get_slice("=",1))
 director.configure(self,attack_seed)
 spawner.attack_announced.connect(func(_plan: Dictionary): AudioManager.combat_cue("radar"))
 spawner.configure(mission_data.waves,float(mission_data.build_time),mission_data.paths.size(),director)
 spawner.spawn_requested.connect(spawn_directed_enemy)
 spawner.changed.connect(func(): status_changed.emit())
 abilities = preload("res://scripts/game/tactical_abilities.gd").new()
 abilities.configure(self)
 add_child(abilities)
 player_turret = PLAYER_TURRET.instantiate()
 player_turret.configure(self,EconomyManager.primary_stats(research_levels))
 add_child(player_turret)
 player_turret.state_changed.connect(func(): status_changed.emit())
 player_controls = PLAYER_INPUT.new()
 player_controls.configure(self)
 add_child(player_controls)
 status_changed.emit()

func _physics_process(delta: float) -> void:
 if paused or finished:
  return
 simulate(delta*effective_speed())

func simulate(delta: float) -> void:
 if paused or finished:
  return
 movement.tick(delta)
 performance.tick()
 if guided:
  if is_instance_valid(tutorial):
   tutorial.tick(delta)
 else:
  tick_environment(delta)
  abilities.tick(delta)
  spawner.tick(delta,living_count())
 for enemy in drones.get_children():
  enemy.tick(delta)
  if finished:
   return
 player_turret.tick(delta)
 player_turret.get_node("Artwork").queue_redraw()
 for turret in turrets.get_children():
  turret.tick(delta)
 for projectile in projectiles.get_children():
  projectile.tick(delta)
 view.tick(delta)
 refresh_timer -= delta
 if refresh_timer <= 0:
  refresh_timer = 0.1
  status_changed.emit()
 if not guided and spawner.finished and living_count() == 0:
  _finish(true)

func living_count() -> int:
 var count := 0
 for enemy in drones.get_children():
  if not enemy.ended:
   count += 1
 return count

func spawn_directed_enemy(kind: String, path_index: int) -> void:
 var enemy := spawn_enemy(kind,path_index)
 enemy.set_meta("attack_wave",spawner.wave)
 enemy.set_meta("attack_sector",str(mission_data.approaches.sectors[path_index]))

func _drone_breached(damage: int, enemy: Node2D) -> void:
 if enemy.training_drone:
  return
 if not finished and not enemy.get_meta("breach_recorded",false):
  enemy.set_meta("breach_recorded",true)
  performance.counters.breaches += 1
  director.record(enemy,"breaches")
 else:
  return
 _breached(damage)

func spawn_enemy(kind: String, path_index: int = 0) -> Node2D:
 var enemy = DRONE.instantiate()
 spawn_identity += 1
 enemy.enemy_type = kind
 enemy.configure(CampaignManager.enemies[kind],mission_data.paths[path_index % mission_data.paths.size()],spawn_identity)
 enemy.speed = minf(float(CampaignManager.balance.maximum_drone_speed),enemy.speed*float(mission_data.get("speed_multiplier",1.0))*float(CampaignManager.balance.movement_multiplier))
 enemy.brain = preload("res://scripts/game/enemy_brain.gd").new()
 enemy.brain.configure(enemy,self,CampaignManager.enemies[kind])
 var rig := preload("res://scripts/game/drone_components.gd").new()
 if rig.configure(enemy,kind,mission_id):
  enemy.components = rig
  var markers := preload("res://scripts/visual/component_markers.gd").new()
  markers.rig = rig
  enemy.component_markers = markers
  enemy.add_child(markers)
 enemy.breached.connect(_drone_breached.bind(enemy))
 enemy.destroyed.connect(_destroyed.bind(enemy))
 enemy.damaged.connect(func(at: Vector2): view.effect(at,"hit",12,Color("fff3be")))
 drones.add_child(enemy)
 if enemy.brain.boss:
  view.combat_fx.announce("HOSTILE COMMAND / "+enemy.display_name.to_upper())
 return enemy

func spawn_support(kind: String, parent_unit: Node2D) -> Node2D:
 if not director.reserve_support(kind,parent_unit):
  return null
 var child := spawn_enemy(kind,0)
 child.is_support = true
 if parent_unit.has_meta("attack_wave"):
  child.set_meta("attack_wave",parent_unit.get_meta("attack_wave"))
  child.set_meta("attack_sector",parent_unit.get_meta("attack_sector"))
  director.record(child,"supports")
 child.reward = int(child.reward*int(preload("res://scripts/core/economy_config.gd").values.battle.support_bounty_percent)/100.0)
 child.route.assign([parent_unit.position,Vector2(parent_unit.position.x,minf(550,maxf(450,parent_unit.position.y+30))),Vector2(560,600)])
 child.position = parent_unit.position+Vector2((support_spawned%3-1)*25,15)
 var bounds: Array = mission_data.approaches.movement_bounds
 child.position = child.position.clamp(Vector2(bounds[0],bounds[1]),Vector2(bounds[0]+bounds[2],bounds[1]+bounds[3]))
 child.waypoint = 1
 child.distance_remaining = child.position.distance_to(child.route[1])+child.route[1].distance_to(child.route[2])
 support_spawned += 1
 return child

func _breached(damage: int) -> void:
 if finished:
  return
 performance.base_damage(mini(health,maxi(0,damage)))
 health = maxi(0,health-damage)
 view.base_flash = 0.12 if SaveManager.settings.get("reduced_effects",false) else 0.35
 view.combat_fx.base_damaged(float(health)/max_health)
 view.effect(Vector2(560,595),"blast",60,Color("ff796b"))
 status_changed.emit()
 if health == 0:
  _finish(false)

func _destroyed(reward: int, enemy: Node2D) -> void:
 if finished or not is_instance_valid(enemy) or bool(enemy.get_meta("bounty_paid",false)):
  return
 enemy.set_meta("bounty_paid",true)
 if enemy.training_drone:
  view.combat_fx.destroyed(enemy)
  view.effect(enemy.position,"blast",24,enemy.tint)
  return
 director.record(enemy,"kills")
 reward = maxi(0,reward)
 kills += 1
 AudioManager.combat_cue("explosion")
 performance.counters.kills += 1
 if enemy.last_damage_source == &"manual":
  performance.counters.manual_kills += 1
 credits += reward
 earned += reward
 view.destruction.snapshot(enemy)
 view.combat_fx.destroyed(enemy)
 view.effect(enemy.position,"blast",72 if enemy.brain.boss else 46 if enemy.body_scale >= 1.3 else 32,enemy.tint)
 status_changed.emit()

func select_slot(index: int) -> void:
 if paused or finished or index < -1 or index >= slots.size():
  return
 if movement.source >= 0 and not movement.active and index >= 0:
  movement.choose(index)
  view.queue_redraw()
  return
 selected_slot = index
 build_mode = index >= 0
 selection_changed.emit()
 status_changed.emit()
 view.queue_redraw()

func select_at(point: Vector2) -> bool:
 if paused or finished:
  return false
 for index in slots.size():
  if point.distance_to(slots[index]) <= float(CampaignManager.combat.slot_touch_radius):
   select_slot(index)
   return true
 return false

func build_turret(kind: String) -> bool:
 if paused or finished or selected_slot < 0 or placed[selected_slot] != null or movement.reserved(selected_slot) or not CampaignManager.turrets.has(kind) or not EconomyManager.unlocked(kind):
  return false
 var definition: Dictionary = CampaignManager.turrets[kind]
 if credits < int(definition.cost):
  return false
 var turret = TURRET.instantiate()
 turret.configure(self,kind)
 turret.position = slots[selected_slot]
 turret.set_emplacement(selected_slot)
 credits -= int(definition.cost)
 placed[selected_slot] = turret
 turrets.add_child(turret)
 view.effect(turret.position,"build",40,Color(str(definition.color)))
 AudioManager.combat_cue("build")
 status_changed.emit()
 selection_changed.emit()
 return true

func upgrade_selected() -> bool:
 if paused or finished or selected_slot < 0:
  return false
 var turret := placed[selected_slot]
 if turret == null or turret.redeploying or turret.level >= int(CampaignManager.combat.max_turret_level):
  return false
 var cost: int = turret.upgrade_cost()
 if credits < cost:
  return false
 credits -= cost
 turret.level += 1
 view.effect(turret.position,"build",48,Color("65e0c0"))
 AudioManager.combat_cue("build")
 status_changed.emit()
 selection_changed.emit()
 return true

func launch_projectile(turret: Node2D, target: Node2D) -> void:
 var projectile = PROJECTILE.instantiate()
 projectile.configure(self,turret,target)
 AudioManager.combat_cue("shot")
 projectiles.add_child(projectile)
 view.combat_fx.shot(turret.position+Vector2.from_angle(turret.barrel_angle)*32,Vector2.from_angle(turret.barrel_angle),turret.kind,projectile.tint)
 shots_fired += 1

func launch_player_projectile(direction: Vector2) -> void:
 var projectile = PROJECTILE.instantiate()
 projectile.configure_manual(self,direction)
 performance.shot(projectile)
 projectiles.add_child(projectile)
 view.combat_fx.shot(projectile.position,direction,projectile.visual_kind,projectile.tint)
 shots_fired += 1

func resolve_impact(projectile: Node2D) -> void:
 # A projectile consumes itself before calling here. Splash replaces direct damage.
 impacts += 1
 AudioManager.combat_cue("impact")
 view.combat_fx.impact(projectile.destination,projectile.visual_kind,projectile.tint,projectile.splash_radius,projectile.critical)
 if projectile.splash_radius > 0:
  if projectile.visual_kind != "emp":
   view.effect(projectile.destination,"blast",projectile.splash_radius,projectile.tint)
  for enemy in drones.get_children():
   if not enemy.ended and (enemy == projectile.target or enemy.position.distance_squared_to(projectile.destination) <= projectile.splash_radius*projectile.splash_radius):
    projectile.apply_payload(enemy,projectile.manual and enemy == projectile.target,true)
    if projectile.manual:
     player_turret.notify_hit(projectile.critical or projectile.precision_critical)
 elif is_instance_valid(projectile.target) and not projectile.target.ended:
  projectile.apply_payload(projectile.target,projectile.manual)
  if projectile.manual:
   player_turret.notify_hit(projectile.critical or projectile.precision_critical)

func start_wave() -> bool:
 return not guided and not paused and not finished and spawner.start_early()

func effective_speed() -> float:
 return 1.0

func close_build_mode() -> void:
 if is_instance_valid(movement) and not movement.active and movement.source >= 0:
  movement.cancel(false)
 build_mode = false
 selected_slot = -1
 selection_changed.emit()
 status_changed.emit()

func set_paused(value: bool) -> void:
 paused = value
 AudioManager.set_battle_paused(value)
 if value and is_instance_valid(player_controls):
  player_controls.clear()
  close_build_mode()
 if is_instance_valid(view):
  view.queue_redraw()
 status_changed.emit()

func _unhandled_input(event: InputEvent) -> void:
 if paused or finished:
  return
 if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
  var point: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
  if select_at(point):
   get_viewport().set_input_as_handled()
   return
 player_controls.handle_unhandled(event)

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(spawner) and not finished:
  set_paused(true)

func _finish(victory: bool) -> void:
 if finished:
  return
 movement.cancel(false)
 director.finish(victory)
 finished = true
 set_paused(true)
 performance.tick()
 completed.emit(victory,{"performance":performance.snapshot(),"mission_id":mission_id,"run_id":run_id,"victory":victory,"kills":kills,"health":health,"waves":spawner.wave+1,"earned":earned,"shots":shots_fired,"manual_shots":player_turret.shots_fired,"manual_hits":player_turret.hits,"seconds":elapsed,"enemy_actions":enemy_actions,"weakpoint_hits":weakpoint_hits,"attack_seed":attack_seed,"tactical_plans":director.plans.duplicate(true),"component_hits":component_hits,"component_destructions":component_destructions,"redeployments":movement.moves,"redeploy_spent":movement.spent,"redeploy_refunded":movement.refunded})

func _exit_tree() -> void:
 if is_instance_valid(movement):
  movement.cancel(false)
