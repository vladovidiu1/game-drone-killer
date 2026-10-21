extends VBoxContainer
signal mission_requested(id: int)
signal menu_requested
signal arsenal_requested
const UI := preload("res://scripts/ui/ui_kit.gd")
var strategic: Control
var transition: Dictionary = {}
var bank: Label

func _balance_changed() -> void:
 bank.text = "WAR CREDITS  /  %s" % int(SaveManager.state.get("credits",0))
func _ready() -> void:
 add_theme_constant_override("separation",12)
 var header := HBoxContainer.new()
 add_child(header)
 var title := VBoxContainer.new()
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 header.add_child(title)
 title.add_child(UI.label("SENTINEL COMMAND / CAMPAIGN OPERATIONS",14,UI.CYAN))
 title.add_child(UI.label("ASTERIA / STRATEGIC MAP",34))
 title.add_child(UI.label("CAMPAIGN RATING / %d / 75 STARS" % CampaignManager.total_stars(),17,UI.ORANGE))
 bank = UI.label("WAR CREDITS  /  %s" % int(SaveManager.state.get("credits",0)),22,UI.CYAN)
 header.add_child(bank)
 EconomyManager.balance_changed.connect(_balance_changed)
 var middle := HBoxContainer.new()
 middle.add_theme_constant_override("separation",14)
 middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
 add_child(middle)
 strategic = preload("res://scripts/ui/strategic_map.gd").new()
 strategic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 strategic.transition = transition
 strategic.transition_age = 0.0 if not transition.is_empty() else 2.0
 middle.add_child(strategic)
 strategic.mission_selected.connect(func(id: int): mission_requested.emit(id))
 var panel := PanelContainer.new()
 panel.custom_minimum_size.x = 280
 middle.add_child(panel)
 var scroll := ScrollContainer.new()
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 panel.add_child(scroll)
 var intel := VBoxContainer.new()
 intel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 intel.add_theme_constant_override("separation",12)
 scroll.add_child(intel)
 var id := int(SaveManager.state.get("frontline",1))
 var mission := CampaignManager.mission(id)
 intel.add_child(UI.label("CURRENT OBJECTIVE",14,UI.ORANGE))
 var heading := UI.label("%02d / %s" % [id,str(mission.name).to_upper()],28)
 heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 intel.add_child(heading)
 intel.add_child(UI.label(CampaignManager.CHAPTERS[(id-1)/5],17,UI.CYAN))
 var image := UI.mission_image(id)
 image.custom_minimum_size = Vector2(250,112)
 intel.add_child(image)
 var objective := UI.label(str(mission.objective),17)
 objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 intel.add_child(objective)
 intel.add_child(UI.label("%d waves  /  %d emplacements" % [mission.waves.size(),mission.slots.size()],16,UI.MUTED))
 intel.add_child(UI.label("VICTORY  /  +%d WC" % int(EconomyManager.victory_quote(int(mission.id)).reward),18,UI.CYAN))
 var ad_offer := preload("res://scripts/ui/rewarded_ad_offer.gd").new()
 ad_offer.compact = true
 intel.add_child(ad_offer)
 intel.add_child(UI.label("SECURED FLOOR  /  %02d" % int(SaveManager.state.get("checkpoint",1)),16,UI.MUTED))
 var hint := UI.label("Select an operation marker to inspect its briefing. Completed operations may be replayed safely for stars, including previously cleared territory beyond the current frontline.",16,UI.MUTED)
 hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 intel.add_child(hint)
 var feedback := UI.label(str(SaveManager.state.get("last_result",{}).get("message","Secure Asteria, one territory at a time.")),17,UI.CYAN)
 feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 feedback.max_lines_visible = 3
 add_child(feedback)
 var nav := HBoxContainer.new()
 nav.add_theme_constant_override("separation",12)
 add_child(nav)
 var back := UI.button("Main menu",func(): menu_requested.emit())
 back.icon = preload("res://assets/ui/icon_back.svg")
 nav.add_child(back)
 var arsenal := UI.button("Arsenal",func(): arsenal_requested.emit())
 arsenal.icon = preload("res://assets/ui/icon_arsenal.svg")
 nav.add_child(arsenal)
 var legend := UI.label("BLUE  Controlled   /   ORANGE  Frontline   /   RED  Enemy   /   ◆  Checkpoint",14,UI.MUTED)
 legend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 nav.add_child(legend)
