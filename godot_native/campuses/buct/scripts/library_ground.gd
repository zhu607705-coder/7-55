extends Sprite2D
## Preserve original peripheral trees/paths; fully erase the old body and old shadows.
## Coverage is geometry data, not a rewritten source or generated PNG.
func _ready() -> void:
	var bytes := FileAccess.get_file_as_bytes("res://campuses/buct/data/library-ground-coverage.bin")
	if bytes.size()!=251*169:
		push_error("Library ground coverage is missing or has invalid dimensions")
		hide()
		return
	var mask := Image.create_from_data(251,169,false,Image.FORMAT_R8,bytes)
	var shader_material := ShaderMaterial.new()
	shader_material.shader = preload("res://campuses/buct/shaders/library_ground.gdshader")
	shader_material.set_shader_parameter("repair_coverage",ImageTexture.create_from_image(mask))
	material = shader_material
