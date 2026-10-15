extends RefCounted
# Exported textures resolve through .import to .ctex; source PNG files are optional.
# A present source is still verified, including when its imported cache is valid.
static func validate(path: String, expected_sha256: String, expected_size: Vector2i) -> bool:
	return inspect(path,expected_sha256,expected_size).ok

static func inspect(path: String, expected_sha256: String, expected_size: Vector2i) -> Dictionary:
	if expected_size.x<=0 or expected_size.y<=0 or expected_sha256.length()!=64:
		return {"ok":false,"reason":"invalid_registration"}
	if not ResourceLoader.exists(path,"Texture2D"):
		return {"ok":false,"reason":"missing_resource"}
	var resource: Resource=ResourceLoader.load(path,"Texture2D",ResourceLoader.CACHE_MODE_REUSE)
	if not resource is Texture2D:
		return {"ok":false,"reason":"invalid_texture_resource"}
	var texture: Texture2D=resource as Texture2D
	if Vector2i(texture.get_size())!=expected_size:
		return {"ok":false,"reason":"imported_dimensions_mismatch"}
	if FileAccess.file_exists(path) and FileAccess.get_sha256(path)!=expected_sha256:
		return {"ok":false,"reason":"available_source_sha256_mismatch"}
	return {"ok":true,"reason":"validated_source_and_import" if FileAccess.file_exists(path) else "validated_import_without_source"}
