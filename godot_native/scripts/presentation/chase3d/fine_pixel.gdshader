shader_type canvas_item;
render_mode unshaded;
uniform sampler2D palette_lut : filter_nearest, repeat_disable;
// One native texel per sample. No coarse low-resolution upscale or TIME clock.
void fragment() {
	vec2 uv = (floor(UV / TEXTURE_PIXEL_SIZE) + vec2(0.5)) * TEXTURE_PIXEL_SIZE;
	vec4 c = texture(TEXTURE, uv);
	vec3 cell = floor(clamp(c.rgb, vec3(0.0), vec3(1.0)) * 31.0 + vec3(0.5));
	vec2 lookup_uv = vec2((cell.r + 0.5) / 32.0, (cell.g + cell.b * 32.0 + 0.5) / 1024.0);
	COLOR = vec4(texture(palette_lut, lookup_uv).rgb, c.a);
}
