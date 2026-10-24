extends SceneTree
const View=preload("res://scripts/games/theater_shadow_rehearsal.gd")
const Proof=preload("res://tests/helpers/theater_rehearsal_proof.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("THEATER_REHEARSAL_UI: "+label)
func mouse(position: Vector2,pressed: bool) -> void:
	var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=position;Input.parse_input_event(event)
func motion(position: Vector2) -> void:
	var event=InputEventMouseMotion.new();event.position=position;event.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(event)
func key(code: Key,pressed: bool) -> void:
	var event=InputEventKey.new();event.keycode=code;event.pressed=pressed;Input.parse_input_event(event)
func touch(index: int,position: Vector2,pressed: bool) -> void:
	var event=InputEventScreenTouch.new();event.index=index;event.position=position;event.pressed=pressed;Input.parse_input_event(event);Input.flush_buffered_events()
func drag(index: int,position: Vector2) -> void:
	var event=InputEventScreenDrag.new();event.index=index;event.position=position;Input.parse_input_event(event);Input.flush_buffered_events()
func point(view: Control,id: String) -> Vector2:
	for object: Dictionary in view.state.objects:
		if object.id==id:return view.field.position+view.prop_rect(object).get_center()/view.LOGICAL*view.field.size
	return Vector2.ZERO
func run() -> void:
	var view=View.new();view.setup({"session":{"nonce":"view-test"}});root.add_child(view);await process_frame
	check(view.help_open and view.help_panel.visible and view.help_close.text=="开始排练" and view.model.actions.is_empty(),"entry offers a story introduction and complete controls before recording input")
	view.help_close.pressed.emit();check(not view.help_open and not view.help_panel.visible,"start action returns focus to actual stage")
	for size2: Vector2 in [Vector2(1280,720),Vector2(1440,900),Vector2(390,844)]:
		view.configure_activity_layout(size2,size2.x<size2.y);await process_frame
		view._intro();await process_frame;await process_frame
		var intro_button: Rect2=Rect2(view.get_global_transform_with_canvas().affine_inverse()*view.help_close.get_global_transform_with_canvas().origin,view.help_close.size)
		check(Rect2(Vector2.ZERO,size2).encloses(intro_button),"real introduction button stays reachable after first text layout at "+str(size2))
		check(view.help_panel.get_global_rect().encloses(view.help_close.get_global_rect()),"reading sheet keeps its own physical close action reachable at "+str(size2))
		view._close_help()
		check(absf(view.field.size.x/view.field.size.y-16.0/9)<0.001,"stage projection stays uniform at "+str(size2))
		check(view.title_label.get_parent()==view.stage_hud and view.status_label.get_parent()==view.stage_hud,"Local rehearsal context shares the physical stage transform")
		check(view.field.encloses(view.status_label.get_global_rect()),"Complete current-beat text stays on the stage-mounted cue sheet")
		for button: Button in view.controls.values():
			if button.visible:check(button.position.x>=0 and button.position.y>=0 and button.position.x+button.size.x<=size2.x+1 and button.position.y+button.size.y<=size2.y+1,"visible control remains inside available viewport: "+button.name)
		check(not view.controls.RehearsalTry.visible and not view.controls.RehearsalNext.visible,"stage trials and curtain changes use the physical lamp without a duplicate bottom action")
	view.configure_activity_layout(Vector2(1280,720),false);await process_frame
	view._intro();view._focus_out();view._close_help()
	check(view.paused and view.menu_open and view.menu_panel.visible,"Closing a reading sheet after focus loss exposes explicit resume instead of an inert stage")
	view._close_menu();check(not view.paused and not view.menu_open,"The visible resume action restores stage input after interrupted reading")
	var rapid_before: float=float(view.state.objects[0].x)
	key(KEY_RIGHT,true);key(KEY_RIGHT,false);await process_frame
	check(is_equal_approx(float(view.state.objects[0].x),rapid_before+0.12),"a complete short key press in one rendering frame moves exactly once")
	view._undo()
	var before_x: float=float(view.state.objects[0].x);var start: Vector2=point(view,"left_fan")
	mouse(start,true);motion(start+Vector2(30,0));mouse(start+Vector2(30,0),false);await process_frame
	check(float(view.state.objects[0].x)>before_x,"real mouse drag moves the physical fan rack")
	check(view.drag_id.is_empty() and view.pointer_id==-99,"release clears drag ownership")
	key(KEY_Z,true);key(KEY_Z,false);await process_frame
	check(is_equal_approx(float(view.state.objects[0].x),before_x),"keyboard undo restores the prior physical pose")
	view._help();var before: Dictionary=view.model.snapshot();key(KEY_RIGHT,true);await create_timer(.12).timeout;key(KEY_RIGHT,false)
	check(view.model.snapshot()==before and view.help_panel.visible,"reading freezes keyboard motion and penalties")
	view._close_help();view._pause();before=view.model.snapshot();key(KEY_RIGHT,true);await create_timer(.12).timeout;key(KEY_RIGHT,false)
	check(view.model.snapshot()==before and view.paused,"pause keeps the stage unchanged until explicit resume")
	view._pause();view.configure_activity_layout(Vector2(390,844),true);await process_frame
	touch(5,Vector2(2,2),true);touch(5,Vector2(2,2),false);await process_frame
	check(view.rotation_label.visible and view.controls.RehearsalExit.visible and not view.controls.RehearsalTry.visible,"portrait fallback explains rotation and retains a real Return action")
	before=view.model.snapshot();start=point(view,"left_fan");touch(5,start,true);drag(5,start+Vector2(25,0));touch(5,start+Vector2(25,0),false);await process_frame
	check(view.model.snapshot()==before,"portrait rotation fallback does not manipulate a miniature stage")
	view.configure_activity_layout(Vector2(844,390),false);await process_frame
	check(view.field.size.x>640 and absf(view.field.size.x/view.field.size.y-16.0/9)<.001 and not view.rotation_label.visible,"touch landscape maximizes the same stage instead of reserving old bottom controls")
	for button:Button in view.controls.values():check(not button.visible,"touch landscape has no permanent operation key "+button.name)
	start=point(view,"left_fan");before_x=float(view.state.objects[0].x)
	touch(5,start,true);drag(5,start+Vector2(18,0));touch(5,start+Vector2(18,0),false);await process_frame
	check(float(view.state.objects[0].x)>before_x and view.drag_id.is_empty(),"real finger directly drags the enlarged physical fan")
	var p1:Vector2=view.field.position+Vector2(18,18);var p2:Vector2=p1+Vector2(42,0)
	touch(1,p1,true);touch(2,p2,true);touch(1,p1,false);touch(2,p2,false);await process_frame
	check(is_equal_approx(float(view.state.objects[0].x),before_x),"two-finger tap undoes the entire previous real drag once")
	start=point(view,"left_fan");touch(5,start,true);await create_timer(.68).timeout;touch(5,start,false);await process_frame
	check(view.help_open and view.state.hintTier==1 and view.help_panel.visible,"holding a real prop requests the first observation layer")
	view._close_help();touch(1,p1,true);touch(2,p2,true);await create_timer(.68).timeout;touch(1,p1,false);touch(2,p2,false);await process_frame
	check(view.menu_open and view.menu_panel.visible and not view.paused,"two-finger hold opens the temporary paper rehearsal sheet")
	for button:Button in view.menu_controls.values():check(button.get_global_rect().size.y>=44 and Rect2(Vector2.ZERO,view.size).encloses(button.get_global_rect()),"paper menu exposes a bounded real action "+button.name)
	view.menu_controls.RehearsalMenuPause.pressed.emit();check(view.paused and view.menu_open,"paper Pause leaves the stage explicitly paused")
	view.menu_controls.RehearsalMenuClose.pressed.emit();check(not view.paused and not view.menu_open,"paper Return resumes explicitly and clears the gesture")
	start=point(view,"left_fan");touch(5,start,true);drag(5,start+Vector2(20,0));before=view.model.snapshot();view.configure_activity_layout(Vector2(900,430),false);drag(5,start+Vector2(60,0));touch(5,start,false);await process_frame
	check(view.model.snapshot()==before and view.fingers.is_empty() and view.drag_id.is_empty(),"resize cancels a live touch owner without moving at stale coordinates")
	view.configure_activity_layout(Vector2(844,390),false);await process_frame
	start=point(view,"left_fan");touch(5,start,true);drag(5,start+Vector2(20,0));touch(1,p1,true);drag(1,p1+Vector2(30,0));before=view.model.snapshot();touch(1,p1+Vector2(30,0),false);touch(5,start+Vector2(20,0),false);await process_frame
	check(view.model.snapshot()==before and not view.menu_open,"moving a multi-finger gesture cannot become an undo or accidental menu")
	var lamp:Vector2=view.field.position+Vector2(480,475)/view.LOGICAL*view.field.size
	touch(5,lamp,true);touch(5,lamp,false);await process_frame
	check(view.state.attempts>0 and view.state.screen=="playing","tapping the actual stage lamp runs an ordinary recoverable trial")
	var after_touch: Dictionary=view.model.snapshot();mouse(start,true);motion(start+Vector2(35,0));mouse(start,false);await process_frame
	check(view.model.snapshot()==after_touch,"synthetic mouse does not apply the same finger gesture twice")
	view.last_touch_ms=-1000;start=point(view,"left_fan");mouse(start,true);await process_frame;check(view.pointer_id==-1,"desktop pointer can own a later genuine gesture")
	touch(7,start,true);drag(7,start-Vector2(10,0));touch(7,start,false);await process_frame
	check(view.pointer_id==-99 and view.drag_id.is_empty(),"real finger supersedes synthetic mouse ownership and releases cleanly")
	view.last_touch_ms=-1000;var attempt_count:int=int(view.state.attempts);mouse(lamp,true);mouse(lamp,false);await process_frame
	check(int(view.state.attempts)==attempt_count+1,"a later physical mouse can operate the same visible lamp on a hybrid touch surface")
	view._focus_out();check(view.paused and view.menu_open and view.held.is_empty() and view.drag_id.is_empty(),"touch focus loss clears inputs and exposes explicit paper-menu resume")
	view._close_menu();view.model=load("res://scripts/games/theater_shadow_rehearsal_model.gd").new();view._refresh()
	for stage in 3:
		check(Proof.solve_round(view.model),"view uses the same deterministic physical model in stage "+str(stage));view._refresh()
		if stage<2:view._continue_stage()
	var emitted: Array=[];view.completed.connect(func(value: Dictionary):emitted.append(value))
	view._try_stage();view._try_stage()
	check(emitted.size()==1 and emitted[0].session.nonce=="view-test" and not load("res://scripts/games/theater_shadow_rehearsal_model.gd").replay(emitted[0]).is_empty(),"completion emits one exact session-bound legal replay")
	view.queue_free();await process_frame
	print("THEATER_REHEARSAL_UI: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
