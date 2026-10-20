extends Control
# Results-only, cosmetic sweep. No access to campaign transactions or combat.
var age := 0.0
var reduced := false
var motion := false
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 reduced = bool(SaveManager.settings.get("reduced_effects",false))
 motion = bool(SaveManager.settings.get("reduced_motion",false))
func _process(delta: float) -> void:
 age += delta
 if age >= 1.4:
  queue_free()
  return
 queue_redraw()
func _draw() -> void:
 var extent := minf(size.x,680)
 var progress := 1.0 if motion else clampf(age/.7,0,1)
 draw_line(Vector2(0,125),Vector2(extent*progress,125),Color(.22,.72,.9,(1-age/1.4)*.65),2)
 if not reduced:
  for index in 4:
   var x := extent*progress-index*14
   if x > 0:
    draw_line(Vector2(x,121),Vector2(x,129),Color(.55,.83,.95,(1-age/1.4)*.4),2)
