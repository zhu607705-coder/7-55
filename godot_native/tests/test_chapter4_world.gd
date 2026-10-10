extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter4.gd")
const Room=preload("res://scripts/games/chapter4_room204_model.gd")
const Layers=preload("res://scripts/ui/chapter4_world_layers.gd")
const Effect=preload("res://scripts/ui/chapter4_world_handoff.gd")
var checks: int=0
var failures: int=0
var state: Dictionary={}
class Surface extends Control:
	var layers: RefCounted
	var state: Dictionary
	var player_point:=Vector2(230,650)
	var draw_order:Array=[]
	var draw_pass:String=""
	func register_object_surface(ids:Array,_geometry:Dictionary) -> void:
		if ids.has("a1_bakery_inspection_lamp"):draw_order.append(draw_pass+":lamp")
	func _draw() -> void:
		if not layers: return
		draw_order.clear()
		var context: Dictionary={"origin":Vector2(-20,-420),"zoom":1.0,"player":player_point,"scene_id":"duan_yongping_temporal_maze","floor":state.chapter4.floor}
		draw_pass="back";layers.draw_back(self,context,state)
		draw_order.append("player")
		draw_pass="front";layers.draw_front(self,context,state)
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1; push_error(label)
func fresh() -> Dictionary:
	var s: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":4,"scene":"duan_yongping_temporal_maze","page":"c4_notes","mode":"light","player":{"x":94,"y":650},"settings":{}}
	s.chapter4.phase="room204_restore"; s.chapter4.floor="A2"; s.chapter4.prologueSeen=true; s.chapter4.timeState="1850_evening"; s.chapter4.mode="light"; s.chapter4.factIds=["misaligned_stair_solved","a3_reference_observed","room204_residual_observed"]
	return s
