extends SceneTree
## Chapter-local seeded fixture tests. These are actual Control/input tests,
## never a claim of earned full-gameplay or physical mobile-device acceptance.
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const TheaterPanel=preload("res://scripts/ui/c3_theater_device_panel.gd")
const Layers=preload("res://scripts/ui/chapter3_world_layers.gd")
var checks:=0
var errors:=0
var state: Node
var shell: Control
var controller=Chapter.new()
var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/c3_devices_source.json"))
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: errors+=1; push_error(label)
func frames(n: int=4) -> void:
	for i in range(n): await process_frame
func click(node: Control) -> void:
	var t: Transform2D=node.get_global_transform_with_canvas()
	var point: Vector2=t*(node.size/2)
	var motion:=InputEventMouseMotion.new(); motion.position=point; root.push_input(motion)
	for down in [true,false]:
		var event:=InputEventMouseButton.new(); event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down; root.push_input(event)
	await frames()
func key(code: Key) -> void:
	for down in [true,false]:
		var event:=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=down; root.push_input(event)
	await frames()
func setup(scene: String,target: String,dim: Vector2i) -> void:
	root.size=dim
	state.d=state.initial(); state.developer_mode=true
	state.d.native.chapter=3; state.d.native.scene=scene; state.d.native.page="c3_canteen" if scene=="canteen_interior" else "c3_theater"
	state.d.rpgScene=scene; state.d.runtimeMode="rpg"; state.d.native.mode="light"
	state.d.canteenHunt.active=true; state.d.canteenHunt.phase="tray_search"; state.d.canteenHunt.entryPaperEscaped=true
	state.d.theaterHunt.active=true; state.d.theaterHunt.phase="entry_ticket"; state.d.theaterHunt.mode="light"; state.d.theaterHunt.ticketCodeRead=true
	var definition: Dictionary=controller.get_definition(scene,target,state.d)
	var point: Dictionary=definition.get("stand",{"x":definition.x,"y":definition.y})
	state.d.native.player={"x":point.x,"y":point.y,"scene":scene}
	shell=load("res://scripts/main.gd").new(); shell.size=Vector2(dim); root.add_child(shell); await frames(6)
	if dim.x<1100: shell._show_world_mobile()
	shell.world.player=Vector2(point.x,point.y); shell.world._sync_player(); shell.world._update_camera(); shell.world._process(0)
	shell.world.grab_focus(); await frames()
func teardown() -> void:
	await shell.shutdown(); shell.queue_free(); await frames(5)
func open_world(target: String) -> void:
	# Explicit authored stand fixture; enter device through the live world key path.
	for candidate in shell.world.targets:
		if str(candidate.id)==target: shell.world.nearby=candidate
	shell.world.grab_focus()
	await key(KEY_SPACE)
	check(is_instance_valid(shell.c3_device_panel),"world Space opens device "+target)
	if is_instance_valid(shell.c3_device_panel): check_readability(shell.c3_device_panel)
func check_readability(panel: Control) -> void:
	if not panel.compact_layout: return
	var viewport_rect:=Rect2(Vector2.ZERO,Vector2(root.size))
	var buttons: Array=[]
	for child in panel.get_children():
		if not child is Control or not child.visible: continue
		var transform: Transform2D=child.get_global_transform_with_canvas()
		var rect:=Rect2(transform.origin,child.size*transform.get_scale())
		if child is Label:
			check(viewport_rect.encloses(rect),"compact text entirely inside visible viewport")
			var physical_font: float=child.get_theme_font_size("font_size")*absf(transform.get_scale().y)
			check(physical_font>=14,"compact physical label font >=14px: "+str(physical_font))
		if child is Button:
			check(child.get_theme_font_size("font_size")*absf(transform.get_scale().y)>=14,"compact physical button font >=14px")
			check(rect.size.x>=44 and rect.size.y>=44,"compact physical button target >=44px "+str(rect.size))
			check(viewport_rect.encloses(rect),"compact button entirely inside visible viewport")
			for previous: Rect2 in buttons: check(not previous.intersects(rect),"compact controls do not overlap")
			buttons.append(rect)
	check(panel.scale==Vector2.ONE,"compact device text is never shrunk with world letterbox")

