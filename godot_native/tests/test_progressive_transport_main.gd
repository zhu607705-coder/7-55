extends SceneTree
## Focused production-Main integration with explicit source-checkpoint/position
## setup. This is not manual navigation or an earned full-chapter playthrough.
const Chapter=preload("res://scripts/chapters/chapter4.gd")
const Stair=preload("res://scripts/games/chapter4_stair_model.gd")
const Proof=preload("res://tests/helpers/progressive_transport_proof.gd")
var state: Node
var shell: Control
var checks:=0
var failures:=0
var starts:=0

func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:failures+=1;push_error("PROGRESSIVE_MAIN: "+label)
	return ok
func frames(n: int=3) -> void:
	for i in n:await process_frame
func tap_key(code: int,world_input: bool=false) -> void:
	for pressed: bool in [true,false]:
		var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed
		if world_input:shell.world_viewport.push_input(e,true)
		else:root.push_input(e,true)
		await frames(1)
func click(button: Button) -> void:
	var rect:=Rect2(button.get_global_transform_with_canvas().origin,button.size*button.get_global_transform_with_canvas().get_scale())
	check(button.is_visible_in_tree() and not button.disabled and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(rect),"Actual button is visible and contained: "+button.name)
	for pressed: bool in [true,false]:
		var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=rect.get_center();e.global_position=e.position;e.pressed=pressed
		root.push_input(e,true);await frames(2)
func close_shell() -> void:
	if is_instance_valid(shell):await shell.shutdown();shell.queue_free();await frames(4)
func mount(view: Vector2i) -> void:
	root.size=view;shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
	shell._refresh();await frames(5)
	check(shell.world_frame.is_visible_in_tree() and state.d.runtimeMode=="rpg","Persisted RPG surface is visible in production Main")
func original_stair_fixture() -> Dictionary:
	# A legal source-model receipt makes this explicit A2 setup exportable.
	# The new activity does not grant, replace or bypass the original stair gate.
	var data: Dictionary=Stair.data();var records: Array=[]
	for level: Dictionary in data.levels:
		var current: Dictionary=Stair.initial(level);var camera: Dictionary=data.cameras[level.id].duplicate(true);var actions: Array=[]
		if level.id=="stair_a":
			stair_step(level,current,camera,"a_slide",1,actions);stair_step(level,current,camera,"a_stair",0,actions);stair_step(level,current,camera,"a_lift",1,actions)
			stair_act(level,current,camera,{"type":"view","value":"south_west"},actions);stair_act(level,current,camera,{"type":"walk","node":"A_EXIT"},actions)
		elif level.id=="stair_b":
			stair_step(level,current,camera,"b_lower_stair",3,actions);stair_step(level,current,camera,"b_mid_lift",0,actions);stair_step(level,current,camera,"b_upper_stair",1,actions);stair_step(level,current,camera,"b_exit_slide",2,actions)
			stair_act(level,current,camera,{"type":"view","value":"south_west"},actions);stair_act(level,current,camera,{"type":"walk","node":"B_MID_LIFT_LOW"},actions);stair_step(level,current,camera,"b_mid_lift",2,actions)
			stair_act(level,current,camera,{"type":"view","value":"top_oblique"},actions);stair_act(level,current,camera,{"type":"walk","node":"B_EXIT"},actions)
		else:
			for index in range(level.ascentViewSequence.size()):
				var prefix: String=level.id+"_"+str(index+1)
				stair_step(level,current,camera,prefix+"_rotate",0,actions);stair_step(level,current,camera,prefix+"_transfer",0,actions)
				stair_act(level,current,camera,{"type":"view","value":level.ascentViewSequence[index]},actions);stair_act(level,current,camera,{"type":"walk","node":prefix+"_car"},actions);stair_step(level,current,camera,prefix+"_transfer",2,actions)
				stair_act(level,current,camera,{"type":"walk","node":level.exitNodeId if index==level.ascentViewSequence.size()-1 else prefix+"_transfer_exit"},actions)
		records.append({"id":level.id,"actions":actions})
	var result: Dictionary={"kind":"chapter4_stair_campaign","doorTraversed":true,"levels":records}
	check(Stair.validate_result(result),"Explicit A2 setup includes the unchanged replay-valid original four-stair receipt")
	return result
func stair_act(level: Dictionary,current: Dictionary,camera: Dictionary,action: Dictionary,actions: Array) -> void:
	check(Stair.apply(level,current,camera,action),"Original source fixture legal stair action");actions.append(action)
