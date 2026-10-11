extends RefCounted
## Presentation assets for stair_b. Source coordinates and graph remain authoritative.
const DIRECTORY := "res://assets/native/stair_b/"
const CLEAN_STONE := DIRECTORY + "terrazzo_clean_pixel_albedo.png"
static var clean_stone_texture: Texture2D
const FILES := {
	"b_lower_stair": "lower_rotating_stair.glb",
	"b_upper_stair": "upper_rotating_stair.glb",
	"b_mid_lift": "mid_lift_platform.glb",
	"b_exit_slide": "exit_slide_platform.glb",
	"b_platform_start": "b_platform_start.glb",
	"b_platform_lower_base": "b_platform_lower_base.glb",
	"b_platform_landing": "b_platform_landing.glb",
	"b_platform_island": "b_platform_island.glb",
	"b_platform_exit": "b_platform_exit.glb",
	"b_deco_fire_door": "school_door.glb",
}

static func available() -> bool:
	# Atomic fallback: an incomplete export never removes half of the original scene.
	if not ResourceLoader.exists(CLEAN_STONE): return false
	for file: String in FILES.values():
		if not ResourceLoader.exists(DIRECTORY + file, "PackedScene"): return false
	return true

static func instantiate(id: String) -> Node3D:
	if not FILES.has(id): return null
	var packed: PackedScene = load(DIRECTORY + str(FILES[id]))
	if packed == null: return null
	var node: Node3D = packed.instantiate()
	node.set_meta("stair_asset_id", id)
	_apply_stone_material(node)
	return node

static func _apply_stone_material(node: Node) -> void:
	if clean_stone_texture == null:
		var imported: Texture2D = load(CLEAN_STONE)
		var bitmap: Image = imported.get_image()
		if bitmap.is_compressed(): bitmap.decompress()
		# Preserve the imported nearest+mipmap sampling at distant oblique angles.
		if not bitmap.has_mipmaps(): bitmap.generate_mipmaps()
		clean_stone_texture = ImageTexture.create_from_image(bitmap)
	if node is MeshInstance3D:
		for index in range(node.mesh.get_surface_count()):
			var original: Material = node.get_active_material(index)
			if original is StandardMaterial3D and original.resource_name == "Campus grey terrazzo":
				var surface: StandardMaterial3D = original.duplicate()
				surface.albedo_texture = clean_stone_texture
				node.set_surface_override_material(index, surface)
	for child in node.get_children(): _apply_stone_material(child)

static func mechanism_transform(spec: Dictionary, value: float) -> Transform3D:
	if spec.kind == "rotate":
		var p: Array = spec.pivot
		var pivot := Vector3(p[0], p[1], p[2])
		var basis := Basis(Vector3.UP, value * PI / 2.0)
		return Transform3D(basis, pivot - basis * pivot)
	var offset := Vector3.ZERO
	offset[{"x": 0, "y": 1, "z": 2}[spec.axis]] = float(spec.stepSize) * value
	return Transform3D(Basis.IDENTITY, offset)
