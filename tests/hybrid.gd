extends Node
const BATTLE := preload("res://scenes/gameplay.tscn")
var checks := 0
var failures := 0
var app: Control

func check(value: bool, message: String) -> void:
 checks += 1
 if value:
  print("PASS: "+message)
 else:
  failures += 1
  push_error("FAIL: "+message)

func arena() -> Node2D:
 var battle = BATTLE.instantiate()
 add_child(battle)
 battle.set_physics_process(false)
 battle.spawner.timer = 10000.0
 return battle

func mouse_button(point: Vector2, held: bool) -> void:
 var event := InputEventMouseButton.new()
 event.position = point
 event.button_index = MOUSE_BUTTON_LEFT
 event.pressed = held
 get_viewport().push_input(event,true)

func mouse_move(point: Vector2) -> void:
 var event := InputEventMouseMotion.new()
 event.position = point
 get_viewport().push_input(event,true)

func touch(index: int, point: Vector2, held: bool) -> void:
 var event := InputEventScreenTouch.new()
 event.index = index
 event.position = point
 event.pressed = held
 get_viewport().push_input(event,true)

func drag(index: int, point: Vector2) -> void:
 var event := InputEventScreenDrag.new()
 event.index = index
 event.position = point
 get_viewport().push_input(event,true)

func key(code: Key) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.pressed = true
 get_viewport().push_input(event,true)

func _ready() -> void:
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 run.call_deferred()

