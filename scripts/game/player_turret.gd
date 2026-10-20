extends Node2D
# Shared combat logic: input adapters supply aim/trigger; only battle advances time.
signal state_changed
var battle: Node2D
var definition: Dictionary = {}
var ammo := 0
var reload_remaining := 0.0
var cooldown := 0.0
var trigger_held := false
var aim_point := Vector2.ZERO
var barrel_angle := -PI/2
var muzzle_flash := 0.0
var recoil := 0.0
var hit_confirm := 0.0
var shots_fired := 0
var hits := 0
var ammunition_type := "standard"
var last_critical := false
var rng := RandomNumberGenerator.new()

func configure(owner_battle: Node2D, data: Dictionary) -> void:
 battle = owner_battle
 definition = data
 rng.randomize()
 ammunition_type = str(SaveManager.state.get("equipped_ammo","standard"))
 var location: Array = battle.mission_data.get("player_position",definition.position)
 position = Vector2(float(location[0]),float(location[1]))
 ammo = int(definition.magazine_size)
 aim_point = position+Vector2.UP*float(definition.range)*0.7

func damage_value() -> float:
 return float(definition.damage)*float(ammunition().damage_multiplier)

func ammunition() -> Dictionary:
 return SaveManager.catalog.ammunition[ammunition_type]

func fire_rate_value() -> float:
 return float(definition.fire_rate)*float(ammunition().fire_rate_multiplier)*battle.abilities.fire_multiplier()

func select_ammunition(id: String) -> bool:
 if battle.paused or battle.finished or reload_remaining > 0 or not SaveManager.catalog.ammunition.has(id) or not EconomyManager.unlocked(id):
  return false
 if not EconomyManager.equip_ammunition(id):
  return false
 ammunition_type = id
 # Preserve ammo and reload state; changing types never accelerates the next shot.
 cooldown = maxf(cooldown,1.0/fire_rate_value())
 state_changed.emit()
 return true

func set_aim(point: Vector2) -> void:
 var offset := point-position
 if offset.length_squared() < 1.0:
  return
 aim_point = position+offset.limit_length(float(definition.range))

func set_trigger(value: bool) -> void:
 trigger_held = value and not battle.paused and not battle.finished

func request_reload() -> bool:
 if battle.paused or battle.finished or reload_remaining > 0 or ammo == int(definition.magazine_size):
  return false
 reload_remaining = float(definition.reload_time)
 AudioManager.combat_cue("reload")
 state_changed.emit()
 return true

func tick(delta: float) -> void:
 if battle.paused or battle.finished:
  return
 barrel_angle = lerp_angle(barrel_angle,(aim_point-position).angle(),1.0-exp(-float(definition.rotation_response)*delta))
 muzzle_flash = maxf(0.0,muzzle_flash-delta)
 recoil = move_toward(recoil,0.0,delta*45.0)
 hit_confirm = maxf(0.0,hit_confirm-delta)
 cooldown = maxf(0.0,cooldown-delta)
 if reload_remaining > 0:
  reload_remaining = maxf(0.0,reload_remaining-delta)
  if reload_remaining <= 0.00001:
   reload_remaining = 0.0
   ammo = int(definition.magazine_size)
   AudioManager.combat_cue("ready")
   state_changed.emit()
  return
 if trigger_held and cooldown <= 0.00001:
  var round_cost := int(ammunition().round_cost)
  if ammo < round_cost:
   request_reload()
   return
  battle.launch_player_projectile(Vector2.from_angle(barrel_angle))
  ammo -= round_cost
  shots_fired += 1
  cooldown = 1.0/fire_rate_value()
  muzzle_flash = 0.065
  recoil = 5.0
  AudioManager.combat_cue("shot")
  if ammo < round_cost:
   request_reload()
  state_changed.emit()

func notify_hit(critical: bool = false) -> void:
 last_critical = critical
 hit_confirm = 0.15
 hits += 1
 AudioManager.combat_cue("hit")

func reload_progress() -> float:
 return 1.0-reload_remaining/float(definition.reload_time) if reload_remaining > 0 else 1.0
