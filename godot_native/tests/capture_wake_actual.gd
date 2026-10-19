extends SceneTree
var shell: Control
var state: Node
var frames_taken: Dictionary={}
var output: String
func _initialize() -> void: run.call_deferred()
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		push_error("Refusing opening capture outside isolated /tmp profile");quit(2);return
	output=OS.get_environment("WAKE_CAPTURE_DIR")
	if output.is_empty(): output="user://wake-actual"
	DirAccess.make_dir_recursive_absolute(output)
	state=root.get_node("State")
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
	state.action_completed.connect(func(id: String,_before: Dictionary,after: Dictionary,_result: Dictionary):
		if id in ["c1_start_alarm","c1_dismiss_alarm","c1_wake","c1_enter_home"]:
			print("ACTUAL_WAKE_ACTION ",JSON.stringify({"id":id,"page":after.native.page,"warned":after.native.get("wake_warned",false),"at_ms":Time.get_ticks_msec()}))
			capture.call_deferred(id))
	print("ACTUAL_WAKE_READY: fresh ordinary controls; no result flags injected")
func _process(_delta: float) -> bool:
	if not is_instance_valid(shell): return false
	var flash: Control=shell.page_body.find_child("WakeFlash",true,false)
	if flash!=null:
		var quarter: int=mini(3,int(floor(flash.elapsed/.105)))
		var id: String="actual-warning-step-"+str(quarter)
		if not frames_taken.has(id):
			frames_taken[id]=true;capture.call_deferred(id)
	return false
func capture(id: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(id+".png"))
