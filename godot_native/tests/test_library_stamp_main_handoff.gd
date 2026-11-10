extends SceneTree
## Complete Main + State/controller + on-disk save/load regression.
## Retained source checkpoints initialize only prerequisites. No completion facts
## or result payloads are synthesized. Pointer events drive real activity views.
var checks:=0
var failures:=0
var state: Node
var shell
var actions: Array[String]=[]
var proofs: Array[Dictionary]=[]
var trace: Array=[]
var page
var phone_clock_owned:=false
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures+=1;push_error("MAIN_HANDOFF: "+label)
	return ok
func _initialize() -> void: run.call_deferred()
func frames(count:=3) -> void:
	for i in count: await process_frame
func mouse(p: Vector2,down: bool) -> void:
	var motion:=InputEventMouseMotion.new();motion.position=p;motion.global_position=p;root.push_input(motion,true)
	var e:=InputEventMouseButton.new();e.position=p;e.global_position=p;e.button_index=MOUSE_BUTTON_LEFT;e.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0;e.pressed=down
	root.push_input(e,true)
func click(button: Button) -> void:
	check(is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled,"ordinary button visible and enabled "+str(button.name))
	var p:=button.get_global_rect().get_center();mouse(p,true);mouse(p,false)
func tick(game,count: int,delta:=.05) -> void:
	for i in count: game._process(delta)
func mount() -> void:
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(6)
	shell.world.set_process(false)
func unmount() -> void:
	if is_instance_valid(shell): await shell.shutdown();shell.free();await frames()
	shell=null
func initialize_checkpoint(id: String) -> void:
	await unmount();state.developer_mode=true
	check(state.begin_checkpoint(id),"legal retained source checkpoint "+id)
	state.developer_mode=false;state.formal_snapshot={};state.persistence_ready=true
	check(state.validate_snapshot(state.d),"checkpoint has valid formal save shape")
	check(state.save_game(),"isolated formal checkpoint persisted")
	check(state.load_game(),"checkpoint reloaded through production validator")
	actions.clear();proofs.clear();await mount()
func assert_stamp_uncommitted(label: String) -> void:
	check(state.d.items.itemRecognitionReport and not state.d.items.bagNonPersonProof and not state.d.ui.libraryFinalsPuzzle.nonPersonProofStamped,label+": original report retained; no proof issued")
func stamp() -> void:
	for extent: Vector2i in [Vector2i(1280,720),Vector2i(390,844)]:
		root.size=extent;await initialize_checkpoint("c2-nonperson-stamp")
		for phase: String in ["scanning","ready","stamping"]:
			var result: Dictionary=state.act("lib_scan")
			await frames()
			if not check(result.has("game") and is_instance_valid(shell.active_game),"ordinary lib_scan opens real Main activity "+phase): return
			var game=shell.active_game;game.set_process(false)
			check(game.get_script().resource_path=="res://scripts/games/identity_stamp.gd","Main uses production scanner")
			game.finished.connect(func(value):proofs.append(value.duplicate(true)))
			if phase!="scanning":tick(game,16)
			if phase=="stamping":click(game.stamp);tick(game,2)
			assert_stamp_uncommitted("before cancel "+phase)
			click(game.return_button)
			tick(game,50)
			check(not is_instance_valid(shell.active_game),"return closes actual Main owner "+phase)
			check(proofs.is_empty() and actions.count("lib_scan_result")==0,"cancel and delayed frames cannot submit success "+phase)
			assert_stamp_uncommitted("after cancel "+phase)
			await frames()
			check(state.save_game(),"cancel state passes production save validator "+phase)
			await unmount();check(state.load_game(),"cancel state reloads "+phase);assert_stamp_uncommitted("after reload "+phase);await mount()
		var result: Dictionary=state.act("lib_scan");await frames()
		if not check(result.has("game") and is_instance_valid(shell.active_game),"reentry still uses ordinary lib_scan"): return
		var game=shell.active_game;game.set_process(false);game.finished.connect(func(value):proofs.append(value.duplicate(true)))
		tick(game,16);click(game.stamp);tick(game,24)
		check(proofs.size()==1 and actions.count("lib_scan_result")==1,"real stamp submits exactly once through Main callback")
		check(not state.d.items.itemRecognitionReport and state.d.items.bagNonPersonProof and state.d.ui.libraryFinalsPuzzle.nonPersonProofStamped,"controller consumes report and grants proof")
		check(not is_instance_valid(shell.active_game),"success releases Main activity")
		var saved: Dictionary=state._read_native_save(state.SAVE_PATH).get("state",{})
		check(saved.get("items",{}).get("bagNonPersonProof",false) and not saved.get("items",{}).get("itemRecognitionReport",true),"State automatic save contains accepted proof")
		tick(game,50);check(proofs.size()==1,"settled scanner cannot issue twice")
		await frames();await unmount();check(state.load_game(),"accepted scanner save reloads")
		check(state.d.items.bagNonPersonProof and not state.d.items.itemRecognitionReport and state.d.ui.libraryFinalsPuzzle.nonPersonProofStamped,"proof facts survive reload")
		var replay: Dictionary=state.act("lib_scan_result",proofs[0])
		check(not replay.has("game") and state.d.ui.libraryFinalsPuzzle.libraryVisitedPoints.count("lost_found")==1,"replaying real proof does not duplicate completion")
		check(not state.act("lib_scan").has("game"),"completed scanner cannot reopen a second award")
		print("STAMP_MAIN_HANDOFF viewport=",extent," realResult=",proofs[0])
func run() -> void:
	if not check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated save root"):quit(1);return
	state=root.get_node("State")
	state.action_completed.connect(func(id,_before,_after,_result):actions.append(id))
	await stamp()
	await unmount()
	print("LIBRARY_STAMP_MAIN_HANDOFF: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
