shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 base_color : source_color = vec4(0.91, 0.88, 0.78, 1.0);
// Fixed three-value feather planes, original morning light direction.
void fragment() {
	vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float light = dot(n, normalize(vec3(-0.45, 0.8, -0.35)));
	float value = light > 0.25 ? 1.0 : (light > -0.35 ? 0.82 : 0.63);
	ALBEDO = base_color.rgb * value;
}
