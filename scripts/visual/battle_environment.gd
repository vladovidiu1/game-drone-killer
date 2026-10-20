extends Control
# Presentation only. Owns at most one terrain sheet, one shared prop sheet and
# three small atmosphere textures. Never modifies paths, collisions or game stats.
static var LIBRARY: Dictionary = preload("res://scripts/visual/environment_library.gd").DATA
static var BINDINGS: Dictionary = preload("res://scripts/visual/visual_assets.gd").catalog
const FIELD := Rect2(0,88,955,560)
const MAX_PROPS := 14
const MAX_PARTICLES := 32
var assignment: Dictionary
var profile: Dictionary
var kit: Dictionary
var terrain: Sprite2D
var decorations: Array[Dictionary] = []
var particles: Array[Vector3] = []
var prop_frames: Dictionary = {}
var elapsed := 0.0
var reduced := false
var pool: Texture2D = preload("res://assets/environment/light_pool.svg")
var cone: Texture2D = preload("res://assets/environment/searchlight_cone.svg")
var wisp: Texture2D = preload("res://assets/environment/smoke_wisp.svg")

func setup(mission: Dictionary) -> void:
 name = "Environment"
 position = FIELD.position
 size = FIELD.size
 clip_contents = true
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 show_behind_parent = true
 texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 assignment = LIBRARY.missions[str(int(mission.id))]
 profile = LIBRARY.profiles[assignment.profile]
 kit = LIBRARY.types[assignment.type]
 reduced = bool(SaveManager.settings.get("reduced_environment_effects",false))
 terrain = Sprite2D.new()
 terrain.name = "TerrainPlate"
 terrain.centered = false
 terrain.texture = local_frame("terrain_"+str(assignment.type))
 terrain.scale = FIELD.size/terrain.texture.get_size()
 terrain.show_behind_parent = true
 var grade := ShaderMaterial.new()
 grade.shader = preload("res://assets/shaders/terrain_grade.gdshader")
 grade.set_shader_parameter("ambient_tint",Color(str(profile.tint)))
 grade.set_shader_parameter("exposure",float(profile.exposure))
 grade.set_shader_parameter("uv_rect",Vector4(0,0,1,1))
 if terrain.texture is AtlasTexture:
  var frame: AtlasTexture = terrain.texture
  var dimensions: Vector2 = frame.atlas.get_size()
  var uv := Rect2(frame.region.position/dimensions,frame.region.size/dimensions)
  grade.set_shader_parameter("uv_rect",Vector4(uv.position.x,uv.position.y,uv.size.x,uv.size.y))
 terrain.material = grade
 add_child(terrain)
 for prop in kit.props:
  prop_frames[prop] = local_frame("prop_"+str(prop))
 var rng := RandomNumberGenerator.new()
 rng.seed = int(assignment.seed)
 # Detail placement is deterministic and bounded. Tall props reject every
 # slot's 44px touch disc, all flight corridors, briefing plate and base.
 for attempt in range(90):
  var point := Vector2(rng.randf_range(50,915),rng.randf_range(178,545))
  var radius := rng.randf_range(22,39)
  if not decoration_is_safe(point,radius,mission):
   continue
  var crowded := false
  for item in decorations:
   if point.distance_to(item.point) < radius+float(item.radius)+12:
    crowded = true
    break
  if crowded:
   continue
  decorations.append({"point":point,"radius":radius,"kind":kit.props[decorations.size()%kit.props.size()]})
  if decorations.size() == MAX_PROPS:
   break
 for index in mini(MAX_PARTICLES,int(profile.particles)):
  particles.append(Vector3(rng.randf_range(0,955),rng.randf_range(0,560),rng.randf_range(0.4,1.0)))
 queue_redraw()

func local_frame(id: String) -> Texture2D:
 # Deliberately bypass VisualAssets' lifetime cache for terrain/prop sheets:
 # changing missions must release unused GPU textures instead of retaining 13 maps.
 var entry: Dictionary = BINDINGS.sprites[id]
 var source: Texture2D = load("res://assets/"+str(entry.file))
 if not entry.has("region"):
  return source
 var rect: Array = entry.region
 var frame := AtlasTexture.new()
 frame.atlas = source
 frame.region = Rect2(float(rect[0]),float(rect[1]),float(rect[2]),float(rect[3]))
 frame.filter_clip = true
 return frame

