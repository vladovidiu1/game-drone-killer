extends Control
var hero: TextureRect
var shade: TextureRect

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 hero = TextureRect.new()
 hero.texture = preload("res://assets/backgrounds/sentinel_keyart.png")
 hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 hero.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(hero)
 shade = TextureRect.new()
 var gradient := GradientTexture2D.new()
 gradient.width = 256
 gradient.height = 4
 gradient.fill_from = Vector2(0,0)
 gradient.fill_to = Vector2(0.85,0)
 gradient.gradient = Gradient.new()
 gradient.gradient.set_color(0,Color(0.025,0.045,0.07,0.85))
 gradient.gradient.set_color(1,Color(0.025,0.045,0.07,0.02))
 shade.texture = gradient
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(shade)
 resized.connect(queue_redraw)

func set_screen(screen: String) -> void:
 visible = screen != "game"
 hero.modulate = Color.WHITE if screen == "menu" else Color(0.24,0.3,0.37,1)
 queue_redraw()

func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("151B24"))
