extends SceneTree
## Run as an external --script against the production --main-pack, with no
## source project beside the pack. Tests/tools are excluded from release PCK.
const Renderer=preload("res://scripts/media/c3_rain_rescue_native/renderer.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok: failures+=1; push_error("PCK INTEGRATION: "+label)
func _initialize()->void: run.call_deferred()
func isolated_user_data()->bool:
	var actual:=OS.get_user_data_dir().simplify_path().trim_suffix("/")
	if OS.get_name()!="macOS":return actual.begins_with("/tmp/")
	# The exported project retains the disposable mirror's custom user path.
	# Validate its nonce receipt without depending on excluded test resources.
	var expected:=OS.get_environment("GODOT_TEST_USER_DATA_DIR").simplify_path().trim_suffix("/")
	if not expected.is_absolute_path() or actual!=expected:return false
	var sandbox:=expected.get_base_dir().get_base_dir()
	if not sandbox.get_file().begins_with("755-native-check-") or expected!=sandbox.path_join("data/SevenFiftyFiveNative"):return false
	if sandbox.get_base_dir()!=OS.get_environment("HOME").path_join("Library/Application Support").simplify_path():return false
	if ProjectSettings.get_setting("application/config/custom_user_dir_name","")!=sandbox.get_file()+"/data/SevenFiftyFiveNative":return false
	var nonce:=OS.get_environment("GODOT_NATIVE_TEST_NONCE")
	var receipt_path:=sandbox.path_join(".native-test-fixture.json")
	if nonce.length()<16 or not FileAccess.file_exists(receipt_path):return false
	var receipt=JSON.parse_string(FileAccess.get_file_as_string(receipt_path))
	return receipt is Dictionary and receipt.get("schema")=="native-macos-test-v1" and receipt.get("nonce")==nonce and receipt.get("user_data_dir")==actual
func run()->void:
	check(isolated_user_data(),"isolated export smoke user data")
	check(ResourceLoader.exists("res://scenes/entry.tscn"),"formal entry is included")
	check(Renderer.available(),"production native rescue resource contract in pack")
	check(not FileAccess.file_exists(Renderer.ASSET_ROOT+"generated/rescue_pose_atlas_v01.png") and not FileAccess.file_exists(Renderer.ASSET_ROOT+"generated/rescue_pose_atlas_v02.png"),"source PNG bytes absent; only imported remaps are available")
	var renderer:Control=Renderer.new(); renderer.size=Vector2(960,540); root.add_child(renderer)
	await process_frame
	check(renderer.atlas is Texture2D and renderer.atlas_v2 is Texture2D and renderer.officer_contact is Texture2D,"all three imported pose textures load through PCK remaps")
	check(renderer.atlas_regions.size()==12 and renderer.atlas_v2_regions.size()==8,"JSON regions included by export filter")
	for resource:String in ["res://scripts/media/c3_swan_entrance.gd","res://scripts/media/c3_swan_entrance_session.gd","res://scripts/presentation/qizhen_swan_entrance_preview.gd","res://scripts/media/c3_rain_rescue.gd","res://scripts/media/c3_rain_rescue_session.gd"]:
		check(load(resource) is GDScript,"production adapter compiled: "+resource)
	check(root.has_node("State"),"unchanged production State autoload starts from PCK")
	var rig:Node2D=load("res://scenes/objects/kayak_rig.tscn").instantiate();root.add_child(rig)
	rig.configure_view(Vector2(480,270),1,{"heading":-.5,"roll":.2,"speed":120})
	check(rig.get_node("BodyRoll/Hull").texture is Texture2D and rig.get_node("BodyRoll/SeatedPlayer").texture is Texture2D,"native kayak scene imports both source textures from the PCK")
	check(rig.get_node("BodyRoll/LeftPaddle") is Node2D and rig.get_node("BodyRoll/RightPaddle") is Node2D,"native kayak paddle dependencies are included")
	var preview:Control=load("res://scenes/qizhen_swan_entrance_preview.tscn").instantiate();root.add_child(preview);preview.set_process(false)
	await process_frame;await process_frame
	check(is_instance_valid(preview.kayak_rig) and preview.kayak_rig.scene_file_path=="res://scenes/objects/kayak_rig.tscn","packed swan preview draws the current native kayak rig")
	preview.queue_free();rig.queue_free();await process_frame
	renderer.present(8500); renderer.queue_redraw(); await process_frame
	renderer.queue_free(); await process_frame
	print("PR_SOURCELESS_PCK: %d checks, %d failures"%[checks,failures]); quit(1 if failures else 0)
