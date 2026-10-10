extends "res://tests/test_compact_world_inventory.gd"
## Declared local C3 fixture; real inventory gestures and world picker. This
## never claims a continuous earned route, navigation or physical mobile test.
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const Bike=preload("res://scripts/presentation/c3_bike_world_view.gd")
var bicycle=Bike.new()
func bike_fixture(dim: Vector2i,dark: bool=false) -> void:
	if is_instance_valid(shell):await shell.shutdown();shell.queue_free();await frames()
	state.d=state.initial();state.developer_mode=true;state.modules[1]=Chapter.new()
	state.d.native.chapter=3;state.d.native.scene="campus_bootstrap";state.d.native.page="c3_canteen";state.d.runtimeMode="rpg";state.d.rpgScene="campus_bootstrap"
	state.d.canteenHunt.active=true;state.d.canteenHunt.phase="chase_ready";state.d.canteenHunt.entryPaperEscaped=true
	state.d.native.mode="dark" if dark else "light";state.d.canteenHunt.mode=state.d.native.mode
	state.d.items.greaseTissue=true;state.d.items.cafeteriaWages=true;state.d.items.campusCard=true;state.d.wallet.cashCents=200
	var p: Vector2=bicycle.point()+Vector2(-70,60);state.d.native.player={"x":p.x,"y":p.y,"scene":"campus_bootstrap"}
	root.size=dim;shell=load("res://scripts/main.gd").new();shell.size=Vector2(dim);root.add_child(shell);await frames(5)
	shell.mobile_world=true;shell.compact_inventory_open=true;shell._refresh();await frames(6)
	shell.world.player=p;shell.world._sync_player();shell.world._update_camera();shell.world.queue_redraw();await frames()
	# Let the real scene-entry fade finish before freezing fixture movement.
	# Freezing too early produces a false dark-scene screenshot.
	for i in range(180):
		if shell.world.transition_alpha<=0:break
		await process_frame
	check(shell.world.transition_alpha<=0,"source scene transition completed before fixture freeze")
	shell.world.set_process(false)
func bike_screen() -> Vector2:
	var center: Vector2=bicycle.point()
	# Source code plate first, otherwise an alpha-visible body pixel. Resolve
	# actual drawn/occluding surfaces, never a nearest-compatible-object guess.
	var points: Array=[center+Vector2(16,-5)]
	for y in range(-25,31,2):
		for x in range(-44,45,2):points.append(center+Vector2(x,y))
	for point: Vector2 in points:
		if shell.world.object_picker.pick(point,shell.world.targets,true).get("id","")=="bike":return world_screen((point-shell.world.camera)*shell.world.zoom+shell.world.size/2)
	return Vector2.INF
func run() -> void:
	state=root.get_node("State")
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"isolated test profile")
	var baseline: bool=Input.emulate_mouse_from_touch;Input.emulate_mouse_from_touch=false
	# Geometry uses the exact same alpha as the visible source bicycle.
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/c3_bike_world_source.json"))
	check(Bike.DRAW.size()==source.bike.texture.primitives.size(),"all 16 source draw primitives present")
	for index in range(Bike.DRAW.size()):
		var actual: Dictionary=Bike.DRAW[index];var expected: Dictionary=source.bike.texture.primitives[index]
		check(actual.method==expected.method and actual.args.size()==expected.args.size(),"source drawing primitive and argument count")
		for i in range(actual.args.size()):check(is_equal_approx(float(actual.args[i]),float(expected.args[i])),"source primitive geometry")
		for key in actual.style:check(is_equal_approx(float(actual.style[key]),float(expected.style[key])),"source primitive color/alpha/stroke")
	check(bicycle.point()==Vector2(source.bike.anchor.x,source.bike.anchor.y),"world anchor matches source")
	var tex: Texture2D=bicycle.body_texture();check(tex!=null and tex.get_size()==Vector2(92,62),"source bicycle texture retains 92x62 dimensions")
	var picker=load("res://scripts/world_object_picker.gd").new();picker.add(["bike"],bicycle.geometry())
	var target: Array=[{"id":"bike","acceptedItems":["greaseTissue","cafeteriaWages"]}]
	check(picker.pick(bicycle.point()+Vector2(16,-5),target,true).get("id")=="bike","visible code plate is pickable")
	check(picker.pick(bicycle.point()+Vector2(-45,-30),target,true).is_empty(),"transparent sprite corner cannot accept item")
	check(picker.pick(bicycle.point()+Vector2(70,0),target,true).is_empty(),"empty area inside legacy 100px circle is not a hidden drop target")
	for dim in [Vector2i(1440,900),Vector2i(390,844),Vector2i(430,860),Vector2i(844,390)]:
		print("C3 bicycle viewport ",dim)
		await bike_fixture(dim)
		var end: Vector2=bike_screen();check(end.is_finite(),"source bicycle is rendered and pickable")
		if not end.is_finite():continue
		await drag_item("campusCard",end,dim.x<1100)
		check(not state.d.canteenHunt.bikeLockCleaned and state.d.items.campusCard and state.d.wallet.cashCents==200,"wrong item rejected without inventory or money changes")
		await drag_item("greaseTissue",world_screen((bicycle.point()+Vector2(135,0)-shell.world.camera)*shell.world.zoom+shell.world.size/2),dim.x<1100)
		check(not state.d.canteenHunt.bikeLockCleaned and state.d.items.greaseTissue,"miss beyond visible body retains tissue")
		await drag_item("greaseTissue",end,dim.x<1100,true)
		check(not state.d.canteenHunt.bikeLockCleaned and state.d.items.greaseTissue,"cancelled native drag cannot clean lock")
		await drag_item("cafeteriaWages",end,dim.x<1100)
		check(not state.d.canteenHunt.bikePaid and state.d.wallet.cashCents==200 and state.d.items.cafeteriaWages,"wages cannot pay before glare is cleaned")
		await drag_item("greaseTissue",end,dim.x<1100)
		check(state.d.canteenHunt.bikeLockCleaned and state.d.items.greaseTissue,"actual source-body drop cleans and retains tissue")
		check(not is_instance_valid(shell.modal),"world drop uses item directly without opening answer panel")
		await drag_item("cafeteriaWages",end,dim.x<1100)
		check(state.d.canteenHunt.bikePaid and state.d.wallet.cashCents==0 and not state.d.items.cafeteriaWages,"actual source-body wage drop pays exactly once")
		check(not state.d.canteenHunt.bikeCodeRead,"world clean/pay has no dark-inspection prerequisite")
		check(state.d.native.selected_item=="","successful world item use clears selection")
		await bike_fixture(dim,true);end=bike_screen()
		await drag_item("greaseTissue",end,dim.x<1100);await drag_item("cafeteriaWages",end,dim.x<1100)
		check(not state.d.canteenHunt.bikeLockCleaned and not state.d.canteenHunt.bikePaid and state.d.wallet.cashCents==200,"dark world drops refuse both operations")
		# Selection plus Space is the existing keyboard alternative to dragging.
		state.toggle_mode();state.select_item("greaseTissue");await frames();shell.world.grab_focus()
		for down in [true,false]:
			var k:=InputEventKey.new();k.keycode=KEY_SPACE;k.physical_keycode=KEY_SPACE;k.pressed=down;event(k);await frames(2)
		check(state.d.canteenHunt.bikeLockCleaned and state.d.items.greaseTissue,"selected-item Space alternative reaches same controller")
	Input.emulate_mouse_from_touch=baseline
	if is_instance_valid(shell):await shell.shutdown();shell.queue_free();await frames()
	print("C3 bicycle actual world drops: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
