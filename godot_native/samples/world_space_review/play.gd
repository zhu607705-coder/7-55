extends SceneTree
## Actual world, original actors/furniture and geometry. Never uses real saves.
const Body=preload("res://scripts/player_metrics.gd")
var world:Control
var checks:=0
var failures:=0
var invalid_frames:=0
var audit_active:=false
var receipts:Array=[]
func _initialize()->void:run.call_deferred()
func _process(_delta:float)->bool:
	if audit_active and is_instance_valid(world) and not world.can_stand(world.player):invalid_frames+=1
	return false
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("WORLD_SPACE_REVIEW: "+label)
func key(code:Key,pressed:bool)->void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	Input.parse_input_event(event);await process_frame
func touch(point:Vector2)->void:
	var local:Vector2=(point-world.camera)*world.zoom+world.size/2
	var screen:Vector2=world.get_global_transform_with_canvas()*local
	var event:=InputEventScreenTouch.new();event.index=0;event.position=screen;event.pressed=true
	Input.parse_input_event(event);await process_frame
	event=event.duplicate();event.pressed=false;Input.parse_input_event(event);await process_frame
func visible_blocked_point()->Vector2:
	var visible:=Rect2(world.camera-world.size/(2*world.zoom),world.size/world.zoom)
	for y:float in [.2,.35,.5,.65,.75]:
		for x:float in [.1,.25,.4,.6,.75,.9]:
			var point:=visible.position+visible.size*Vector2(x,y)
			if not Rect2(Vector2.ZERO,world.world_size).has_point(point):continue
			if not world.can_stand(point-Body.FOOT_CENTER_OFFSET) and world._pick_target(point).is_empty():return point
	return Vector2.INF
func capture(label:String)->void:
	var output:=OS.get_environment("WORLD_SPACE_CAPTURE_DIR")
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(output);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():printerr("Use samples/world_space_review/run.mjs");quit(2);return
	var output:=OS.get_environment("WORLD_SPACE_CAPTURE_DIR")
	var state:Node=root.get_node("State");state.developer_mode=true;state.begin_checkpoint("c4-755-room204-1850")
	world=load("res://scripts/world.gd").new();world.size=Vector2(960,540)
	var fit:float=minf(root.size.x/960.0,root.size.y/540.0)
	world.scale=Vector2.ONE*fit;world.position=(Vector2(root.size)-world.size*fit)/2
	root.add_child(world)
	var overlay:Control=load("res://samples/world_space_review/overlay.gd").new();overlay.world=world;world.add_child(overlay)
	var cases:Array=[]
	for scene:String in ["dorm_hub","campus_bootstrap","library_interior","canteen_interior","theater_interior","campus_qizhen_loop"]:cases.append({"scene":scene,"label":scene})
	for floor_id:String in ["A1","A2","A3"]:cases.append({"scene":"duan_yongping_temporal_maze","floor":floor_id,"label":floor_id})
	for zone:String in ["dock","open_water","channel","swan_cove"]:cases.append({"scene":"qizhen_lake","zone":zone,"label":"lake_"+zone})
	for row:Dictionary in cases:
		audit_active=false;world.set_process(false);world.capture_mode=true
		state.d.native.scene=row.scene;state.d.rpgCheckpoint="";state.d.native.positions={};state.d.native.mode="light";state.d.actOne.phase="complete"
		if row.has("floor"):state.d.chapter4.floor=row.floor;state.d.chapter4.mode="light"
		if row.has("zone"):state.d.qizhenLake.active=true;state.d.qizhenLake.zone=row.zone;state.d.qizhenLake.vehicle="on_foot" if row.zone=="dock" else "kayak"
		world.scene_id="";world.world_key="";world.refresh_world();world.transition_alpha=0;world.mode_mix=0
		world.zoom=minf(world.size.x/world.world_size.x,world.size.y/world.world_size.y);world.camera=world.world_size/2
		world.queue_redraw();await process_frame;await process_frame
		check(world.can_stand(world.player),str(row.label)+" safe entry")
		await capture(str(row.label)+"_overview")
		world.zoom=1.0 if row.scene!="dorm_hub" else 1.15;world._update_camera();world.capture_mode=false;world.set_process(true)
		root.grab_focus();world.grab_focus();audit_active=true
		if world.kayak==null:
			var start:Vector2=world.player
			var can_move:bool=world._axis_destination(start,Vector2(0,-10)).distance_to(start)>1
			await key(KEY_W,true);await create_timer(.7).timeout;await key(KEY_W,false)
			check(world.can_stand(world.player),str(row.label)+" ordinary keyboard stops legally")
			check(not can_move or world.player.distance_to(start)>1,str(row.label)+" held keyboard really moves when its path is clear")
			var blocked:Vector2=visible_blocked_point()
			if blocked!=Vector2.INF:await touch(blocked);await create_timer(.15).timeout
			check(world.can_stand(world.player) and world._floor_route.is_empty(),str(row.label)+" touch cannot route outside registered ground")
			await key(KEY_S,true);await create_timer(.3).timeout;await key(KEY_S,false)
			check(world.can_stand(world.player),str(row.label)+" can walk away from contact")
			receipts.append({"map":str(row.label),"start":str(start),"final":str(world.player),"ground":world.world_space.snapshot(),"valid":world.can_stand(world.player)})
		else:
			await key(KEY_A,true);await create_timer(.1).timeout;await key(KEY_A,false)
			await key(KEY_D,true);await create_timer(.1).timeout;await key(KEY_D,false)
			check(world.can_stand(world.player),str(row.label)+" ordinary paddle input keeps full hull on water")
			receipts.append({"map":str(row.label),"ground":world.world_space.snapshot(),"valid":world.can_stand(world.player)})
		await capture(str(row.label)+"_contact")
		overlay.hide();world.queue_redraw();await process_frame;await capture(str(row.label)+"_actual");overlay.show();audit_active=false
		world.set_process(false)
	check(invalid_frames==0,"every sampled input frame preserves a legal complete body")
	if not output.is_empty():
		var file:=FileAccess.open(output.path_join("evidence.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"invalidFrames":invalid_frames,"logicalViewport":[960,540],"actualViewport":str(root.size),"save":"isolated developer checkpoint","maps":receipts},"  "));file.close()
	print("WORLD_SPACE_REVIEW: %d checks, %d failures, %d illegal frames"%[checks,failures,invalid_frames]);quit(1 if failures else 0)
