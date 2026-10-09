extends SceneTree
## Interactive source-checkpoint fixture only. F6 pickup, F7 ready exit,
## F8 cabinet, F9 locked door, F10 390x844 / 1180x812. No scripted user actions.
class InputRouter extends Node:
	var harness: SceneTree
	func _input(event: InputEvent) -> void:harness.handle_input(event)
var state: Node
var shell: Control
var scenario:="pickup"
var serial:=0
var capture_busy:=false
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var router:=InputRouter.new();router.harness=self;root.add_child(router)
	state=root.get_node("State");state.begin_checkpoint("c2-inventory")
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
	await process_frame;await process_frame
	shell._show_world_mobile();shell.world.grab_focus()
	root.title="7:55 · Dorm objects · Source-checkpoint QA"
	state.action_completed.connect(action_done)
	capture.call_deferred("initial")
func handle_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	if event.keycode in [KEY_F6,KEY_F7,KEY_F8,KEY_F9,KEY_F10]:root.set_input_as_handled()
	if event.keycode==KEY_F10:
		root.size=Vector2i(390,844) if root.size.x>500 else Vector2i(1180,812)
		await process_frame;shell._layout();capture.call_deferred("resize");return
	var next: String={KEY_F6:"pickup",KEY_F7:"exit",KEY_F8:"cabinet",KEY_F9:"locked"}.get(event.keycode,"")
	if next.is_empty():return
	scenario=next
	state.begin_checkpoint("c2-inventory" if next in ["pickup","locked"] else "c2-dorm-exit")
	shell._show_world_mobile();shell.world.refresh_world()
	if next!="pickup":
		shell.world.player=Vector2(489,232) if next=="cabinet" else Vector2(480,700)
		shell.world._sync_player();shell.world._update_camera()
	shell.world.grab_focus();capture.call_deferred("fixture_"+next)
func action_done(action: String,_before: Dictionary,after: Dictionary,_result: Dictionary) -> void:
	if not action.begins_with("c2_"):return
	print("DORM_REAL_INPUT ",action," phase=",after.actOne.phase," scene=",after.native.scene)
	capture.call_deferred(action)
func capture(label: String) -> void:
	if capture_busy:return
	capture_busy=true
	await process_frame;await RenderingServer.frame_post_draw
	var dir:=OS.get_environment("DORM_CAPTURE_DIR")
	if dir.is_empty():dir=OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	serial+=1
	var path:=dir+"/%02d_%dx%d_%s_%s.png"%[serial,root.size.x,root.size.y,scenario,label]
	root.get_texture().get_image().save_png(path)
	print("DORM_CAPTURE ",path)
	await create_timer(.65).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path.trim_suffix(".png")+"_settled.png")
	capture_busy=false
