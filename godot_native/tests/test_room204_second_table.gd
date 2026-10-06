extends "res://tests/test_room204_native_object.gd"
const Metrics=preload("res://scripts/player_metrics.gd")
func stand_for(bounds: Rect2) -> Vector2:
	for y in range(535,790,4):
		for x in range(50,475,4):
			var p:=Vector2(x,y)
			if world.can_stand(p) and Room.distance(Metrics.foot_rect(p).get_center(),bounds)<60:return p
	return Vector2.INF
func run() -> void:
	state=root.get_node("State");fixture()
	world=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false);await frames()
	var adapter: Node2D=world.room204_object;adapter.sync(state.d,world.scene_id)
	var second: Node2D=adapter.tables["table:group_table_2"]
	var art: Sprite2D=second.get_node("OriginalAppearance")
	var frame: Dictionary=Room.data().sheets.chapter4_room204_furniture.frames.group_table_2
	check(second.object_id=="group_table_2" and second.position==Vector2(188,710),"Independent second-scene identity and authored root")
	check(art.region_rect==Room.rect(frame.sourceTrim),"Second table uses its exact distinct original trim")
	check(art.position+art.offset*art.scale==(Room.rect(frame.sourceTrim).position-Room.point(frame.pivot))*.25,"Second table preserves its own pivot")
	check(art.texture==adapter.table.get_node("OriginalAppearance").texture,"Original immutable atlas shared without duplicating image")
	check(second.get_node("Solid")!=adapter.table.get_node("Solid"),"Each object has independent native body ownership")
	var before:=JSON.stringify(state.d);var original: Array=Room.collisions(state.d)
	check(world.chapter4_layers.collisions(state.d)==original,"All source collider records exactly preserved")
	var plain: RefCounted=Layers.new()
	for x in range(158,233,3):
		for y in range(645,777,4):
			var point:=Vector2(x,y)
			check(plain.pick_drag(point,state.d)==world.chapter4_layers.pick_drag(point,state.d),"Second-object central picking preserves source at "+str(point))
	var feet: Rect2=second.footprint_bounds();var visual: Vector2=art.global_position;var pick: Vector2=second.interaction_polygon()[0]
	second.position+=Vector2(64,0)
	check(second.footprint_bounds().position.is_equal_approx(feet.position+Vector2(64,0)),"Second root moves its real foot")
	check(second.interaction_polygon()[0].is_equal_approx(pick+Vector2(64,0)),"Second root moves its real pick")
	check((art.global_position-visual).is_equal_approx(Vector2(64,0)*adapter.source_space.scale),"Second root moves original appearance together")
	check(adapter.table.position==Vector2(72,710),"Moving second root leaves first object independent")
	adapter.sync(state.d,world.scene_id)
	check(second.footprint_bounds()==feet,"Source-authoritative sync restores exact original pose")
	for reduce: bool in [false,true]:
		var ghost: Control=adapter.drag_preview(Vector2(188,710),.9,reduce);root.add_child(ghost);ghost.set_process(false)
		check(ghost.art.region_rect==Room.rect(frame.sourceTrim) and ghost.art.texture==art.texture,"Second drag keeps its own source crop")
		check(second._held and not adapter.table._held,"Second drag dims only its own visual")
		adapter.finish_drag();second.advance_feedback(.04)
		check(second.footprint_bounds()==feet,"Second return animation cannot distort body")
		second.advance_feedback(.3);check(art.position==Vector2.ZERO and art.offset==Vector2(-219,-175) and art.scale==Vector2(.25,.25),"Second settle restores its own177px trim geometry")
		ghost.free()
	check(JSON.stringify(state.d)==before,"Object query/motion never writes story")
	var chapter: RefCounted=Chapter.new()
	for order: Array in [["window_time_marks","central_drag_marks"],["central_drag_marks","window_time_marks"]]:
		fixture();world.world_key="";world.refresh_world();world.set_process(false);adapter.sync(state.d,world.scene_id)
		var remaining:=2
		for group_id: String in order:
			var group: Dictionary
			for candidate: Dictionary in Room.data().groups:
				if candidate.id==group_id:group=candidate;break
			var target: Rect2=Room.rect(group.targetBounds);var stand:=stand_for(target)
			check(stand.is_finite(),"Original legal full-foot stand exists for "+group_id)
			state.d.native.player={"x":stand.x,"y":stand.y}
			chapter.dispatch(state.d,"c4_group_"+group_id,{"groupId":group_id,"targetGroupId":group_id,"orientation":"up","drop":[target.get_center().x,target.get_center().y]})
			remaining-=1;adapter.sync(state.d,world.scene_id)
			check(adapter.tables.size()==remaining and adapter.source_space.get_child_count()==remaining,"Retire exactly one native object in either original order")
			check(state.d.chapter4.room204Placements.size()==(2-remaining)*3,"Controller grants only original three-piece group")
			check(world.chapter4_layers.collisions(state.d)==Room.collisions(state.d),"Retirement leaves no stale or duplicate physical owner")
			chapter.dispatch(state.d,"c4_group_"+group_id,{"groupId":group_id,"targetGroupId":group_id,"orientation":"up","drop":[target.get_center().x,target.get_center().y]})
			check(state.d.chapter4.room204Placements.size()==(2-remaining)*3,"Repeat cannot duplicate original placements")
		check(not adapter.has_objects() and not adapter.visible,"Both restored groups retire the complete two-object adapter")
	fixture();world.world_key="";world.refresh_world();adapter.sync(state.d,world.scene_id)
	check(adapter.tables.size()==2,"Reentry recreates only the two source-owned tables")
	state.d.chapter4.floor="A1";adapter.sync(state.d,world.scene_id)
	check(adapter.tables.is_empty() and not adapter.visible,"Floor change disposes both bodies/picks/visuals")
	world.queue_free();await frames();check(not is_instance_valid(adapter),"World disposal releases both native objects")
	print("ROOM204_SECOND_TABLE ",checks," checks; ",failures," failures");quit(1 if failures else 0)
