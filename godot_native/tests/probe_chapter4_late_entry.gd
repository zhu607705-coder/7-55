extends SceneTree
## Fresh process -> real entry Continue -> Main -> legal A2 movement/202 door.
## Earned input save only. No initial/checkpoint/fact or actor-position writes.
const Metrics=preload("res://scripts/player_metrics.gd")
const Planner=preload("res://scripts/mobile_floor_route.gd")
var checks: Array=[]
var failures:=0
var shell: Control
var state: Node
var scenario:=OS.get_environment("C4_LATE_SCENARIO")
var movements: Array=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> bool:
	checks.append({"ok":ok,"label":label})
	if not ok: failures+=1;push_error("C4_LATE_ENTRY: "+label)
	return ok
func frames(count: int=6) -> void:
	for i in count: await process_frame
func click(control: Control) -> void:
	var point: Vector2=control.get_global_transform_with_canvas()*(control.size/2)
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=down
		Input.parse_input_event(event);Input.flush_buffered_events();await process_frame
	await frames()
func key(code: Key,pressed: bool) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	Input.parse_input_event(event);Input.flush_buffered_events()
func gameplay() -> Dictionary:
	return {"items":state.d.items.duplicate(true),"wallet":state.d.wallet.duplicate(true),"chapter4":state.d.chapter4.duplicate(true)}
func run() -> void:
	state=root.get_node("State")
	if not check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated formal-save fixture"): finish();return
	if not check(FileAccess.file_exists(state.SAVE_PATH) and state.load_game(),"fresh process loads earned formal save"): finish();return
	var earned: Dictionary=gameplay()
	var chapter: Dictionary=state.d.chapter4
	check(not state.developer_mode and chapter.floor=="A2","ordinary earned A2 state, no developer checkpoint")
	check(chapter.factIds.has("misaligned_stair_solved"),"real stairs proof survives process boundary")
	if scenario=="stairs":check(chapter.phase=="room204_restore" and not chapter.factIds.has("room204_restored"),"stair arrival grants no later classroom completion")
	else:check(chapter.phase=="final_chase" and chapter.chaseStairwellStage=="complete" and not chapter.factIds.has("room202_route_reached"),"chase arrival grants no later 202 entry")
	root.size=Vector2i(int(OS.get_environment("C4_LATE_WIDTH")),int(OS.get_environment("C4_LATE_HEIGHT")))
	root.set_meta("entry_arguments_consumed",true)
	change_scene_to_file("res://scenes/entry.tscn");await frames()
	if not check(current_scene.story_button!=null and current_scene.story_button.is_visible_in_tree(),"real entry Continue is visible"): finish();return
	await click(current_scene.story_button)
	shell=current_scene
	if not check(shell.get_script().resource_path=="res://scripts/main.gd","real Continue reaches Main"):finish();return
	check(gameplay()==earned,"Continue preserves inventory, wallet and all earned C4 facts")
	if not shell.world_frame.is_visible_in_tree():
		if not check(shell.phone_world_return.visible and not shell.phone_world_return.disabled,"compact Continue exposes explicit Return to world"):await finish();return
		await click(shell.phone_world_return)
	var world: Control=shell.world
	world.set_process(false)
	await frames()
	check(shell.world_frame.is_visible_in_tree() and world.is_visible_in_tree(),"saved A2 map is visibly mounted")
	check(world.scene_id=="duan_yongping_temporal_maze" and world._last_floor=="A2" and world.world_size==Vector2(1672,941),"real world restores exact A2 floor and source extent")
	check(world.background!=null and world.background.get_size()==Vector2(1672,941),"A2 source plate is loaded")
	check(world.can_stand(world.player),"restored player has legal source collision feet")
	if scenario=="chase":check(world.player.distance_to(Vector2(966,214))<.01,"chase Continue restores committed A2 arrival instead of stale A1 pose")
	else:check(world.player.distance_to(Vector2(791,204))<.01,"stairs Continue restores authored A2 corridor spawn")
	check(not world.presentation_actor_hidden and not is_instance_valid(shell.active_game) and not is_instance_valid(shell.world_effect),"no old activity or presenter keeps player hidden/blocked")
	check(shell.world_viewport.gui_get_focus_owner()==world,"Main restores world keyboard focus")
	var screen: Vector2=world.size/2+(world.player-world.camera)*world.zoom
	check(world.camera.is_finite() and Rect2(Vector2.ZERO,world.size).has_point(screen),"A2 camera keeps restored player inside real world viewport")
	var start: Vector2=world.player
	var moved:=false
	for choice: Array in [[KEY_D,Vector2.RIGHT],[KEY_A,Vector2.LEFT],[KEY_S,Vector2.DOWN],[KEY_W,Vector2.UP]]:
		if not world.can_stand(start+choice[1]*8):continue
		key(choice[0],true);await process_frame;world._process(.025);key(choice[0],false);await process_frame
		if world.player.distance_to(start)>.1:moved=true;break
	check(moved and world.can_stand(world.player),"real keyboard input moves restored actor within collision bounds")
	check(gameplay()==earned,"walking cannot mint later story facts or alter owned items")
	movements.append({"kind":"keyboard","start":[start.x,start.y],"end":[world.player.x,world.player.y],"camera":[world.camera.x,world.camera.y]})
	if scenario=="chase": await enter202(world)
	check(state.save_game(),"post-entry real movement/door state persists through production save API")
	await finish()