func stair_step(level: Dictionary,current: Dictionary,camera: Dictionary,id: String,value: int,actions: Array) -> void:
	var count:=0
	while int(current.values[id])!=value and count<4:
		stair_act(level,current,camera,{"type":"step","id":id,"delta":1},actions);count+=1

func prepare(id: String,view: Vector2i) -> Dictionary:
	await close_shell()
	state.developer_mode=true
	check(state.begin_checkpoint("c3-qizhen-dock" if id=="lake_logistics" else "c4-755-room204-1850"),"Explicit source setup "+id)
	if id!="lake_logistics":
		# This source checkpoint is A3 before the stair, despite its room204 name.
		# Its elevator origin is explicit fixture setup; the actual stair controller
		# must still accept the legal four-level proof and transport this state to A2.
		state.d.native.c4_elevator_transport=true
		var stair_request: Dictionary=state.act("c4_stairs")
		if not check(stair_request.has("game"),"Source A3 fixture issues original stair controller session"):return {}
		var stair_receipt:=original_stair_fixture();stair_receipt.session=stair_request.game.session
		state.act(stair_request.game.on_success,stair_receipt)
		check(state.d.chapter4.floor=="A2" and state.d.chapter4.factIds.has("misaligned_stair_solved"),"Original replay-valid stair transport establishes the A2 device fixture")
		state.d.chapter4.mode="light";state.d.native.mode="light"
	state.d.runtimeMode="rpg";state.d.native.positions={};state.d.ui.controlCenterOpen=false;state.d.ui.inventoryOpen=false
	state.developer_mode=false
	await mount(view)
	var action: String="c3_lake_target:qizhen_dock_logistics" if id=="lake_logistics" else "c4_device_"+id
	var target: Dictionary={}
	for entry: Dictionary in state.get_targets(str(state.d.native.scene)):
		if entry.get("action","")==action:target=entry
	if not check(not target.is_empty(),"Actual world exposes physical target "+id):return {}
	var center: Vector2=Vector2(target.position[0],target.position[1]);var point:=Vector2.INF
	for offset: Vector2 in [Vector2(25,0),Vector2(0,78),Vector2(0,-78),Vector2(-78,0),Vector2(78,0),Vector2.ZERO]:
		if shell.world.can_stand(center+offset):point=center+offset;break
	if not check(point.is_finite(),"Target has a legal source-foot standing point "+id):return {}
	shell.world.player=point;shell.world._sync_player();shell.world.grab_focus();await frames(5)
	check(shell.world._distance(target)<=target.radius and shell.world.can_stand(shell.world.player),"Fixture is on authored land at actual interaction distance "+id)
	check(state.validate_snapshot(state.d),"Setup passes ordinary native save validator "+id)
	var output: String=OS.get_environment("PROGRESSIVE_CAPTURE_DIR")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
		check(state.export_save(output.path_join("before_"+id+".json"))==OK,"Export explicit setup before physical activity "+id)
	return target

func open_target(target: Dictionary,id: String) -> Control:
	var prior:=starts
	var local: Vector2=(shell.world._target_point(target)-shell.world.camera)*shell.world.zoom+shell.world.size/2
	check(Rect2(Vector2.ZERO,shell.world.size).has_point(local),"Source object is visible for real pointer input "+id)
	for pressed: bool in [true,false]:
		var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=local;e.global_position=local;e.pressed=pressed
		shell.world_viewport.push_input(e,true);await frames(2)
	var game: Control=shell.active_game
	check(is_instance_valid(game) and game.config.get("kind","")=="progressive_transport" and game.config.puzzleId==id and starts==prior+1,"Ordinary physical object pointer mounts exactly one activity "+id)
	check(shell.modal==null and shell.world_effect==null,"No old answer modal or second world overlay "+id)
	return game
func world_return(point: Vector2,id: String) -> void:
	await frames(5)
	check(not is_instance_valid(shell.active_game) and shell.world_frame.is_visible_in_tree() and state.d.runtimeMode=="rpg","Activity returns to real world surface "+id)
	check(shell.world.player.is_equal_approx(point) and shell.world.can_stand(shell.world.player),"Return preserves original legal world position "+id)
	check(shell.world_viewport.gui_get_focus_owner()==shell.world and not shell.world._shell_input_blocked(),"Return restores actual world viewport focus and input "+id)

