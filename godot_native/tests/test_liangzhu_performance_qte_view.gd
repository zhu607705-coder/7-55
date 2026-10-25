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
	if not ok:failures+=1;push_error("LIANGZHU_QTE_VIEW: "+label)
func frames(n:int=2)->void:
	for i in n:await process_frame
func image(size2:Vector2i)->Texture2D:
	var pixels:=Image.create(size2.x,size2.y,false,Image.FORMAT_RGBA8);pixels.fill(Color("70503B"));return ImageTexture.create_from_image(pixels)
func assets()->Dictionary:
	return {"stage":image(Vector2i(1200,675)),"actors":image(Vector2i(480,320)),"table":image(Vector2i(160,100)),"chair_left":image(Vector2i(60,120)),"chair_right":image(Vector2i(60,120))}
func mount(viewport:Vector2i)->Control:
	root.size=viewport
	var view:=View.new();root.add_child(view);view.set_process(false)
	check(view.setup({"read_state":func()->Dictionary:return fixture,"is_blocked":func()->bool:return blocked,"assets":assets()}),"Admitted theater mounts an interactive performance with complete furniture")
	view.set_process(false);view.configure_activity_layout(Vector2(viewport));view.closed.connect(func(reason:String):closed.append(reason));await frames();return view
func touch(id:int,point:Vector2,down:bool,cancelled:bool=false)->void:
	var event:=InputEventScreenTouch.new();event.index=id;event.position=point;event.pressed=down;event.canceled=cancelled;root.push_input(event,true);await frames()
func drag(id:int,point:Vector2)->void:
	var event:=InputEventScreenDrag.new();event.index=id;event.position=point;root.push_input(event,true);await frames()
func mouse_at(point:Vector2,down:bool,device:int=0)->void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;event.global_position=point;event.device=device;root.push_input(event,true);await frames()
func click(button:Button)->void:
	var rect:Rect2=button.get_global_rect()
	check(button.is_visible_in_tree() and rect.size.x>=43.99 and rect.size.y>=43.99 and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(rect),"Visible native action has a real bounded44CSS target: "+button.name)
	for down:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=rect.get_center();event.global_position=event.position;root.push_input(event,true);await frames()
func key(code:Key,down:bool)->void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;root.push_input(event,true);await frames()
func target(view:Control)->Vector2:
	var q:Rect2=view.qte_target
	check(q.size.x>=44 and q.size.y>=44 and view.field.encloses(q),"Expanded grip remains44CSS and follows the complete stage")
	check(not q.intersects(view.return_button.get_global_rect()) and not q.intersects(view.caption_paper) and not q.intersects(view.help_button.get_global_rect()),"Actor input is separate from the side-wing programme, subtitles and Return")
	return q.get_center()
func control_boundaries()->void:
	closed.clear()
	var view:Control=await mount(Vector2i(1280,720))
	var pressed:Dictionary={"retry":0,"return":0}
	view.retry_button.pressed.connect(func():pressed.retry+=1)
	view.return_button.pressed.connect(func():pressed["return"]+=1)
	view.tick(15,true);view.tick(60,true)
	# Include larger-to-smaller resizes: stale minimum sizes must not overlap.
	for viewport:Vector2i in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1440,900),Vector2i(844,390),Vector2i(390,844),Vector2i(360,640),Vector2i(1280,720)]:
		root.size=viewport;view.configure_activity_layout(Vector2(viewport));await frames(4)
		check(view.model.status=="failure" and view.retry_button.is_visible_in_tree(),"Boundary check uses the actual failed-QTE Retry at "+str(viewport))
		var retry:Rect2=view.retry_button.get_global_rect();var back:Rect2=view.return_button.get_global_rect()
		check(not retry.intersects(back),"Retry and Return never share a hit area at "+str(viewport))
		var bounds:=Rect2(Vector2.ZERO,Vector2(viewport))
		check(bounds.encloses(retry) and bounds.encloses(back),"Both failed-QTE actions remain inside the viewport at "+str(viewport))
		check(view.caption.get_theme_font_size("font_size")*view.stage_frame.scale.x>=18,"The enlarged subtitle remains at least 18 screen pixels")
		var attempts:int=view.model.qte_snapshot().attempts
		var prior:int=pressed.retry
		var edge:=Vector2(retry.end.x-5,retry.get_center().y)
		await mouse_at(edge,true);await mouse_at(edge,false)
		check(pressed.retry==prior+1 and pressed["return"]==0 and closed.is_empty(),"Retry's right edge belongs only to Retry at "+str(viewport))
		check(view.model.status=="waiting" and view.model.qte_snapshot().attempts==attempts+1,"The real edge click retries exactly one local cue")
		view.tick(60,true);await frames()
	var prior:int=pressed.retry
	# Original desktop failure: Retry used to steal this point inside Return.
	var return_edge:=Vector2(1145,30)
	check(view.return_button.get_global_rect().has_point(return_edge),"Original reported point remains inside the visible Return sign")
	await mouse_at(return_edge,true);await mouse_at(return_edge,false)
	check(pressed["return"]==1 and pressed.retry==prior and closed==["skipped"] and view.disposed,"Return's left edge closes once without triggering Retry")
	await mouse_at(return_edge,true);await mouse_at(return_edge,false)
	check(closed==["skipped"] and pressed["return"]==1,"Repeated click after dismissal cannot invoke the disposed controls")
	view.queue_free();await frames();closed.clear()
