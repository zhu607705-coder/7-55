extends RefCounted
## Presentation assets for stair_b. Source coordinates and graph remain authoritative.
const DIRECTORY := "res://assets/native/stair_b/"
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
	for file: String in FILES.values():
		if not ResourceLoader.exists(DIRECTORY + file, "PackedScene"): return false
	return true

static func instantiate(id: String) -> Node3D:
	if not FILES.has(id): return null
	var packed: PackedScene = load(DIRECTORY + str(FILES[id]))
	if packed == null: return null
	var node: Node3D = packed.instantiate()
	node.set_meta("stair_asset_id", id)
	return node

static func mechanism_transform(spec: Dictionary, value: float) -> Transform3D:
	if spec.kind == "rotate":
		var p: Array = spec.pivot
		var pivot := Vector3(p[0], p[1], p[2])
		var basis := Basis(Vector3.UP, value * PI / 2.0)
		return Transform3D(basis, pivot - basis * pivot)
	var offset := Vector3.ZERO
	offset[{"x": 0, "y": 1, "z": 2}[spec.axis]] = float(spec.stepSize) * value
	return Transform3D(Basis.IDENTITY, offset)
