shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// A bounded material-side approximation of the lamp's warm reflected light.
// It adds no light pass, screen glow, geometry, or per-frame update loop.
uniform vec4 surface_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform float surface_metallic : hint_range(0.0, 1.0) = 0.8;
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.35;
uniform float lamp_on : hint_range(0.0, 1.0) = 0.0;
uniform float spill_strength : hint_range(0.0, 2.0) = 0.8;
uniform vec4 spill_color : source_color = vec4(1.0, 0.91, 0.73, 1.0);
varying float reflection_facing;
varying vec3 lamp_world_position;

void vertex() {
	lamp_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_position = lamp_world_position;
	vec3 nearest_core = vec3(0.0, clamp(world_position.y, 6.75, 7.55), 0.0);
	vec3 to_core = nearest_core - world_position;
	vec3 world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	float facing = max(0.0, dot(world_normal, normalize(to_core + vec3(0.0, 0.0001, 0.0))));
	reflection_facing = 0.32 + 0.68 * facing;
}

void fragment() {
	// Evaluate the radius at the fragment's world position: a tapered pole has
	// long triangles, so interpolating a vertex-only cutoff would leak light
	// metres down the shaft. Squared distances avoid a per-fragment square root.
	vec3 nearest_core = vec3(0.0, clamp(lamp_world_position.y, 6.75, 7.55), 0.0);
	vec3 to_core = nearest_core - lamp_world_position;
	float distance_squared = dot(to_core, to_core);
	float bounded_falloff = (1.0 - smoothstep(0.7225, 4.41, distance_squared)) / (1.0 + 1.4 * distance_squared);
	ALBEDO = surface_color.rgb;
	METALLIC = surface_metallic;
	ROUGHNESS = surface_roughness;
	EMISSION = spill_color.rgb * reflection_facing * bounded_falloff * spill_strength * lamp_on;
}
