extends SceneTree
## Runs inside an actual tiny PCK. No fake campus, production scene, gameplay,
## screenshot or GPU-acceptance claim. Test production helpers and configuration.
const REGION = preload("res://campuses/buct_changping/scripts/registered_hd_region.gd")
const BODY = preload("res://campuses/buct_changping/scripts/registered_hd_building.gd")
var checks := 0
var failures: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS " if ok else "FAIL ", label)
	if not ok:
		failures.append(label)

func run() -> void:
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://expectation.json"))
	var case_id: String = expected["case"]
	var data: Variant = REGION._read_json(expected.profile)
	check(data is Dictionary, "Production profile read by unchanged production JSON method")
	if not data is Dictionary:
		finish(case_id)
		return
	var profile: Dictionary = data
	var size := Vector2i(int(profile.body_image_to_world.raw_size[0]), int(profile.body_image_to_world.raw_size[1]))
	var source: String = profile.body_asset
	var surface: String = profile.surface_id_path
	check(REGION._valid_body_profile(profile), "Unchanged real registration passes production schema validation")
	for path in expected.script_sha256:
		check(FileAccess.get_sha256(path) == expected.script_sha256[path], "Production script snapshot is byte-identical: " + path)
	check(not FileAccess.file_exists(source), "Actual PCK has no raw source PNG")
	check(FileAccess.file_exists(source + ".import"), "Actual PCK has unchanged real import mapping")
	check(FileAccess.file_exists(expected.ctex) == (case_id != "missing_ctex"), "Actual imported binary presence matches case")
	check(FileAccess.file_exists(surface) == (case_id != "missing_surface"), "Actual R8 presence matches case")
	check(not FileAccess.file_exists("res://campuses/buct_changping/scenes/playable.tscn"), "Whole campus scene is intentionally not packaged")
	var region: Node2D = REGION.new()
	for region_path in expected.get("region_profiles",[expected.region_profile]):
		var region_expected: Dictionary=expected.duplicate();region_expected.region_profile=region_path
		check_region_resources(region, region_expected)
	var texture: Texture2D = region._texture(source, size, profile.body_rgba_sha256)
	var texture_ok: bool = texture != null
	check(texture_ok == (case_id != "missing_ctex"), "Production texture method rejects actual absent ctex and accepts existing imported Texture2D")
	var surface_resource: ImageTexture = region._r8(surface, size, profile.surface_id_sha256)
	var surface_ok: bool = surface_resource != null
	check(surface_ok == (case_id not in ["missing_surface", "corrupt_surface"]), "Production R8 method validates bytes, size and hash")
	if case_id == "corrupt_surface":
		check(FileAccess.get_file_as_bytes(surface).size() == size.x * size.y, "Corrupt R8 keeps valid byte length")
		check(FileAccess.get_sha256(surface) != profile.surface_id_sha256, "Corrupt R8 differs from production hash")
	var body: Node2D = BODY.new()
	var configured: bool = body.configure(profile, texture)
	check(configured == (case_id == "valid"), "Production configure accepts only complete source-less imported package")
	check(body._configured == configured, "Production configured state agrees with return value")
	check(not region._committed and region.bodies.is_empty(), "Resource-method probe does not commit a region or alter source owners")
	if case_id == "valid" and configured:
		check(texture is CompressedTexture2D, "Loaded resource is real CompressedTexture2D, not a generated test texture")
		check(texture.get_size() == Vector2(size) and texture.get_image().has_mipmaps(), "Production imported dimensions and mipmaps are retained")
		check(body.body_passes.size() == profile.static_overlap_foot_y.size() + 2, "Production common-quad pass count matches explicit registration")
		check(body.alpha_bytes.size() == size.x * size.y, "Production alpha-only picking buffer has expected length")
		check(body.depth_texture != null and body.surface_texture != null, "Production configure creates actual depth and surface textures")
		var depth: Image = body.depth_texture.get_image()
		check(depth.get_format() == Image.FORMAT_RF and depth.get_size() == Vector2i(size.x, int(profile.surface_count)), "Computed depth texture uses exact RF dimensions")
		var reference: PackedByteArray = FileAccess.get_file_as_bytes("res://expected_depth.rf.bin")
		check(REGION._sha(reference) == expected.depth_sha256, "Independent Python float32 depth reference has verified hash")
		check(depth.get_data() == reference, "Production generated RF depth matches every independently packed profile value")
		check(body.column_depths.to_byte_array() == reference, "Production retained column depths match every generated RF texel")
		var field: Image = body.surface_texture.get_image()
		check(field.get_format() == Image.FORMAT_R8 and field.get_size() == size, "Production surface texture uses exact R8 dimensions")
		check(REGION._sha(field.get_data()) == profile.surface_id_sha256, "Production surface texture preserves all verified R8 bytes")
		var raw_min := float(profile.depth_rows_raw_y[0][0])
		var raw_max := raw_min
		for row in profile.depth_rows_raw_y:
			for value in row:
				raw_min = minf(raw_min, float(value))
				raw_max = maxf(raw_max, float(value))
		var foot_y: float = (raw_min + raw_max) * 0.5 * body.image_scale + float(profile.body_image_to_world.origin[1])
		body.update_actor_foot(foot_y, true)
		check(body._active_passes == 2, "Production depth update splits two active intervals at an interior actor foot")
		var first: ShaderMaterial = body.body_passes[0].material
		var second: ShaderMaterial = body.body_passes[1].material
		check(is_equal_approx(float(first.get_shader_parameter("depth_upper")), foot_y) and is_equal_approx(float(second.get_shader_parameter("depth_lower")), foot_y), "Actual production material intervals meet at computed world-space actor foot")
		evidence["depth_sha256"] = REGION._sha(depth.get_data())
		evidence["body_diagnostics"] = body.get_diagnostics()
	else:
		check(not configured and body.body_passes.is_empty() and body.get_child_count() == 0, "Rejected body never allocates or exposes render passes")
		check(body.depth_texture == null, "Rejected body never creates a depth texture")
		check(body.surface_texture == null, "Rejected body never creates a surface texture")
		evidence["safe_rejection"] = not configured and body.get_child_count() == 0
	evidence["source_png_absent"] = not FileAccess.file_exists(source)
	evidence["texture_accepted"] = texture_ok
	evidence["surface_accepted"] = surface_ok
	evidence["configure_accepted"] = configured
	body.free()
	region.free()
	surface_resource = null
	texture = null
	finish(case_id)

