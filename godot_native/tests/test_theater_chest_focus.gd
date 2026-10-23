extends SceneTree
## Isolated source-phase fixture: real Main, source scanner transaction, camera,
## mouse/touch Controls. This is not an earned campaign or physical-device run.
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const STAND=Vector2(406,218)
var state: Node
var shell: Control
var checks:=0
var failures:=0
var accepted_scans:=0
var actions: Array[String]=[]
var captures: Array=[]
var manual_capture_index:=0

func _initialize() -> void:run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("THEATER CHEST: "+label)
func frames(count:=4) -> void:
	for index in count:await process_frame
func key(code: Key, down: bool) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
	Input.parse_input_event(event);Input.flush_buffered_events()
func tap(control: Control, touch:=false, local_point:=Vector2.INF) -> void:
	check(is_instance_valid(control) and control.is_visible_in_tree(),"input targets a visible chest part")
	if not is_instance_valid(control):return
	if local_point==Vector2.INF and control.get("part_id")!=null:
		var best_distance:=INF
		var panel: Control=control.owner_panel
		for x: int in range(1,20):
			for y: int in range(1,20):
				var candidate:=Vector2(control.size.x*x/20.0,control.size.y*y/20.0)
				if panel.pick_part(control.position+candidate)!=control.part_id:continue
				var distance:=candidate.distance_squared_to(control.size*.5)
				if distance<best_distance:best_distance=distance;local_point=candidate
		check(local_point!=Vector2.INF,"stacked part has an exposed, correctly owned input point: "+str(control.part_id))
	var point: Vector2=control.get_global_transform_with_canvas()*(control.size*.5 if local_point==Vector2.INF else local_point)
	for down: bool in [true,false]:
		if touch:
			var event:=InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=down
			Input.parse_input_event(event)
		else:
			var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
			Input.parse_input_event(event)
		Input.flush_buffered_events()
	await frames()
func until(predicate: Callable, label: String, timeout_ms:=4000) -> bool:
	var deadline:=Time.get_ticks_msec()+timeout_ms
	while not predicate.call() and Time.get_ticks_msec()<deadline:await process_frame
	var completed: bool=predicate.call();check(completed,label);return completed

func panel_valid() -> bool:
	return is_instance_valid(shell) and is_instance_valid(shell.c3_device_panel)

func require_panel(expected: Control) -> bool:
	var valid: bool=panel_valid() and is_instance_valid(expected) and shell.c3_device_panel==expected
	if not valid:check(false,"mounted inspection disappeared during mechanism input")
	return valid

func until_panel(predicate: Callable, label: String, timeout_ms:=4000) -> bool:
	# A close/context change may free the panel during any frame we await.
	# Preserve the failed assertion instead of repeatedly dereferencing nil.
	return await until(func():return panel_valid() and predicate.call(),label,timeout_ms)

func fixture(dim: Vector2i, reduced:=false, point:=STAND) -> void:
	await teardown();root.size=dim
	if DisplayServer.get_name()!="headless":root.grab_focus();await frames(3)
	state.d=state.initial();state.developer_mode=true;state.modules[1]=Chapter.new()
	state.d.native.chapter=3;state.d.native.scene="theater_interior";state.d.native.page="c3_theater";state.d.native.mode="light"
	state.d.runtimeMode="rpg";state.d.rpgScene="theater_interior";state.d.rpgCheckpoint="theater_stage"
	state.d.theaterHunt.active=true;state.d.theaterHunt.phase="prop_setup";state.d.theaterHunt.mode="light"
	state.d.theaterHunt.admitted=true;state.d.theaterHunt.posterCleaned=true;state.d.theaterHunt.ticketCodeRead=true
	state.d.theaterHunt.collectedProgramIds=["opening","spotlight","finale"]
	state.d.theaterHunt.propBoxOpened=false
	state.d.items.temporaryTheaterTicket=true;state.d.items.fluorescentBrush=false;state.d.items.spotlightRemote=true
	state.d.items.campusCard=true;state.d.ui.inventoryRecovered=true
	state.d.actOne.phase="complete";state.d.actOne.movementEnabled=true
	state.d.native.settings.music=false;state.d.native.settings.effects=false;state.d.native.settings.reduced_motion=reduced
	state.d.native.player={"x":point.x,"y":point.y,"scene":"theater_interior"}
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(6)
	shell._show_world_mobile();await frames(6)
	shell.world.player=point;shell.world._sync_player();shell.world._update_camera();shell.world.grab_focus()
	check(shell.world.can_stand(point),"authored stand is clear for the actual player body")
	await until(func():return shell.world.transition_alpha<=0,"entry fade finishes")
	accepted_scans=0;actions.clear()
