extends "res://tests/test_compact_world_inventory.gd"
## Real Main/root-input fixture, adapted from PR117's source poster fixture.
## No new theater objects, automatic success, or earned-navigation claim.
const Chapter=preload("res://scripts/chapters/chapter3.gd")
var manual_reported:=false
var capture_index:=0

func poster_fixture(dim:Vector2i)->void:
	if is_instance_valid(shell):await shell.shutdown();shell.queue_free();await frames()
	state.d=state.initial();state.developer_mode=true;state.modules[1]=Chapter.new()
	state.d.native.chapter=3;state.d.native.scene="theater_interior";state.d.native.page="c3_theater";state.d.native.mode="light"
	state.d.runtimeMode="rpg";state.d.rpgScene="theater_interior";state.d.theaterHunt.active=true
	state.d.theaterHunt.phase="entry_ticket";state.d.theaterHunt.ticketCodeRead=true
	state.d.items.greaseTissue=true;state.d.items.campusCard=true;state.d.ui.inventoryRecovered=true
	state.d.actOne.phase="complete";state.d.actOne.movementEnabled=true
	state.d.native.settings.music=false;state.d.native.settings.effects=false
	state.d.native.player={"x":476,"y":755,"scene":"theater_interior"}
	root.size=dim;shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(6)
	shell.mobile_world=true;shell.compact_inventory_open=true;shell._refresh();await frames(6)
	shell.world.player=Vector2(476,755);shell.world._sync_player()
	# Normal camera pan field; the source target and stand remain unchanged.
	if dim.x<1100:shell.world.pan_offset=Vector2(-150,0)
	shell.world._update_camera();shell.world.grab_focus()
	for i in 180:
		if shell.world.transition_alpha<=0:break
		await process_frame
	check(shell.world.transition_alpha<=0,"real source entry fade completed")
	await frames()

func poster_screen()->Vector2:
	return world_screen((Vector2(282,755)-shell.world.camera)*shell.world.zoom+shell.world.size/2)

func capture(label:String)->void:
	var directory:=OS.get_environment("INVENTORY_RELEASE_CAPTURE_DIR")
	if directory.is_empty() or DisplayServer.get_name()=="headless":return
	if not directory.begins_with("/tmp/"):push_error("Capture directory must be under /tmp");return
	DirAccess.make_dir_recursive_absolute(directory)
	await RenderingServer.frame_post_draw
	var path:=directory.path_join(label+".png")
	root.get_texture().get_image().save_png(path)
	print("INVENTORY_RELEASE_CAPTURE ",path)

func manual_key(e:InputEvent)->void:
	if e is InputEventMouseButton:
		print("INVENTORY_RELEASE_MANUAL_POINTER ",e.position," down=",e.pressed," dragging=",root.gui_is_dragging())
	if not e is InputEventKey or not e.pressed or e.echo:return
	if e.keycode==KEY_F6:
		manual_reported=false;await poster_fixture(root.size);await manual_ready()
	elif e.keycode==KEY_F11:
		await capture("manual-%03d"%capture_index);capture_index+=1

func manual_ready()->void:
	var item:Control=await reveal("greaseTissue")
	print("INVENTORY_RELEASE_MANUAL_READY source=",item.get_global_rect().get_center()," target=",poster_screen()," viewport=",root.size)
	await capture("manual-ready")

func sample_manual()->void:
	if not manual_reported and state.d.theaterHunt.posterCleaned:
		manual_reported=true
		print("INVENTORY_RELEASE_MANUAL_ACCEPTED tissue=",state.d.items.greaseTissue," ticket=",state.d.items.theaterTicketHalfA," target=",poster_screen())
		await capture("manual-accepted")

