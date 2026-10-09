shader_type canvas_item;
render_mode unshaded;
uniform sampler2D lake_screen : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 view_size = vec2(1.0);
uniform vec4 drop0 = vec4(0.0);
uniform vec4 drop1 = vec4(0.0);
uniform vec4 drop2 = vec4(0.0);
uniform vec4 drop3 = vec4(0.0);

void fragment() {
	vec2 point = UV * view_size;
	vec4 beads[4] = {drop0, drop1, drop2, drop3};
	vec4 water = vec4(0.0);
	for (int i = 0; i < 4; i++) {
		vec4 bead = beads[i];
		if (bead.z > 0.0 && bead.w > 0.001) {
			vec2 p = (point - bead.xy) / vec2(bead.z, bead.z * 1.55);
			float distance = length(p);
			if (distance < 1.0) {
				float mask = (1.0 - smoothstep(0.82, 1.0, distance)) * bead.w;
				vec2 normal = p / max(distance, 0.001);
				vec2 bend = normal * (1.0 - distance * distance) * 4.0 * SCREEN_PIXEL_SIZE;
				vec3 through = texture(lake_screen, SCREEN_UV + bend).rgb;
				float rim = smoothstep(0.60, 0.84, distance) * (1.0 - smoothstep(0.88, 1.0, distance));
				float shine = max(0.0, dot(normal, vec2(-0.6, -0.8)));
				vec3 tint = mix(through, vec3(0.10, 0.36, 0.41), 0.17) + vec3(0.64, 0.86, 0.88) * rim * shine * 0.6;
				water = vec4(tint, mask * 0.88);
			}
		}
	}
	COLOR = water;
}
