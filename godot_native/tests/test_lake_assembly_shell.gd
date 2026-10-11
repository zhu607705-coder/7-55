extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("ASSEMBLY SHELL: "+label)
func frames(n: int=3) -> void:
	for i in n:await process_frame
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var state: Node=root.get_node("State");state.developer_mode=true
	var shell: Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	for dim: Vector2i in [Vector2i(390,844),Vector2i(1180,812)]:
		for phone: bool in [false,true]:
			root.size=dim;shell.size=dim;state.begin_checkpoint("c3-qizhen-paper");shell._refresh();shell._show_world_mobile();await frames()
			if phone:shell._show_phone_surface();await frames()
			var was_world: bool=shell.world_frame.visible
			var result: Dictionary=state.act("c3_lake_combine")
			await frames()
			check(result.get("world_effect",{}).get("kind")=="lake_rod_assembly","real action creates presentation")
			check(is_instance_valid(shell.world_effect) and shell.world_effect.get_parent()==shell,"same overlay is visible on either surface")
			check(shell.world_effect.size.is_equal_approx(shell.size),"overlay fills responsive shell")
			check(shell.world_frame.visible==was_world,"craft does not navigate away from inventory surface")
			check(shell._surface_navigation_blocked(),"background input blocked while assembly plays")
			var kayak_tick: int=shell.world.kayak.tick;shell.world._process(.05)
			check(shell.world.kayak.tick==kayak_tick,"world movement paused beneath close-up")
			var after: String=JSON.stringify([state.d.items,state.d.qizhenLake])
			var repeat: Dictionary=state.act("c3_lake_combine")
			check(not repeat.has("world_effect"),"duplicate click has no second animation")
			check(JSON.stringify([state.d.items,state.d.qizhenLake])==after,"duplicate click does not duplicate reward")
			var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;Input.parse_input_event(escape);Input.flush_buffered_events();await frames()
			check(not is_instance_valid(shell.world_effect) and state.d.items.magneticFishingRod,"interruption settles committed inventory")
			check(not shell._surface_navigation_blocked(),"cancel releases input lock")
	# Real serialization during an animation recovers the completed controller transaction.
	state.begin_checkpoint("c3-qizhen-paper");shell._refresh();shell._show_world_mobile();state.act("c3_lake_combine");await frames()
	check(state.export_save("user://assembly-interrupt.json")==OK,"mid-animation save export")
	var imported: Dictionary=state.import_save("user://assembly-interrupt.json");await frames()
	check(imported.get("ok",false) and state.d.items.magneticFishingRod and state.d.qizhenLake.magneticRodCombined,"real import preserves exact accepted result")
	check(not is_instance_valid(shell.world_effect),"reload does not replay stale assembly")
	check(not state.act("c3_lake_combine").has("world_effect"),"reloaded completed recipe cannot replay")
	await shell.shutdown();shell.free();await frames()
	print("LAKE_ASSEMBLY_SHELL: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