static func decoration_is_safe(point: Vector2, radius: float, mission: Dictionary) -> bool:
 var type: String = LIBRARY.missions[str(int(mission.id))].type
 for zone in LIBRARY.types[type].get("no_props",[]):
  if Rect2(float(zone[0]),float(zone[1]),float(zone[2]),float(zone[3])).grow(radius).has_point(point):
   return false
 if not FIELD.grow(-radius).has_point(point):
  return false
 if Rect2(20,94,335,68).grow(radius).has_point(point) or Rect2(390,550,340,110).grow(radius).has_point(point):
  return false
 for slot in mission.slots:
  if point.distance_to(Vector2(float(slot[0]),float(slot[1]))) < radius+48:
   return false
 for path in mission.paths:
  for index in range(1,path.size()):
   var a := Vector2(float(path[index-1][0]),float(path[index-1][1]))
   var b := Vector2(float(path[index][0]),float(path[index][1]))
   if point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b)) < radius+28:
    return false
 return true

func tick(delta: float) -> void:
 elapsed += delta
 if not reduced:
  queue_redraw()

func _draw() -> void:
 if profile.is_empty():
  return
 var ambient := Color(str(profile.tint))*float(profile.exposure)
 ambient.a = 1.0
 var shadow := Vector2(float(profile.shadow[0]),float(profile.shadow[1]))
 for item in decorations:
  var point: Vector2 = item.point-FIELD.position
  var radius: float = item.radius
  # Extra contact shadow length follows the selected sunlight profile.
  draw_texture_rect(pool,Rect2(point+shadow-Vector2(radius,radius*.4),Vector2(radius*2.5,radius*1.3)),false,Color(0,0,0,.65))
  draw_texture_rect(prop_frames[item.kind],Rect2(point-Vector2.ONE*radius,Vector2.ONE*radius*2),false,ambient)
 var kind := str(assignment.profile)
 if kind == "night":
  # Baked soft light pools on terrain only: prelit actors remain readable.
  for point in [Vector2(170,240),Vector2(830,370),Vector2(560,510)]:
   var sweep := Vector2.ZERO if reduced else Vector2(sin(elapsed*.18+point.x)*36,cos(elapsed*.12)*18)
   draw_texture_rect(pool,Rect2(point+sweep-Vector2(105,110),Vector2(210,220)),false,Color(0.65,.8,1,.65))
  for index in 2:
   var origin := Vector2(95,165) if index == 0 else Vector2(870,230)
   var angle := -.65 if index == 0 else .65
   if not reduced:
    angle += sin(elapsed*.16+index)*.24
   draw_set_transform(origin,angle)
   draw_texture_rect(cone,Rect2(-65,0,130,260),false,Color(.8,.9,1,.6))
  draw_set_transform(Vector2.ZERO)
 if reduced:
  return
 if kind in ["storm","smoke"]:
  # Haze and all particles render below units and are clipped to the world field.
  draw_rect(Rect2(Vector2.ZERO,FIELD.size),Color(.48,.55,.62,float(profile.haze)))
  for index in 4:
   var x := fposmod(index*270.0+elapsed*(22 if kind == "storm" else 13),1255)-250
   var y := 80+index*117+sin(elapsed*.2+index)*18
   draw_texture_rect(wisp,Rect2(x,y,420,140),false,Color(1,1,1,.42 if kind == "smoke" else .22))
 for index in particles.size():
  var seed_point: Vector3 = particles[index]
  var speed: float = seed_point.z
  if kind == "storm":
   var p := Vector2(fposmod(seed_point.x+elapsed*105*speed,955),fposmod(seed_point.y+elapsed*310*speed,560))
   draw_line(p,p+Vector2(4,13)*speed,Color(.72,.82,.92,.16),1)
  elif kind == "smoke":
   var p := Vector2(fposmod(seed_point.x+elapsed*13*speed,955),fposmod(seed_point.y-elapsed*19*speed,560))
   # Embers stay at the perimeter; do not resemble hittable projectiles.
   if p.x < 140 or p.x > 895:
    draw_circle(p,1.1,Color(1,.43,.14,.38+.15*sin(elapsed*3+index)))
  else:
   var p := Vector2(fposmod(seed_point.x+elapsed*5*speed,955),fposmod(seed_point.y-elapsed*7*speed,560))
   draw_circle(p,.8,Color(.94,.85,.68,.12))
 # Small perimeter fire sources only; bounded circles, no emitters or live lights.
 if kind == "smoke":
  for point in [Vector2(82,350),Vector2(902,210)]:
   var flicker := 1.0+.12*sin(elapsed*8+point.x)
   draw_texture_rect(pool,Rect2(point-Vector2(30,24),Vector2(60,48)),false,Color(1,.32,.07,.6*flicker))
   draw_circle(point,3*flicker,Color(1,.53,.17,.8))
