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
func key(code: Key) -> void:
	for down: bool in [true,false]:
		var ev := InputEventKey.new();ev.keycode=code;ev.physical_keycode=code;ev.pressed=down;root.push_input(ev)
	await frames(2)
func named(id: String) -> Control: return shell.find_child(id,true,false)
func scan_width(node: Node, width: float) -> void:
	if node is Control and node.is_visible_in_tree():
		check(rect(node).size.x<=width+1,"contained node width "+str(node.name))
	for child in node.get_children(): scan_width(child,width)
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
		var before: Dictionary=state.d.duplicate(true)
		shell._show_journal();await frames(4)
		var hook := named("JournalObservationCompare")
		check(hook!=null,"journal exposes optional comparison at "+str(dim))
		await click(hook);await frames(4)
		var view := named("ObservationComparison")
		check(view!=null,"real pointer opens new comparison modal")
		check(not named("ObservationCompare").is_enabled() if named("ObservationCompare").has_method("is_enabled") else named("ObservationCompare").disabled,"incomplete comparison disabled")
		var one := named("ObservationChoice_item_waterDrop")
		check(one!=null and rect(one).size.y>=44,"actual option is readable target")
		await click(one)
		check(shell.observation_comparison_session.selected[0]=="item:waterDrop","pointer chooses first held card")
		var choose_scroll: ScrollContainer = named("ObservationComparison").get_parent().get_parent()
		choose_scroll.ensure_control_visible(named("ObservationChoice_item_headphone"));await frames(3)
		await click(named("ObservationChoice_item_headphone"))
		check(shell.observation_comparison_session.can_compare(),"pointer chooses second distinct card")
		check(rect(choose_scroll).encloses(rect(named("ObservationCompare"))),"compare stays visible after choosing two materials without scrolling to the list end")
		check(named("ObservationCompare").get_index()<named("ObservationChoices").get_index(),"compare precedes the growing choice list")
		await click(named("ObservationCompare"));await frames(3)
		check(shell.observation_comparison_session.stage=="comparison","comparison requires actual enabled button")
		check(named("ObservationBody0").text.contains("早八") and named("ObservationBody1").text.contains("凹槽"),"original earned descriptions are actually rendered")
		check(named("ObservationBody0").text.find("tower-lock")==-1,"no target ID printed")
		check(rect(shell.modal_panel).position.x>=0 and rect(shell.modal_panel).end.x<=dim.x+1,"modal contained horizontally")
		scan_width(view,dim.x-20)
		# Bottom controls can be reached through the existing modal ScrollContainer.
		var scroll: ScrollContainer = view.get_parent().get_parent()
		scroll.ensure_control_visible(named("ObservationSwap"));await frames(3)
		await click(named("ObservationSwap"));await frames(3)
		check(shell.observation_comparison_session.selected==["item:headphone","item:waterDrop"],"swap changes order through actual control")
		await key(KEY_ESCAPE)
		check(not is_instance_valid(shell.modal),"Escape closes comparison with existing modal route")
		check(state.d.items==before.items and state.d.flags==before.flags and state.d.digits==before.digits and state.d.actOne==before.actOne,"comparison cannot mutate chapter/items/facts")
		# Reopen preserves ephemeral selection but still filters any unavailable item.
		shell._show_journal();await frames(2);await click(named("JournalObservationCompare"));await frames(2)
		check(shell.observation_comparison_session.selected==["item:headphone","item:waterDrop"],"optional local selection preserved while game session remains")
		await key(KEY_ESCAPE)
		state.d.items.headphone=false;shell._refresh_observation_comparison()
		check(not shell.observation_comparison_session.can_compare(),"stale consumed card is removed on refresh")
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
