extends SceneTree
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
	print("COHESION_LIFECYCLE: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
