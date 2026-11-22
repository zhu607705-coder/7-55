extends SceneTree
const Assets = preload("res://scripts/objects/library_animation_assets.gd")
const ActorTexture = preload("res://scripts/objects/library_actor_texture.gd")
const Locomotion = preload("res://scripts/player_walk_art.gd")
const Metrics = preload("res://scripts/player_metrics.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("LIBRARY_ANIMATION " + message)

func connected_neck(image: Image, bounds: Rect2i) -> bool:
	var previous := PackedByteArray()
	for y in range(bounds.position.y + roundi(bounds.size.y * 0.27), bounds.position.y + roundi(bounds.size.y * 0.49)):
		var occupied := PackedByteArray()
		var overlap := 0
		for x in range(bounds.position.x, bounds.end.x):
			var solid := image.get_pixel(x, y).a >= 0.5
			occupied.append(1 if solid else 0)
			if solid and not previous.is_empty() and previous[x - bounds.position.x] == 1:
				overlap += 1
		if not previous.is_empty() and overlap < 8:
			return false
		previous = occupied
	return true

func side_crown_width(image: Image) -> int:
	var left := image.get_width()
	var right := -1
	# Crown and hair of the registered 120x160 side poses.
	for y in range(25, 58):
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.5:
				left = mini(left, x)
				right = maxi(right, x)
	return right - left + 1

func run() -> void:
	var state: Node = root.get_node("State")
	var before := JSON.stringify(state.d)
	var assets := Assets.new()
	check(assets.ensure_loaded(), "complete generated family activates atomically")
	if not assets.ready:
		quit(1)
		return
	check(Locomotion.frame_at(49.99) == 0 and Locomotion.frame_at(50) == 1
		and Locomotion.frame_at(799.99) == 15 and Locomotion.frame_at(800) == 0, "side gait advances every 50 ms and loops in 800 ms")
	var original_sheet := Image.load_from_file(Locomotion.WALK_PATH)
	for row in Locomotion.WALK_DIRECTIONS.size():
		var direction: String = Locomotion.WALK_DIRECTIONS[row]
		var frame_count := Locomotion.WALK_FRAMES
		var frame_ms := Locomotion.CYCLE_MS / frame_count
		var idle_image: Image = assets.idles[direction].get_image()
		var hashes := {}
		var head_tops: Array[int] = []
		check(assets.walks[direction].size() == frame_count, "complete frame count " + direction)
		for index in frame_count:
			var texture: Texture2D = assets.walks[direction][index]
			var image := texture.get_image()
			var bounds := image.get_used_rect()
			head_tops.append(bounds.position.y)
			check(image.get_size() == Locomotion.WALK_CELL, "walk uses the registered player frame")
			check(bounds.end.y >= Locomotion.WALK_CELL.y - 13 and bounds.end.y <= Locomotion.WALK_CELL.y, "soles stay in the registered floor band")
			check(bounds.position.x > 0 and bounds.end.x < Locomotion.WALK_CELL.x and bounds.position.y > 4, "complete silhouette has transparent margin")
			check(connected_neck(image, bounds), "connected head and shoulders in each complete pose")
			if direction == "side":
				check(side_crown_width(image) <= side_crown_width(idle_image), "side crown stays within the standing width")
			var colors := {}
			for y in range(bounds.position.y, bounds.end.y):
				for x in range(bounds.position.x, bounds.end.x):
					var pixel := image.get_pixel(x, y)
					if pixel.a == 0:
						continue
					colors[pixel.to_rgba32() >> 8] = true
			check(not image.is_compressed() and image.get_format() == Image.FORMAT_RGBA8
				and image.get_data() == original_sheet.get_region(Locomotion.walk_region(row, index)).get_data() and colors.size() > 32,
				"the walk frame retains the exact RGBA8 pixels of the approved atlas")
			hashes[image.get_data().hex_encode().sha256_text()] = true
			check(assets.actor(direction, false, (index + .5) * frame_ms, true).texture == texture, "clock selects consecutive full drawings")
		check(hashes.size() == frame_count, "all walking frames are distinct " + direction)
		check(head_tops.max() - head_tops.min() <= 12, "head height stays stable through both steps " + direction)
		check(assets.actor(direction, false, Locomotion.CYCLE_MS, true).texture == assets.walks[direction][0], "cycle wraps after both steps at the in-game cadence")
		check(assets.actor(direction, false, 473, false).texture == assets.idles[direction], "stopping selects the standing pose")
		check(idle_image.get_data() == original_sheet.get_region(Locomotion.walk_region(row, Locomotion.WALK_FRAMES)).get_data(), "idle uses its own approved unaltered artwork")
		check(not hashes.has(idle_image.get_data().hex_encode().sha256_text()), "idle uses a separate static image from the walk")
	var left := assets.actor("left", false, Locomotion.CYCLE_MS / Locomotion.WALK_FRAMES * 1.5, true)
	check(left.flip_h and left.texture == assets.walks.side[1], "left mirrors the same complete side drawing")
	var left_idle := assets.actor("left", false, 0, false)
	check(left_idle.flip_h and left_idle.texture == assets.idles.side, "left mirrors the corresponding stationary drawing")
	check(assets.book.get_size()==Vector2(768,640),"book atlas has sixteen complete cells")
	check(assets.book_source(15)==Rect2(576,480,192,160),"last page-turn frame has an exact atlas boundary")
	var canvas := Node2D.new()
	root.add_child(canvas)
	canvas.position = Vector2(0.37, 1.25)
	canvas.scale = Vector2.ONE * 0.85
	var transform := canvas.get_global_transform_with_canvas()
	for phase in [0.13, 0.37, 0.63, 0.87]:
		var at := Vector2(301 + phase, 203 - phase)
		var original := transform * at
		var snapped := transform * ActorTexture.snap_draw_anchor(canvas, at)
		check(snapped.is_equal_approx(original.round()), "actor keeps one texel phase during fractional camera motion")
	canvas.free()
	for ms:int in range(0,1760,5):
		check(Metrics.frame_for_count(ms,8)==Metrics.frame_at(ms),"additional samples retain the original shared stride clock")
	check(JSON.stringify(state.d)==before,"loading and sampling animations never change progress or saves")
	print("LIBRARY_ANIMATION ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
