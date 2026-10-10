extends Node
## Real Main + original scanner. Only prerequisites/standing position are seeded.
## Drag the report into the actual front desk, then use its existing stamp button.
## The actual stamp button starts a buffered recording with 0.8s pre-roll.
## This observer never clicks or advances the game. Render times are retained.
var shell: Control
var elapsed: float=0
var recording: bool=false
var frames: Array=[]
var images: Array[Image]=[]
var capture_crop:=Rect2i(0,0,1152,760)
var preroll: Array=[]
var pre_images: Array[Image]=[]
var clock: float=0
var events: Array=[]
var directory: String
var stamp_at: float=-1
var wired_scanner: Control
var checking_saved: bool=false
var capture_enabled: bool=true
var previous_max_fps: int=0
func _ready() -> void:
	get_window().size=Vector2i(1152,760)
	get_window().title="7:55 Library Stamp Review"
	previous_max_fps=Engine.max_fps;Engine.max_fps=30
	directory=ProjectSettings.globalize_path("user://library_stamp_review")
	var mkdir_error: Error=DirAccess.make_dir_recursive_absolute(directory)
	if mkdir_error!=OK:_capture_failed("create output directory",mkdir_error)
	State.developer_mode=true;State.d=State.initial()
	State.d.native.chapter=2;State.d.native.scene="library_interior";State.d.native.page="phone_home";State.d.native.mode="light"
	State.d.actOne.phase="complete";State.d.actOne.movementEnabled=true;State.d.actOne.controlsInstalled=true;State.d.actOne.inventoryRecovered=true
	State.d.ui.libraryFinalsPhase="evidence_gathering"
	State.d.ui.libraryFinalsPuzzle.photoCaptured=true;State.d.ui.libraryFinalsPuzzle.photoDimmed=true;State.d.native.lib_selected_photo="seat_022_clue"
	State.act("lib_item_report")
	State.d.native.positions={"library_interior:":{"x":334,"y":694}}
	shell=load("res://scenes/main.tscn").instantiate();add_child(shell)
	await get_tree().process_frame;await get_tree().process_frame
	shell._show_world_mobile()
	shell.world.player=Vector2(334,694);shell.world.facing="down";shell.world._sync_player()
	shell.world._update_camera();shell.world.queue_redraw()
	State.action_completed.connect(_action)
	RenderingServer.frame_post_draw.connect(_capture)
	print("LIBRARY REVIEW READY; report earned through controller; frame output ",directory)
func _exit_tree() -> void:
	Engine.max_fps=previous_max_fps
func _capture_failed(operation: String,error: Error) -> void:
	capture_enabled=false;recording=false;images.clear();preroll.clear();pre_images.clear()
	push_error("LIBRARY CAPTURE FAILED: %s (%s); game remains active" % [operation,error_string(error)])
func _action(action: String,_before: Dictionary,_after: Dictionary,result: Dictionary) -> void:
	if action in ["lib_scan","lib_scan_result"]:
		events.append({"action":action,"at":elapsed,"accepted":result.has("game") if action=="lib_scan" else bool(State.d.items.bagNonPersonProof),"facing":shell.world.facing})
		if action=="lib_scan_result":stamp_at=elapsed
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F9 and not recording and capture_enabled:
		_begin_recording()
		print("LIBRARY CAPTURE START")
func _begin_recording() -> void:
	frames=preroll.duplicate(true);images.assign(pre_images);events.clear();elapsed=0;recording=true
	for row: Dictionary in frames:row.at=float(row.at)-clock
	preroll.clear();pre_images.clear()
func _process(delta: float) -> void:
	clock+=delta
	if not capture_enabled:return
	if is_instance_valid(shell) and is_instance_valid(shell.active_game) and wired_scanner!=shell.active_game:
		wired_scanner=shell.active_game
		if wired_scanner.get("stamp") is Button:
			wired_scanner.stamp.button_down.connect(func():
				if capture_enabled and not recording:
					_begin_recording()
					print("LIBRARY CAPTURE START FROM ACTUAL BUTTON")
			)
	if not recording:return
	elapsed+=delta
	if elapsed>=3.0:
		recording=false
		var meta: Dictionary={"source":"Real Main, physical mouse/keyboard; seeded photo prerequisites and counter position; original lib_item_report earned report; no result injection","width":capture_crop.size.x,"height":capture_crop.size.y,"source_width":get_viewport().size.x,"source_height":get_viewport().size.y,"crop":[capture_crop.position.x,capture_crop.position.y,capture_crop.size.x,capture_crop.size.y],"duration":elapsed,"stamp_at":stamp_at,"frames":frames,"events":events,"final_facing":shell.world.facing,"report_present":State.d.items.itemRecognitionReport,"proof_present":State.d.items.bagNonPersonProof}
		for index: int in range(images.size()):
			frames[index]["file"]="frame_%04d.png"%index
			var save_error: Error=images[index].save_png(directory+"/"+str(frames[index].file))
			if save_error!=OK:_capture_failed("write frame "+str(index),save_error);return
		images.clear()
		var file:=FileAccess.open(directory+"/capture.json",FileAccess.WRITE)
		if file==null:_capture_failed("open metadata",FileAccess.get_open_error());return
		file.store_string(JSON.stringify(meta,"  "));file.flush()
		if file.get_error()!=OK:_capture_failed("write metadata",file.get_error());return
		print("LIBRARY CAPTURE COMPLETE ",directory," frames=",frames.size())
func _capture() -> void:
	if not capture_enabled:return
	if not checking_saved and is_instance_valid(wired_scanner) and wired_scanner.elapsed>=.72:
		var save_error: Error=get_viewport().get_texture().get_image().save_png(directory+"/checking.png")
		if save_error!=OK:_capture_failed("write checking still",save_error);return
		checking_saved=true
	if not recording and (not is_instance_valid(wired_scanner) or stamp_at>=0):return
	var img: Image=get_viewport().get_texture().get_image()
	var row: Dictionary={"at":elapsed if recording else clock,"stamp_ms":shell.world.library_layers.stamp_ms,"facing":shell.world.facing,"scanner":is_instance_valid(shell.active_game),"story":shell.library_story_host.current!=null}
	if not recording:
		preroll.append(row);pre_images.append(img)
		while preroll.size()>24:preroll.pop_front();pre_images.pop_front()
	else:
		images.append(img);frames.append(row)
