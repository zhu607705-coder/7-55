shader_type canvas_item;
uniform sampler2D shore_distance : filter_nearest, repeat_disable;
uniform vec2 water_size = vec2(163.0, 108.0);
uniform bool animation_enabled = true;
uniform float wave_time = 0.0;
uniform float amplitude_source_px = 0.30;
uniform float angular_speed = 0.65;
uniform float static_border_source_px = 2.0;
uniform float fade_width_source_px = 8.0;

void fragment() {
	// Snap to the exact same nearest source-pixel lattice as the unchanged plate.
	vec2 pixel = floor(UV * water_size);
	vec2 center_uv = (pixel + vec2(0.5)) / water_size;
	vec4 original = texture(TEXTURE, center_uv);
	vec3 rgb = original.rgb;
	float distance_px = texture(shore_distance, center_uv).r * 255.0 / 8.0;
	float weight = smoothstep(static_border_source_px,
		static_border_source_px + fade_width_source_px, distance_px);
	if (animation_enabled && original.a > 0.5 && weight > 0.0) {
		float phase = wave_time * angular_speed;
		vec2 offset = vec2(
			(sin(pixel.y * 0.18 + phase) + 0.35 * sin((pixel.x + pixel.y) * 0.13 - phase * 0.58)) / 1.35,
			0.35 * cos(pixel.x * 0.16 - phase * 0.85)
		) * amplitude_source_px * weight;
		vec2 sample_pixel = pixel + offset;
		vec2 lo = floor(sample_pixel);
		vec2 fraction = fract(sample_pixel);
		vec4 a = texture(TEXTURE, (lo + vec2(0.5, 0.5)) / water_size);
		vec4 b = texture(TEXTURE, (lo + vec2(1.5, 0.5)) / water_size);
		vec4 c = texture(TEXTURE, (lo + vec2(0.5, 1.5)) / water_size);
		vec4 d = texture(TEXTURE, (lo + vec2(1.5, 1.5)) / water_size);
		// Even the four interpolated samples must belong to this same water object.
		// A dry/transparent sample falls back to exact source RGB, never shore art.
		if (min(min(a.a, b.a), min(c.a, d.a)) > 0.5) {
			rgb = mix(mix(a.rgb, b.rgb, fraction.x), mix(c.rgb, d.rgb, fraction.x), fraction.y);
		}
	}
	// Time never changes alpha or geometry. No additive glow or generated waves.
	COLOR = vec4(rgb, original.a);
}
