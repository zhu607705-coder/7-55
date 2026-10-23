extends SceneTree
const View=preload("res://scripts/presentation/liangzhu_performance.gd")
var checks:=0
var failures:=0
var fixture:Dictionary={}
var blocked:=false
var closed:Array[String]=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("LIANGZHU_VIEW: "+label)
func frames(count:int=2)->void:
	for i in count:await process_frame
func state_fixture()->Dictionary:
	return {"runtimeMode":"rpg","rpgScene":"theater_interior","rpgCheckpoint":"campus_theater_interior","native":{"scene":"theater_interior","mode":"light","settings":{"reduced_motion":false}},"theaterHunt":{"active":true,"admitted":true,"phase":"program_search"},"ui":{"controlCenterOpen":false},"items":{"programA":true}}
func image_texture(size2:Vector2i,color:Color)->Texture2D:
	var image:=Image.create(size2.x,size2.y,false,Image.FORMAT_RGBA8);image.fill(color)
	return ImageTexture.create_from_image(image)
func assets()->Dictionary:
	return {"stage":image_texture(Vector2i(1200,675),Color("70503B")),"actors":image_texture(Vector2i(480,320),Color("385B79")),"table":image_texture(Vector2i(160,100),Color("70503B")),"chair_left":image_texture(Vector2i(60,120),Color("70503B")),"chair_right":image_texture(Vector2i(60,120),Color("70503B"))}
func config(images:Dictionary={},mode:String="interactive")->Dictionary:
	return {"read_state":func()->Dictionary:return fixture,"is_blocked":func()->bool:return blocked,"assets":images,"playback_mode":mode}
func mount(images:Dictionary={},mode:String="interactive")->Control:
	var view=View.new();root.add_child(view);view.set_process(false)
	check(view.setup(config(images,mode)),"Valid admitted theater opens the independent presentation")
	view.set_process(false);view.closed.connect(func(reason:String):closed.append(reason))
	view.configure_activity_layout(Vector2(root.size));await frames();return view
func mouse(button:Button)->void:
	var position:Vector2=button.get_global_rect().get_center()
	for down:bool in [true,false]:
		var input:=InputEventMouseButton.new();input.button_index=MOUSE_BUTTON_LEFT;input.position=position;input.global_position=position;input.pressed=down
		root.push_input(input,true);await frames()
func key(code:Key)->void:
	for down:bool in [true,false]:
		var input:=InputEventKey.new();input.keycode=code;input.physical_keycode=code;input.pressed=down;root.push_input(input,true);await frames()