func teardown() -> void:
	if not is_instance_valid(shell):return
	if is_instance_valid(shell.get("object_focus")):shell.object_focus.request_close(true)
	await shell.shutdown();shell.queue_free();await frames(5);shell=null

func target(id: String) -> Dictionary:
	for candidate: Dictionary in shell.world.targets:
		if str(candidate.id)==id:return candidate
	return {}
func world_space(id: String) -> void:
	if DisplayServer.get_name()!="headless":root.grab_focus();await frames(2)
	var found:=target(id);check(not found.is_empty(),"source target remains reachable: "+id)
	if found.is_empty():return
	shell.world.nearby=found;shell.world.grab_focus()
	key(KEY_SPACE,true);key(KEY_SPACE,false);await frames()
func open_box() -> bool:
	await world_space("theater_prop_box")
	check(is_instance_valid(shell.object_focus) and is_instance_valid(shell.c3_device_panel),"original box interaction opens the inspection camera")
	if not is_instance_valid(shell.object_focus) or not panel_valid():return false
	return await until_panel(func():return is_instance_valid(shell.object_focus) and shell.object_focus.phase=="inside","camera reaches chest inspection")
func scan() -> bool:
	state.select_item("temporaryTheaterTicket");await frames()
	await world_space("theater_prop_scanner")
	check(is_instance_valid(shell.object_focus) and is_instance_valid(shell.c3_device_panel),"original world scanner opens the same inspection")
	return is_instance_valid(shell.object_focus) and is_instance_valid(shell.c3_device_panel)
func inside() -> bool:
	var reached: bool=await until(func():return is_instance_valid(shell.object_focus) and shell.object_focus.phase=="inside" and is_instance_valid(shell.c3_device_panel) and shell.c3_device_panel.phase=="inside","opened lid exposes the complete interior")
	if not reached:print("CHEST_ENTER_DIAGNOSTIC ",JSON.stringify({"focus":root.has_focus(),"modal":is_instance_valid(shell.modal),"focusPhase":shell.object_focus.phase if is_instance_valid(shell.object_focus) else "none","focusAmount":shell.object_focus.amount if is_instance_valid(shell.object_focus) else -1,"paused":shell.object_focus.focus_paused if is_instance_valid(shell.object_focus) else false,"panelPhase":shell.c3_device_panel.phase if is_instance_valid(shell.c3_device_panel) else "none","lid":shell.c3_device_panel.lid_open if is_instance_valid(shell.c3_device_panel) else -1}))
	return reached
func closed() -> bool:
	var result: bool=await until(func():return not is_instance_valid(shell.modal) and not is_instance_valid(shell.object_focus),"inspection releases modal and camera")
	if not result:print("THEATER_CHEST_CLOSE_DIAGNOSTIC ",JSON.stringify({"viewport":root.size,"worldSize":shell.world.size,"focusPhase":str(shell.object_focus.phase) if is_instance_valid(shell.object_focus) else "none","panelPhase":str(shell.c3_device_panel.phase) if is_instance_valid(shell.c3_device_panel) else "none","worldVisible":shell.world_frame.visible,"runtimeMode":state.d.runtimeMode}))
	return result
