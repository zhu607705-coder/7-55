extends "res://tests/test_compact_world_inventory.gd"
## Isolated source-phase fixtures using the real Main, inventory and world picker.
## This test does not claim an earned campaign or physical phone traversal.
const Chapter=preload("res://scripts/chapters/chapter3.gd")
var manual_part:="poster"
var manual_capture_index:=0
var manual_samples:Dictionary={}
func clue_fixture(dim:Vector2i,part:="poster",reduced:=false)->void:
	if is_instance_valid(shell):await shell.shutdown();shell.queue_free();await frames()
	state.d=state.initial();state.developer_mode=true;state.modules[1]=Chapter.new()
	state.d.native.chapter=3;state.d.native.scene="theater_interior";state.d.native.page="c3_theater";state.d.native.mode="light"
	state.d.runtimeMode="rpg";state.d.rpgScene="theater_interior";state.d.theaterHunt.active=true
	state.d.theaterHunt.phase="entry_ticket" if part=="poster" else "prop_setup"
	state.d.theaterHunt.ticketCodeRead=true;state.d.theaterHunt.admitted=part!="poster"
	state.d.theaterHunt.posterCleaned=part!="poster";state.d.theaterHunt.propBoxOpened=part!="poster"
	state.d.items.greaseTissue=part=="poster";state.d.items.fluorescentBrush=part!="poster"
	state.d.items.campusCard=true;state.d.ui.inventoryRecovered=true
	state.d.actOne.phase="complete";state.d.actOne.movementEnabled=true
	state.d.native.settings.music=false;state.d.native.settings.effects=false;state.d.native.settings.reduced_motion=reduced
	var p:=Vector2(476,755) if part=="poster" else Vector2(936,228)
	state.d.native.player={"x":p.x,"y":p.y,"scene":"theater_interior"}
	root.size=dim;shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(6)
	shell.mobile_world=true;shell.compact_inventory_open=true;shell._refresh();await frames(6)
	shell.world.player=p;shell.world._sync_player()
	# Frame the wide poster in the portrait inspection fixture, keeping its
	# original stand and source target. This is the normal camera pan field.
	if dim.x<1100 and part=="poster":shell.world.pan_offset=Vector2(-150,0)
	shell.world._update_camera();shell.world.grab_focus()
	for i in 180:
		if shell.world.transition_alpha<=0:break
		await process_frame
	check(shell.world.transition_alpha<=0,"real entry fade completed")
	await frames()

func clue_screen(part:String)->Vector2:
	var p:=Vector2(282,755) if part=="poster" else Vector2(936,145)
	return world_screen((p-shell.world.camera)*shell.world.zoom+shell.world.size/2)

func manual_key(e:InputEvent)->void:
	if not e is InputEventKey or not e.pressed:return
	if e.keycode in [KEY_F6,KEY_F7]:
		manual_part="poster" if e.keycode==KEY_F6 else "vent"
		manual_samples.clear()
		await clue_fixture(root.size,manual_part)
		print("THEATER_CLUE_MANUAL ",manual_part," target=",clue_screen(manual_part))
	if e.keycode==KEY_F11:
		await RenderingServer.frame_post_draw
		var path:=capture_path("theater-clue-%s-%03d.png"%[manual_part,manual_capture_index])
		manual_capture_index+=1;root.get_texture().get_image().save_png(path)
		print("THEATER_CLUE_CAPTURE ",ProjectSettings.globalize_path(path))

func capture_path(filename:String)->String:
	var directory:=OS.get_environment("THEATER_CLUE_CAPTURE_DIR")
	if directory.is_empty():directory="user://"
	DirAccess.make_dir_recursive_absolute(directory)
	return directory.path_join(filename)

func sample_manual()->void:
	if not is_instance_valid(shell) or shell.world.chapter3_layers==null:return
	var visual:RefCounted=shell.world.chapter3_layers.theater_clues
	var ms:float=visual.poster_ms if manual_part=="poster" else visual.dust_ms
	if not is_finite(ms):return
	var thresholds:Array=[400,850,1220] if manual_part=="poster" else [300,680,1060]
	for threshold:int in thresholds:
		var key:String=manual_part+"-"+str(threshold)
		if ms<threshold or manual_samples.has(key):continue
		manual_samples[key]=true
		await RenderingServer.frame_post_draw
		var path:String=capture_path("theater-clue-"+key+".png")
		root.get_texture().get_image().save_png(path)
		print("THEATER_CLUE_LIVE_SAMPLE ",key," elapsed=",ms," file=",ProjectSettings.globalize_path(path))

