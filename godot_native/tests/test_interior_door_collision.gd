extends SceneTree
## Declared entrance fixtures exercise the live renderer/body/input. The existing
## routed library entry test separately earns the introduction and record by UI.
const Metrics=preload("res://scripts/player_metrics.gd")
const Door=preload("res://scripts/presentation/library_entrance_door.gd")
var checks:=0
var failures:=0
var state:Node
var world:Control
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("INTERIOR DOOR COLLISION: "+label)
func fixture(scene:String,point:Vector2)->void:
	state.d=state.initial();state.d.native.chapter=2 if scene=="library_interior" else 3
	state.d.native.scene=scene;state.d.native.page="phone_home";state.d.native.mode="light"
	state.d.rpgScene=scene;state.d.runtimeMode="rpg";state.d.actOne.phase="complete"
	state.d.ui.libraryFinalsPhase="library_entered"
	state.d.native.player={"scene":scene,"x":point.x,"y":point.y}
	state.d.native.positions={scene+":":{"x":point.x,"y":point.y}}
	if is_instance_valid(world):world.world_key="";world.scene_id="";world.refresh_world();world._process(0)
func keyboard(code:int,down:bool)->void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
	Input.parse_input_event(event);Input.flush_buffered_events()
func finger(point:Vector2,down:bool)->void:
	var event:=InputEventScreenTouch.new();event.index=5;event.position=point;event.pressed=down
	world._gui_input(event)