func action_seen(action: String, previous: Dictionary, current: Dictionary, _result: Dictionary) -> void:
	actions.append(action)
	if action=="c3_target:theater_prop_scanner" and not bool(previous.get("theaterHunt",{}).get("propBoxOpened",false)) and bool(current.get("theaterHunt",{}).get("propBoxOpened",false)):accepted_scans+=1

func capture_directory() -> String:
	for value: String in OS.get_cmdline_user_args():
		if value.begins_with("--capture-dir="):return value.trim_prefix("--capture-dir=")
	return OS.get_environment("THEATER_CHEST_CAPTURE_DIR")
func capture(label: String) -> void:
	var directory:=capture_directory()
	if directory.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(directory);await RenderingServer.frame_post_draw
	var path:=directory.path_join(label+".png")
	check(root.get_texture().get_image().save_png(path)==OK,"captures rendered "+label)
	captures.append(path);print("THEATER_CHEST_CAPTURE ",path)
func verify_controls() -> void:
	check(panel_valid(),"inspection panel is still mounted for control checks")
	if not panel_valid():return
	var panel: Control=shell.c3_device_panel
	var viewport:=Rect2(Vector2.ZERO,Vector2(root.size))
	var keys: Array=panel.controls.keys();keys.sort()
	check(keys==["axle","bottom","butterfly","close","crank","drawer","fan","lamp","lid","note","slot0","slot1","slot2"],"inspection contains physical parts and exit")
	for id: String in panel.controls:
		var control: Control=panel.controls[id]
		if not control.is_visible_in_tree():continue
		var transform:=control.get_global_transform_with_canvas()
		var bounds:=Rect2(transform*Vector2.ZERO,control.size*transform.get_scale())
		check(viewport.encloses(bounds),"visible "+id+" hotspot fits the physical viewport")
		if panel.compact_layout:check(bounds.size.x>=44 and bounds.size.y>=44,"touch "+id+" target is at least 44px")
	if panel.phase=="inside":
		check(panel.controls.bottom.visible and panel.controls.bottom.size.x>0 and panel.controls.bottom.size.y>0,"open chest has a directly reachable bottom surface")
		var bottom: Rect2=panel.get_bottom_rect()
		var hit: Rect2=Rect2(panel.controls.bottom.position,panel.controls.bottom.size)
		check(hit.position.is_equal_approx(bottom.position) and hit.size.is_equal_approx(bottom.size),"bottom hit area follows the actually rendered bottom projection")
		var art: Rect2=panel.get_art_rect()
		var transform:=panel.get_global_transform_with_canvas()
		var physical_art:=Rect2(transform*art.position,art.size*transform.get_scale())
		check(viewport.encloses(physical_art),"initial fully opened object fits the physical viewport without clipping")

func tap_floor(touch:=false) -> void:
	check(panel_valid(),"inspection panel is still mounted for floor input")
	if not panel_valid():return
	var floor: Control=shell.c3_device_panel.controls.bottom
	await tap(floor,touch,Vector2(24,floor.size.y-24))

func settle_parts() -> bool:
	return await until_panel(func():return not shell.c3_device_panel.busy and shell.c3_device_panel.focus_motion==null,"object animation settles")

