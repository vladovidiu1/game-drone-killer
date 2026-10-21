extends VBoxContainer
signal purchase_requested(id: String, expected_level: int)
signal changed
const UI := preload("res://scripts/ui/ui_kit.gd")
const TECH := preload("res://scripts/core/weapon_technology.gd")
var feedback: Label
var equip_buttons: Dictionary = {}
var research_buttons: Dictionary = {}
var cards: GridContainer
func _ready() -> void:
 add_theme_constant_override("separation",12)
 var loadout: Array = SaveManager.state.get("ammo_loadout",["standard"])
 var names: PackedStringArray = []
 for id in loadout:
  names.append(str(SaveManager.catalog.projectile_technologies[id].name))
 var summary := UI.label("MISSION LOADOUT / %d OF 3: %s\nOne shared magazine. HE/EMP/Cryo/Rail spend more units. Switching never refills or skips reload/cooldown. Changes apply next deployment." % [loadout.size(),", ".join(names)],18,UI.CYAN)
 summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 add_child(summary)
 feedback = UI.label("Research a technology, then equip up to three types before deployment.",17,UI.MUTED)
 feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 add_child(feedback)
 cards = GridContainer.new()
 cards.columns = 2
 cards.add_theme_constant_override("h_separation",12)
 cards.add_theme_constant_override("v_separation",12)
 add_child(cards)
 resized.connect(func(): cards.columns = 2 if size.x >= 980 else 1)
 for id in SaveManager.catalog.projectile_technologies:
  add_technology(str(id),loadout)

func stats_text(profile: Dictionary) -> String:
 var primary := EconomyManager.primary_stats()
 var effect := "No status effect"
 if profile.has("disable_duration"):
  effect = "Disrupt %.2fs • bosses resist" % float(profile.disable_duration)
 elif profile.has("slow_factor"):
  effect = "Slow %.0f%% / %.2fs • resistance applies" % [(1.0-float(profile.slow_factor))*100,float(profile.status_duration)]
 elif profile.has("penetration"):
  effect = "%d targets • %.0f%% damage retained per penetration" % [int(profile.penetration),float(profile.penetration_falloff)*100]
 return "%.1f damage / %.1f vs armor • %.2f shots/s\n%d units/shot • %d shots/full magazine • %.0f speed\n%.0f splash • %s" % [float(primary.damage)*float(profile.damage_multiplier),float(primary.damage)*float(profile.damage_multiplier)*float(profile.armor_multiplier),float(primary.fire_rate)*float(profile.fire_rate_multiplier),int(profile.round_cost),int(primary.magazine_size)/int(profile.round_cost),float(primary.projectile_speed)*float(profile.speed_multiplier),float(profile.splash_radius),effect]

func add_technology(id: String, loadout: Array) -> void:
 var data: Dictionary = SaveManager.catalog.projectile_technologies[id]
 var profile := TECH.ammunition(id,SaveManager.state.get("research",{}))
 var unlocked := EconomyManager.unlocked(id)
 var panel := UI.panel()
 panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 cards.add_child(panel)
 var stack := VBoxContainer.new()
 stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 stack.add_theme_constant_override("separation",8)
 panel.add_child(stack)
 var heading := HBoxContainer.new()
 stack.add_child(heading)
 var illustration := TextureRect.new()
 illustration.texture = load("res://assets/projectiles/"+id+"_round.svg")
 illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 illustration.custom_minimum_size = Vector2(100,48)
 heading.add_child(illustration)
 var title := UI.label(str(data.name),24,UI.CYAN)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 heading.add_child(title)
 for value in [str(data.role),str(data.tradeoff),stats_text(profile),"Highest mission %d • Prerequisites: %s" % [int(data.highest),EconomyManager.prerequisite_text(data.requires)],"%s • TECHNOLOGY TIER %d / 3" % ["UNLOCKED" if unlocked else "LOCKED",int(profile.tier)]]:
  var label := UI.label(value,17,UI.WHITE if value == stats_text(profile) else UI.MUTED)
  label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  stack.add_child(label)
 if int(profile.tier) < 3:
  var next_levels: Dictionary = SaveManager.state.get("research",{}).duplicate(true)
  next_levels["ammo_"+id] = int(profile.tier)+1
  var preview := UI.label("NEXT TIER / "+stats_text(TECH.ammunition(id,next_levels)),16,UI.CYAN)
  preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  stack.add_child(preview)
 var tiers := HBoxContainer.new()
 stack.add_child(tiers)
 for index in 3:
  var pip := ColorRect.new()
  pip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  pip.custom_minimum_size.y = 5
  pip.color = UI.CYAN if index < int(profile.tier) else Color("303D4C")
  pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
  tiers.add_child(pip)
 var purchase_id := "ammo_"+id if unlocked else id
 var offer := EconomyManager.purchase_state(purchase_id)
 var buy := UI.button(("Improve • " if unlocked else "Unlock • ")+"%d WC / %s" % [int(offer.cost),offer.reason],func(): purchase_requested.emit(purchase_id,int(offer.level)),Vector2(0,54))
 buy.clip_text = true
 buy.add_theme_font_size_override("font_size",16)
 buy.disabled = not bool(offer.allowed)
 stack.add_child(buy)
 research_buttons[id] = buy
 var equip := UI.button(("REMOVE FROM LOADOUT" if loadout.has(id) else "EQUIP FOR NEXT MISSION"),_equip.bind(id),Vector2(0,54))
 equip.disabled = not unlocked or not SaveManager.has_campaign()
 equip.theme_type_variation = &"TacticalPrimary" if loadout.has(id) else &"Button"
 stack.add_child(equip)
 equip_buttons[id] = equip

func _equip(id: String) -> void:
 var ids: Array = SaveManager.state.get("ammo_loadout",["standard"]).duplicate()
 if ids.has(id):
  ids.erase(id)
 else:
  ids.append(id)
 if EconomyManager.set_loadout(ids):
  changed.emit()
 else:
  feedback.text = SaveManager.last_error if not SaveManager.last_error.is_empty() else "Keep 1–3 unlocked types equipped. Remove one before adding a fourth."
