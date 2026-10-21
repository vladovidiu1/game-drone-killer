extends Node
# Native, unedited viewport fixtures. Funding/unlocks/deployments are staged QA.
var app: Control
var directory := "/tmp/frontline-m2-native"
var failures := 0
var metrics: Array[Dictionary] = []
func check(value: bool, message: String) -> void:
 if not value:
  failures += 1
  push_error(message)
func _ready() -> void:
 run.call_deferred()
func settle() -> void:
 await get_tree().process_frame
 await get_tree().process_frame
func touch(index: int, point: Vector2, pressed: bool) -> void:
 var event := InputEventScreenTouch.new()
 event.index = index
 event.position = point
 event.pressed = pressed
 get_viewport().push_input(event,true)
func tap(control: Control) -> void:
 var point := control.get_global_rect().get_center()
 for pressed in [true,false]:
  var event := InputEventScreenTouch.new()
  event.index = 20
  event.position = point
  event.pressed = pressed
  control.get_viewport().push_input(event,true)
 await settle()
func capture(name: String) -> void:
 await settle()
 await RenderingServer.frame_post_draw
 check(get_viewport().get_texture().get_image().save_png(directory.path_join(name+".png")) == OK,"Native image saved")
 metrics.append({"capture":name,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"size":[get_tree().root.size.x,get_tree().root.size.y]})
 print("CAPTURE: "+name)
func equip_from_card(arsenal: Control, id: String) -> void:
 var technology: Control = arsenal.body.get_child(0)
 var scroll: ScrollContainer = arsenal.body.get_parent()
 scroll.ensure_control_visible(technology.equip_buttons[id])
 await settle()
 var was_equipped: bool = SaveManager.state.ammo_loadout.has(id)
 await tap(technology.equip_buttons[id])
 check(SaveManager.state.ammo_loadout.has(id) != was_equipped,"Native loadout card changes selection: "+id)

func buy(arsenal: Control, id: String) -> void:
 var level: int = EconomyManager.purchase_state(id).level
 arsenal.confirm(id,level)
 await settle()
 for node in arsenal.get_children():
  if node is ConfirmationDialog:
   await tap(node.get_ok_button())
 check(int(EconomyManager.purchase_state(id).level) == level+1,"Native confirmation buys "+id)
