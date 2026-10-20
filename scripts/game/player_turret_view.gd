extends Node2D
const ASSETS := preload("res://scripts/visual/visual_assets.gd")
var art: Node2D
@onready var cannon: Node2D = get_parent()

func _ready() -> void:
 art = preload("res://scripts/visual/unit_visual.gd").new()
 art.configure("gun_primary",1.0)
 add_child(art)

func _draw() -> void:
 if cannon.definition.is_empty():
  return
 var tint := Color(str(cannon.ammunition().color))
 if is_instance_valid(art):
  art.sync(cannon.barrel_angle+PI/2,0.0,false,false,cannon.recoil)
 preload("res://scripts/visual/weapon_effects.gd").flash(self,"primary",cannon.barrel_angle,clampf(cannon.muzzle_flash/.065,0,1),tint)
 # Crosshair belongs to the player cannon, independent of turret selection.
 var crosshair: Vector2 = cannon.aim_point-cannon.position
 var color := (Color("ff6c7e") if cannon.last_critical else Color("fff1a0")) if cannon.hit_confirm > 0 else tint
 draw_arc(crosshair,13,0,TAU,32,color,2)
 for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
  draw_line(crosshair+direction*17,crosshair+direction*24,color,2)
 draw_circle(crosshair,2,color)
 if cannon.reload_remaining > 0:
  draw_arc(Vector2.ZERO,33,-PI/2,-PI/2+TAU*cannon.reload_progress(),40,Color("f6c777"),4)