func run()->void:
	state=root.get_node("State")
	if OS.get_cmdline_user_args().has("--manual"):
		root.title="7:55 Theater clue physical response · isolated QA"
		await clue_fixture(Vector2i(390,844) if OS.get_cmdline_user_args().has("--portrait") else Vector2i(1280,820))
		root.window_input.connect(manual_key)
		process_frame.connect(sample_manual)
		print("THEATER_CLUE_MANUAL_READY: drag tissue to poster; F6 resets poster, F7 resets vent; F11 captures; target=",clue_screen("poster"))
		return
	create_timer(60).timeout.connect(func():push_error("Theater clue real-shell watchdog");quit(2))
	for dim in [Vector2i(1440,900),Vector2i(390,844)]:
		for part in ["poster","vent"]:
			await clue_fixture(dim,part)
			# Freeze only the world clock so the real gesture can inspect the exact
			# accepted edge. Main, inventory and pointer dispatch remain live.
			shell.world.set_process(false)
			var item:String="greaseTissue" if part=="poster" else "fluorescentBrush"
			var end:=clue_screen(part)
			await drag_item(item,end,dim.x<1100,true)
			check(state.d.items[item],"cancelled real drag retains "+item)
			await drag_item(item,end,dim.x<1100)
			check(not state.d.items[item],"real world drop consumes once: "+item)
			check(state.d.theaterHunt.posterCleaned if part=="poster" else state.d.theaterHunt.paperDusted,"real world drop commits original success")
			var visual:RefCounted=shell.world.chapter3_layers.theater_clues
			check(visual.poster_ms==0 if part=="poster" else visual.dust_ms==0,"accepted State.changed starts presentation at contact")
			check(not is_instance_valid(shell.world_effect) and not is_instance_valid(shell.modal),"clue animation mounts no blocking overlay")
			var items:Dictionary=state.d.items.duplicate(true)
			shell.world.set_process(true);await frames(3)
			shell._show_settings();await frames(4)
			check(visual.poster_ms==INF and visual.dust_ms==INF,"real settings interruption retires clue visuals")
			check(state.d.items==items,"real interruption keeps accepted consumption and reward intact")
			shell._close_modal();await frames(3)
			check(visual.poster_ms==INF and visual.dust_ms==INF,"closing settings does not replay completion")
	await clue_fixture(Vector2i(390,844),"vent")
	shell.world.set_process(false)
	await drag_item("fluorescentBrush",clue_screen("vent"),true)
	var phone_visual:RefCounted=shell.world.chapter3_layers.theater_clues
	# Native headless draw does not emit canvas draw signals; bind the real owner
	# directly in that renderer only. A GUI fixture binds during normal painting.
	if DisplayServer.get_name()=="headless":phone_visual._bind_owner(shell.world)
	check(phone_visual.paper_active(),"first ownership binding does not cancel the accepted dust edge")
	shell._show_phone_surface();await frames(3)
	check(not shell.world_frame.visible and not phone_visual.paper_active(),"opening real phone immediately settles the hidden paper")
	shell._return_from_phone();await frames(3)
	check(state.d.theaterHunt.paperDusted and not state.d.items.fluorescentBrush and not phone_visual.paper_active(),"phone return preserves accepted result without replay or rollback")
	await clue_fixture(Vector2i(390,844),"vent",true)
	await drag_item("fluorescentBrush",clue_screen("vent"),true)
	check(state.d.theaterHunt.paperDusted and not shell.world.chapter3_layers.theater_clues.paper_active(),"reduced motion settles directly after real accepted drop")
	if is_instance_valid(shell):await shell.shutdown();shell.queue_free();await frames()
	print("THEATER_CLUE_MAIN ",checks," checks; ",failures," failures");quit(1 if failures else 0)
