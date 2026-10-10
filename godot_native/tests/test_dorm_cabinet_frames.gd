extends SceneTree
## Registered art and original-controller timing, not a second cabinet state machine.
var failures:=0
var checks:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("DORM FRAMES: "+label)
func frames(n:=3) -> void:
	for i in n:await process_frame
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var atlas: Image=load("res://assets/native/dorm_cabinet/cabinet_opening_frames.png").get_image()
	var plate: Image=load("res://assets/rpg/interiors/dorm_hub.png").get_image()
	check(atlas.get_size()==Vector2i(1024,512),"registered atlas is four exact 256px columns and two rows")
	var exact_closed:=true
	var transparent_outside:=true
	var all_distinct:=true
	var seen: Array[PackedByteArray]=[]
	for frame in 8:
		var image:=atlas.get_region(Rect2i((frame%4)*256,(frame/4)*256,256,256))
		var bytes:=image.get_data()
		if bytes in seen:all_distinct=false
		seen.append(bytes)
		for y in 256:
			for x in 256:
				var color:=image.get_pixel(x,y)
				# The right physical hinge / leaf-tip edge is at x193, inclusive.
				if (x<61 or x>193 or y<41 or y>=192) and color.a!=0:transparent_outside=false
				if frame==0 and x>=61 and x<193 and y>=41 and y<181 and color!=plate.get_pixel(x+360,y+208):exact_closed=false
	check(exact_closed,"closed frame is byte-faithful original source art")
	check(transparent_outside,"background and non-occluded outer cabinet shell are truly transparent")
	check(all_distinct,"all eight poses have different pixel data")
	var state=root.get_node("State")
	state.begin_checkpoint("c2-inventory")
	var shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell._show_world_mobile();shell._layout();await frames()
	var adapter=shell.world.native_dorm
	adapter.set_process(false);adapter.sync(state.d,"dorm_hub")
	var story_before:=JSON.stringify(state.d.actOne)
	var items_before:=JSON.stringify(state.d.items)
	check(adapter.cabinet_frame_index()==0,"initial source pose")
	state.act("c2_dorm_prop","cabinet_open")
	for i in range(1,8):
		adapter._process(.26/7.0+.000001)
		check(adapter.cabinet_frame_index()==i,"opening uses authored pose "+str(i))
	check(is_equal_approx(adapter.cabinet_amount,1.0),"original 260ms endpoint")
	for i in range(1,7):
		adapter.cabinet_amount=float(i)/7.0+.000001
		check(adapter.cabinet_frame_index()==i,"same registered selection on reverse "+str(i))
	adapter.cabinet_amount=.6
	state.act("c2_dorm_prop","cabinet_open")
	adapter._process(.13)
	check(is_equal_approx(adapter.cabinet_amount,.1),"mid-animation reversal retains original speed")
	adapter._process(.026001)
	check(adapter.cabinet_amount==0 and adapter.cabinet_frame_index()==0,"close restores exact original pose")
	check(JSON.stringify(state.d.actOne)==story_before and JSON.stringify(state.d.items)==items_before,"art never changes story or item facts")
	state.d.native.settings.reduced_motion=true;adapter.sync(state.d,"dorm_hub")
	state.act("c2_dorm_prop","cabinet_open");adapter._process(.001)
	check(adapter.cabinet_amount==1 and adapter.cabinet_frame_index()==7,"reduced motion uses stable authored open pose immediately")
	state.d.native.settings.reduced_motion=false;adapter.sync(state.d,"dorm_hub")
	state.developer_mode=false
	check(state.save_game(),"ordinary open cabinet save")
	state.d=state.initial();check(state.load_game(),"ordinary open cabinet reload")
	adapter.sync(state.d,"dorm_hub")
	check(adapter.cabinet_amount==1 and adapter.cabinet_frame_index()==7,"reload restores stable pose without opening replay")
	state.act("c2_dorm_prop","cabinet_open");adapter._process(.27)
	check(state.save_game(),"ordinary closed cabinet save")
	state.d=state.initial();check(state.load_game(),"ordinary closed cabinet reload")
	adapter.sync(state.d,"dorm_hub")
	check(not adapter.reduced and adapter.cabinet_amount==0 and adapter.cabinet_frame_index()==0,"ordinary-motion reload restores exact closed endpoint")
	await shell.shutdown();shell.free();await frames()
	print("DORM CABINET FRAMES: %d checks / %d failures" % [checks,failures]);quit(1 if failures else 0)
