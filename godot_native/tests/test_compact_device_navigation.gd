extends SceneTree
## Required device surfaces through actual Main, world targets and Control input.
## Source-phase fixtures isolate routing; they are not a campaign completion proof.
## Source-authentic C3/C4 devices are live world modals, not generic phone forms.
const WORLD_DEVICES := ["mixer","kiosk","console","c4_duty","c4_numeric"]
var checks: int=0
var failures: int=0
var state: Node
var main: Control
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("DEVICE NAV: "+message)
func _initialize() -> void: call_deferred("run")
func find_button(node: Node,text: String) -> Button:
	if node is Button and node.text==text: return node
	for child in node.get_children():
		var found: Button=find_button(child,text)
		if found!=null: return found
	return null
func descendants(node: Node,type: String) -> Array:
	var found: Array=[]
	for child in node.get_children():
		if child.is_class(type): found.append(child)
		found.append_array(descendants(child,type))
	return found
func luminance(color: Color) -> float:
	var linear: Color=color.srgb_to_linear()
	return .2126*linear.r+.7152*linear.g+.0722*linear.b
func contrast(a: Color,b: Color) -> float:
	return (maxf(luminance(a),luminance(b))+.05)/(minf(luminance(a),luminance(b))+.05)
func click(button: Button,label: String) -> void:
	check(button!=null,label+" exists")
	if button==null: return
	var parent: Node=button.get_parent()
	while parent!=null:
		if parent is ScrollContainer: parent.ensure_control_visible(button)
		parent=parent.get_parent()
	await process_frame; await process_frame
	check(button.is_visible_in_tree() and not button.disabled,label+" is visible and enabled")
	var point: Vector2=button.get_global_rect().get_center()
	check(Rect2(Vector2.ZERO,Vector2(root.size)).has_point(point),label+" has reachable physical hit area")
	for pressed: bool in [true,false]:
		var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.position=point; event.global_position=point; event.pressed=pressed; root.push_input(event,true)
		await process_frame
	await process_frame
func seed_case(id: String) -> void:
	state.d=state.initial(); state.developer_mode=true
	state.d.actOne.phase="complete"; state.d.actOne.movementEnabled=true
	state.d.native.chapter=3; state.d.native.mode="light"; state.d.native.scene="canteen_interior"; state.d.native.page="c3_canteen"
	state.d.runtimeMode="rpg"; state.d.canteenHunt.active=true; state.d.canteenHunt.phase="drink_mix"; state.d.canteenHunt.entryPaperEscaped=true
	if id=="mixer":
		for item in ["blackCoffee","sparklingWater","lemonTea"]: state.d.items[item]=true
	elif id=="menu": state.d.canteenHunt.phase="menu_order"; state.d.canteenHunt.queueGapOpened=true
	elif id=="bike":
		state.d.native.scene="campus_bootstrap"; state.d.canteenHunt.phase="chase_ready"; state.d.items.greaseTissue=true
	elif id in ["kiosk","console"]:
		state.d.native.scene="theater_interior"; state.d.native.page="c3_theater"; state.d.theaterHunt.active=true
		state.d.theaterHunt.phase="entry_ticket" if id=="kiosk" else "program_search"; state.d.theaterHunt.posterCleaned=true; state.d.theaterHunt.ticketCodeRead=true
		state.d.theaterHunt.cc98TicketCommissionPhase="delivered"
		if id=="console": state.d.theaterHunt.admitted=true; state.d.theaterHunt.collectedProgramIds=["opening","spotlight","finale"]
	elif id.begins_with("library"):
		state.d.native.chapter=2; state.d.native.scene="library_interior"; state.d.native.page="library_app"; state.d.canteenHunt.active=false
		state.d.ui.libraryFinalsPhase="library_entered" if id=="library_record" else "evidence_gathering"
		state.d.ui.libraryFinalsPuzzle.investigationOpened=id!="library_record"
	elif id.begins_with("c4"):
		state.d.native.chapter=4; state.d.native.scene="duan_yongping_temporal_maze"; state.d.native.page="c4_notes"; state.d.canteenHunt.active=false
		state.d.chapter4.prologueSeen=true; state.d.chapter4.phase="room204_restore"; state.d.chapter4.timeState="1850_evening"; state.d.chapter4.floor="A1"; state.d.chapter4.mode="light"; state.d.chapter4.factIds=["hour_hand_installed"]
		if id=="c4_power": state.d.chapter4.phase="blackout_light_grid"; state.d.chapter4.timeState="0754_blackout"; state.d.chapter4.factIds=["paper_temporarily_out_of_inventory"]; state.d.chapter4.lightGrid={"mask":6,"locked":false}
		if id=="c4_numeric": state.d.chapter4.floor="A2"; state.d.chapter4.factIds.append("misaligned_stair_solved")
	state.d.rpgScene=state.d.native.scene
