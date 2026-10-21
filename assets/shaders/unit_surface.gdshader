shader_type canvas_item;
render_mode unshaded;
// Prelit artwork: no expensive screen reads, glow buffers or renderer-specific APIs.
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform float suppression : hint_range(0.0, 1.0) = 0.0;
uniform float visibility : hint_range(0.0, 1.0) = 1.0;
uniform float damage_amount : hint_range(0.0, 1.0) = 0.0;
uniform float heat : hint_range(0.0, 1.0) = 0.0;
uniform vec4 uv_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool armor_split = false;
uniform vec2 armor_columns = vec2(0.25,0.75);
uniform vec4 component_scorch[6];
uniform int component_scorch_count = 0;
void fragment() {
 vec4 albedo = COLOR;
 vec2 local_uv = clamp((UV - uv_rect.xy) / uv_rect.zw, vec2(0.0), vec2(1.0));
 vec2 panel = floor(local_uv * 28.0);
 float wear = fract(sin(dot(panel, vec2(17.13, 41.71))) * 43758.5453);
 float scorch = smoothstep(0.53, 0.9, wear) * damage_amount;
 albedo.rgb *= 1.0 - scorch * 0.58;
 float fracture = step(0.976, fract(local_uv.x * 19.0 + local_uv.y * 11.0));
 albedo.rgb += vec3(0.3, 0.07, 0.015) * fracture * damage_amount * damage_amount;
 float barrel_zone = 1.0 - smoothstep(0.25, 0.62, local_uv.y);
 albedo.rgb += vec3(0.27, 0.07, 0.015) * heat * heat * barrel_zone;
 for (int i=0; i<6; i++) {
  if (i >= component_scorch_count) { break; }
  vec4 mark = component_scorch[i];
  float charred = 1.0-smoothstep(0.65,1.25,length((UV-mark.xy)/max(mark.zw,vec2(0.0001))));
  albedo.rgb *= 1.0-charred*0.78;
 }
 float luminance = dot(albedo.rgb, vec3(0.2126, 0.7152, 0.0722));
 albedo.rgb = mix(albedo.rgb, vec3(luminance) * vec3(0.66, 0.78, 0.9), suppression * 0.65);
 albedo.rgb = mix(albedo.rgb, vec3(0.91, 0.94, 0.96), hit_flash * 0.35);
 if (armor_split) {
  albedo.a *= step(armor_columns.x,local_uv.x) * step(local_uv.x,armor_columns.y);
 }
 COLOR = vec4(albedo.rgb, albedo.a * visibility);
}
