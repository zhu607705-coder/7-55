extends SceneTree
const SCENE=preload("res://scenes/raking_light.tscn")
var view: Control
var checks:=0
var failures:=0

func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS ",label)
	else: failures+=1; push_error("TEST FAILED: "+label)
func frames(n: int=2) -> void:
	for i: int in range(n): await process_frame
func key(code: int,pressed: bool=true,echo: bool=false,shift: bool=false) -> void:
	var event:=InputEventKey.new(); event.keycode=code; event.physical_keycode=code
	event.pressed=pressed; event.echo=echo; event.shift_pressed=shift
	Input.parse_input_event(event); await frames(); view._process(0)
func tap(code: int,shift: bool=false) -> void:
	await key(code,true,false,shift); await key(code,false,false,shift)
func repeat_key(code: int,count: int) -> void:
	await key(code)
	for i: int in range(count-1): await key(code,true,true)
	await key(code,false)
func touch(id: int,p: Vector2,pressed: bool) -> void:
	var event:=InputEventScreenTouch.new(); event.index=id; event.position=p; event.pressed=pressed
	Input.parse_input_event(event); await frames()
func arrangement() -> Array: return [view.model.paper_tilt,view.model.lamp_azimuth,view.model.lamp_elevation]
func observe(n: int=65) -> void:
	for i: int in range(n): view._process(1.0/30.0)
func snapshot(file: String) -> void:
	var folder:=OS.get_environment("RAKING_RENDER_ARTIFACT_DIR")
	if folder.is_empty() or DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	check(not image.is_empty() and image.save_png(folder.path_join(file))==OK,"Actual graphical keyboard frame saved: "+file)
