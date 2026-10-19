extends SceneTree
## Seeded, same-Main lifecycle checks for the combined animation branches.
## State replacement + story_reset mirrors the post-normalization load boundary.
## This is automated runtime coverage, not an earned campaign or GUI recording.
const Chapter=preload("res://scripts/chapters/chapter3.gd")
var checks:=0
var failures:=0
var state:Node
var shell:Control
var teleports:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("ANIMATION_BATCH: "+label)
func frames(count:int=3)->void:
	for i in count:await process_frame
func install(value:Dictionary)->void:
	state.d=value.duplicate(true);state.story_reset.emit();state.changed.emit()
	shell._show_world_mobile();shell._refresh();await frames()
	shell.world.set_process(false);shell.c3_scene_host.set_process(false)
	shell.c3_narrative_host.set_process(false);shell.library_story_host.set_process(false)
	shell.world._process(0)
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated profile")
	if failures:quit(1);return
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	root.size=Vector2i(1280,720)
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	var original_world:Control=shell.world
	for reduced in [false,true]:
		# The same Main must cancel queued cup motion while preserving its already
		# committed transaction. A replaced state cannot inherit a visual tail.
		state.begin_checkpoint("c3-canteen-entry")
		var value:Dictionary=state.d.duplicate(true)
		value.canteenHunt.entryPaperEscaped=true;value.native.settings.reduced_motion=reduced
		var chapter:=Chapter.new()
		var target:Dictionary=chapter.get_definition("canteen_interior","canteen-mixer",value)
		var point:Dictionary=target.get("stand",{"x":target.x,"y":target.y})
		value.native.positions={"canteen_interior:":{"x":point.x,"y":point.y}}
		for id:String in chapter.RECIPE:value.items[id]=true
		await install(value)
		shell.world.player=Vector2(point.x,point.y);shell.world._sync_player()
		state.act("c3_target:canteen-mixer")
		check(is_instance_valid(shell.c3_device_panel),"original action opens Main mixer")
		if not is_instance_valid(shell.c3_device_panel):continue
		var mixer:Control=shell.c3_device_panel
		mixer.set_process(false);mixer.surface.motion.set_process(false)
		for id:String in chapter.RECIPE:mixer._pour(mixer.session.button_order.find(id))
		check(state.d.items.dailySpecialSparklingWater and mixer.finishing,"reward is committed before optional queued animation")
		check(mixer.surface.pending_pours.size()==2,"rapid original controls retain two queued pours")
		var committed:Dictionary=state.d.duplicate(true)
		state.d=committed.duplicate(true);state.story_reset.emit()
		check(shell.c3_device_panel==null and not is_instance_valid(shell.modal),"same-Main load closes old mixer")
		check(mixer.surface.pending_pours.is_empty() and not mixer.surface.motion.playing,"load cancels all old cup motion")
		mixer._pour(0);mixer._process(10)
		check(state.d.items==committed.items and state.d.canteenHunt.drinkMixAttemptCount==committed.canteenHunt.drinkMixAttemptCount,"stale mixer callbacks cannot spend or duplicate reward")
		await frames()
		# A stamp that was already awarded is static after load. The old scanner
		# cannot issue to its replacement Main owner or restart the paper wait.
		value=state.initial();value.native.chapter=2;value.native.scene="library_interior";value.native.mode="light"
		value.runtimeMode="rpg";value.rpgScene="library_interior";value.actOne.phase="complete"
		value.actOne.controlsInstalled=true;value.actOne.movementEnabled=true;value.actOne.inventoryRecovered=true
		value.native.settings.reduced_motion=reduced
		value.ui.libraryFinalsPhase="evidence_gathering";value.ui.libraryFinalsPuzzle.itemReportGenerated=true
		value.ui.libraryFinalsPuzzle.lostFoundStage="ready";value.items.itemRecognitionReport=true
		value.native.selected_item="itemRecognitionReport";value.native.positions={"library_interior:":{"x":334,"y":694}}
		await install(value)
		shell.world.player=Vector2(334,694);shell.world._sync_player()
		var desk:Dictionary={"id":"identity_machine","position":[334,594],"bounds":[174,519,320,150],"radius":64,"mode":"light","item":"itemRecognitionReport","action":"lib_scan"}
		shell.world._try_interact(desk)
		check(is_instance_valid(shell.active_game),"same Main opens original identity scanner")
		if not is_instance_valid(shell.active_game):continue
		var scanner:Control=shell.active_game;scanner.set_process(false)
		for i in 8:scanner._process(.1)
		scanner._stamp();shell.world.library_layers.sync(state.d)
		check(state.d.items.bagNonPersonProof and not state.d.items.itemRecognitionReport,"original scanner/controller awards once")
		check(shell.world.library_layers.stamp_ms==0,"combined world begins actual stamp choreography")
		committed=state.d.duplicate(true)
		state.d=committed.duplicate(true);state.story_reset.emit()
		scanner.finished.emit({"scanMs":720,"identityChecks":[false,false,false],"stamped":true})
		check(shell.active_game==null and state.d.items==committed.items,"replaced scanner callback is ignored")
		shell.world.refresh_world();shell.world.library_layers.sync(state.d)
		check(shell.world.library_layers.stamp_ms==-1 and not shell._library_stamp_presentation_active(),"loaded proof has no replay or stuck stamp wait")
		await frames()
		# A live admission interrupted by a checkpoint cannot teleport the newly
		# installed scene. Returning shows only persisted accepted gate state.
		state.begin_checkpoint("c3-theater-code");value=state.d.duplicate(true)
		value.items.temporaryTheaterTicket=true;value.native.selected_item="temporaryTheaterTicket"
		value.native.settings.reduced_motion=reduced;value.native.positions={"theater_interior:":{"x":842,"y":740}}
		await install(value);shell.world.player=Vector2(842,740);shell.world._sync_player()
		teleports.clear()
		var listener:Callable=func(p:Array):teleports.append(p)
		state.world_teleport.connect(listener)
		state.act("c3_target:theater_ticket_gate");shell.c3_narrative_host.tick(0,true)
		var session:RefCounted=shell.c3_narrative_host.current
		check(session!=null and state.d.theaterHunt.admitted,"same Main starts controller-owned admission")
		if session!=null:
			shell.c3_narrative_host.tick(100,true);shell.world._process(0)
			var admitted:Dictionary=state.d.duplicate(true)
			await install(admitted)
			state.act("c3_story_complete",session)
			check(teleports.is_empty(),"stale pre-load admission cannot teleport new world")
			check(shell.world.chapter3_layers.admission_pose(state.d).offset==Vector2.ZERO,"loaded admission does not replay nod")
			check(state.d.items.temporaryTheaterTicket and state.d.theaterHunt.admitted,"load retains ticket and earned admission")
			await install(value)
			check(not state.d.theaterHunt.admitted and shell.world.chapter3_layers.ticket_gate.openness==0,"rejected/reset state cannot retain accepted wings")
		state.world_teleport.disconnect(listener)
		check(shell.world==original_world,"all interruptions exercise one actual Main and World instance")
	await shell.shutdown();shell.queue_free();await frames()
	print("ANIMATION_BATCH_LIFECYCLE: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