func exercise(id: String,view: Vector2i) -> void:
	var target: Dictionary=await prepare(id,view)
	if target.is_empty():return
	var point: Vector2=shell.world.player
	var lake_before: Dictionary=state.d.qizhenLake.duplicate(true);var items: Dictionary=state.d.items.duplicate(true);var wallet: Dictionary=state.d.wallet.duplicate(true);var checkpoint: String=state.d.rpgCheckpoint
	var game: Control=await open_target(target,id)
	if not is_instance_valid(game):return
	var first_config: Dictionary=game.config.duplicate(true)
	await tap_key(KEY_RIGHT);await tap_key(KEY_D,true)
	check(shell.world.player.is_equal_approx(point),"Activity owns input and cannot move the hidden-underlay actor "+id)
	var cancel_bytes:=FileAccess.get_file_as_string(state.SAVE_PATH)
	await click(game.controls.TransportExit)
	await world_return(point,id)
	check(FileAccess.get_file_as_string(state.SAVE_PATH)==cancel_bytes,"Physical cancellation leaves durable save bytes unchanged "+id)
	check(state.d.qizhenLake==lake_before and state.d.items==items and state.d.wallet==wallet and state.d.rpgCheckpoint==checkpoint,"Cancel preserves all lake, inventory, wallet and checkpoint fields "+id)
	state.act(first_config.on_success,Proof.proof(first_config))
	if id!="lake_logistics":check(not state.d.chapter4.factIds.has("a2_power_topology_recovered" if id=="power_topology" else "a2_evacuation_route_confirmed"),"Cancelled old callback cannot grant original fact "+id)
	game=await open_target(target,id)
	if not is_instance_valid(game):return
	check(game.config.session!=first_config.session and game.model.proof().actions.is_empty(),"Re-entry issues fresh nonce and starts local board clean "+id)
	var unfinished: Dictionary=game.config.duplicate(true)
	check(state.save_game(),"Ordinary save during unfinished local board "+id)
	await close_shell()

	var stale_result: Dictionary=state.act(unfinished.on_success,Proof.proof(unfinished))
	if id=="lake_logistics":check(not stale_result.get("accepted",false),"Main shutdown retires dock nonce before state reload")
	else:check(not state.d.chapter4.factIds.has("a2_power_topology_recovered" if id=="power_topology" else "a2_evacuation_route_confirmed"),"Main shutdown retires device nonce before state reload "+id)
	state.d=state.initial();check(state.load_game(),"Ordinary reload of unfinished local board "+id)
	await mount(view)
	check(shell.active_game==null and shell.modal==null and state.d.qizhenLake==lake_before,"Unfinished local session is absent from ordinary save "+id)
	# The lake intentionally reloads at its source safe checkpoint. This second
	# near-target placement is explicit integration setup, not claimed traversal.
	shell.world.player=point;shell.world._sync_player();await frames(4)
	game=await open_target(target,id)
	if not is_instance_valid(game):return
	check(game.config.session!=unfinished.session and game.model.proof().actions.is_empty(),"Post-load physical re-entry starts a new activity "+id)
	var paths: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Proof.FIXTURE))
	for action: String in paths.puzzles[id].actions:
		if action=="continue":await click(game.controls.TransportContinue)
		else:await tap_key({"up":KEY_UP,"down":KEY_DOWN,"left":KEY_LEFT,"right":KEY_RIGHT}[action])
	check(game.state.complete,"Actual directional inputs reach three real exits "+id)
	if id!="lake_logistics":check(not state.d.chapter4.factIds.has("a2_power_topology_recovered" if id=="power_topology" else "a2_evacuation_route_confirmed"),"Final local exit waits for explicit controller handoff "+id)
	await click(game.controls.TransportContinue)
	await world_return(point,id)
	if id=="lake_logistics":check(state.d.qizhenLake==lake_before,"Successful optional activity leaves entire lake story state equal")
	else:check(state.d.chapter4.factIds.has("a2_power_topology_recovered" if id=="power_topology" else "a2_evacuation_route_confirmed"),"Actual final button earns original device fact "+id)
	check(state.d.items==items and state.d.wallet==wallet and state.d.rpgCheckpoint==checkpoint,"Successful handoff retains inventory wallet checkpoint "+id)
	var saved_facts: Array=state.d.chapter4.factIds.duplicate();var saved_lake: Dictionary=state.d.qizhenLake.duplicate(true)
	check(state.save_game(),"Ordinary save after activity "+id)
	await close_shell();state.d=state.initial();check(state.load_game(),"Ordinary file reload after activity "+id)
	await mount(view)
	check(state.d.chapter4.factIds==saved_facts and state.d.qizhenLake==saved_lake and state.d.items==items and state.d.wallet==wallet and state.d.rpgCheckpoint==checkpoint,"Reload preserves original facts and all lake/material contracts "+id)
	check(shell.active_game==null and shell.modal==null and shell.world.can_stand(shell.world.player),"Reload cannot restore a partial activity or block normal world "+id)
	if id=="lake_logistics":
		check(shell.world.player.is_equal_approx(Vector2(330,830)),"Lake reload retains its original safe dock spawn semantics")
		# Explicit fixture positioning again, followed by the same real physical input.
		shell.world.player=point;shell.world._sync_player();await frames(3)
		game=await open_target(target,id)
		if is_instance_valid(game):await click(game.controls.TransportExit);await world_return(point,id)
	else:
		state.act("c4_device_"+id);await frames(3)
		check(is_instance_valid(shell.modal) and shell.modal.session.completed and shell.active_game==null,"Completed save re-entry uses original read-only record without a new gate "+id)
		if is_instance_valid(shell.modal):await click(shell.modal.close_button)
	await close_shell()

