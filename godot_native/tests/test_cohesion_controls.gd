extends SceneTree
var Main
var checks := 0
var failures := 0
var state: Node
var shell: Control
func _initialize() -> void: run.call_deferred()
func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("COHESION CONTROLS: "+detail)
func frames(count: int=3) -> void:
	for i in range(count): await process_frame
func rect(node: Control) -> Rect2:
	var t := node.get_global_transform_with_canvas()
	return Rect2(t.origin,node.size*t.get_scale())
func click(node: Control) -> void:
	var point := rect(node).get_center()
	var move := InputEventMouseMotion.new(); move.position=point; root.push_input(move)
	for down: bool in [true,false]:
		var ev := InputEventMouseButton.new();ev.position=point;ev.button_index=MOUSE_BUTTON_LEFT;ev.pressed=down;root.push_input(ev)
	await frames(3)
func named(id: String) -> Control: return shell.find_child(id,true,false)
func run() -> void:
	Main=load("res://scripts/main.gd")
	state=root.get_node("State");state.developer_mode=true
	for dim: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812)]:
		root.size=dim
		state.d=state.initial();state.d.native.page="phone_home";state.d.currentScene="phone_home"
		state.d.items.waterDrop=true;state.d.items.headphone=true;state.d.flags.codeScattered=true
		state.d.flags.cardZeroTaken=true;state.d.digits.d1="0"
		for flag in ["plantLit","plantWatered","plantFertilized"]: state.d.flags[flag]=true
		shell=Main.new();shell.size=Vector2(dim);root.add_child(shell);await frames(6)
		# Ending recovery page builds its own context and invokes only original intent.
		state.d=state.initial();state.d.flags.checkinDone=true;state.d.native.page="ending";state.d.currentScene="ending"
		shell._refresh();await frames(5)
		var resume := named("EndingResumePage")
		check(resume!=null and resume.is_visible_in_tree(),"ordinary ending resume has dedicated visible page")
		check(not shell.phone_padding.visible,"full-page recovery does not reserve phantom status space")
		var continue_button := named("EndingResumeContinue")
		check(continue_button!=null and not continue_button.disabled,"legitimate unfinished ending exposes Continue")
		check(rect(continue_button).size.y>=44 and rect(continue_button).size.x>=44,"resume target above44px at "+str(dim))
		check(rect(shell.phone).encloses(rect(continue_button)),"resume button visible inside phone")
		check(not named("EndingResumeInstructions").visible,"instructions start collapsed")
		await click(named("EndingResumeReview"))
		check(named("EndingResumeInstructions").visible,"player deliberately reopens current controls")
		await click(named("EndingResumeReview"))
		check(not named("EndingResumeInstructions").visible,"instruction toggle collapses without side effects")
		await click(continue_button);await frames(5)
		check(is_instance_valid(shell.active_game),"Continue starts actual controller-issued game")
		if is_instance_valid(shell.active_game):
			check(shell.active_game.config.get("resume",false),"controller keeps safe resume flag")
			check(shell.active_game.phase=="blackout","authored blackout remains entry, no skip")
			check(shell.active_game.blocks==0 and shell.active_game.misses==0 and shell.active_game.hold_ms==0,"no fabricated catches or hold")
		check(state.d.actOne.phase=="prologue" and state.d.native.chapter==1,"no chapter completion from resume UI")
		await shell.shutdown();shell.queue_free();await frames(4)
	print("COHESION_CONTROLS: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
