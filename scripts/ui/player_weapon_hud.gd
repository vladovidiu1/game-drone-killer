extends VBoxContainer
# Compact native UI shared by Android and desktop; no dependency on hover.
const UI := preload("res://scripts/ui/ui_kit.gd")
var battle: Node2D
var ammo_label: Label
var progress: ProgressBar
var fire_button: Button
var reload_button: Button

func setup(simulation: Node2D) -> void:
 battle = simulation
 add_theme_constant_override("separation",6)
 ammo_label = UI.label("",17,UI.CYAN)
 add_child(ammo_label)
 progress = ProgressBar.new()
 progress.custom_minimum_size = Vector2(0,8)
 progress.show_percentage = false
 progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(progress)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",8)
 add_child(row)
 fire_button = UI.button("FIRE / HOLD",func(): pass,Vector2(170,66))
 fire_button.focus_mode = Control.FOCUS_NONE
 fire_button.button_down.connect(func(): battle.player_controls.set_fire(&"fire_button",true))
 fire_button.button_up.connect(func(): battle.player_controls.set_fire(&"fire_button",false))
 reload_button = UI.button("Reload",func(): battle.player_controls.reload(),Vector2(92,66))
 reload_button.add_theme_font_size_override("font_size",16)
 row.add_child(fire_button)
 row.add_child(reload_button)
 battle.status_changed.connect(refresh)
 refresh()

func refresh() -> void:
 var cannon: Node2D = battle.player_turret
 var reloading: bool = cannon.reload_remaining > 0
 ammo_label.text = "RELOAD • %.1fs" % cannon.reload_remaining if reloading else "PRIMARY / %02d : %02d" % [cannon.ammo,int(cannon.definition.magazine_size)]
 progress.value = cannon.reload_progress()*100 if reloading else 100.0*cannon.ammo/int(cannon.definition.magazine_size)
 fire_button.disabled = battle.paused or battle.finished
 fire_button.text = "RELOADING" if reloading else "FIRE / HOLD"
 reload_button.disabled = battle.paused or battle.finished or reloading or cannon.ammo == int(cannon.definition.magazine_size)
 if battle.paused or battle.finished:
  fire_button.cancel_touch()
