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
 var performance: Dictionary = outcome.get("performance",preload("res://scripts/core/mission_performance.gd").evaluate(id,victory,{}))
 var snapshot: Dictionary = performance.snapshot
 var replay: bool = outcome.get("mode") == "replay"
 var accent := UI.CYAN if victory else Color("F04B45")
 add_child(UI.label("SENTINEL COMMAND / AFTER ACTION REPORT",14,accent))
 add_child(UI.label(("ASTERIA LIBERATED" if id == 25 and not replay else "REPLAY COMPLETE" if replay else "TERRITORY SECURED") if victory else "REPLAY ENDED" if replay else "DEFENSE LOST",42,accent))
 var body_scroll := preload("res://scripts/ui/touch_scroll.gd").new()
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
 var stars := preload("res://scripts/ui/star_rating.gd").new()
 stars.rating = int(performance.stars)
 stars.reveal = victory
 column.add_child(stars)
 column.add_child(UI.label("%d / 3 STARS • SCORE %d" % [int(performance.stars),int(performance.score)],19,UI.ORANGE))
 var feedback := UI.label(str(outcome.message),20,accent)
 feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 column.add_child(feedback)
 column.add_child(UI.label("FRONTLINE  %02d → %02d   /   SECURED FLOOR %02d" % [int(outcome.get("from",SaveManager.state.frontline)),int(outcome.get("to",SaveManager.state.frontline)),int(SaveManager.state.checkpoint)],17,UI.MUTED))
 var metrics := HBoxContainer.new()
 metrics.add_theme_constant_override("separation",12)
 body.add_child(metrics)
 var health_text := "%.0f%% / %d HP" % [100*float(snapshot.get("hp_ratio",0)),int(snapshot.get("health",stats.get("health",0)))] if not snapshot.is_empty() else "%d HP / ratio unrecorded" % int(stats.get("health",0))
 for entry in [["DRONES DESTROYED",str(int(snapshot.get("kills",stats.get("kills",0)))),"drone"],["BASE HP REMAINING",health_text,"shield"],["WAR CREDITS","+%d" % reward,"credits"]]:
  var card := preload("res://scripts/ui/telemetry_card.gd").new()
  metrics.add_child(card)
  card.setup(str(entry[0]),str(entry[2]),accent)
  card.update_value(str(entry[1]))
 var performance_panel := UI.panel(UI.ORANGE)
 body.add_child(performance_panel)
 var details := VBoxContainer.new()
 details.add_theme_constant_override("separation",8)
 performance_panel.add_child(details)
 var accuracy := 100*float(snapshot.get("accuracy",0))
 var accuracy_label := UI.label("PRIMARY ACCURACY %.1f%%  /  %d of %d rounds hit • WEAK POINTS %d • CRITICAL ROUNDS %d" % [accuracy,int(snapshot.get("manual_hits",0)),int(snapshot.get("manual_shots",0)),int(snapshot.get("components",0)),int(snapshot.get("critical_hits",0))],18,UI.CYAN)
 accuracy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 if snapshot.is_empty():
  accuracy_label.text = "LEGACY RESULT / full performance metrics were not recorded. Replay to set new records."
 details.add_child(accuracy_label)
 var metrics_copy := UI.label("HULL DAMAGE / Manual %.0f • Automatic %.0f • Other %.0f\nBREACHES %d • MANUAL KILLS %d • TIME %.1fs" % [float(snapshot.get("manual_damage",0)),float(snapshot.get("automatic_damage",0)),float(snapshot.get("other_damage",0)),int(snapshot.get("breaches",0)),int(snapshot.get("manual_kills",0)),float(snapshot.get("seconds",0))],18)
 metrics_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 details.add_child(metrics_copy)
 var secondary: Dictionary = performance.secondary
 var objective := UI.label("SECONDARY / %s / %s\n%s" % ["MET" if secondary.complete else "MISSED",str(secondary.name),str(secondary.description)],19,UI.CYAN if secondary.complete else UI.ORANGE)
 objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 details.add_child(objective)
 for condition in secondary.conditions:
  var condition_label := UI.label(("✓ " if condition.met else "○ ")+str(condition.text),17,UI.CYAN if condition.met else UI.MUTED)
  condition_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  details.add_child(condition_label)
 var thresholds: Dictionary = performance.thresholds
 var explanation := UI.label("1 STAR: %s • 2 STARS: %.0f%% HP %s • 3 STARS: %.0f%% HP %s + secondary %s" % ["VICTORY" if victory else "MISSED",100*float(thresholds.two),"MET" if performance.conditions.two_hp else "MISSED",100*float(thresholds.three),"MET" if performance.conditions.three_hp else "MISSED","MET" if secondary.complete else "MISSED"],17,UI.MUTED)
 explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 details.add_child(explanation)
 var bests: Array = outcome.get("new_bests",[])
 if not bests.is_empty():
  var best_copy := UI.label("NEW PERSONAL BEST / "+", ".join(bests),19,UI.ORANGE)
  best_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  details.add_child(best_copy)
 var reward_label := UI.label("REWARD / Mission %d + campaign objectives %d + new star milestones %d WC" % [int(outcome.get("mission_reward",reward)),int(outcome.get("objective_reward",0)),int(outcome.get("star_reward",0))],18,UI.CYAN)
 reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 details.add_child(reward_label)
 body.add_child(UI.label("+%d War Credits • Frontline: %02d • Highest: %02d" % [reward,int(SaveManager.state.frontline),int(SaveManager.state.highest)],20,accent))
 body.add_child(UI.label("Battle bounties: %d credits (temporary). Permanent research retained." % int(stats.get("earned",0)),17,UI.MUTED))
 if int(outcome.get("objective_reward",0)) > 0:
  body.add_child(UI.label("Includes +%d War Credits for a completed campaign objective." % int(outcome.objective_reward),18,UI.CYAN))
 var next := int(SaveManager.state.frontline)
 if victory and id == 25 and SaveManager.state.get("campaign_complete",false):
  body.add_child(UI.label("CAMPAIGN COMPLETE • All five chapters cleared. Replay from the map.",20,UI.CYAN))
 elif CampaignManager.can_play(next):
  var next_button := UI.button(("Next: " if victory else "Retry ")+str(CampaignManager.mission(next).name),func(): briefing_requested.emit(next))
  next_button.theme_type_variation = &"TacticalPrimary"
  next_button.icon = UI.icon("play")
  add_child(next_button)
 var nav := HBoxContainer.new()
 nav.add_theme_constant_override("separation",12)
 add_child(nav)
 nav.add_child(UI.button("Continue",func(): map_requested.emit()))
 nav.add_child(UI.button("Campaign map",func(): map_requested.emit()))
 nav.add_child(UI.button("Arsenal",func(): arsenal_requested.emit()))
 if victory and CampaignManager.can_play(id):
  nav.add_child(UI.button("Replay "+str(CampaignManager.mission(id).name),func(): replay_requested.emit(id)))
 if not victory:
  UI.flash(panel,Color("d28e82"))
 elif reward > 0:
  UI.flash(metrics,UI.CYAN)
