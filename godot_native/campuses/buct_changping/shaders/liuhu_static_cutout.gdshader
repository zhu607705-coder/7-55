shader_type canvas_item;
// Complementary ownership, not a second retained copy of the water.
uniform sampler2D water_rgba : filter_nearest, repeat_disable;
uniform vec2 source_size = vec2(950.0, 1656.0);
uniform vec4 source_crop = vec4(317.0, 750.0, 163.0, 108.0);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 pixel = floor(UV * source_size);
	vec2 local = pixel - source_crop.xy;
	float water_alpha = 0.0;
	if (all(greaterThanEqual(local, vec2(0.0))) && all(lessThan(local, source_crop.zw))) {
		water_alpha = texture(water_rgba, (local + vec2(0.5)) / source_crop.zw).a;
	}
	COLOR = vec4(source.rgb, source.a * (1.0 - water_alpha));
}
