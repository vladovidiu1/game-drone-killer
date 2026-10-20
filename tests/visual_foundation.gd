extends Node
const ASSETS := preload("res://scripts/visual/visual_assets.gd")
const UI := preload("res://scripts/ui/ui_kit.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)

func _ready() -> void:
 run.call_deferred()

func run() -> void:
 var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/manifest.json"))
 for asset in manifest.assets:
  var path := "res://assets/"+str(asset.filename)
  check(ResourceLoader.exists(path),"Manifest resource exists: "+path)
  check(not str(asset.license).is_empty() and not str(asset.source_or_generation_method).is_empty() and not str(asset.integration_status).is_empty(),"Asset provenance and integration status: "+path)
  check(FileAccess.get_sha256(path) == asset.sha256,"Manifest matches checked source: "+path)
  if asset.required_dimensions is Array:
   var texture: Texture2D = load(path)
   check(texture.get_width() == int(asset.required_dimensions[0]) and texture.get_height() == int(asset.required_dimensions[1]),"Texture dimensions: "+path)
 for id in ASSETS.catalog.sprites:
  var texture := ASSETS.sprite(str(id))
  check(texture != null and texture.get_width() > 0 and texture.get_height() > 0,"Sprite binding loads: "+str(id))
  if texture is AtlasTexture:
   check(Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region) and texture.filter_clip,"Atlas region stays within its shared source")
 check(ASSETS.sprite("drone_scout").atlas == ASSETS.sprite("drone_heavy").atlas,"Standard drones share the new GPU atlas")
 check(ASSETS.sprite("gun_machine").atlas == ASSETS.sprite("gun_cannon").atlas,"Automatic weapon heads share their dedicated GPU atlas")
 for index in 6:
  var frame := ASSETS.explosion_frame(index)
  check(frame.get_width() == 512 and frame.get_height() == 512,"Explosion uses six correctly sliced frames")
 for path in ["drones/combat_atlas.png","effects/explosion_atlas.png","environment/command_bunker.png","environment/props_atlas.png"]:
  var image := ASSETS.texture(path).get_image()
  check(image.get_pixel(0,0).a < 0.01,"Alpha artwork has transparent corners; no opaque backing")
 var theme := UI.theme()
 check(theme.default_font != null and theme.has_stylebox("normal","Button") and theme.get_stylebox("normal","Button") is StyleBoxTexture,"Reusable theme supplies local font and textured button surfaces")
 check(theme.has_stylebox("normal","TacticalPrimary") and theme.has_stylebox("normal","TacticalFire"),"Primary/fire actions have semantic variants")
 check(theme.has_stylebox("fill","ProgressBar") and theme.has_stylebox("panel","PanelContainer"),"Progress bars and panels share the design system")
 check(str(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "gl_compatibility","Compatibility renderer preserved")
 SaveManager.new_campaign()
 var battle := preload("res://scenes/gameplay.tscn").instantiate()
 add_child(battle)
 battle.set_physics_process(false)
 check(battle.view.get_node_or_null("OutpostTerrain") != null,"Outpost has a separate graded terrain layer")
 check(battle.player_turret.get_node("Artwork").art.body.texture != null,"Primary cannon uses the shared rendered artwork")
 for kind in CampaignManager.enemies:
  var unit: Node2D = battle.spawn_enemy(str(kind))
  check(unit.art.body.texture != null and unit.art.body.material.shader != null,"Enemy presentation composes real texture and shader: "+str(kind))
  var hp: float = unit.health
  unit.art.sync(0,0.12,true,true)
  check(unit.health == hp and not unit.ended,"Presentation state cannot alter enemy health/lifecycle")
  check(is_equal_approx(float(unit.art.surface.get_shader_parameter("visibility")),0.38),"Cloak only changes artwork opacity")
  unit.ended = true
  unit.queue_free()
 await get_tree().process_frame
 battle.credits = 5000 # Isolated graphics binding fixture, not an economy/balance simulation.
 SaveManager.state.unlocks = ["laser","emp_tower","heavy_aa"]
 for kind in CampaignManager.turrets:
  battle.select_slot(0)
  check(battle.build_turret(str(kind)),"Automatic weapon graphics fixture builds "+str(kind))
  var gun: Node2D = battle.placed[0]
  check(gun.art.body.texture != null,"Automatic weapon has a bound sprite: "+str(kind))
  gun.art.sync(1.2,0,false,true)
  check(gun.disabled_remaining == 0 and gun.shots_fired == 0,"Visual suppression does not change combat state")
  battle.placed[0] = null
  gun.queue_free()
  await get_tree().process_frame
 battle.close_build_mode()
 check(battle.abilities.activate("emp_blast") and battle.view.effects.back().kind == "pulse","EMP keeps its tactical pulse instead of a full-field orange explosion")
 battle.view.effect(Vector2(400,300),"blast",40,Color.ORANGE)
 battle.view.tick(.3)
 var age: float = battle.view.effects[0].age
 battle.set_paused(true)
 battle.simulate(1)
 check(battle.view.effects[0].age == age,"Paused battle freezes the new animation lifecycle")
 battle.set_paused(false)
 battle.view.tick(1)
 check(battle.view.effects.is_empty(),"Animated effects retire within their finite lifetime")
 battle.queue_free()
 await get_tree().process_frame
 print("VISUAL FOUNDATION: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
