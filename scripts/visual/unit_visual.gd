extends Node2D
# Presentation-only component. Simulation supplies elapsed delta and snapshots;
# visual transforms never touch a controller, target, collision shape or input.
const ASSETS := preload("res://scripts/visual/visual_assets.gd")
var anchored_components := false
var component_rotors: Array[int] = []
var component_weapons: Array[int] = []
var body: Sprite2D
var shadow: Sprite2D
var base: Sprite2D
var barrels: Sprite2D
var mechanics: Node2D
var surface: ShaderMaterial
var barrel_surface: ShaderMaterial
var entry: Dictionary
var sprite_id := ""
var clock := 0.0
var heat := 0.0
var kick := 0.0
var tier := 1
var last_shots := 0
var reloading := false
var reload_fraction := 1.0
var is_weapon := false
var damage_state := 0.0
var phase_state := 0
var armor_open := 0.0
var armor_panels: Array[Sprite2D] = []
var cloak_state := false
var graphics: Dictionary
var cached_damage := -1.0
var cached_heat := -1.0
var cached_flash := -1.0
var cached_visibility := -1.0
var cached_suppression := -1.0
var barrel_heat := -1.0
var overlay_remaining := 0.0

func make_surface(texture: Texture2D) -> ShaderMaterial:
 var result := ShaderMaterial.new()
 result.shader = preload("res://assets/shaders/unit_surface.gdshader")
 var uv := Vector4(0,0,1,1)
 if texture is AtlasTexture:
  var region: Rect2 = texture.region
  var dimensions: Vector2 = texture.atlas.get_size()
  uv = Vector4(region.position.x/dimensions.x,region.position.y/dimensions.y,region.size.x/dimensions.x,region.size.y/dimensions.y)
 result.set_shader_parameter("uv_rect",uv)
 return result

func configure(id: String, size_multiplier: float = 1.0) -> void:
 graphics = preload("res://scripts/visual/graphics_profile.gd").resolve(SaveManager.settings)
 sprite_id = id
 entry = ASSETS.catalog.sprites[id]
 is_weapon = bool(entry.get("weapon",false))
 scale = Vector2.ONE*size_multiplier
 shadow = Sprite2D.new()
 shadow.texture = ASSETS.texture("effects/soft_shadow.svg")
 shadow.scale = Vector2(.63,.4)
 shadow.position = Vector2(6,13)
 shadow.visible = float(graphics.shadow_strength) > 0
 add_child(shadow)
 if is_weapon:
  base = Sprite2D.new()
  base.texture = ASSETS.sprite("primary_base" if id == "gun_primary" else "secondary_base")
  base.scale = Vector2(.34,.23) if id == "gun_primary" else Vector2.ONE*.29
  add_child(base)
 body = Sprite2D.new()
 body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 body.texture = ASSETS.sprite(id)
 body.centered = false
 body.offset = -Vector2(float(entry.pivot[0]),float(entry.pivot[1]))
 body.scale = Vector2(float(entry.get("scale_x",entry.scale)),float(entry.scale))
 surface = make_surface(body.texture)
 body.material = surface
 add_child(body)
 if bool(entry.get("boss",false)):
  var frame: AtlasTexture = body.texture
  var width := int(frame.region.size.x)
  var cut := int(width*.25)
  surface.set_shader_parameter("armor_columns",Vector2(float(cut)/width,float(width-cut)/width))
  surface.set_shader_parameter("armor_split",true)
  for side in [-1,1]:
   var panel := Sprite2D.new()
   var cropped := AtlasTexture.new()
   cropped.atlas = frame.atlas
   var x := 0 if side == -1 else width-cut
   cropped.region = Rect2(frame.region.position+Vector2(x,0),Vector2(cut,frame.region.size.y))
   cropped.filter_clip = true
   panel.texture = cropped
   panel.centered = false
   panel.offset = body.offset+Vector2(x,0)
   panel.material = make_surface(cropped)
   body.add_child(panel)
   armor_panels.append(panel)
 if id == "gun_primary":
  barrels = Sprite2D.new()
  barrels.texture = ASSETS.sprite("primary_barrels")
  barrels.centered = false
  var barrel_entry: Dictionary = ASSETS.catalog.sprites.primary_barrels
  barrels.offset = -Vector2(float(barrel_entry.pivot[0]),float(barrel_entry.pivot[1]))
  barrel_surface = make_surface(barrels.texture)
  barrels.material = barrel_surface
  body.add_child(barrels)
 mechanics = preload("res://scripts/visual/unit_mechanics.gd").new()
 mechanics.visual = self
 body.add_child(mechanics)

