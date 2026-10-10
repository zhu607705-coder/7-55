extends SceneTree
## Detect source/resource drift and pose-data export omissions independently.
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func run() -> void:
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/native_755/provenance.json"))
	check(manifest.sourceFiles.size()==17 and manifest.nativeFiles.size()==120,"complete original-source and native-resource inventory")
	for row: Dictionary in manifest.sourceFiles:
		check(FileAccess.get_sha256("res://../"+row.path)==row.sha256,"original source identity: "+row.path)
	for row: Dictionary in manifest.nativeFiles:
		check(FileAccess.get_sha256("res://"+row.path)==row.sha256,"native asset identity: "+row.path)
	check(FileAccess.get_sha256("res://scripts/games/chase_stunt_model.gd")==manifest.sourceModelSha256,"source chase simulation remains unchanged")
	var presets:=ConfigFile.new()
	check(presets.load("res://export_presets.cfg")==OK,"native export presets are readable")
	for section: String in ["preset.0","preset.1"]:
		check(str(presets.get_value(section,"include_filter","")).split(",").has("*.bin"),"pose binaries are exported for "+section)
		check(str(presets.get_value(section,"exclude_filter","")).contains("tools/*"),"offline source exporters are excluded from runtime")
	print("CHASE_ASSET_PROVENANCE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
