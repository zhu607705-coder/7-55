extends AbstractUtility
## Bundled source JSON loading has no progression or scene dependencies.
var _cache: Dictionary = {}

func get_utility_name() -> String: return "Content"
func init() -> void: pass

func read(name: String) -> Variant:
	var normalized := name.trim_prefix("src/data/").trim_prefix("data/source/")
	if not normalized.ends_with(".json"): normalized += ".json"
	if not _cache.has(normalized):
		var path := "res://data/source/" + normalized
		_cache[normalized] = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	return _cache[normalized]

func developer_checkpoints() -> Array:
	if not _cache.has("_developer_checkpoints"):
		var file := FileAccess.open("res://data/native/developer_checkpoints.json.gz",FileAccess.READ)
		if not file: return []
		var decoded := file.get_buffer(file.get_length()).decompress_dynamic(4*1024*1024,FileAccess.COMPRESSION_GZIP)
		var parsed = JSON.parse_string(decoded.get_string_from_utf8())
		_cache["_developer_checkpoints"] = parsed.get("checkpoints",[]) if parsed is Dictionary else []
	return _cache["_developer_checkpoints"]