func run()->void:
	root.size=Vector2i(1280,720);fixture=state_fixture()
	var images:Dictionary=assets();var durable_before:Dictionary={}
	for file:String in ["user://save.json","user://save.previous.json"]:durable_before[file]=FileAccess.get_file_as_string(file) if FileAccess.file_exists(file) else null
	var missing=View.new();root.add_child(missing);missing.set_process(false)
	check(not missing.setup(config({"stage":"res://assets/native/missing_performance_stage.png","actors":"res://assets/native/missing_performance_actors.png"})) and missing.get_meta("setup_rejection")=="assets_unavailable","Unbuilt assets cannot become an accepted release fallback")
	missing.queue_free();await frames()
	var bad=View.new();root.add_child(bad);bad.set_process(false)
	var old_size:Dictionary=images.duplicate();old_size.actors=image_texture(Vector2i(384,256),Color.WHITE)
	check(not bad.setup(config(old_size)) and bad.asset_issues.has("actors:size"),"Coarse old atlas cannot silently replace the new fine raster")
	bad.queue_free();await frames()
	var view:Control=await mount(images);var original:Dictionary=fixture.duplicate(true)
	check(view.assets_ready and not view.diagnostic and view.stage_texture().get_size()==Vector2(1200,675),"Runtime and offline capture share one native fine raster")
	for viewport:Vector2i in [Vector2i(1280,720),Vector2i(1440,900),Vector2i(360,640),Vector2i(390,844),Vector2i(430,932),Vector2i(844,390)]:
		root.size=viewport;view.configure_activity_layout(Vector2(viewport));await frames()
		check(absf(view.field.size.x/view.field.size.y-16.0/9.0)<.001,"Entire stage keeps one uniform16:9 projection at "+str(viewport))
		for button:Button in [view.pause_button,view.return_button]:
			check(Rect2(Vector2.ZERO,Vector2(viewport)).encloses(button.get_global_rect()) and button.get_global_rect().size.x>=43.99 and button.get_global_rect().size.y>=43.99,"Visible action is bounded with44CSSpx target: "+button.name)
		check(not view.pause_button.get_global_rect().intersects(view.return_button.get_global_rect()),"Pause and Return hit areas remain separate")
		check(view.title.get_parent()==view.stage_frame and view.caption.get_parent()==view.stage_frame,"Title and caption inherit the same authored stage-frame transform")
		if viewport.x<viewport.y:check(absf(view.caption_paper.position.y-view.field.end.y-8)<.01,"Portrait caption remains next to the complete stage")
		await mouse(view.help_button);await frames(6)
		var bounds:=Rect2(Vector2.ZERO,Vector2(viewport))
		check(view.help_open and bounds.encloses(view.help_panel.get_global_rect()) and view.help_panel.get_global_rect().encloses(view.help_body.get_global_rect()),"Ordinary non-QTE help measures all text inside a bounded paper after container settling at "+str(viewport))
		for button:Button in [view.passive_button,view.help_close]:
			check(button.is_visible_in_tree() and bounds.encloses(button.get_global_rect()) and button.get_global_rect().size.y>=43.99,"Ordinary help action remains on-screen with a real44CSSpx target: "+button.name)
		await mouse(view.help_close);check(not view.help_open,"Actual help Close returns to this same performance")
	root.size=Vector2i(1280,720);view.configure_activity_layout(Vector2(root.size));await frames()
	view.tick(.1,true);var before:float=view.model.elapsed_ms
	await mouse(view.pause_button);view.tick(.1,true)
	check(view.model.manually_paused and view.model.elapsed_ms==before and view.pause_button.text=="继续","Real Pause freezes the clock and exposes explicit Continue")
	await mouse(view.pause_button);view.tick(.1,true)
	check(not view.model.manually_paused and view.model.elapsed_ms>before,"Real Continue resumes only this presentation")
	view.grab_focus();await frames();await key(KEY_SPACE);before=view.model.elapsed_ms;view.tick(.1,true)
	check(view.model.manually_paused and view.model.elapsed_ms==before,"Focused Space is an equivalent pause action")
	await key(KEY_SPACE);view.tick(.1,true);before=view.model.elapsed_ms
	root.focus_exited.emit();view.tick(.1,true)
	check(view.model.focus_paused and view.model.elapsed_ms==before,"Actual window focus signal freezes animation without advancing story")
	root.focus_entered.emit();view.tick(.1,true);check(view.model.elapsed_ms==before,"Focus return preserves explicit resume requirement")
	await mouse(view.pause_button);view.tick(.1,true);before=view.model.elapsed_ms
	blocked=true;view.tick(.1,true);check(view.model.elapsed_ms==before,"Host occlusion freezes playback")
	blocked=false;fixture.ui.controlCenterOpen=true;view.tick(.1,true);check(view.model.elapsed_ms==before,"Control Center freezes the clock")
	fixture.ui.controlCenterOpen=false;fixture.native.settings.reduced_motion=true;view.tick(.1,true)
	check(view.model.reduced_motion,"Live reduced-motion setting reaches the native renderer")
	fixture.native.settings.reduced_motion=false;view.tick(.1,true);before=view.model.elapsed_ms
	view.render_at(50000);check(view.model.elapsed_ms==before and view.capture_pose.beat==3,"Offline frame selection does not spend runtime time or finish")
	view.tick(.1,true);check(view.model.elapsed_ms==before,"Capture frame remains stable while sampled")
	var rig_snapshot:Dictionary=view.geometry_snapshot().actorRigs
	check(rig_snapshot.scholar.bones>=10 and rig_snapshot.yingtai.bones>=10,"Each visible actor owns a real articulated Bone2D hierarchy")
	for sample:Dictionary in [{"time":14000.0,"owner":"yingtai"},{"time":17500.0,"owner":"scholar"},{"time":30000.0,"owner":"yingtai"}]:
		view.render_at(sample.time);var geometry:Dictionary=view.geometry_snapshot()
		var fan:Dictionary=geometry.fans[0].point;var wrist:Dictionary=geometry.actorRigs[sample.owner].fanSocket
		check(Vector2(fan.x,fan.y).distance_to(Vector2(wrist.x,wrist.y))<.2,"Held fan follows the current cel's real bone wrist at "+str(sample.time))
	view.render_at(view.Model.BUTTERFLY_LAUNCH_MS-1);var held:Dictionary=view.geometry_snapshot()
	view.render_at(view.Model.BUTTERFLY_LAUNCH_MS);var released:Dictionary=view.geometry_snapshot()
	for side:int in 2:
		var a:Dictionary=held.fans[side].point;var b:Dictionary=released.fans[side].point
		check(Vector2(a.x,a.y).distance_to(Vector2(b.x,b.y))<=.21,"Butterfly release preserves the fan socket with no launch jump")
	view.render_at(50000);var flight:Dictionary=view.geometry_snapshot()
	check(flight.fans.size()==2 and flight.fans.all(func(f:Dictionary)->bool:return f.kind=="butterfly"),"The same resolved release becomes two independently animated fan-wing butterflies")
	check(fixture==original,"All reading, input, pause and capture preserve source state")
	await mouse(view.return_button);view.skip();view.cancel()
	check(closed==["skipped"] and view.disposed and not view.visible,"Return closes exactly once, without submitting a rehearsal proof")
	view.queue_free();await frames();closed.clear();fixture=state_fixture()
	view=await mount(images);fixture=fixture.duplicate(true);view.tick(.1,true)
	check(closed==["context_changed"] and view.disposed,"Equal-valued replacement save cannot inherit an old playback owner")
	view.queue_free();await frames();closed.clear();fixture=state_fixture()
	view=await mount(images);fixture.native.mode="dark";view.tick(.1,true)
	check(closed==["context_changed"],"Changed scene context cancels rather than completing a stale performance")
	view.queue_free();await frames();closed.clear();fixture=state_fixture()
	view=await mount(images,"passive")
	for i in 550:view.tick(.1,true)
	check(closed==["finished"] and view.disposed,"Natural terminal frame closes this owner once")
	view.queue_free();await frames();closed.clear();fixture=state_fixture()
	view=await mount(images);view.dispose_presentation();view.skip()
	check(closed.is_empty() and view.disposed,"Host disposal is silent and cannot call a stale completion callback")
	view.queue_free();await frames()
	for file:String in durable_before:
		var after:Variant=FileAccess.get_file_as_string(file) if FileAccess.file_exists(file) else null
		check(after==durable_before[file],"Presentation preserves durable save bytes: "+file)
	print("LIANGZHU_VIEW: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