func play_mechanism(touch: bool, label: String) -> bool:
	check(panel_valid(),"inspection panel is still mounted for mechanism input")
	if not panel_valid():return false
	var panel: Control=shell.c3_device_panel
	var items: Dictionary=state.d.items.duplicate(true)
	var story: Dictionary=state.d.theaterHunt.duplicate(true)
	check(panel.mechanism.get("remaining",[]).size()==4,"opened chest contains three symbols and a separate crank")
	await tap(panel.controls.drawer,touch)
	if not require_panel(panel):return false
	check(not panel.mechanism.get("drawer_open",true),"wrong arrangement keeps the real compartment shut")
	await tap(panel.controls.note,touch)
	if not await settle_parts():return false
	check(panel.mechanism.get("clue_open",false) and panel.get_part_rect("note").size.x>160,"paper opens and its physical clue becomes readable")
	await capture(label+"-clue")
	if not require_panel(panel):return false
	await tap(panel.controls.note,touch)
	if not await settle_parts():return false
	check(not panel.mechanism.get("clue_open",true),"paper closes without advancing the story")
	await tap(panel.controls.crank,touch)
	if not require_panel(panel):return false
	await tap(panel.controls.axle,touch)
	if not await settle_parts():return false
	check(panel.mechanism.get("crank_installed",false) and not panel.controls.crank.visible,"crank travels from the floor into the axle")
	var arrangement: Array[String]=["butterfly","lamp","fan"]
	for index: int in range(3):
		await tap(panel.controls[arrangement[index]],touch)
		if not require_panel(panel):return false
		check(panel.selected==arrangement[index],"exposed stacked piece selects the visible symbol")
		await tap(panel.controls["slot%d"%index],touch)
		if not await settle_parts():return false
	check(panel.mechanism.slots==arrangement,"all physical slots receive their selected pieces")
	await capture(label+"-assembled")
	if not require_panel(panel):return false
	await tap(panel.controls.axle,touch)
	if not await settle_parts():return false
	check(panel.mechanism.slots==["fan","butterfly","lamp"] and panel.mechanism.turns==1,"one real crank input rotates the symbols into clue order")
	await tap(panel.controls.drawer,touch)
	if not await settle_parts():return false
	check(panel.mechanism.get("drawer_open",false) and is_equal_approx(panel.contents.drawer_amount,1),"correct symbols let the player pull open the hidden compartment")
	await capture(label+"-compartment")
	check(state.d.items==items and state.d.theaterHunt==story,"optional mechanism never changes original mainline items or progression")
	return true