func run() -> void:
	root.size=Vector2i(390,844); view=SCENE.instantiate(); root.add_child(view); await frames(5); view.set_process(false); view._process(0)
	await tap(KEY_TAB)
	check(view.keyboard_target=="paper","First Tab selects the physical paper without manipulating it")
	await snapshot("keyboard-paper-focus.png")
	for i: int in range(8): await tap(KEY_TAB)
	await tap(KEY_ENTER); await tap(KEY_SPACE)
	observe()
	check(not view.model.paper_moved and not view.model.lamp_moved and not view.model.completed,"Selection-only keyboard input cannot solve or earn movement flags")
	await key(KEY_LEFT)
	check(view.model.owners.get(view.KEYBOARD_OWNER)=="paper" and not view.keyboard_keys.is_empty(),"Arrow key acquires a dedicated model owner")
	await touch(0,view.paper_hit_point(),true)
	check(not view.model.owners.has(0),"Touch cannot steal a keyboard-held paper")
	await touch(1,view.lamp_hit_point(),true)
	check(view.model.owners.get(1)=="lamp" and view.model.owners.size()==2,"Touch lamp and keyboard paper retain independent owners")
	await key(KEY_LEFT,false)
	check(not view.model.owners.has(view.KEYBOARD_OWNER) and view.model.owners.get(1)=="lamp","Keyboard release leaves the other object's touch owner intact")
	await touch(0,view.paper_hit_point(),false); await touch(1,view.lamp_hit_point(),false)
	await touch(0,view.paper_hit_point(),true)
	var before:=arrangement()
	await key(KEY_UP)
	check(arrangement()==before and not view.model.owners.has(view.KEYBOARD_OWNER),"Keyboard cannot steal a touch-held object")
	await touch(0,view.paper_hit_point(),false)
	await key(KEY_UP,true,true)
	check(arrangement()==before and not view.model.owners.has(view.KEYBOARD_OWNER),"Rejected hold repeats cannot start after the touch owner releases")
	await key(KEY_UP,false)
	await key(KEY_RIGHT); await key(KEY_UP)
	check(view.keyboard_keys.size()==2 and view.model.owners.get(view.KEYBOARD_OWNER)=="paper","Two direction keys share one keyboard object owner")
	await key(KEY_RIGHT,false)
	check(view.model.owners.has(view.KEYBOARD_OWNER),"Releasing one direction retains the other held direction's owner")
	await tap(KEY_TAB)
	before=arrangement(); await key(KEY_UP,true,true)
	check(view.keyboard_target=="lamp" and view.keyboard_keys.is_empty() and arrangement()==before,"Changing keyboard target clears holds and ignores old repeats")
	await key(KEY_UP,false)
	await key(KEY_DOWN)
	view.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	before=arrangement(); await key(KEY_DOWN,true,true)
	check(view.model.suspended and view.keyboard_keys.is_empty() and view.model.owners.is_empty() and arrangement()==before,"Backgrounding clears keyboard owner and late repeats cannot manipulate")
	await key(KEY_DOWN,false); await tap(KEY_ENTER)
	check(not view.model.suspended and view.keyboard_target=="paper","Native Enter resumes from the focused secondary menu")
	await key(KEY_RIGHT); await tap(KEY_ESCAPE)
	check(view.model.suspended and view.keyboard_keys.is_empty() and view.model.owners.is_empty(),"Escape pauses and clears keyboard manipulation")
	await key(KEY_RIGHT,false); await tap(KEY_TAB); await tap(KEY_ENTER)
	check(not view.model.suspended and view.model.paper_tilt==Vector2.ZERO and view.model.lamp_elevation==80 and not view.model.paper_moved,"Native Tab and Enter retry without pointing or direct signal emission")
	await key(KEY_LEFT)
	root.size=Vector2i(844,390); await frames(5)
	before=arrangement(); await key(KEY_LEFT,true,true)
	check(view.model.suspended and view.keyboard_keys.is_empty() and arrangement()==before,"Resize cancels keyboard hold and prevents repeated motion")
	await key(KEY_LEFT,false); await tap(KEY_ENTER)
	check(not view.model.suspended and view.model.owners.is_empty(),"Keyboard can explicitly resume after rotation without resurrecting owners")
	root.size=Vector2i(390,844); await frames(5); await tap(KEY_TAB); await tap(KEY_ENTER)
	# The full solution below uses only real key events, no angle/flag assignments.
	await tap(KEY_TAB); await tap(KEY_TAB)
	check(view.keyboard_target=="history","Historical window is keyboard-selectable")
	before=arrangement()
	var old_history: Vector2=view.history_rect.position
	var recorded: Transform3D=view.recorded_world.lamp.global_transform
	await tap(KEY_RIGHT); await tap(KEY_DOWN)
	check(view.history_rect.position==old_history+Vector2(5,5) and arrangement()==before and view.recorded_world.lamp.global_transform==recorded,"History arrow movement changes neither current arrangement nor recorded lighting")
	await tap(KEY_UP); await tap(KEY_LEFT)
	await tap(KEY_TAB,true); await tap(KEY_TAB,true)
	check(view.keyboard_target=="paper","Shift Tab reverses object focus order")
	await repeat_key(KEY_UP,11); await repeat_key(KEY_LEFT,8)
	await tap(KEY_TAB)
	await repeat_key(KEY_LEFT,28); await repeat_key(KEY_DOWN,25)
	check(view.model.owners.is_empty() and view.model.paper_moved and view.model.lamp_moved,"Ordinary key press/repeat/release earns both physical movement flags and releases owner")
	print("RAKING_KEYBOARD_POSE ",arrangement()," metrics=",view.metrics)
	observe()
	check(view.model.completed and view.model.completion_count==1,"Keyboard-only paper and lamp adjustments complete through stable physical visibility")
	observe(40)
	check(view.current_world.door_hinge.rotation.y<deg_to_rad(-70),"Keyboard solution opens only the local visible preview door")
	await snapshot("keyboard-complete.png")
	await tap(KEY_TAB); await tap(KEY_SPACE)
	check(view.model.suspended and view.retry.visible,"Native Space opens the keyboard-reachable menu after completion")
	await tap(KEY_TAB); await tap(KEY_SPACE)
	check(not view.model.completed and not view.model.suspended and view.model.paper_tilt==Vector2.ZERO,"Keyboard can retry after completion without pointer input")
	await tap(KEY_RIGHT,true)
	check(is_equal_approx(view.model.paper_tilt.y,0.2),"Shift arrow applies a fine adjustment through the same model drag")
	check(view.find_children("*","Label",true,false).is_empty(),"Keyboard accessibility adds no permanent narrative panel")
	print("RAKING_KEYBOARD checks=",checks," failures=",failures," real_key_events=true renderer=",DisplayServer.get_name())
	view.queue_free(); await frames(); quit(1 if failures else 0)