func enter202(world: Control) -> void:
	var target: Dictionary={}
	for entry: Dictionary in state.get_targets(world.scene_id):
		if entry.get("action","")=="c4_reach202":target=entry;break
	if not check(not target.is_empty(),"earned chase exit exposes original 202 entrance"):return
	var goal:=Vector2(target.position[0],target.position[1])-Metrics.FOOT_CENTER_OFFSET
	var obstacles: Array=world._floor_obstacles()
	var route: Array[Vector2]=Planner.new().plan(world.player,goal,obstacles,world._floor_anchor_bounds(Rect2(Vector2.ZERO,world.world_size)),world.can_stand,func(a: Vector2,b: Vector2):return world._floor_segment_clear(a,b,obstacles,true))
	if not check(not route.is_empty(),"202 entrance has a continuous route through unchanged source collisions"):return
	# Analog-direction input is explicit harness setup. Actor position is never
	# assigned: every displacement still crosses the real world's collision path.
	var ticks:=0
	for point: Vector2 in route:
		while world.player.distance_to(point)>.05 and ticks<1800:
			var distance: float=world.player.distance_to(point)
			world.touch_axis=(point-world.player).normalized()
			var before: Vector2=world.player
			world._process(minf(.02,distance/208.0));ticks+=1
			if world.player.distance_to(before)<.0001:break
			if state.d.chapter4.floor!="A2" or state.d.chapter4.phase!="final_chase":break
	world.touch_axis=Vector2.ZERO;world._process(0)
	check(world.can_stand(world.player) and world._distance(target)<=float(target.radius),"collision-backed movement reaches 202 interaction range")
	check(world.nearby.get("action","")=="c4_reach202","202 is the actual nearby Space target")
	var event:=InputEventKey.new();event.keycode=KEY_SPACE;event.physical_keycode=KEY_SPACE;event.pressed=true
	shell.world_viewport.push_input(event,true);event=event.duplicate();event.pressed=false;shell.world_viewport.push_input(event,true)
	for i in range(6):world._process(.02)
	await frames()
	check(state.d.chapter4.floor=="A2" and state.d.chapter4.phase=="final_minute_recovery" and state.d.chapter4.roomId=="a2_room_202","real Space door-close hands off to 202 through original world/guard/controller seam")
	check(state.d.chapter4.factIds.has("room202_route_reached") and not state.d.items.finalMinute,"door entry grants its own fact without collecting later reward")
	movements.append({"kind":"collision-backed analog route and viewport Space","ticks":ticks,"end":[world.player.x,world.player.y],"phase":state.d.chapter4.phase})
func finish() -> void:
	var report: Dictionary={"scenario":scenario,"processId":OS.get_process_id(),"viewport":str(root.size),"failures":failures,"checks":checks,"movements":movements,"earnedCampaignSave":true,"developerSeeds":false,"actorPositionWrites":false,"notManualPlaythrough":true}
	var out:=OS.get_environment("C4_LATE_REPORT")
	if not out.is_empty():var file:=FileAccess.open(out,FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	if is_instance_valid(shell) and shell.has_method("shutdown"):await shell.shutdown();shell.queue_free();await frames()
	print("C4_LATE_ENTRY ",scenario," checks=",checks.size()," failures=",failures)
	quit(1 if failures else 0)
