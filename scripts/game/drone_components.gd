extends RefCounted
# Mission-scoped component rig. No physics server shapes or persistent rewards.
static var CONFIG: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/drone_components.json"))
const COMPONENT := preload("res://scripts/game/drone_component.gd")
var enemy: Node2D
var mission_id := 1
var parts: Array[Node2D] = []
var clock := 0.0
var smoke_timer := 0.0
var pose_angle := 0.0
var armor_open := 0.0
var falling := false
var crash_source: StringName = &"other"
var fall_time := 0.0
var feedback := ""
var feedback_time := 0.0
var destroyed_parts := 0

func configure(unit: Node2D, kind: String, mission: int) -> bool:
 enemy = unit
 mission_id = mission
 var chosen: Array = []
 for item in CONFIG.loadouts.get(kind,[]):
  if mission >= int(item.from_mission):
   chosen.append(item)
 if chosen.is_empty():
  return false
 enemy.art.anchored_components = true
 enemy.art.body.rotation = float(enemy.art.entry.get("facing",0))
 add_part({"id":"body","type":"body","health":0},{"point":enemy.art.entry.pivot,"radius":18.0/float(enemy.art.entry.scale),"parent":"body"})
 for item in chosen.slice(0,int(CONFIG.maximum_parts)-1):
  var definition: Dictionary = CONFIG.types[str(item.type)].duplicate(true)
  definition.merge(item,true)
  if item.has("health_fraction"):
   definition.health = enemy.maximum_health*float(item.health_fraction)
  if mission >= int(CONFIG.late_armor_from) and str(item.type) != "core":
   definition.armor = maxf(float(definition.armor),float(CONFIG.late_armor))
  var binding: Dictionary = enemy.art.entry.component_mounts[str(item.id)]
  add_part(definition,binding)
 refresh_art()
 return true

func add_part(data: Dictionary, binding: Dictionary) -> void:
 var part := COMPONENT.new()
 part.configure(self,data,binding)
 var parent: Node2D = enemy.art.body
 if str(binding.parent) == "armor_left" and not enemy.art.armor_panels.is_empty():
  parent = enemy.art.armor_panels[0]
 elif str(binding.parent) == "armor_right" and enemy.art.armor_panels.size() > 1:
  parent = enemy.art.armor_panels[1]
 parent.add_child(part)
 parts.append(part)
 part.destroyed.connect(_destroyed)

func find(id: String) -> Node2D:
 for part in parts:
  if part.id == id:
   return part
 return null

func disabled(effect: String) -> bool:
 for part in parts:
  if str(part.definition.get("effect","body")) == effect and part.broken:
   return true
 return false

func shield_operational() -> bool:
 var part := find("generator")
 return part != null and not part.broken and enemy.disable_remaining <= 0 and not falling

func attack_allowed(attack: String) -> bool:
 for part in parts:
  if part.broken and part.kind == "weapon" and attack in part.definition.get("attacks",["emp","sniper","barrage"]):
   return false
 return not falling

func speed_multiplier() -> float:
 var broken := 0
 for part in parts:
  if part.kind == "engine" and part.broken:
   broken += 1
 return pow(1.0-float(CONFIG.engine_speed_loss),broken)

func tick(delta: float) -> void:
 clock += delta
 feedback_time = maxf(0,feedback_time-delta)
 for part in parts:
  part.flash = maxf(0,part.flash-delta)
 if falling:
  fall_time += delta
  if fall_time >= float(CONFIG.crash_seconds):
   enemy.die(crash_source)
  return
 var loss := 1.0-speed_multiplier()
 pose_angle = sin(clock*3.2)*float(CONFIG.instability_radians) if loss > 0 else 0.0
 # Essential hitbox pose is simulated, independent of graphics preset/shake/hover.
 enemy.art.body.rotation = pose_angle+float(enemy.art.entry.get("facing",0))
 enemy.art.body.position = Vector2.ZERO
 if enemy.brain.boss:
  armor_open = move_toward(armor_open,float(enemy.brain.phase_index),delta*2.4)
  enemy.art.armor_open = armor_open
  for index in enemy.art.armor_panels.size():
   enemy.art.armor_panels[index].position.x = armor_open*9*(-1 if index == 0 else 1)
 smoke_timer -= delta
 if smoke_timer <= 0:
  smoke_timer = float(CONFIG.smoke_interval)
  for part in parts:
   if part.broken and part.kind != "body":
    enemy.brain.battle.view.combat_fx.particle("smoke",part.point(),Vector2(8,-22),.7,14,Color("65717b"))

