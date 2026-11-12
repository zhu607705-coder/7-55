extends SceneTree
## Registers whole drawings from the reviewed walk previews, with one transform per row.
const Assets = preload("res://scripts/objects/library_animation_assets.gd")
const Metrics = preload("res://scripts/player_metrics.gd")
const SOURCE_ROOT := "res://art_source/library_animation_20261105/originals/"
const SIDE_SOURCE := SOURCE_ROOT + "walk_8_side_20261111.png"
const VERTICAL_SOURCE := SOURCE_ROOT + "walk_8_vertical_20261111.png"
const BACKGROUND_ALPHA := 64
const ALIGNMENT_ALPHA := 128
const TARGET_HEIGHT := 132.0

static func source_path(direction: String) -> String:
	return SIDE_SOURCE if direction == "side" else VERTICAL_SOURCE

static func clear_background(cell: Image, threshold: int) -> Image:
	var rgba := cell.get_data()
	for pixel in range(0, rgba.size(), 4):
		if rgba[pixel + 3] < threshold:
			rgba.encode_u32(pixel, 0)
	return Image.create_from_data(cell.get_width(), cell.get_height(), false, Image.FORMAT_RGBA8, rgba)

static func median(samples: Array[float]) -> float:
	samples.sort()
	var middle := samples.size() / 2
	return (samples[middle - 1] + samples[middle]) * 0.5

static func read_row(source: Image, row: int, rows: int) -> Array[Dictionary]:
	var poses: Array[Dictionary] = []
	for phase in Assets.WALK_FRAMES:
		var cell := Vector2i(phase, row)
		var grid := Vector2i(Assets.WALK_FRAMES, rows)
		var start := cell * source.get_size() / grid
		var end := (cell + Vector2i.ONE) * source.get_size() / grid
		var region := source.get_region(Rect2i(start, end - start))
		var alignment := clear_background(region, ALIGNMENT_ALPHA)
		var ink := alignment.get_used_rect()
		if ink.size.y < region.get_height() * 0.55 or ink.size.x < 24:
			return []
		var head := alignment.get_region(Rect2i(0, ink.position.y, region.get_width(), roundi(ink.size.y * 0.29))).get_used_rect()
		var waist_y := ink.position.y + roundi(ink.size.y * 0.60)
		var waist := alignment.get_region(Rect2i(0, waist_y - 3, region.get_width(), 7)).get_used_rect()
		var crop := ink.grow(3).intersection(Rect2i(Vector2i.ZERO, region.get_size()))
		poses.append({
			"image": clear_background(region, BACKGROUND_ALPHA).get_region(crop),
			"origin": crop.position,
			"head_x": head.get_center().x,
			"waist_x": waist.get_center().x,
			"floor": ink.end.y,
			"height": ink.size.y,
		})
	return poses

