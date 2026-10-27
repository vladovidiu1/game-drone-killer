extends VBoxContainer
signal back_requested
const UI := preload("res://scripts/ui/ui_kit.gd")
var current_tab := "primary"
var body: VBoxContainer
var balance: Label
var feedback: Label
var pending := false
var tab_buttons: Dictionary = {}
var grid: GridContainer
var previous_balance := -1

func _ready() -> void:
 add_theme_constant_override("separation",12)
 add_child(UI.label("SENTINEL ENGINEERING / PERMANENT DEVELOPMENT",14,UI.CYAN))
 add_child(UI.label("ARSENAL & RESEARCH",34))
 balance = UI.label("",21)
 add_child(balance)
 var tabs := HBoxContainer.new()
 tabs.add_theme_constant_override("separation",8)
 add_child(tabs)
 for item in [["primary","PRIMARY CANNON"],["projectiles","PROJECTILES"],["automatic","TURRETS"],["research","RESEARCH"],["abilities","ABILITIES"]]:
  var button := UI.button(str(item[1]),select_tab.bind(str(item[0])),Vector2(0,54))
  button.clip_text = true
  button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  button.add_theme_font_size_override("font_size",14)
  button.icon = UI.icon({"primary":"target","projectiles":"ammo","automatic":"arsenal","research":"research","abilities":"ability"}[str(item[0])])
  tabs.add_child(button)
  tab_buttons[item[0]] = button
 feedback = UI.label("Choose a research card to review and confirm its purchase.",17,UI.MUTED)
 add_child(feedback)
 var scroll := preload("res://scripts/ui/touch_scroll.gd").new()
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 add_child(scroll)
 body = VBoxContainer.new()
 body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation",12)
 scroll.add_child(body)
 add_child(UI.button("Back",func(): back_requested.emit()))
 RewardedAdsManager.rewarded.connect(_ad_rewarded)
 resized.connect(_layout_cards)
 refresh()

func _ad_rewarded(_amount: int) -> void:
 refresh()

func _layout_cards() -> void:
 if is_instance_valid(grid):
  grid.columns = 2 if size.x >= 980 else 1

func select_tab(tab: String) -> void:
 current_tab = tab
 refresh()

func paragraph(value: String, size: int = 18, tint: Color = UI.MUTED) -> void:
 var label := UI.label(value,size,tint)
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 body.add_child(label)

