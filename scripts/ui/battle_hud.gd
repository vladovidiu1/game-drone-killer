extends VBoxContainer
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
var shop_scroll: ScrollContainer
var close_button: Button
var ability_buttons: Dictionary = {}

func setup(simulation: Node2D) -> void:
 battle = simulation
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_theme_constant_override("separation",10)
 var top := HBoxContainer.new()
 top_panel = top
 top.mouse_filter = Control.MOUSE_FILTER_IGNORE
 top.add_theme_constant_override("separation",8)
 add_child(top)
 readout = UI.label("",17,UI.CYAN)
 readout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 top.add_child(readout)
 pause_button = UI.button("Pause",func(): battle.set_paused(not battle.paused),Vector2(110,50))
 speed_button = UI.button("1x speed",func(): battle.toggle_speed(),Vector2(130,50))
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
 side_panel = PanelContainer.new()
 side_panel.custom_minimum_size.x = 300
 var style := StyleBoxFlat.new()
 style.bg_color = Color("101f2c")
 style.border_color = Color("345565")
 style.set_border_width_all(1)
 style.set_corner_radius_all(8)
 style.set_content_margin_all(10)
 side_panel.add_theme_stylebox_override("panel",style)
 middle.add_child(side_panel)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",6)
 side_panel.add_child(stack)
 var wave_row := HBoxContainer.new()
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
 shop_scroll.custom_minimum_size.y = 75
 shop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 stack.add_child(shop_scroll)
 var shop := VBoxContainer.new()
 shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 shop.add_theme_constant_override("separation",5)
 shop_scroll.add_child(shop)
 for kind in CampaignManager.turrets:
  var definition: Dictionary = CampaignManager.turrets[kind]
  var button := UI.button("%s • %d BC\n%.0f damage / %.1f rate / %.0f range" % [definition.name,int(definition.cost),float(definition.damage),float(definition.fire_rate),float(definition.range)],_build.bind(str(kind)),Vector2(265,52))
  if kind == "laser":
   button.text = "%s • %d BC\n%.0f DPS / %.0f range" % [definition.name,int(definition.cost),float(definition.damage),float(definition.range)]
  elif kind == "emp_tower":
   button.text = "%s • %d BC\n%.0f%% slow / %.1fs / %.0f range" % [definition.name,int(definition.cost),(1.0-float(definition.slow_factor))*100,float(definition.status_duration),float(definition.range)]
  button.add_theme_font_size_override("font_size",14)
  shop.add_child(button)
  build_buttons[kind] = button
 upgrade_button = UI.button("Upgrade",func(): battle.upgrade_selected(),Vector2(270,48))
 stack.add_child(upgrade_button)
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
  var button := UI.button(str(pair[1]),_ability.bind(str(pair[0])),Vector2(88,52))
  button.add_theme_font_size_override("font_size",13)
  abilities.add_child(button)
  ability_buttons[pair[0]] = button
 var bottom := HBoxContainer.new()
 bottom_panel = bottom
 bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(bottom)
 bottom.add_child(UI.button("Abort mission",func(): abort_requested.emit(),Vector2(170,46)))
 bottom.add_child(UI.label("   LEFT DRAG: AIM • HOLD FIRE • BUILD MODE: 0.25x",16,UI.MUTED))
 battle.player_controls.ui_hit_test = blocks_pointer
 battle.status_changed.connect(refresh)
 battle.selection_changed.connect(refresh)
 refresh()

func _build(kind: String) -> void:
 battle.build_turret(kind)

func _ability(id: String) -> void:
 battle.abilities.activate(id)

func refresh() -> void:
 if not is_instance_valid(battle):
  return
 var spawner: Node = battle.spawner
 var wave_number: int = mini(spawner.wave+2 if spawner.intermission else spawner.wave+1,spawner.waves.size())
 readout.text = "BASE %d/%d | WAVE %d/%d | ENEMIES %d | BATTLE CREDITS %d" % [battle.health,battle.max_health,wave_number,spawner.waves.size(),spawner.remaining_to_spawn()+battle.living_count(),battle.credits]
 pause_button.text = "Resume" if battle.paused else "Pause"
 speed_button.text = "0.25x / BUILD" if battle.build_mode else "%dx speed" % int(battle.game_speed)
 speed_button.disabled = battle.build_mode
 wave_label.text = "BUILD %ds" % maxi(0,int(ceil(spawner.timer))) if spawner.intermission else "WAVE %d" % wave_number
 wave_button.disabled = battle.paused or not spawner.intermission or battle.finished
 var selected: int = battle.selected_slot
 var turret: Node2D = battle.placed[selected] if selected >= 0 else null
 selection_label.text = "SLOT %d / L%d" % [selected+1,turret.level if turret != null else 0] if selected >= 0 else "SELECT A SLOT"
 close_button.visible = battle.build_mode
 shop_scroll.visible = battle.build_mode and turret == null
 upgrade_button.visible = battle.build_mode and turret != null
 for kind in build_buttons:
  var button: Button = build_buttons[kind]
  button.disabled = battle.paused or battle.finished or selected < 0 or not EconomyManager.unlocked(kind) or battle.credits < int(CampaignManager.turrets[kind].cost)
  if not EconomyManager.unlocked(kind):
   button.text = "%s • LOCKED\nResearch in Arsenal" % CampaignManager.turrets[kind].name
 if turret != null:
  details.text = "%s / %.1f DMG • %.2f rate • %.0f range" % [turret.definition.name,turret.damage_value(),turret.fire_rate_value(),turret.range_value()]
  if turret.kind == "laser":
   details.text = "Laser / %.1f sustained DPS • %.0f range" % [turret.damage_value()*turret.fire_rate_value()/float(turret.definition.fire_rate),turret.range_value()]
  elif turret.kind == "emp_tower":
   details.text = "EMP / %.0f%% slow for %.1fs • %.1fs cycle" % [(1.0-float(turret.definition.slow_factor))*100,float(turret.definition.status_duration),1.0/turret.fire_rate_value()]
  var maximum: bool = turret.level >= int(CampaignManager.combat.max_turret_level)
  upgrade_button.text = "Maximum level" if maximum else "Upgrade → L%d • %d BC" % [turret.level+1,turret.upgrade_cost()]
  upgrade_button.disabled = maximum or battle.paused or battle.finished or battle.credits < turret.upgrade_cost()
 else:
  details.text = "Tap a slot to build. Scroll to see all six designs. Close restores your previous speed."
 for id in ability_buttons:
  var data: Dictionary = SaveManager.catalog.abilities[id]
  var cooldown: float = battle.abilities.cooldowns[id]
  var button: Button = ability_buttons[id]
  button.text = ("REPAIR" if id == "repair" else ("EMP" if id == "emp_blast" else "BOOST"))+"\n"+("%.0fs" % ceil(cooldown) if cooldown > 0 else "%d BC" % int(data.cost))
  if id == "overclock" and battle.abilities.overclock_remaining > 0:
   button.text = "BOOST ACTIVE\n%.1fs" % battle.abilities.overclock_remaining
  button.disabled = not battle.abilities.can_activate(id)

func blocks_pointer(point: Vector2) -> bool:
 return side_panel.get_global_rect().has_point(point) or top_panel.get_global_rect().has_point(point) or bottom_panel.get_global_rect().has_point(point)
