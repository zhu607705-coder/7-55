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
func run()->void:
	check(OS.get_user_data_dir().begins_with("/tmp/"),"isolated export smoke user data")
	check(ResourceLoader.exists("res://scenes/entry.tscn"),"formal entry is included")
	check(Renderer.available(),"production native rescue resource contract in pack")
	check(not FileAccess.file_exists(Renderer.ASSET_ROOT+"generated/rescue_pose_atlas_v01.png") and not FileAccess.file_exists(Renderer.ASSET_ROOT+"generated/rescue_pose_atlas_v02.png"),"source PNG bytes absent; only imported remaps are available")
	var renderer:Control=Renderer.new(); renderer.size=Vector2(960,540); root.add_child(renderer)
	await process_frame
	check(renderer.atlas is Texture2D and renderer.atlas_v2 is Texture2D and renderer.officer_contact is Texture2D,"all three imported pose textures load through PCK remaps")
	check(renderer.atlas_regions.size()==12 and renderer.atlas_v2_regions.size()==8,"JSON regions included by export filter")
	for resource:String in ["res://scripts/media/c3_swan_entrance.gd","res://scripts/media/c3_swan_entrance_session.gd","res://scripts/media/c3_rain_rescue.gd","res://scripts/media/c3_rain_rescue_session.gd"]:
		check(load(resource) is GDScript,"production adapter compiled: "+resource)
	check(root.has_node("State"),"unchanged production State autoload starts from PCK")
	renderer.present(8500); renderer.queue_redraw(); await process_frame
	renderer.queue_free(); await process_frame
	print("PR_SOURCELESS_PCK: %d checks, %d failures"%[checks,failures]); quit(1 if failures else 0)
