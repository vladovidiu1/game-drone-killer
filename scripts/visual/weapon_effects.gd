extends RefCounted
const ASSETS := preload("res://scripts/visual/visual_assets.gd")

static func flash(canvas: CanvasItem, kind: String, angle: float, strength: float, ammunition: Color = Color.WHITE) -> void:
 if strength <= 0:
  return
 var pair := kind in ["machine_gun","heavy_aa","primary"]
 var id: String = "gun_primary" if kind == "primary" else ASSETS.catalog.turret_aliases[kind]
 var entry: Dictionary = ASSETS.catalog.sprites[id]
 var reach := float(entry.get("muzzle_forward",33))
 var spread := float(entry.get("muzzle_lateral",5))
 var length := 34.0 if kind in ["cannon","heavy_aa","primary"] else 21.0
 var width := 21.0 if kind in ["cannon","heavy_aa","primary"] else 12.0
 if kind == "missile":
  for side in [-1,1]:
   canvas.draw_set_transform(Vector2.from_angle(angle)*-9+Vector2.from_angle(angle+PI/2)*side*12,angle+PI/2)
   canvas.draw_texture_rect(ASSETS.sprite("jet_exhaust"),Rect2(-7,0,14,39),false,Color(1,.65,.35,strength*.8))
 elif kind not in ["laser","emp_tower"]:
  canvas.draw_set_transform(Vector2.ZERO,angle)
  for side in [-1,1] if pair else [0]:
   canvas.draw_texture_rect(ASSETS.texture("effects/muzzle_flash.svg"),Rect2(reach-3,side*spread-width*.5,length,width),false,Color(1,1,1,strength))
  if kind == "primary":
   canvas.draw_texture_rect(ASSETS.texture("projectiles/tracer.svg"),Rect2(reach,-2,18,4),false,Color(ammunition,strength*.65))
 canvas.draw_set_transform(Vector2.ZERO)
