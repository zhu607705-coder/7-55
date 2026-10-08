extends SceneTree
const Fixture=preload("res://tests/canteen_native_fixture.gd")
const Pose=preload("res://scripts/presentation/c3_return_stack_pose.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var hand:=Vector2(1466,605);var anchor:=Vector2(1497,555);var height:float=28.716
	for reduced:bool in [false,true]:
		var duration:float=Pose.duration(reduced)
		var start:Dictionary=Pose.sample(0,hand,anchor,height,reduced)
		var touch:Dictionary=Pose.sample(duration*.3125,hand,anchor,height,reduced)
		var weight:Dictionary=Pose.sample(duration*.5625,hand,anchor,height,reduced)
		var end:Dictionary=Pose.sample(duration,hand,anchor,height,reduced)
		check(start.position==hand and start.size==24 and start.alpha==1,"first frame matches carried tray footprint")
		check(float(touch.pressure)==0 and touch.alpha==1,"corner contact remains opaque before stack takes weight")
		check(float(weight.pressure)>0 and is_equal_approx(float(weight.angle),-PI/2),"weight lands only after tray is laid flat")
		check(weight.position==weight.contact and weight.alpha==1,"impact tray follows compressed top surface")
		check(float(end.pressure)==0 and end.alpha==0 and end.settled,"terminal pose resets stack and retires moving tray")
		for boundary:float in [.3125,.5625,.75,.80,1.0]:
			var a:Dictionary=Pose.sample(maxf(0,duration*boundary-.000001),hand,anchor,height,reduced)
			var b:Dictionary=Pose.sample(duration*boundary,hand,anchor,height,reduced)
			check(a.position.distance_to(b.position)<.01 and absf(float(a.angle)-float(b.angle))<.01,"poses are continuous at semantic boundary")
	check(Pose.duration(true)<Pose.duration(false),"reduced mode has a shorter presentation without controller wait")
	var state:Node=root.get_node("State");Fixture.install(state)
	state.d.native.positions={"canteen_interior:":{"x":1466.0,"y":608.0}}
	state.d.canteenHunt.carriedTrayIds=["tray_blue_01"]
	var world:Control=load("res://scripts/world.gd").new();world.size=Vector2(1280,800);root.add_child(world);await process_frame;world.set_process(false)
	world.player=Vector2(1466,608);world._sync_player()
	var scene:Node2D=world.native_canteen;scene.set_process(false);scene.sync(state.d,"canteen_interior")
	var cash_before:int=int(state.d.wallet.cashCents);var result:Dictionary=state.act("c3_target:auntie");scene.sync(state.d,"canteen_interior")
	check(state.d.canteenHunt.returnedTrayIds==["tray_blue_01"] and state.d.canteenHunt.carriedTrayIds.is_empty(),"original action immediately commits one returned tray")
	check(scene.return_age==0 and scene.return_start==world.player+Vector2(0,-3),"accepted fact starts at recorded hand, once")
	scene.configure_view(Vector2.ZERO,1,world.player)
	check(float(scene.source_space.get_node("return_contact").get_meta("source_depth"))>float(scene.player_sprite.get_meta("source_depth")),"initial returned tray stays in front of the player like the carried tray")
	check(not scene._return_surface().is_empty(),"visible temporary tray contributes alpha occlusion in the unified surface pass")
	check(int(state.d.wallet.cashCents)==cash_before and not state.d.items.cafeteriaWages,"first return cannot invent a completion reward")
	scene._process(.05);var after_tick:float=scene.return_age;scene.sync(state.d,"canteen_interior")
	check(scene.return_age==after_tick,"unchanged repeated sync cannot restart the return")
	for i in range(7):scene._process(.05)
	var stack:Node2D=scene.objects.return_stack
	check(scene.return_pose().alpha==0 and stack.parts[0].sprite.scale==stack.parts[0].base_scale,"stack settles to exact original geometry")
	check(scene._return_surface().is_empty(),"retired temporary tray leaves no invisible pick occluder")
	state.d=state.d.duplicate(true);scene.sync(state.d,"canteen_interior")
	check(scene.return_age>1 and state.d.canteenHunt.returnedTrayIds==["tray_blue_01"],"ordinary state replacement preserves fact and never replays")
	scene.return_age=.12;scene._process(.02);scene.sync(state.d,"campus_bootstrap")
	check(not scene.visible and scene.return_age>1 and stack.parts[0].sprite.scale==stack.parts[0].base_scale,"region exit cancels and restores stack geometry")
	var out:String=OS.get_environment("RETURN_STACK_REPORT")
	if not out.is_empty():
		var f:=FileAccess.open(out,FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"original_result":result,"fixture":true},"\t"));f.close()
	print("CANTEEN_RETURN_STACK ",checks," checks; ",failures," failures")
	world.queue_free();await process_frame;quit(1 if failures else 0)
