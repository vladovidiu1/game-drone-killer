extends Node2D
# One batched overlay per unit, not one Node per rotor/engine/weapon section.
const ASSETS := preload("res://scripts/visual/visual_assets.gd")
var visual: Node2D

func _draw() -> void:
 if not is_instance_valid(visual):
  return
 var entry: Dictionary = visual.entry
 var pivot := Vector2(float(entry.pivot[0]),float(entry.pivot[1]))
 var time: float = visual.clock
 for index in entry.get("rotors",[]).size():
  if index in visual.component_rotors:
   continue
  var rotor: Array = entry.rotors[index]
  var point := mounted(Vector2(float(rotor[0]),float(rotor[1])))-pivot
  var radius := float(rotor[2])
  draw_set_transform(point,time*(19 if index%2 == 0 else -19)+index)
  draw_texture_rect(ASSETS.sprite("rotor_blade"),Rect2(-Vector2.ONE*radius,Vector2.ONE*radius*2),false,Color(1,1,1,.43))
 draw_set_transform(Vector2.ZERO)
 for engine_index in entry.get("engines",[]).size():
  if engine_index in visual.component_rotors:
   continue
  var engine: Array = entry.engines[engine_index]
  var point := mounted(Vector2(float(engine[0]),float(engine[1])))-pivot
  var width := float(engine[2])
  var pulse := 1.0+.1*sin(time*15+point.x)
  draw_texture_rect(ASSETS.sprite("jet_exhaust"),Rect2(point-Vector2(width*.5,0),Vector2(width,width*2.4*pulse)),false,Color(1,.8,.75,.7))
 for index in entry.get("weapons",[]).size():
  if index in visual.component_weapons:
   continue
  var mount: Array = entry.weapons[index]
  var point := mounted(Vector2(float(mount[0]),float(mount[1])))-pivot
  var radius := float(mount[2])
  var sweep := sin(time*.8+index*2)*.12
  draw_set_transform(point,PI+sweep)
  draw_texture_rect(ASSETS.sprite("boss_gun"),Rect2(-radius,-radius*1.6,radius*2,radius*2.8),false,Color(1,1,1,.92))
 draw_set_transform(Vector2.ZERO)
 if visual.is_weapon:
  # Autoloader travels beside the breech only during actual reload state.
  if visual.reloading:
   var stroke := sin(visual.reload_fraction*PI)
   draw_texture_rect(ASSETS.sprite("magazine_cassette"),Rect2(40+stroke*26,-12,42,58),false)
  if visual.tier >= 2:
   draw_texture_rect(ASSETS.sprite("upgrade_collar"),Rect2(-99,-22,198,132),false,Color(1,1,1,.9))
  if visual.tier >= 3:
   # The same rendered armor component forms a second reinforced rear collar.
   draw_texture_rect(ASSETS.sprite("upgrade_collar"),Rect2(-110,8,220,128),false,Color(.83,.91,1,.82))

func mounted(point: Vector2) -> Vector2:
 if not visual.entry.get("boss",false):
  return point
 var width := float(visual.entry.region[2])
 if point.x < int(width*.25):
  point.x -= visual.armor_open*9
 elif point.x > width-int(width*.25):
  point.x += visual.armor_open*9
 return point