func prepare(id: String,width: int) -> void:
	seed_case(id); state.story_reset.emit(); state.changed.emit()
	root.size=Vector2i(width,844 if width<1100 else 720)
	await process_frame; await process_frame
	main.world.set_process(false); main.c3_narrative_host.set_process(false); main.c3_scene_host.set_process(false); main.library_story_host.set_process(false)
	main.mobile_world=true; main._layout(); await process_frame
func interact(action: String) -> Dictionary:
	var selected: Dictionary={}
	for target: Dictionary in state.get_targets(state.d.native.scene):
		if target.action==action: selected=target; break
	check(not selected.is_empty(),"source target exists for "+action)
	if selected.is_empty(): return {}
	var point:=Vector2(selected.position[0],selected.position[1])
	if selected.get("stand") is Dictionary: point=Vector2(selected.stand.x,selected.stand.y)
	main.world.player=main.world._find_safe(point); main.world._sync_player()
	check(main.world._distance(selected)<=float(selected.get("radius",100)),"collision-safe source target within interaction radius")
	main.world._try_interact(selected)
	await process_frame; await process_frame
	return selected
func fill_form(values: Array) -> void:
	check(is_instance_valid(main.modal),"real input dialog opened")
	if not is_instance_valid(main.modal): return
	var editors: Array=[]
	for node in descendants(main.modal,"Control"):
		if node is OptionButton or node is LineEdit: editors.append(node)
	check(editors.size()==values.size(),"expected actual input controls")
	for i in range(mini(editors.size(),values.size())):
		if editors[i] is OptionButton: editors[i].select(int(values[i]))
		else:
			var input: LineEdit=editors[i]
			var background: Color=input.get_theme_stylebox("normal").bg_color
			check(contrast(input.get_theme_color("font_color"),background)>=4.5,"required form text has readable contrast")
			check(contrast(input.get_theme_color("font_placeholder_color"),background)>=4.5,"required form placeholder has readable contrast")
			check(input.get_theme_color("caret_color")==main.INK,"input caret remains visible on light form")
			input.text=str(values[i])
	await click(find_button(main.modal,"确认"),"form submit")