func exercise(dim: Vector2i) -> void:
	await fixture(dim)
	var label:="mobile" if dim.x<1100 else "desktop"
	var touch: bool=dim.x<1100
	var initial_items: Dictionary=state.d.items.duplicate(true)
	var initial_player: Vector2=shell.world.player
	var original_camera: Vector2=shell.world.camera
	var original_zoom: float=shell.world.zoom
	var original_pan: Vector2=shell.world.pan_offset
	if not await open_box():return
	check(state.d.items==initial_items and not state.d.theaterHunt.propBoxOpened,"inspection alone leaves the existing flow and items unchanged")
	check(shell.world.zoom>original_zoom and shell.world.player==initial_player,"real camera approaches without teleporting the player")
	verify_controls();await capture(label+"-closed")
	key(KEY_D,true);await create_timer(.12).timeout;key(KEY_D,false);await frames()
	check(shell.world.player==initial_player,"world movement remains frozen under inspection")
	var action_count:=actions.size()
	await tap(shell.c3_device_panel.controls.lid,touch)
	check(actions.size()==action_count and state.d.items==initial_items and not state.d.theaterHunt.propBoxOpened,"touching the closed lid cannot perform a story action")
	await tap(shell.c3_device_panel.controls.close,touch)
	if not await closed():return
	await frames()
	check(shell.world.camera.is_equal_approx(original_camera) and is_equal_approx(shell.world.zoom,original_zoom) and shell.world.pan_offset.is_equal_approx(original_pan),"inspection exit restores camera, zoom and pan")
	if not await scan():return
	check(state.d.theaterHunt.propBoxOpened and not state.d.items.temporaryTheaterTicket and state.d.items.fluorescentBrush and accepted_scans==1,"world scanner immediately performs the original atomic ticket-to-brush transaction")
	var earned_items: Dictionary=state.d.items.duplicate(true)
	check(bool(shell.c3_device_panel.get_meta("scan_just_accepted",false)),"newly accepted scan is identified only for its visual opening")
	if DisplayServer.get_name()!="headless" and not capture_directory().is_empty():
		if not await until_panel(func():return shell.c3_device_panel.lid_open>=.34,"lid reaches its first visible rotation"):return
		await capture(label+"-opening-front")
		if not await until_panel(func():return shell.c3_device_panel.lid_open>=.94,"lid turns past its upright edge"):return
		await capture(label+"-opening-inner")
	if not await inside():return
	check(is_equal_approx(shell.c3_device_panel.lid_open,1.0) and shell.c3_device_panel.observed_open,"open state is driven by the accepted controller fact")
	verify_controls();await capture(label+"-bottom")
	var bottom_size: Vector2=shell.c3_device_panel.get_bottom_rect().size
	action_count=actions.size();await tap_floor(touch)
	if not await until_panel(func():return is_equal_approx(shell.c3_device_panel.interior_focus,1.0) and shell.c3_device_panel.focus_motion==null,"physical bottom tap completes the detail camera movement"):return
	check(shell.c3_device_panel.get_bottom_rect().size.x>bottom_size.x*1.02,"detail movement enlarges the actual bottom projection")
	check(actions.size()==action_count and state.d.items==earned_items and accepted_scans==1,"looking at the bottom adds no puzzle action or duplicate reward")
	await capture(label+"-bottom-focused")
	await tap_floor(touch)
	if not await until_panel(func():return shell.c3_device_panel.get_bottom_rect().size.is_equal_approx(bottom_size) and shell.c3_device_panel.focus_motion==null,"second bottom tap restores the fully framed object"):return
	if not await play_mechanism(touch,label):return
	if not panel_valid():check(false,"inspection panel remains mounted after mechanism");return
	await tap(shell.c3_device_panel.controls.close,touch)
	if not await closed():return
	await frames()
	check(shell.world.camera.is_equal_approx(original_camera) and is_equal_approx(shell.world.zoom,original_zoom) and shell.world.pan_offset.is_equal_approx(original_pan),"opening sequence returns to the original camera")
	check(shell.world.player==initial_player and state.d.items==earned_items,"return retains original player position and earned inventory")
	await capture(label+"-returned")
	if not await open_box():return
	check(shell.c3_device_panel.phase=="inside" and shell.c3_device_panel.lid_open==1.0,"already opened box restores directly to its open interior")
	check(not shell.c3_device_panel.mechanism.get("drawer_open",true) and shell.c3_device_panel.mechanism.get("remaining",[]).size()==4,"reentry starts a fresh temporary mechanism")
	check(state.d.items==earned_items and accepted_scans==1,"reopening never replays ticket consumption or brush reward")
	key(KEY_ESCAPE,true);key(KEY_ESCAPE,false)
	if not await closed():return
	state.select_item("temporaryTheaterTicket");await world_space("theater_prop_scanner")
	check(not is_instance_valid(shell.modal) and state.d.items==earned_items and accepted_scans==1,"spent ticket cannot repeat the scanner transaction")

