extends SceneTree
var host:SubViewportContainer
var viewport:SubViewport
var world:Node2D
func _initialize()->void:run.call_deferred()
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():printerr("Use samples/future_learning_center/run.mjs");quit(2);return
	root.title="7:55 · 未来学习中心 · 单间拼接 / 房间镜头"
	RenderingServer.set_default_clear_color(Color("101820"))
	host=SubViewportContainer.new();host.size=Vector2(960,540);host.stretch=false;root.add_child(host)
	viewport=SubViewport.new();viewport.size=Vector2i(960,540);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;host.add_child(viewport)
	world=load("res://campuses/future_learning_center/scripts/floor_view.gd").new();viewport.add_child(world)
	root.size_changed.connect(fit);fit()
	if not OS.get_environment("FLC_CAPTURE_DIR").is_empty():
		if OS.get_environment("FLC_INPUT_CHECK")=="1":await check_input()
		if OS.get_environment("FLC_WORKSHOP_CHECK")=="1":await check_workshop()
		if OS.get_environment("FLC_STAIRS_CHECK")=="1":await check_stairs()
		await capture_review()
		if OS.get_environment("FLC_CAPTURE_MOTION")=="1":await capture_motion()
		quit()
func fit()->void:
	var ratio:float=minf(root.size.x/960.0,root.size.y/540.0)
	host.scale=Vector2.ONE*ratio;host.position=(Vector2(root.size)-Vector2(960,540)*ratio)/2

func check_stairs()->void:
	var results:Array[Dictionary]=[]
	world.load_floor(2);world.user_control=true
	results.append({"name":"stairs require source landing","passed":not world.travel_to(3)})
	var landing:Dictionary=world.data.transits.filter(func(t:Dictionary)->bool:return t.id=="northeast_stair")[0]
	world.set_foot(Vector2(landing.arrival[0],landing.arrival[1]));await process_frame
	await key(KEY_E,true);await key(KEY_E,false);await tap(Vector2(470,385))
	results.append({"name":"real transit button starts ascent without early floor change","passed":world.stairs.visible and world.data.floor==2})
	if not world.stairs.visible:push_error("STAIR_INPUT could not open actual transit button");return
	results.append({"name":"duplicate floor input rejected","passed":not world.travel_to(3)})
	await create_timer(1.8).timeout;await capture("stairs_up")
	world.stairs._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var paused:float=world.stairs.model.distance;await create_timer(.25).timeout
	results.append({"name":"focus loss pauses feet on tread","passed":world.stairs.model.paused and absf(world.stairs.model.distance-paused)<.001})
	await tap(Vector2(480,500))
	results.append({"name":"scaled tap resumes traversal","passed":not world.stairs.model.paused})
	var limit:=0
	while world.stairs.visible and world.stairs.model.progress()<.45 and limit<1000:await process_frame;limit+=1
	await capture("stairs_landing")
	world.stairs.model.pause();world.stairs.fixed_camera=true;await capture("stairs_section");world.stairs.fixed_camera=false;world.stairs.model.resume()
	limit=0
	while world.stairs.visible and limit<1500:await process_frame;limit+=1
	results.append({"name":"ascent reaches paired legal landing","passed":world.data.floor==3 and world.space.can_stand(world.player) and world.transit.nearby(world.data,world.player).get("id")=="northeast_stair"})
	world.open_transit();await process_frame;await tap(Vector2(380,385));await create_timer(1.8).timeout;await capture("stairs_down")
	results.append({"name":"descent retains source until landing","passed":world.stairs.visible and world.data.floor==3 and world.stairs.model.direction==-1})
	await key(KEY_ESCAPE,true);await key(KEY_ESCAPE,false)
	results.append({"name":"cancel restores unchanged source floor","passed":not world.stairs.visible and world.data.floor==3 and world.stair_destination.is_empty()})
	world.open_transit();await process_frame;await tap(Vector2(380,385))
	limit=0
	while world.stairs.visible and limit<1500:await process_frame;limit+=1
	results.append({"name":"descent reaches paired legal landing","passed":world.data.floor==2 and world.space.can_stand(world.player)})
	# Check the second staircase and the other adjacency with the same live view.
	world.load_floor(3);landing=world.data.transits.filter(func(t:Dictionary)->bool:return t.id=="southwest_stair")[0]
	world.set_foot(Vector2(landing.arrival[0],landing.arrival[1]));world.travel_to(4)
	results.append({"name":"3F to 4F uses southwest paired section","passed":world.stairs.visible and world.stairs.model.via=="southwest_stair"})
	world.stairs.model.step(30);world._finish_stairs(world.stairs.model.take_arrival())
	results.append({"name":"4F arrival is grounded","passed":world.data.floor==4 and world.space.can_stand(world.player)})
	var failures:Array=results.filter(func(row:Dictionary)->bool:return not row.passed)
	for failure:Dictionary in failures:push_error("STAIR_INPUT: "+str(failure.name))
	var output:=OS.get_environment("FLC_CAPTURE_DIR");var file:=FileAccess.open(output.path_join("stairs_input.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":results,"failures":failures.size(),"viewport":[root.size.x,root.size.y],"scale":host.scale.x},"  "));file.close()
	print("FLC_STAIR_INPUT: %d checks, %d failures"%[results.size(),failures.size()]);world.load_floor(3)
