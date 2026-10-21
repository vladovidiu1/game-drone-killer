extends Control
const UI := preload("res://scripts/ui/ui_kit.gd")
var controller: Node
var hud: Control
var panel: PanelContainer
var title: Label
var instruction: Label
var progress: Label
var next_button: Button
var skip_button: Button
var age := 0.0
var transition: Tween

func setup(guide: Node, battle_hud: Control) -> void:
 controller = guide
 hud = battle_hud
 z_index = 12
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 panel = UI.panel(UI.CYAN,12)
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(panel)
 panel.minimum_size_changed.connect(func(): _layout.call_deferred())
 var column := VBoxContainer.new()
 column.mouse_filter = Control.MOUSE_FILTER_IGNORE
 column.add_theme_constant_override("separation",6)
 panel.add_child(column)
 title = UI.label("",23,UI.CYAN)
 title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 column.add_child(title)
 instruction = UI.label("",20)
 instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 column.add_child(instruction)
 progress = UI.label("",13,UI.MUTED)
 progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 progress.max_lines_visible = 3
 column.add_child(progress)
 var actions := HBoxContainer.new()
 actions.add_theme_constant_override("separation",8)
 column.add_child(actions)
 next_button = UI.button("Skip intro",func():
  if controller.phase == 0:
   controller.skip_intro()
  else:
   controller.acknowledge(),Vector2(170,48))
 next_button.add_theme_font_size_override("font_size",16)
 actions.add_child(next_button)
 skip_button = UI.button("Skip tutorial",func(): controller.finish("skipped"),Vector2(170,48))
 skip_button.add_theme_font_size_override("font_size",16)
 actions.add_child(skip_button)
 controller.changed.connect(refresh)
 resized.connect(_layout)
 refresh()

func refresh() -> void:
 var step: Dictionary = controller.description()
 title.text = str(step.title)
 instruction.text = str(step.text)
 progress.text = "GUIDED DRILL / practice credits and targets do not carry into the live mission."
 if not controller.error.is_empty():
  progress.text = controller.error
 next_button.visible = controller.phase in [0,7]
 next_button.text = "Skip intro" if controller.phase == 0 else "Begin live defense"
 if is_instance_valid(transition):
  transition.kill()
 panel.modulate.a = 1.0
 if not SaveManager.settings.get("reduced_motion",false):
  panel.modulate.a = .7
  transition = create_tween()
  transition.tween_property(panel,"modulate:a",1.0,.14)
 _layout.call_deferred()
 queue_redraw()

func _layout() -> void:
 if not is_instance_valid(hud):
  return
 var field: Rect2 = hud.radar.get_parent().get_global_rect()
 var width := 640.0 if controller.phase == 0 else 360.0
 panel.size.x = minf(width,maxf(360,field.size.x-24))
 var left: bool = controller.phase == 5 and controller.incoming_sector == "EAST"
 if controller.phase == 6 and controller.first_turret() != null:
  left = controller.first_turret().global_position.x > field.get_center().x
 var offset: float = maxf(4,(field.size.x-panel.size.x)*.5) if controller.phase == 0 else 8.0 if left else maxf(8,field.size.x-panel.size.x-8)
 panel.position = field.position-global_position+Vector2(offset,66)
 panel.size.y = 0

func blocks_pointer(point: Vector2) -> bool:
 return skip_button.get_global_rect().has_point(point) or next_button.visible and next_button.get_global_rect().has_point(point)

func _process(delta: float) -> void:
 if not is_instance_valid(controller) or not controller.active:
  return
 if not controller.battle.paused:
  age += delta
 queue_redraw()

func highlight() -> Rect2:
 var battle: Node2D = controller.battle
 match controller.phase:
  1:
   var origin: Vector2 = battle.get_global_transform_with_canvas()*Vector2(24,326)
   return Rect2(origin,Vector2(430,230)*battle.scale)
  2:
   return hud.player_panel.fire_button.get_global_rect()
  3:
   return hud.player_panel.reload_button.get_global_rect()
  4:
   if battle.selected_slot >= 0 and battle.placed[battle.selected_slot] == null and hud.build_buttons.machine_gun.is_visible_in_tree():
    return hud.build_buttons.machine_gun.get_global_rect()
   for index in battle.slots.size():
    if battle.placed[index] == null:
     var point: Vector2 = battle.get_global_transform_with_canvas()*battle.slots[index]
     return Rect2(point-Vector2.ONE*36*battle.scale,Vector2.ONE*72*battle.scale)
  6:
   if battle.selected_slot >= 0 and battle.placed[battle.selected_slot] != null and hud.upgrade_button.is_visible_in_tree():
    return hud.upgrade_button.get_global_rect()
   var turret: Node2D = controller.first_turret()
   if turret != null:
    var point: Vector2 = battle.get_global_transform_with_canvas()*turret.position
    return Rect2(point-Vector2.ONE*36*battle.scale,Vector2.ONE*72*battle.scale)
  7:
   return hud.stat_cards.base.get_global_rect()
 return Rect2()

func _draw() -> void:
 if not is_instance_valid(controller) or not controller.active:
  return
 if controller.phase == 1:
  var cannon: Vector2 = controller.battle.get_global_transform_with_canvas()*controller.battle.player_turret.position-global_position
  draw_arc(cannon,48*controller.battle.scale.x,0,TAU,32,UI.CYAN,2,true)
 var rect := highlight()
 if rect.size == Vector2.ZERO:
  return
 rect.position -= global_position
 var alpha := .85 if SaveManager.settings.get("reduced_motion",false) else .65+.25*sin(age*3)
 draw_rect(rect.grow(4),Color(UI.ORANGE,alpha),false,2.5)
 var point := Vector2(rect.get_center().x,rect.position.y-12)
 draw_polyline(PackedVector2Array([point+Vector2(-7,-7),point,point+Vector2(7,-7)]),Color(UI.ORANGE,alpha),2,true)