func run() -> void:
	state=root.get_node("State"); seed_case("mixer")
	root.size=Vector2i(390,844); main=load("res://scenes/main.tscn").instantiate(); root.add_child(main); await process_frame; await process_frame
	var actions: Dictionary={"mixer":"c3_target:canteen-mixer","menu":"c3_target:ordering_kiosk","bike":"c3_target:bike","kiosk":"c3_target:theater_ticket_kiosk","console":"c3_target:theater_light_console","library_record":"lib_open_record","library_catalog":"lib_catalog_terminal","c4_duty":"c4_device_duty_board","c4_elevator":"c4_elevator","c4_power":"c4_power","c4_numeric":"c4_device_positioning_calibration"}
	var pages: Dictionary={"menu":"c3_menu","bike":"c3_bike","library_record":"library_record","library_catalog":"library_catalog"}
	for width: int in [390,430,1280]:
		for id: String in actions:
			await prepare(id,width)
			var scene: String=state.d.native.scene
			var original_page: String=state.d.native.page
			await interact(actions[id]); var position: Vector2=main.world.player
			if id in WORLD_DEVICES:
				await exercise_world_device(id,actions[id],width,scene,position,original_page)
				continue
			if id.begins_with("library"):
				check(state.get_phone_entry_session().phase=="loading","new Library mount observes source Zjuding entry delay")
				await create_timer(1.6).timeout
			check(state.d.native.page==pages.get(id,"c4_device"),id+" routed required page at "+str(width))
			check(main.phone.is_visible_in_tree(),id+" actionable page visible at "+str(width))
			check(main.world_frame.is_visible_in_tree()==(width>=1100),id+" compact hides world, desktop preserves split")
			check(state.d.native.scene==scene and main.world.player==position,"navigation preserves source world scene and position")
			# A harmless refresh is not a navigation command.
			state.act("phone_refresh",{}); await process_frame; await process_frame
			check(main.phone.is_visible_in_tree(),"ordinary refresh leaves selected device visible")
			match id:
				"menu":
					await click(find_button(main.page_body,"下单"),"menu order"); await fill_form([3])
					check(state.d.items.pickupTicket0755 and state.d.canteenHunt.orderedMenuOption=="D","real menu input reaches source controller")
				"bike": await click(find_button(main.page_body,"用油渍纸巾擦拭车锁"),"bike cleaning"); check(state.d.canteenHunt.bikeLockCleaned,"visible bike action mutates only intended fact")
				"library_record": await click(find_button(main.page_body,"记下入馆记录"),"library record"); check(state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"library record action accepted")
				"library_catalog":
					var query: LineEdit=main.page_body.find_child("LibraryCatalogQuery",true,false)
					check(query!=null and query.is_visible_in_tree(),"native Library catalog field visible")
					if query!=null: query.text="离座"; query.text_changed.emit(query.text); query.text_submitted.emit(query.text)
					await process_frame; await process_frame
					check(main.phone_builder.native_library.catalog_submitted,"real Library custom search preserves interaction")
				"c4_elevator": check(find_button(main.page_body,"调节回放起点")!=null,"elevator calibration control reachable")
				"c4_power":
					var button: Button=find_button(main.page_body,"大厅"); var before: int=state.d.chapter4.lightGrid.mask
					await click(button,"power toggle"); check(state.d.chapter4.lightGrid.mask!=before,"real power control applies toggle")
			if id=="menu":
				check(main.world_frame.is_visible_in_tree(),"device submission reveals its source world dialogue")
				main.c3_narrative_host.tick(0,true)
				check(main.c3_narrative_host.current!=null,"genuine narrative host receives source queue")
				for _i in range(300):
					if main.c3_narrative_host.current==null: break
					main.c3_narrative_host.tick(100,true)
				check(main.c3_narrative_host.current==null,"source queue can complete without hidden-world deadlock")
			else:
				await click(find_button(main.page_body,"进入横屏场景"),"return to same world")
				check(main.world_frame.is_visible_in_tree() and main.world.player==position and state.d.native.scene==scene,"return retains source world position")
				state.act("phone_refresh",{}); await process_frame
				check(main.world_frame.is_visible_in_tree(),"refresh does not yank return view back to phone")
				if id in ["bike","library_record","library_catalog","c4_elevator","c4_power"]:
					await interact(actions[id]); check(main.phone.is_visible_in_tree(),"same world device reopens its controls")
	await rain_return()
	await closure_return()
	await main.shutdown(); main.queue_free(); await process_frame
	print("Compact device navigation: %d checks, %d failures" % [checks,failures]); quit(0 if failures==0 else 1)


