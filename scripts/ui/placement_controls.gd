extends VBoxContainer
const UI := preload("res://scripts/ui/ui_kit.gd")
var battle: Node2D
var move_button: Button
var confirm_button: Button
var cancel_button: Button
var turn_row: HBoxContainer
var left_button: Button
var right_button: Button
var bearing: Label
var hint: Label

func setup(owner_battle: Node2D) -> void:
 battle = owner_battle
 hint = UI.label("",15,UI.CYAN)
 hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 add_child(hint)
 move_button = UI.button("Move turret",func(): battle.movement.begin(battle.selected_slot),Vector2(265,48))
 add_child(move_button)
 turn_row = HBoxContainer.new()
 add_child(turn_row)
 left_button = UI.button("↶ %.0f°" % float(preload("res://scripts/game/placement_rules.gd").CONFIG.bearing_step_degrees),_turn.bind(-1),Vector2(88,44))
 turn_row.add_child(left_button)
 bearing = UI.label("",14)
 bearing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 bearing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 turn_row.add_child(bearing)
 right_button = UI.button("%.0f° ↷" % float(preload("res://scripts/game/placement_rules.gd").CONFIG.bearing_step_degrees),_turn.bind(1),Vector2(88,44))
 turn_row.add_child(right_button)
 confirm_button = UI.button("Confirm move",func(): battle.movement.confirm(),Vector2(265,48))
 confirm_button.add_theme_font_size_override("font_size",15)
 add_child(confirm_button)
 cancel_button = UI.button("Cancel move selection",func(): battle.movement.cancel(),Vector2(265,44))
 add_child(cancel_button)

func _turn(steps: int) -> void:
 if battle.selected_slot >= 0 and is_instance_valid(battle.placed[battle.selected_slot]):
  battle.placed[battle.selected_slot].rotate_bearing(steps)

func refresh() -> void:
 var selected: int = battle.selected_slot
 var turret: Node2D = battle.placed[selected] if selected >= 0 else null
 var movement: RefCounted = battle.movement
 var choosing: bool = movement.source >= 0 and not movement.active
 visible = battle.build_mode and (is_instance_valid(turret) or choosing)
 move_button.visible = not choosing
 turn_row.visible = not choosing
 confirm_button.visible = choosing
 cancel_button.visible = choosing
 if choosing:
  hint.text = movement.message
  confirm_button.text = "Confirm S%d→S%d / %d BC / %.0fs" % [movement.source+1,movement.destination+1,movement.quote(movement.actor),movement.duration()] if movement.destination >= 0 else "Choose an empty slot"
  confirm_button.disabled = battle.paused or movement.destination < 0 or battle.credits < movement.quote(movement.actor)
 elif is_instance_valid(turret):
  var data: Dictionary = battle.mission_data.emplacements[selected]
  hint.text = "%s / %s • ARC %.0f°\nMove: %d BC / %.0fs offline" % [data.sector,str(data.role).to_upper(),float(turret.definition.traverse_degrees),movement.quote(turret),movement.duration()]
  move_button.text = "Move / %d BC / %.0fs" % [movement.quote(turret),movement.duration()]
  move_button.disabled = movement.active or battle.paused or battle.finished
  left_button.disabled = turret.redeploying or battle.paused or battle.finished
  right_button.disabled = left_button.disabled
  bearing.text = "%.0f°" % rad_to_deg(turret.bearing)
