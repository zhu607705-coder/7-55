shader_type canvas_item;
// Union of disjoint fixed alpha masks. Each water pixel has exactly one owner.
uniform sampler2D main_rgba : filter_nearest, repeat_disable;
uniform sampler2D south_rgba : filter_nearest, repeat_disable;
uniform bool main_installed = true;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 pixel = floor(UV * vec2(950.0,1656.0));
	vec2 main_local = pixel - vec2(317.0,750.0);
	vec2 south_local = pixel - vec2(395.0,867.0);
	float removed_alpha = 0.0;
	if (main_installed && all(greaterThanEqual(main_local,vec2(0.0))) && all(lessThan(main_local,vec2(163.0,108.0)))) {
		removed_alpha = texture(main_rgba,(main_local+vec2(0.5))/vec2(163.0,108.0)).a;
	}
	if (all(greaterThanEqual(south_local,vec2(0.0))) && all(lessThan(south_local,vec2(24.0,21.0)))) {
		removed_alpha = max(removed_alpha,texture(south_rgba,(south_local+vec2(0.5))/vec2(24.0,21.0)).a);
	}
	COLOR = vec4(source.rgb,source.a*(1.0-removed_alpha));
}