func exercise_world_device(id: String,action: String,width: int,scene: String,position: Vector2,original_page: String) -> void:
	var c4: bool=id.begins_with("c4")
	var panel: Control=main.modal if c4 else main.c3_device_panel
	check(is_instance_valid(panel),id+" opens source world device at "+str(width))
	if not is_instance_valid(panel): return
	check(state.d.native.page==("c4_device" if c4 else original_page),id+" preserves source page contract")
	check(panel.is_visible_in_tree() and main.world_frame.is_visible_in_tree(),id+" actionable modal and world are visible")
	check(main.phone.is_visible_in_tree()==(width>=1100),id+" compact keeps world device, desktop keeps split phone")
	check(state.d.native.scene==scene and main.world.player==position,"world device preserves source scene and position")
	var frame: Control=panel.frame if c4 else panel
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(frame.get_global_rect()),id+" device frame fits physical viewport")
	state.act("phone_refresh",{}); await process_frame; await process_frame
	check(is_instance_valid(panel) and panel.is_visible_in_tree() and main.world_frame.is_visible_in_tree(),"ordinary refresh retains exact live world device")
	match id:
		"mixer":
			var slot: int=panel.session.button_order.find("blackCoffee")
			check(slot>=0,"live shuffled mixer contains owned coffee control")
			if slot>=0: await click(panel.slots[slot],"mixer coffee slot")
			check(state.d.canteenHunt.drinkMixSequence==["blackCoffee"],"real mixer pointer accepts ingredient")
			await click(panel.exit_button,"return from source mixer")
		"kiosk":
			for digit in ["0","8","3","2"]: await click(panel.controls[digit],"kiosk digit "+digit)
			check(panel.code=="0832","actual keypad preserves four-digit draft")
			await click(panel.controls.submit,"kiosk submit")
			check(state.d.items.theaterTicketHalfB,"real kiosk keypad accepted")
		"console":
			for card in ["spotlight","opening","finale"]: await click(panel.controls[card],"program card "+card)
			await click(panel.controls.submit,"program submit")
			check(state.d.theaterHunt.phase=="prop_setup","real program cards accepted")
		"c4_duty":
			# Fresh source draft: elevator, 104, 105. Move the actual card twice.
			await click(panel.find_child("down_main_elevator",true,false),"C4 duty first move")
			await click(panel.find_child("down_main_elevator",true,false),"C4 duty second move")
			await click(panel.submit_button,"C4 order submit")
			check(panel.session.completed and state.d.chapter4.factIds.has("a1_duty_board_reconstructed"),"real C4 order accepted")
			await click(panel.close_button,"return from completed duty device")
		"c4_numeric":
			await click(panel.submit_button,"C4 initial wrong calibration")
			check(not state.d.chapter4.factIds.has("a2_positioning_plate_calibrated") and not panel.session.feedback.is_empty(),"wrong calibration keeps live controls and no fact")
			for step in ["minus_horizontal","minus_horizontal","plus_vertical","plus_pressure","plus_pressure","plus_pressure"]:
				await click(panel.find_child(step,true,false),"C4 axis "+step)
			await click(panel.submit_button,"C4 calibration submit")
			check(panel.session.completed and state.d.chapter4.factIds.has("a2_positioning_plate_calibrated"),"real C4 numeric axis input accepted")
			await click(panel.close_button,"return from completed calibration")
	check(not is_instance_valid(main.modal),id+" source return closes modal")
	check(main.world_frame.is_visible_in_tree() and state.d.native.scene==scene,id+" source return retains visible world")
	if id=="kiosk":
		main.c3_narrative_host.tick(0,true)
		check(main.c3_narrative_host.current!=null,"real keypad submission reaches original narrative queue")
		for _i in range(300):
			if main.c3_narrative_host.current==null: break
			main.c3_narrative_host.tick(100,true)
		check(main.c3_narrative_host.current==null,"keypad dialogue completes in visible world")
	if id in ["mixer","c4_duty","c4_numeric"]:
		check(main.world.player==position,"source modal close retains exact world position")
		state.act("phone_refresh",{}); await process_frame
		check(main.world_frame.is_visible_in_tree(),"refresh after modal return keeps world visible")
		await interact(action)
		var reopened: Control=main.modal if c4 else main.c3_device_panel
		check(is_instance_valid(reopened) and reopened.is_visible_in_tree(),"same world device reopens live controls")
		if is_instance_valid(reopened):
			if c4: check(reopened.session.completed,"reopened C4 completed state comes from controller fact")
			else: check(reopened.model.layers.size()==1,"reopened mixer retains partial pour")
			await click(reopened.close_button if c4 else reopened.exit_button,"close reopened world device")
		check(not is_instance_valid(main.modal),"reopened world device closes through live control")