func contact(start: Vector2, direction: Vector2, remaining: float) -> Dictionary:
 var finish := start+direction*remaining
 var reach: float = (Vector2(float(enemy.art.entry.region[2]),float(enemy.art.entry.region[3])).length()*.5*float(enemy.art.entry.scale)*enemy.body_scale+20)*maxf(absf(enemy.scale.x),absf(enemy.scale.y))
 if Geometry2D.get_closest_point_to_segment(enemy.position,start,finish).distance_squared_to(enemy.position) > reach*reach:
  return {"distance":INF,"component":null}
 var nearest := INF
 var selected: Node2D
 # Exposed surface components take priority over the coarse hull of this actor.
 for part in parts:
  if part.kind == "body" or not part.collider_enabled():
   continue
  var distance: float = part.segment(start,finish)
  if distance < nearest:
   nearest = distance
   selected = part
 if selected == null:
  selected = find("body")
  nearest = selected.segment(start,finish)
 return {"distance":nearest,"component":selected}

func area(amount: float, at: Vector2, radius: float, armor_piercing: bool, traits: Dictionary, source: StringName = &"other") -> void:
 # Explicit blast model: one hull packet plus one reduced packet per part in radius.
 for part in parts:
  if enemy.ended or falling:
   break
  if part.kind != "body" and not part.broken and part.point().distance_to(at) <= radius:
   part.receive(amount*float(CONFIG.area_component_fraction),false,armor_piercing,traits,source)

func _destroyed(part: Node2D) -> void:
 if part.kind == "body":
  return
 destroyed_parts += 1
 var battle: Node2D = enemy.brain.battle
 battle.component_destructions += 1
 battle.performance.component(part)
 feedback = {"engine":"ENGINE DISABLED","weapon":"WEAPON OFFLINE","shield":"SHIELD DESTROYED","sensor":"SENSOR DESTROYED","core":"CORE BREACHED"}.get(str(part.kind),"COMPONENT DESTROYED")
 feedback_time = 1.4
 var point: Vector2 = part.point()
 battle.view.combat_fx.burst(point,6,90,Color("ffb866"),true)
 battle.view.combat_fx.particle("debris",point,Vector2(22,-15),.65,8,Color("a5b2bc"))
 if part.kind == "shield":
  battle.view.combat_fx.pulse(point,48,Color("85ddec"))
 if part.kind in ["weapon","sensor"]:
  battle.view.combat_fx.particle("electric",point,Vector2.ZERO,.35,22,Color("9dddf0"))
 if part.kind == "weapon":
  enemy.damage = int(ceil(enemy.damage*.5))
  if not attack_allowed(str(enemy.brain.pending_attack.get("attack",""))):
   enemy.brain.charging = false
 if part.kind == "core":
  enemy.apply_body_damage(enemy.maximum_health*float(part.definition.get("burst_fraction",0)),part.last_source)
 if part.kind == "engine":
  var engines := 0
  var remaining := 0
  for other in parts:
   if other.kind == "engine" and mission_id >= int(other.definition.get("critical_from",1000)):
    engines += 1
    remaining += int(not other.broken)
  if engines > 0 and remaining == 0 and not enemy.ended:
   falling = true
   crash_source = part.last_source
   fall_time = 0
   enemy.brain.charging = false
   feedback = "PROPULSION LOST / CRASHING"
   battle.view.combat_fx.particle("smoke",enemy.position,Vector2(0,-20),float(CONFIG.crash_seconds),30,Color("65717b"))
 refresh_art()

func hit_feedback(part: Node2D, direct: bool) -> void:
 enemy.brain.battle.view.effect(part.point(),"hit",10,Color("fff2c6"))
 if direct:
  enemy.brain.battle.component_hits += 1
  if part.kind == "core" and part.open() and feedback_time < .4:
   feedback = "CRITICAL HIT / CORE"
   feedback_time = maxf(feedback_time,.35)

func refresh_art() -> void:
 var markers := PackedVector4Array()
 markers.resize(6)
 var count := 0
 var stopped: Array[int] = []
 var weapons: Array[int] = []
 for part in parts:
  if not part.broken:
   continue
  if part.binding.has("rotor"):
   stopped.append(int(part.binding.rotor))
  if part.binding.has("weapon"):
   weapons.append(int(part.binding.weapon))
  if count < 6 and part.kind != "core":
   var region: Array = enemy.art.entry.region
   var atlas: Texture2D = enemy.art.body.texture.atlas
   var size := atlas.get_size()
   markers[count] = Vector4((float(region[0])+float(part.binding.point[0]))/size.x,(float(region[1])+float(part.binding.point[1]))/size.y,part.radius/size.x,part.radius/size.y)
   count += 1
 enemy.art.component_rotors = stopped
 enemy.art.component_weapons = weapons
 enemy.art.apply_surface_value("component_scorch",markers)
 enemy.art.apply_surface_value("component_scorch_count",count)
 enemy.art.mechanics.queue_redraw()
