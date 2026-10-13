extends SceneTree
## Automated capture on the existing real desktop. Never a manual-QA claim.
var output := ""
var checks := 0
var failures: Array[String] = []
var captures: Array = []

func _initialize(): call_deferred("run")
func frames(n := 4):
	for i in range(n): await process_frame
func verify(ok: bool, label: String):
	checks += 1
	if not ok: failures.append(label); push_error(label)
func snapshot(name: String, delay_frames := 4):
	await frames(delay_frames)
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	picture.save_png(output.path_join(name + ".png"))
	captures.append({"file":name+".png", "actual_viewport":[root.size.x,root.size.y]})
func click(control: Control):
	var point := control.get_global_transform_with_canvas() * (control.size / 2)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		root.push_input(event)
	await frames()
func refs_for(node: Node, refs: Array[WeakRef]):
	refs.append(weakref(node))
	for child in node.get_children(): refs_for(child,refs)
func run():
	output=OS.get_environment("BUCT_CHANGPING_CAPTURE_DIR")
	if output.is_empty() or not OS.get_cmdline_user_args().has("--fresh"):
		printerr("Capture requires workspace output and --fresh");quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	root.set_meta("entry_arguments_consumed",true)
	var state: Node=root.get_node("State")
	var before: Dictionary=state.d.duplicate(true)
	root.size=Vector2i(1280,720)
	verify(change_scene_to_file("res://scenes/entry.tscn")==OK,"Actual entry loads")
	await snapshot("01-four-entry-chooser")
	await click(current_scene.changping_button)
	var campus=current_scene
	verify(campus.initialized,"Changping initializes through actual button")
	await snapshot("02-south-gate-student")
	var refs: Array[WeakRef]=[];refs_for(campus,refs)
	for item in [["right",KEY_D,Vector2.RIGHT],["left",KEY_A,Vector2.LEFT],["down",KEY_S,Vector2.DOWN],["up",KEY_W,Vector2.UP]]:
		var start := Vector2.ZERO
		for cell in campus.walk_cells:
			var point: Vector2=campus.grid.get_point_position(cell)
			var valid:=true
			for step in range(18):valid=valid and campus.is_walkable(point+item[2]*step)
			if valid:start=point;break
		verify(start!=Vector2.ZERO,"Original paving supports keyboard "+item[0])
		campus.visitor.position=start;campus.current_path.clear();campus.close_info()
		await frames()
		var event:=InputEventKey.new();event.physical_keycode=item[1];event.pressed=true;Input.parse_input_event(event)
		for i in range(8):await physics_frame
		print("CHANGPING_KEY_TRACE ",item[0]," action=",Input.is_action_pressed("buct_changping_walk_"+item[0])," start=",start," actual=",campus.visitor.position," paused=",campus.movement_paused())
		verify((campus.visitor.position-start).dot(item[2])>1,"Actual keyboard moves "+item[0])
		await snapshot("03-walk-"+item[0],0)
		event.pressed=false;Input.parse_input_event(event);await frames()
		verify(not campus.visitor.character_visual.walking,"Release returns directional idle "+item[0])
	root.size=Vector2i(390,844);await frames()
	campus.toggle_overview();await snapshot("04-portrait-complete-map")
	verify(is_equal_approx(campus.camera.zoom.x,campus.camera.zoom.y),"Portrait remains uniformly scaled")
	campus.show_landmark("main_building");await snapshot("05-portrait-first-teaching-info")
	campus.close_info();await click(campus.return_button)
	for ref in refs:verify(ref.get_ref()==null,"First exit releases descendant")
	await snapshot("06-portrait-returned-chooser")
	root.size=Vector2i(667,375);await frames()
	await snapshot("07-landscape-four-entry-chooser")
	await click(current_scene.changping_button);campus=current_scene;refs.clear();refs_for(campus,refs)
	await click(campus.ui_controls.nearby);await snapshot("08-landscape-gate-info")
	campus.close_info();campus.return_to_entry();campus.return_to_entry();await frames(5)
	for ref in refs:verify(ref.get_ref()==null,"Second exit releases descendant")
	verify(state.d==before,"Actual campus entry cycle never changes story state")
	await snapshot("09-second-returned-chooser")
	var report={"scope":"Automated actual desktop GPU capture; two real entry/return cycles, four keyboard directions. Not manual input and not full-story visual certification", "checks":checks,"failures":failures,"captures":captures}
	var file:=FileAccess.open(output.path_join("capture-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close()
	current_scene.queue_free();await frames(6)
	print("CHANGPING_FORMAL_ENTRY_CAPTURE ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
