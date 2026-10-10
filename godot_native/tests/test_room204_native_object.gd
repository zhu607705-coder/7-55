extends SceneTree
const Room=preload("res://scripts/games/chapter4_room204_model.gd")
const Layers=preload("res://scripts/ui/chapter4_world_layers.gd")
const Chapter=preload("res://scripts/chapters/chapter4.gd")
var checks:=0
var failures:=0
var state: Node
var world: Control
func _initialize() -> void: run.call_deferred()
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1;push_error(label)
func frames(n:=2) -> void:
	for i in range(n): await process_frame
func fixture() -> void:
	state.d=state.initial()
	state.d.native.chapter=4;state.d.native.scene="duan_yongping_temporal_maze";state.d.native.mode="light"
	state.d.chapter4.prologueSeen=true;state.d.chapter4.phase="room204_restore";state.d.chapter4.floor="A2";state.d.chapter4.timeState="1850_evening";state.d.chapter4.mode="light"
	state.d.chapter4.factIds=["misaligned_stair_solved","a3_reference_observed","room204_residual_observed"]
	state.d.native.player={"x":94,"y":650}
func run() -> void:
	state=root.get_node("State");fixture()
	world=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false);await frames()
	var adapter: Node2D=world.room204_object
	adapter.sync(state.d,world.scene_id)
	check(adapter.owns_entity("table:group_table_1"),"One table scene owns the selected original entity")
	check(adapter.source_space.get_child_count()==2 and adapter.owns_entity("table:group_table_2"),"Exactly two independent source table instances")
	check(adapter.table.get_node("OriginalAppearance") is Sprite2D,"Actual Sprite2D renders original atlas")
	check(adapter.table.get_node("Solid/Foot") is CollisionShape2D,"Actual native foot shape is present")
	check(not adapter.table.get_node("Interaction").input_pickable,"Central World dispatcher is sole pointer owner")
	check(adapter.before_pass.get_index()<adapter.source_space.get_index() and adapter.source_space.get_index()<adapter.after_pass.get_index(),"Native sprite sits between original before/after draw passes")
	var original: Array=Room.collisions(state.d)
	var native: Array=world.chapter4_layers.collisions(state.d)
	check(original.size()==native.size(),"No duplicate or missing dynamic collider")
	for i in range(original.size()): check(original[i].is_equal_approx(native[i]),"Source foot bounds preserved at index "+str(i))
	var plain: RefCounted=Layers.new();var before:=JSON.stringify(state.d)
	for x in range(40,126,3):
		for y in range(646,775,5):
			var point:=Vector2(x,y)
			check(plain.pick_drag(point,state.d)==world.chapter4_layers.pick_drag(point,state.d),"Original full-region group picking parity "+str(point))
	for z: float in [.5,.85,1.7]:
		for camera: Vector2 in [Vector2.ZERO,Vector2(100,600),Vector2(500,700)]:
			adapter.configure_view(Vector2(480,270)-camera*z,z)
			check(adapter.footprint_bounds().is_equal_approx(Room.entity_collision(adapter.entity)),"Camera/zoom cannot alter source collision")
			var sprite: Sprite2D=adapter.table.get_node("OriginalAppearance")
			var expected: Vector2=Vector2(480,270)-camera*z+adapter.table.transform*sprite.position*z
			check(sprite.global_position.is_equal_approx(expected),"Rendered original pivot follows source camera transform")
	# A scene-root transform moves visible sprite, foot and pick together. This
	# fixture transform is not a campaign placement or saved-state mutation.
	var initial_bounds: Rect2=adapter.footprint_bounds();var initial_pick: Vector2=adapter.table.interaction_polygon()[0]
	adapter.table.position+=Vector2(116,0)
	check(adapter.footprint_bounds().position.is_equal_approx(initial_bounds.position+Vector2(116,0)),"Moving native root moves its collision")
	check(adapter.table.interaction_polygon()[0].is_equal_approx(initial_pick+Vector2(116,0)),"Moving native root moves its pick shape")
	check(not adapter.contains_source_point(Vector2(72,710)) and adapter.contains_source_point(Vector2(188,710)),"No invisible old interaction survives native root move")
	check(adapter.front_of_player(Vector2(0,710)),"Occlusion order reads the same native root transform")
	adapter.table.position.y-=20
	check(not adapter.front_of_player(Vector2(0,710)),"Moving root across actor depth also changes its occlusion pass")
	adapter.sync(state.d,world.scene_id)
	check(adapter.footprint_bounds().is_equal_approx(initial_bounds),"State-derived original transform restored without a second placement record")
	check(JSON.stringify(state.d)==before,"Presentation and geometry queries never mutate campaign state")
	for y in range(640,780,5):
		for x in range(40,128,5):
			var p:=Vector2(x,y);world.chapter4_layers.native_prop=null;var old: bool=world.can_stand(p);world.chapter4_layers.native_prop=adapter
			check(world.can_stand(p)==old,"Full player foot collision parity "+str(p))
	var chapter: RefCounted=Chapter.new()
	state.d.native.player={"x":94,"y":650}
	chapter.dispatch(state.d,"c4_group_window_time_marks",{"groupId":"window_time_marks","targetGroupId":"central_drag_marks","orientation":"up","drop":[94,609]})
	check(state.d.chapter4.room204Placements.is_empty() and adapter.owns_entity("table:group_table_1"),"Wrong group retains original table and authority rejects result")
	chapter.dispatch(state.d,"c4_group_window_time_marks",{"groupId":"window_time_marks","targetGroupId":"window_time_marks","orientation":"up","drop":[94,609]})
	world.chapter4_layers.collisions(state.d)
	check(state.d.chapter4.room204Placements.size()==3,"Original controller grants exactly three pieces")
	check(not adapter.owns_entity("table:group_table_1") and adapter.source_space.get_child_count()==1 and adapter.owns_entity("table:group_table_2"),"Completed first group retires only its visual/collision/input, preserving second table")
	check(world.chapter4_layers.collisions(state.d)==Room.collisions(state.d),"Restored desks keep original collision ownership")
	await frames();fixture();world.refresh_world();adapter.sync(state.d,world.scene_id)
	check(adapter.source_space.get_child_count()==2,"Ordinary pre-placement state recreates exactly two scenes")
	state.d.chapter4.floor="A1";world.refresh_world();adapter.sync(state.d,world.scene_id)
	check(adapter.source_space.get_child_count()==0 and not adapter.visible,"Floor return disposes the inactive table and render passes")
	fixture();world.refresh_world();adapter.sync(state.d,world.scene_id)
	check(adapter.source_space.get_child_count()==2,"Repeated reentry has one owner per source table")
	world.queue_free();await frames()
	check(not is_instance_valid(adapter),"World disposal retires its entire native object adapter")
	print("ROOM204_NATIVE_OBJECT ",checks," checks; ",failures," failures");quit(1 if failures else 0)
