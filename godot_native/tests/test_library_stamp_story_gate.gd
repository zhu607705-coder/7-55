extends SceneTree
const Library=preload("res://scripts/chapters/library022.gd")
const Layer=preload("res://scripts/ui/library_world_layers.gd")
const Host=preload("res://scripts/presentation/library_story_host.gd")
var checks: int=0
var failures: int=0
var s: Dictionary
var library: RefCounted
var layer: RefCounted
var host: Control
var surface_visible: bool=true
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(label)
func _initialize() -> void:run.call_deferred()
func prepare(reduced: bool=false) -> void:
	if is_instance_valid(host):host.free()
	s=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":2,"scene":"library_interior","mode":"light","page":"phone_home","settings":{"reduced_motion":reduced}}
	s.actOne.phase="complete";s.ui.libraryFinalsPhase="evidence_gathering"
	s.ui.libraryFinalsPuzzle.itemReportGenerated=true;s.ui.libraryFinalsPuzzle.lostFoundStage="ready";s.items.itemRecognitionReport=true
	library=Library.new();layer=Layer.new();layer.sync(s);surface_visible=true
	host=Host.new();root.add_child(host)
	host.setup(func():return s,func(ms: float):return library.story_session(s,ms),func(id: String,v: Variant):return library.dispatch(s,id,v),Callable(),func():return {"native":{"host":{"library_stamp_active":surface_visible and layer.stamp_animation_active(s)}}})
	host.set_process(false)
	library.dispatch(s,"lib_scan",null)
	library.dispatch(s,"lib_scan_result",{"scanMs":720,"identityChecks":[false,false,false],"stamped":true});layer.sync(s)
func run() -> void:
	for mode: String in ["normal","reduced","slow"]:
		prepare(mode=="reduced")
		var steps: int=0
		var elapsed: float=0
		while host.current==null and steps<150:
			var ms: float=200 if mode=="slow" else 20
			layer.tick(ms/1000,s);host.tick(ms);elapsed+=ms;steps+=1
			if layer.stamp_ms>=0:check(host.current==null and not host.view.visible,"dialogue cannot obscure unfinished sheet: "+mode)
		check(host.current!=null and layer.stamp_ms==-1,"actual completion releases dialogue even at low FPS: "+mode)
		check(elapsed<6100,"low FPS resolves without an unbounded wait: "+mode)
		check(elapsed>=1480 if mode=="normal" else elapsed>=900,"retained controller delay remains minimum: "+mode)
		check(s.items.bagNonPersonProof and not s.items.itemRecognitionReport,"original controller owns consumed report and proof: "+mode)
		var facts: String=JSON.stringify(s.items)
		library.dispatch(s,"lib_scan_result",{"scanMs":720,"identityChecks":[false,false,false],"stamped":true})
		check(JSON.stringify(s.items)==facts,"result retry cannot duplicate evidence: "+mode)
	for kind: String in ["hidden","scene","state"]:
		prepare()
		# Provider reaches its 900ms issue boundary while slow visuals are at450ms.
		for i in range(9):layer.tick(.05,s);host.tick(100)
		check(host.current==null and layer.stamp_ms>=0,"interruption starts inside withheld presentation: "+kind)
		var facts: String=JSON.stringify(s.items)
		if kind=="hidden":surface_visible=false
		elif kind=="scene":s.native.scene="campus_bootstrap"
		else:s=s.duplicate(true)
		host.tick(0)
		check(not host._awaiting_stamp(library.story_session(s)),"exit/replacement releases local gate: "+kind)
		check(JSON.stringify(s.items)==facts,"exit never changes awarded evidence: "+kind)
		if kind!="state":check(host.current!=null,"ordinary already-issued dialogue continues after local exit: "+kind)
		layer.sync(s);s.native.scene="library_interior";layer.sync(s)
		if kind!="hidden":check(layer.stamp_ms==-1,"reentry does not replay consumed paper: "+kind)
	host.free()
	# The real shell exports a presentation-only flag, bound to exact state and visibility.
	var state: Node=root.get_node("State");state.developer_mode=true;state.d=s
	var shell: Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
	await process_frame;await process_frame
	shell._show_world_mobile();shell.world.library_layers.sync(state.d,true);shell.world.library_layers.stamp_ms=300
	check(shell._library_stamp_presentation_active(),"real visible processing world exports active gate")
	shell.world_frame.hide();check(not shell._library_stamp_presentation_active(),"hidden real frame releases gate")
	shell.world_frame.show();shell.world.capture_mode=true;check(not shell._library_stamp_presentation_active(),"capture mode cannot leave a stopped animation wait")
	shell.world.capture_mode=false;shell.world.set_process(false);check(not shell._library_stamp_presentation_active(),"disabled world releases gate")
	shell.world.set_process(true);state.d=state.d.duplicate(true);check(not shell._library_stamp_presentation_active(),"replaced real state cannot retain old gate")
	shell.queue_free();await process_frame
	print("LIBRARY_STAMP_STORY_GATE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
