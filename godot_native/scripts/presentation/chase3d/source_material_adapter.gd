extends RefCounted
## Original source HemisphereLight diffuse equation plus exact grain color space.
## Source CampusEnvironment's grain CanvasTexture is NoColorSpace (linear).
## glTF/Godot albedo defaults to sRGB. Preserve bytes and use a linear sampler
## only for the two exact seed755 fingerprints (native/export vertical order).
const SOURCE_GRAIN_SHA: Array[String]=[
	"31816330a8414b3b44dc7d4431d6c2c0748fad94ffc4734ab6098fc9235b24f9",
	"2fcadcc47b6bd757ecd0a6cc78b3d527c81b86d69e26b5bf0bff2a3c5b2b85c2"
]
var hemisphere_enabled: bool=true
var sky_linear: Color=Color("eaf4f1").srgb_to_linear()
var ground_linear: Color=Color("6e7b65").srgb_to_linear()
var hemisphere_intensity: float=2.0
var texture_matches: Dictionary={}
var materials: Dictionary={}
var shaders: Dictionary={}
var adapted_surfaces: int=0
var skipped_unsupported: int=0
func is_source_grain(texture: Texture2D) -> bool:
	if texture==null:return false
	if texture_matches.has(texture):return texture_matches[texture]
	var result:=false
	if texture.get_size()==Vector2(128,128):
		var image: Image=texture.get_image()
		if image!=null:
			if image.is_compressed():image.decompress()
			image.convert(Image.FORMAT_RGBA8)
			if image.has_mipmaps():image.clear_mipmaps()
			var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(image.get_data())
			result=SOURCE_GRAIN_SHA.has(hash.finish().hex_encode())
	texture_matches[texture]=result
	return result
func material_for(source: Material) -> Material:
	var standard: StandardMaterial3D=source as StandardMaterial3D
	if standard==null:return source
	if standard.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED:return source
	var grain: bool=is_source_grain(standard.albedo_texture)
	if not grain and not hemisphere_enabled:return source
	if materials.has(source):return materials[source]
	# The source opaque materials use this bounded PBR feature set. Never
	# discard an unsupported feature merely to force an adaptation.
	if standard.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or standard.shading_mode!=BaseMaterial3D.SHADING_MODE_PER_PIXEL or standard.normal_enabled or standard.roughness_texture!=null or standard.metallic_texture!=null or standard.emission_texture!=null:
		skipped_unsupported+=1;return source
	var cull: String="cull_disabled" if standard.cull_mode==BaseMaterial3D.CULL_DISABLED else ("cull_front" if standard.cull_mode==BaseMaterial3D.CULL_FRONT else "cull_back")
	var shader_code: String="""shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, %s;
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D source_linear_grain : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D source_srgb_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool source_has_albedo = false;
uniform bool source_grain_is_linear = false;
uniform bool source_vertex_color = false;
uniform bool source_vertex_color_srgb = false;
uniform bool source_hemisphere_enabled = true;
uniform vec3 source_sky_linear;
uniform vec3 source_ground_linear;
uniform float source_hemisphere_intensity = 2.0;
uniform vec4 source_emission : source_color;
uniform float source_emission_energy = 0.0;
uniform float source_roughness = 0.88;
uniform float source_metallic = 0.0;
uniform float source_specular = 0.5;
uniform vec3 source_uv_scale = vec3(1.0);
uniform vec3 source_uv_offset = vec3(0.0);
vec3 source_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + vec3(0.055)) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}
vec3 source_to_srgb(vec3 c) {
	c = max(c, vec3(0.0));
	return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - vec3(0.055), step(vec3(0.0031308), c));
}
void fragment() {
	vec2 source_uv = UV * source_uv_scale.xy + source_uv_offset.xy;
	vec3 texel = vec3(1.0);
	if (source_has_albedo) texel = source_grain_is_linear ? texture(source_linear_grain, source_uv).rgb : texture(source_srgb_albedo, source_uv).rgb;
	// Compatibility converts ALBEDO/EMISSION to linear after fragment().
	// Do the source multiplications in linear space, then encode that boundary.
	vec3 linear_base = OUTPUT_IS_SRGB ? source_to_linear(base_color.rgb) : base_color.rgb;
	if (OUTPUT_IS_SRGB && source_has_albedo && !source_grain_is_linear) texel = source_to_linear(texel);
	vec3 vertex_color = source_vertex_color ? (source_vertex_color_srgb ? source_to_linear(COLOR.rgb) : COLOR.rgb) : vec3(1.0);
	vec3 linear_albedo = linear_base * texel * vertex_color;
	ALBEDO = OUTPUT_IS_SRGB ? source_to_srgb(linear_albedo) : linear_albedo;
	ROUGHNESS = source_roughness;
	METALLIC = source_metallic;
	SPECULAR = source_specular;
	vec3 linear_emission = (OUTPUT_IS_SRGB ? source_to_linear(source_emission.rgb) : source_emission.rgb) * source_emission_energy;
	if (source_hemisphere_enabled) {
		vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		vec3 irradiance = mix(source_ground_linear, source_sky_linear, 0.5 * world_normal.y + 0.5) * source_hemisphere_intensity;
		linear_emission += linear_albedo * (1.0 - METALLIC) * irradiance / 3.141592653589793;
	}
	EMISSION = OUTPUT_IS_SRGB ? source_to_srgb(linear_emission) : linear_emission;
}
"""%(cull+(", ambient_light_disabled" if hemisphere_enabled else ""))
	# Material values remain independent, while identical programs compile once.
	var shader_key: String=cull+str(hemisphere_enabled)
	var shader: Shader=shaders.get(shader_key)
	if shader==null:
		shader=Shader.new();shader.code=shader_code;shaders[shader_key]=shader
	var result:=ShaderMaterial.new();result.shader=shader
	result.set_shader_parameter("base_color",standard.albedo_color)
	result.set_shader_parameter("source_has_albedo",standard.albedo_texture!=null)
	result.set_shader_parameter("source_grain_is_linear",grain)
	result.set_shader_parameter("source_vertex_color",standard.vertex_color_use_as_albedo)
	result.set_shader_parameter("source_vertex_color_srgb",standard.vertex_color_is_srgb)
	result.set_shader_parameter("source_linear_grain" if grain else "source_srgb_albedo",standard.albedo_texture)
	result.set_shader_parameter("source_hemisphere_enabled",hemisphere_enabled)
	result.set_shader_parameter("source_sky_linear",Vector3(sky_linear.r,sky_linear.g,sky_linear.b))
	result.set_shader_parameter("source_ground_linear",Vector3(ground_linear.r,ground_linear.g,ground_linear.b))
	result.set_shader_parameter("source_hemisphere_intensity",hemisphere_intensity)
	result.set_shader_parameter("source_emission",standard.emission)
	result.set_shader_parameter("source_emission_energy",standard.emission_energy_multiplier if standard.emission_enabled else 0.0)
	result.set_shader_parameter("source_roughness",standard.roughness)
	result.set_shader_parameter("source_metallic",standard.metallic)
	result.set_shader_parameter("source_specular",standard.metallic_specular)
	result.set_shader_parameter("source_uv_scale",standard.uv1_scale)
	result.set_shader_parameter("source_uv_offset",standard.uv1_offset)
	materials[source]=result
	return result
func adapt_scene(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var source: Material=node.get_active_material(surface)
			var adapted: Material=material_for(source)
			if adapted!=source:node.set_surface_override_material(surface,adapted);adapted_surfaces+=1
	for child: Node in node.get_children():adapt_scene(child)
