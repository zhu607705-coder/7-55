extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter4.gd")
const Room=preload("res://scripts/games/chapter4_room204_model.gd")
var checks:=0
var failures:=0
var state: Node
var world: Control
var chapter: RefCounted
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func fixture() -> Dictionary:
	var path:=OS.get_environment("C4_RESIDUAL_INPUT")
	if not path.is_empty():return JSON.parse_string(FileAccess.get_file_as_string(path)).state
	var s: Dictionary=state.initial();s.native.chapter=4;s.native.scene="duan_yongping_temporal_maze";s.native.mode="light"
	s.chapter4.merge({"phase":"room204_restore","floor":"A2","timeState":"1850_evening","mode":"light","prologueSeen":true},true)
	s.chapter4.factIds=["a1_time_route_compared","a3_reference_observed","a3_identity_context_observed","misaligned_stair_solved","room204_residual_observed","room204_restored"]
	s.chapter4.room204Placements=[]
	for group in chapter.content.room204.groups:
		for m in group.mappings:s.chapter4.room204Placements.append({"pieceId":m.pieceId,"slotId":m.slotId,"orientation":"up"})
	return s
func ids() -> Array:return world.targets.map(func(t):return t.id)
func refresh() -> void:
	world.world_key="";world.refresh_world();world.set_process(false)
	world.object_picker.clear();world._record_plate_targets()
func run() -> void:
	state=root.get_node("State");chapter=Chapter.new();state.d=fixture()
	world=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false)
	await process_frame
	var full: Dictionary=state.d.duplicate(true);var footprint: Array=Room.collisions(full)
	for mode: String in ["light","dark"]:
		state.d=full.duplicate(true);state.d.chapter4.mode=mode;state.d.native.mode=mode;refresh()
		var before:=JSON.stringify(state.d)
		check("a2_room204_residual_group" not in ids(),"Observed residual is retired in "+mode)
		check("a2_room204_podium_drawer" in ids(),"Original projection target remains in "+mode)
		for point: Vector2 in [Vector2(199.5,575),Vector2(180,557),Vector2(219,600),Vector2(200,550)]:
			check(world._pick_target(point).get("id","")=="a2_room204_podium_drawer","Drawer center/edges pick podium in "+mode+" "+str(point))
		check(world._pick_target(Vector2(300,700)).is_empty(),"Retired broad region no longer intercepts open floor in "+mode)
		check(Room.collisions(state.d)==footprint,"Original geometry unchanged in "+mode)
		check(JSON.stringify(state.d)==before,"Picking remains read-only in "+mode)
	# An earlier ordinary save still exposes its original unearned observation.
	state.d=full.duplicate(true);state.d.chapter4.factIds.erase("room204_residual_observed");refresh()
	check("a2_room204_residual_group" in ids(),"Unobserved residual remains available after old-save reentry")
	check(world._pick_target(Vector2(300,700)).get("id","")=="a2_room204_residual_group","Original residual geometry is retained")
	state.d=full.duplicate(true);state.d.chapter4.factIds.append("room204_projection_completed");refresh()
	var picked: Dictionary=world._pick_target(Vector2(199.5,575))
	check(picked.get("action","")=="c4_plate","After original projection, same drawer selects original plate pickup")
	state.d.chapter4.factIds.append("positioning_plate_collected");refresh()
	check("a2_room204_podium_drawer" not in ids(),"Collected original plate retires its target")
	state.d=full.duplicate(true);state.d.chapter4.floor="A1";refresh()
	check("a2_room204_residual_group" not in ids() and "a2_room204_podium_drawer" not in ids(),"Leaving floor retires both targets")
	world.queue_free();await process_frame
	print("ROOM204_RESIDUAL_TARGET ",checks," checks; ",failures," failures");quit(1 if failures else 0)