func run() -> void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"test profile isolated")
	if errors: quit(1); return
	state=root.get_node("State")
	# Executed-source controller edits, not a hand-authored recipe oracle.
	var s: Dictionary=state.initial(); s.native.chapter=3; s.native.scene="theater_interior"; s.native.mode="light"
	s.theaterHunt.phase="program_search"; s.theaterHunt.active=true; s.theaterHunt.mode="light"; s.theaterHunt.collectedProgramIds=["opening","spotlight","finale"]
	var def: Dictionary=controller.get_definition("theater_interior","theater_light_console",s)
	s.native.player={"x":def.stand.x,"y":def.stand.y}
	for sample in fixture.orders:
		controller.dispatch(s,"c3_program_set",sample.order)
		check(s.theaterHunt.programOrder==sample.draft,"program draft matches source for "+str(sample.order))
	for sample in fixture.occlusions:
		var layer=Layers.new()
		var result: Dictionary=layer.canteen_occlusion({"id":"lost_found_front","left":1344,"top":253,"right":1618,"bottom":407,"sortY":407},Vector2(sample.anchor.x,sample.anchor.y),sample.reduced)
		check(result.visible==sample.visible and result.softened==sample.softened and is_equal_approx(result.alpha,sample.alpha),"occlusion matches executed source "+str(sample))
	for dim in [Vector2i(1280,720),Vector2i(960,540),Vector2i(390,844),Vector2i(430,860),Vector2i(844,390)]:
		await setup("canteen_interior","canteen-mixer",dim)
		for id in controller.RECIPE: state.d.items[id]=true
		var original_page: String=state.d.native.page
		await open_world("canteen-mixer")
		if not is_instance_valid(shell.c3_device_panel): await teardown(); continue
		var panel: Control=shell.c3_device_panel
		check(state.d.native.page==original_page and shell.world_frame.visible,"mixer keeps current world/page at "+str(dim))
		check(panel.session.button_order!=controller.RECIPE,"mixer never lays out answer order")
		var before: Vector2=shell.world.player
		shell.world.move_target=before+Vector2(200,0);shell.world._process(.04)
		check(shell.world.player==before,"modal blocks held or queued world movement")
		shell.world.move_target=Vector2.INF
		var index: int=panel.session.button_order.find("blackCoffee")
		await click(panel.slots[index])
		check(state.d.canteenHunt.drinkMixSequence==["blackCoffee"] and not state.d.items.blackCoffee,"actual pointer pours owned coffee")
		if dim.x==390:
			var order: Array=panel.session.button_order.duplicate()
			root.size=Vector2i(430,860);shell.size=Vector2(430,860);shell._layout();await frames()
			check_readability(panel)
			check(panel.session.button_order==order and panel.model.layers.size()==1,"resize preserves shuffle and partial pour")
			root.size=Vector2i(1280,720);shell.size=Vector2(1280,720);shell._layout();await frames()
			check(not panel.compact_layout and panel.size.is_equal_approx(Vector2(960,540)),"resize back to desktop restores original source geometry")
			check(panel.session.button_order==order and panel.model.layers.size()==1,"desktop/compact transition preserves active session")
			root.size=dim;shell.size=Vector2(dim);shell._layout();await frames()
		await key(KEY_ESCAPE)
		check(not is_instance_valid(shell.modal) and state.d.canteenHunt.drinkMixSequence==["blackCoffee"],"Escape retains partial sequence")
		await open_world("canteen-mixer");panel=shell.c3_device_panel
		if not is_instance_valid(panel): await teardown(); continue
		check(panel.model.layers.size()==1,"reopened view contains coffee layer")
		for id in ["sparklingWater","lemonTea"]:
			await click(panel.slots[panel.session.button_order.find(id)])
		check(state.d.items.dailySpecialSparklingWater and not is_instance_valid(shell.modal),"third real pointer awards good drink and closes exactly once")
		check(state.d.canteenHunt.drinkMixAttemptCount==1 and state.d.canteenHunt.drinkMixSequence.is_empty(),"mixer transaction authority preserved")
		await open_world("canteen-mixer");panel=shell.c3_device_panel
		await click(panel.slots[0])
		check(state.d.canteenHunt.drinkMixSequence.is_empty() and is_instance_valid(shell.modal),"missing ingredient click preserves open panel and state")
		for id in controller.RECIPE: state.d.items[id]=true
		panel.refresh()
		for id in ["sparklingWater","blackCoffee","lemonTea"]: await click(panel.slots[panel.session.button_order.find(id)])
		check(state.d.items.badDrink and state.d.canteenHunt.drinkMixAttemptCount==2 and not is_instance_valid(shell.modal),"wrong actual pointer recipe grants only authored bad drink and closes")
		await teardown()
		await setup("theater_interior","theater_ticket_kiosk",dim)
		state.d.theaterHunt.cc98TicketCommissionPhase="delivered"
		await open_world("theater_ticket_kiosk");panel=shell.c3_device_panel
		if not is_instance_valid(panel): await teardown(); continue
		if dim.x>=1100:
			var keypad_index:=0
			for id in panel.controls:
				var expected: Dictionary=fixture.keypad.buttons[keypad_index]
				var actual: Control=panel.controls[id]
				check(actual.size==Vector2(expected.width,expected.height) and actual.position+actual.size/2==Vector2(480+expected.x,270+expected.y),"desktop keypad matches executed source button geometry")
				keypad_index+=1
		for id in ["0","1","2","3","4"]: await click(panel.controls[id])
		check(panel.code==fixture.keypad.draft and panel.display.text==fixture.keypad.display,"source four-digit keypad maximum and visible draft")
		await click(panel.controls.submit)
		check(panel.active and panel.code=="0123" and state.d.theaterHunt.ticketCodeAttempts==1,"wrong keypad submission retains editable draft")
		check(panel.controls.submit.get_theme_color("font_hover_color")==panel.controls.submit.get_theme_color("font_color"),"device hover/focus text preserves light-on-dark contrast")
		if dim.x<1100:
			check(panel.feedback_label.visible and panel.content.ticket.codeWrong in panel.feedback_label.text,"wrong keypad feedback visible inside compact modal")
			check_readability(panel)
		await key(KEY_BACKSPACE)
		check(panel.code==fixture.keypad.afterBackspace,"keyboard backspace changes one digit")
		await key(KEY_ESCAPE);await open_world("theater_ticket_kiosk");panel=shell.c3_device_panel
		check(panel.code==fixture.keypad.freshOpen,"fresh keypad open resets local draft")
		for code in [KEY_0,KEY_8,KEY_3,KEY_2]: await key(code)
		await key(KEY_ENTER)
		check(state.d.items.theaterTicketHalfB and not is_instance_valid(shell.modal),"keyboard code prints controller ticket and dismisses device")
		await teardown();await setup("theater_interior","theater_ticket_kiosk",dim)
		state.d.theaterHunt.cc98TicketCommissionPhase="posted"
		# Independent seeded branch; the previous earned ticket was not altered.
		await open_world("theater_ticket_kiosk");panel=shell.c3_device_panel
		for code in [KEY_0,KEY_8,KEY_3,KEY_2]: await key(code)
		await key(KEY_ENTER)
		check(not state.d.items.theaterTicketHalfB and not is_instance_valid(shell.modal),"correct code without phone release closes with source refusal")
		await teardown()
		await setup("theater_interior","theater_light_console",dim)
		state.d.theaterHunt.phase="program_search";state.d.theaterHunt.admitted=true;state.d.theaterHunt.collectedProgramIds=["opening","spotlight","finale"]
		for id in controller.PROGRAM.values(): state.d.items[id]=true
		shell.world.refresh_world(); await frames();await open_world("theater_light_console");panel=shell.c3_device_panel
		if not is_instance_valid(panel): await teardown(); continue
		await click(panel.controls.opening);await click(panel.controls.opening)
		check(state.d.theaterHunt.programOrder==["opening"],"duplicate card cannot fill draft twice")
		await click(panel.controls.spotlight);await click(panel.controls.undo)
		check(state.d.theaterHunt.programOrder==["opening"],"undo retracts last real draft card")
		await key(KEY_ESCAPE);await open_world("theater_light_console");panel=shell.c3_device_panel
		check(state.d.theaterHunt.programOrder==["opening"] and panel.display.text==panel.content.program.labels.opening,"program draft survives close and reopen")
		await click(panel.controls.spotlight);await click(panel.controls.finale);await click(panel.controls.submit)
		check(state.d.theaterHunt.programOrder==fixture.wrongDraft and state.d.theaterHunt.programWrongAttempts==1 and is_instance_valid(shell.modal),"wrong program keeps first two cards and original dialogue without closing")
		for step in range(300):
			if shell.c3_narrative_host.current==null: break
			shell.c3_narrative_host.tick(100,true)
		await frames()
		await click(panel.controls.clear)
		check(state.d.theaterHunt.programOrder.is_empty(),"clear affects draft only")
		for id in controller.PROGRAM_ORDER: await click(panel.controls[id])
		await click(panel.controls.submit)
		check(state.d.theaterHunt.phase=="prop_setup" and state.d.rpgCheckpoint=="theater_stage" and state.d.items.spotlightRemote and not is_instance_valid(shell.modal),"program pointer submission earns remote and dismisses")
		await teardown()
	print("C3 local device actual controls/source checks: ",checks," checks, ",errors," failures")
	quit(1 if errors else 0)