func run()->void:
	fixture={"runtimeMode":"rpg","rpgScene":"theater_interior","rpgCheckpoint":"campus_theater_interior","native":{"scene":"theater_interior","mode":"light","settings":{"reduced_motion":false}},"theaterHunt":{"active":true,"admitted":true,"phase":"program_search"},"ui":{"controlCenterOpen":false}}
	var before:Dictionary=fixture.duplicate(true);var durable:Dictionary={}
	for file:String in ["user://save.json","user://save.previous.json"]:durable[file]=FileAccess.get_file_as_string(file) if FileAccess.file_exists(file) else null
	var view:Control=await mount(Vector2i(390,844))
	view.tick(15,true);check(view.model.status=="waiting" and view.model.elapsed_ms==15000,"The first cue freezes at the authored handoff instead of advancing itself")
	check(view.help_button.text.is_empty() and view.field.encloses(view.help_button.get_global_rect()),"Observation is attached to the visible book inside the stage, without an Observe label")
	await touch(8,view.help_button.get_global_rect().get_center(),true);await touch(8,view.help_button.get_global_rect().get_center(),false);await frames(6)
	var bounds:=Rect2(Vector2.ZERO,Vector2(root.size))
	check(bounds.encloses(view.help_panel.get_global_rect()) and view.help_panel.get_global_rect().encloses(view.help_body.get_global_rect()),"The first-cue observation paper bounds its measured full text after settling")
	for button:Button in [view.help_next,view.passive_button,view.help_close]:
		check(button.is_visible_in_tree() and bounds.encloses(button.get_global_rect()) and button.get_global_rect().size.y>=43.99,"Every real QTE observation action remains reachable: "+button.name)
	await click(view.help_close)
	var point:Vector2=target(view);await touch(1,point+Vector2(80,0),true);await touch(1,point+Vector2(80,0),false)
	check(view.model.qte_completed.is_empty(),"Touching an unrelated part of the stage cannot catch the fan")
	await touch(1,point,true);await drag(1,point+Vector2(30,0));await drag(1,point);await touch(1,point,false)
	check(view.model.qte_completed.is_empty(),"A drag never becomes a catch tap after returning to its start")
	await mouse_at(point,true,-1);check(view.qte_pointer=="","First-finger emulated MouseDown cannot steal the native touch gesture")
	await touch(0,point,true);check(view.qte_pointer=="touch:0","The real first finger owns the fan after its emulated mouse event")
	await touch(1,point,true);await touch(1,point,false);check(view.model.qte_completed.is_empty() and view.qte_pointer=="touch:0","A second finger cannot steal or release the first finger's catch")
	await mouse_at(point,false,-1);check(view.model.qte_completed.is_empty() and view.qte_pointer=="touch:0","Emulated MouseUp cannot complete or discard the actual touch owner")
	await touch(0,point,false);check(view.model.qte_completed.has("catch-fan") and view.model.status=="playing","An ordinary first-finger tap on the actual grip catches exactly one fan")
	view.tick(14,true);point=target(view);await touch(3,point,true);await drag(3,point+Vector2(32,0));await touch(3,point+Vector2(32,0),false)
	check(view.model.status=="failure" and view.model.qte_completed.size()==1,"Wrong-direction turn is a local miss that retains the caught fan")
	await click(view.retry_button);check(view.model.status=="waiting" and view.model.qte_completed.size()==1,"Real Retry repeats only the current turn")
	point=target(view);await touch(3,point,true);await drag(3,point-Vector2(32,0));await touch(3,point-Vector2(32,0),false)
	check(view.model.qte_completed.has("turn-back") and view.model.qte_results.size()==2,"The visible leftward ground gesture advances the second cue")
	view.tick(17,true);point=target(view);await touch(4,point,true);view.tick(.3,true);root.focus_exited.emit();var clock:float=view.model.runtime_ms
	await touch(4,point,false);view.tick(1,true)
	check(view.model.focus_paused and not view.model.qte_snapshot().holding and view.model.runtime_ms==clock and view.model.qte_completed.size()==2,"Focus loss cancels a held fan and freezes its active clock without releasing it")
	root.focus_entered.emit();view.tick(.1,true);check(view.model.runtime_ms==clock,"Returning focus does not silently restart a partial held cue")
	await click(view.pause_button);point=target(view);await touch(4,point,true);view.tick(.1,true);await touch(4,point,false)
	check(view.model.status=="failure" and view.model.qte_completed.size()==2,"A premature release fails only the final cue")
	await click(view.retry_button);point=target(view);await mouse_at(point,true,-1);await touch(0,point,true);view.tick(.9,true)
	check(view.model.qte_snapshot().holdProgress>=1 and "松手" in view.qte_label.text,"The stable paper fan explicitly signals when release is ready")
	await touch(9,point,false);await mouse_at(point,false,-1);check(view.model.qte_completed.size()==2 and view.qte_pointer=="touch:0","A different finger or emulated mouse cannot finish the settled first-finger butterfly")
	await touch(0,point,false);check(view.model.qte_completed.size()==3 and view.model.qte_results.all(func(r:Dictionary)->bool:return r.mode=="interactive"),"Actual first-finger release earns three runtime-only cue receipts")
	view.tick(8,true);check(closed==["finished"] and view.disposed,"Only the completed interactive timeline closes this presenter once")
	view.queue_free();await frames();closed.clear()
	view=await mount(Vector2i(1280,720));view.tick(15,true);point=target(view)
	await mouse_at(point,true);await touch(0,point,true);await touch(0,point,false)
	check(view.qte_pointer=="mouse" and view.model.qte_completed.is_empty(),"A genuine physical mouse owner cannot be stolen by a simultaneous finger")
	await mouse_at(point,false);check(view.model.qte_completed.has("catch-fan"),"A real owned mouse release still completes within the synthetic-touch filter period")
	view.tick(14,true);await key(KEY_LEFT,true);await key(KEY_LEFT,false);view.tick(17,true);point=target(view)
	await mouse_at(point,true,-1);await touch(0,point,true)
	check(view.qte_pointer=="touch:0" and view.model.qte_snapshot().holding,"A butterfly hold belongs to the real first finger, never its emulated mouse")
	await touch(1,point,true);await touch(1,point,false);await mouse_at(point,false,-1)
	check(view.model.qte_snapshot().holding and view.qte_pointer=="touch:0" and view.model.qte_completed.size()==2,"Neither a second finger nor emulated MouseUp can release the first-finger butterfly hold")
	view.tick(.4,true)
	root.size=Vector2i(1440,900);view.configure_activity_layout(Vector2(root.size));await key(KEY_SPACE,false)
	check(view.model.focus_paused and not view.model.qte_snapshot().holding and view.model.qte_completed.size()==2,"Resize cancels a keyboard hold without generating release success")
	await click(view.pause_button);await key(KEY_SPACE,true);view.tick(.3,true);blocked=true;view.tick(.5,true);clock=view.model.runtime_ms;await key(KEY_SPACE,false)
	check(view.model.focus_paused and not view.model.qte_snapshot().holding and view.model.runtime_ms==clock,"A real host overlay boundary cancels the same held owner")
	blocked=false;await click(view.pause_button);await click(view.help_button)
	check(view.help_open and view.help_panel.visible and view.model.manually_paused,"The native observation paper pauses the same performance clock")
	await click(view.passive_button)
	check(view.model.playback_mode=="passive" and view.model.elapsed_ms==0 and view.model.qte_completed.is_empty() and view.model.qte_results.is_empty() and not view.help_open,"From-the-start viewing explicitly clears cue receipts and creates a passive clock")
	view.tick(54,true);check(closed==["finished"] and view.model.qte_completed.is_empty() and view.model.qte_results.is_empty(),"Passive completion never masquerades as three successful QTEs")
	check(fixture==before,"Every ordinary input path preserves the entire source game state")
	view.queue_free();await frames()
	await control_boundaries()
	for file:String in durable:
		var value:Variant=FileAccess.get_file_as_string(file) if FileAccess.file_exists(file) else null
		check(value==durable[file],"QTEs and viewing preserve durable save bytes: "+file)
	print("LIANGZHU_QTE_VIEW: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
