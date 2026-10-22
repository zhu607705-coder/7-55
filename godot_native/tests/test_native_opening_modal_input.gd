extends SceneTree
var shell: Control
var state: Node
var checks=[]
func _initialize() -> void: _run.call_deferred()
func frame(count: int=2) -> void:
	for i in count: await process_frame
func check(ok: bool,id: String,detail: Variant=null) -> void: checks.append({"passed":ok,"id":id,"detail":detail})
func key(code: Key) -> void:
	for down in [true,false]:
		var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down; root.push_input(e,true);await frame(1)
func click(at: Vector2) -> void:
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e,true);await frame(1)
func _run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frame(5)
	state.begin_checkpoint("c2-seat-dialogue");shell._refresh();shell.mobile_world=true;shell._layout();await frame(4)
	var host=shell.c3_scene_host;host.set_process(false);shell.world.set_process(false);host.tick(0,true)
	check(host.current!=null and host.current.kind=="opening","issued-opening-ready")
	var before: int=host.current.beat_index
	await key(KEY_ENTER)
	check(host.current.beat_index>before,"opening-enter-advances-without-modal")
	host.tick(0,true);await key(KEY_F10);await frame()
	check(is_instance_valid(shell.modal),"f10-opens-settings-over-opening")
	host.tick(0,true);before=host.current.beat_index
	await key(KEY_ENTER)
	check(host.current.beat_index==before,"modal-enter-does-not-advance-opening",{"before":before,"after":host.current.beat_index})
	host.tick(0,true);await key(KEY_TAB)
	var focus=root.gui_get_focus_owner()
	check(focus==shell.modal or (focus!=null and shell.modal.is_ancestor_of(focus)),"modal-tab-retains-focus-over-opening",str(focus.get_path()) if focus else "none")
	host.tick(0,true);before=host.current.beat_index
	await click(host.opening.advance_button.get_global_rect().get_center())
	check(host.current.beat_index==before,"modal-pointer-does-not-advance-opening")
	await key(KEY_ESCAPE)
	check(not is_instance_valid(shell.modal),"escape-closes-settings-over-opening")
	host.tick(0,true);before=host.current.beat_index
	await key(KEY_ENTER)
	check(host.current.beat_index>before,"ordinary-opening-advance-resumes-after-escape")
	await shell.shutdown();shell.queue_free();await frame()
	var failed=checks.filter(func(x): return not x.passed)
	var out=OS.get_environment("UI_QA_REPORT");if out.is_empty():out="user://native-opening-modal-input.json"
	var f=FileAccess.open(out,FileAccess.WRITE);f.store_string(JSON.stringify(checks,"\t"));f.close()
	print("OPENING_MODAL_QA: ",checks.size()," checks; ",failed.size()," failures")
	for x in failed:print("UI_QA_FAIL: ",JSON.stringify(x))
	quit(1 if failed.size()>0 else 0)
