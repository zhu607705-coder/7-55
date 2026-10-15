extends RefCounted
## Source check shared by the two native4x owners. Exported PCKs normally retain
## only the imported texture, so verify its actual decoded pixels in every build.
## If the original PNG is present, its pinned file hash remains mandatory too.
const SOURCE_PATH := "res://campuses/buct_changping/assets/approved-changping.png"
const SOURCE_SHA256 := "f92a8de6ef703bab4b2e471a49acc082dd4d128d264d99d3ed1818fdb0c93707"
const SOURCE_RGBA_SHA256 := "2b30e419d0c58bfcac911af822bb3d08c2c007baadbf177eeda5baa39041c989"
const SOURCE_SIZE := Vector2i(950, 1656)

static func matches(source: Variant) -> bool:
	if not source is Texture2D:
		return false
	if source.resource_path != SOURCE_PATH or source.get_size() != Vector2(SOURCE_SIZE):
		return false
	if FileAccess.file_exists(SOURCE_PATH) and FileAccess.get_sha256(SOURCE_PATH) != SOURCE_SHA256:
		return false
	return image_matches(source.get_image())

static func image_matches(source: Image) -> bool:
	if source == null or source.is_empty() or source.get_size() != SOURCE_SIZE:
		return false
	# Never mutate an image shared by another renderer or resource consumer.
	var pixels: Image = source.duplicate()
	if pixels.is_compressed() and pixels.decompress() != OK:
		return false
	pixels.clear_mipmaps()
	pixels.convert(Image.FORMAT_RGBA8)
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return false
	if context.update(pixels.get_data()) != OK:
		return false
	return context.finish().hex_encode() == SOURCE_RGBA_SHA256
