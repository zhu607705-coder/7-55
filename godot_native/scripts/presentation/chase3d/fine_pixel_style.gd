extends RefCounted
## Only the 3D picture is quantized. Native text, prompts and touch targets stay clear.
const SHADER=preload("res://scripts/presentation/chase3d/fine_pixel.gdshader")
static func apply(surface: TextureRect) -> void:
	var material:=ShaderMaterial.new();material.shader=SHADER
	material.set_shader_parameter("palette_lut",load("res://assets/native_755/ride/pelican_palette_lut.png"))
	surface.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	surface.material=material
