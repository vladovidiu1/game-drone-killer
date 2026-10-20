shader_type canvas_item;
render_mode unshaded;
// Prelit artwork: no expensive screen reads, glow buffers or renderer-specific APIs.
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform float suppression : hint_range(0.0, 1.0) = 0.0;
uniform float visibility : hint_range(0.0, 1.0) = 1.0;
void fragment() {
 vec4 albedo = COLOR;
 float luminance = dot(albedo.rgb, vec3(0.2126, 0.7152, 0.0722));
 albedo.rgb = mix(albedo.rgb, vec3(luminance) * vec3(0.66, 0.78, 0.9), suppression * 0.65);
 albedo.rgb = mix(albedo.rgb, vec3(0.91, 0.94, 0.96), hit_flash * 0.35);
 COLOR = vec4(albedo.rgb, albedo.a * visibility);
}
