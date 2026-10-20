extends RefCounted
# Presentation-only bindings. Replacing artwork never changes combat definitions.
static var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/visual_catalog.json"))
static var textures: Dictionary = {}
static var frames: Dictionary = {}

static func texture(path: String) -> Texture2D:
 if not textures.has(path):
  textures[path] = load("res://assets/"+path)
 return textures[path] as Texture2D

static func sprite(id: String) -> Texture2D:
 if not frames.has(id):
  var entry: Dictionary = catalog.sprites[id]
  if entry.has("region"):
   var frame := AtlasTexture.new()
   frame.atlas = texture(str(entry.file))
   var rect: Array = entry.region
   frame.region = Rect2(float(rect[0]),float(rect[1]),float(rect[2]),float(rect[3]))
   frame.filter_clip = true
   frames[id] = frame
  else:
   frames[id] = texture(str(entry.file))
 return frames[id] as Texture2D

static func explosion_frame(index: int) -> Texture2D:
 index = clampi(index,0,5)
 var key := "explosion_%d" % index
 if not frames.has(key):
  var frame := AtlasTexture.new()
  frame.atlas = texture("effects/explosion_atlas.png")
  var cell := Vector2(frame.atlas.get_width()/3.0,frame.atlas.get_height()/2.0)
  frame.region = Rect2(Vector2(index%3,index/3)*cell,cell)
  frame.filter_clip = true
  frames[key] = frame
 return frames[key] as Texture2D
