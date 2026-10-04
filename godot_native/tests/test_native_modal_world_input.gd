extends SceneTree
var shell: Control
var state: Node
var checks=[]
func _initialize() -> void: _run.call_deferred()
func frame(count: int=3) -> void:
	for i in count: await process_frame
func check(ok: bool,id: String,detail: Variant=null) -> void:
	checks.append({"id":id,"passed":ok,"detail":detail})
func _run() -> void:
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frame(5)
	state.begin_checkpoint("c3-canteen-drinks"); shell._refresh(); await frame(5)
	root.size=Vector2i(1440,900); shell.size=Vector2(1440,900); shell._show_world_mobile(); await frame()
	var world: Control=shell.world
	world.set_process(false)
	shell.c3_narrative_host.set_process(false); shell.c3_scene_host.set_process(false); shell.library_story_host.set_process(false)
	check(world.is_visible_in_tree() and shell.world_frame.visible,"world-ready",world.scene_id)
	# Use a measured collision-free cardinal direction before assessing a block.
	var start: Vector2=world.player
	var axis:=Vector2.ZERO
	for candidate in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
		if world.can_stand(start+candidate*8.25): axis=candidate; break
	world.touch_axis=axis; world._process(.05)
	check(world.player.distance_to(start)>1,"baseline-world-input-moves",{"before":[start.x,start.y],"after":[world.player.x,world.player.y]})
	world.player=start
	shell._modal_base("QA世界输入隔离"); await frame()
	world._process(.05)
	check(world.player.is_equal_approx(start),"generic-modal-blocks-held-movement")
	var original_zoom: float=world.zoom
	var wheel=InputEventMouseButton.new(); wheel.button_index=MOUSE_BUTTON_WHEEL_UP; wheel.pressed=true; wheel.position=Vector2(400,200)
	world._gui_input(wheel)
	check(is_equal_approx(world.zoom,original_zoom),"generic-modal-blocks-world-zoom")
	shell._close_modal(); await frame()
	shell._open_phone_document({"item_id":"bagNonPersonProof","source":"library_recovery"}); await frame()
	check(is_instance_valid(shell.phone_document),"phone-document-opens")
	world.player=start; world.touch_axis=axis; world._process(.05)
	check(world.player.is_equal_approx(start),"phone-document-blocks-held-movement",{"before":[start.x,start.y],"after":[world.player.x,world.player.y]})
	world._gui_input(wheel)
	check(is_equal_approx(world.zoom,original_zoom),"phone-document-blocks-world-zoom")
	shell._close_phone_document(); world.touch_axis=Vector2.ZERO
	await shell.shutdown(); shell.queue_free(); await frame()
	var path=OS.get_environment("UI_QA_REPORT"); if path.is_empty(): path="user://native-modal-world-input.json"
	var f=FileAccess.open(path,FileAccess.WRITE); f.store_string(JSON.stringify({"kind":"headless-input","graphical_acceptance":false,"checks":checks},"\t")); f.close()
	var failures=checks.filter(func(x): return not x.passed)
	print("UI_MODAL_WORLD_QA: ",checks.size()," checks; ",failures.size()," failures")
	for failure in failures: print("UI_QA_FAIL: ",JSON.stringify(failure))
	quit(1 if failures.size()>0 else 0)