func advance(delta: float, health_fraction: float = 1.0, shots: int = 0, upgrade_tier: int = 1, reload_active: bool = false, progress: float = 1.0, phase: int = 0) -> void:
 var previous_shots := last_shots
 var previous_tier := tier
 var previous_reload := reloading
 if not bool(SaveManager.settings.get("reduced_motion",false)):
  clock += delta
 damage_state = clampf(1.0-health_fraction,0,1)
 tier = clampi(upgrade_tier,1,3)
 phase_state = phase
 if not anchored_components:
  armor_open = move_toward(armor_open,float(phase),delta*2.4)
  for index in armor_panels.size():
   var panel: Sprite2D = armor_panels[index]
   panel.position.x = armor_open*9*(-1 if index == 0 else 1)
 reloading = reload_active
 reload_fraction = progress
 heat = maxf(0.0,heat-delta*.16)
 kick = maxf(0.0,kick-delta*28)
 if shots > last_shots:
  heat = minf(1.0,heat+float(shots-last_shots)*.095)
  kick = float(entry.get("recoil",2.5))
 last_shots = shots
 if cached_damage != damage_state:
  cached_damage = damage_state
  apply_surface_value("damage_amount",damage_state)
 var visible_heat := heat if is_weapon else 0.0
 if cached_heat != visible_heat:
  cached_heat = visible_heat
  apply_surface_value("heat",visible_heat)
 if barrel_surface != null and barrel_heat != heat:
  barrel_surface.set_shader_parameter("heat",heat)
  barrel_heat = heat
 overlay_remaining -= delta
 if overlay_remaining <= 0 or shots != previous_shots or tier != previous_tier or reloading or reloading != previous_reload:
  overlay_remaining = 1.0/float(graphics.unit_overlay_hz)
  mechanics.queue_redraw()

func sync(angle: float, flash: float = 0.0, cloaked: bool = false, suppressed: bool = false, recoil: float = 0.0) -> void:
 cloak_state = cloaked
 body.rotation = angle+float(entry.get("facing",0.0))
 if is_weapon:
  # Primary barrels slide independently; the fixed bearing never recoils.
  body.position = -Vector2.from_angle(angle-PI/2)*(0.0 if barrels != null else kick)
  if barrels != null:
   barrels.position = Vector2(0,maxf(recoil,kick)/float(entry.scale))
 else:
  body.position = Vector2.ZERO if anchored_components else Vector2(0,sin(clock*2.7+float(entry.get("hover_phase",0)))*1.5)
 var flash_value := clampf(flash/0.12,0,1)
 var visibility_value := .38 if cloaked else 1.0
 var suppression_value := 1.0 if suppressed else 0.0
 if cached_flash != flash_value:
  cached_flash = flash_value
  apply_surface_value("hit_flash",flash_value)
 if cached_visibility != visibility_value:
  cached_visibility = visibility_value
  apply_surface_value("visibility",visibility_value)
 if cached_suppression != suppression_value:
  cached_suppression = suppression_value
  apply_surface_value("suppression",suppression_value)
 mechanics.modulate = Color(.65,.72,.85,.38 if cloaked else 1.0) if suppressed else Color(1,1,1,.38 if cloaked else 1.0)
 shadow.modulate.a = (.35 if cloaked else .9)*float(graphics.shadow_strength)
 if base != null:
  base.modulate = Color(.58,.65,.75) if suppressed else Color.WHITE

func apply_surface_value(key: String, value: Variant) -> void:
 # Cached scalars and bounded component-mask arrays update the shared materials.
 # Damage, hits, cloak/suppression recovery and boss armor still update instantly.
 surface.set_shader_parameter(key,value)
 for panel in armor_panels:
  panel.material.set_shader_parameter(key,value)
