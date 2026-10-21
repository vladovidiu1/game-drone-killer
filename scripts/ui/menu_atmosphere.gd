extends Control
var clock := 0.0
var particle_count := 18
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 particle_count = int(preload("res://scripts/visual/graphics_profile.gd").resolve(SaveManager.settings).menu_particles)
func _process(delta: float) -> void:
 if particle_count == 0 or not visible or bool(SaveManager.settings.get("reduced_motion",false)) or bool(SaveManager.settings.get("reduced_effects",false)):
  return
 clock += delta
 queue_redraw()
func _draw() -> void:
 if particle_count == 0 or bool(SaveManager.settings.get("reduced_motion",false)) or bool(SaveManager.settings.get("reduced_effects",false)):
  return
 # Restrained dust/embers and a slow radar sweep, never a flashing overlay.
 for index in particle_count:
  var p := Vector2(fposmod(index*137.0+clock*(5+index%4),size.x+40)-20,fposmod(index*71.0-clock*(3+index%5),size.y+40)-20)
  if p.x > size.x*.48:
   draw_circle(p,.8+(index%3)*.35,Color(.8,.67,.47,.16))
 var center := Vector2(size.x*.84,size.y*.75)
 draw_arc(center,110,clock*.12,clock*.12+.6,24,Color(.22,.72,.9,.07),2,true)
