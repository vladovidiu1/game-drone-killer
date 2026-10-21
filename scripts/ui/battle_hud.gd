extends VBoxContainer
signal abort_requested
const UI := preload("res://scripts/ui/ui_kit.gd")
var battle: Node2D
var readout: Label
var base_bar: ProgressBar
var pause_button: Button
var wave_button: Button
var wave_label: Label
var selection_label: Label
var details: Label
var placement_controls: Control
var shop: VBoxContainer
var progress_row: VBoxContainer
var move_progress: ProgressBar
var move_status: Label
var coverage_button: Button
var upgrade_button: Button
var build_buttons: Dictionary = {}
var player_panel: Control
var side_panel: PanelContainer
var top_panel: Control
var bottom_panel: Control
var shop_scroll: ScrollContainer
var close_button: Button
var ability_buttons: Dictionary = {}
var stat_cards: Dictionary = {}
var stack: VBoxContainer
var radar: Control
var wave_row: HBoxContainer

func setup(simulation: Node2D) -> void:
 battle = simulation
 z_index = 10
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_theme_constant_override("separation",10)
 var top := HBoxContainer.new()
 top_panel = top
 top.mouse_filter = Control.MOUSE_FILTER_IGNORE
 top.add_theme_constant_override("separation",8)
 add_child(top)
 var telemetry := HBoxContainer.new()
 telemetry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 telemetry.mouse_filter = Control.MOUSE_FILTER_IGNORE
 telemetry.add_theme_constant_override("separation",8)
 top.add_child(telemetry)
 for item in [["base","BASE INTEGRITY","shield"],["wave","WAVE","wave"],["enemies","AIR THREATS","drone"],["credits","BATTLE CREDITS","credits"]]:
  var card := preload("res://scripts/ui/telemetry_card.gd").new()
  telemetry.add_child(card)
  card.setup(str(item[1]),str(item[2]),UI.ORANGE if item[0] == "enemies" else UI.CYAN)
  stat_cards[item[0]] = card
 readout = UI.label("",16,UI.WHITE)
 readout.visible = false
 telemetry.add_child(readout)
 base_bar = stat_cards.base.meter
 pause_button = UI.button("Pause",func(): battle.set_paused(not battle.paused),Vector2(110,50))
 pause_button.icon = UI.icon("pause")
 pause_button.add_theme_font_size_override("font_size",16)
 top.add_child(pause_button)
 var middle := HBoxContainer.new()
 middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
 middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
 add_child(middle)
 var field := Control.new()
 field.mouse_filter = Control.MOUSE_FILTER_IGNORE
 field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 middle.add_child(field)
 radar = preload("res://scripts/ui/tactical_radar.gd").new()
 radar.battle = battle
 field.add_child(radar)
 radar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
 side_panel = UI.panel(UI.CYAN,6)
 side_panel.custom_minimum_size.x = 300
 middle.add_child(side_panel)
 stack = VBoxContainer.new()
 stack.add_theme_constant_override("separation",4)
 side_panel.add_child(stack)
 wave_row = HBoxContainer.new()
 stack.add_child(wave_row)
 wave_label = UI.label("",14,UI.CYAN)
 wave_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 wave_row.add_child(wave_label)
 wave_button = UI.button("Start early",func(): battle.start_wave(),Vector2(130,44))
 wave_button.add_theme_font_size_override("font_size",16)
 wave_row.add_child(wave_button)
 var selection := HBoxContainer.new()
 stack.add_child(selection)
 selection_label = UI.label("",16)
 selection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 selection.add_child(selection_label)
 close_button = UI.button("Close",func(): battle.close_build_mode(),Vector2(85,44))
 close_button.add_theme_font_size_override("font_size",15)
 selection.add_child(close_button)
 details = UI.label("",14,UI.MUTED)
 details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 details.custom_minimum_size = Vector2(270,32)
 stack.add_child(details)
 shop_scroll = ScrollContainer.new()
 shop_scroll.custom_minimum_size.y = 64
 shop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 stack.add_child(shop_scroll)
 var actions := VBoxContainer.new()
 actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 shop_scroll.add_child(actions)
 shop = VBoxContainer.new()
 shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 shop.add_theme_constant_override("separation",5)
 actions.add_child(shop)
 for kind in CampaignManager.turrets:
  var definition: Dictionary = CampaignManager.turrets[kind]
  var button := UI.button("%s • %d BC\n%.0f damage / %.1f rate / %.0f range" % [definition.name,int(definition.cost),float(definition.damage),float(definition.fire_rate),float(definition.range)],_build.bind(str(kind)),Vector2(265,52))
  if kind == "laser":
   button.text = "%s • %d BC\n%.0f DPS / %.0f range" % [definition.name,int(definition.cost),float(definition.damage),float(definition.range)]
  elif kind == "emp_tower":
   button.text = "%s • %d BC\n%.0f%% slow / %.1fs / %.0f range" % [definition.name,int(definition.cost),(1.0-float(definition.slow_factor))*100,float(definition.status_duration),float(definition.range)]
  button.text += "\nARC %.0f°" % float(definition.traverse_degrees)
  button.add_theme_font_size_override("font_size",14)
  button.icon = preload("res://scripts/visual/visual_assets.gd").sprite(str(preload("res://scripts/visual/visual_assets.gd").catalog.turret_aliases[kind]))
  button.expand_icon = true
  button.add_theme_constant_override("icon_max_width",34)
  shop.add_child(button)
  build_buttons[kind] = button
 upgrade_button = UI.button("Upgrade",func(): battle.upgrade_selected(),Vector2(270,48))
 actions.add_child(upgrade_button)
 placement_controls = preload("res://scripts/ui/placement_controls.gd").new()
 actions.add_child(placement_controls)
 placement_controls.setup(battle)
 progress_row = VBoxContainer.new()
 stack.add_child(progress_row)
 var move_row := HBoxContainer.new()
 progress_row.add_child(move_row)
 move_status = UI.label("",13,UI.ORANGE)
 move_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 move_row.add_child(move_status)
 var cancel_move := UI.button("Cancel",func(): battle.movement.cancel(),Vector2(86,44))
 cancel_move.add_theme_font_size_override("font_size",14)
 move_row.add_child(cancel_move)
 move_progress = ProgressBar.new()
 move_progress.custom_minimum_size.y = 6
 move_progress.show_percentage = false
 progress_row.add_child(move_progress)
 var spacer := Control.new()
 spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
 stack.add_child(spacer)
 player_panel = preload("res://scripts/ui/player_weapon_hud.gd").new()
 stack.add_child(player_panel)
 player_panel.setup(battle)
 var abilities := HBoxContainer.new()
 abilities.add_theme_constant_override("separation",4)
 stack.add_child(abilities)
 for pair in [["repair","REPAIR"],["emp_blast","EMP"],["overclock","BOOST"]]:
  var button := UI.button(str(pair[1]),_ability.bind(str(pair[0])),Vector2(88,48))
  button.add_theme_font_size_override("font_size",13)
  button.icon = UI.icon({"repair":"repair","emp_blast":"ability","overclock":"speed"}[str(pair[0])])
  button.expand_icon = true
  button.add_theme_constant_override("icon_max_width",14)
  button.add_theme_constant_override("h_separation",4)
  abilities.add_child(button)
  ability_buttons[pair[0]] = button
 var bottom := HBoxContainer.new()
 bottom_panel = bottom
 bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(bottom)
 bottom.add_child(UI.button("Abort mission",func(): abort_requested.emit(),Vector2(170,46)))
 coverage_button = UI.button("Coverage OFF",func():
  battle.coverage_visible = not battle.coverage_visible
  battle.status_changed.emit(),Vector2(140,46))
 coverage_button.add_theme_font_size_override("font_size",14)
 bottom.add_child(coverage_button)
 var input_hint := UI.label("LEFT DRAG: AIM • HOLD FIRE • BUILD: 0.25x" if OS.has_feature("mobile") else "AIM + HOLD LMB • R: RELOAD • BUILD: 0.25x",14,UI.MUTED)
 input_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 input_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 bottom.add_child(input_hint)
 var operation := UI.label("%02d / %s" % [battle.mission_id,str(battle.mission_data.name).to_upper()],16,UI.CYAN)
 operation.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 bottom.add_child(operation)
 battle.player_controls.ui_hit_test = blocks_pointer
 resized.connect(_layout)
 battle.status_changed.connect(refresh)
 battle.selection_changed.connect(refresh)
 refresh()

