extends "res://tests/test_chapter4_device_main.gd"
## Isolated checkpoints; real root key press/release dispatch through Main and GUI.
## This tests input ownership, not continuous earned chapter progression.
func run() -> void:
	state_node=root.get_node("State");state_node.developer_mode=true
	for view: Vector2i in [Vector2i(390,844),Vector2i(1440,900)]:
		await prepare(view,"c4-755-hall-clock")
		var c:Dictionary=state_node.d.chapter4
		c.phase="hall_clock_inspection";c.timeState="2245_opening";c.factIds=["external_time_rejected","hall_clock_inspected"];c.floor="A1";c.mode="light"
		state_node.d.native.c4_context="clock"
		for target:String in ["close_button"]:
			for code:int in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
				check(shell._open_chapter4_clock(state_node.d),"clock opens for focused return test")
				await frames()
				var panel=shell.modal
				check(panel.checkpoint.step==0,"fresh mechanism has no completed chain")
				panel.get(target).grab_focus();await frames(1)
				check(root.gui_get_focus_owner()==panel.get(target),"clock return has actual GUI focus")
				await press_key(code)
				check(shell.modal==null,"clock "+target+" activates with "+str(code))
				check(state_node.d.chapter4.timeState=="2245_opening","focused return never submits valid clock answer")
		check(shell._open_chapter4_clock(state_node.d),"clock reopens for unchanged shortcut")
		await frames()
		var panel=shell.modal
		panel.grab_focus()
		await press_key(KEY_ENTER)
		check(state_node.d.chapter4.timeState=="2245_opening" and shell.modal==panel,"bare Enter cannot bypass the unverified clock chain")
		await press_key(KEY_ESCAPE)
		await prepare(view,"c4-755-room204-1850")
		# Explicit source checkpoint seam: earn no progression via presentation.
		state_node.d.chapter4.floor="A2"
		if "misaligned_stair_solved" not in state_node.d.chapter4.factIds:state_node.d.chapter4.factIds.append("misaligned_stair_solved")
		shell._refresh();await frames()
		for code:int in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
			state_node.act("c4_elevator");await frames()
			panel=shell.modal
			check(is_instance_valid(panel) and panel.has_method("toggle_records"),"controller-issued floor selection opens")
			if not is_instance_valid(panel):continue
			panel.close_button.grab_focus();await frames(1)
			check(root.gui_get_focus_owner()==panel.close_button,"floor Leave has actual GUI focus")
			await press_key(code)
			check(shell.modal==null and not is_instance_valid(shell.world_effect),"floor Leave key closes instead of starting ride or reviewing records")
			check(state_node.d.chapter4.floor=="A2","floor Leave preserves current floor")
		state_node.act("c4_elevator");await frames();panel=shell.modal
		panel.buttons[panel.selected].grab_focus()
		await press_key(KEY_SPACE)
		check(panel.records.visible and shell.modal==panel,"Space still opens archived records away from Leave")
		await press_key(KEY_SPACE)
		check(not panel.records.visible,"Space still closes archived records")
		await press_key(KEY_ENTER)
		check(shell.modal==null and is_instance_valid(shell.world_effect),"Enter still requests controller-owned ride away from Leave")
	await shell.shutdown();shell.queue_free();await frames(3)
	print("C4_PANEL_KEYBOARD_FOCUS: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