func check_region_resources(region: Node2D, expected: Dictionary) -> void:
	var decoded: Variant = REGION._read_json(expected.region_profile)
	check(decoded is Dictionary, "Production north region profile is present and readable")
	if not decoded is Dictionary:
		return
	var data: Dictionary = decoded
	var ground_size := Vector2i(int(data.runtime_size[0]), int(data.runtime_size[1]))
	var seam: Dictionary = data.shared_overlap if data.has("shared_overlap") else data.shared_edges[0]
	var seam_size := Vector2i(int(seam.sample_size[0]), int(seam.sample_size[1]))
	check_positive_texture(region, "north ground", data.ground_asset, ground_size, data.ground_rgba_sha256, expected.region_ctex[data.ground_asset])
	check_positive_texture(region, "shared strip", seam.unfeathered_strip_asset, seam_size, seam.rgba_sha256, expected.region_ctex[seam.unfeathered_strip_asset])
	var ownership: Dictionary = data.source_body_ownership
	var ownership_size := Vector2i(int(ownership["size"][0]), int(ownership["size"][1]))
	check_positive_r8(region, "body ownership", ownership.asset, ownership_size, ownership.sha256)
	for crown in data.foreground:
		var crown_size := Vector2i(int(crown.rect[2] * 5), int(crown.rect[3] * 5))
		check_positive_r8(region, str(crown.id), crown.alpha_asset, crown_size, crown.alpha_sha256)
	if data.has("water_complement"):
		var mask: Dictionary=data.water_complement
		check_positive_r8(region,"original_water_complement",mask.asset,Vector2i(mask["size"][0],mask["size"][1]),mask.sha256)

func check_positive_texture(region: Node2D, label: String, path: String, size: Vector2i, expected_sha: String, ctex: String) -> void:
	check(not FileAccess.file_exists(path), label + ": actual PCK omits raw PNG")
	check(FileAccess.file_exists(path + ".import") and FileAccess.file_exists(ctex), label + ": unchanged real import mapping and binary are present")
	var texture: Texture2D = region._texture(path, size, expected_sha)
	check(texture is CompressedTexture2D, label + ": production helper accepts real imported Texture2D using profile RGBA hash")
	if texture == null:
		return
	check(texture.get_size() == Vector2(size) and texture.get_image().has_mipmaps(), label + ": exact profile dimensions and real mipmaps retained")
	var pixels: Image = texture.get_image().duplicate()
	if pixels.is_compressed():
		pixels.decompress()
	pixels.clear_mipmaps()
	pixels.convert(Image.FORMAT_RGBA8)
	check(REGION._sha(pixels.get_data()) == expected_sha, label + ": loaded base-level RGBA bytes match production profile")
	evidence[label] = {"source_png_absent": true, "dimensions": [size.x, size.y], "rgba_sha256": REGION._sha(pixels.get_data())}

func check_positive_r8(region: Node2D, label: String, path: String, size: Vector2i, expected_sha: String) -> void:
	check(FileAccess.file_exists(path), label + ": actual production R8 field is packaged")
	check(FileAccess.get_file_as_bytes(path).size() == size.x * size.y and FileAccess.get_sha256(path) == expected_sha, label + ": original R8 size and SHA match region profile")
	var texture: ImageTexture = region._r8(path, size, expected_sha)
	check(texture != null, label + ": unchanged production R8 helper accepts field")
	if texture == null:
		return
	var pixels: Image = texture.get_image().duplicate()
	check(pixels.get_format() == Image.FORMAT_R8 and pixels.get_size() == size and pixels.has_mipmaps(), label + ": production R8 texture retains dimensions and generates mipmaps")
	pixels.clear_mipmaps()
	check(REGION._sha(pixels.get_data()) == expected_sha, label + ": created texture preserves production base-level R8 bytes")
	evidence[label] = {"dimensions": [size.x, size.y], "r8_sha256": REGION._sha(pixels.get_data())}

func finish(case_id: String) -> void:
	var report := {"case": case_id, "checks": checks, "failures": failures, "evidence": evidence,
		"scope": "Actual standalone PCK; production resource helpers and building configure only. No campus/scene/gameplay/GPU acceptance.",
		"expected_diagnostics": "Missing imported binary and missing R8 cases may log engine errors; case assertions and exit status are authoritative."}
	var file := FileAccess.open(OS.get_environment("NORTH_PACKAGE_REPORT"), FileAccess.WRITE)
	if file == null:
		printerr("Cannot write north package report")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("NORTH_PACKAGE case=%s checks=%d failures=%d" % [case_id, checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