func _layout() -> void:
 if not is_instance_valid(battle) or not is_instance_valid(player_panel):
  return
 var compact := size.y < 620
 wave_row.visible = not (compact and battle.build_mode)
 details.visible = not compact
 shop_scroll.custom_minimum_size.y = 52 if compact else 64
 player_panel.fire_button.custom_minimum_size.y = 56 if compact else 58
 player_panel.reload_button.custom_minimum_size.y = 56 if compact else 58
 for id in ability_buttons:
  ability_buttons[id].custom_minimum_size.y = 44 if compact else 48

func _build(kind: String) -> void:
 battle.build_turret(kind)

func _ability(id: String) -> void:
 battle.abilities.activate(id)

func refresh() -> void:
 if not is_instance_valid(battle):
  return
 _layout()
 base_bar.value = 100.0*battle.health/battle.max_health
 var spawner: Node = battle.spawner
 var wave_number: int = mini(spawner.wave+2 if spawner.intermission else spawner.wave+1,spawner.waves.size())
 readout.text = "BASE %d/%d | WAVE %d/%d | ENEMIES %d | BATTLE CREDITS %d" % [battle.health,battle.max_health,wave_number,spawner.waves.size(),spawner.remaining_to_spawn()+battle.living_count(),battle.credits]
 pause_button.text = "Resume" if battle.paused else "Pause"
 wave_label.text = "PREPARE" if spawner.wave < 0 else "BUILD %ds" % maxi(0,int(ceil(spawner.timer))) if spawner.intermission else "WAVE %d" % wave_number
 radar.queue_redraw()
 wave_button.text = "Radar %ds" % int(ceil(spawner.warning_remaining)) if spawner.warning_remaining > 0 else "Launch wave" if spawner.wave < 0 else "Start early"
 wave_button.disabled = battle.paused or not spawner.intermission or battle.finished or spawner.warning_remaining > 0
 stat_cards.base.update_value("%d / %d" % [battle.health,battle.max_health],-1,float(battle.health)/battle.max_health)
 stat_cards.wave.update_value("%02d / %02d" % [wave_number,spawner.waves.size()])
 stat_cards.enemies.update_value("%02d" % (spawner.remaining_to_spawn()+battle.living_count()))
 stat_cards.credits.update_value("%04d" % battle.credits,battle.credits)
 var selected: int = battle.selected_slot
 var turret: Node2D = battle.placed[selected] if selected >= 0 else null
 selection_label.text = "SLOT %d / L%d" % [selected+1,turret.level if turret != null else 0] if selected >= 0 else "SELECT A SLOT"
 close_button.visible = battle.build_mode
 shop_scroll.visible = battle.build_mode
 shop.visible = turret == null and battle.movement.source < 0
 upgrade_button.visible = battle.build_mode and turret != null and battle.movement.source < 0
 placement_controls.refresh()
 coverage_button.text = "Coverage ON" if battle.coverage_visible else "Coverage OFF"
 coverage_button.disabled = battle.finished
 progress_row.visible = battle.movement.active
 if battle.movement.active:
  move_status.text = "MOVE S%d→S%d / %.1fs" % [battle.movement.source+1,battle.movement.destination+1,maxf(0,battle.movement.duration()-battle.movement.elapsed)]
  move_progress.value = 100*battle.movement.elapsed/battle.movement.duration()
 battle.view.placement.queue_redraw()
 for kind in build_buttons:
  var button: Button = build_buttons[kind]
  button.disabled = battle.paused or battle.finished or selected < 0 or not EconomyManager.unlocked(kind) or battle.movement.reserved(selected) or battle.credits < int(CampaignManager.turrets[kind].cost)
  if not EconomyManager.unlocked(kind):
   button.text = "%s • LOCKED\nResearch in Arsenal" % CampaignManager.turrets[kind].name
 if turret != null:
  details.text = "%s / %.1f DMG • %.2f rate • %.0f range" % [turret.definition.name,turret.damage_value(),turret.fire_rate_value(),turret.range_value()]
  if turret.kind == "laser":
   details.text = "Laser / %.1f sustained DPS • %.0f range" % [turret.damage_value()*turret.fire_rate_value()/float(turret.definition.fire_rate),turret.range_value()]
  elif turret.kind == "emp_tower":
   details.text = "EMP / %.0f%% slow for %.1fs • %.1fs cycle" % [(1.0-float(turret.definition.slow_factor))*100,float(turret.definition.status_duration),1.0/turret.fire_rate_value()]
  details.text += "\n"+preload("res://scripts/game/placement_rules.gd").description(turret.definition)
  var maximum: bool = turret.level >= int(CampaignManager.combat.max_turret_level)
  upgrade_button.text = "Maximum level" if maximum else "Upgrade → L%d • %d BC" % [turret.level+1,turret.upgrade_cost()]
  upgrade_button.disabled = maximum or turret.redeploying or battle.paused or battle.finished or battle.credits < turret.upgrade_cost()
 else:
  details.text = "Tap a slot to build. Scroll to see all six designs. Close restores normal combat speed."
 for id in ability_buttons:
  var data: Dictionary = SaveManager.catalog.abilities[id]
  var cooldown: float = battle.abilities.cooldowns[id]
  var button: Button = ability_buttons[id]
  button.text = ("REPAIR" if id == "repair" else ("EMP" if id == "emp_blast" else "BOOST"))+"\n"+("%.0fs" % ceil(cooldown) if cooldown > 0 else "%d BC" % int(data.cost))
  if id == "overclock" and battle.abilities.overclock_remaining > 0:
   button.text = "BOOST\nON %.1fs" % battle.abilities.overclock_remaining
  button.disabled = not battle.abilities.can_activate(id)

func blocks_pointer(point: Vector2) -> bool:
 return side_panel.get_global_rect().has_point(point) or top_panel.get_global_rect().has_point(point) or bottom_panel.get_global_rect().has_point(point)
