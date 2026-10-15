extends SceneTree
## Pure timing/geometry tests. No world startup, imported textures, save writes, or GUI.
const Picker = preload("res://scripts/world_object_picker.gd")
const Frames = preload("res://scripts/presentation/c3_tray_frames.gd")
const OriginalReturn = preload("res://scripts/presentation/c3_return_stack_pose.gd")
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CANTEEN TRAY FRAMES: " + label)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	_test_regions()
	_test_pickup()
	_test_return()
	_test_pure_sampling()
	# Raw-file image checks do not launch the importer or depend on texture caches.
	# A tiny logic-only project may omit assets explicitly; release runs must check them.
	if OS.get_environment("CANTEEN_TRAY_FRAMES_LOGIC_ONLY") != "1":
		_test_atlas()
	print("CANTEEN_TRAY_FRAMES %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _test_regions() -> void:
	check(Frames.FRAME_COUNT == 8 and Frames.ATLAS_COLUMNS == 4 and Frames.ATLAS_ROWS == 2,
		"eight registered poses use four columns and two rows")
	var atlas_rect := Rect2(0, 0, 512, 256)
	for frame in range(Frames.FRAME_COUNT):
		var region: Rect2 = Frames.atlas_region(frame)
		check(region.size == Vector2(128, 128) and atlas_rect.encloses(region),
			"frame region stays within the atlas: " + str(frame))
		check(region.position == Vector2((frame % 4) * 128, floori(frame / 4.0) * 128),
			"row-major frame position: " + str(frame))
	check(Frames.atlas_region(-1) == Frames.atlas_region(0), "negative frame clamps")
	check(Frames.atlas_region(80) == Frames.atlas_region(7), "oversized frame clamps")

func _test_pickup() -> void:
	var start := Vector2(680, 630)
	var hand := Vector2(730, 590)
	check(Frames.pickup_duration_ms(false) == 360.0, "original pickup lasts 360ms")
	check(Frames.pickup_duration_ms(true) == 100.0, "reduced pickup lasts 100ms")
	for reduced: bool in [false, true]:
		var duration: float = Frames.pickup_duration_ms(reduced)
		var first: Dictionary = Frames.pickup_sample(-100.0, start, hand, reduced)
		var middle: Dictionary = Frames.pickup_sample(duration * .5, start, hand, reduced)
		var last: Dictionary = Frames.pickup_sample(duration, start, hand, reduced)
		check(first.position == start and first.frame == 0 and not first.settled,
			"pickup starts at its source with the original tray pixels")
		check(last.position == hand and last.frame == 0 and last.settled,
			"pickup ends exactly at the hand with source frame zero")
		check(first.asset == Frames.SOURCE_ASSET and last.asset == Frames.SOURCE_ASSET
			and first.source == Frames.SOURCE_REGION and last.source == Frames.SOURCE_REGION,
			"endpoint texture is the unchanged original SVG")
		check(middle.position.is_equal_approx(start.lerp(hand, .5) - Vector2(0, 3 if reduced else 18)),
			"original midpoint and reduced flight arc are preserved")
		check(Frames.pickup_sample(INF, start, hand, reduced) == last,
			"old or unstarted pickup clock resolves to the stable carried pose")
		var seen: Array[int] = []
		for tick in range(101):
			var pose: Dictionary = Frames.pickup_sample(duration * tick / 100.0, start, hand, reduced)
			check(pose.size == 24.0 and pose.angle == 0.0 and pose.alpha == 1.0,
				"pickup uses a rigid square canvas and frame-authored tilt")
			check(pose.frame >= 0 and pose.frame < Frames.FRAME_COUNT, "pickup frame remains bounded")
			check(pose.position.x >= start.x and pose.position.x <= hand.x,
				"pickup stays within the original horizontal flight bounds")
			if not seen.has(pose.frame):
				seen.append(pose.frame)
		check(seen == ([0, 1] if reduced else [0, 1, 2, 3, 4]),
			"reduced pickup has one shallow tilt; normal pickup visits the lifted keyposes")
		var cues: Array = Frames.REDUCED_PICKUP_CUES if reduced else Frames.PICKUP_CUES
		var indices: Array = Frames.REDUCED_PICKUP_FRAMES if reduced else Frames.PICKUP_FRAMES
		for i in range(cues.size()):
			var at_cue: float = duration * float(cues[i]) + .000001
			check(Frames.pickup_sample(at_cue, start, hand, reduced).frame == indices[i],
				"pickup frame changes at its authored cue: " + str(i))

func _test_return() -> void:
	var hand := Vector2(1466, 605)
	var anchor := Vector2(1497, 555)
	var height := 28.716
	var contact := anchor + Vector2(0, -height * .67)
	check(Frames.return_duration(false) == .32, "original return lasts 320ms")
	check(Frames.return_duration(true) == .16, "reduced return lasts 160ms")
	for reduced: bool in [false, true]:
		var duration: float = Frames.return_duration(reduced)
		check(duration == OriginalReturn.duration(reduced), "no new return timing authority")
		var first: Dictionary = Frames.return_sample(-1.0, hand, anchor, height, reduced)
		var touch: Dictionary = Frames.return_sample(duration * Frames.CONTACT_T, hand, anchor, height, reduced)
		var impact: Dictionary = Frames.return_sample(duration * Frames.IMPACT_T, hand, anchor, height, reduced)
		var last: Dictionary = Frames.return_sample(duration, hand, anchor, height, reduced)
		check(first.position == hand and first.size == 24.0 and first.frame == 0 and first.alpha == 1.0,
			"first return frame exactly matches the carried source tray")
		check(touch.contact == contact and touch.size == 28.0 and touch.alpha == 1.0,
			"original contact time reaches the fixed stack-top anchor")
		check(impact.position == contact and impact.alpha == 1.0,
			"original impact time lands on an uncompressed stack")
		check(last.position == contact and last.alpha == 0.0 and last.settled and last.frame == 7,
			"endpoint retires the transient top tray without adding a permanent tray")
		check(Frames.return_sample(INF, hand, anchor, height, reduced) == last,
			"terminal return stays retired for a late clock")
		check(not Frames.return_sample(duration - .000001, hand, anchor, height, reduced).settled,
			"return cannot declare its endpoint early")
		var seen: Array[int] = []
		for tick in range(101):
			var pose: Dictionary = Frames.return_sample(duration * tick / 100.0, hand, anchor, height, reduced)
			check(pose.pressure == 0.0 and pose.angle == 0.0,
				"all return poses leave the stack rigid and use authored tray angles")
			check(pose.size >= 24.0 and pose.size <= 28.0 and pose.alpha >= 0.0 and pose.alpha <= 1.0,
				"return canvas and alpha remain within the source bounds")
			check(pose.frame >= 0 and pose.frame < Frames.FRAME_COUNT and pose.contact == contact,
				"return frame and fixed stack-top registration remain bounded")
			if not seen.has(pose.frame):
				seen.append(pose.frame)
		check(seen == ([0, 1, 5, 7] if reduced else [0, 1, 2, 3, 4, 5, 6, 7]),
			"normal return visits every keypose; reduced return uses four restrained poses")
		if reduced:
			check(Frames.return_sample(duration * .70, hand, anchor, height, true).position == contact,
				"reduced return has no rebound")
		for boundary: float in [Frames.CONTACT_T, Frames.IMPACT_T, .75, Frames.ALIGNED_T, 1.0]:
			var before: Dictionary = Frames.return_sample(duration * boundary - .000001, hand, anchor, height, reduced)
			var after: Dictionary = Frames.return_sample(duration * boundary, hand, anchor, height, reduced)
			check(before.position.distance_to(after.position) < .01
				and absf(before.size - after.size) < .01 and absf(before.alpha - after.alpha) < .01,
				"return geometry is continuous at semantic boundary: " + str(boundary))

func _test_pure_sampling() -> void:
	var model := {"carriedTrayIds": ["tray_blue_01"], "returnedTrayIds": [], "cashCents": 75,
		"items": {"cafeteriaWages": false}, "player": Vector2(1466, 608), "anchor": Vector2(1497, 555)}
	var before: String = var_to_str(model)
	var hand: Vector2 = model.player + Vector2(0, -3)
	var a: Dictionary = Frames.return_sample(.10, hand, model.anchor, 28.716, false)
	for age: float in [.30, -.10, 0.0, .32, .12, .10]:
		Frames.return_sample(age, hand, model.anchor, 28.716, false)
		Frames.pickup_sample(age * 1000, model.anchor, hand, false)
	check(Frames.return_sample(.10, hand, model.anchor, 28.716, false) == a,
		"out-of-order samples do not create a second clock or accumulate a count")
	a["frame"] = 123
	a["position"] = Vector2(-500, -500)
	check(Frames.return_sample(.10, hand, model.anchor, 28.716, false).frame != 123,
		"returned presentation dictionaries are independent")
	check(var_to_str(model) == before,
		"sampling cannot alter carried/returned ids, player, wallet, inventory, or rewards")

func _test_atlas() -> void:
	check(FileAccess.file_exists(Frames.ATLAS_ASSET), "registered tray atlas exists")
	if not FileAccess.file_exists(Frames.ATLAS_ASSET):
		return
	var atlas: Image = Image.load_from_file(Frames.ATLAS_ASSET)
	check(atlas != null and not atlas.is_empty(), "registered atlas decodes")
	if atlas == null or atlas.is_empty():
		return
	check(atlas.get_size() == Vector2i(512, 256), "registered atlas has exact 128px cells")
	if atlas.get_size() != Vector2i(512, 256):
		return
	check(atlas.detect_alpha() != Image.ALPHA_NONE, "tray keyposes have real alpha")
	var seen: Array[PackedByteArray] = []
	var picker: RefCounted = Picker.new()
	var texture: Texture2D = ImageTexture.create_from_image(atlas)
	for frame in range(Frames.FRAME_COUNT):
		var image: Image = atlas.get_region(Rect2i(Frames.atlas_region(frame)))
		var pixels: PackedByteArray = image.get_data()
		check(not seen.has(pixels), "separately drawn keypose has distinct pixels: " + str(frame))
		seen.append(pixels)
		var used: Rect2i = image.get_used_rect()
		check(used.has_area() and Rect2i(1, 1, 126, 126).encloses(used),
			"tray is visible and cannot clip against its cell border: " + str(frame))
		var geometry := {"rect":Rect2(-12,-12,24,24), "texture":texture, "source":Frames.atlas_region(frame), "transform":Transform2D(0,Vector2(300,400))}
		check(picker.contains(geometry,Vector2(300,400)),"opaque keypose centre participates in source-region picking: "+str(frame))
		check(not picker.contains(geometry,Vector2(288.5,388.5)),"transparent cell corner cannot block picking: "+str(frame))
