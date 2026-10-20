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
var mission_id := 1
var run_id := ""
var mission_data: Dictionary
var health := 1000
var max_health := 1000
var research_levels: Dictionary = {}
var abilities: Node
var build_mode := false
var credits := 0
var earned := 0
var kills := 0
var finished := false
var paused := false
var game_speed := 1.0
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

func _ready() -> void:
 mission_data = CampaignManager.mission(mission_id)
 research_levels = SaveManager.state.get("research",{}).duplicate(true)
 max_health = int(mission_data.base_health)+int(EconomyManager.modifier("base_health",research_levels))
 health = max_health
 credits = int(mission_data.starting_credits)+int(EconomyManager.modifier("starting_credits",research_levels))
 for point in mission_data.slots:
  slots.append(Vector2(float(point[0]),float(point[1])))
 placed.resize(slots.size())
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
 add_child(spawner)
 spawner.configure(mission_data.waves,float(mission_data.build_time),mission_data.paths.size())
 spawner.spawn_requested.connect(spawn_enemy)
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
 if spawner.finished and living_count() == 0:
  _finish(true)

func living_count() -> int:
 var count := 0
 for enemy in drones.get_children():
  if not enemy.ended:
   count += 1
 return count

func spawn_enemy(kind: String, path_index: int = 0) -> Node2D:
 var enemy = DRONE.instantiate()
 spawn_identity += 1
 enemy.configure(CampaignManager.enemies[kind],mission_data.paths[path_index % mission_data.paths.size()],spawn_identity)
 enemy.breached.connect(_breached)
 enemy.destroyed.connect(_destroyed.bind(enemy))
 enemy.damaged.connect(func(at: Vector2): view.effect(at,"hit",12,Color("fff3be")))
 drones.add_child(enemy)
 return enemy

func _breached(damage: int) -> void:
 if finished:
  return
 health = maxi(0,health-damage)
 view.base_flash = 0.35
 view.effect(Vector2(560,595),"blast",60,Color("ff796b"))
 status_changed.emit()
 if health == 0:
  _finish(false)

func _destroyed(reward: int, enemy: Node2D) -> void:
 if finished:
  return
 kills += 1
 credits += reward
 earned += reward
 view.effect(enemy.position,"blast",32,enemy.tint)
 status_changed.emit()

func select_slot(index: int) -> void:
 if paused or finished or index < -1 or index >= slots.size():
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
 if paused or finished or selected_slot < 0 or placed[selected_slot] != null or not CampaignManager.turrets.has(kind) or not EconomyManager.unlocked(kind):
  return false
 var definition: Dictionary = CampaignManager.turrets[kind]
 if credits < int(definition.cost):
  return false
 var turret = TURRET.instantiate()
 turret.configure(self,kind)
 turret.position = slots[selected_slot]
 credits -= int(definition.cost)
 placed[selected_slot] = turret
 turrets.add_child(turret)
 view.effect(turret.position,"build",40,Color(str(definition.color)))
 status_changed.emit()
 selection_changed.emit()
 return true

func upgrade_selected() -> bool:
 if paused or finished or selected_slot < 0:
  return false
 var turret := placed[selected_slot]
 if turret == null or turret.level >= int(CampaignManager.combat.max_turret_level):
  return false
 var cost: int = turret.upgrade_cost()
 if credits < cost:
  return false
 credits -= cost
 turret.level += 1
 view.effect(turret.position,"build",48,Color("65e0c0"))
 status_changed.emit()
 selection_changed.emit()
 return true

func launch_projectile(turret: Node2D, target: Node2D) -> void:
 var projectile = PROJECTILE.instantiate()
 projectile.configure(self,turret,target)
 projectiles.add_child(projectile)
 shots_fired += 1

func launch_player_projectile(direction: Vector2) -> void:
 var projectile = PROJECTILE.instantiate()
 projectile.configure_manual(self,direction)
 projectiles.add_child(projectile)
 shots_fired += 1

func resolve_impact(projectile: Node2D) -> void:
 # A projectile consumes itself before calling here. Splash replaces direct damage.
 impacts += 1
 if projectile.splash_radius > 0:
  view.effect(projectile.destination,"blast",projectile.splash_radius,projectile.tint)
  for enemy in drones.get_children():
   if not enemy.ended and enemy.position.distance_squared_to(projectile.destination) <= projectile.splash_radius*projectile.splash_radius:
    enemy.hit(projectile.damage_for(enemy))
    if projectile.manual:
     player_turret.notify_hit(projectile.critical)
 elif is_instance_valid(projectile.target) and not projectile.target.ended:
  projectile.target.hit(projectile.damage_for(projectile.target))
  if projectile.manual:
   player_turret.notify_hit(projectile.critical)

func start_wave() -> bool:
 return not paused and not finished and spawner.start_early()

func effective_speed() -> float:
 return 0.25 if build_mode else game_speed

func close_build_mode() -> void:
 build_mode = false
 selected_slot = -1
 selection_changed.emit()
 status_changed.emit()

func toggle_speed() -> void:
 if finished or build_mode:
  return
 game_speed = 2.0 if game_speed == 1.0 else 1.0
 status_changed.emit()

func set_paused(value: bool) -> void:
 paused = value
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
 finished = true
 set_paused(true)
 completed.emit(victory,{"mission_id":mission_id,"run_id":run_id,"victory":victory,"kills":kills,"health":health,"waves":spawner.wave+1,"earned":earned,"shots":shots_fired,"manual_shots":player_turret.shots_fired,"manual_hits":player_turret.hits})
