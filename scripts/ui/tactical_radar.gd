extends Control
# Native, non-interactive telemetry: never claims or blocks an aiming pointer.
const UI := preload("res://scripts/ui/ui_kit.gd")
const FONT := preload("res://assets/ui/fonts/Barlow-Regular.ttf")
var panel_style: StyleBoxFlat
var battle: Node2D

func _init() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 custom_minimum_size.y = 58
 panel_style = UI.theme().get_stylebox("panel","PanelContainer").duplicate()
 panel_style.bg_color = Color("151b24d9")

func _draw() -> void:
 if not is_instance_valid(battle) or battle.spawner == null or battle.spawner.plan.is_empty():
  return
 var scheduler: Node = battle.spawner
 var plan: Dictionary = scheduler.plan
 var prep: bool = scheduler.intermission
 var accent: Color = UI.ORANGE if prep else UI.CYAN
 var width := minf(size.x,610)
 var left := (size.x-width)*.5
 panel_style.border_color = Color(accent,.5)
 draw_style_box(panel_style,Rect2(left,0,width,56 if prep else 26))
 draw_rect(Rect2(left,0,3,56 if prep else 26),accent)
 var title := "RADAR / "+str(plan.name)
 if prep:
  title += " / %ds" % int(ceil(scheduler.warning_remaining)) if scheduler.warning_remaining > 0 else " / READY"
 else:
  title = "%s / W %d  C %d  E %d" % [plan.name,plan.sectors.WEST,plan.sectors.CENTER,plan.sectors.EAST]
 draw_string(FONT,Vector2(left+12,20),title,HORIZONTAL_ALIGNMENT_LEFT,width-24,15,accent)
 if not prep:
  return
 var sectors: Dictionary = plan.sectors
 var line := "W %d   ·   C %d   ·   E %d   /   DEFEND SENTINEL BASE" % [sectors.WEST,sectors.CENTER,sectors.EAST]
 if int(plan.support_budget) > 0:
  line += " + SUPPORT"
 if plan.adaptive:
  line += " / RECON"
 draw_string(FONT,Vector2(left+12,43),line,HORIZONTAL_ALIGNMENT_LEFT,width-24,14,UI.WHITE)
