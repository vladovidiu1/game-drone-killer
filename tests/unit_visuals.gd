extends Node
const ASSETS := preload("res://scripts/visual/visual_assets.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)

func _ready() -> void:
 run.call_deferred()

func run() -> void:
 SaveManager.new_campaign()
 SaveManager.state.unlocks = ["laser","emp_tower","heavy_aa","armor_piercing","explosive"]
 SaveManager.state.ammo_loadout = ["standard","armor_piercing","explosive"]
 var battle := preload("res://scenes/gameplay.tscn").instantiate()
 add_child(battle)
 battle.set_physics_process(false)
 var seen: Array[String] = []
 var originals: Dictionary = CampaignManager.enemies.duplicate(true)
 for kind in CampaignManager.enemies:
  var enemy: Node2D = battle.spawn_enemy(str(kind))
  var id: String = enemy.art.sprite_id
  check(not seen.has(id),"Unique body binding for "+str(kind))
  seen.append(id)
  check(enemy.art.body.texture is AtlasTexture and not str(ASSETS.catalog.sprites[id].file).ends_with(".svg"),"Detailed transparent raster art replaces shared/procedural bodies")
  check(node_count(enemy.art) <= 6,"Bounded actor nodes, no Node per rotor")
  check(enemy.art.mechanics != null and enemy.art.shadow.texture != null,"Reusable mechanical overlay and ground shadow")
  check(not enemy.art.entry.get("rotors",[]).is_empty() or not enemy.art.entry.get("engines",[]).is_empty(),"Every drone has declared propulsion animation axes")
  var before: Vector2 = enemy.position
  var health: float = enemy.health
  enemy.art.advance(.2,.35,0,1,false,1,2)
  enemy.art.sync(0,.12,true,true)
  check(enemy.position == before and enemy.health == health and enemy.reward == int(CampaignManager.enemies[kind].reward),"Animation cannot change physical position, HP or reward")
  check(enemy.art.damage_state > .6 and enemy.art.body.position.length() <= 1.51,"Damage stage and bounded visual-only hovering")
  check(enemy.art.cloak_state and is_equal_approx(float(enemy.art.surface.get_shader_parameter("visibility")),.38),"Cloak applies across body and mechanics")
  check(is_equal_approx(enemy.art.mechanics.modulate.a,.38),"Propulsion obeys cloak opacity")
  if enemy.brain.boss:
   check(enemy.art.armor_panels.size() == 2 and enemy.art.armor_open > 0,"Boss has articulated armor sections")
   var weakpoint: Vector2 = enemy.brain.weakpoint()
   enemy.art.advance(.3,.2,1,1,false,1,2)
   check(enemy.brain.weakpoint() == weakpoint and enemy.brain.phase_index == 0,"Visual phase pose cannot change vulnerable geometry or boss AI phase")
  else:
   check(is_equal_approx(enemy.art.body.rotation,float(enemy.art.entry.get("facing",0))),"Presentation has no turn-driven gameplay dependency")
  enemy.ended = true
  enemy.queue_free()
  await get_tree().process_frame
 check(seen.size() == 14,"All nine ordinary drones and five bosses redesigned")
 check(CampaignManager.enemies == originals,"Enemy definitions remain byte-equivalent data")
 battle.credits = 15000
 SaveManager.state.unlocks = ["laser","emp_tower","heavy_aa","armor_piercing","explosive"]
 SaveManager.state.ammo_loadout = ["standard","armor_piercing","explosive"]
 var gun_ids: Array[String] = []
 for kind in CampaignManager.turrets:
  battle.select_slot(0)
  check(battle.build_turret(str(kind)),"Build actual weapon "+str(kind))
  var gun: Node2D = battle.placed[0]
  check(not gun_ids.has(gun.art.sprite_id),"All six automatic weapons have unique heads")
  gun_ids.append(gun.art.sprite_id)
  check(gun.art.base != null and gun.art.base != gun.art.body,"Fixed detailed bearing is separate from rotating head")
  var bearing_angle: float = gun.art.base.rotation
  gun.art.advance(.1,1,3,3)
  gun.art.sync(1.2)
  check(is_equal_approx(gun.art.body.rotation,1.2) and gun.art.base.rotation == bearing_angle,"Head rotation/recoil leaves stationary mount intact")
  check(gun.art.tier == 3 and gun.art.heat > 0 and gun.art.kick > 0,"Upgrade armor, heat and recoil derive from shot/upgrade snapshots")
  battle.placed[0] = null
  gun.queue_free()
  await get_tree().process_frame
 battle.close_build_mode()
 var cannon: Node2D = battle.player_turret
 var art: Node2D = cannon.get_node("Artwork").art
 check(art.sprite_id not in gun_ids and art.barrels != null,"Primary is distinct and has a separate sliding barrel assembly")
 var magazine: int = cannon.ammo
 cannon.set_aim(cannon.position+Vector2(30,-300))
 cannon.set_trigger(true)
 battle.simulate(.2)
 check(cannon.shots_fired > 0 and cannon.ammo < magazine,"Actual held manual firing still consumes ammo")
 var hull: Vector2 = art.body.position
 var recoil: Vector2 = art.barrels.position
 check(recoil.y > 0 and hull == Vector2.ZERO,"Primary breech stays mounted while barrels recoil")
 cannon.set_trigger(false)
 check(cannon.request_reload(),"Real partial reload starts")
 battle.simulate(.5)
 check(art.reloading and art.reload_fraction > 0 and art.reload_fraction < 1,"Autoloader pose tracks actual reload progress")
 var time: float = art.clock
 var ammo: int = cannon.ammo
 battle.set_paused(true)
 battle.simulate(2)
 check(art.clock == time and cannon.ammo == ammo,"Pause freezes visual animation and reload together")
 battle.set_paused(false)
 battle.simulate(2)
 check(not art.reloading and cannon.ammo == int(cannon.definition.magazine_size),"Reload animation retires when real reload completes")
 for kind in ["standard","armor_piercing","explosive"]:
  check(cannon.select_ammunition(kind),"Real ammunition mode selection "+kind)
  var projectile := preload("res://scenes/projectile.tscn").instantiate()
  projectile.configure_manual(battle,Vector2.UP)
  battle.projectiles.add_child(projectile)
  check(projectile.visual_kind == kind and projectile.damage == cannon.damage_value(),"Ammo artwork snapshot preserves damage")
  projectile.queue_free()
 await get_tree().process_frame
 var victim: Node2D = battle.spawn_enemy("scout")
 var credits: int = battle.credits
 victim.hit(1000,true,true,victim.position)
 check(victim.ended and battle.credits == credits+int(CampaignManager.enemies.scout.reward) and battle.view.destruction.wrecks.size() == 1,"Dead enemy removal/reward immediate, detached wreck presentation retained")
 var kills: int = battle.kills
 victim.hit(1000)
 check(battle.kills == kills,"Death visuals cannot award a duplicate kill")
 await get_tree().process_frame
 check(battle.living_count() == 0,"Detached wrecks never remain combat targets")
 for index in 15:
  var unit: Node2D = battle.spawn_enemy("scout")
  battle.view.destruction.snapshot(unit)
  unit.ended = true
  unit.queue_free()
 check(battle.view.destruction.wrecks.size() == 12,"Detached effects have a hard cap")
 battle.view.destruction.tick(3)
 check(battle.view.destruction.wrecks.is_empty(),"All wrecks/debris retire")
 battle.queue_free()
 await get_tree().process_frame
 print("UNIT VISUALS: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)

func node_count(node: Node) -> int:
 var count := 1
 for child in node.get_children():
  count += node_count(child)
 return count
