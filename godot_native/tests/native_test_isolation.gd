extends RefCounted
## Preserve Linux's existing /tmp contract; verify the macOS mirror receipt.
static func is_isolated_save() -> bool:
	var actual:=OS.get_user_data_dir().replace("\\","/").simplify_path().trim_suffix("/")
	if OS.get_name()!="macOS":return actual.begins_with("/tmp/")
	var declared:=OS.get_environment("GODOT_TEST_USER_DATA_DIR").replace("\\","/")
	if not declared.is_absolute_path():return false
	declared=declared.simplify_path().trim_suffix("/")
	if declared!=actual:return false
	if ProjectSettings.globalize_path("user://").replace("\\","/").simplify_path().trim_suffix("/")!=declared:return false
	var sandbox:=declared.get_base_dir().get_base_dir()
	if not (sandbox.get_file().begins_with("755-native-check-") or sandbox.get_file().begins_with("755-lake-source-parity-")):return false
	if declared!=sandbox.path_join("data/SevenFiftyFiveNative"):return false
	var support:=OS.get_environment("HOME").path_join("Library/Application Support").simplify_path()
	if sandbox.get_base_dir()!=support:return false
	if ProjectSettings.get_setting("application/config/custom_user_dir_name","")!=sandbox.get_file()+"/data/SevenFiftyFiveNative":return false
	var nonce:=OS.get_environment("GODOT_NATIVE_TEST_NONCE")
	if nonce.length()<16:return false
	var receipt_path:=sandbox.path_join(".native-test-fixture.json")
	if not FileAccess.file_exists(receipt_path):return false
	var receipt=JSON.parse_string(FileAccess.get_file_as_string(receipt_path))
	if not receipt is Dictionary:return false
	return receipt.get("schema")=="native-macos-test-v1" and receipt.get("nonce")==nonce and receipt.get("user_data_dir")==declared and str(receipt.get("mirror_project","")).simplify_path()==ProjectSettings.globalize_path("res://").simplify_path().trim_suffix("/")