func replacement_boundaries() -> void:
	var target: Dictionary=await prepare("power_topology",Vector2i(1280,720))
	if target.is_empty():return
	var point: Vector2=shell.world.player
	var first: Control=await open_target(target,"power_topology")
	if not is_instance_valid(first):return
	var old: Dictionary=first.config.duplicate(true)
	var before_scene: String=state.d.native.scene
	# Explicit lifecycle fixture using an existing unrelated host. No domain
	# result is submitted for it and no story/phase precondition is fabricated.
	shell._open_game_now({"type":"kayak","phase":"boarding","goal":4,"on_success":"c3_kayak_result","title":"既有活动的生命周期测试"})
	await frames(3)
	check(is_instance_valid(shell.active_game) and shell.active_game!=first and state.d.native.scene==before_scene and state.d.native.c4_context=="power_topology","Unrelated host replaces old view while the original domain context stays equal")
	state.act(old.on_success,Proof.proof(old))
	check(not state.d.chapter4.factIds.has("a2_power_topology_recovered"),"Cross-activity replacement retires old nonce despite equal domain context")
	if is_instance_valid(shell.active_game):await click(shell.active_game.exit_button)
	await world_return(point,"cross-activity replacement")
	first=await open_target(target,"power_topology")
	if not is_instance_valid(first):return
	old=first.config.duplicate(true)
	var issued: Dictionary=state.act("c4_device_evacuation_route")
	await frames(3)
	var next: Control=shell.active_game
	var controller: RefCounted
	for module: RefCounted in state.modules:
		if module.has_method("cancel_progressive_session"):controller=module
	if not check(issued.has("game") and is_instance_valid(next) and next!=first,"Same-chapter intent issues a new nonce before old-view cleanup"):await close_shell();return
	check(next.config.session==issued.game.session and controller.progressive_session==issued.game.session,"Exact old-view cancellation preserves the already-issued new nonce")
	state.act(old.on_success,Proof.proof(old))
	check(controller.progressive_session==issued.game.session and not state.d.chapter4.factIds.has("a2_power_topology_recovered"),"Late old completion cannot finish or cancel the newer activity")
	var paths: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Proof.FIXTURE))
	for action: String in paths.puzzles.evacuation_route.actions:
		if action=="continue":await click(next.controls.TransportContinue)
		else:await tap_key({"up":KEY_UP,"down":KEY_DOWN,"left":KEY_LEFT,"right":KEY_RIGHT}[action])
	check(next.state.complete,"Newer activity remains playable through all actual exits after old cleanup")
	await click(next.controls.TransportContinue)
	await world_return(point,"newer same-chapter activity")
	check(state.d.chapter4.factIds.has("a2_evacuation_route_confirmed") and not state.d.chapter4.factIds.has("a2_power_topology_recovered"),"Only the newer actual final input commits its original domain fact")
	await close_shell()

func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():push_error("Progressive Main checks require isolated saves");quit(2);return
	state=root.get_node("State")
	state.game_requested.connect(func(config: Dictionary):
		if config.get("kind","")=="progressive_transport":starts+=1
	)
	await exercise("power_topology",Vector2i(1440,900))
	await exercise("evacuation_route",Vector2i(390,844))
	await exercise("lake_logistics",Vector2i(1180,812))
	await replacement_boundaries()
	print("PROGRESSIVE_TRANSPORT_MAIN %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