func interruptions_and_legacy() -> void:
	await fixture(Vector2i(1440,900))
	var items: Dictionary=state.d.items.duplicate(true)
	if await open_box():
		root.size=Vector2i(390,844);await frames(6);await closed()
		check(state.d.items==items and not state.d.theaterHunt.propBoxOpened,"resize releases uncommitted inspection without changing items")
	await fixture(Vector2i(390,844))
	if await scan():
		items=state.d.items.duplicate(true)
		shell.world_frame.hide();await frames(6);await closed()
		check(state.d.items==items and state.d.theaterHunt.propBoxOpened,"hiding an opening view retains the already accepted scanner result")
	await fixture(Vector2i(1440,900),true)
	if await scan():
		check(shell.object_focus.amount==1.0 and shell.object_focus.phase=="inside","reduced motion settles the camera immediately")
		if not await inside():return
		check(shell.c3_device_panel.lid_open==1.0 and accepted_scans==1,"reduced motion shows the same fully opened bottom")
		await tap(shell.c3_device_panel.controls.close);await closed()
	await fixture(Vector2i(390,844),true)
	state.d.theaterHunt.propBoxOpened=true;state.d.items.temporaryTheaterTicket=false;state.d.items.fluorescentBrush=true
	shell._refresh();await frames()
	if await open_box():
		check(shell.c3_device_panel.phase=="inside" and shell.c3_device_panel.lid_open==1.0,"old earned open-box state needs no new interaction steps")
		items=state.d.items.duplicate(true)
		var action_count:=actions.size();await tap_floor(true)
		check(actions.size()==action_count and state.d.items==items and accepted_scans==0,"old inventory stays unchanged while inspecting the bottom")
		await tap(shell.c3_device_panel.controls.close,true);await closed()
	state.d.items.fluorescentBrush=false;shell._refresh();await frames()
	if await open_box():
		await tap_floor(true)
		check(not state.d.items.fluorescentBrush and not state.d.items.temporaryTheaterTicket and accepted_scans==0,"an empty legacy chest cannot regenerate a used brush")
		await tap(shell.c3_device_panel.controls.close,true);await closed()

func manual_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:return
	if event.keycode==KEY_F6:
		await fixture(root.size);await open_box()
	elif event.keycode==KEY_F7:
		await fixture(root.size)
		if await scan():await inside()
	elif event.keycode==KEY_F8:
		print("CHEST_WINDOW_FOCUS ",root.has_focus()," modal=",is_instance_valid(shell.modal)," objectFocus=",is_instance_valid(shell.object_focus))
		if is_instance_valid(shell.c3_device_panel):
			var panel: Control=shell.c3_device_panel
			print("CHEST_MANUAL_STATE ",JSON.stringify({"selected":panel.selected,"mechanism":panel.mechanism,"feedback":panel.feedback_label.text,"busy":panel.busy}))
	elif event.keycode==KEY_F11:
		manual_capture_index+=1;await capture("manual-%03d"%manual_capture_index)
func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"test profile uses isolated storage")
	if failures:quit(1);return
	state=root.get_node("State");state.action_completed.connect(action_seen)
	if OS.get_cmdline_user_args().has("--manual"):
		root.title="7:55 · Theater chest mechanism · isolated QA"
		await fixture(Vector2i(390,844) if OS.get_cmdline_user_args().has("--portrait") else Vector2i(1280,820))
		if OS.get_cmdline_user_args().has("--closed"):await open_box()
		elif await scan():await inside()
		root.window_input.connect(manual_input)
		print("THEATER_CHEST_MANUAL_READY F6 resets closed inspection; F7 performs original world scan; F11 captures")
		return
	var portrait_only: bool=OS.get_cmdline_user_args().has("--portrait-only")
	var desktop_only: bool=OS.get_cmdline_user_args().has("--desktop-only")
	check(not (portrait_only and desktop_only),"choose at most one automated viewport scope")
	if failures:quit(1);return
	create_timer(95).timeout.connect(func():push_error("THEATER CHEST watchdog");quit(2))
	var dimensions: Array[Vector2i]=[Vector2i(1440,900),Vector2i(390,844)]
	if portrait_only:dimensions=[Vector2i(390,844)]
	elif desktop_only:dimensions=[Vector2i(1440,900)]
	for dim: Vector2i in dimensions:await exercise(dim)
	if not portrait_only and not desktop_only:await interruptions_and_legacy()
	else:print("THEATER_CHEST_SCOPE ","portrait-only" if portrait_only else "desktop-only","; resize/interruption/legacy cases remain in the default full suite")
	await teardown()
	print("THEATER_CHEST_FOCUS ",checks," checks; ",failures," failures; captures=",JSON.stringify(captures))
	quit(1 if failures else 0)
