shader_type canvas_item;
render_mode unshaded, blend_disabled;

// Read the completed composition, not an individual sprite's source color.
// An explicit BackBufferCopy immediately before this item owns the sample.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float lift_amount : hint_range(0.0, 0.8) = 0.60;

void fragment() {
	vec4 source = textureLod(screen_texture, SCREEN_UV, 0.0);
	float peak = max(source.r, max(source.g, source.b));
	float low = min(source.r, min(source.g, source.b));
	float lightness = (peak + low) * 0.5;
	// Protect dark ink. Bounded HSL lightness lifts even warm paper whose red
	// channel is already 1, while preserving hue and HSL saturation.
	float ink_guard = smoothstep(0.20, 0.40, peak);
	float lifted = lightness + lift_amount * lightness * (1.0 - lightness) * ink_guard;
	float old_chroma_capacity = min(lightness, 1.0 - lightness);
	float new_chroma_capacity = min(lifted, 1.0 - lifted);
	float chroma_scale = new_chroma_capacity / max(old_chroma_capacity, 0.000001);
	vec3 graded = vec3(lifted) + (source.rgb - vec3(lightness)) * chroma_scale;
	COLOR = vec4(graded, source.a);
}
