extends SceneTree
## Isolated actual-native-shell preview. F6 assembles; A/D paddle; S reverses.
## --capture writes five actual rendered assembly frames and paddle contact phases.
var state: Node
var shell: Control
var capture_dir: String="res://.screenshots/lake_assembly_paddles"
func _initialize() -> void:run.call_deferred()
func frames(n: int=3) -> void:
	for i in n:await process_frame
func reset() -> void:
	state.begin_checkpoint("c3-qizhen-paper");shell._refresh();shell._show_world_mobile();shell._layout()
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):push_error("Preview requires an isolated /tmp XDG_DATA_HOME");quit(2);return
	state=root.get_node("State");state.developer_mode=true
	root.size=Vector2i(1180,812)
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames();reset();await frames()
	print("LAKE PREVIEW: F6 restart four-part assembly; A/D paddle; S+A/D reverse; F12 screenshot. DEV save isolation is active.")
	if "--capture" in OS.get_cmdline_user_args():await capture();return
	var controls:=PreviewControls.new();controls.session=self;root.add_child(controls)
	state.act("c3_lake_combine")
class PreviewControls extends Node:
	var session: SceneTree
	var observed_inputs:=0
	func _process(_delta: float) -> void:
		if session.shell.world.kayak==null:return
		var inputs: Array=session.shell.world.kayak.inputs
		if inputs.size()<observed_inputs:observed_inputs=0
		if inputs.size()>observed_inputs:
			for i in range(observed_inputs,inputs.size()):print("NATIVE MANUAL STROKE: ",JSON.stringify(inputs[i]))
			observed_inputs=inputs.size()
	func _unhandled_input(input: InputEvent) -> void:
		if input is InputEventKey and input.pressed and input.keycode==KEY_F6:
			session.shell._cancel_world_effect();session.reset();session.state.act("c3_lake_combine");get_viewport().set_input_as_handled()
func snap(name: String) -> void:
	await frames(3);await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(capture_dir+"/"+name+".png")
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	state.act("c3_lake_combine");await frames();shell.world_effect.set_process(false)
	for key: Array in [[1350,"assembly-frame"],[2850,"assembly-rope"],[4900,"assembly-clasp"],[5520,"assembly-tug"],[6800,"assembly-stow"]]:
		shell.world_effect.render_pose(key[0]);await snap(key[1])
	shell._cancel_world_effect();await frames();shell.world.set_process(false)
	for key: Array in [["left",false,240,"paddle-left-pull"],["right",false,240,"paddle-right-pull"],["left",true,240,"paddle-left-reverse"],["right",false,430,"paddle-right-exit"]]:
		var model: RefCounted=shell.world.kayak;model.inputs.clear();model.tick=0;model.elapsed=0;model.status="running";model.stroke(key[0],key[1]);model.tick=int(float(key[2])*120/1000);model.elapsed=model.tick/120.0;shell.world.queue_redraw();await snap(key[3])
	print("LAKE CAPTURES: ",ProjectSettings.globalize_path(capture_dir))
	await shell.shutdown();shell.free();await frames();quit()
