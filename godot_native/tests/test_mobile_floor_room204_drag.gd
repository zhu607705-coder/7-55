extends "res://tests/test_mobile_floor_route.gd"
const Room=preload("res://scripts/games/chapter4_room204_model.gd")
var case_name: String=""
func room_fixture(dimensions: Vector2i,source: Vector2,group_id: String,allow_stick_overlap:=false) -> Vector2:
	state.story_reset.emit();state.d=state.initial()
	state.d.native.chapter=4;state.d.native.page="c4_notes";state.d.native.scene="duan_yongping_temporal_maze";state.d.native.mode="light"
	state.d.chapter4.phase="room204_restore";state.d.chapter4.floor="A2";state.d.chapter4.prologueSeen=true
	state.d.chapter4.timeState="1850_evening";state.d.chapter4.mode="light"
	state.d.chapter4.factIds=["misaligned_stair_solved","a3_reference_observed","room204_residual_observed"]
	root.size=dimensions;shell.size=Vector2(dimensions);shell.mobile_world=true;shell.compact_inventory_open=false
	shell.world.world_key="";shell._refresh();await frames(6);shell.world.set_process(false)
	if dimensions.y>dimensions.x:
		check(shell.world.size==Vector2(960,540),"portrait device keeps the map's landscape viewport before rotation "+case_name)
		root.size=Vector2i(dimensions.y,dimensions.x);shell.size=Vector2(root.size);shell._layout();await frames(4)
	var w=shell.world
	var target: Dictionary={}
	for group in Room.data().groups:
		if group.id==group_id: target=group
	check(not target.is_empty(),"fixture has real authored drag group "+group_id)
	var bounds: Rect2=Room.rect(target.targetBounds);var drop:=bounds.get_center()
	var found:=false
	# Source-state fixture chooses a legal nearby position; no controller result
	# or completion action is injected, and source furniture stays unchanged.
	for y in range(550,790,4):
		for x in range(40,460,4):
			var point:=Vector2(x,y)
			if not w.can_stand(point) or Room.distance(Metrics.foot_rect(point).get_center(),bounds)>60: continue
			w.player=point;w._update_camera()
			var valid:=true
			for goal in [source,drop]:
				var local: Vector2=(goal-w.camera)*w.zoom+w.size/2
				valid=valid and Rect2(5,50,w.size.x-10,w.size.y-110).has_point(local)
				if w.mobile_exploration:
					var controls: Dictionary=w.mobile_control_metrics()
					valid=valid and controls.gestureArea.has_point(local) and not controls.mode.has_point(local)
					if controls.has("stick") and not allow_stick_overlap:
						var stick:Rect2=controls.stick
						valid=valid and local.distance_to(stick.get_center())>stick.size.x/2
			if valid: found=true;break
		if found: break
	check(found,"legal nearby feet leave source and target visible "+case_name)
	w._sync_player();w.transition_alpha=0;w.queue_redraw();await frames(2)
	return drop
func dragging() -> bool:
	return root.gui_is_dragging() or shell.world.get_viewport().gui_is_dragging()
func test_stick_overlap_recovery() -> void:
	case_name="painted stick overlap and ordinary touch recovery"
	var source:=Vector2(78,618)
	var drop:Vector2=await room_fixture(Vector2i(390,844),source,"window_time_marks",true)
	var w=shell.world
	var local:Vector2=(source-w.camera)*w.zoom+w.size/2
	var stick:Rect2=w.mobile_control_metrics().stick
	check(local.distance_to(stick.get_center())<stick.size.x/2,"authored window furniture starts under the actual painted stick circle")
	var before:=story();var feet:Vector2=w.player;var action_count:=actions.size()
	var colliders:Array=w.collisions.duplicate(true)
	var start:=source_screen(source)
	touch(start,true);finger(start+Vector2(0,-22),Vector2(0,-22));await frames(2)
	check(w.mobile_stick_id==0 and w.touch_axis.length()>0,"touch on covered furniture belongs to visible locomotion stick")
	check(not dragging() and not w._native_table_drag and not w.direct_gestures.has_active(),"touch-emulated mouse cannot also acquire hidden furniture drag")
	finger(source_screen(drop),source_screen(drop)-start-Vector2(0,-22));touch(source_screen(drop),false);await frames(3)
	check(w.mobile_stick_id==-1 and w.touch_axis==Vector2.ZERO and not dragging(),"covered-source release neutralizes only the stick")
	check(story()==before and actions.size()==action_count and state.d.chapter4.room204Placements.is_empty(),"stick release above matching furniture target cannot place pieces or dispatch an object action")
	# The live UI already lets a player reveal covered scene objects without
	# moving the feet or changing puzzle state. Use root touch input, not a
	# direct camera setter, and then complete the original furniture gesture.
	var pan_start:=world_screen(Vector2(720,150))
	touch(pan_start,true);finger(pan_start+Vector2(0,-65),Vector2(0,-65));touch(pan_start+Vector2(0,-65),false);await frames(3)
	local=(source-w.camera)*w.zoom+w.size/2
	stick=w.mobile_control_metrics().stick
	check(w.exploration_safe_rect(true).has_point(local) and local.distance_to(stick.get_center())>stick.size.x/2,"ordinary touch pan exposes the actual furniture outside the painted stick")
	check(story()==before and actions.size()==action_count and w.player==feet and w.collisions==colliders,"camera recovery preserves actual feet, collision geometry and puzzle facts")
	start=source_screen(source);var end:=source_screen(drop)
	touch(start,true);await frames(1)
	check(w.mobile_stick_id==-1 and w.direct_gestures.pointers.get(0,{}).get("role","")=="furniture","exposed source acquires the real furniture touch owner")
	finger(start+Vector2(0,-18),Vector2(0,-18));await frames(2)
	finger(end,end-start-Vector2(0,-18));await frames(2)
	check(dragging() and state.d.chapter4.room204Placements.is_empty(),"ordinary touch moves native furniture preview without committing before release")
	var second:=InputEventScreenTouch.new()
	second.index=1;second.position=world_screen(w.mobile_control_metrics().stick.get_center());second.pressed=true
	event(second);await frames(2)
	check(dragging() and w.mobile_stick_id==-1 and w.touch_axis==Vector2.ZERO,"already-owned native furniture drag prevents a second finger from acquiring the stick")
	second=second.duplicate();second.pressed=false;event(second);await frames(2)
	check(dragging() and state.d.chapter4.room204Placements.is_empty(),"second finger release neither cancels nor commits the first furniture drag")
	touch(end,false);await frames(4)
	check(not dragging() and not w.direct_gestures.has_active(),"furniture release retires both native and scene pointer owners")
	check(state.d.chapter4.room204Placements.size()==3 and actions.slice(action_count).count("c4_group_window_time_marks")==1,"exposed furniture release commits exactly three original pieces through one controller action")
	check(w.player==feet and w._floor_route.is_empty(),"successful recovered drag leaves feet unchanged and starts no walking route")
	touch(end,false);await frames(2)
	check(actions.size()==action_count+1 and state.d.chapter4.room204Placements.size()==3,"duplicate late release cannot submit the recovered furniture a second time")

