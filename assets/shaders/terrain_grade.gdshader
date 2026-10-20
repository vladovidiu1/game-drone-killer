shader_type canvas_item;
render_mode unshaded;
uniform float edge_shade : hint_range(0.0, 0.6) = 0.23;
void fragment() {
 vec4 terrain = COLOR;
 vec2 centered = UV * 2.0 - 1.0;
 float vignette = smoothstep(0.35, 1.45, length(centered));
 terrain.rgb = mix(terrain.rgb, terrain.rgb * vec3(0.74, 0.84, 0.96), vignette * edge_shade);
 COLOR = terrain;
}
