extends RefCounted
## Runtime-only capability. Never serialize this object into the save dictionary.
## The real world host supplies its rendered Image; the journal retains and checks
## this exact object identity before accepting the capture or writing a photo.
var id: String = ""
var scene: String = "qizhen_lake"
var zone: String = ""
var spot_id: String = ""
var expected_player: Vector2 = Vector2.ZERO
var image: Image = null
var metadata: Dictionary = {}
var supplied: bool = false
var consumed: bool = false
var result: Dictionary = {}

func supply(captured_image: Image, captured_metadata: Dictionary) -> bool:
	if supplied or consumed or captured_image == null or captured_image.is_empty(): return false
	image = captured_image.duplicate()
	metadata = captured_metadata.duplicate(true)
	supplied = true
	return true

func receive_capture(path: String, captured_metadata: Dictionary) -> bool:
	if supplied or consumed or not path.begins_with("user://qizhen_journal/") or path.contains("..") or not FileAccess.file_exists(path): return false
	var loaded: Image = Image.load_from_file(path)
	if not supply(loaded, captured_metadata): return false
	result = {"imagePath":path,"metadata":metadata.duplicate(true)}
	return true

func is_complete() -> bool:
	return supplied and not consumed and image!=null and not image.is_empty()

func fail_from_host(reason: String) -> void:
	if consumed: return
	result = {"error":reason}
	image = null
	metadata.clear()
	supplied = false

func invalidate() -> void:
	consumed = true
	image = null
	metadata.clear()
