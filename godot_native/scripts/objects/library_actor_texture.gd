extends RefCounted
## Library actor presentation. The texture retains its authored size and alpha.
static func prepare_player(original: Texture2D, jacket_top: int = 54, jacket_bottom: int = 99) -> Texture2D:
	var image := original.get_image()
	if image == null or image.is_empty():
		return original
	if image.is_compressed() and image.decompress() != OK:
		return original
	image.convert(Image.FORMAT_RGBA8)
	var pixels := image.get_data()
	var width := image.get_width()
	# Generated cels alternate between slate gray and navy for the same coat.
	# Use one coat ramp independent of each pose's silhouette. The dark ink,
	# skin, shirt and original alpha keep their own authored values.
	var slate := Color("344452").to_abgr32()
	var blue_shadow := Color("243f5a").to_abgr32()
	var blue_mid := Color("385b79").to_abgr32()
	var bright_blue := Color("547f9d").to_abgr32()
	var muted_light := Color("526b7a").to_abgr32()
	for offset in range(jacket_top * width * 4, mini(jacket_bottom, image.get_height()) * width * 4, 4):
		var color := pixels.decode_u32(offset)
		if color == slate or color == blue_shadow:
			pixels.encode_u32(offset, blue_mid)
		elif color == bright_blue:
			pixels.encode_u32(offset, muted_light)
	return ImageTexture.create_from_image(Image.create_from_data(width, image.get_height(), false, Image.FORMAT_RGBA8, pixels))

static func snap_draw_anchor(canvas: CanvasItem, anchor: Vector2) -> Vector2:
	# The world first rasterizes into a 960 × 540 SubViewport. Keep one
	# nearest-neighbour sample phase at that grid as the camera pans.
	var to_viewport := canvas.get_global_transform_with_canvas()
	return to_viewport.affine_inverse() * (to_viewport * anchor).round()