func run() -> void:
	state=fresh(); var chapter: RefCounted=Chapter.new(); var layers: RefCounted=Layers.new()
	var entities: Array=Room.entities(state)
	check(entities.size()==17,"Source discussion layout: twelve chairs, four tables, one podium")
	check(Room.collisions(state).size()==17,"Each visible furniture entity has exactly one source foot collider")
	var table: Dictionary={}
	for e in entities:
		if e.id=="group_table_1": table=e
	var collider: Rect2=Room.entity_collision(table)
	check(collider.size.y>collider.size.x,"Ninety-degree table rotation rotates the source collision footprint")
	var payload: Dictionary=layers.pick_drag(Vector2(72,710),state)
	check(payload.get("groupId","")=="window_time_marks","Picking the visible first discussion table identifies its authored group")
	var resolved: Dictionary=layers.resolve_drag(payload,Vector2(94,609),state)
	check(resolved.get("action","")=="c4_group_window_time_marks","Dragging to authored group target returns controller intent")
	var bad: Dictionary=resolved.value.duplicate(); bad.orientation="down"; chapter.dispatch(state,resolved.action,bad)
	check(state.chapter4.room204Placements.is_empty(),"Controller rejects down orientation")
	bad=resolved.value.duplicate(); bad.targetGroupId="central_drag_marks"; chapter.dispatch(state,resolved.action,bad)
	check(state.chapter4.room204Placements.is_empty(),"Controller rejects wrong group destination")
	bad=resolved.value.duplicate(); bad.drop=[500,500]; chapter.dispatch(state,resolved.action,bad)
	check(state.chapter4.room204Placements.is_empty(),"Controller rejects drop outside exact source target")
	state.native.player={"x":836,"y":716}; chapter.dispatch(state,resolved.action,resolved.value)
	check(state.chapter4.room204Placements.is_empty(),"Controller rechecks actual player proximity")
	state.native.player={"x":94,"y":650}; chapter.dispatch(state,resolved.action,resolved.value)
	check(state.chapter4.room204Placements.size()==3,"One group rearranges exactly three source desk-chair pairs")
	check(Room.entities(state).size()==19,"Rearranged group removes one discussion table and adds three desks")
	chapter.dispatch(state,resolved.action,resolved.value); check(state.chapter4.room204Placements.size()==3,"Repeated drop cannot duplicate furniture")
	for group in Room.data().groups:
		state.native.player={"x":group.targetBounds.x+16,"y":group.targetBounds.y+40}; chapter.dispatch(state,"c4_group_"+group.id)
	check(Room.entities(state).size()==25 and Room.complete(state.chapter4.room204Placements),"Final layout has twelve desks, twelve chairs and fixed podium")
	var clear: bool=true
	for x in Room.data().layout.walkability.verticalAisleCenters:
		for y in range(600,793,2):
			var foot: Rect2=Rect2(Vector2(x,y)-Vector2(19.5,14.625)/2,Vector2(19.5,14.625))
			for obstacle in Room.collisions(state):
				if foot.intersects(obstacle): clear=false
	check(clear,"All three authored vertical aisles retain full shared player foot clearance")
	state.chapter4.phase="maintenance_repair"; check(Room.presentation(state)=="restored","Restored furniture persists in later source display phases")
	state.chapter4.floor="A1"; check(Room.collisions(state).is_empty(),"A2 furniture does not leak colliders across floors")
	state=fresh(); state.chapter4.factIds.erase("room204_residual_observed"); chapter.dispatch(state,"c4_group_window_time_marks"); check(state.chapter4.room204Placements.is_empty(),"Active source group gate requires residual evidence")
	check(layers.pick_drag(Vector2(72,710),state).is_empty(),"Pointer cannot bypass evidence gate")
	var group: Dictionary=Room.data().groups[0]
	var current: Array=[{"pieceId":"desk_pair_01","slotId":"morning_slot_02","orientation":"up"}]
	var swapped: Dictionary=Room.group_result(current,group.id,group.id)
	check(swapped.accepted and swapped.placements.size()==3 and swapped.placements[1].slotId=="morning_slot_01","Source preferred-slot fallback preserves legitimate swapped placements")
	# Every timed world handoff remains presentation-only until validated terminal.
	state=fresh(); state.chapter4.floor="A1"; state.chapter4.factIds=["classroom_104_chalk_residual_observed","classroom_105_terminal_replay_checked","elevator_history_calibrated"]
	var request: Dictionary=chapter.dispatch(state,"c4_elevator_ride"); check(request.has("world_effect") and request.world_effect.durationMs==3960,"Source elevator includes open, board, close, two floors, open, exit, close")
	var proof: Dictionary={"session":request.world_effect.session,"elapsedMs":3959,"boarded":true,"arrived":true,"fromFloor":"A1","destination":"A3"}
	chapter.dispatch(state,"c4_arrive_a3",proof); check(state.chapter4.floor=="A1","Elevator rejects early terminal")
	proof.elapsedMs=3960; chapter.dispatch(state,"c4_arrive_a3",proof); check(state.chapter4.floor=="A3" and state.native.get("c4_native_elevator_completed",false),"Fresh native elevator completion marker is written only at validated terminal")
	var holder: Surface=Surface.new(); holder.size=Vector2(960,540); holder.layers=layers; state=fresh(); holder.state=state; root.add_child(holder)
	layers.tick(0.016,state); holder.queue_redraw(); await process_frame; await process_frame
	state.chapter4.mode="dark"; Layers.presentation={"kind":"projection","elapsedMs":400}; holder.queue_redraw(); await process_frame; await process_frame
	state.chapter4.floor="A1"; state.chapter4.phase="bakery_hour_hand"; state.chapter4.timeState="1225_bakery"; state.chapter4.factIds=[]; Layers.presentation={"kind":"bakery_stop","elapsedMs":550}; holder.queue_redraw(); await process_frame; await process_frame
	check(layers.collisions(state).size()==3,"Bakery moving crowd supplies three source player-foot colliders")
	# ChapterFourElevatorDepthModel.ts places the player at9900. The source
	# bakery machinery stays below4400, including at the actual hidden-avatar
	# save and at the authored lamp standing point (foot centre at374,390).
	for point:Vector2 in [Vector2(345.62857,384.56699),Vector2(374,358.3125),Vector2(374,425)]:
		holder.player_point=point;holder.queue_redraw();await process_frame;await process_frame
		check(holder.draw_order==["back:lamp","player"],"Source bakery paint order at "+str(point))
	for kind in ["paper_flight","paper_pickup","elevator_ride"]:
		state.chapter4.floor="A1"; state.chapter4.phase="room204_restore"; state.chapter4.timeState="1850_evening"
		var effect: Control=Effect.new(); holder.add_child(effect); effect.setup({"kind":kind,"session":"smoke-"+kind,"on_success":"noop","fromFloor":"A1","destination":"A3","phase":"room204_restore","player":{"x":772.5,"y":204},"durationMs":7000,"read_state":func(): return state,"project_position":func(p): return Vector2(480,160)+(p-Vector2(772.5,105.5))*0.85})
		for stamp in ([0,1500,2800,5400,5900] if kind=="paper_pickup" else [0,500,1000,2000,2900,3400]):
			effect.elapsed_ms=stamp; effect.queue_redraw(); await process_frame; await process_frame
		effect.cancel(); await process_frame
	check(Layers.presentation.is_empty(),"Cancelled world effect clears runtime animation state")
	holder.queue_free(); await process_frame
	print("CHAPTER4_WORLD_TESTS ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