func capture(label:String)->void:
	var folder:=OS.get_environment("FLC_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(folder)
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(label+".png"))
func capture_review()->void:
	await process_frame;await process_frame
	world.user_control=false
	var report:={"floors":[],"viewport":[root.size.x,root.size.y],"illegalFrames":0}
	for f:int in [2,3,4]:
		if not world.load_floor(f):push_error("Could not load floor %d"%f);continue
		world.set_hour(12)
		for room:Dictionary in world.data.rooms:
			var area:Rect2=world.Space.rect(room.bounds);var point:=area.get_center()
			if room.id=="pantry":point=Vector2(world.data.loungeReference.capture[0],world.data.loungeReference.capture[1])
			var found:bool=world.set_foot(point)
			if not found:
				for offset:Vector2 in [Vector2(0,100),Vector2(-120,0),Vector2(120,0),Vector2(0,200),Vector2(-200,100)]:
					if world.set_foot(point+offset):found=true;break
			if found:await capture("f%d_%s"%[f,room.id])
		if world.data.has("hallReference"):
			if world.set_foot(Vector2(world.data.hallReference.capture[0],world.data.hallReference.capture[1])):await capture("f%d_hall"%f)
			for view:Array in [["under",world.data.hallReference.frameCenter],["behind",world.data.hallReference.walkThrough[0]],["front",world.data.hallReference.walkThrough[1]]]:
				if world.set_foot(Vector2(view[1][0],view[1][1])):await capture("f%d_hall_%s"%[f,str(view[0])])
		if f==3:
			var atrium:Rect2=world.Space.rect(world.data.atrium.bounds)
			if world.set_foot(Vector2(atrium.position.x-170,atrium.position.y+460)):await capture("f3_atrium_corridor")
		var light_room:String={2:"electrical",3:"studio_1",4:"focus_a"}[f]
		var module:Dictionary=world.data.modules.filter(func(r:Dictionary)->bool:return r.id==light_room)[0]
		var light_position:Vector2=world.Space.rect(module.bounds).get_center()
		if not world.set_foot(light_position):world.set_foot(light_position+Vector2(120,0))
		for hour:int in [8,12,16,21]:
			world.set_hour(hour);await capture("f%d_light_%02d"%[f,hour])
		world.set_hour(12)
		world.overview=true;world.framing.update(0,world.player,world.space,true,true);world._apply_camera();world.queue_redraw()
		await capture("floor_%d_overview"%f)
		if OS.get_environment("FLC_EXPORT_MAP")=="1":await export_map()
		report.floors.append({"floor":f,"world":world.data.world,"objects":world.data.objects.size(),"doors":world.data.doors.size(),"transits":world.data.transits.size(),"rejectedLinks":world.space.invalid_links})
	report.illegalFrames=world.invalid_frames
	var file:=FileAccess.open(OS.get_environment("FLC_CAPTURE_DIR").path_join("capture.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	world.load_floor(3)

func capture_legacy()->void:
	await process_frame;await process_frame
	world.user_control=false
	await capture("studio_room")
	for target:Array in [["seminar",Vector2(700,560)],["recording",Vector2(700,650)],["pantry",Vector2(650,650)],["xlab_south",Vector2(450,1000)]]:
		for row:Dictionary in world.data.modules:
			if row.id!=target[0]:continue
			var foot:Vector2=Vector2(row.at[0],row.at[1])+(target[1]-Vector2(row.crop[0],row.crop[1]))*float(row.scale)
			if not world.set_foot(foot):push_error("Invalid screenshot position: "+str(target[0]));continue
			await create_timer(.15).timeout;await capture(str(target[0])+"_room")
	world.overview=true;world.framing.update(0,world.player,world.space,true,true);world._apply_camera();world.queue_redraw()
	await capture("floor_overview")
	var report:={"floor":3,"world":world.data.world,"viewport":str(root.size),"illegalFrames":world.invalid_frames,"graphRejectedEdges":world.space.invalid_links,"modules":world.data.modules.size()}
	var file:=FileAccess.open(OS.get_environment("FLC_CAPTURE_DIR").path_join("capture.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
func export_map()->void:
	world.capture_only=true;world.ui.hide();viewport.transparent_bg=true
	viewport.size=Vector2i(ceili(world.data.world[0]),ceili(world.data.world[1]))
	world.camera.position=Vector2(viewport.size)/2;world.camera.zoom=Vector2.ONE;world.camera.force_update_scroll();world.queue_redraw()
	await process_frame;await RenderingServer.frame_post_draw
	var plate:Image=viewport.get_texture().get_image()
	var output:=OS.get_environment("FLC_CAPTURE_DIR")
	plate.save_png(output.path_join("floor_%d_assembled.png"%int(world.data.floor)))
	plate.resize(roundi(2000.0*plate.get_width()/plate.get_height()),2000,Image.INTERPOLATE_LANCZOS);plate.save_png(output.path_join("floor_%d_assembled_preview.png"%int(world.data.floor)))
	viewport.size=Vector2i(960,540);viewport.transparent_bg=false;world.capture_only=false;world.ui.show()
	world.framing.update(0,world.player,world.space,true,world.overview);world._apply_camera()
func capture_motion()->void:
	var output:=OS.get_environment("FLC_CAPTURE_DIR").path_join("motion")
	DirAccess.make_dir_recursive_absolute(output)
	world.overview=false;world.user_control=true;world.set_process(false)
	var door:Dictionary=world.data.doors[0]
	var inside:=Vector2(door.inside[0],door.inside[1]);var outside:=Vector2(door.outside[0],door.outside[1])
	world.set_foot(inside-Vector2(480,0))
	world.request_walk(outside+Vector2(140,0))
	for frame:int in 420:
		if frame==220:world.request_walk(inside-Vector2(480,0))
		world._process(1.0/30.0)
		await process_frame;await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(output.path_join("frame_%04d.png"%frame))
	world.set_process(true)
func key(code:Key,pressed:bool)->void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	Input.parse_input_event(event);await process_frame
func check_input()->void:
	var checks:=0;var failures:=0
	root.grab_focus();await process_frame;await process_frame
	var spawn:=Vector2(world.data.spawn[0],world.data.spawn[1])
	world.set_foot(spawn);world.user_control=true
	var before:Vector2=world.player
	await key(KEY_D,true);await create_timer(.35).timeout;await key(KEY_D,false)
	checks+=1
	if world.player.distance_to(before)<30 or not world.space.can_stand(world.player):failures+=1;push_error("FLC_INPUT keyboard did not move legally: %s -> %s"%[str(before),str(world.player)])
	await key(KEY_W,true);await create_timer(1.2).timeout;await key(KEY_W,false)
	checks+=1
	if not world.space.can_stand(world.player):failures+=1;push_error("FLC_INPUT crossed north wall")
	before=world.player
	await key(KEY_S,true);await create_timer(.3).timeout;await key(KEY_S,false)
	checks+=1
	if world.player.distance_to(before)<30:failures+=1;push_error("FLC_INPUT cannot retreat from wall: %s -> %s"%[str(before),str(world.player)])
	world.set_foot(spawn)
	var target:Vector2=spawn+Vector2(160,30)
	var screen:Vector2=host.position+world.world_to_screen(target)*host.scale
	var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=screen;touch.pressed=true
	root.push_input(touch,true);await process_frame
	touch=touch.duplicate();touch.pressed=false;root.push_input(touch,true)
	await create_timer(1.1).timeout
	checks+=1
	if (world.player+world.Body.FOOT_CENTER_OFFSET).distance_to(target)>8:failures+=1;push_error("FLC_INPUT scaled touch did not reach target")
	var touch_final:Vector2=world.player+world.Body.FOOT_CENTER_OFFSET
	world.load_floor(2)
	var passage:Array=world.data.hallReference.walkThrough
	world.set_foot(Vector2(passage[0][0],passage[0][1]))
	await key(KEY_S,true);await create_timer(1.0).timeout;await key(KEY_S,false)
	checks+=1
	if world.player.y+world.Body.FOOT_CENTER_OFFSET.y<float(passage[1][1])-8:failures+=1;push_error("FLC_INPUT cannot walk under overhead hall frame")
	var post:Dictionary=world.data.objects.filter(func(o:Dictionary)->bool:return o.id=="hall_frame_front_left")[0]
	var post_box:Rect2=world.Space.rect(post.footprint)
	world.set_foot(post_box.get_center()-Vector2(0,70))
	await key(KEY_S,true);await create_timer(.8).timeout;await key(KEY_S,false)
	checks+=1
	if world.player.y+world.Body.FOOT_CENTER_OFFSET.y>=post_box.position.y or not world.space.can_stand(world.player):failures+=1;push_error("FLC_INPUT crossed hall post")
	before=world.player
	await key(KEY_W,true);await create_timer(.25).timeout;await key(KEY_W,false)
	checks+=1
	if world.player.distance_to(before)<35:failures+=1;push_error("FLC_INPUT cannot retreat from hall post")
	world.load_floor(3)
	var table:Dictionary=world.data.objects.filter(func(o:Dictionary)->bool:return o.id==world.data.loungeReference.table)[0]
	var table_box:Rect2=world.Space.rect(table.footprint)
	world.set_foot(Vector2(table_box.end.x+90,table_box.get_center().y))
	await key(KEY_A,true);await create_timer(.7).timeout;await key(KEY_A,false)
	checks+=1
	if world.player.x+world.Body.FOOT_CENTER_OFFSET.x<=table_box.end.x or not world.space.can_stand(world.player):failures+=1;push_error("FLC_INPUT crossed pantry table")
	before=world.player
	await key(KEY_D,true);await create_timer(.25).timeout;await key(KEY_D,false)
	checks+=1
	if world.player.distance_to(before)<35:failures+=1;push_error("FLC_INPUT cannot retreat from pantry table")
	var lounge_target:=Vector2(table_box.position.x-70,table_box.get_center().y)
	var lounge_screen:Vector2=host.position+world.world_to_screen(lounge_target)*host.scale
	touch=InputEventScreenTouch.new();touch.index=0;touch.position=lounge_screen;touch.pressed=true
	root.push_input(touch,true);await process_frame
	touch=touch.duplicate();touch.pressed=false;root.push_input(touch,true)
	await create_timer(5.5).timeout
	checks+=1
	if (world.player+world.Body.FOOT_CENTER_OFFSET).distance_to(lounge_target)>8:failures+=1;push_error("FLC_INPUT touch route cannot circle pantry table and chairs")
	var lounge_final:Vector2=world.player+world.Body.FOOT_CENTER_OFFSET
	var sofa:Dictionary=world.data.objects.filter(func(o:Dictionary)->bool:return o.get("cluster","")=="pantry_lounge" and o.asset=="sofa")[0]
	var sofa_box:Rect2=world.Space.rect(sofa.footprint)
	world.set_foot(Vector2(sofa_box.get_center().x,sofa_box.end.y+60))
	await key(KEY_W,true);await create_timer(.6).timeout;await key(KEY_W,false)
	checks+=1
	if world.player.y+world.Body.FOOT_CENTER_OFFSET.y<=sofa_box.end.y or not world.space.can_stand(world.player):failures+=1;push_error("FLC_INPUT crossed pantry sofa")
	before=world.player
	await key(KEY_S,true);await create_timer(.18).timeout;await key(KEY_S,false)
	checks+=1
	if world.player.distance_to(before)<30:failures+=1;push_error("FLC_INPUT cannot retreat from pantry sofa")
	checks+=1
	if world.invalid_frames!=0:failures+=1;push_error("FLC_INPUT illegal frame")
	var output:=OS.get_environment("FLC_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(output)
	var file:=FileAccess.open(output.path_join("input.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"invalidFrames":world.invalid_frames,"viewport":[root.size.x,root.size.y],"scale":host.scale.x,"touchTarget":[target.x,target.y],"touchFinal":[touch_final.x,touch_final.y],"loungeTouchTarget":[lounge_target.x,lounge_target.y],"loungeTouchFinal":[lounge_final.x,lounge_final.y],"hallFloor":2,"loungeFloor":world.data.floor},"  "));file.close()
	print("FLC_INPUT: %d checks, %d failures at %s"%[checks,failures,str(root.size)])
	world.load_floor(3);world.set_foot(spawn)

func pointer_event(at:Vector2,pressed:bool)->void:
	var screen:Vector2=host.position+at*host.scale
	if OS.get_environment("FLC_TOUCH")=="1":
		var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=screen;touch.pressed=pressed;root.push_input(touch,true)
	else:
		var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.position=screen;click.pressed=pressed;root.push_input(click,true)
	await process_frame
func tap(at:Vector2)->void:await pointer_event(at,true);await pointer_event(at,false)
func check_workshop()->void:
	var results:Array[Dictionary]=[]
	root.grab_focus();await process_frame
	world.load_floor(2);world.user_control=true
	var spec:Dictionary=world.data.workshopReference;var approach:=Vector2(spec.approach[0],spec.approach[1])
	world.set_foot(Vector2(spec.capture[0],spec.capture[1]));await capture("workshop_room")
	world.set_foot(approach+Vector2(300,150))
	await process_frame
	results.append({"name":"remote activation rejected","passed":not world.open_workbench()})
	var bench:Dictionary=world.workshop_bench();var center:=Vector2(world.Space.rect(bench.bounds).get_center().x,float(bench.baseline)-16)
	await tap(world.world_to_screen(center));await create_timer(3.5).timeout
	results.append({"name":"tap bench walks to it and opens","passed":world.workbench.visible and world.space.can_stand(world.player)})
	await capture("workshop_setup")
	await key(KEY_1,true);await key(KEY_1,false);await key(KEY_SPACE,true);await key(KEY_SPACE,false);await create_timer(1.6).timeout
	results.append({"name":"wrong small gear shows visible failure","passed":world.workbench.model.outcome=="gear_small"})
	await capture("workshop_gap")
	await pointer_event(Vector2(238,387),true);await pointer_event(Vector2(350,205),false)
	results.append({"name":"drag medium gear onto axle","passed":world.workbench.model.gear==1})
	await tap(Vector2(760,386));await tap(Vector2(760,386));await tap(Vector2(610,386));await tap(Vector2(480,386));await create_timer(.8).timeout
	results.append({"name":"tap controls start a visible drive","passed":world.workbench.model.running and world.workbench.model.travel>.12})
	await capture("workshop_running")
	var trial_deadline:=Time.get_ticks_msec()+8000
	while world.workbench.model.running and Time.get_ticks_msec()<trial_deadline:await process_frame
	results.append({"name":"workpiece reaches marker","passed":world.workbench.model.outcome=="passed"})
	await capture("workshop_success")
	var feet:Vector2=world.player
	await key(KEY_ESCAPE,true);await key(KEY_ESCAPE,false)
	results.append({"name":"exit restores same floor and feet","passed":not world.workbench.visible and world.ui.visible and world.player.distance_to(feet)<.1})
	world.open_workbench();results.append({"name":"reopen keeps installed parts","passed":world.workbench.model.gear==1 and world.workbench.model.outcome=="passed"})
	await tap(Vector2(480,386));await create_timer(.15).timeout;world.workbench.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	var travel:float=world.workbench.model.travel;await create_timer(.25).timeout
	results.append({"name":"focus loss stops trial","passed":not world.workbench.model.running and world.workbench.model.travel==travel})
	await key(KEY_R,true);await key(KEY_R,false)
	results.append({"name":"reset restores reusable parts","passed":world.workbench.model.gear==-1 and world.workbench.model.belt==0 and world.workbench.model.outcome.is_empty()})
	world.workbench.close();world.load_floor(3)
	results.append({"name":"no workshop activation on another floor","passed":not world.open_workbench()})
	var failed:=0
	for result:Dictionary in results:
		if not result.passed:failed+=1;push_error("FLC_WORKSHOP_INPUT: "+str(result.name))
	var folder:=OS.get_environment("FLC_CAPTURE_DIR")
	var file:=FileAccess.open(folder.path_join("workshop_input.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":results.size(),"failures":failed,"viewport":[root.size.x,root.size.y],"touch":OS.get_environment("FLC_TOUCH")=="1","results":results},"  "));file.close()
	print("FLC_WORKSHOP_INPUT: %d checks, %d failures"%[results.size(),failed])
