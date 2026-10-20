extends Node2D
# Reusable presentation component: no targets, collision, firing or timers of its own.
const ASSETS := preload("res://scripts/visual/visual_assets.gd")
var body: Sprite2D
var shadow: Sprite2D
var surface: ShaderMaterial

func configure(id: String, size_multiplier: float = 1.0) -> void:
 var entry: Dictionary = ASSETS.catalog.sprites[id]
 scale = Vector2.ONE*size_multiplier
 shadow = Sprite2D.new()
 shadow.texture = ASSETS.texture("effects/soft_shadow.svg")
 shadow.scale = Vector2(0.6,0.36)
 shadow.position = Vector2(6,13)
 add_child(shadow)
 body = Sprite2D.new()
 body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 body.texture = ASSETS.sprite(id)
 body.centered = false
 body.offset = -Vector2(float(entry.pivot[0]),float(entry.pivot[1]))
 body.scale = Vector2.ONE*float(entry.scale)
 surface = ShaderMaterial.new()
 surface.shader = preload("res://assets/shaders/unit_surface.gdshader")
 body.material = surface
 add_child(body)

func sync(angle: float, flash: float = 0.0, cloaked: bool = false, suppressed: bool = false, recoil: float = 0.0) -> void:
 body.rotation = angle
 body.position = -Vector2.from_angle(angle-PI/2)*recoil
 surface.set_shader_parameter("hit_flash",clampf(flash/0.12,0.0,1.0))
 surface.set_shader_parameter("visibility",0.38 if cloaked else 1.0)
 surface.set_shader_parameter("suppression",1.0 if suppressed else 0.0)
 shadow.modulate.a = 0.35 if cloaked else 1.0