func run() -> void:
 SaveManager.new_campaign()
 var battle := arena()
 var cannon: Node2D = battle.player_turret
 check(cannon.name == "PlayerTurret" and battle.placed.size() == 5 and battle.turrets.get_child_count() == 0,"primary cannon is a dedicated scene outside all five slots")
 check(cannon.ammo == 60 and cannon.position.y > 560,"primary cannon starts loaded at bottom center")
 var enemy: Node2D = battle.spawn_enemy("scout")
 enemy.position = cannon.position+Vector2(0,-120)
 for i in 90:
  cannon.tick(1.0/60.0)
 check(cannon.shots_fired == 0 and enemy.health == 40,"primary never acquires targets or fires without input")
 battle.player_controls.aim_at(cannon.position+Vector2(-180,-180))
 var angle: float = cannon.barrel_angle
 cannon.tick(1.0/60.0)
 check(absf(angle_difference(angle,cannon.barrel_angle)) > 0.01 and absf(angle_difference(cannon.barrel_angle,(cannon.aim_point-cannon.position).angle())) > 0.01,"rotation responds smoothly rather than snapping")
 cannon.set_aim(cannon.position+Vector2.UP*300)
 cannon.barrel_angle = -PI/2
 battle.player_controls.set_fire(&"test",true)
 cannon.tick(1.0/60.0)
 check(cannon.ammo == 59 and cannon.shots_fired == 1,"trigger consumes exactly one round per shot")
 check(cannon.muzzle_flash > 0 and cannon.recoil > 0,"shots drive muzzle flash and recoil feedback")
 var bullet: Node2D = battle.projectiles.get_child(0)
 check(bullet.manual and bullet.speed == 850 and bullet.damage == 15,"manual projectiles use the requested configurable speed and damage")
 bullet.tick(0.2)
 check(enemy.health == 25 and bullet.consumed and cannon.hits == 1,"straight projectile collides and applies 15 damage")
 bullet.impact()
 bullet.tick(0.2)
 check(enemy.health == 25 and cannon.hits == 1,"manual projectile cannot hit twice")
 check(cannon.hit_confirm > 0 and not battle.view.effects.is_empty(),"manual hits create crosshair and impact feedback")
 # Automatic and manual shots share the normal enemy lifecycle.
 battle.select_slot(4)
 check(battle.build_turret("machine_gun"),"secondary turret can be built while manual trigger is held")
 var turret: Node2D = battle.placed[4]
 turret.tick(0.25)
 check(turret.shots_fired == 1,"automatic turret still acquires and shoots with primary active")
 bullet = battle.projectiles.get_child(battle.projectiles.get_child_count()-1)
 bullet.tick(0.2)
 check(enemy.health == 15,"automatic damage stacks with manual damage")
 cannon.tick(0.2)
 bullet = battle.projectiles.get_child(battle.projectiles.get_child_count()-1)
 bullet.tick(0.2)
 check(enemy.ended and battle.kills == 1 and battle.credits == 407,"combined attacks destroy drone and award credits once")
 battle.player_controls.set_fire(&"test",false)
 var shots: int = cannon.shots_fired
 for i in 30:
  cannon.tick(1.0/60.0)
 check(cannon.shots_fired == shots,"releasing trigger stops continuous fire")
 battle.queue_free()
 await get_tree().process_frame

 battle = arena()
 cannon = battle.player_turret
 battle.player_controls.set_fire(&"test",true)
 for frame in 700:
  cannon.tick(1.0/60.0)
  if cannon.ammo == 0:
   break
 check(cannon.shots_fired == 60 and cannon.ammo == 0,"holding fire depletes all 60 rounds")
 check(cannon.reload_remaining == 2.0,"empty magazine starts two-second reload automatically")
 battle.player_controls.set_fire(&"test",false)
 for frame in 60:
  cannon.tick(1.0/60.0)
 check(cannon.ammo == 0 and is_equal_approx(cannon.reload_progress(),0.5),"reload halfway progress is visible and no rounds refill early")
 battle.set_paused(true)
 var reload_before: float = cannon.reload_remaining
 battle.simulate(0.5)
 check(cannon.reload_remaining == reload_before,"pause freezes reload countdown")
 battle.set_paused(false)
 for frame in 60:
  cannon.tick(1.0/60.0)
 check(cannon.ammo == 60 and cannon.reload_remaining == 0,"reload refills magazine after two simulation seconds")
 check(not cannon.request_reload(),"full magazine cannot reload")
 battle.player_controls.set_fire(&"test",true)
 cannon.tick(0.2)
 check(cannon.request_reload(),"partial magazine can be reloaded manually")
 check(not cannon.request_reload(),"reload cannot be restarted mid-cycle")
 shots = cannon.shots_fired
 cannon.tick(1.0)
 check(cannon.shots_fired == shots,"held trigger cannot fire during reload")
 battle._physics_process(1.0)
 check(cannon.ammo == 60 and cannon.reload_remaining == 0,"normal speed advances primary reload with the rest of combat")
 battle.set_paused(true)
 check(not cannon.trigger_held and battle.player_controls.fire_sources.is_empty(),"pause clears all held firing sources")
 battle.set_paused(false)
 cannon.tick(0.3)
 check(cannon.shots_fired == shots,"resume requires fresh fire input")
 battle.queue_free()
 await get_tree().process_frame

 battle = arena()
 cannon = battle.player_turret
 var near: Node2D = battle.spawn_enemy("scout")
 var far: Node2D = battle.spawn_enemy("scout")
 near.position = cannon.position+Vector2(0,-100)
 far.position = cannon.position+Vector2(0,-200)
 battle.launch_player_projectile(Vector2.UP)
 bullet = battle.projectiles.get_child(0)
 bullet.tick(0.4)
 check(near.health == 25 and far.health == 40,"swept manual collision hits nearest drone on the ray, not every drone")
 near.position.x += 150
 far.position = cannon.position+Vector2(0,-450)
 battle.launch_player_projectile(Vector2.UP)
 bullet = battle.projectiles.get_child(battle.projectiles.get_child_count()-1)
 bullet.tick(1.0)
 check(bullet.consumed and far.health == 40 and cannon.position.distance_to(bullet.position) <= 400.01,"manual rounds expire at 400-unit range")
 far.position = cannon.position+Vector2(60,-180)
 battle.launch_player_projectile(Vector2.UP)
 bullet = battle.projectiles.get_child(battle.projectiles.get_child_count()-1)
 bullet.tick(0.4)
 check(far.health == 40,"off-axis aim misses instead of homing toward an enemy")
 battle.queue_free()
 await get_tree().process_frame

 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 app._play()
 await get_tree().process_frame
 await get_tree().process_frame
 battle = app.battle
 battle.set_physics_process(false)
 battle.spawner.timer = 10000.0
 cannon = battle.player_turret
 var weapon: Control = app.hud.player_panel
 var visible := get_viewport().get_visible_rect()
 check(visible.encloses(weapon.fire_button.get_global_rect()) and visible.encloses(weapon.reload_button.get_global_rect()),"FIRE and Reload fit 1280x720 and remain visible")
 var aim_target := cannon.position+Vector2(100,-230)
 mouse_move(aim_target)
 check(cannon.aim_point.is_equal_approx(aim_target),"desktop mouse position controls aiming")
 mouse_button(aim_target,true)
 battle.simulate(1.0/60.0)
 check(cannon.shots_fired == 1 and cannon.trigger_held,"unhandled left mouse press fires")
 mouse_button(app.hud.stat_cards.wave.get_global_rect().get_center(),false)
 check(not cannon.trigger_held,"global mouse release over UI prevents stuck firing")
 mouse_button(aim_target,true)
 mouse_move(app.hud.stat_cards.wave.get_global_rect().get_center())
 check(not cannon.trigger_held,"moving a held mouse over UI cancels world firing")
 mouse_button(app.hud.stat_cards.wave.get_global_rect().get_center(),false)
 var prior_aim: Vector2 = cannon.aim_point
 mouse_button(app.hud.build_buttons.cannon.get_global_rect().get_center(),true)
 mouse_button(app.hud.build_buttons.cannon.get_global_rect().get_center(),false)
 check(not cannon.trigger_held and cannon.aim_point == prior_aim,"UI interaction never starts desktop aiming or firing")
 mouse_button(battle.slots[0],true)
 mouse_button(battle.slots[0],false)
 await get_tree().process_frame
 check(battle.selected_slot == 0 and not cannon.trigger_held,"slot selection takes priority over manual mouse fire")
 key(KEY_R)
 check(cannon.reload_remaining == 2.0,"R key starts a partial-magazine reload")
 battle.simulate(0.5)
 check(weapon.ammo_label.text.begins_with("RELOAD") and weapon.progress.value > 0 and weapon.progress.value < 100,"HUD shows reload text and progress")
 battle.simulate(1.5)
 var start_point := Vector2(160,400)
 touch(10,start_point,true)
 check(battle.player_controls.aim_finger == 10,"left-zone touch owns aiming gesture")
 prior_aim = cannon.aim_point
 var fire_center: Vector2 = weapon.fire_button.get_global_rect().get_center()
 touch(11,fire_center,true)
 check(cannon.trigger_held and battle.player_controls.aim_finger == 10,"second finger holds FIRE while first owns aim")
 drag(10,start_point+Vector2(70,-30))
 check(not cannon.aim_point.is_equal_approx(prior_aim),"owned aim drag adjusts direction while firing")
 touch(12,app.hud.build_buttons.machine_gun.get_global_rect().get_center(),true)
 touch(12,app.hud.build_buttons.machine_gun.get_global_rect().get_center(),false)
 check(battle.placed[0] != null and cannon.trigger_held and battle.player_controls.aim_finger == 10,"third finger builds automatic defense during aim and fire")
 shots = cannon.shots_fired
 battle.simulate(0.2)
 check(cannon.shots_fired > shots and cannon.ammo < 60,"touch hold fires continuously through shared combat logic")
 touch(13,Vector2(800,200),true)
 drag(13,Vector2(700,180))
 check(battle.player_controls.aim_finger == 10,"unrelated right-side touch cannot steal aim")
 touch(13,Vector2(700,180),false)
 touch(11,fire_center,false)
 check(not cannon.trigger_held and battle.player_controls.aim_finger == 10,"FIRE release stops shots without dropping the aim finger")
 touch(10,start_point,false)
 check(battle.player_controls.aim_finger == -1,"aim release clears ownership")
 touch(14,fire_center,true)
 key(KEY_ESCAPE)
 check(battle.paused and not cannon.trigger_held,"ESC pauses battle and releases FIRE")
 app._pause()
 battle.simulate(0.2)
 check(not cannon.trigger_held,"resume does not resume a stale touch hold")
 touch(14,fire_center,false)
 var old_battle := battle
 app._play()
 await get_tree().process_frame
 battle = app.battle
 battle.set_physics_process(false)
 cannon = battle.player_turret
 check(cannon.ammo == 60 and cannon.reload_remaining == 0 and cannon.shots_fired == 0 and not cannon.trigger_held,"retry resets primary ammo, reload and trigger")
 check(battle.player_controls.aim_finger == -1 and battle.turrets.get_child_count() == 0,"retry clears input ownership and temporary defenses")
 check(not is_instance_valid(old_battle),"retry releases previous battle scene")
 # Play a complete mission using ordinary player input intentions and bought defenses.
 battle.spawner.timer = float(battle.mission_data.build_time)
 battle.select_slot(0)
 battle.build_turret("machine_gun")
 battle.select_slot(1)
 battle.build_turret("cannon")
 battle.select_slot(2)
 battle.build_turret("machine_gun")
 var auto_shots := 0
 for frame in 22000:
  if app.screen == "results":
   break
  if battle.spawner.intermission:
   battle.start_wave()
  for slot in [3,4]:
   if battle.placed[slot] == null:
    battle.select_slot(slot)
    battle.build_turret("cannon" if slot == 3 else "machine_gun")
  for slot in battle.placed.size():
   if battle.placed[slot] != null:
    battle.select_slot(slot)
    battle.upgrade_selected()
  var target: Node2D = null
  for drone in battle.drones.get_children():
   if not drone.ended and drone.position.distance_to(cannon.position) < float(cannon.definition.range):
    if target == null or drone.distance_remaining < target.distance_remaining:
     target = drone
  if target != null:
   battle.player_controls.aim_at(target.position)
  battle.player_controls.set_fire(&"test",target != null)
  auto_shots = 0
  for automatic in battle.turrets.get_children():
   auto_shots += automatic.shots_fired
  battle.close_build_mode()
  battle.simulate(1.0/60.0)
  await get_tree().process_frame
 check(app.screen == "results" and bool(app.result_data.get("victory",false)),"full hybrid mission reaches victory using ordinary attacks and earned credits")
 check(int(app.result_data.get("manual_shots",0)) > 0 and int(app.result_data.get("manual_hits",0)) > 0 and auto_shots > 0,"manual and automatic guns both contribute throughout the mission")
 check(int(SaveManager.state.credits) == 100+int(app.result_data.campaign.star_reward) and int(SaveManager.state.frontline) == 2,"hybrid victory retains campaign rewards and progression")
 app.queue_free()
 await get_tree().process_frame
 print("HYBRID: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
