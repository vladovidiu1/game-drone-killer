extends Node
const UI := preload("res://scripts/ui/ui_kit.gd")
var checks := 0
var failures := 0
var app: Control
func check(condition: bool, message: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error(message)
func _ready() -> void:
 run.call_deferred()
func buttons(node: Node) -> Array[Button]:
 var found: Array[Button] = []
 for child in node.get_children():
  if child is Button:
   found.append(child)
  found.append_array(buttons(child))
 return found
func touch(index: int, position: Vector2, pressed: bool) -> void:
 var event := InputEventScreenTouch.new()
 event.index = index
 event.position = position
 event.pressed = pressed
 get_viewport().push_input(event,true)
func settle() -> void:
 await get_tree().process_frame
 await get_tree().process_frame
func run() -> void:
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 SaveManager.new_campaign()
 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 await settle()
 # All operation markers are real controls routed through the existing briefing.
 app._map()
 await settle()
 var strategic: Control = app.content.get_child(0).strategic
 check(strategic.nodes.size() == 25 and buttons(app).filter(func(button: Button): return button.text in ["Main menu","Arsenal"]).size() == 2,"Map retains 25 interactive operation nodes and existing navigation")
 var seen: Array[int] = []
 for node in strategic.nodes:
  check(not seen.has(node.mission_id) and Rect2(Vector2.ZERO,Vector2(1600,900)).encloses(node.get_rect()),"Distinct accessible world-space operation %02d" % node.mission_id)
  seen.append(node.mission_id)
 check(strategic.clip_contents,"World artwork and markers are clipped away from navigation")
 var state_snapshot: Dictionary = SaveManager.state.duplicate(true)
 var start: Vector2 = strategic.nodes[0].get_global_rect().get_center()
 var old_pan: Vector2 = strategic.pan_target
 touch(30,start,true)
 await settle()
 var drag := InputEventScreenDrag.new()
 drag.index = 30
 drag.position = start+Vector2(-90,-20)
 drag.relative = Vector2(-90,-20)
 get_viewport().push_input(drag,true)
 await settle()
 touch(30,drag.position,false)
 await settle()
 check(app.screen == "map" and strategic.pan_target != old_pan,"Dragging from a mission marker pans without accidentally opening a briefing")
 check(SaveManager.state == state_snapshot,"Panning/hover/animation never mutates campaign state")
 strategic.focus_current(true)
 await settle()
 var center: Vector2 = strategic.nodes[0].get_global_rect().get_center()
 touch(31,center,true)
 await settle()
 touch(31,center,false)
 await settle()
 check(app.screen == "briefing","A deliberate touch after dragging still activates the node")
 for id in range(1,26):
  app._map()
  await settle()
  var map: Control = app.content.get_child(0).strategic
  map.nodes[id-1].pressed.emit()
  await settle()
  check(app.screen == "briefing","Operation %02d opens actual briefing" % id)
  var actions := buttons(app)
  check(actions.size() == 2 and actions[0].text == "Start Mission" and actions[0].disabled == not CampaignManager.can_play(id),"Deployment eligibility still belongs to CampaignManager")
  actions[1].pressed.emit()
  await settle()
  check(app.screen == "map","Briefing back action returns to strategic map")
 var token := CampaignManager.begin_mission(1)
 var result := CampaignManager.resolve(true,1,token,{"health":900})
 var saved: Dictionary = SaveManager.state.duplicate(true)
 app._map()
 await settle()
 strategic = app.content.get_child(0).strategic
 check(strategic.transition.from == 1 and strategic.transition.to == 2,"Saved conquest drives frontline presentation")
 strategic._process(.5)
 check(SaveManager.state == saved and strategic.nodes[0].tint == UI.CYAN and strategic.nodes[1].current,"Conquest presentation reads final real territory states without awarding again")
 app._map()
 await settle()
 check(app.content.get_child(0).strategic.transition.is_empty(),"Reopening the map does not replay a consumed transition in the same session")
 SaveManager.state.frontline = 6
 SaveManager.state.highest = 6
 SaveManager.state.checkpoint = 5
 SaveManager.state.checkpoints = [1,5]
 SaveManager.state.research.cannon_damage = 1
 SaveManager.persist()
 token = CampaignManager.begin_mission(6)
 result = CampaignManager.resolve(false,6,token,{"health":0})
 app._map()
 await settle()
 strategic = app.content.get_child(0).strategic
 saved = SaveManager.state.duplicate(true)
 check(strategic.transition.from == 6 and strategic.transition.to == 5 and strategic.nodes[4].checkpoint,"Counterattack animation obeys the actual secured checkpoint")
 strategic._process(1)
 check(SaveManager.state == saved and SaveManager.state.research.cannon_damage == 1,"Counterattack presentation preserves permanent upgrades and save transaction")
 SaveManager.state.credits = 10000
 SaveManager.persist()
 app._arsenal()
 await settle()
 var arsenal: Control = app.content.get_child(0)
 for tab in ["primary","automatic","research","abilities"]:
  arsenal.tab_buttons[tab].pressed.emit()
  await settle()
  check(arsenal.current_tab == tab and arsenal.body.get_child_count() > 0,"Actual research tab action: "+tab)
 arsenal.select_tab("primary")
 var bank: int = SaveManager.state.credits
 arsenal.confirm("cannon_rate",0)
 var confirmation: ConfirmationDialog
 for node in arsenal.get_children():
  if node is ConfirmationDialog:
   confirmation = node
 check(confirmation != null,"Illustrated research cards still require reviewed purchase")
 confirmation.confirmed.emit()
 confirmation.confirmed.emit()
 await settle()
 check(SaveManager.state.research.cannon_rate == 1 and SaveManager.state.credits == bank-int(SaveManager.catalog.upgrades.cannon_rate.costs[0]),"Purchase feedback reflects exactly one saved debit/level")
 for dimensions in [Vector2i(1280,720),Vector2i(1600,720),Vector2i(1280,600),Vector2i(1024,768)]:
  get_tree().root.size = dimensions
  app._menu()
  await settle()
  var viewport := get_viewport().get_visible_rect()
  for button in buttons(app):
   check(viewport.encloses(button.get_global_rect()),"Menu control fits %s: %s" % [dimensions,button.text])
  app._arsenal()
  await settle()
  arsenal = app.content.get_child(0)
  check(arsenal.grid.columns == (2 if arsenal.size.x >= 980 else 1),"Research cards adapt column count to available width")
  for button in arsenal.tab_buttons.values():
   check(viewport.encloses(button.get_global_rect()),"Research tabs remain reachable at "+str(dimensions))
  app._play(1)
  await settle()
  app.battle.set_physics_process(false)
  app.battle.select_slot(0)
  await settle()
  check(app.hud.stat_cards.size() == 4,"Four real battle readouts replace dense text telemetry")
  for control in [app.hud.player_panel.fire_button,app.hud.player_panel.reload_button,app.hud.ability_buttons.repair,app.hud.close_button,app.hud.pause_button]:
   check(viewport.encloses(control.get_global_rect()) and control.size.y >= 44,"HUD action fits viewport with touch target ≥44: "+str(dimensions))
  check(not app.hud.player_panel.fire_button.get_global_rect().intersects(app.hud.ability_buttons.repair.get_global_rect()),"FIRE does not overlap ability controls")
  var field_center: Vector2 = app.battle.get_global_transform_with_canvas()*Vector2(480,330)
  check(app.hud.build_panel.size.x >= 400 and viewport.encloses(app.hud.build_panel.get_global_rect()),"Expanded build drawer fits viewport")
  check(app.hud.blocks_pointer(app.hud.build_panel.get_global_rect().get_center()),"Expanded drawer owns its input")
  app.battle.close_build_mode()
  check(not app.hud.blocks_pointer(field_center),"Closing drawer restores battlefield input")
  app._menu()
  await settle()
 SaveManager.settings.reduced_motion = true
 app._map()
 await settle()
 strategic = app.content.get_child(0).strategic
 strategic.pan_target = strategic.bounded(Vector2(-200,-200))
 strategic.focus_current()
 check(strategic.pan == strategic.pan_target,"Reduced motion centers map immediately without a camera glide")
 app.queue_free()
 await settle()
 print("TACTICAL UI: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
