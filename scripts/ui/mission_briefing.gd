extends VBoxContainer
signal deploy_requested(mission_id: int)
signal replay_deploy_requested(mission_id: int)
var optional_replay := false
signal back_requested
const UI := preload("res://scripts/ui/ui_kit.gd")

func setup(id: int, replay: bool = false) -> void:
 optional_replay = replay or id != int(SaveManager.state.get("frontline",1)) and CampaignManager.completed(id) or SaveManager.state.get("campaign_complete",false)
 var definition := CampaignManager.mission(id)
 add_theme_constant_override("separation",12)
 add_child(UI.label("SENTINEL COMMAND / MISSION BRIEFING",16,UI.CYAN))
 add_child(UI.label("%02d / %s" % [id,str(definition.name).to_upper()],32))
 add_child(UI.label(str(definition.location),20,UI.CYAN))
 var overview := UI.panel()
 add_child(overview)
 var overview_row := HBoxContainer.new()
 overview_row.add_theme_constant_override("separation",16)
 overview.add_child(overview_row)
 var preview := preload("res://scripts/ui/deployment_preview.gd").new()
 preview.setup(definition)
 preview.custom_minimum_size = Vector2(270,158)
 overview_row.add_child(preview)
 var overview_text := UI.label("OPERATION %02d  /  %s\n%d WAVES   •   %d SLOTS   •   VICTORY +%d WC" % [id,CampaignManager.CHAPTERS[(id-1)/5].to_upper(),definition.waves.size(),definition.slots.size(),int(EconomyManager.victory_quote(id).reward)],21,UI.CYAN)
 overview_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 overview_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 overview_row.add_child(overview_text)
 var scroll := preload("res://scripts/ui/touch_scroll.gd").new()
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 add_child(scroll)
 var body := VBoxContainer.new()
 body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation",12)
 scroll.add_child(body)
 var requirements := UI.label(preload("res://scripts/core/mission_performance.gd").requirements(id),19,UI.ORANGE)
 requirements.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 body.add_child(requirements)
 body.add_child(UI.label("STAR BONUSES: +%d WC at 2 stars; +%d WC at 3 stars, once per mission." % [int(preload("res://scripts/core/economy_config.gd").values.war.star_milestones["2"]),int(preload("res://scripts/core/economy_config.gd").values.war.star_milestones["3"])],17,UI.MUTED))
 var mode_notice := UI.label("OPTIONAL REPLAY / Territory and checkpoints are protected on victory or defeat." if optional_replay else "FRONTLINE BATTLE / Victory advances; defeat retreats to the secured floor.",18,UI.CYAN)
 mode_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 body.add_child(mode_notice)
 body.add_child(UI.label("KNOWN APPROACHES / WEST · CENTER · EAST",17,UI.CYAN))
 body.add_child(UI.label("Numbers: available slots • Orange pads: elevated range positions • Lines: known air corridors, not a wave forecast.",16,UI.MUTED))
 var equipped: Array = SaveManager.state.get("ammo_loadout",["standard"])
 var names: PackedStringArray = []
 for ammunition in equipped:
  names.append("%s T%d" % [str(SaveManager.catalog.ammunition[ammunition].name),int(SaveManager.state.research.get("ammo_"+str(ammunition),0))])
 var equipment := UI.label("EQUIPPED: "+", ".join(names)+"\n"+"Starting supply: %d BC. Place and orient defenses before pressing Launch wave. Later formations remain unknown." % (int(definition.starting_credits)+int(EconomyManager.modifier("starting_credits"))),18,UI.CYAN)
 equipment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 body.add_child(equipment)
 var primary := EconomyManager.primary_stats()
 var designs: PackedStringArray = []
 for kind in CampaignManager.turrets:
  if EconomyManager.unlocked(str(kind)):
   designs.append(str(CampaignManager.turrets[kind].name))
 var armament := UI.label("PRIMARY: %.0f damage · %.1f shots/s · %d rounds\nAVAILABLE DEFENSES: %s" % [float(primary.damage),float(primary.fire_rate),int(primary.magazine_size),", ".join(designs)],17,UI.MUTED)
 armament.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 body.add_child(armament)
 for field in [["OBJECTIVE",definition.get("objective","Protect the base.")],["CONDITIONS",str(definition.get("environment",{}).get("kind","clear")).to_upper()+" • Target duration: %d–%d minutes at normal speed; early wave starts shorten deployment." % [int(definition.target_minutes[0]),int(definition.target_minutes[1])]],["SITUATION",definition.story],["ENEMY INTELLIGENCE",definition.intel],["RECOMMENDED PREPARATION",definition.preparation]]:
  body.add_child(UI.label(str(field[0]),17,UI.CYAN))
  var paragraph := UI.label(str(field[1]),20)
  paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  body.add_child(paragraph)
 var record: Dictionary = SaveManager.state.get("records",{}).get(str(id),{})
 var quote := EconomyManager.victory_quote(id)
 body.add_child(UI.label("%s: %d War Credits. Later victories: %d WC. Defeat: 0." % ["First clear" if quote.first_clear else "Replay victory",int(quote.reward),int(int(quote.first_reward)*int(preload("res://scripts/core/economy_config.gd").values.war.replay_percent)/100.0)],18,UI.MUTED))
 if bool(definition.playable):
  body.add_child(UI.label("%d waves • %d slots • %d starting battle credits" % [definition.waves.size(),definition.slots.size(),int(definition.starting_credits)],18,UI.MUTED))
 if not record.is_empty():
  body.add_child(UI.label("Record: %d victories / %d defeats • %d/3 stars • Best HP %.0f%% • Fastest %.1fs" % [int(record.victories),int(record.defeats),int(record.get("best_stars",0)),100*float(record.get("best_hp_ratio",0)),float(record.get("fastest_seconds",0))],18,UI.MUTED))
 if bool(definition.playable):
  var start := UI.button("Start Replay" if optional_replay else "Start Mission",func(): deploy_requested.emit(id))
  start.icon = UI.icon("play")
  start.theme_type_variation = &"TacticalPrimary"
  start.disabled = not CampaignManager.can_play(id)
  add_child(start)
  if start.disabled:
   body.add_child(UI.label("LOCKED: reconquer the current frontline first.",20,Color("f9ad52")))
  if not optional_replay and CampaignManager.completed(id):
   add_child(UI.button("Optional Replay / Protect frontline",func(): replay_deploy_requested.emit(id)))
 else:
  body.add_child(UI.label("IN DEVELOPMENT / DEPLOYMENT UNAVAILABLE",20,Color("f9ad52")))
 add_child(UI.button("Back to campaign",func(): back_requested.emit()))