func run()->void:
	# Refuse before any fixture/state change. Production saves are never touched.
	if not ProjectSettings.globalize_path("user://").begins_with("/tmp/"):
		push_error("INVENTORY_RELEASE_TEMP_PROFILE_REQUIRED");quit(2);return
	state=root.get_node("State");state.developer_mode=true
	state.action_completed.connect(func(id,_a,_b,_c):actions.append(id))
	state.feedback.connect(func(message):feedback.append(message))
	if OS.get_cmdline_user_args().has("--manual"):
		state.feedback.connect(func(message):print("INVENTORY_RELEASE_MANUAL_FEEDBACK ",message))
		root.title="7:55 inventory release · isolated source fixture"
		await poster_fixture(Vector2i(390,844))
		root.window_input.connect(manual_key);process_frame.connect(sample_manual)
		await manual_ready();return
	create_timer(120).timeout.connect(func():push_error("Inventory release Main watchdog");quit(2))
	for dim:Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(844,390),Vector2i(1440,900)]:
		for using_touch:bool in [false,true]:
			await poster_fixture(dim)
			var end:=poster_screen()
			var label:="%dx%d-%s"%[dim.x,dim.y,"touch" if using_touch else "mouse"]
			check(shell.world._pick_target(Vector2(282,755),true).get("id")=="theater_poster","unchanged original poster target exists")
			await drag_item("campusCard",end,using_touch)
			check(not state.d.theaterHunt.posterCleaned and state.d.items.campusCard and state.d.items.greaseTissue,"wrong item retains both items")
			await drag_item("greaseTissue",end,using_touch,true)
			check(not state.d.theaterHunt.posterCleaned and state.d.items.greaseTissue,"cancelled gesture cannot commit")
			# Deliberately leave the last motion over the valid poster, then release
			# outside the world without another motion. Stale hover must not win.
			var item:Control=await reveal("greaseTissue")
			var from:=await begin_drag(item,using_touch)
			if using_touch:finger(end,end-from)
			else:motion(end,end-from,MOUSE_BUTTON_MASK_LEFT)
			await frames(2)
			var rejected_before:=actions.count("c3_target:theater_poster")
			var selection_before:String=state.d.native.selected_item
			if using_touch:touch(Vector2(4,4),false)
			else:mouse(Vector2(4,4),false)
			await frames()
			check(not state.d.theaterHunt.posterCleaned and state.d.items.greaseTissue and not state.d.items.theaterTicketHalfA,"release outside world rejects the last valid hover")
			check(actions.count("c3_target:theater_poster")==rejected_before and state.d.native.selected_item==selection_before and not is_instance_valid(shell.modal),"outside release sends no controller action or new selection/modal")
			check(not root.gui_is_dragging() and Gesture.touch_owner()==null,"outside release retires its pointer owner")
			# Keep the positive case independent even on a buggy baseline that
			# wrongly consumes the tissue during the rejected release above.
			await poster_fixture(dim)
			end=poster_screen()
			await capture(label+"-before")
			var before:=actions.count("c3_target:theater_poster")
			await drag_item("greaseTissue",end,using_touch)
			check(state.d.theaterHunt.posterCleaned and not state.d.items.greaseTissue and state.d.items.theaterTicketHalfA,"root inventory release consumes tissue and grants original ticket")
			check(actions.count("c3_target:theater_poster")==before+1,"exactly one original controller action")
			var accepted:Dictionary=state.d.items.duplicate(true)
			if using_touch:touch(end,false)
			else:mouse(end,false)
			await frames()
			check(state.d.items==accepted and actions.count("c3_target:theater_poster")==before+1,"duplicate release cannot repeat the action")
			check(not root.gui_is_dragging() and Gesture.touch_owner()==null,"accepted release retires drag and touch owner")
			await capture(label+"-after")
			print("INVENTORY_RELEASE_MAIN_CASE ",label," accepted=",state.d.theaterHunt.posterCleaned," target=",end)
	if is_instance_valid(shell):await shell.shutdown();shell.queue_free();await frames()
	print("INVENTORY_RELEASE_MAIN ",checks," checks; ",failures," failures");quit(1 if failures else 0)
