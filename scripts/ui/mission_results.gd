extends VBoxContainer
signal briefing_requested(id: int)
signal replay_requested(id: int)
signal map_requested
signal arsenal_requested
const UI := preload("res://scripts/ui/ui_kit.gd")
func setup(victory: bool, reward: int, stats: Dictionary) -> void:
 add_theme_constant_override("separation",14)
 var outcome: Dictionary = stats.campaign
 var id := int(outcome.mission_id)
 var accent := UI.CYAN if victory else Color("F04B45")
 add_child(UI.label("SENTINEL COMMAND / AFTER ACTION REPORT",14,accent))
 add_child(UI.label(("ASTERIA LIBERATED" if id == 25 else "TERRITORY SECURED") if victory else "DEFENSE LOST",42,accent))
 var body_scroll := ScrollContainer.new()
 body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 add_child(body_scroll)
 var body := VBoxContainer.new()
 body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation",16)
 body_scroll.add_child(body)
 var panel := UI.panel(accent)
 body.add_child(panel)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",24)
 panel.add_child(row)
 var image := UI.mission_image(id)
 image.custom_minimum_size = Vector2(250,150)
 row.add_child(image)
 var column := VBoxContainer.new()
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation",12)
 row.add_child(column)
 column.add_child(UI.label(str(CampaignManager.mission(id).name).to_upper(),30))
 var feedback := UI.label(str(outcome.message),20,accent)
 feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 column.add_child(feedback)
 column.add_child(UI.label("FRONTLINE  %02d → %02d   /   SECURED FLOOR %02d" % [int(outcome.get("from",SaveManager.state.frontline)),int(outcome.get("to",SaveManager.state.frontline)),int(SaveManager.state.checkpoint)],17,UI.MUTED))
 var metrics := HBoxContainer.new()
 metrics.add_theme_constant_override("separation",12)
 body.add_child(metrics)
 for entry in [["DRONES DESTROYED",str(int(stats.kills)),"drone"],["BASE HP REMAINING",str(int(stats.health)),"shield"],["WAR CREDITS","+%d" % reward,"credits"]]:
  var card := preload("res://scripts/ui/telemetry_card.gd").new()
  metrics.add_child(card)
  card.setup(str(entry[0]),str(entry[2]),accent)
  card.update_value(str(entry[1]))
 body.add_child(UI.label("+%d War Credits • Frontline: %02d • Highest: %02d" % [reward,int(SaveManager.state.frontline),int(SaveManager.state.highest)],20,accent))
 body.add_child(UI.label("Battle bounties: %d credits (temporary). Permanent research retained." % int(stats.get("earned",0)),17,UI.MUTED))
 if int(outcome.get("objective_reward",0)) > 0:
  body.add_child(UI.label("Includes +%d War Credits for a completed campaign objective." % int(outcome.objective_reward),18,UI.CYAN))
 var next := int(SaveManager.state.frontline)
 if victory and id == 25:
  body.add_child(UI.label("CAMPAIGN COMPLETE • All five chapters cleared. Replay from the map.",20,UI.CYAN))
 elif CampaignManager.can_play(next):
  var next_button := UI.button(("Next: " if victory else "Retry ")+str(CampaignManager.mission(next).name),func(): briefing_requested.emit(next))
  next_button.theme_type_variation = &"TacticalPrimary"
  next_button.icon = UI.icon("play")
  add_child(next_button)
 var nav := HBoxContainer.new()
 nav.add_theme_constant_override("separation",12)
 add_child(nav)
 nav.add_child(UI.button("Campaign map",func(): map_requested.emit()))
 nav.add_child(UI.button("Arsenal",func(): arsenal_requested.emit()))
 if victory and CampaignManager.can_play(id):
  nav.add_child(UI.button("Replay "+str(CampaignManager.mission(id).name),func(): replay_requested.emit(id)))
 if not victory:
  UI.flash(panel,Color("d28e82"))
 elif reward > 0:
  UI.flash(metrics,UI.CYAN)
