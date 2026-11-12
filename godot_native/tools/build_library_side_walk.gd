extends "res://tools/normalize_library_animation.gd"
## Bake each complete generated pose with the common side walk's proportional
## reduction and foot registration. The generated head and torso move together.
const CELL := Vector2i(120, 160)
const GRID := Vector2i(3, 3)
const TARGET_HEIGHT := 134.0
const SOURCE := "originals/walk_side_full_20261111.png"
const INK := Color("202B35")
const HAIR_SHADOW := Color("44332D")
const HAIR_LIGHT := Color("766E63")
const CHARCOAL := Color("344452")
const BLUE_SHADOW := Color("243F5A")
const BLUE := Color("385B79")
const BLUE_LIGHT := Color("547F9D")

func keep_material_contrast(image: Image) -> void:
	var original := image.duplicate() as Image
	quantize(image)
	var hair_limit := roundi(float(image.get_height()) * 0.36)
	for y in image.get_height():
		for x in image.get_width():
			var color := original.get_pixel(x, y)
			if color.a == 0.0:
				continue
			var value := color.get_luminance()
			var neutral := maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b)) < 0.10
			if y < hair_limit and neutral and value < 0.42:
				# The dark hair in the shared art has warm midtones and a visible
				# highlight instead of sharing all three colors with the jacket.
				var hair := INK
				if value >= 0.30:
					hair = HAIR_LIGHT
				elif value >= 0.235:
					hair = CHARCOAL
				elif value >= 0.15:
					hair = HAIR_SHADOW
				image.set_pixel(x, y, hair)
			elif color.b > color.r + 0.085 and color.g > color.r + 0.035 and value < 0.46:
				var cloth := BLUE_LIGHT
				if value < 0.13:
					cloth = INK
				elif value < 0.205:
					cloth = BLUE_SHADOW
				elif value < 0.365:
					cloth = BLUE
				image.set_pixel(x, y, cloth)

func normalize_pose(source: Image, factor: float) -> Image:
	var bounds := source.get_used_rect()
	var head_height := roundi(bounds.size.y * 0.32)
	var head := source.get_region(Rect2i(bounds.position, Vector2i(bounds.size.x, head_height))).get_used_rect()
	var size := Vector2i((Vector2(bounds.size) * factor).round())
	var crop := source.get_region(bounds)
	crop.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	for y in size.y:
		for x in size.x:
			var color := crop.get_pixel(x, y)
			crop.set_pixel(x, y, Color(color, 1.0) if color.a >= 0.5 else Color.TRANSPARENT)
	crop = clean_cell(crop)
	var ink := crop.get_used_rect()
	var center := head.get_center().x * float(size.x) / bounds.size.x
	var offset := Vector2i(roundi(CELL.x * 0.5 - center), CELL.y - 1 - ink.end.y)
	if not Rect2i(Vector2i.ZERO, CELL).encloses(Rect2i(ink.position + offset, ink.size)):
		push_error("A side walk pose falls outside its cell")
		return null
	keep_material_contrast(crop)
	var frame := Image.create_empty(CELL.x, CELL.y, false, Image.FORMAT_RGBA8)
	frame.blit_rect(crop, ink, ink.position + offset)
	return frame

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Expected the absolute godot_native project directory")
		quit(1)
		return
	var project := args[0]
	var art := project.path_join("art_source/library_animation_20261105")
	var original := Image.load_from_file(art.path_join(SOURCE))
	if original == null or original.is_empty():
		push_error("Missing the newly generated full-body sheet")
		quit(1)
		return
	var direction: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(project.path_join("docs/art/art_direction_v1.json")))
	for hex: String in direction.palette.colors:
		palette.append(Color(hex))
	var poses := cells(original, GRID)
	var heights: Array[int] = []
	for pose: Image in poses:
		var bounds := pose.get_used_rect()
		if bounds.size.y < 80 or bounds.size.x < 20:
			push_error("Missing a full character in the source sheet")
			quit(1)
			return
		heights.append(bounds.size.y)
	heights.sort()
	# A shared factor keeps body proportions and the authored rise and fall.
	var factor := TARGET_HEIGHT / heights[heights.size() / 2]
	var atlas := Image.create_empty(CELL.x * GRID.x, CELL.y * GRID.y, false, Image.FORMAT_RGBA8)
	for index in poses.size():
		var frame := normalize_pose(poses[index], factor)
		if frame == null:
			quit(1)
			return
		var at := Vector2i(index % GRID.x, index / GRID.x) * CELL
		atlas.blit_rect(frame, Rect2i(Vector2i.ZERO, CELL), at)
	var output := project.path_join("assets/native/library_animation_20261105/player_side_walk.png")
	if atlas.save_png(output) != OK:
		push_error("Could not write the full-body side walk sheet")
		quit(1)
		return
	print("Generated eight complete side walk poses and a standing pose from ", SOURCE)
	quit()
