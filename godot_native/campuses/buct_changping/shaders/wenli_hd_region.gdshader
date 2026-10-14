shader_type canvas_item;
render_mode unshaded;
uniform vec4 source_rect = vec4(630.0, 615.0, 240.0, 240.0);
varying vec2 world_pixel;

void vertex() {
	world_pixel = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 p = world_pixel - source_rect.xy;
	// Exact source collar is owned by the old map, not a filtered copy.
	if (p.x < 2.0 || p.y < 2.0 || p.x >= source_rect.z - 2.0 || p.y >= source_rect.w - 2.0) {
		discard;
	}
	COLOR = vec4(texture(TEXTURE, p / source_rect.zw).rgb, 1.0);
}
