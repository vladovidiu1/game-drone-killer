extends RefCounted
# Detached, non-physical presentation snapshots. Rewards/removal remain immediate.
const ASSETS := preload("res://scripts/visual/visual_assets.gd")
const LIMIT := 12
var wrecks: Array[Dictionary] = []

func snapshot(enemy: Node2D) -> void:
 if wrecks.size() >= LIMIT:
  wrecks.pop_front()
 var id: String = enemy.art.sprite_id
 var boss: bool = enemy.brain != null and enemy.brain.boss
 wrecks.append({"point":enemy.position,"id":id,"size":enemy.body_scale,"boss":boss,"age":0.0,"duration":2.1 if boss else 1.0,"seed":enemy.spawn_id})

func tick(delta: float) -> void:
 for index in range(wrecks.size()-1,-1,-1):
  wrecks[index].age += delta
  if float(wrecks[index].age) >= float(wrecks[index].duration):
   wrecks.remove_at(index)

func draw(canvas: CanvasItem) -> void:
 for wreck in wrecks:
  var age: float = wreck.age
  var t: float = age/float(wreck.duration)
  var moving := not bool(SaveManager.settings.get("reduced_motion",false))
  var entry: Dictionary = ASSETS.catalog.sprites[wreck.id]
  var texture := ASSETS.sprite(str(wreck.id))
  var scale: float = float(entry.scale)*float(wreck.size)*(1.0-t*.15 if moving else 1.0)
  canvas.draw_set_transform(wreck.point+(Vector2(t*9,t*16) if moving else Vector2.ZERO),(t*.24 if moving else 0.0)*(1 if int(wreck.seed)%2 else -1)+float(entry.get("facing",0)),Vector2.ONE*scale)
  canvas.draw_texture_rect(texture,Rect2(-Vector2(float(entry.pivot[0]),float(entry.pivot[1])),texture.get_size()),false,Color(.34,.29,.26,(1.0-t)*.9))
  canvas.draw_set_transform(Vector2.ZERO)
  if wreck.boss and not bool(SaveManager.settings.get("reduced_effects",false)):
   for index in 4:
    var local := (age-index*.22)/.75
    if local < 0 or local >= 1 or (not bool(SaveManager.settings.get("effects_smoke",true)) and local >= .5):
     continue
    var point: Vector2 = wreck.point+Vector2.from_angle(index*2.4)*index*18
    canvas.draw_texture_rect(ASSETS.explosion_frame(mini(5,int(local*6))),Rect2(point-Vector2.ONE*65,Vector2.ONE*130),false,Color(1,1,1,1-smoothstep(.65,1,local)))
