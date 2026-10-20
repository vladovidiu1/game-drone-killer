from pathlib import Path
r=Path(__file__).resolve().parents[1];a=r/'assets/ui'
variants={'normal':('#293a4a','#17232f','#496174','#44657F'),'hover':('#344f63','#203647','#638ba3','#37B7E5'),'pressed':('#172a38','#17212c','#37B7E5','#37B7E5'),'disabled':('#1b252f','#171f29','#303c48','#34434e'),'primary':('#284d63','#1a3549','#4f8eac','#37B7E5'),'primary_hover':('#38657d','#23485e','#80c6df','#37B7E5'),'fire':('#553e2d','#322921','#a57347','#FF9C42'),'fire_hover':('#705038','#493326','#d5a16f','#FF9C42')}
for name,(hi,lo,border,accent) in variants.items():
 (a/f'button_{name}.svg').write_text(f'''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="64"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="{hi}"/><stop offset="1" stop-color="{lo}"/></linearGradient></defs><path d="M7 1H249L255 7V57L249 63H7L1 57V7Z" fill="url(#g)" stroke="{border}"/><path d="M8 3H248" stroke="#b6c9d5" stroke-opacity=".15"/><path d="M4 12V52" stroke="{accent}" stroke-width="2"/><path d="M12 60H244" stroke="#090f17" stroke-opacity=".5"/></svg>\n''')
def col(h):
 return 'Color('+', '.join(str(round(int(h[i:i+2],16)/255,5)) for i in [0,2,4])+', 1)'
ext=['[ext_resource type="FontFile" path="res://assets/ui/fonts/Barlow-Regular.ttf" id="1"]']
for i,name in enumerate(variants,2):ext.append(f'[ext_resource type="Texture2D" path="res://assets/ui/button_{name}.svg" id="{i}"]')
subs=[]
for i,name in enumerate(variants,2):subs.append(f'''[sub_resource type="StyleBoxTexture" id="{name}"]
texture = ExtResource("{i}")
texture_margin_left = 8.0
texture_margin_top = 8.0
texture_margin_right = 8.0
texture_margin_bottom = 8.0
content_margin_left = 14.0
content_margin_right = 14.0
content_margin_top = 7.0
content_margin_bottom = 7.0
''')
subs+=['''[sub_resource type="StyleBoxFlat" id="focus"]
bg_color = Color(0, 0, 0, 0)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.72, 0.86, 0.94, 0.9)
corner_radius_top_left = 3
corner_radius_top_right = 3
corner_radius_bottom_left = 3
corner_radius_bottom_right = 3
''','''[sub_resource type="StyleBoxFlat" id="panel"]
bg_color = Color(0.061, 0.09, 0.125, 0.96)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.27, 0.36, 0.43, 0.9)
corner_radius_top_left = 4
corner_radius_top_right = 4
corner_radius_bottom_left = 4
corner_radius_bottom_right = 4
shadow_color = Color(0.01, 0.02, 0.03, 0.35)
shadow_size = 5
shadow_offset = Vector2(0, 3)
content_margin_left = 10.0
content_margin_right = 10.0
content_margin_top = 10.0
content_margin_bottom = 10.0
''','''[sub_resource type="StyleBoxFlat" id="track"]
bg_color = Color(0.05, 0.075, 0.1, 1)
corner_radius_top_left = 2
corner_radius_top_right = 2
corner_radius_bottom_left = 2
corner_radius_bottom_right = 2
''','''[sub_resource type="StyleBoxFlat" id="fill"]
bg_color = Color(0.216, 0.718, 0.898, 1)
corner_radius_top_left = 2
corner_radius_top_right = 2
corner_radius_bottom_left = 2
corner_radius_bottom_right = 2
''']
res=['[resource]','default_font = ExtResource("1")','default_font_size = 20',f'Label/colors/font_color = {col("E9F0F6")}',f'Button/colors/font_color = {col("E9F0F6")}',f'Button/colors/font_hover_color = {col("FFFFFF")}',f'Button/colors/font_pressed_color = {col("FFFFFF")}',f'Button/colors/font_disabled_color = {col("778896")}', 'Button/constants/h_separation = 10', 'Button/constants/outline_size = 0']
for state in ['normal','hover','pressed','disabled','focus']:res.append(f'Button/styles/{state} = SubResource("{state}")')
for name,norm,hov in [('TacticalPrimary','primary','primary_hover'),('TacticalFire','fire','fire_hover')]:
 res.append(f'{name}/base_type = &"Button"')
 for state,style in [('normal',norm),('hover',hov),('pressed','pressed'),('disabled','disabled'),('focus','focus')]:res.append(f'{name}/styles/{state} = SubResource("{style}")')
res+=['PanelContainer/styles/panel = SubResource("panel")','PopupPanel/styles/panel = SubResource("panel")','ProgressBar/styles/background = SubResource("track")','ProgressBar/styles/fill = SubResource("fill")','HScrollBar/styles/scroll = SubResource("track")','VScrollBar/styles/scroll = SubResource("track")','VScrollBar/styles/grabber = SubResource("normal")','VScrollBar/styles/grabber_highlight = SubResource("hover")','VScrollBar/styles/grabber_pressed = SubResource("pressed")']
(r/'assets/ui/frontline_theme.tres').write_text('[gd_resource type="Theme" load_steps='+str(1+len(ext)+len(subs))+' format=3]\n\n'+'\n'.join(ext)+'\n\n'+'\n'.join(subs)+'\n'+'\n'.join(res)+'\n')
