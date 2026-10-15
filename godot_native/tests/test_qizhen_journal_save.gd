extends SceneTree
## Runs in an isolated /tmp Godot user-data directory. Synthetic pixels exercise
## save transport only, and are not asserted to be authentic gameplay screenshots.
const Journal=preload("res://scripts/chapters/c3_journal.gd")
var failures: int=0
func check(value: bool, text: String) -> void:
	if not value:
		failures+=1
		push_error(text)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		push_error("Run this persistence regression with HOME/XDG_DATA_HOME under /tmp; refusing to touch formal user saves.")
		quit(1)
		return
	var state: Node=root.get_node("State")
	state.developer_mode=false
	state.d=state.initial()
	state.d.native.chapter=3
	state.d.native.scene="qizhen_lake"
	state.d.native.page="c3_journal_camera"
	state.d.native.player={"x":836,"y":470}
	state.d.rpgScene="qizhen_lake"
	state.d.runtimeMode="rpg"
	state.d.qizhenLake.active=true
	state.d.qizhenLake.phase="lake_exploration"
	state.d.qizhenLake.zone="open_water"
	state.d.qizhenLake.vehicle="kayak"
	state.d.qizhenLake.boardingTutorialCompleted=true
	state.d.networkMode="campus_wifi"
	check(state.validate_snapshot(state.d),"initial lake test snapshot validates")
	var journal: RefCounted=Journal.new()
	var request: Dictionary=journal.request_capture(state.d,"lake_center")
	var path: String="user://qizhen_journal/save_unit_pixels.png"
	DirAccess.make_dir_recursive_absolute("user://qizhen_journal")
	var pixels: Image=Image.create(960,540,false,Image.FORMAT_RGBA8)
	pixels.fill(Color("135b71"))
	pixels.fill_rect(Rect2i(0,0,480,270),Color("d3ac64"))
	pixels.save_png(path)
	request.capture.session.receive_capture(path,{"source":"world_viewport_crop","scene":"qizhen_lake","zone":"open_water","player":{"x":836,"y":470},"speed":0,"roll":0,"heading":0,"capturedAtSeconds":755})
	var result: Dictionary=journal.finish_capture(state.d,request.capture.session)
	check(result.accepted,"capability receipt produces structured photo draft")
	check(journal.validate_journal_snapshot(state.d.qizhenLake.journal),"journal helper accepts structured draft")
	check(state.validate_snapshot(state.d),"shared State accepts nullable dictionary photo and pendingDraft after capture")
	journal.save_draft(state.d,{"titleId":"title_makeshift_boat","statusId":"status_still_afloat"})
	check(state.validate_snapshot(state.d),"shared State accepts authored choices and structured draft")
	var before: String=JSON.stringify(state.d.qizhenLake.journal)
	check(state.save_game(),"native state writes camera save")
	state.d=state.initial()
	check(state.load_game(),"native state reloads structured camera save")
	check(JSON.parse_string(JSON.stringify(state.d.qizhenLake.journal))==JSON.parse_string(before),"reload retains image path recipe tags and complete draft")
	if failures==0:
		journal.publish_main(state.d)
		check(state.save_game(),"published journal writes")
		state.d=state.initial()
		check(state.load_game() and state.d.qizhenLake.journal.status=="open","published journal reloads")
	# Only paths created by this isolated test are removed.
	for created: String in [path,str(result.get("photo",{}).get("nativeImagePath","")),"user://save.json","user://save.previous.json"]:
		if not created.is_empty() and FileAccess.file_exists(created): DirAccess.remove_absolute(created)
	print("Qizhen journal native save failures: ",failures)
	quit(1 if failures else 0)
