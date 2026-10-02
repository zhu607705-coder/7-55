extends SceneTree
var Main
const Pages = preload("res://scripts/ui/phone_pages.gd")
const Chapter = preload("res://scripts/chapters/chapter1_2.gd")
var checks := 0
var failures := 0
var signals_seen: Array = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("COHESION LIFECYCLE: "+label)
func frames(n: int=3) -> void:
	for i in range(n): await process_frame
func run() -> void:
	Main=load("res://scripts/main.gd")
	var state: Node=root.get_node("State");state.developer_mode=true
	var p=Pages.new();var c=Chapter.new();var holder:=Control.new();holder.size=Vector2(424,854);root.add_child(holder)
	var s: Dictionary=state.initial();s.native.page="ending";s.currentScene="ending"
	p.action_requested.connect(func(id,value): signals_seen.append([id,value]))
	var control: Control=p.build("ending",c.view("ending",s),s);holder.add_child(control);await frames()
	var button: Button=control.find_child("EndingResumeContinue",true,false)
	check(button.disabled,"invalid unearned ending cannot continue")
	check(control.get_meta("handles_all_actions",false),"custom ending suppresses fallback action duplication")
	check(control.get_meta("handled_action_ids",[]).count("c1_resume_ending")==1,"one declared controller intent owner")
	control.queue_free();await frames()
	s.flags.checkinDone=true
	control=p.build("ending",c.view("ending",s),s);holder.add_child(control);await frames()
	button=control.find_child("EndingResumeContinue",true,false)
	button.pressed.emit();button.pressed.emit()
	check(signals_seen.size()==1 and signals_seen[0][0]=="c1_resume_ending","double activation emits once per live page")
	check(signals_seen[0][1]==null,"no fabricated result/proof supplied by continuation UI")
	check(s.actOne.phase=="prologue" and s.native.chapter==1,"page never writes story phase")
	control.queue_free();holder.queue_free();await frames()
	# No comparison entrance for a clean start, no stray retained cards after reset.
	state.d=state.initial();state.d.native.page="phone_home";state.d.currentScene="phone_home"
	var shell=Main.new();root.add_child(shell);await frames(5)
	shell._show_journal();await frames()
	check(shell.find_child("JournalObservationCompare",true,false)==null,"fresh journal has no misleading empty new activity")
	shell._close_modal()
	state.d.items.wateredHeadphone=true;state.d.items.fertilizer=true
	shell._show_journal();await frames()
	check(shell.find_child("JournalObservationCompare",true,false)!=null,"valid held pair enables optional activity")
	shell._show_observation_comparison();await frames()
	var m: RefCounted=shell.observation_comparison_session
	m.choose("item:wateredHeadphone");m.choose("item:fertilizer");m.compare()
	var saved: Dictionary=state.d.duplicate(true)
	shell._close_modal();shell._reset_runtime_presentations();await frames()
	check(m.selected==["",""] and m.stage=="selection","story reset clears optional transient selections")
	check(state.d.items==saved.items and state.d.flags==saved.flags,"comparison reset cannot modify gameplay items/facts")
	# Long source paper stays present and selectable in both compact viewports.
	for dim: Vector2i in [Vector2i(390,844),Vector2i(430,860)]:
		root.size=dim;shell.size=Vector2(dim);shell._layout()
		state.d=state.initial();state.d.native.chapter=2;state.d.native.page="phone_home";state.d.actOne.phase="complete"
		state.d.ui.libraryFinalsPuzzle.archivedRuleRead=true;state.d.ui.libraryFinalsPuzzle.nonPersonProofStamped=true
		shell._refresh_observation_comparison();m=shell.observation_comparison_session;m.clear()
		check(m.choose("archive:archivedLeaveRule") and m.choose("archive:bagNonPersonProof") and m.compare(),"consumed proofs can be chosen without regrant at "+str(dim))
		shell._show_observation_comparison();await frames(5)
		var a: Label=shell.find_child("ObservationBody0",true,false);var b: Label=shell.find_child("ObservationBody1",true,false)
		check(a!=null and b!=null,"two long documents actually rendered")
		check(a.text.contains("三类证明") and b.text.contains("姓名"),"document body and field text preserved")
		for label: Label in [a,b]:
			check(label.autowrap_mode==TextServer.AUTOWRAP_WORD_SMART,"long proof text wraps")
			check(label.size.x<=dim.x-40,"proof card width remains bounded")
			check(label.get_line_count()>1 and label.size.y>=label.get_line_height(),"proof card expands vertically")
		var view: Control=shell.find_child("ObservationComparison",true,false)
		var scroll: ScrollContainer=view.get_parent().get_parent()
		var back: Button=shell.find_child("ObservationReturn",true,false)
		scroll.ensure_control_visible(back);await frames(4)
		var t:=back.get_global_transform_with_canvas();var screen:=Rect2(t.origin,back.size*t.get_scale())
		check(screen.position.y>=0 and screen.end.y<=dim.y,"return remains reachable by ordinary scrolling")
		var old: Dictionary=state.d.duplicate(true)
		back.pressed.emit();await frames()
		check(not is_instance_valid(shell.modal),"return closes back to game without route side effects")
		check(state.d==old,"close never writes a proof/item/quest fact")
	await shell.shutdown();shell.queue_free();await frames(4)
	print("COHESION_LIFECYCLE: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
