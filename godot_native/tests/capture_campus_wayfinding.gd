extends SceneTree
## Lead-scheduled graphical review only. Source-seeded, not earned walk evidence.
const Wayfinding=preload("res://scripts/ui/campus_wayfinding.gd")
var state: Node
var shell: Control
var failures:=0
func _initialize() -> void: run.call_deferred()
func frames(n:=4) -> void:
	for i in n:await process_frame
func click(control: Control) -> void:
	if control==null:failures+=1;push_error("Capture fixture target missing");return
	var point:=control.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=point;root.push_input(motion)
	for down in [true,false]:
		var e:=InputEventMouseButton.new();e.position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e)
	await frames()
func capture(label: String) -> void:
	shell.world.transition_alpha=0;shell.world.subtitle="";shell.world.subtitle_left=0;shell.world.queue_redraw()
	shell.toast.text="";shell.toast_time=0;shell.toast.hide()
	await frames(8);await RenderingServer.frame_post_draw
	var output:=OS.get_environment("CAMPUS_CAPTURE_DIR")
	if output.is_empty():output=ProjectSettings.globalize_path("res://.screenshots/campus-wayfinding")
	DirAccess.make_dir_recursive_absolute(output)
	var path:=output+"/"+label+".png"
	root.get_texture().get_image().save_png(path);print("CAMPUS_CAPTURE ",path)
func run() -> void:
	if DisplayServer.get_name()=="headless":push_error("Capture needs the lead's GUI handoff");quit(2);return
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	DisplayServer.window_set_title("7:55 · Campus identity review · source fixture")
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(1280,720)]:
		DisplayServer.window_set_size(dimensions);root.size=dimensions;shell.size=Vector2(dimensions)
		state.begin_checkpoint("c2-library-gate");state.d.native.page="library_app";state.d.currentScene="library";state.d.networkMode="campus_wifi"
		shell.mobile_world=dimensions.x<1100;shell.compact_inventory_open=false;shell._refresh();await frames(8)
		shell.world.set_process(false);shell.world.player=Wayfinding.LIBRARY_GATE;shell.world._sync_player();shell.world._update_camera()
		await capture(str(dimensions.x)+"x"+str(dimensions.y)+"-library-facade")
		if OS.get_environment("CAMPUS_CAPTURE_HOLD")=="1":
			shell.world.set_process(true)
			print("CAMPUS_MANUAL_READY: source-seeded library gate; not earned progress")
			return
		shell.mobile_world=false;shell.phone_builder.native_library.local_page="seat";shell.phone_builder.native_library.selected_library="基础馆";shell._refresh()
		await create_timer(1.65).timeout;await frames()
		await capture(str(dimensions.x)+"x"+str(dimensions.y)+"-reservation-link")
		if OS.get_environment("CAMPUS_CAPTURE_HOLD")=="phone":
			print("CAMPUS_PHONE_READY: source-seeded reservation; manual optional open and Back")
			return
		await click(shell.find_child("LibraryBuildingLocationLink",true,false));await frames()
		await capture(str(dimensions.x)+"x"+str(dimensions.y)+"-building-map")
		var scroll:ScrollContainer=shell.find_child("LibraryLocationScroll",true,false)
		if scroll!=null:scroll.scroll_vertical=100;await frames();await capture(str(dimensions.x)+"x"+str(dimensions.y)+"-tower-reference")
		var location:Control=shell.find_child("LibraryBuildingLocation",true,false)
		if location==null:failures+=1;push_error("Location view missing after reservation input");continue
		await click(location.find_child("PhoneNav_back",true,false));await frames()
		await capture(str(dimensions.x)+"x"+str(dimensions.y)+"-reservation-return")
	await shell.shutdown();shell.queue_free();await frames()
	print("Campus fixture capture complete; failures=",failures,". Not earned traversal or physical-device proof.");quit(1 if failures else 0)
