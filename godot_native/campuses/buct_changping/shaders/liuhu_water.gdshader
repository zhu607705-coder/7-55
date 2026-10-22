shader_type canvas_item;
uniform sampler2D shore_distance : filter_nearest, repeat_disable;
uniform vec2 water_size = vec2(163.0, 108.0);
uniform bool animation_enabled = true;
uniform float wave_time = 0.0;
uniform float amplitude_source_px = 0.30;
uniform float angular_speed = 0.65;
uniform float static_border_source_px = 2.0;
uniform float fade_width_source_px = 8.0;
// Optional display input only. The original small RGBA and distance textures
// remain the sole alpha/shore/animation authority. Never derive water from HD.
uniform bool hd_rgb_enabled = false;
uniform sampler2D hd_rgb : filter_nearest, repeat_disable;
uniform sampler2D hd_original_water : filter_nearest, repeat_disable;
uniform vec4 hd_source_rect = vec4(398.0, 615.0, 256.0, 240.0);
const vec2 WATER_SOURCE_ORIGIN = vec2(317.0, 750.0);

float hd_texel_is_water(ivec2 raw_pixel) {
	ivec2 detail_size = textureSize(hd_rgb,0);
	if (any(lessThan(raw_pixel,ivec2(0))) || any(greaterThanEqual(raw_pixel,detail_size))) { return 0.0; }
	vec2 world_center = hd_source_rect.xy+(vec2(raw_pixel)+vec2(0.5))*hd_source_rect.zw/vec2(detail_size);
	ivec2 source_pixel = ivec2(floor(world_center-WATER_SOURCE_ORIGIN));
	if (any(lessThan(source_pixel,ivec2(0))) || any(greaterThanEqual(source_pixel,ivec2(water_size)))) { return 0.0; }
	return texelFetch(hd_original_water,source_pixel,0).a > 0.5 ? 1.0 : 0.0;
}

// Manual base-level bilinear filtering. Even an undisplaced base sample cannot
// borrow RGB from a texel whose source coordinate is outside original water.
// The return alpha reports whether ALL four support texels are legal, allowing
// the stricter displacement guard to keep its exact four-tap requirement.
vec4 legal_hd_bilinear(vec2 sample_world, vec2 fallback_world) {
	vec2 detail_size = vec2(textureSize(hd_rgb,0));
	vec2 raw = (sample_world-hd_source_rect.xy)*detail_size/hd_source_rect.zw-vec2(0.5);
	ivec2 lo = ivec2(floor(raw));
	vec2 t = fract(raw);
	vec4 valid = vec4(hd_texel_is_water(lo),
		hd_texel_is_water(lo+ivec2(1,0)),
		hd_texel_is_water(lo+ivec2(0,1)),
		hd_texel_is_water(lo+ivec2(1,1)));
	vec4 weights = vec4((1.0-t.x)*(1.0-t.y),t.x*(1.0-t.y),(1.0-t.x)*t.y,t.x*t.y)*valid;
	float total = dot(weights,vec4(1.0));
	vec3 rgb = vec3(0.0);
	if (valid.x > 0.5) { rgb += texelFetch(hd_rgb,lo,0).rgb*weights.x; }
	if (valid.y > 0.5) { rgb += texelFetch(hd_rgb,lo+ivec2(1,0),0).rgb*weights.y; }
	if (valid.z > 0.5) { rgb += texelFetch(hd_rgb,lo+ivec2(0,1),0).rgb*weights.z; }
	if (valid.w > 0.5) { rgb += texelFetch(hd_rgb,lo+ivec2(1,1),0).rgb*weights.w; }
	if (total > 0.0) {
		rgb /= total;
	} else {
		// The fallback is the current ORIGINAL water pixel's center. Uniform5x
		// integer registration places its center on a legal HD texel exactly.
		ivec2 fallback_raw = ivec2(floor((fallback_world-hd_source_rect.xy)*detail_size/hd_source_rect.zw));
		if (hd_texel_is_water(fallback_raw) > 0.5) { rgb = texelFetch(hd_rgb,fallback_raw,0).rgb; }
	}
	return vec4(rgb,min(min(valid.x,valid.y),min(valid.z,valid.w)));
}

void fragment() {
	// Snap to the exact same nearest source-pixel lattice as the unchanged plate.
	vec2 pixel = floor(UV * water_size);
	vec2 center_uv = (pixel + vec2(0.5)) / water_size;
	vec4 original = texture(TEXTURE, center_uv);
	vec3 rgb = original.rgb;
	float distance_px = texture(shore_distance, center_uv).r * 255.0 / 8.0;
	float weight = smoothstep(static_border_source_px,
		static_border_source_px + fade_width_source_px, distance_px);
	vec2 permitted_offset = vec2(0.0);
	bool original_water_guard_passed = false;
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
			permitted_offset = offset;
			original_water_guard_passed = true;
		}
	}
	if (hd_rgb_enabled && original.a > 0.5) {
		// Keep fractional source coordinates: snapped pixel/center_uv would erase
		// the 1280x1200 texture's five-texel-per-source-pixel detail.
		vec2 world_pixel = WATER_SOURCE_ORIGIN + UV * water_size;
		vec2 p = world_pixel - hd_source_rect.xy;
		if (all(greaterThanEqual(p,vec2(0.0))) && all(lessThan(p,hd_source_rect.zw))) {
			float edge_distance = min(min(p.x,p.y),min(hd_source_rect.z-p.x,hd_source_rect.w-p.y));
			float coverage = smoothstep(2.0,12.0,edge_distance);
			if (coverage > 0.0) {
				vec2 fallback_world = WATER_SOURCE_ORIGIN+pixel+vec2(0.5);
				vec3 detail = legal_hd_bilinear(world_pixel,fallback_world).rgb;
				if (original_water_guard_passed) {
					vec2 sample_world = world_pixel + permitted_offset;
					// The original four-source-sample guard above is mandatory.
					// This second guard rejects any displaced four-HD-texel support
					// that includes dry art. Failure keeps the safe static HD above.
					vec4 shifted = legal_hd_bilinear(sample_world,fallback_world);
					if (shifted.a > 0.5) { detail = shifted.rgb; }
				}
				// The full HD core has no low-resolution RGB contribution. Alpha is
				// still read exclusively from the original immutable water texture.
				rgb = coverage >= 1.0 ? detail : mix(rgb,detail,coverage);
			}
		}
	}
	// Time never changes alpha or geometry. No additive glow or generated waves.
	COLOR = vec4(rgb, original.a);
}
