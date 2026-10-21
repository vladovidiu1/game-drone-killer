extends Node
# Reusable guided drill inside the actual Mission-1 battlefield/controllers.
# This rehearsal never owns a campaign result; Main resumes the persisted live token.
signal changed
signal finished(status: String)
static var DATA: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tutorial.json"))
var battle: Node2D
var phase := 0
var clock := 0.0
var elapsed := 0.0
var active := true
var practice_hit := false
var group_hit := false
var incoming_sector := "EAST"
var group_spawned := false
var group_resolved := false
var assistance := 0
var practice: WeakRef
var error := ""

func configure(owner_battle: Node2D) -> void:
 battle = owner_battle
 battle.guided = true
 battle.player_controls.clear()
 spawn_practice()

func description() -> Dictionary:
 return DATA.steps[phase]

func enter(index: int) -> void:
 phase = index
 elapsed = 0
 if phase in [1,2,3,5,7]:
  battle.close_build_mode()
 if phase == 3 and battle.player_turret.reloads_completed == 0 and battle.player_turret.reload_remaining <= 0:
  battle.player_turret.ammo = mini(battle.player_turret.ammo,int(DATA.demo_rounds))
  battle.status_changed.emit()
 if phase == 5 and not group_spawned:
  spawn_group()
 changed.emit()

func tick(delta: float) -> void:
 if not active:
  return
 clock += delta
 elapsed += delta
 if phase <= 2 and not practice_hit and (practice == null or not is_instance_valid(practice.get_ref()) or practice.get_ref().ended):
  spawn_practice()
 match phase:
  0:
   if elapsed >= float(DATA.intro_seconds):
    enter(1)
  1:
   if battle.player_controls.human_aim_movements > 0:
    enter(2)
  2:
   if practice_hit:
    enter(3)
  3:
   if battle.player_turret.reloads_completed > 0:
    enter(4)
  4:
   if first_turret() != null:
    enter(5)
   else:
    reserve_supply(int(CampaignManager.turrets.machine_gun.cost))
  5:
   if elapsed >= float(DATA.sector_min_seconds) and (group_hit or group_resolved):
    enter(6)
  6:
   var turret := first_turret()
   if turret == null:
    enter(4)
   else:
    var upgraded := false
    for unit in battle.placed:
     upgraded = upgraded or is_instance_valid(unit) and unit.level >= 2
    if upgraded:
     enter(7)
    else:
     reserve_supply(turret.upgrade_cost())

func first_turret() -> Node2D:
 for turret in battle.placed:
  if is_instance_valid(turret):
   return turret
 return null

func reserve_supply(cost: int) -> void:
 # Isolated practice supply; the live Battle starts from normal mission data.
 if battle.credits < cost:
  assistance += cost-battle.credits
  battle.credits = cost
  battle.status_changed.emit()

func training_unit(path_index: int, group: bool) -> Node2D:
 var unit: Node2D = battle.spawn_enemy("scout",path_index)
 unit.training_drone = true
 unit.set_meta("tutorial_group",group)
 unit.reward = 0
 unit.damage = 0
 unit.designation = "DRILL"
 unit.brain.data = unit.brain.data.duplicate(true)
 unit.brain.data.erase("mobility")
 unit.damaged.connect(func(_at: Vector2):
  if unit.last_damage_source == &"manual":
   if group:
    group_hit = true
   else:
    practice_hit = true)
 unit.destroyed.connect(func(_reward: int):
  if group:
   group_resolved = true)
 unit.breached.connect(func(_damage: int):
  if group:
   group_resolved = true)
 return unit

func spawn_practice() -> void:
 var unit := training_unit(0,false)
 unit.position = Vector2(500,420)
 unit.route.assign([unit.position,Vector2(540,550),Vector2(560,600)])
 unit.waypoint = 1
 unit.distance_remaining = 210
 unit.speed = float(DATA.practice_speed)
 practice = weakref(unit)

func spawn_group() -> void:
 group_spawned = true
 var first := first_turret()
 var defended := str(battle.mission_data.emplacements[first.emplacement].sector) if first != null else "WEST"
 var sector := "EAST" if defended == "WEST" else "WEST"
 incoming_sector = sector
 var path_index := 0
 for index in battle.mission_data.approaches.sectors.size():
  if str(battle.mission_data.approaches.sectors[index]) == sector:
   path_index = index
   break
 for index in 3:
  var unit := training_unit(path_index,true)
  unit.position += Vector2(index*16,-index*18)
  unit.speed = float(DATA.group_speed)
  unit.set_meta("tutorial_sector",sector)
 battle.view.effect(Vector2(battle.mission_data.paths[path_index][0][0],battle.mission_data.paths[path_index][0][1]),"pulse",40,Color("ff9c42"))

func skip_intro() -> void:
 if active and phase == 0:
  enter(1)

func finish(status: String) -> bool:
 if not active or status not in ["completed","skipped"]:
  return false
 var previous: Dictionary = SaveManager.settings.duplicate(true)
 SaveManager.settings.tutorial_status = status
 if not SaveManager.save_settings():
  SaveManager.settings = previous
  error = "Could not save tutorial status. Try again: "+SaveManager.last_error
  changed.emit()
  return false
 active = false
 battle.player_controls.clear()
 finished.emit(status)
 return true

func acknowledge() -> void:
 if phase == 7:
  finish("completed")
