extends Node2D
# Reusable clipped batch, no per-particle nodes, lights or physics.
func _draw() -> void:
 get_parent().get_parent().paint(self)
