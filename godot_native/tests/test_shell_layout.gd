extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("_run")
func check(value: bool,label: String) -> void:
	if not value: failures+=1; push_error("TEST FAILED: "+label)
func _run() -> void:
	var state = root.get_node("State")
	state.developer_mode=true
	state.d=state.initial()
	var main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for screen in [Vector2(1440,900),Vector2(1280,720),Vector2(390,844),Vector2(430,860)]:
		main.size=screen
		main._layout()
		check(main.phone.size==Vector2(430,860),"phone logical430x860 at"+str(screen))
		check(is_equal_approx(main.phone.scale.x,main.phone.scale.y),"uniform phone scaling at"+str(screen))
		check(main.phone.size.x*main.phone.scale.x<=screen.x,"phone within screen width"+str(screen))
		check(main.phone.size.y*main.phone.scale.y<=screen.y,"phone within screen height"+str(screen))
		check(not main.world_frame.visible,"phone-only scene never leaks world surface")
	main.size=Vector2(1440,900)
	state.begin_checkpoint("c3-canteen-entry")
	main._refresh()
	main.size=Vector2(1440,900)
	main._layout()
	check(main.world_frame.visible and not main.phone.visible,"desktop dedicates the surface to the world")
	main.size=Vector2(390,844)
	main._layout()
	check(main.world_frame.visible and not main.phone.visible,"rotation preserves the chosen world surface")
	main._show_world_mobile()
	check(main.world_frame.visible and not main.phone.visible,"portrait can enter native world surface")
	check(is_equal_approx(main.world_frame.scale.x,main.world_frame.scale.y),"world uniformly scaled")
	main.mobile_world=false
	main._layout()
	check(main.phone.visible and not main.world_frame.visible,"return restores phone with world progress intact")
	await main.shutdown()
	main.queue_free()
	await process_frame
	print("Native shell layout tests: ","PASS" if failures==0 else "FAIL", " (",failures," failures)")
	quit(0 if failures==0 else 1)
