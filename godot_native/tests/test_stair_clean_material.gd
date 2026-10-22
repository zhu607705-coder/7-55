extends SceneTree
## Independent imported-resource comparison. No production files are changed.
const EXPECTED_PNG_SHA := "d6a96b7306512791085eb2c45a494de4f814dde1d9c003996a55be0b8ab0e4ad"
const STONE_NAME := "Campus grey terrazzo"
var checks := 0
var failures := 0
var surfaces := 0
var stone_surfaces := 0
var untouched_surfaces := 0
var changed_properties: Dictionary = {}
var shared_texture: Texture2D
var material_counts: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CLEAN STONE: " + label)

func all_nodes(node: Node) -> Array:
	var nodes: Array = [node]
	for child in node.get_children(): nodes.append_array(all_nodes(child))
	return nodes

func properties(material: Material) -> Dictionary:
	var out: Dictionary = {}
	for item in material.get_property_list():
		var property: String = item.name
		if int(item.usage) & PROPERTY_USAGE_STORAGE == 0: continue
		if property in ["resource_path", "resource_scene_unique_id"]: continue
		out[property] = material.get(property)
	return out

func compare_asset(adapter: Script, id: String) -> void:
	var packed: PackedScene = load(adapter.DIRECTORY + str(adapter.FILES[id]))
	var original: Node3D = packed.instantiate()
	var snapshots: Dictionary = {}
	var geometry: Dictionary = {}
	for node in all_nodes(original):
		if not node is MeshInstance3D: continue
		for index in range(node.mesh.get_surface_count()):
			var key := str(original.get_path_to(node)) + ":" + str(index)
			snapshots[key] = properties(node.get_active_material(index))
			geometry[key] = hash(node.mesh.surface_get_arrays(index))
	var candidate: Node3D = adapter.instantiate(id)
	check(candidate != null, id + " available through production adapter")
	check(candidate.get_meta("stair_asset_id", "") == id, id + " source owner metadata unchanged")
	check(all_nodes(original).size() == all_nodes(candidate).size(), id + " exact imported node count")
	for node in all_nodes(original):
		var path: NodePath = original.get_path_to(node)
		var adapted: Node = candidate.get_node_or_null(path)
		check(adapted != null, id + " original hierarchy " + str(path))
		if adapted == null: continue
		check(adapted.get_class() == node.get_class(), id + " original node type " + str(path))
		if node is Node3D:
			check(adapted.transform == node.transform, id + " exact imported pose " + str(path))
			check(adapted.visible == node.visible, id + " imported visibility " + str(path))
		if not node is MeshInstance3D: continue
		check(adapted.mesh == node.mesh, id + " original geometry resource " + str(path))
		check(adapted.material_override == node.material_override, id + " mesh-level material override preserved")
		for index in range(node.mesh.get_surface_count()):
			surfaces += 1
			var key := str(path) + ":" + str(index)
			var before: Dictionary = snapshots[key]
			var raw_material: Material = node.get_active_material(index)
			var actual: Material = adapted.get_active_material(index)
			var after: Dictionary = properties(actual)
			var differences: Array = []
			for property in before:
				if before[property] != after.get(property): differences.append(property)
			check(properties(raw_material) == before, id + " imported shared material not mutated " + key)
			check(hash(adapted.mesh.surface_get_arrays(index)) == geometry[key], id + " vertex/index/normal/UV arrays unchanged " + key)
			var name: String = raw_material.resource_name
			material_counts[name] = int(material_counts.get(name, 0)) + 1
			if name == STONE_NAME:
				stone_surfaces += 1
				check(differences == ["albedo_texture"], id + " only stone albedo changed " + key + " observed=" + str(differences))
				check(actual != raw_material, id + " stone material is isolated duplicate " + key)
				check(actual.texture_filter == 2, id + " original nearest+mipmap filter 2 preserved " + key)
				check(actual.roughness == before.roughness and actual.metallic == before.metallic, id + " roughness/metallic preserved " + key)
				if shared_texture == null: shared_texture = actual.albedo_texture
				check(actual.albedo_texture == shared_texture, id + " one shared texture across all stone surfaces")
				changed_properties[id + "/" + key] = differences
			else:
				untouched_surfaces += 1
				check(differences.is_empty(), id + " non-stone properties unchanged " + name)
				check(actual == raw_material, id + " non-stone material resource untouched " + name)
				check(adapted.get_surface_override_material(index) == node.get_surface_override_material(index), id + " no new non-stone override " + key)
	original.free()
	candidate.free()

