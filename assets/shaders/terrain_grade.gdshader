shader_type canvas_item;
render_mode unshaded;
uniform float edge_shade : hint_range(0.0, 0.6) = 0.23;
uniform vec4 ambient_tint : source_color = vec4(1.0);
uniform float exposure : hint_range(0.4, 1.2) = 1.0;
// Normalize atlas coordinates so each terrain region has its own vignette.
uniform vec4 uv_rect = vec4(0.0, 0.0, 1.0, 1.0);
void fragment() {
 vec4 terrain = COLOR;
 vec2 local_uv = (UV - uv_rect.xy) / uv_rect.zw;
 vec2 centered = local_uv * 2.0 - 1.0;
 float vignette = smoothstep(0.35, 1.45, length(centered));
 terrain.rgb = mix(terrain.rgb, terrain.rgb * vec3(0.74, 0.84, 0.96), vignette * edge_shade);
 terrain.rgb *= ambient_tint.rgb * exposure;
 COLOR = terrain;
}