func refresh() -> void:
 for child in body.get_children():
  body.remove_child(child)
  child.queue_free()
 for tab in tab_buttons:
  tab_buttons[tab].theme_type_variation = &"TacticalPrimary" if tab == current_tab else &"Button"
 var current_balance := int(SaveManager.state.get("credits",0))
 if previous_balance >= 0 and current_balance != previous_balance:
  UI.flash(balance)
 previous_balance = current_balance
 balance.text = "WAR CREDITS: %d   •   Permanent research survives defeat and retreat" % int(SaveManager.state.get("credits",0))
 if current_tab == "primary":
  var stats := EconomyManager.primary_stats()
  var profile: Dictionary = SaveManager.catalog.ammunition[str(SaveManager.state.get("equipped_ammo","standard"))]
  showcase("gun_primary","SENTINEL-7 / PRIMARY CANNON","%.1f damage  •  %.2f shots/s  •  %d rounds  •  %.2fs reload\n%.0f velocity  •  %.0f%% crit  •  %.2fx critical damage\n%s ammunition / legacy amplifier +%d%% retained" % [stats.damage,stats.fire_rate,int(stats.magazine_size),stats.reload_time,stats.projectile_speed,float(stats.critical_chance)*100,stats.critical_multiplier,profile.name,int(SaveManager.state.get("damage_level",0))*15])
 elif current_tab == "automatic":
  paragraph("Automatic turrets target only within their mounted firing arc and range. Adjust facing, compare coverage or pay to redeploy in battle. Rotation and lock delays still apply. Battle Credits pay construction, levels and moves; War Credits unlock designs.",19,UI.CYAN)
 elif current_tab == "abilities":
  for id in SaveManager.catalog.abilities:
   var ability: Dictionary = SaveManager.catalog.abilities[id]
   paragraph("%s / %d Battle Credits • %.1fs cooldown • %.1fs duration" % [ability.name,int(ability.cost),float(ability.cooldown)*(1.0+EconomyManager.modifier(str(ability.mastery))),float(ability.duration)],19,UI.CYAN)
  paragraph("Emergency Repair restores %d HP. EMP disables drones; Overclock boosts both combat styles by 50%%. Abilities start available and are purchased per activation using Battle Credits." % int(float(SaveManager.catalog.abilities.repair.heal)*(1.0+EconomyManager.modifier("repair_efficiency"))))
 elif current_tab == "research":
  paragraph("CURRENT BASE / %d extra HP • +%d starting Battle Credits • +%.0f%% turret damage • +%.0f%% range • +%.0f%% rate • +%.0f%% repair" % [int(EconomyManager.modifier("base_health")),int(EconomyManager.modifier("starting_credits")),EconomyManager.modifier("turret_damage")*100,EconomyManager.modifier("turret_range")*100,EconomyManager.modifier("turret_rate")*100,EconomyManager.modifier("repair_efficiency")*100],19,UI.CYAN)
  for id in SaveManager.catalog.objectives:
   var objective: Dictionary = SaveManager.catalog.objectives[id]
   paragraph("%s: %s • %d War Credits • %s" % [objective.name,objective.description,int(objective.reward),"CLAIMED" if SaveManager.state.get("claimed_objectives",[]).has(id) else "awarded on eligible victory"])
 body.add_child(preload("res://scripts/ui/rewarded_ad_offer.gd").new())
 if current_tab == "projectiles":
  var technology := preload("res://scripts/ui/projectile_research.gd").new()
  body.add_child(technology)
  technology.purchase_requested.connect(confirm)
  technology.changed.connect(refresh)
  return
 grid = GridContainer.new()
 grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 grid.columns = 2 if size.x >= 980 else 1
 grid.add_theme_constant_override("h_separation",12)
 grid.add_theme_constant_override("v_separation",12)
 body.add_child(grid)
 for id in SaveManager.catalog.upgrades:
  var upgrade: Dictionary = SaveManager.catalog.upgrades[id]
  if upgrade.tab == current_tab:
   add_card(grid,str(id),upgrade)
 if current_tab == "automatic":
  for id in CampaignManager.turrets:
   var turret: Dictionary = EconomyManager.automatic_stats(str(id))
   var description := "%s / %d Battle Credits • %.1f damage • %.1f rate • %.1f range\nTRACK %.0f°/s • LOCK %.2fs" % [turret.name,int(turret.cost),float(turret.damage),float(turret.fire_rate),float(turret.range),float(turret.turn_degrees),float(turret.acquisition_delay)]+"\nARC %.0f° • %s" % [float(turret.traverse_degrees),"Radial support" if id == "emp_tower" else "Mounted forward sector"]
   if SaveManager.catalog.unlocks.has(id):
    add_card(grid,str(id),SaveManager.catalog.unlocks[id],description)
   else:
    var panel := UI.panel()
    grid.add_child(panel)
    var stack := VBoxContainer.new()
    panel.add_child(stack)
    var image := TextureRect.new()
    image.texture = preload("res://scripts/visual/visual_assets.gd").sprite(str(preload("res://scripts/visual/visual_assets.gd").catalog.turret_aliases[id]))
    image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    image.custom_minimum_size.y = 90
    stack.add_child(image)
    var text := UI.label(description+" • AVAILABLE",18)
    text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(text)

  for kind in SaveManager.catalog.turret_specializations:
   var reset := UI.button(str(CampaignManager.turrets[kind].name)+" / Standard tuning",_branch.bind(str(kind),""))
   body.add_child(reset)
   for branch in SaveManager.catalog.turret_specializations[kind]:
    var entry: Dictionary = SaveManager.catalog.turret_specializations[kind][branch]
    var id := str(entry.research)
    var preview_levels: Dictionary = SaveManager.state.get("research",{}).duplicate(true)
    preview_levels[id] = 3
    var preview := preload("res://scripts/core/weapon_technology.gd").turret(str(kind),preview_levels,{kind:branch})
    var summary := "%s / TIER 3: %.1f damage • %.2f rate • %.0f range\n%.0f splash • %.0f%% armor bypass • %.0f%% shield bypass\nOne branch per design; changes apply next deployment." % [CampaignManager.turrets[kind].name,float(preview.damage),float(preview.fire_rate),float(preview.range),float(preview.splash_radius),float(preview.armor_bypass)*100,float(preview.shield_bypass)*100]
    var card := add_card(grid,id,SaveManager.catalog.upgrades[id],summary)
    var selected: bool = SaveManager.state.get("turret_specializations",{}).get(kind,"") == branch
    var equip := UI.button("EQUIPPED" if selected else "Equip branch",_branch.bind(str(kind),str(branch)))
    equip.disabled = selected or EconomyManager.research_level(id) == 0
    card.add_child(equip)

