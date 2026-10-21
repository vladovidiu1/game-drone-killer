extends "res://scripts/ui/touch_button.gd"
# Real Button inherits native focus and independent touch ownership. Its visible
# label is a child so long operation names wrap without changing the hit target.
const UI := preload("res://scripts/ui/ui_kit.gd")
var mission_id := 1
var tint := UI.CYAN
var checkpoint := false
var locked := false
var current := false
var best_stars := 0
var clock := 0.0
func setup(id: int) -> void:
 mission_id = id
 best_stars = int(SaveManager.state.get("records",{}).get(str(id),{}).get("best_stars",0))
 custom_minimum_size = Vector2(190,64)
 size = custom_minimum_size
 tooltip_text = "%02d  %s" % [id,CampaignManager.mission(id).name]
 for state in ["normal","hover","pressed","disabled","focus"]:
  add_theme_stylebox_override(state,StyleBoxEmpty.new())
 var label := UI.label(tooltip_text,15)
 label.position = Vector2(60,6)
 label.size = Vector2(126,44)
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(label)
 checkpoint = SaveManager.state.get("checkpoints",[1]).has(id)
 locked = not CampaignManager.can_play(id)
 current = id == int(SaveManager.state.get("frontline",1)) and not bool(SaveManager.state.get("campaign_complete",false))
 tint = UI.ORANGE if current else UI.CYAN if CampaignManager.territory_state(id) == "CONTROLLED" else Color("F04B45")
func _draw() -> void:
 var center := Vector2(27,32)
 if best_stars > 0:
  for star in 3:
   var points := PackedVector2Array()
   for point in 10:
    points.append(Vector2(67+star*15,59)+Vector2.from_angle(-PI/2+point*PI/5)*(6 if point%2 == 0 else 2.7))
   draw_colored_polygon(points,UI.ORANGE if star < best_stars else Color("52626f"))
 draw_circle(center+Vector2(0,3),26,Color(0,0,0,.4))
 draw_circle(center,24,Color("101d29"))
 draw_arc(center,24,0,TAU,40,Color(tint,.8),1.4,true)
 if current:
  var pulse := .45 if SaveManager.settings.reduced_motion else .45+.15*sin(clock*3)
  draw_arc(center,28,0,TAU,40,Color(tint,pulse),1.6,true)
 draw_string(UI.MONO,Vector2(14,38),"%02d" % mission_id,HORIZONTAL_ALIGNMENT_LEFT,-1,18,tint)
 if checkpoint:
  draw_texture_rect(preload("res://assets/ui/icon_checkpoint.svg"),Rect2(36,42,18,18),false,UI.CYAN)
 elif locked:
  draw_texture_rect(preload("res://assets/ui/icon_lock.svg"),Rect2(37,43,16,16),false,Color("a4afb9"))
 if has_focus() or accent_alpha > 0:
  draw_arc(center,30,0,TAU,40,Color(UI.WHITE,maxf(.45,accent_alpha)),1.4,true)
