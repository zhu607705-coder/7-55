extends SceneTree
## Cancellation is navigation, never an alternative completion proof.
const Scanner=preload("res://scripts/games/identity_stamp.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:run.call_deferred()
func create_scan() -> Control:
	var scan:=Scanner.new();scan.size=Vector2(430,820);root.add_child(scan);scan.set_process(false)
	return scan
func advance(scan: Control,seconds: float) -> void:
	for i in range(ceili(seconds/.1)):scan._process(.1)
func run() -> void:
	root.size=Vector2i(430,820)
	for phase: String in ["scanning","ready","stamping","reduced_stamping"]:
		var scan:=create_scan()
		var cancelled_results: Array=[];var finished_results: Array=[]
		scan.cancelled.connect(func():cancelled_results.append(true))
		scan.finished.connect(func(result: Dictionary):finished_results.append(result))
		check(scan.return_button.visible and not scan.return_button.disabled,"return available during "+phase)
		check(scan.SHEET.encloses(scan.return_button.get_rect()),"return stays inside report")
		check(not scan.return_button.get_rect().intersects(scan.stamp.get_rect()),"navigation does not cover stamp action")
		check(scan.return_button.text=="返回图书馆","return destination is explicit")
		check(scan.return_button.get_meta("tactile_exempt",false),"paper navigation opts out of global button restyling")
		if phase!="scanning":advance(scan,.8)
		if phase in ["stamping","reduced_stamping"]:
			scan.reduced_motion=phase=="reduced_stamping"
			scan._stamp();scan._process(.1)
		if phase=="ready":
			var key:=InputEventKey.new();key.keycode=KEY_ESCAPE;key.pressed=true
			scan._unhandled_key_input(key)
		else:scan.return_button.pressed.emit()
		check(scan.closed and scan.return_button.disabled and scan.stamp.disabled,"cancel retires both controls: "+phase)
		scan._cancel();scan._stamp();advance(scan,2)
		check(cancelled_results.size()==1,"cancellation is one shot: "+phase)
		check(finished_results.is_empty() and not scan.issued,"cancelled animation cannot submit proof: "+phase)
		scan.free()
	# Exercise the actual native Button path rather than only its signal.
	var clicked:=create_scan();var click_results: Array=[]
	clicked.cancelled.connect(func():click_results.append(true))
	await process_frame
	var point: Vector2=clicked.return_button.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=point;root.push_input(motion,true)
	for pressed: bool in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=pressed
		root.push_input(event,true)
	check(clicked.closed and click_results.size()==1,"ordinary mouse press/release returns through native Button")
	clicked.free()
	var touched:=create_scan();var touch_results: Array=[]
	touched.cancelled.connect(func():touch_results.append(true))
	await process_frame
	var emulate_before:=Input.emulate_mouse_from_touch
	Input.emulate_mouse_from_touch=true
	point=touched.return_button.get_global_rect().get_center()
	var touch_down:=InputEventScreenTouch.new();touch_down.index=0;touch_down.position=point;touch_down.pressed=true
	Input.parse_input_event(touch_down);await process_frame
	var touch_cancel:=InputEventScreenTouch.new();touch_cancel.index=0;touch_cancel.position=point;touch_cancel.canceled=true
	Input.parse_input_event(touch_cancel);await process_frame
	check(not touched.closed and touch_results.is_empty(),"cancelled touch does not activate return")
	Input.parse_input_event(touch_down);await process_frame
	var second_release:=InputEventScreenTouch.new();second_release.index=1;second_release.position=point
	Input.parse_input_event(second_release);await process_frame
	check(not touched.closed and touched.return_touch==0,"second finger cannot release navigation owner")
	var outside:=InputEventScreenTouch.new();outside.index=0;outside.position=Vector2(8,8)
	Input.parse_input_event(outside);await process_frame
	check(not touched.closed and touched.return_touch==-1,"release outside cancels navigation gesture")
	Input.parse_input_event(touch_down);await process_frame
	touched._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	var old_release:=InputEventScreenTouch.new();old_release.index=0;old_release.position=point
	Input.parse_input_event(old_release);await process_frame
	check(not touched.closed and touch_results.is_empty(),"focus loss retires the old return gesture")
	for pressed: bool in [true,false]:
		var event:=InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=pressed
		Input.parse_input_event(event)
		await process_frame
	Input.emulate_mouse_from_touch=emulate_before
	check(touched.closed and touch_results.size()==1,"ordinary simulated touch returns once through native Button")
	touched.free()
	# A fresh entry must not inherit cancellation or bypass the scan gate.
	var reopened:=create_scan();var results: Array=[];var cancellations: Array=[]
	reopened.finished.connect(func(result: Dictionary):results.append(result))
	reopened.cancelled.connect(func():cancellations.append(true))
	check(not reopened.closed and reopened.stamp.disabled,"fresh entry starts with normal scan gate")
	advance(reopened,.8);reopened._stamp();advance(reopened,1.1)
	check(results.size()==1 and results[0].stamped and results[0].identityChecks==[false,false,false] and results[0].scanMs>=720,"ordinary completion payload retained")
	reopened._cancel();advance(reopened,1)
	check(cancellations.is_empty() and results.size()==1,"committed local result cannot also cancel or duplicate")
	for viewport: Vector2 in [Vector2(390,844),Vector2(844,390),Vector2(1280,720),Vector2(1152,760),Vector2(390,844)]:
		root.size=Vector2i(viewport)
		var display_scale:=minf((viewport.x-20)/430.0,(viewport.y-20)/820.0)
		reopened.scale=Vector2.ONE*display_scale
		reopened.position=(viewport-Vector2(430,820)*display_scale)/2
		reopened._layout_return()
		var bounds: Rect2=reopened.return_button.get_global_rect()
		check(bounds.size.x>=44 and bounds.size.y>=44,"return target reaches 44 display pixels at "+str(viewport))
		check(Rect2(Vector2.ZERO,viewport).encloses(bounds),"return stays fully within viewport at "+str(viewport))
		if viewport==Vector2(844,390):
			check(not reopened.get_global_rect().intersects(bounds),"short landscape navigation uses the free edge, not the report")
		else:check(reopened.SHEET.encloses(reopened.return_button.get_rect()),"portrait and desktop retain paper navigation after resize")
	for child: Node in reopened.get_children():
		if child is Label:check(child.get_minimum_size().x<=child.size.x and child.get_minimum_size().y<=child.size.y,"report text still fits")
	reopened.free()
	# The edge navigation must remain interactive outside the portrait parent.
	root.size=Vector2i(844,390)
	for device: String in ["mouse","touch"]:
		var landscape:=create_scan();var exits: Array=[]
		landscape.cancelled.connect(func():exits.append(true))
		landscape.scale=Vector2.ONE*(370.0/820.0)
		landscape.position=(Vector2(844,390)-landscape.size*landscape.scale)/2
		landscape._layout_return();await process_frame
		point=landscape.return_button.get_global_rect().get_center()
		motion=InputEventMouseMotion.new();motion.position=point;root.push_input(motion,true)
		Input.emulate_mouse_from_touch=true
		for pressed: bool in [true,false]:
			if device=="mouse":
				var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=pressed
				root.push_input(event,true)
			else:
				var event:=InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=pressed
				Input.parse_input_event(event);await process_frame
		Input.emulate_mouse_from_touch=emulate_before
		check(landscape.closed and exits.size()==1,"844 x 390 edge navigation accepts actual "+device+" events")
		landscape.free()
	print("LIBRARY_STAMP_RETURN: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
