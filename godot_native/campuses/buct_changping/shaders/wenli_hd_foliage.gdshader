shader_type canvas_item;
render_mode unshaded;
uniform sampler2D region_rgb : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 source_rect = vec4(630.0, 615.0, 240.0, 240.0);
varying vec2 world_pixel;

void vertex() {
	world_pixel = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Original cropped RGBA still owns the exact LOD0 mask. Its RGB is used
	// only outside the enhanced draw region, including the 17 south pixels.
	vec4 original = textureLod(TEXTURE, UV, 0.0);
	vec2 p = world_pixel - source_rect.xy;
	vec3 rgb = original.rgb;
	if (p.x >= 2.0 && p.y >= 2.0 && p.x < source_rect.z - 2.0 && p.y < source_rect.w - 2.0) {
		rgb = texture(region_rgb, p / source_rect.zw).rgb;
	}
	COLOR = vec4(rgb, original.a);
}
