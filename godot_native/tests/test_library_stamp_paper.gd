extends SceneTree
const NativeUi=preload("res://scripts/ui/native_ui_theme.gd")
const Scanner=preload("res://scripts/games/identity_stamp.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var scan:=Scanner.new();scan.size=Vector2(430,820);scan.theme=NativeUi.make_theme(scan.font);root.add_child(scan);scan.set_process(false)
	var results: Array=[];scan.finished.connect(func(row: Dictionary):results.append(row))
	check(scan.stamp.disabled and scan.status.text=="核验中","scan still gates actual action")
	check(scan.backpack==JSON.parse_string(FileAccess.get_file_as_string("res://data/native/library-world-source.json")).backpack,"graphical bag comes from authored Library source geometry")
	check(scan.stamp_art.resource_path.ends_with("library_front_desk_stamp_v01.png"),"original stamp artwork retained")
	check(scan.PAPER==Color("eee7d5") and scan.INK==Color("29251e") and scan.RED==Color("8b3f35"),"source React paper palette")
	for row: Label in scan.result_labels:check(row.text=="核验中…","no false pass or premature verdict")
	for i in range(7):scan._process(.1)
	scan._stamp();check(results.is_empty() and scan.stamp.disabled,"700ms cannot issue proof")
	scan._process(.021)
	for row: Label in scan.result_labels:
		check(row.text=="未通过" and row.get_theme_color("font_color")==scan.RED,"all original failure verdicts are explicit")
	check(scan.status.text=="待盖章" and not scan.stamp.disabled,"ready result is not visually pre-stamped")
	check(scan.stamp.text=="盖章：非本人","original button action preserved")
	for child: Node in scan.get_children():
		if child is Control:
			check(scan.SHEET.encloses(child.get_rect()),"all native labels/button stay on paper")
	for property: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
		check(scan.stamp.get_theme_color(property)==Color("fffaf0"),"local readable ink overrides actual Main theme: "+property)
	for state: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		check(scan.stamp.has_theme_stylebox_override(state),"all real button states locally styled: "+state)
	check(scan.stamp.get_theme_stylebox("hover_pressed").bg_color==scan.stamp.get_theme_stylebox("pressed").bg_color,"held hover cannot revert to global cream style")
	for child: Node in scan.get_children():
		if child is Label:check(child.get_minimum_size().x<=child.size.x and child.get_minimum_size().y<=child.size.y,"paper text fits without clipping")
	check(scan.stamp.size.y>=64,"clear pointer/touch target")
	scan._stamp();scan._stamp()
	check(results.size()==1 and results[0].identityChecks==[false,false,false] and results[0].stamped,"unchanged one-shot authority payload")
	check(results[0].scanMs>=720,"unchanged minimum scan duration")
	scan.queue_free();await process_frame
	var state: Node=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	state.d.native.chapter=2;state.d.native.scene="library_interior";state.d.native.page="phone_home";state.d.ui.libraryFinalsPhase="evidence_gathering";state.d.actOne.phase="complete"
	var shell: Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
	await process_frame;await process_frame
	shell._open_game_now({"script":"res://scripts/games/identity_stamp.gd","viewport":[430,820]})
	for viewport: Vector2i in [Vector2i(390,844),Vector2i(1152,760)]:
		root.size=viewport;await process_frame;await process_frame
		var live: Control=shell.active_game
		check(Rect2(Vector2.ZERO,Vector2(viewport)).grow(1).encloses(live.get_global_rect()),"real Main keeps full paper game within viewport: "+str(viewport))
		for child: Node in live.get_children():
			if child is Label:check(child.get_minimum_size().x<=child.size.x and child.get_minimum_size().y<=child.size.y,"real narrow/wide paper labels fit: "+str(viewport))
	shell.queue_free();await process_frame
	print("LIBRARY_STAMP_PAPER: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