func run() -> void:
	await setup_main()
	await test_stick_overlap_recovery()
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		for sample in [{"source":Vector2(78,618),"group":"window_time_marks","overlap":"window_time_marks"},{"source":Vector2(351,618),"group":"door_paper_trace","overlap":"central_drag_marks"},{"source":Vector2(273,670),"group":"podium_projection_edge","overlap":"podium_projection_edge"}]:
			case_name=str(dimensions)+" "+str(sample.group)
			var drop: Vector2=await room_fixture(dimensions,sample.source,sample.group)
			var w=shell.world
			var payload: Dictionary=w.chapter4_layers.pick_drag(sample.source,state.d)
			check(payload.get("groupId","")==sample.group,"source art resolves actual group "+case_name)
			var overlap: Dictionary={}
			for group in Room.data().groups:
				if group.id==sample.overlap: overlap=group
			check(Room.rect(overlap.targetBounds).has_point(sample.source),"source pixels overlap authored target bounds "+case_name)
			var picked: Dictionary=w._pick_target(sample.source)
			check(not picked.is_empty(),"real object picker resolves overlapping click target "+case_name)
			var before:=story();var position: Vector2=w.player;var action_count:=actions.size();var feedback_count:=feedback.size()
			var start:=source_screen(sample.source);var end:=source_screen(drop)
			# An actual furniture touch released outside the viewport must retire
			# its scene pointer even when the native drag owner receives the up.
			touch(start,true);await frames(1)
			check(w.direct_gestures.pointers.get(0,{}).get("role","")=="furniture","touch resolves actual furniture ownership "+case_name)
			touch(Vector2(-40,-40),false);await frames(2)
			check(not w.direct_gestures.has_active(),"outside furniture release cannot leave a stale scene pointer "+case_name)
			check(story()==before and actions.size()==action_count,"canceled furniture touch leaves story and actions unchanged "+case_name)
			motion(start);mouse(start,true);await frames(2)
			check(actions.size()==action_count and state.d.chapter4.room204Placements.is_empty(),"mousedown cannot dispatch or place group "+case_name)
			check(feedback.size()==feedback_count,"mousedown belongs to furniture; no overlapping target feedback "+case_name)
			check(story()==before and w._floor_route.is_empty(),"mousedown cannot write story or start route "+case_name)
			var previous:=start
			for index in range(1,9):
				var point:=start.lerp(end,index/8.0)
				# A small initial lift crosses native drag threshold even for a
				# source already within its own target rectangle.
				if index==1: point=start+Vector2(0,-18)
				motion(point,point-previous,MOUSE_BUTTON_MASK_LEFT);previous=point;await frames(1)
			check(dragging(),"held pointer starts actual native furniture drag "+case_name)
			w._process(0)
			check(dragging(),"world process preserves already-owned native furniture drag "+case_name)
			check(state.d.chapter4.room204Placements.is_empty(),"held drag cannot commit before release "+case_name)
			mouse(end,false);await frames(4)
			check(not dragging(),"release ends native drag "+case_name)
			check(state.d.chapter4.room204Placements.size()==3,"release commits exactly three authored pieces "+case_name)
			check(actions.slice(action_count).count("c4_group_"+sample.group)==1,"release dispatches actual group exactly once "+case_name)
			check(w.player==position and w._floor_route.is_empty(),"drag leaves feet unchanged and never starts floor walk "+case_name)
	await finish("MOBILE_FLOOR_ROOM204_DRAG")
