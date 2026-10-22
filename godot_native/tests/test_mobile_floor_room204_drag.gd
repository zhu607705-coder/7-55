extends "res://tests/test_mobile_floor_route.gd"
const Room=preload("res://scripts/games/chapter4_room204_model.gd")
var case_name: String=""
func room_fixture(dimensions: Vector2i,source: Vector2,group_id: String) -> Vector2:
	state.story_reset.emit();state.d=state.initial()
	state.d.native.chapter=4;state.d.native.page="c4_notes";state.d.native.scene="duan_yongping_temporal_maze";state.d.native.mode="light"
	state.d.chapter4.phase="room204_restore";state.d.chapter4.floor="A2";state.d.chapter4.prologueSeen=true
	state.d.chapter4.timeState="1850_evening";state.d.chapter4.mode="light"
	state.d.chapter4.factIds=["misaligned_stair_solved","a3_reference_observed","room204_residual_observed"]
	root.size=dimensions;shell.size=Vector2(dimensions);shell.mobile_world=true;shell.compact_inventory_open=false
	shell.world.world_key="";shell._refresh();await frames(6);shell.world.set_process(false)
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
					valid=valid and not controls.stick_rect.has_point(local) and not controls.interact.has_point(local)
			if valid: found=true;break
		if found: break
	check(found,"legal nearby feet leave source and target visible "+case_name)
	w._sync_player();w.transition_alpha=0;w.queue_redraw();await frames(2)
	return drop
func dragging() -> bool:
	return root.gui_is_dragging() or shell.world.get_viewport().gui_is_dragging()
func run() -> void:
	await setup_main()
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
			check(state.d.chapter4.room204Placements.is_empty(),"held drag cannot commit before release "+case_name)
			mouse(end,false);await frames(4)
			check(not dragging(),"release ends native drag "+case_name)
			check(state.d.chapter4.room204Placements.size()==3,"release commits exactly three authored pieces "+case_name)
			check(actions.slice(action_count).count("c4_group_"+sample.group)==1,"release dispatches actual group exactly once "+case_name)
			check(w.player==position and w._floor_route.is_empty(),"drag leaves feet unchanged and never starts floor walk "+case_name)
	await finish("MOBILE_FLOOR_ROOM204_DRAG")
