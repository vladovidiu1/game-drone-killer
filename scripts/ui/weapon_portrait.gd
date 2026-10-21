extends Control
# Static composed game artwork for UI. No ticking, targeting or combat controller.
var artwork: Node2D
func setup(id: String, minimum: Vector2) -> void:
 custom_minimum_size = minimum
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 artwork = preload("res://scripts/visual/unit_visual.gd").new()
 artwork.configure(id)
 artwork.sync(0.0)
 add_child(artwork)
 resized.connect(_layout)
 _layout()
func _layout() -> void:
 if is_instance_valid(artwork):
  artwork.position = size*.5+Vector2(0,8)
  artwork.scale = Vector2.ONE*minf(size.x/105.0,size.y/115.0)
