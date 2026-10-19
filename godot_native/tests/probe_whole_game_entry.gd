extends SceneTree
## Restarts an earned formal save through entry.tscn -> ContinueStory -> Main.
## The caller supplies an isolated XDG save; no checkpoint or chapter writes.
## Production host ticks use a test clock; this is not visual/manual playthrough QA.
var failures:=0
var observations:Array=[]
var shell:Control
var state:Node
var scenario:=OS.get_environment("CONTINUITY_SCENARIO")
var stage:=OS.get_environment("CONTINUITY_STAGE")
func _initialize(): run.call_deferred()
func check(ok:bool,label:String):
	observations.append({"ok":ok,"label":label})
	if not ok: failures+=1;push_error("CONTINUITY_ENTRY: "+label)
func frames(count:int=6):
	for i in count:await process_frame
func click(button:Control,touch:bool=false):
	var point:Vector2=button.get_global_transform_with_canvas()*(button.size/2)
	for down in [true,false]:
		if touch:
			var event:=InputEventScreenTouch.new();event.position=point;event.index=7;event.pressed=down;Input.parse_input_event(event);Input.flush_buffered_events()
		else:
			var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event)
	await frames(10)
func stable_facts(s:Dictionary)->Dictionary:
	return {"items":s.items.duplicate(true),"wallet":s.wallet.duplicate(true),"canteen":s.canteenHunt.duplicate(true),"theater":s.theaterHunt.duplicate(true)}
func check_destination(s:Dictionary,label:String):
	if scenario=="escape":
		check(s.native.scene=="campus_bootstrap" and s.canteenHunt.phase=="chase_ready",label+" returns to campus bike task")
	elif scenario=="admission":
		var point:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json")).worlds.theater_interior.spawns.theater_auditorium
		check(s.native.positions.get("theater_interior:",{})=={"x":point.x,"y":point.y},label+" retains accepted auditorium destination")
		check(Vector2(s.native.player.x,s.native.player.y).distance_to(Vector2(point.x,point.y))<.01,label+" retains auditorium player position")
	elif scenario=="theater_intro":
		check(s.native.get("c3_theater_entry_seen",false),label+" retains intro acknowledgement")
	check(not s.native.has("c3_pending_handoff"),label+" has no consumed handoff receipt")
func run():
	state=root.get_node("State")
	check(OS.get_user_data_dir().begins_with("/tmp/"),"formal save is isolated from player data")
	check(FileAccess.file_exists(state.SAVE_PATH) and state.load_game(),"process startup loads actual valid formal save")
	if failures:quit(1);return
	var before:Dictionary=state.d.duplicate(true)
	var facts:Dictionary=stable_facts(before)
	if stage=="reload":check_destination(before,"saved state before entry")
	root.size=Vector2i(390,844) if stage=="reload" else Vector2i(1280,720)
	root.set_meta("entry_arguments_consumed",true)
	change_scene_to_file("res://scenes/entry.tscn")
	await frames()
	check(current_scene.has_node("ContinueStory") or current_scene.story_button!=null,"real entry selector rendered")
	await click(current_scene.story_button,stage=="reload")
	shell=current_scene
	check(shell.get_script().resource_path=="res://scripts/main.gd","ContinueStory routes to real Main")
	if shell.get_script().resource_path!="res://scripts/main.gd":quit(1);return
	check(not state.developer_mode,"formal save mode remains enabled")
	check(stable_facts(state.d)==facts,"entry preserves earned inventory, wallet and chapter facts")
	var host:Control=shell.c3_narrative_host
	host.set_process(false)
	host.tick(0,true)
	var session:RefCounted=state.get_c3_narrative_session()
	if stage=="reload":
		check(session==null and host.current==null,"completed handoff does not replay through compact touch Continue")
		check_destination(state.d,"re-entered Main")
	elif scenario=="escape":
		check(session!=null and session.sequence_id=="canteen_escape","accepted defense resumes escape-to-campus narrative")
	elif scenario=="admission":
		check(session!=null and session.sequence_id=="theater_admission","accepted ticket resumes auditorium handoff")
	elif scenario=="theater_intro":
		check(session!=null and session.sequence_id=="theater_entry","unfinished theater introduction resumes")
	elif scenario=="theater_done":
		check(session==null,"completed theater introduction does not replay on reload")
	elif scenario=="lake_approach":
		check(session!=null and session.sequence_id=="qizhen_approach","theater exit resumes authored lake approach")
	if stage in ["interrupt","complete"] and session!=null:
		check(host.current==session and session.status=="playing","production narrative host owns restored session")
		var elapsed:float=session.elapsed_ms
		host.tick(100,false)
		check(session.elapsed_ms==elapsed,"unfocused production host does not finish handoff")
		for i in range(8):host.tick(100,true)
		check(session.status=="playing","interruption occurs before authored completion")
		if scenario in ["escape","admission"]:check(state.d.native.has("c3_pending_handoff"),"receipt survives partial playback")
		if stage=="interrupt":
			check(state.save_game(),"interrupted host persists through production save API")
		else:
			for i in range(2000):
				if session.status=="consumed":break
				host.tick(100,true)
			check(session.status=="consumed" and host.current==null,"production host consumes completion exactly once")
			check_destination(state.d,"completed handoff")
			var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(state.SAVE_PATH)).state
			check_destination(saved,"automatic save before extra save call")
			check(stable_facts(state.d)==facts,"handoff does not alter earned items, wallet or puzzle facts")
			state.act("c3_story_complete",session)
			check(stable_facts(state.d)==facts,"duplicate completion cannot duplicate rewards or progression")
	var seconds:=float(OS.get_environment("CONTINUITY_SECONDS"))
	if seconds>0: await create_timer(seconds).timeout
	if scenario=="escape" and seconds>0:
		check(state.d.native.scene=="campus_bootstrap" and state.d.canteenHunt.phase=="chase_ready","escape completes into campus bike task")
	if scenario=="admission" and seconds>0:
		check(state.d.theaterHunt.admitted and state.d.native.scene=="theater_interior","admission preserves ticket gate proof")
	var report:Dictionary={"scenario":scenario,"stage":stage,"failures":failures,"checks":observations,"scene":state.d.native.scene,"page":state.d.native.page,"objective":state.objective(),"player":state.d.native.player,"developerMode":state.developer_mode,"automatedControlActivation":true,"testClockForNarrative":true,"notManualFullPlaythrough":true}
	var path:=OS.get_environment("CONTINUITY_REPORT")
	if not path.is_empty():var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	if DisplayServer.get_name()!="headless" and not OS.get_environment("CONTINUITY_IMAGE").is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("CONTINUITY_IMAGE"))
	await shell.shutdown()
	shell.queue_free();await frames()
	print("WHOLE_GAME_ENTRY ",scenario," ",stage," checks=",observations.size()," failures=",failures)
	quit(1 if failures else 0)
