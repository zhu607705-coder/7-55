extends SceneTree
var failures:=0
var checks:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("THEATER PREVIEW STORAGE: "+label)
func run()->void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"isolated fixture profile")
	if failures:quit(1);return
	var preview:Control=preload("res://tests/preview_theater.gd").new()
	root.add_child(preview);preview.set_process(false);preview.game.set_process(false);await process_frame
	check(preview._evidence_directory()=="user://theater_review","default diagnostics live in user data, not project source")
	check(preview._write_report("probe.json",{"probe":true}),"default directory is created before optional write")
	check(FileAccess.file_exists("user://theater_review/probe.json"),"diagnostic file exists after successful write")
	# A regular file where a parent directory is expected makes mkdir fail.
	var blocker:=FileAccess.open("user://blocked-output",FileAccess.WRITE);blocker.store_string("fixture");blocker.close()
	preview.evidence_directory_override="user://blocked-output/child"
	check(not preview._write_report("probe.json",{}),"unavailable directory is rejected without a null FileAccess write")
	preview.game._primary();var before:Dictionary=preview.game.state.duplicate(true)
	preview.sample_frames=479;preview.sample_seconds=8.0;preview.sample_fps.assign([60.0]);preview._process(1.0/60.0)
	check(preview.sample_frames==480 and preview.game.screen=="running" and preview.game.state==before,"frame480 diagnostics failure leaves actual game running and unchanged")
	preview._capture_replay()
	check(not preview.sampling and preview.game.screen=="running","unavailable capture path never takes ownership from gameplay")
	# The parent directory exists, but the target is a directory rather than a file.
	preview.evidence_directory_override="user://theater_review"
	DirAccess.make_dir_recursive_absolute("user://theater_review/blocked-file.json")
	check(not preview._write_report("blocked-file.json",{}),"failed FileAccess.open is guarded independently of mkdir")
	preview.queue_free();await process_frame
	print("THEATER_PREVIEW_STORAGE: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