func run() -> void:
 if DisplayServer.get_name() == "headless":
  push_error("M2 captures require a real display")
  get_tree().quit(1)
  return
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--output="):
   directory = arg.trim_prefix("--output=")
 DirAccess.make_dir_recursive_absolute(directory)
 get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 get_tree().root.size = Vector2i(1280,720)
 SaveManager.new_campaign()
 SaveManager.state.highest = 25
 SaveManager.state.frontline = 25
 SaveManager.state.credits = 100000 # Clearly staged research bank; real purchases follow.
 SaveManager.persist()
 app = preload("res://scenes/main.tscn").instantiate()
 add_child(app)
 await settle()
 app._arsenal()
 await settle()
 var arsenal: Control = app.content.get_child(0)
 await tap(arsenal.tab_buttons.projectiles)
 check(arsenal.current_tab == "projectiles","Native touch opens advanced projectiles tab")
 await capture("projectiles_locked")
 for id in SaveManager.catalog.projectile_technologies:
  if id != "standard":
   await buy(arsenal,str(id))
  for tier in 3:
   await buy(arsenal,"ammo_"+str(id))
 await capture("projectiles_researched")
 var scroll: ScrollContainer = arsenal.body.get_parent()
 scroll.scroll_vertical = 100000
 await capture("projectiles_railgun")
 await equip_from_card(arsenal,"emp")
 await equip_from_card(arsenal,"cryo")
 await equip_from_card(arsenal,"standard")
 await equip_from_card(arsenal,"railgun")
 check(SaveManager.state.ammo_loadout == ["emp","cryo","railgun"],"Native equip cards produce the ordered three-type loadout")
 arsenal.refresh()
 await settle()
 for dimensions in [Vector2i(1280,600),Vector2i(1024,768),Vector2i(1600,720)]:
  get_tree().root.size = dimensions
  await settle()
  var visible := get_viewport().get_visible_rect()
  for button in arsenal.tab_buttons.values():
   check(visible.encloses(button.get_global_rect()),"All five research tabs fit native layout")
  await capture("projectiles_%dx%d" % [dimensions.x,dimensions.y])
 get_tree().root.size = Vector2i(1280,720)
 await settle()
 arsenal.select_tab("automatic")
 await buy(arsenal,"spec_machine_gun_rapid")
 await buy(arsenal,"spec_machine_gun_rapid")
 await buy(arsenal,"spec_machine_gun_rapid")
 var automatic_scroll: ScrollContainer = arsenal.body.get_parent()
 automatic_scroll.scroll_vertical = 800
 await capture("turret_specialization")
 for dimensions in [Vector2i(1280,600),Vector2i(1024,768),Vector2i(1600,720)]:
  get_tree().root.size = dimensions
  await settle()
  for button in arsenal.tab_buttons.values():
   check(get_viewport().get_visible_rect().encloses(button.get_global_rect()),"Specialization copy never expands UI outside viewport")
 get_tree().root.size = Vector2i(1280,720)
 await settle()
 for id in SaveManager.catalog.ammunition:
  check(EconomyManager.set_loadout(["standard","armor_piercing","explosive"] if id in ["standard","armor_piercing","explosive"] else ["emp","cryo","railgun"]),"Fixture pre-deployment loadout")
  check(EconomyManager.equip_ammunition(str(id)),"Fixture active ammunition preference")
  app._play(3)
  await settle()
  var battle: Node2D = app.battle
  battle.set_physics_process(false)
  battle.spawner.timer = 10000
  battle.close_build_mode()
  var label := preload("res://scripts/ui/ui_kit.gd").label("M2 TEST FIXTURE\n%s / TIER 3\nFUNDED RESEARCH" % str(id).to_upper(),16)
  label.position = Vector2(957,260)
  label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  label.size = Vector2(275,90)
  label.z_index = 11
  label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  app.add_child(label)
  for y in [420,350,270]:
   var enemy: Node2D = battle.spawn_enemy("heavy")
   enemy.position = Vector2(560,y)
   enemy.speed = 0
  battle.player_controls.aim_at(Vector2(560,350))
  for other in battle.player_turret.loadout:
   if other != id:
    await tap(app.hud.player_panel.ammo_buttons[other])
    check(battle.player_turret.ammunition_type == other,"Native advanced ammo chip selects equipped type")
    break
  await tap(app.hud.player_panel.ammo_buttons[id])
  check(battle.player_turret.ammunition_type == id and battle.player_turret.ammo == 60,"Native ammo changes preserve full shared capacity")
  for frame in 120:
   battle.simulate(.01)
  # Two fingers through actual native input, retaining the shared aiming owner.
  touch(40,Vector2(180,400),true)
  touch(41,app.hud.player_panel.fire_button.get_global_rect().get_center(),true)
  check(battle.player_controls.aim_finger == 40 and battle.player_turret.trigger_held,"Simultaneous aim/FIRE touches reach advanced cannon")
  battle.simulate(.01)
  check(battle.player_turret.shots_fired == 1 and battle.projectiles.get_child_count() > 0,"Real advanced round fires from native FIRE control")
  battle.simulate(.06)
  await capture(str(id)+"_flight")
  touch(41,app.hud.player_panel.fire_button.get_global_rect().get_center(),false)
  touch(40,Vector2(180,400),false)
  for frame in 24:
   battle.simulate(1.0/120)
  check(battle.player_turret.hits > 0,"Advanced native round impacts actual drones")
  await capture(str(id)+"_impact")
  # A real partial-magazine reload must not permit an ammunition swap.
  await tap(app.hud.player_panel.reload_button)
  check(battle.player_turret.reload_remaining > 0,"Native reload starts shared cooldown")
  for button in app.hud.player_panel.ammo_buttons.values():
   check(button.disabled,"Reload disables every equipped ammunition switch")
  await capture(str(id)+"_reload")
  label.queue_free()
 app.queue_free()
 await settle()
 var file := FileAccess.open(directory.path_join("render_metrics.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(metrics,"  "))
 print("NATIVE M2: %d captures, %d failures" % [metrics.size(),failures])
 get_tree().quit(1 if failures else 0)