func _branch(kind: String, branch: String) -> void:
 feedback.text = "Specialization saved for next deployment." if EconomyManager.select_specialization(kind,branch) else (SaveManager.last_error if not SaveManager.last_error.is_empty() else "Research this branch first.")
 refresh()

func add_card(grid: GridContainer, id: String, item: Dictionary, extra: String = "") -> VBoxContainer:
 var panel := PanelContainer.new()
 panel.custom_minimum_size.x = 0
 panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var style := StyleBoxFlat.new()
 style.bg_color = Color(.055,.08,.11,.94)
 style.border_color = Color("44657F")
 style.set_border_width_all(1)
 style.set_corner_radius_all(8)
 style.set_content_margin_all(14)
 panel.add_theme_stylebox_override("panel",style)
 grid.add_child(panel)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",8)
 panel.add_child(stack)
 var offer := EconomyManager.purchase_state(id)
 var identity := HBoxContainer.new()
 identity.add_theme_constant_override("separation",12)
 stack.add_child(identity)
 var image := preload("res://scripts/ui/weapon_portrait.gd").new()
 var assets := preload("res://scripts/visual/visual_assets.gd")
 var sprite: String = str(assets.catalog.turret_aliases[id]) if assets.catalog.turret_aliases.has(id) else "gun_primary" if current_tab == "primary" else "gun_emp" if current_tab == "abilities" else "gun_heavy_aa"
 image.setup(sprite,Vector2(64,64))
 identity.add_child(image)
 var name_label := UI.label(str(item.name),23,UI.CYAN)
 name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 identity.add_child(name_label)
 var text := UI.label(str(item.benefit)+( "\n"+extra if not extra.is_empty() else ""),17)
 text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 stack.add_child(text)
 var upgrade: bool = SaveManager.catalog.upgrades.has(id)
 var level_label := UI.label("Level %d / %d • Next: %s" % [int(offer.level),item.costs.size(),item.benefit] if upgrade else "Requirement: highest mission %d" % int(item.highest),16,UI.MUTED)
 level_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 stack.add_child(level_label)
 var levels := HBoxContainer.new()
 levels.add_theme_constant_override("separation",5)
 stack.add_child(levels)
 for index in (item.costs.size() if upgrade else 1):
  var pip := ColorRect.new()
  pip.custom_minimum_size = Vector2(0,5)
  pip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  pip.color = UI.CYAN if index < int(offer.level) else Color("303D4C")
  pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
  levels.add_child(pip)
 var purchase_text := str(offer.reason) if str(offer.reason) in ["MAXIMUM","UNLOCKED"] else "%d War Credits • %s" % [int(offer.cost),str(offer.reason)]
 var buy := UI.button(purchase_text,confirm.bind(id,int(offer.level)))
 buy.clip_text = true
 buy.disabled = not bool(offer.allowed) or pending
 stack.add_child(buy)
 return stack

func confirm(id: String, expected_level: int) -> void:
 if pending:
  return
 var offer := EconomyManager.purchase_state(id)
 if not bool(offer.allowed) or int(offer.level) != expected_level:
  feedback.text = str(offer.reason)
  refresh()
  return
 pending = true
 var dialog := ConfirmationDialog.new()
 UI.prepare_confirmation(dialog)
 dialog.title = "Confirm permanent research"
 dialog.dialog_text = "Spend %d War Credits?\n%s\nBalance after purchase: %d" % [int(offer.cost),id.replace("_"," ").capitalize(),int(SaveManager.state.credits)-int(offer.cost)]
 dialog.confirmed.connect(func():
  var success := EconomyManager.purchase(id,expected_level)
  pending = false
  feedback.text = "Research saved." if success else (SaveManager.last_error if not SaveManager.last_error.is_empty() else "Purchase changed or insufficient funds.")
  refresh()
  if success:
   UI.flash(feedback))
 dialog.canceled.connect(func(): pending = false)
 dialog.confirmed.connect(dialog.queue_free)
 dialog.canceled.connect(dialog.queue_free)
 add_child(dialog)
 dialog.popup_centered()

func showcase(sprite: String, title: String, description: String) -> void:
 var panel := UI.panel()
 body.add_child(panel)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",20)
 panel.add_child(row)
 var image := preload("res://scripts/ui/weapon_portrait.gd").new()
 image.setup(sprite,Vector2(120,94))
 row.add_child(image)
 var stack := VBoxContainer.new()
 stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_child(stack)
 stack.add_child(UI.label(title,27,UI.CYAN))
 var detail := UI.label(description,17,UI.MUTED)
 detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 stack.add_child(detail)