func move_input(direction:Vector2,ticks:int,touch:bool)->void:
	var code:int=KEY_W if direction==Vector2.UP else KEY_S
	if touch:
		var anchor:=Vector2(715,641.5 if direction==Vector2.UP else 770)
		var point:Vector2=(anchor+Metrics.FOOT_CENTER_OFFSET-world.camera)*world.zoom+world.size/2
		finger(point,true);finger(point,false)
		for i:int in range(240):
			world._process(.016)
			if world._floor_route.is_empty():break
	else:
		keyboard(code,true)
		for i:int in range(ticks):world._process(.05)
		keyboard(code,false)
	world._process(0)
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated user storage")
	if failures:quit(1);return
	state=root.get_node("State");state.developer_mode=true
	fixture("library_interior",Vector2(715,842))
	world=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world)
	await process_frame;world.set_process(false)
	var source:=FileAccess.get_file_as_string("res://../src/scenes/rpg/LibraryInteriorModel.ts")
	for literal:String in ["x: 750","y: 724","closedLeftX: 697","closedRightX: 803","openOffset: 56","blockerY: 742","sensorHalfWidth: 156","sensorHalfHeight: 142"]:
		check(source.contains(literal),"retained Web source geometry "+literal)
	# Wide landscape can see around the glass assembly. Its original source
	# spawn between the turnstiles must not yield a route through painted outer
	# masonry. This is the exact physical path found by production Web QA.
	for dimensions:Vector2 in [Vector2(824,314),Vector2(960,540),Vector2(390,844)]:
		for spawn_y:float in [792.5,842.0]:
			fixture("library_interior",Vector2(715,spawn_y));world.size=dimensions;world.mobile_exploration=true;world.touch_controls=true;world._update_camera();world.queue_redraw();await process_frame
			check(not world.can_stand(Vector2(452,817.875)) and not world.can_stand(Vector2(1084,817.875)),"painted west/east south-wall bases stop the real foot body "+str(dimensions))
			check(world.can_stand(Vector2(452,760)) and world.can_stand(Vector2(1084,760)) and world.can_stand(Vector2(715,842)),"adjacent clear interior floor and authored central spawn stay open")
			var point:Vector2=(Vector2(715,673.1875)-world.camera)*world.zoom+world.size/2
			finger(point,true);finger(point,false)
			check(world._floor_status=="blocked" and world._floor_route.is_empty(),"wide real floor tap cannot route around closed leaves via either outer wall from "+str(spawn_y))
			var fixed:Vector2=world.player
			for i:int in range(320):world._process(.016)
			check(world.player==fixed and not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"blocked outer-wall route never moves the actor or grants original access")
	for x:float in [452.,1084.]:
		fixture("library_interior",Vector2(x,780));world.grab_focus()
		keyboard(KEY_S,true)
		for i:int in range(20):world._process(.05)
		keyboard(KEY_S,false)
		check(world.player.y>780 and world.player.y<789.1 and world.can_stand(world.player),"actual keyboard body stops against the visible fixed south-wall base "+str(x))
	fixture("library_interior",Vector2(715,842))
	for id:String in ["library_entrance","library_front_desk","library_shelf_755"]:
		var spawn:Dictionary=world.spec.spawns[id]
		check(world.can_stand(Vector2(spawn.x,spawn.y)),"original source checkpoint remains physically open "+id)
	# The retained seat checkpoint (1180,500) already intersects the authored
	# south reading rail. This entrance repair must not silently move that rail
	# or declare the old occupied point walkable; the validated nearby fixture
	# uses (1180,480). Track the independent source mismatch explicitly.
	check(world.can_stand(Vector2(1180,480)),"existing validated reading-area arrival stays physically open")
	var old_seat:=Vector2(1180,500)
	check(not world.can_stand(old_seat) and world.collisions.any(func(r:Dictionary)->bool:return r.id=="reading_south_rail" and Metrics.foot_rect(old_seat).intersects(world._rect(r))),"retained seat spawn mismatch remains attributable to its original rail, not the new wall bases")
	for stand:Vector2 in [Vector2(548,355),Vector2(1255,480),Vector2(700,623),Vector2(827,591)]:
		check(world.can_stand(stand),"measured shelf, bag, catalog and printer operating stands remain open "+str(stand))
	check(state.begin_checkpoint("c2-seat-arrival"),"retained ordinary seat-arrival checkpoint prerequisites")
	state.d.native.player={"scene":"library_interior","x":1180.,"y":500.};state.d.native.positions={"library_interior:":{"x":1180.,"y":500.}}
	world.world_key="";world.scene_id="";world.refresh_world();world._process(0)
	check(world.player!=old_seat and world.can_stand(world.player),"ordinary scene entry resolves occupied source seat point through existing safe-spawn recovery")
	state.developer_mode=false;check(state.save_game(),"ordinary recovered seat position validates for durable save")
	state.d=state.initial();check(state.load_game(),"ordinary recovered seat save restores through production importer")
	world.world_key="";world.refresh_world();world._process(0)
	check(world.can_stand(world.player),"ordinary seat Continue restores an actual open player-body pose")
	var seat_before:Vector2=world.player;var moved:=false
	world.grab_focus()
	for sample:Array in [[KEY_W,Vector2.UP],[KEY_D,Vector2.RIGHT],[KEY_S,Vector2.DOWN],[KEY_A,Vector2.LEFT]]:
		if not world.can_stand(world.player+sample[1]*8.25):continue
		keyboard(sample[0],true);world._process(.05);keyboard(sample[0],false)
		moved=world.player.distance_to(seat_before)>0;break
	check(moved and world.can_stand(world.player),"recovered seat Continue supports real keyboard displacement with the unchanged physical body")
	state.developer_mode=true
	for touch:bool in [false,true]:
		fixture("library_interior",Vector2(715,842));world.mobile_exploration=touch;world.touch_controls=touch
		world.size=Vector2(390,844) if touch else Vector2(960,540)
		world._floor_bounds=Rect2(Vector2.ZERO,world.world_size)
		var original:Array=world.collisions.duplicate(true)
		check(world.can_stand(world.player),"library entrance safe spawn "+str(touch))
		check(not world.library_door.access_granted and world.library_door.progress==0,"unread record keeps physical leaves closed")
		check(not world.can_stand(Vector2(715,710)),"closed left lane blocks actual foot body")
		check(not world.can_stand(Vector2(785,710)),"closed right leaf also blocks its actual foot lane")
		check(not world._floor_segment_clear(Vector2(715,770),Vector2(715,675)),"tap planner cannot route through closed leaf")
		var closed_start:Vector2=world.player
		move_input(Vector2.UP,30,touch)
		if touch:
			check(world.player==closed_start and world._floor_route.is_empty(),"real floor tap cannot plan across unread closed leaves")
			move_input(Vector2.UP,30,false)
		check(world.player.y>=723 and world.player.y<733,"ordinary input stops at visible door base "+str(world.player))
		var record:Dictionary=state.get_targets("library_interior").filter(func(t:Dictionary)->bool:return t.id=="entrance_record")[0]
		check(world._distance(record)<=record.radius,"closed gate leaves record reachable")
		world._try_interact(record);check(state.d.native.page=="library_record","real target opens existing record page")
		state.act("lib_record")
		check(state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"existing controller alone grants record access")
		for i:int in range(10):world._process(.05)
		check(world.library_door.progress==1 and world.can_stand(Vector2(715,710)),"fully open left lane clears actual foot body")
		check(world.can_stand(Vector2(785,710)),"fully open right lane also clears actual foot body")
		var entry_parts:Array[Rect2]=world.library_door.foreground_regions(Rect2(505,672,490,72))
		var actor_frame:Rect2=Metrics.visual_rect(world.player)
		check(not entry_parts.any(func(part:Rect2)->bool:return part.intersects(actor_frame)),"open central passage cannot repaint floor over approaching actor")
		check(entry_parts.any(func(part:Rect2)->bool:return part.has_point(Vector2(530,700))) and entry_parts.any(func(part:Rect2)->bool:return part.has_point(Vector2(970,700))) and entry_parts.any(func(part:Rect2)->bool:return part.has_point(Vector2(750,676))),"source fixed sides and actual upper header remain foreground")
		world.library_door.progress=.5
		check(not world.can_stand(Vector2(715,710)) and world.can_stand(Vector2(750,710)),"partial leaf clearance uses each visible width instead of a whole-door boolean")
		world.library_door.progress=1
		check(world._floor_segment_clear(Vector2(715,740),Vector2(715,675)),"same tap planner accepts visible open passage")
		check(world.collisions==original,"all static furniture, frame and turnstile solids retained")
		move_input(Vector2.UP,10,touch)
		check(world.player.y<700 and world.can_stand(world.player),"ordinary input physically crosses opened door")
		var items:String=JSON.stringify(state.d.items)
		move_input(Vector2.DOWN,18,touch)
		check(world.player.y>760 and world.can_stand(world.player),"return movement crosses same safe door")
		world.library_door.progress=.4
		world.player=Vector2(715,710);world._sync_player();world.library_door.tick(.01,state.d)
		check(world.library_door.progress==1,"occupied valid passage reopens interrupted closure")
		var saved:Dictionary=state.d.duplicate(true);var restored:RefCounted=Door.new();restored.sync(saved)
		check(restored.progress==1 and restored.collision_rects()[0].end.x==694,"ordinary restored actor derives open pose from existing record")
		state.d.native.player={"scene":"library_interior","x":400.0,"y":650.0}
		for i:int in range(20):world.library_door.tick(.05,state.d)
		check(world.library_door.progress==0,"distant actor permits complete closure")
		check(JSON.stringify(state.d.items)==items,"door motion never changes inventory")
		check(not state.d.native.has("libraryDoor") and not state.d.native.has("doorProgress"),"no new saved door authority")
	fixture("theater_interior",Vector2(836,800))
	world._floor_bounds=Rect2(Vector2.ZERO,world.world_size)
	var motion:RefCounted=world.chapter3_layers.doors
	motion.configure("theater_interior");motion.progress=0;motion.visual_progress=0
	check(not world.can_stand(Vector2(836,880)),"closed theater leaves block actual foot base")
	check(not world._floor_segment_clear(Vector2(836,850),Vector2(836,895)),"theater closed leaves also block tap planner")
	motion.progress=.38;motion.visual_progress=(1-cos(PI*.38))/2
	check(world.can_stand(Vector2(836,880)) and not world.can_stand(Vector2(780,880)),"part-open theater center clears while its visible left leaf stays solid")
	motion.progress=0;motion.visual_progress=0
	check(motion.begin_departure(),"runtime-only departure hold belongs to theater door")
	for i:int in range(12):world._process(.05)
	check(motion.passable() and motion.progress==1 and world.can_stand(Vector2(836,895)),"departure opens a complete body-sized passage")
	move_input(Vector2.DOWN,12,false)
	check(world.player.y>890 and world.can_stand(world.player),"real keyboard motion crosses opened theater door")
	check(state.d.native.scene=="theater_interior" and state.d.theaterHunt.phase!="complete","opening a door cannot finish chapter or exit")
	motion.cancel_departure();state.d.native.player={"scene":"theater_interior","x":1100.0,"y":800.0}
	for i:int in range(8):motion.tick(.1,state.d)
	check(not motion.departure_held and motion.progress==0,"cancelled departure returns to ordinary sensor closure")
	fixture("theater_interior",Vector2(836,880))
	check(world.player==Vector2(836,880) and world.chapter3_layers.doors.progress==1,"restored occupied theater door never relocates player")
	fixture("library_interior",Vector2(715,842))
	check(not world.chapter3_layers.doors.departure_held and world._door_collision_rects().size()==4,"scene retirement discards theater hold and restores unread library leaves and fixed source walls")
	world.queue_free();await process_frame
	print("INTERIOR_DOOR_COLLISION: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
