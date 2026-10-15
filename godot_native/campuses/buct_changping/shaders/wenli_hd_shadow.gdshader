shader_type canvas_item;
render_mode unshaded;
uniform float shadow_opacity = 0.28;
void fragment() {
	COLOR = vec4(0.0, 0.0, 0.0, texture(TEXTURE, UV).r * shadow_opacity);
}
