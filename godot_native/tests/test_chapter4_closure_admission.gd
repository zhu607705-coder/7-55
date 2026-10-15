extends "res://tests/test_chapter4_device_main.gd"
var requests:=0
func run()->void:
	state_node=root.get_node("State");state_node.developer_mode=true
	state_node.game_requested.connect(func(config):
		if config.get("kind","")=="star_lamp_closure":requests+=1
	)
	for dimensions in [Vector2i(390,844),Vector2i(1180,812)]:
		requests=0;await prepare(dimensions,"c4-755-closure")
		var facts:Dictionary=state_node.d.chapter4.duplicate(true)
		check(is_instance_valid(shell.world_effect),"Ordinary eligible startup owns one door prelude at "+str(dimensions))
		check(requests==1,"Startup issues exactly one closure session")
		var door=shell.world_effect
		for i in 3:shell._resume_world_activity()
		shell._show_world_mobile();await frames(4)
		check(requests==1 and shell.world_effect==door,"Repeated Return/admission retains same door and token")
		check(state_node.d.chapter4==facts,"Opening presentation cannot grant facts")
		if is_instance_valid(door):
			door.set_process(false)
			for i in 31:door._process(.05)
			await frames(3)
			var activity=shell.active_game
			check(is_instance_valid(activity) and activity.kind=="star_lamp_closure","Original door owns its single handoff")
			if is_instance_valid(activity):
				activity.set_process(false)
				for i in 3:shell._resume_world_activity()
				shell._layout();shell._refresh();await frames(3)
				check(requests==1 and shell.active_game==activity,"Refresh/resize/Return never replace live question owner")
		await prepare(dimensions,"c4-755-checkin");requests=0
		state_node.act("c4_checkin_card");await frames(2)
		check(requests==0 and shell.world_effect==null,"Partial check-in does not admit closure")
		var previous:Dictionary=state_node.d.duplicate(true)
		state_node.act("c4_checkin_paper")
		# Repeated delayed notifications are still the same accepted transition.
		for i in 3:shell._on_controller_page_intent("c4_checkin_paper",previous,state_node.d,{"page":"c4_lamp"})
		await frames(5)
		check(requests==1 and is_instance_valid(shell.world_effect),"Automatic check-in + delayed + Return paths issue one nonce only")
		var prior=shell.world_effect;shell._cancel_world_effect();await frames(2)
		check(not is_instance_valid(prior) and shell.active_game==null,"Cancelled prelude does not later mount questions")
		shell._show_world_mobile();await frames(3)
		check(requests==2 and is_instance_valid(shell.world_effect),"Explicit Return after cancellation creates one fresh session")
		var pending_door=shell.world_effect
		state_node.d.chapter4.phase="complete";state_node.d.chapter4.completed=true
		if is_instance_valid(pending_door):pending_door._process(.05)
		await frames(2);shell._resume_world_activity();await frames(2)
		check(not is_instance_valid(pending_door) and shell.active_game==null and requests==2,"Completed/changed context retires old prelude without new admission")
	# UI owners must keep their existing blocking contract.
	await prepare(Vector2i(390,844),"c4-755-checkin");requests=0
	state_node.begin_checkpoint("c4-755-closure")
	var blocker:=PanelContainer.new();shell.add_child(blocker);shell.modal=blocker
	shell._resume_world_activity();await frames(3);check(requests==0,"Child modal blocks deferred admission")
	shell._close_modal();state_node.d.chapter4.roomId="a1_lobby";shell._resume_world_activity();await frames(3);check(requests==0,"Wrong room cannot auto-admit ending")
	await shell.shutdown();shell.queue_free();await frames(3)
	print("CHAPTER4_CLOSURE_ADMISSION ",checks," checks; ",failures," failures");quit(1 if failures else 0)
