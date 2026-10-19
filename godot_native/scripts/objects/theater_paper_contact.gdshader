shader_type canvas_item;
// Object-local, pixel-aligned reveal. No emitted light or screen-space effect.
uniform float reveal : hint_range(0.0, 1.0) = 0.0;
uniform bool unmarked = false;
varying vec4 object_tint;
void vertex() {
	object_tint = COLOR;
}
void fragment() {
	vec2 cell = floor(UV * 64.0) / 64.0;
	float grain = mod(floor(UV.x * 32.0) + floor(UV.y * 32.0) * 3.0, 5.0) * 0.006;
	float distance_from_contact = distance(cell, vec2(0.80, 0.48)) + grain;
	float mask = 1.0 - smoothstep(reveal * 1.08 - 0.018, reveal * 1.08 + 0.018, distance_from_contact);
	if (reveal <= 0.0) { mask = 0.0; }
	if (reveal >= 1.0) { mask = 1.0; }
	COLOR = texture(TEXTURE, UV) * object_tint;
	COLOR.a *= unmarked ? 1.0 - mask : mask;
}