func run() -> void:
	var adapter: Script = load("res://scripts/games/chapter4_stair_assets.gd")
	check(adapter.available(), "complete delivered asset set available")
	check(adapter.instantiate("not_a_source_asset") == null, "unknown asset remains rejected")
	check(FileAccess.get_sha256(adapter.CLEAN_STONE) == EXPECTED_PNG_SHA, "approved four-color texture exact bytes")
	for id: String in adapter.FILES: compare_asset(adapter, id)
	check(surfaces == 644, "all 644 actual imported material surfaces compared")
	check(stone_surfaces == 32, "exactly 32 stone surfaces adapted")
	check(untouched_surfaces == 612, "all 612 other surfaces untouched including entire wooden door")
	check(shared_texture != null, "shared stone texture actually used")
	if shared_texture != null:
		var bitmap: Image = shared_texture.get_image()
		check(bitmap.get_size() == Vector2i(128, 128), "source pixel texture dimensions")
		check(bitmap.has_mipmaps(), "mipmaps available for unchanged filter 2")
		var colors: Dictionary = {}
		for y in range(bitmap.get_height()):
			for x in range(bitmap.get_width()):
				var pixel: Color = bitmap.get_pixel(x, y)
				var color_key: int = pixel.to_rgba32()
				colors[color_key] = int(colors.get(color_key, 0)) + 1
		check(colors.size() == 4, "exactly four base-mipmap colors")
		var greatest := 0
		for count: int in colors.values(): greatest = maxi(greatest, count)
		var speckle_fraction := 1.0 - float(greatest) / (128 * 128)
		check(absf(speckle_fraction - .15032958984375) < .0000001, "approved sparse aggregate density 15.03296 percent")
		var source_bitmap := Image.new()
		check(source_bitmap.load_png_from_buffer(FileAccess.get_file_as_bytes(adapter.CLEAN_STONE)) == OK, "approved PNG decodes")
		var copied := bitmap.duplicate()
		copied.clear_mipmaps()
		check(copied.get_data() == source_bitmap.get_data(), "runtime uses approved texture pixels without color/filter resampling")
	# Inspect the actual interactive renderer as well as isolated asset instances.
	root.size = Vector2i(960, 540)
	var renderer: Script = load("res://scripts/games/chapter4_stairs.gd")
	var game: Control = renderer.new()
	game.level_index = 1
	root.add_child(game)
	game.setup({"session": "independent-clean-stone"})
	var deadline: int = Time.get_ticks_msec() + 10000
	while game.busy and Time.get_ticks_msec() < deadline: await process_frame
	check(not game.busy and game.level.id == "stair_b", "real renderer settles on original stair_b")
	check(game.visible and game.caption.is_visible_in_tree() and game.toolbar.is_visible_in_tree(), "formal interactive text and controls remain visible")
	var rendered_stone := 0
	for node in all_nodes(game.root3d):
		if not node is MeshInstance3D: continue
		for index in range(node.mesh.get_surface_count()):
			var material: Material = node.get_active_material(index)
			if material is StandardMaterial3D and material.resource_name == STONE_NAME:
				rendered_stone += 1
				check(material.albedo_texture == shared_texture, "real scene uses shared clean albedo")
	check(rendered_stone == 32, "actual renderer has exactly 32 cleaned stone surfaces")
	game.queue_free()
	await process_frame
	# Execute the real presentation's setup and marker refresh. This deliberately
	# stops before its deferred automated route; the GUI capture verifies that route.
	var presentation_script: Script = load("res://tests/preview_stair_b_presentation.gd")
	var presentation: Control = presentation_script.new()
	root.add_child(presentation)
	presentation._process(0.0)
	check(presentation.capture_directory.is_empty(), "presentation does not write captures by default")
	check(not presentation.game.visible, "presentation hides the real renderer's text UI host")
	check(presentation.game.level.id == "stair_b", "presentation retains original level identity")
	check(presentation.game.view3d.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "hidden GUI does not suspend the actual 3D renderer")
	var visible_displays := 0
	var hidden_text_controls := 0
	for node in all_nodes(presentation):
		if node is TextureRect and node.is_visible_in_tree():
			visible_displays += 1
			check(node.texture == presentation.game.view3d.get_texture(), "presentation displays the actual native viewport")
		if node is Label or node is RichTextLabel or node is BaseButton:
			hidden_text_controls += 1
			check(not node.is_visible_in_tree(), "presentation has no visible text UI or buttons")
		if node is Label3D: check(not node.is_visible_in_tree(), "presentation has no visible 3D text")
	check(visible_displays == 1, "exactly one clean viewport displayed")
	check(hidden_text_controls > 10, "real interactive controls exist but are hidden only in presentation")
	var hidden_dots := 0
	for node in all_nodes(presentation.game.root3d):
		if node is MeshInstance3D and node.mesh is SphereMesh and is_equal_approx(node.mesh.radius, 0.1):
			hidden_dots += 1
			check(not node.visible, "source navigation dots hidden only in presentation")
	check(hidden_dots == presentation.game.level.nodes.size(), "all and only source-sized navigation dots covered")
	check(presentation.game.actor.is_visible_in_tree(), "source actor remains visible in the native 3D world")
	# Reproduce a source-level rebuild after _process but before the next draw.
	# The old process-only implementation leaves every new marker visible here.
	check(RenderingServer.frame_pre_draw.is_connected(presentation._prepare_visible_frame), "presentation refresh is attached to actual pre-draw signal")
	var old_root: int = presentation.observed_root
	presentation.game.level_index = 2
	presentation.game._load_level()
	check(presentation.game.level.id == "stair_c", "actual source renderer rebuilds next level")
	check(presentation.observed_root == old_root and presentation.game.root3d.get_instance_id() != old_root, "negative control recreates root after last process refresh")
	var visible_before_draw := 0
	for node in all_nodes(presentation.game.root3d):
		if node is MeshInstance3D and node.mesh is SphereMesh and is_equal_approx(node.mesh.radius, 0.1) and node.visible:
			visible_before_draw += 1
	check(visible_before_draw == presentation.game.level.nodes.size(), "negative control new source markers start visible")
	RenderingServer.frame_pre_draw.emit()
	var invisible_after_draw := 0
	for node in all_nodes(presentation.game.root3d):
		if node is MeshInstance3D and node.mesh is SphereMesh and is_equal_approx(node.mesh.radius, 0.1):
			check(not node.visible, "new level navigation dot hidden before first draw")
			if not node.visible: invisible_after_draw += 1
	check(invisible_after_draw == presentation.game.level.nodes.size(), "no first-frame navigation flash on rebuilt source level")
	check(presentation.observed_root == presentation.game.root3d.get_instance_id(), "pre-draw tracks exact rebuilt root")
	presentation.free()
	await create_timer(0.6).timeout
	print("CLEAN_STONE_REPORT ", JSON.stringify({"checks": checks, "failures": failures, "surfaces": surfaces, "stone_surfaces": stone_surfaces, "untouched_surfaces": untouched_surfaces, "material_counts": material_counts, "texture_sha256": EXPECTED_PNG_SHA}))
	quit(1 if failures else 0)
