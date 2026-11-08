extends SceneTree
## Declared entrance fixtures exercise the live renderer/body/input. The existing
## routed library entry test separately earns the introduction and record by UI.
const Metrics=preload("res://scripts/player_metrics.gd")
const Gate=preload("res://scripts/presentation/library_turnstiles.gd")
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
		var anchor:=Vector2(715,695 if direction==Vector2.UP else 848)
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
	fixture("library_interior",Vector2(715,790))
	check(world.player==Vector2(715,842) and not state.d.native.has("lib_admission_recorded") and not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"old vestibule save resumes outside the new gate without earning a record")
	# The legacy and current entry spawns must both be contained by the new
	# gate row and the source plate's south masonry.
	for dimensions:Vector2 in [Vector2(824,314),Vector2(960,540),Vector2(390,844)]:
		for spawn_y:float in [792.5,842.0]:
			fixture("library_interior",Vector2(715,spawn_y));world.size=dimensions;world.mobile_exploration=true;world.touch_controls=true;world._update_camera();world.queue_redraw();await process_frame
			check(not world.can_stand(Vector2(452,817.875)) and not world.can_stand(Vector2(1084,817.875)),"painted west/east south-wall bases stop the real foot body "+str(dimensions))
			check(world.can_stand(Vector2(452,760)) and world.can_stand(Vector2(1084,760)) and world.can_stand(Vector2(715,842)),"adjacent clear interior floor and authored central spawn stay open")
			# The former point now hits the visible entrance reader. Aim at clear
			# floor farther inside, so this still exercises routing across the gate.
			var goal:=Vector2.INF
			for y:int in range(650,701,5):
				for x:int in [715,700,730,680,750,660,770,640,790,620,810,600,830,580,850,560,870,540,890,520,910,500,930,950,970,990]:
					var candidate:=Vector2(x,y)
					if world._floor_empty_destination(candidate) and world.can_stand(candidate-Metrics.FOOT_CENTER_OFFSET):goal=candidate;break
				if goal.is_finite():break
			check(goal.is_finite(),"closed-gate floor tap has a visible empty destination on the interior side")
			if not goal.is_finite():continue
			var point:Vector2=(goal-world.camera)*world.zoom+world.size/2
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
	for side: int in [Gate.INWARD,Gate.OUTWARD]:
		var start := Vector2(620 if side < 0 else 900, 842)
		var goal := Vector2(500 if side < 0 else 1000, start.y)
		fixture("library_interior",start)
		world._floor_bounds=Rect2(Vector2.ZERO,world.world_size)
		world.grab_focus()
		check(world.can_stand(start),"clear floor on the entrance landing "+str([side,start,world.player]))
		check(not world.can_stand(goal),"landing edge blocks foot placement "+str([side,goal]))
		check(not world._floor_segment_clear(start,goal),"landing edge blocks a lateral tap route "+str(side))
		var key := KEY_A if side < 0 else KEY_D
		keyboard(key,true)
		for frame in 24: world._process(.05)
		keyboard(key,false)
		var feet := Metrics.foot_rect(world.player,world.scene_id)
		var aperture: Vector2 = world.library_gate.aperture_x
		check(side*(world.player.x-start.x)>35 and feet.position.x>=aperture.x and feet.end.x<=aperture.y,"real lateral movement stops on the paved landing "+str(side))
	fixture("library_interior",Vector2(715,842))
	for id:String in ["library_entrance","library_front_desk","library_shelf_755"]:
		var spawn:Dictionary=world.spec.spawns[id]
		check(world.can_stand(Vector2(spawn.x,spawn.y)),"original source checkpoint remains physically open "+id)
	check(world.can_stand(Vector2(1180,480)),"existing validated reading-area arrival stays physically open")
	check(world.can_stand(Vector2(1180,500)),"seat checkpoint clears the separately rendered reading rail")
	var old_landing:=Vector2(715,850)
	check(not world.can_stand(old_landing),"the new lower edge exposes an old saved pose at the landing limit")
	state.d.native.positions={"library_interior:":{"x":old_landing.x,"y":old_landing.y}}
	world.world_key="";world.scene_id="";world.refresh_world()
	check(world.player==Vector2(715,847.4375) and world.can_stand(world.player),"loading the old landing pose lifts it by 2.5625px on the same side of the gate")
	# A saved position in the former horizontal-stack aisle now intersects a
	# north-south stack. Exercise actual Continue recovery against that footprint.
	var old_aisle:=Vector2(642,277)
	check(not world.can_stand(old_aisle),"former horizontal aisle is occupied by the restored vertical stack")
	for stand:Vector2 in [Vector2(548,355),Vector2(1255,480),Vector2(700,623),Vector2(827,591)]:
		check(world.can_stand(stand),"measured shelf, bag, catalog and printer operating stands remain open "+str(stand))
	check(state.begin_checkpoint("c2-seat-arrival"),"retained ordinary seat-arrival checkpoint prerequisites")
	state.d.native.player={"scene":"library_interior","x":642.,"y":277.};state.d.native.positions={"library_interior:":{"x":642.,"y":277.}}
	world.world_key="";world.scene_id="";world.refresh_world();world._process(0)
	check(world.player!=old_aisle and world.can_stand(world.player),"ordinary scene entry resolves the former aisle through existing safe-spawn recovery")
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
	for touch: bool in [false,true]:
		fixture("library_interior", Vector2(715,842))
		world.mobile_exploration=touch;world.touch_controls=touch
		world.size=Vector2(390,844) if touch else Vector2(960,540)
		world._update_camera()
		world._floor_bounds=Rect2(Vector2.ZERO,world.world_size)
		var gate = world.library_gate
		var closed_leaves: Array = gate.snapshot().leafRects
		for index in gate.lanes.size():
			for side in 2:
				var leaf: Rect2 = closed_leaves[index * 2 + side]
				var cabinet: Rect2 = gate.cabinets[index + side]
				check(is_equal_approx(leaf.get_center().y,cabinet.get_center().y),"each visible hinge sits at the cabinet midpoint")
		var left_axis := Metrics.anchor_from_foot_center(Vector2(715,gate.axis_y))
		var right_axis := Metrics.anchor_from_foot_center(Vector2(785,gate.axis_y))
		var original: Array = world.collisions.duplicate(true)
		check(world.can_stand(world.player),"lower cabinets keep the authored spawn clear")
		check(not gate.arrival_recorded and gate.lanes[0].progress==0 and gate.lanes[1].progress==0,"both lanes idle before entry")
		check(not world.can_stand(left_axis) and not world.can_stand(right_axis),"both closed wing pairs block the actual foot body")
		check(not world._floor_segment_clear(Vector2(715,842),Vector2(715,695)),"closed swing wings block the shared route planner")
		var closed_start: Vector2=world.player
		move_input(Vector2.UP,30,touch)
		if touch:
			check(world.player==closed_start and world._floor_route.is_empty(),"unread lane cannot accept a floor route")
			move_input(Vector2.UP,30,false)
		check(gate.outside(world.player) and world.player.y<closed_start.y,"ordinary input stops outside the physical gate")
		var record: Dictionary=world.targets.filter(func(t:Dictionary)->bool:return t.id=="entrance_record")[0]
		check(world._distance(record)<=record.radius,"closed gate's reader is within reach")
		world._try_interact(record)
		state.act("lib_record")
		check(state.d.native.page=="phone_home" and gate.lanes[0].phase==Gate.Phase.SCANNING,"physical swipe starts before phone confirmation")
		check(not state.d.ui.libraryFinalsPuzzle.entranceRecordRead and not state.d.native.get("lib_admission_recorded",false),"premature confirmation cannot record arrival")
		for frame in 8: world._process(.05)
		check(gate.lanes[0].progress>0 and gate.lanes[0].progress<1 and gate.lanes[0].direction==Gate.INWARD,"inbound wings swing through an intermediate pose")
		for frame in 12: world._process(.05)
		check(gate.lanes[0].progress==1 and world.can_stand(left_axis) and not world.can_stand(right_axis),"only the swiped lane opens")
		check(world._floor_segment_clear(Vector2(715,842),Vector2(715,695)),"opened wing clears the same route planner")
		move_input(Vector2.UP,15,touch)
		check(Metrics.foot_rect(world.player,world.scene_id).end.y<gate.axis_y and world.can_stand(world.player),"ordinary input enters the library through the wing")
		check(state.d.native.get("lib_admission_recorded",false) and not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"crossing issues the unread record")
		state.act("lib_record")
		check(state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"phone acknowledgement follows physical entry")
		for frame in 20: world._process(.05)
		check(gate.lanes[0].progress==0,"lane closes after passage")
		var items: Dictionary=state.d.items.duplicate(true)
		world.player=Vector2(715,728);world._sync_player()
		move_input(Vector2.DOWN,18,false)
		check(gate.outside(world.player) and gate.lanes[0].direction==Gate.OUTWARD,"moving toward the inside sensor opens wings in the exit direction")
		for frame in 20: world._process(.05)
		check(gate.lanes[0].progress==0,"exit also closes after passage")
		world.player=Vector2(785,842);world._sync_player()
		var east: Dictionary=world.targets.filter(func(t:Dictionary)->bool:return t.id=="entrance_record_east")[0]
		world._try_interact(east)
		for frame in 16: world._process(.05)
		check(gate.lanes[1].progress==1 and gate.lanes[0].progress==0,"repeat swipe can select the other lane")
		world.player=right_axis;world._sync_player()
		for frame in 65: gate.tick(.1,state.d,world.player)
		check(gate.lanes[1].progress==1 and world.can_stand(world.player),"safety sensor holds the wings open around a stopped body")
		world.player=Vector2(785,842);world._sync_player()
		for frame in 12: gate.tick(.1,state.d,world.player)
		check(gate.lanes[1].progress==0,"occupied lane closes once the body clears")
		world._try_interact(east)
		for frame in 65: gate.tick(.1,state.d,world.player)
		check(gate.lanes[1].progress==0,"an unused swipe times out and closes")
		var restored := Gate.new()
		restored.sync(state.d.duplicate(true))
		var safe := restored.restore_anchor(right_axis, Vector2(715,842))
		check(restored.lanes[1].progress==0 and safe!=right_axis and restored.outside(safe),"a saved pose at the wing reloads clear of a closed lane")
		check(world.collisions==original and state.d.items==items,"motion leaves cabinet solids, inventory and story authority unchanged")
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
	var landing:=Metrics.anchor_from_foot_center(Vector2(836,929))
	check(motion.passable() and motion.progress==1 and world.can_stand(landing),"departure opens a complete body-sized passage up to the original ground edge")
	move_input(Vector2.DOWN,12,false)
	check(world.player.y>890 and world.can_stand(world.player),"real keyboard motion crosses opened theater door")
	check(state.d.native.scene=="theater_interior" and state.d.theaterHunt.phase!="complete","opening a door cannot finish chapter or exit")
	motion.cancel_departure();state.d.native.player={"scene":"theater_interior","x":1100.0,"y":800.0}
	for i:int in range(8):motion.tick(.1,state.d)
	check(not motion.departure_held and motion.progress==0,"cancelled departure returns to ordinary sensor closure")
	fixture("theater_interior",Vector2(836,880))
	check(world.player==Vector2(836,880) and world.chapter3_layers.doors.progress==1,"restored occupied theater door never relocates player")
	fixture("library_interior",Vector2(715,842))
	var gate = world.library_gate
	check(not world.chapter3_layers.doors.departure_held and world._door_collision_rects().size()==gate.fixed_collision_rects.size()+gate.guardrails.size()+4,"scene retirement restores all library barriers")
	world.queue_free();await process_frame
	print("INTERIOR_DOOR_COLLISION: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
