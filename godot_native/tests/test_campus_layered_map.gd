extends SceneTree
## Runtime coverage, not a static composition-only acceptance.
const Layered = preload("res://scripts/presentation/campus_layered_map.gd")
var failures := 0
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("Campus layers: " + label)
func layer_pixel(art: Layered, id: String, point: Vector2i) -> Color:
	for row: Dictionary in art.manifest.layers:
		if row.id != id: continue
		var local := point - Vector2i(row.origin[0], row.origin[1])
		for tile: Dictionary in row.tiles:
			var rect: Array = tile.rect
			var bounds := Rect2i(rect[0], rect[1], rect[2], rect[3])
			if bounds.has_point(local):
				return art.textures[str(tile.path)].get_image().get_pixelv(local - bounds.position)
		break
	return Color.TRANSPARENT
func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(), "isolated save")
	if failures: quit(1); return
	var art := Layered.new()
	check(art.configure(), "manifest and every texture load")
	if not art.ready: quit(1); return
	check(art.max_texture_dimension <= 1024, "bounded GPU textures")
	check(not art.manifest.get("waterTiles", []).is_empty(), "independent animated true-water tiles")
	var animated_tiles := 0
	for tile: Dictionary in art.manifest.waterTiles:
		if FileAccess.get_sha256(str(tile.frames[0])) != FileAccess.get_sha256(str(tile.frames[1])): animated_tiles += 1
		check(tile.frames.size() == 3, "three water frames")
		var alpha: PackedByteArray
		for i in range(3):
			check(FileAccess.get_sha256(str(tile.frames[i])) == str(tile.frameSha256[i]), "water bytes match identity")
			var image: Image = art.textures[str(tile.frames[i])].get_image()
			image.convert(Image.FORMAT_RGBA8)
			var bytes := image.get_data()
			var current := PackedByteArray()
			for pixel in range(3, bytes.size(), 4): current.append(bytes[pixel])
			if i == 0: alpha = current
			else: check(current == alpha, "water movement never moves its shore mask")
	check(animated_tiles > 0, "water frames actually animate")
	var curb := Vector2i(2352, 1680)
	for row: Dictionary in art.manifest.layers:
		check(str(row.category) != "water", "no static whole-water layer hides animation")
		for tile: Dictionary in row.tiles:
			check(FileAccess.get_sha256(str(tile.path)) == str(tile.sha256), "runtime tile bytes match manifest")
		check(not str(row.id).begins_with("central_hall"), "old main hall retired")
		check(not str(row.id).begins_with("west15_compound_edge_reconstructed"), "old west15 retired")
		check(not str(row.id).begins_with("north16_compound_derived_recovery"), "old north16 retired")
		check(not str(row.id).begins_with("site16_middle_wholecompound"), "old middle16 retired")
	check(layer_pixel(art, "central_long_v4", curb).a > .9 and layer_pixel(art, "right_v4__tree_011", curb).a == 0, "stone beside the tree stays on the ground at the original source pixel")
	for sample: Array in [
		["right_v4__tree_173", "central_long_v4", Vector2i(2379, 2780), Vector2i(2378, 2815), Vector2i(2365, 2818)],
		["walkable_tree_719_1967", "haina_V4", Vector2i(730, 1974), Vector2i(730, 1999), Vector2i(736, 2002)],
		["walkable_tree_606_2034", "yuhu_third_combined", Vector2i(617, 2037), Vector2i(617, 2062), Vector2i(622, 2065)],
	]:
		var tree: String = sample[0]
		var ground: String = sample[1]
		for point: Vector2i in [sample[2], sample[3]]:
			check(layer_pixel(art, tree, point).a > .9 and layer_pixel(art, ground, point).a == 0, tree + " owns its canopy tip and visible trunk")
		var rim: Vector2i = sample[4]
		check(layer_pixel(art, ground, rim).a > .9 and layer_pixel(art, tree, rim).a == 0, tree + " leaves the planter rim or turf at ground depth")
	var rear_path := Vector2i(2470, 2554)
	var front_wall := Vector2i(2495, 2765)
	check(layer_pixel(art, "central_long_v4", rear_path).a > .9 and layer_pixel(art, "right_v4__biology_complex", rear_path).a == 0, "biology roof no longer redraws the path to its north")
	check(layer_pixel(art, "right_v4__biology_complex", front_wall).a > .9, "biology facade includes the visible bottom of the wall")
	var west_lawn := Vector2i(3300, 2810)
	check(layer_pixel(art, "west_v1_accepted_fusion_unchanged", west_lawn) == layer_pixel(art, "grass", west_lawn), "west lawn overlaps the same exact base texel at the seam")
	var state = root.get_node("State")
	state.developer_mode = true
	state.d = state.initial()
	var shell = load("res://scenes/main.tscn").instantiate()
	root.add_child(shell)
	await process_frame
	var world = shell.world
	state.d.native.scene = "campus_bootstrap"
	state.d.rpgCheckpoint = ""
	state.d.native.positions = {}
	world.refresh_world()
	check(world.campus_layers.ready and world.background == null and not world.background_is_tiled, "no old baked plate underneath")
	check(world.world_size == Vector2(4516,3420), "source coordinates preserved")
	check(world.can_stand(world.player), "safe campus spawn")
	for checkpoint: String in ["", "campus_library_gate", "campus_canteen_gate", "campus_theater_junction", "campus_qizhen_gate", "campus_qizhen_transition_stop"]:
		state.d.rpgCheckpoint = checkpoint
		state.d.native.positions = {}
		world.world_key = ""
		world.refresh_world()
		check(world.can_stand(world.player), "safe checkpoint " + checkpoint)
		var can_move := false
		for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-1,-1), Vector2(1,-1), Vector2(-1,1), Vector2(1,1)]:
			if world.can_stand(world.player + direction * 4): can_move = true
		check(can_move, "checkpoint has an ordinary movement exit " + checkpoint)
	check(not world.can_stand(Vector2(-1,0)), "outside campus blocked")
	world.campus_layers.ready = false
	check(not world.can_stand(world.player), "missing layers fail closed")
	world.campus_layers.ready = true
	state.d.native.scene = "library_interior"
	world.refresh_world()
	check(not world.campus_layers.ready and world.campus_layers.textures.is_empty(), "leaving releases campus textures")
	shell.queue_free()
	await process_frame
	art.release()
	check(not art.ready and art.textures.is_empty(), "release resets standalone renderer")
	print("Campus layered runtime: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
