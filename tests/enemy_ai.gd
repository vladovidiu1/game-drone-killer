extends Node
var checks := 0
var failures := 0
var battle: Node2D
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)

func _ready() -> void:
 run.call_deferred()

func clear_units() -> void:
 for enemy in battle.drones.get_children():
  enemy.ended = true
  enemy.queue_free()
 for projectile in battle.projectiles.get_children():
  projectile.queue_free()
 await get_tree().process_frame

func unit(kind: String, point: Vector2 = Vector2(560,340)) -> Node2D:
 var enemy: Node2D = battle.spawn_enemy(kind)
 enemy.position = point
 return enemy

func run() -> void:
 SaveManager.new_campaign()
 var legacy: Dictionary = SaveManager.state.duplicate(true)
 legacy.erase("campaign_complete")
 check(not SaveManager.validate_campaign(legacy).campaign_complete,"Existing v3 saves gain no spurious liberation")
 legacy.campaign_complete = true
 check(not SaveManager.validate_campaign(legacy).campaign_complete,"Final flag requires a reached final territory and victory record")
 legacy.frontline = 25
 legacy.highest = 25
 legacy.records["25"] = {"victories":1,"last_outcome":"victory"}
 check(SaveManager.validate_campaign(legacy).campaign_complete,"Validated final victory restores liberation")
 legacy.campaign_complete = "true"
 check(not SaveManager.validate_campaign(legacy).campaign_complete,"Malformed final flag is rejected")
 battle = preload("res://scenes/gameplay.tscn").instantiate()
 add_child(battle)
 battle.set_physics_process(false)
 battle.select_slot(0)
 battle.build_turret("machine_gun")
 battle.close_build_mode()
 var turret: Node2D = battle.placed[0]
 # Aura applies once per hit, never stacks emitters, AP bypasses, disable removes it.
 var shield := unit("shield")
 var scout := unit("scout",Vector2(570,340))
 scout.hit(20)
 check(is_equal_approx(scout.health,31),"Shield reduces nearby incoming damage by 55 percent")
 var shield2 := unit("shield",Vector2(550,340))
 scout.hit(20)
 check(is_equal_approx(scout.health,22),"Multiple shield emitters do not compound protection")
 scout.hit(10,true,true)
 check(is_equal_approx(scout.health,12),"Manual armor-piercing rounds bypass the aura")
 shield.apply_disable(2)
 shield2.apply_disable(2)
 scout.hit(10)
 check(is_equal_approx(scout.health,2),"EMP removes shield protection for its duration")
 var reward_before: int = battle.credits
 scout.hit(100)
 scout.hit(100)
 check(battle.credits == reward_before+10,"New ability damage retains once-only enemy rewards")
 await clear_units()
 # Cloaked drones are hittable by straight manual rounds and revealed by EMP.
 var stealth := unit("stealth",turret.position+Vector2(0,-80))
 check(stealth.brain.cloaked() and turret.acquire_target() == null,"Stealth temporarily evades autonomous target acquisition")
 stealth.hit(15,true,false,stealth.position)
 check(stealth.health == 50,"Cloaked drone remains manually damageable")
 stealth.apply_disable(1)
 check(turret.acquire_target() == stealth,"EMP reveals stealth to automatic defenses")
 stealth.brain.elapsed = 4
 stealth.disable_remaining = 0
 check(not stealth.brain.cloaked() and turret.acquire_target() == stealth,"Stealth has predictable visible windows")
 await clear_units()
 # Targeted attacks wind up before suppression, pause freezes both timers.
 for kind in ["emp","sniper"]:
  var attacker := unit(kind,turret.position+Vector2(0,-100))
  attacker.brain.cooldown = 0
  attacker.brain.tick(.01)
  check(attacker.brain.charging and turret.disabled_remaining == 0,"%s attack is telegraphed" % kind)
  var charge: float = attacker.brain.charge
  battle.set_paused(true)
  battle.simulate(2)
  check(is_equal_approx(attacker.brain.charge,charge),"Pause freezes enemy windup")
  battle.set_paused(false)
  attacker.brain.tick(charge+.01)
  check(turret.disabled_remaining > 0,"%s attack suppresses a defense" % kind)
  var shots: int = turret.shots_fired
  turret.tick(.1)
  check(turret.shots_fired == shots,"Suppressed automatic defense cannot fire")
  turret.tick(10)
  check(turret.disabled_remaining == 0,"Suppression recovers instead of deleting the purchased turret")
  check(battle.player_turret.reload_remaining == 0 and not battle.player_turret.trigger_held,"EMP/sniper never take control of primary cannon")
  await clear_units()
 var carrier := unit("carrier")
 carrier.brain.cooldown = 0
 carrier.brain.tick(.01)
 check(carrier.brain.charging and battle.support_spawned == 0,"Carrier telegraphs launch")
 carrier.brain.tick(3)
 check(battle.support_spawned == 2 and battle.living_count() == 3,"Carrier launches real supporting drones")
 var child: Node2D = battle.drones.get_children()[1]
 check(child.is_support and child.reward == 5 and child.position.y > 300,"Support spawns at its carrier with reduced bounty")
 for index in range(8):
  carrier.brain.cooldown = 0
  carrier.brain.tick(.01)
  carrier.brain.tick(3)
 check(battle.support_spawned == 6,"Carrier support cap prevents unbounded spawning")
 await clear_units()
 # All five data-driven bosses execute phases and attacks; no synthetic win here.
 for id in [5,10,15,20,25]:
  var key: String = CampaignManager.mission(id).boss
  var boss := unit(key)
  boss.position = boss.brain.anchor()
  var health: float = boss.health
  boss.hit(100)
  check(boss.health > health-15,"Boss hull resists automatic fire, rewarding manual support")
  health = boss.health
  boss.hit(100,true,false,boss.brain.weakpoint())
  check(boss.health <= health-250,"Precise primary hits exploit the visible boss core")
  for phase in range(3):
   boss.health = boss.maximum_health*[.9,.6,.3][phase]
   boss.brain.cooldown = 0
   boss.brain.tick(.01)
   check(boss.brain.phase_index == phase and boss.brain.charging,"Boss %d enters phase %d and telegraphs" % [id,phase+1])
   var actions: int = boss.brain.actions
   boss.brain.tick(float(boss.brain.settings().windup)+.01)
   check(boss.brain.actions == actions+1,"Boss %d phase %d executes a real attack" % [id,phase+1])
  boss.apply_disable(2)
  boss.brain.cooldown = 0
  boss.brain.tick(.5)
  check(not boss.brain.charging,"EMP interrupts boss attack initiation")
  boss.hit(100000,true,true,boss.brain.weakpoint())
  check(boss.ended,"Every boss can actually be destroyed")
  await clear_units()
  turret.disabled_remaining = 0
 # A health threshold cannot silently swap an already telegraphed attack.
 var transitioning := unit("assault_carrier")
 transitioning.position = transitioning.brain.anchor()
 transitioning.brain.cooldown = 0
 transitioning.brain.tick(.01)
 check(transitioning.brain.pending_attack.attack == "spawn","Carrier telegraphs its launch")
 transitioning.health = transitioning.maximum_health*.6
 transitioning.brain.tick(.01)
 check(transitioning.brain.phase_index == 1 and transitioning.brain.pending_attack.attack == "spawn","Phase transition preserves the promised attack")
 var before_support: int = battle.support_spawned
 transitioning.brain.tick(3)
 check(battle.support_spawned > before_support,"Telegraphed launch completes instead of silently becoming EMP")
 await clear_units()
 # Environmental effects are simulation-driven, do not affect primary ownership.
 battle.mission_data = CampaignManager.mission(6)
 battle.elapsed = 31
 check(battle.environment_warning() > 0,"Grid surge offers a three-second warning")
 battle.tick_environment(3.1)
 check(turret.disabled_remaining == 2 and battle.environmental_pulses == 1,"Grid surge has a finite suppression effect")
 battle.mission_data = CampaignManager.mission(13)
 check(is_equal_approx(battle.visibility_multiplier(),.87),"Dust range penalty is data-driven")
 check(battle.player_turret.definition.range == 400,"Dust preserves manual cannon range")
 # Empty final scheduler cannot resolve victory while a boss remains alive.
 battle.mission_data = CampaignManager.mission(5)
 var final_boss := unit("assault_carrier")
 battle.spawner.finished = true
 battle.simulate(.01)
 check(not battle.finished,"Wave completion waits for living boss")
 final_boss.hit(100000,true,true,final_boss.brain.weakpoint())
 battle.simulate(.01)
 check(battle.finished,"Destroying final boss completes mission")
 battle.queue_free()
 await get_tree().process_frame
 print("ENEMY AI: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