static func build_direction(source: Image, direction: String) -> Array[Image]:
	if source == null or source.is_empty():
		return []
	source.convert(Image.FORMAT_RGBA8)
	var rows := 3 if direction == "side" else 2
	var poses := read_row(source, 1 if direction == "up" else 0, rows)
	if poses.size() != Assets.WALK_FRAMES:
		return []
	var scale_poses := poses.duplicate()
	if direction != "side":
		scale_poses.append_array(read_row(source, 0 if direction == "up" else 1, rows))
	var heights: Array[float] = []
	for pose: Dictionary in scale_poses:
		heights.append(pose.height)
	var floor_samples: Array[float] = []
	var head_offsets: Array[float] = []
	var head_sum := 0.0
	var head_trend := 0.0
	var phase_variance := 0.0
	var middle_phase := (Assets.WALK_FRAMES - 1) * 0.5
	for phase in poses.size():
		var pose := poses[phase]
		var centered_phase := phase - middle_phase
		head_sum += pose.head_x
		head_trend += centered_phase * pose.head_x
		phase_variance += centered_phase * centered_phase
		floor_samples.append(pose.floor)
		head_offsets.append(pose.head_x - pose.waist_x)
	# The rows drift across the source grid. Fit the spacing once so swinging arms
	# do not move the frame anchor, and preserve the remaining motion in the art.
	var scale := TARGET_HEIGHT / median(heights)
	var x_at_middle := head_sum / poses.size() - median(head_offsets)
	var x_per_phase := head_trend / phase_variance
	var floor_y := median(floor_samples)
	var center_x := Assets.WALK_CELL.x / 2
	var body_width := floori(Metrics.UPPER_BODY_HALF_WIDTH * Assets.WALK_CELL.x / Metrics.FRAME.x / Metrics.DISPLAY_SCALE)
	var body_end_y := roundi(104 * Assets.WALK_CELL.x / Metrics.FRAME.x)
	var body_left := Assets.WALK_CELL.x
	var body_right := 0
	var lowest_pixel := 0
	var offsets: Array[Vector2i] = []
	for phase in poses.size():
		var pose := poses[phase]
		var cropped: Image = pose.image
		var scaled_size := Vector2i((Vector2(cropped.get_size()) * scale).round())
		cropped.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_NEAREST)
		var grid_x := x_at_middle + (phase - middle_phase) * x_per_phase
		var offset := Vector2i(
			roundi(center_x - (grid_x - pose.origin.x) * scale),
			roundi(Assets.WALK_CELL.y - 1 - (floor_y - pose.origin.y) * scale))
		offsets.append(offset)
		lowest_pixel = maxi(lowest_pixel, offset.y + cropped.get_used_rect().end.y)
		var torso_end := clampi(body_end_y - offset.y, 1, cropped.get_height())
		var torso := cropped.get_region(Rect2i(0, 0, cropped.get_width(), torso_end)).get_used_rect()
		body_left = mini(body_left, offset.x + torso.position.x)
		body_right = maxi(body_right, offset.x + torso.end.x)
	var left_limit := center_x - body_width - body_left
	var right_limit := center_x + body_width - body_right
	if left_limit > right_limit:
		return []
	# Apply any clearance adjustment to the entire direction, never to one frame.
	var correction := Vector2i(clampi(0, left_limit, right_limit), mini(0, Assets.WALK_CELL.y - 1 - lowest_pixel))
	var frames: Array[Image] = []
	var frame_rect := Rect2i(Vector2i.ZERO, Assets.WALK_CELL)
	for phase in poses.size():
		var cropped: Image = poses[phase].image
		var ink := cropped.get_used_rect()
		var offset := offsets[phase] + correction + ink.position
		if not frame_rect.encloses(Rect2i(offset, ink.size)):
			return []
		var frame := Image.create_empty(Assets.WALK_CELL.x, Assets.WALK_CELL.y, false, Image.FORMAT_RGBA8)
		frame.blit_rect(cropped, ink, offset)
		frames.append(frame)
	return frames

func _initialize() -> void:
	var size := Assets.atlas_size()
	var atlas := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var frame_rect := Rect2i(Vector2i.ZERO, Assets.WALK_CELL)
	for row in Assets.WALK_DIRECTIONS.size():
		var direction: String = Assets.WALK_DIRECTIONS[row]
		var frames := build_direction(Image.load_from_file(source_path(direction)), direction)
		if frames.size() != Assets.WALK_FRAMES:
			push_error("Incomplete full-body walk cycle: " + direction)
			quit(1)
			return
		for index in frames.size():
			atlas.blit_rect(frames[index], frame_rect, Assets.walk_region(row, index).position)
	var result := atlas.save_png(Assets.WALK_PATH)
	if result != OK:
		push_error("Could not write the full-body walk sheet")
	else:
		print("Registered ", Assets.WALK_FRAMES * Assets.WALK_DIRECTIONS.size(), " complete poses")
	quit(result)
