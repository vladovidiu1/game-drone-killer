extends VBoxContainer
signal back_requested
const UI := preload("res://scripts/ui/ui_kit.gd")
var current_tab := "primary"
var body: VBoxContainer
var balance: Label
var feedback: Label
var pending := false

func _ready() -> void:
 add_theme_constant_override("separation",12)
 add_child(UI.label("SENTINEL RESEARCH COMMAND / ARSENAL",28,UI.CYAN))
 balance = UI.label("",21)
 add_child(balance)
 var tabs := HBoxContainer.new()
 tabs.add_theme_constant_override("separation",8)
 add_child(tabs)
 for item in [["primary","PRIMARY CANNON"],["automatic","AUTOMATIC TURRETS"],["research","RESEARCH"],["abilities","SPECIAL ABILITIES"]]:
  tabs.add_child(UI.button(str(item[1]),select_tab.bind(str(item[0])),Vector2(260,52)))
 feedback = UI.label("Choose a research card to review and confirm its purchase.",17,UI.MUTED)
 add_child(feedback)
 var scroll := ScrollContainer.new()
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 add_child(scroll)
 body = VBoxContainer.new()
 body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation",12)
 scroll.add_child(body)
 add_child(UI.button("Back",func(): back_requested.emit()))
 refresh()

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
 balance.text = "WAR CREDITS: %d   •   Permanent research survives defeat and retreat" % int(SaveManager.state.get("credits",0))
 if current_tab == "primary":
  var stats := EconomyManager.primary_stats()
  paragraph("CURRENT CANNON  /  %.1f damage • %.2f shots/s • %d rounds • %.2fs reload • %.0f velocity • %.0f%% crit • %.2fx critical damage" % [stats.damage,stats.fire_rate,int(stats.magazine_size),stats.reload_time,stats.projectile_speed,float(stats.critical_chance)*100,stats.critical_multiplier],19,UI.CYAN)
  var profile: Dictionary = SaveManager.catalog.ammunition[str(SaveManager.state.get("equipped_ammo","standard"))]
  paragraph("EQUIPPED %s / %.1f damage • %.2f shots/s • %.2fx versus armor • %d rounds per shot" % [profile.name,float(stats.damage)*float(profile.damage_multiplier),float(stats.fire_rate)*float(profile.fire_rate_multiplier),float(profile.armor_multiplier),int(profile.round_cost)])
  paragraph("Legacy amplifier retained: +%d%% damage. Ammunition modifiers and temporary Overclock apply in battle." % (int(SaveManager.state.get("damage_level",0))*15))
 elif current_tab == "automatic":
  paragraph("Automatic turrets retain autonomous targeting. Battle Credits pay construction and temporary levels; War Credits unlock new designs.",19,UI.CYAN)
 elif current_tab == "abilities":
  for id in SaveManager.catalog.abilities:
   var ability: Dictionary = SaveManager.catalog.abilities[id]
   paragraph("%s / %d Battle Credits • %.1fs cooldown • %.1fs duration" % [ability.name,int(ability.cost),float(ability.cooldown)*(1.0+EconomyManager.modifier(str(ability.mastery))),float(ability.duration)],19,UI.CYAN)
  paragraph("Emergency Repair restores %d HP. EMP disables drones; Overclock boosts both combat styles by 50%%. Abilities start available and are purchased per activation using Battle Credits." % int(float(SaveManager.catalog.abilities.repair.heal)*(1.0+EconomyManager.modifier("repair_efficiency"))))
 else:
  paragraph("CURRENT BASE / %d extra HP • +%d starting Battle Credits • +%.0f%% turret damage • +%.0f%% range • +%.0f%% rate • +%.0f%% repair" % [int(EconomyManager.modifier("base_health")),int(EconomyManager.modifier("starting_credits")),EconomyManager.modifier("turret_damage")*100,EconomyManager.modifier("turret_range")*100,EconomyManager.modifier("turret_rate")*100,EconomyManager.modifier("repair_efficiency")*100],19,UI.CYAN)
  for id in SaveManager.catalog.objectives:
   var objective: Dictionary = SaveManager.catalog.objectives[id]
   paragraph("%s: %s • %d War Credits • %s" % [objective.name,objective.description,int(objective.reward),"CLAIMED" if SaveManager.state.get("claimed_objectives",[]).has(id) else "awarded on eligible victory"])
 var grid := GridContainer.new()
 grid.columns = 2
 grid.add_theme_constant_override("h_separation",12)
 grid.add_theme_constant_override("v_separation",12)
 body.add_child(grid)
 for id in SaveManager.catalog.upgrades:
  var upgrade: Dictionary = SaveManager.catalog.upgrades[id]
  if upgrade.tab == current_tab:
   add_card(grid,str(id),upgrade)
 if current_tab == "primary":
  for id in ["armor_piercing","explosive"]:
   add_card(grid,str(id),SaveManager.catalog.unlocks[id])
 if current_tab == "automatic":
  for id in CampaignManager.turrets:
   var turret: Dictionary = EconomyManager.automatic_stats(str(id))
   var description := "%s / %d Battle Credits • %.1f damage • %.1f rate • %.1f range" % [turret.name,int(turret.cost),float(turret.damage),float(turret.fire_rate),float(turret.range)]
   if SaveManager.catalog.unlocks.has(id):
    add_card(grid,str(id),SaveManager.catalog.unlocks[id],description)
   else:
    paragraph(description+" • AVAILABLE")

func add_card(grid: GridContainer, id: String, item: Dictionary, extra: String = "") -> void:
 var panel := PanelContainer.new()
 panel.custom_minimum_size.x = 520
 panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var style := StyleBoxFlat.new()
 style.bg_color = Color("172e3d")
 style.border_color = Color("345869")
 style.set_border_width_all(1)
 style.set_corner_radius_all(8)
 style.set_content_margin_all(14)
 panel.add_theme_stylebox_override("panel",style)
 grid.add_child(panel)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",8)
 panel.add_child(stack)
 var offer := EconomyManager.purchase_state(id)
 stack.add_child(UI.label(str(item.name),23,UI.CYAN))
 var text := UI.label(str(item.benefit)+( "\n"+extra if not extra.is_empty() else ""),17)
 text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 stack.add_child(text)
 var upgrade: bool = SaveManager.catalog.upgrades.has(id)
 stack.add_child(UI.label("Level %d / %d • Next: %s" % [int(offer.level),item.costs.size(),item.benefit] if upgrade else "Requirement: highest mission %d" % int(item.highest),16,UI.MUTED))
 var purchase_text := str(offer.reason) if str(offer.reason) in ["MAXIMUM","UNLOCKED"] else "%d War Credits • %s" % [int(offer.cost),str(offer.reason)]
 var buy := UI.button(purchase_text,confirm.bind(id,int(offer.level)))
 buy.disabled = not bool(offer.allowed) or pending
 stack.add_child(buy)

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
  refresh())
 dialog.canceled.connect(func(): pending = false)
 dialog.confirmed.connect(dialog.queue_free)
 dialog.canceled.connect(dialog.queue_free)
 add_child(dialog)
 dialog.popup_centered()
