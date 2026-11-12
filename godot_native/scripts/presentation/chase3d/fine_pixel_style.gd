extends RefCounted
## Only the 3D picture is quantized. Native text, prompts and touch targets stay clear.
const SHADER=preload("res://scripts/presentation/chase3d/fine_pixel.gdshader")
static func apply(surface: TextureRect) -> void:
	var material:=ShaderMaterial.new();material.shader=SHADER
	material.set_shader_parameter("palette_lut",load("res://assets/native_755/ride/pelican_palette_lut.png"))
	surface.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	surface.material=material

static func add_campus_sky(environment: Environment) -> void:
	var material:=ProceduralSkyMaterial.new()
	material.sky_top_color=Color("547f9d")
	material.sky_horizon_color=Color("a9bcc2")
	material.ground_horizon_color=material.sky_horizon_color
	material.ground_bottom_color=Color("879883")
	material.sky_curve=.21
	material.ground_curve=.21
	var sky:=Sky.new()
	sky.sky_material=material
	environment.sky=sky
	environment.background_mode=Environment.BG_SKY
