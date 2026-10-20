extends VBoxContainer
# Native Controls own touch hit areas; battlefield receives unhandled slot presses.
signal abort_requested
const UI := preload("res://scripts/ui/ui_kit.gd")
var battle: Node2D
var readout: Label
var pause_button: Button
var speed_button: Button
var wave_button: Button
var wave_label: Label
var selection_label: Label
var details: Label
var upgrade_button: Button
var build_buttons: Dictionary = {}
var player_panel: Control
var side_panel: PanelContainer
var top_panel: Control
var bottom_panel: Control

func setup(simulation: Node2D) -> void:
 battle = simulation
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_theme_constant_override("separation",12)
 var top := HBoxContainer.new()
 top_panel = top
 top.mouse_filter = Control.MOUSE_FILTER_IGNORE
 top.add_theme_constant_override("separation",10)
 add_child(top)
 readout = UI.label("",19,UI.CYAN)
 readout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 top.add_child(readout)
 pause_button = UI.button("Pause",func(): battle.set_paused(not battle.paused),Vector2(120,54))
 speed_button = UI.button("1x speed",func(): battle.toggle_speed(),Vector2(130,54))
 top.add_child(pause_button)
 top.add_child(speed_button)
 var middle := HBoxContainer.new()
 middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
 middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
 add_child(middle)
 var field := Control.new()
 field.mouse_filter = Control.MOUSE_FILTER_IGNORE
 field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 middle.add_child(field)
 var panel := PanelContainer.new()
 side_panel = panel
 panel.custom_minimum_size.x = 300
 var style := StyleBoxFlat.new()
 style.bg_color = Color("101f2c")
 style.border_color = Color("345565")
 style.set_border_width_all(1)
 style.set_corner_radius_all(8)
 style.set_content_margin_all(14)
 panel.add_theme_stylebox_override("panel",style)
 middle.add_child(panel)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",6)
 panel.add_child(stack)
 wave_label = UI.label("",18,UI.CYAN)
 stack.add_child(wave_label)
 wave_button = UI.button("Start wave",func(): battle.start_wave(),Vector2(0,52))
 stack.add_child(wave_button)
 stack.add_child(HSeparator.new())
 selection_label = UI.label("SELECT A BUILD SLOT",18)
 stack.add_child(selection_label)
 details = UI.label("",16,UI.MUTED)
 details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 details.custom_minimum_size = Vector2(265,44)
 stack.add_child(details)
 for kind in CampaignManager.turrets:
  var definition: Dictionary = CampaignManager.turrets[kind]
  var button := UI.button("%s • %d\n%d DMG  /  %s/s  /  %d RNG" % [definition.name,int(definition.cost),int(definition.damage),str(definition.fire_rate),int(definition.range)],_build.bind(str(kind)),Vector2(270,58))
  button.add_theme_font_size_override("font_size",16)
  stack.add_child(button)
  build_buttons[kind] = button
 upgrade_button = UI.button("Upgrade",func(): battle.upgrade_selected(),Vector2(270,58))
 stack.add_child(upgrade_button)
 var spacer := Control.new()
 spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
 spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stack.add_child(spacer)
 player_panel = preload("res://scripts/ui/player_weapon_hud.gd").new()
 stack.add_child(player_panel)
 player_panel.setup(battle)
 var bottom := HBoxContainer.new()
 bottom_panel = bottom
 bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(bottom)
 bottom.add_child(UI.button("Abort mission",func(): abort_requested.emit(),Vector2(170,50)))
 var hint := UI.label("   LEFT DRAG: AIM   •   HOLD FIRE   •   TAP SLOTS TO BUILD",16,UI.MUTED)
 bottom.add_child(hint)
 battle.player_controls.ui_hit_test = blocks_pointer
 battle.status_changed.connect(refresh)
 battle.selection_changed.connect(refresh)
 refresh()

func _build(kind: String) -> void:
 battle.build_turret(kind)

func refresh() -> void:
 if not is_instance_valid(battle):
  return
 var spawner: Node = battle.spawner
 var wave_number: int = mini(spawner.wave+2 if spawner.intermission else spawner.wave+1,spawner.waves.size())
 var remaining: int = spawner.remaining_to_spawn()+battle.living_count()
 readout.text = "BASE %d / %d   |   WAVE %d / %d   |   ENEMIES %d   |   CREDITS %d" % [battle.health,int(battle.mission_data.base_health),wave_number,spawner.waves.size(),remaining,battle.credits]
 pause_button.text = "Resume" if battle.paused else "Pause"
 speed_button.text = "%dx speed" % int(battle.game_speed)
 wave_label.text = "BUILD PHASE • %ds" % maxi(0,int(ceil(spawner.timer))) if spawner.intermission else "WAVE %d INCOMING" % wave_number
 wave_button.text = "Start wave %d early" % wave_number if spawner.intermission else "Clear the airspace"
 wave_button.disabled = battle.paused or not spawner.intermission or battle.finished
 var selected: int = battle.selected_slot
 var turret: Node2D = battle.placed[selected] if selected >= 0 else null
 selection_label.text = "SLOT %d / %s" % [selected+1,"READY" if turret == null else "LEVEL %d" % turret.level] if selected >= 0 else "SELECT A BUILD SLOT"
 for kind in build_buttons:
  var button: Button = build_buttons[kind]
  button.visible = turret == null
  button.disabled = battle.paused or battle.finished or selected < 0 or battle.credits < int(CampaignManager.turrets[kind].cost)
 upgrade_button.visible = turret != null
 if turret != null:
  details.text = "%s\n%.0f damage • %s shots/s\n%.0f range • +%.0f splash" % [turret.definition.name,turret.damage_value(),str(turret.definition.fire_rate),turret.range_value(),float(turret.definition.splash_radius)]
  var maximum: bool = turret.level >= int(CampaignManager.combat.max_turret_level)
  upgrade_button.text = "Maximum level" if maximum else "Upgrade → L%d • %d" % [turret.level+1,turret.upgrade_cost()]
  upgrade_button.disabled = maximum or battle.paused or battle.finished or battle.credits < turret.upgrade_cost()
 else:
  details.text = "Tap a slot to build defenses.\nBattle credits reset on retry."

func blocks_pointer(point: Vector2) -> bool:
 return side_panel.get_global_rect().has_point(point) or top_panel.get_global_rect().has_point(point) or bottom_panel.get_global_rect().has_point(point)
