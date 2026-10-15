extends SceneTree
const Table=preload("res://scenes/objects/room204_table.tscn")
const Preview=preload("res://scripts/ui/room204_drag_preview.gd")
const Room=preload("res://scripts/games/chapter4_room204_model.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var table: Node2D=Table.instantiate();root.add_child(table);table.set_process(false)
	var art: Sprite2D=table.get_node("OriginalAppearance")
	var foot: Rect2=table.footprint_bounds();var pick: PackedVector2Array=table.interaction_polygon();var original:=table.transform
	for reduced: bool in [false,true]:
		for repeat in range(3):
			var preview: Control=Preview.new();preview.configure(art,table.rotation,.9,reduced);root.add_child(preview);preview.set_process(false)
			table.begin_drag(reduced)
			check(art.modulate.a<.5,"Source appearance dims while held")
			check(preview.get_node("OriginalDragLabel").text=="桌椅组 ↑","Original group/orientation label retained")
			check(preview.art.texture==art.texture and preview.art.region_rect==art.region_rect,"Ghost shares exact original texture and trim")
			for i in range(24):
				preview.advance_feedback(1.0/60,Vector2(i*10,100))
				check(table.transform==original and table.footprint_bounds()==foot and table.interaction_polygon()==pick,"Drag never changes root or physical bounds")
			check(is_zero_approx(preview.tilt) if reduced else preview.tilt>0,"Reduced motion is static; ordinary drag leans with actual pointer delta")
			check(preview.visual.scale==Vector2.ONE if reduced else preview.visual.scale.x>1,"Pickup scale respects reduced motion")
			table.finish_drag();preview.retire();check(not preview.visible and not preview.is_processing(),"Retired ghost stops immediately")
			var centre: Vector2=art.position+Vector2(438,178)*art.scale/2
			for i in range(20):
				table.advance_feedback(.016)
				check(table.footprint_bounds()==foot and table.interaction_polygon()==pick,"Return settle does not move colliders/picking")
				check((art.position+Vector2(438,178)*art.scale/2).is_equal_approx(centre),"Settle keeps source art centre")
			check(art.scale==Vector2(.25,.25) and art.position==Vector2(-54.75,-44) and art.modulate==Color.WHITE,"Return reaches exact original appearance")
			preview.free()
		table.begin_drag(reduced);table.finish_drag(false);check(art.modulate==Color.WHITE and table._return_elapsed==1,"Interruption resets immediately")
	table.free()
	var state: Node=root.get_node("State");state.d=state.initial()
	state.d.native.chapter=4;state.d.native.scene="duan_yongping_temporal_maze";state.d.native.mode="light"
	state.d.chapter4.prologueSeen=true;state.d.chapter4.phase="room204_restore";state.d.chapter4.floor="A2";state.d.chapter4.timeState="1850_evening";state.d.chapter4.mode="light"
	state.d.chapter4.factIds=["misaligned_stair_solved","a3_reference_observed","room204_residual_observed"]
	state.d.native.player={"x":94,"y":650}
	var world: Control=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false)
	await process_frame;world.room204_object.sync(state.d,world.scene_id)
	var before:=JSON.stringify(state.d)
	for reduced: bool in [false,true]:
		var ghost: Control=world.room204_object.drag_preview(Vector2(72,710),.9,reduced);root.add_child(ghost);ghost.set_process(false)
		world.furniture_drag_preview=ghost;world._native_table_drag=true
		world._notification(Control.NOTIFICATION_DRAG_END)
		check(not world._native_table_drag and world.furniture_drag_preview==null and not ghost.visible,"Drag end clears same-world owner")
		ghost.free()
	for reason: int in [Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT,Control.NOTIFICATION_RESIZED]:
		var ghost: Control=world.room204_object.drag_preview(Vector2(72,710),.9,false);root.add_child(ghost);ghost.set_process(false)
		world.furniture_drag_preview=ghost;world._native_table_drag=true;world._notification(reason)
		check(not world._native_table_drag and not ghost.visible and not world.room204_object.table._held,"Focus/resize clears held visual and ghost")
		ghost.free()
	world.room204_object.table.begin_drag(false);world.room204_object.table.finish_drag();world.room204_object.table.advance_feedback(.035)
	var rapid: Control=world.room204_object.drag_preview(Vector2(72,710),.9,false)
	check(rapid.art.scale==Vector2(.225,.225),"Rapid re-pick starts from exact art scale, never previous rebound deformation")
	rapid.free();world.room204_object.finish_drag(false)
	check(JSON.stringify(state.d)==before,"Every feedback/cancel path is campaign read-only")
	var ghost: Control=world.room204_object.drag_preview(Vector2(72,710),.9,false);root.add_child(ghost);ghost.set_process(false)
	world.furniture_drag_preview=ghost;world._native_table_drag=true
	var chapter: RefCounted=load("res://scripts/chapters/chapter4.gd").new()
	state.d.native.player={"x":94,"y":650}
	chapter.dispatch(state.d,"c4_group_window_time_marks",{"groupId":"window_time_marks","targetGroupId":"window_time_marks","orientation":"up","drop":[94,609]})
	world.room204_object.sync(state.d,world.scene_id);world._notification(Control.NOTIFICATION_DRAG_END)
	check(state.d.chapter4.room204Placements.size()==3 and not world.room204_object.owns_entity("table:group_table_1"),"Accepted result retires original table immediately through unchanged controller")
	check(not ghost.visible and not world._native_table_drag,"Late drag end after accepted retirement is harmless")
	ghost.free();world.queue_free();await process_frame
	print("ROOM204_DRAG_MOTION ",checks," checks; ",failures," failures");quit(1 if failures else 0)
