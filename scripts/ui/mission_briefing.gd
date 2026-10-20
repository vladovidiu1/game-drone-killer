extends VBoxContainer
signal deploy_requested(mission_id: int)
signal back_requested
const UI := preload("res://scripts/ui/ui_kit.gd")

func setup(id: int) -> void:
 var definition := CampaignManager.mission(id)
 add_theme_constant_override("separation",12)
 add_child(UI.label("SENTINEL COMMAND / MISSION BRIEFING",16,UI.CYAN))
 add_child(UI.label("%02d / %s" % [id,str(definition.name).to_upper()],32))
 add_child(UI.label(str(definition.location),20,UI.CYAN))
 var scroll := ScrollContainer.new()
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 add_child(scroll)
 var body := VBoxContainer.new()
 body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation",12)
 scroll.add_child(body)
 for field in [["OBJECTIVE",definition.get("objective","Protect the base.")],["CONDITIONS",str(definition.get("environment",{}).get("kind","clear")).to_upper()+" • Target duration: 3–7 minutes at 1x; early wave starts shorten deployment."],["SITUATION",definition.story],["ENEMY INTELLIGENCE",definition.intel],["RECOMMENDED PREPARATION",definition.preparation]]:
  body.add_child(UI.label(str(field[0]),17,UI.CYAN))
  var paragraph := UI.label(str(field[1]),20)
  paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  body.add_child(paragraph)
 var record: Dictionary = SaveManager.state.get("records",{}).get(str(id),{})
 body.add_child(UI.label("Reward: %d War Credits on victory. Defeat grants no reward." % int(definition.reward),18,UI.MUTED))
 if bool(definition.playable):
  body.add_child(UI.label("%d waves • %d slots • %d starting battle credits" % [definition.waves.size(),definition.slots.size(),int(definition.starting_credits)],18,UI.MUTED))
 if not record.is_empty():
  body.add_child(UI.label("Record: %d victories / %d defeats • Best base HP: %d" % [int(record.victories),int(record.defeats),int(record.best_health)],18,UI.MUTED))
 if bool(definition.playable):
  var start := UI.button("Start Mission",func(): deploy_requested.emit(id))
  start.disabled = not CampaignManager.can_play(id)
  add_child(start)
  if start.disabled:
   body.add_child(UI.label("LOCKED: reconquer the current frontline first.",20,Color("f9ad52")))
 else:
  body.add_child(UI.label("IN DEVELOPMENT / DEPLOYMENT UNAVAILABLE",20,Color("f9ad52")))
 add_child(UI.button("Back to campaign",func(): back_requested.emit()))