func rain_return() -> void:
	# The real issued reduced-motion rescue owns its elapsed clock and callback.
	# It intentionally returns a phone_home page together with a dorm scene.
	await prepare("mixer",390)
	state.d.native.scene="qizhen_lake"; state.d.native.page="c3_lake"; state.d.rpgScene="qizhen_lake"
	state.d.native.settings.reduced_motion=true; state.d.rpgCheckpoint="qizhen_dock"
	var q: Dictionary=state.d.qizhenLake
	q.active=true; q.phase="boarding_tutorial"; q.zone="dock"; q.vehicle="on_foot"
	q.kayakEquipped=true; q.leftPaddleEquipped=true; q.rightPaddleEquipped=true; q.rainWarningSeen=true
	q.rainSafetyCleared=false; q.rainRescueCompleted=false
	state.story_reset.emit(); state.changed.emit(); await process_frame; await process_frame
	main._show_world_mobile(); main.world.player=Vector2(690,620); main.world._sync_player()
	var request: Dictionary=state.act("c3_lake_target:qizhen_dock_board")
	check(request.has("world_effect"),"rain route issues actual source rescue")
	if not request.has("world_effect"): return
	main.world_effect.read_state=func()->Dictionary:return state.d
	var started: int=Time.get_ticks_msec()
	while not q.rainRescueCompleted and Time.get_ticks_msec()-started<5000: await create_timer(.025).timeout
	await process_frame; await process_frame
	check(q.rainRescueCompleted and state.d.native.scene=="dorm_hub" and state.d.native.page=="phone_home","genuine rescue callback produces original dorm/phone handoff")
	check(main.phone.is_visible_in_tree() and not main.world_frame.is_visible_in_tree(),"actual compact rain completion visibly reveals phone home")
	check(not main.mobile_world and main.world_page_origin_scene.is_empty(),"home handoff leaves no stale device navigation owner")

func closure_return() -> void:
	# Unmodified source checkpoint is scenario setup only. Both questions, full
	# source playback and final acknowledgment go through the actual activity.
	check(state.begin_checkpoint("c4-755-closure"),"source closure fixture loads")
	root.size=Vector2i(430,844); await process_frame; await process_frame
	main.world.set_process(false); main._show_world_mobile()
	var request: Dictionary=state.act("c4_lamp_start")
	check(request.has("game") and main.active_game==null and is_instance_valid(main.world_effect),"actual closure request starts source door before lamp")
	if not is_instance_valid(main.world_effect): return
	var door: Control=main.world_effect
	var before: Dictionary=state.d.chapter4.duplicate(true)
	var source_duration: float=door.source.presentationMs
	check(source_duration==1500.0,"door uses original 240ms delay, 880ms opening and 380ms hold")
	var started: int=Time.get_ticks_msec()
	var observed: Dictionary={"elapsed_ms":-1.0,"wall_ms":-1}
	door.opened.connect(func():
		observed.elapsed_ms=door.elapsed_ms
		observed.wall_ms=Time.get_ticks_msec()-started
	)
	# Let the real process/focus/delta-clamp clock deliver its registered callback.
	# A monotonic bound prevents hanging; no timers or story gates are shortened.
	while not is_instance_valid(main.active_game) and Time.get_ticks_msec()-started<10000:
		if not is_instance_valid(door): break
		await process_frame
	check(is_instance_valid(main.active_game),"actual source door completion issues final lamp activity")
	check(float(observed.elapsed_ms)>=source_duration,"registered door callback waits for full source clock")
	print("Door handoff observed: source=",observed.elapsed_ms,"ms; wall=",observed.wall_ms,"ms")
	check(state.d.chapter4==before,"door handoff never writes answer or completion facts")
	if not is_instance_valid(main.active_game): return
	var activity: Control=main.active_game; activity.set_process(false)
	await process_frame; await process_frame
	await click(activity.controls.get_child(0),"first original lamp answer")
	await click(activity.controls.get_child(0),"second original lamp answer")
	check(activity.stage=="playback" and state.d.chapter4.factIds.has("zhu_two_questions_answered"),"real answer controls save valid choices")
	for i in range(116): activity._process(.05)
	await process_frame; await process_frame
	check(activity.stage=="final" and not state.d.chapter4.completed,"full source playback still requires terminal acknowledgement")
	await click(find_button(activity,"我记住了"),"source closure acknowledgement")
	check(state.d.chapter4.completed and state.d.native.scene.is_empty() and state.d.native.page=="phone_home","actual closure callback closes world scene")
	check(main.phone.is_visible_in_tree() and not main.world_frame.is_visible_in_tree() and not main.mobile_world,"compact ending visibly returns to phone without stale world")
