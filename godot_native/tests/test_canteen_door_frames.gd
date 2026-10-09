extends SceneTree
## Registered art and stateless sampling. Does not create a second door controller.
const Frames = preload("res://scripts/presentation/c3_door_frames.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CANTEEN DOOR FRAMES: " + label)

func run() -> void:
	_test_sampling()
	if OS.get_environment("CANTEEN_DOOR_FRAMES_LOGIC_ONLY") != "1":
		_test_art()
	print("CANTEEN_DOOR_FRAMES %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _test_sampling() -> void:
	var scale_value := 88.0 / 766.0
	var source_at := Vector2(1305, 900 - 791 * scale_value)
	var registered: Rect2 = Frames.canvas_rect(source_at, scale_value)
	check(Frames.FRAME_COUNT == 8 and Frames.ATLAS_COLUMNS == 4 and Frames.ATLAS_ROWS == 2,
		"eight keyposes occupy four columns and two rows")
	check((registered.position + Frames.SOURCE_OFFSET * scale_value * Frames.CELL_TO_SOURCE_SCALE).is_equal_approx(source_at),
		"original source crop stays at the existing southeast position")
	check(Frames.SOURCE_REGION == Rect2(244, 232, 766, 791), "exact source crop is preserved")
	check(Frames.frame_index(-1, false) == 0 and Frames.frame_index(2, true) == 7, "out-of-range sampling clamps")
	check(Frames.atlas_region(-1) == Frames.atlas_region(0) and Frames.atlas_region(9) == Frames.atlas_region(7),
		"atlas regions clamp without leaving the eight cells")
	var seen: Array[int] = []
	for tick in range(1001):
		var p := tick / 1000.0
		var pose: Dictionary = Frames.sample(p, p >= Frames.VISUAL_CUES[Frames.FIRST_PASSABLE_FRAME], source_at, scale_value)
		check(pose.rect == registered, "fixed registered canvas at " + str(tick))
		check(pose.alpha == 1.0 and pose.rotation == 0.0 and pose.scale == Vector2.ONE * scale_value * Frames.CELL_TO_SOURCE_SCALE,
			"no leaf fade, whole-image turn or nonuniform squash at " + str(tick))
		check(pose == Frames.sample(p, p >= Frames.VISUAL_CUES[Frames.FIRST_PASSABLE_FRAME], source_at, scale_value), "sampling has no mutable state")
		check(pose.closed == (pose.frame == 0), "original source selects the closed endpoint")
		if not seen.has(pose.frame):
			seen.append(pose.frame)
	check(seen == [0, 1, 2, 3, 4, 5, 6, 7], "opening visits all eight authored poses")
	for frame in range(8):
		var p: float = Frames.VISUAL_CUES[frame]
		var pose: Dictionary = Frames.sample(p, p >= Frames.VISUAL_CUES[Frames.FIRST_PASSABLE_FRAME], source_at, scale_value)
		check(pose.frame == frame, "opening or reversing chooses identical pose " + str(frame))
		check(pose.source == Rect2((frame % 4) * 512, floori(frame / 4.0) * 512, 512, 512),
			"exact registered region for pose " + str(frame))

	# Interrupted forward and reverse visual progress can differ from gate progress.
	for visual in range(101):
		for passable: bool in [false, true]:
			var selected: int = Frames.frame_index(visual / 100.0, passable)
			check((float(Frames.CENTERED_CLEAR_WIDTHS[selected]) >= 19.5) == passable,
				"visible clearance follows original gate during interruption/reversal")
	var gate_visual: float = (1.0 - cos(PI * .38)) / 2.0
	check(Frames.frame_index(gate_visual, false) == Frames.FIRST_PASSABLE_FRAME - 1,
		"state before the logical threshold cannot show a foot-passable pose")
	check(Frames.frame_index(gate_visual, true) == Frames.FIRST_PASSABLE_FRAME,
		"first original 38% passable state has a visible 19.5px centered passage")

func _test_art() -> void:
	var source := Image.load_from_file(Frames.SOURCE_ASSET)
	var shell := Image.load_from_file(Frames.FRAME_ASSET)
	var atlas := Image.load_from_file(Frames.LEAVES_ASSET)
	check(source != null and shell != null and atlas != null, "all original and authored assets load")
	if source == null or shell == null or atlas == null:
		return
	check(shell.get_format() == Image.FORMAT_RGBA8 and atlas.get_format() == Image.FORMAT_RGBA8,
		"production art is true RGBA8")
	check(shell.get_size() == Vector2i(766, 791), "stationary frame preserves the exact original crop size")
	check(atlas.get_size() == Vector2i(2048, 1024), "eight equal padded cells retain fixed registration")
	var seen: Array[PackedByteArray] = []
	for frame in range(8):
		var cell := atlas.get_region(Rect2i(Frames.atlas_region(frame)))
		check(not seen.has(cell.get_data()), "independently drawn pose differs: " + str(frame))
		seen.append(cell.get_data())
		var bounds := cell.get_used_rect()
		check(bounds.position.x > 0 and bounds.position.y > 0 and bounds.end.x < 512 and bounds.end.y < 512,
			"leaf silhouette has real transparent margin and unclipped tips: " + str(frame))
		var corridor_left := 98
		var corridor_right := 412
		for y in range(82, 487):
			if cell.get_pixel(256, y).a >= 8.0 / 255.0:
				corridor_left = 256
				corridor_right = 256
				continue
			var left := 256
			var right := 256
			while left > 98 and cell.get_pixel(left - 1, y).a < 8.0 / 255.0:
				left -= 1
			while right < 412 and cell.get_pixel(right, y).a < 8.0 / 255.0:
				right += 1
			corridor_left = maxi(corridor_left, left)
			corridor_right = mini(corridor_right, right)
		var half_clearance := maxf(0, minf(255.5 - corridor_left, corridor_right - 255.5))
		var measured := 2 * half_clearance * 2 * 88.0 / 766.0
		check(is_equal_approx(measured, float(Frames.CENTERED_CLEAR_WIDTHS[frame])),
			"cue clearance is measured from real alpha pixels: " + str(frame))
		check((measured >= 19.5) == (frame >= Frames.FIRST_PASSABLE_FRAME),
			"first foot-passable keypose comes from actual centered clearance")
	# The full-resolution original closed source is selected directly by the renderer.
	# A stationary frame pixel is either transparent at the aperture or exactly source.
	var exact := true
	for y in range(791):
		for x in range(766):
			var pixel := shell.get_pixel(x, y)
			if pixel.a > 0 and pixel != source.get_pixel(x + 244, y + 232):
				exact = false
	check(exact, "stationary frame retains exact original cropped RGBA pixels")
