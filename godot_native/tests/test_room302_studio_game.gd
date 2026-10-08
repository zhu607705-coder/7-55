extends SceneTree
const Model=preload("res://scripts/objects/room302_studio_model.gd")
var checks:=0
var failures:=0
var state:Node
var game_font:Font
func _initialize()->void:run.call_deferred()
func check(condition:bool,label:String)->void:
	checks+=1
	if not condition:failures+=1;push_error(label)
func frames(n:=2)->void:
	for i in range(n):await process_frame
func event(value:Dictionary)->Dictionary:return state.act("c4_media_studio_event",value)
func run()->void:
	game_font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	root.size=Vector2i(390,844)
	state=root.get_node("State");state.developer_mode=false
	state.d=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/room302_earned_film_entry.json")).state
	check(not state.d.native.has("c4_media_studio") and state.validate_snapshot(state.d),"Old ordinary save with absent optional checkpoint still loads")
	var first:Dictionary=Model.initial();check(Model.valid(first) and Model.stage(first)=="wardrobe","New hats start misplaced, not pre-earned")
	check(Model.valid(JSON.parse_string(JSON.stringify(first))),"Ordinary JSON numeric float roundtrip accepts finite integral fields")
	check(Model.canonical(JSON.parse_string(JSON.stringify(first)))==Model.canonical(first),"JSON float checkpoint preserves every gameplay value after typed canonicalization")
	var bad:Dictionary=first.duplicate(true);bad.wardrobe_done=true;check(not Model.valid(bad),"Forged done flag is rejected")
	for hats:Array in [["entrance","entrance","honor_wall"],["entrance","stairs"],["entrance","stairs","extra"]]:
		bad=first.duplicate(true);bad.hats=hats;check(not Model.valid(bad),"Illegal/duplicate hat permutation rejected")
	for axis:String in Model.AXES:
		for number:Variant in [-99,99,.5,"1",true]:
			bad=first.duplicate(true);bad.alignment[axis]=number;check(not Model.valid(bad),"Illegal numeric checkpoint rejected "+axis)
	check(not Model.transition(first,{"kind":"step","axis":"xOffset","delta":1}).accepted,"Second stage cannot move before hats return")
	var moved:Dictionary=Model.transition(first,{"kind":"swap","a":0,"b":2}).checkpoint
	check(Model.transition(moved,{"kind":"swap","a":0,"b":2}).checkpoint==first,"Swapping the same pair reverses the operation")
	var opened:Dictionary=state.act("c4_device_media_alignment");check(opened.get("page","")=="c4_device","Original scanner entry retained")
	var original_facts:Array=state.d.chapter4.factIds.duplicate()
	state.act("c4_solve_media_alignment",Model.source().registration.media.duplicate())
	check(state.d.chapter4.factIds==original_facts,"Knowing the old numeric answer cannot bypass unsolved hats")
	event({"kind":"swap","a":0,"b":2})
	check(state.d.native.c4_media_studio.hats==["entrance","honor_wall","stairs"],"Controller commits first physical hat exchange")
	check(state.validate_snapshot(state.d),"Partial hat layout is a legal ordinary save")
	var layout:Dictionary=state.d.native.c4_media_studio.duplicate(true)
	var panel:Control=load("res://scripts/objects/room302_studio_panel.gd").new()
	check(panel.configure("media_alignment",state.d,game_font),"Object page opens original media context")
	root.add_child(panel);await frames(3)
	check(panel.checkpoint==layout and panel.view.lamps.size()==3,"Three native lamp sprites restore partial layout")
	await frames(8)
	check(panel.header.size.y<=48.1 and panel.close_button.size.y<=48.1,"Freshly mounted studio title cannot inflate header before first input")
	check(panel.has_method("layout_fullscreen") and panel.frame==null and panel.get_global_rect()==Rect2(Vector2.ZERO,root.size),"Native game fills viewport without a nested panel frame")
	for mode:String in ["keyboard","touch"]:
		for dimensions:Vector2i in [Vector2i(390,844),Vector2i(430,932),Vector2i(844,390),Vector2i(1180,812)]:await check_layout(panel,dimensions,mode)
	panel.dispose_session();panel.queue_free();await frames()
	check(state.d.native.c4_media_studio==layout,"Returning to room preserves hat checkpoint")
	check(state.save_game(),"Partial first stage ordinary save")
	state.d=state.initial();check(state.load_game() and Model.canonical(state.d.native.c4_media_studio)==Model.canonical(layout),"Ordinary reload restores first stage without a solved shortcut")
	event({"kind":"swap","a":1,"b":2})
	check(Model.hats_ready(state.d.native.c4_media_studio) and Model.stage(state.d.native.c4_media_studio)=="curtain","Controller confirms first stage from exact hat arrangement")
	panel=load("res://scripts/objects/room302_studio_panel.gd").new();check(panel.configure("media_alignment",state.d,game_font),"Curtain stage opens from saved hat completion")
	root.add_child(panel);await frames(3)
	for mode:String in ["keyboard","touch"]:
		for dimensions:Vector2i in [Vector2i(390,844),Vector2i(430,932),Vector2i(844,390),Vector2i(1180,812)]:
			await check_layout(panel,dimensions,mode)
			check_physical_inputs(panel)
	panel.dispose_session();panel.queue_free();await frames()
	var retained:Dictionary=state.d.native.c4_media_studio.duplicate(true)
	var wrong:Dictionary=state.act("c4_solve_media_alignment",{"xOffset":0,"yOffset":0,"rotationQuarterTurns":0})
	check(state.d.native.c4_media_studio==retained and state.d.chapter4.factIds==original_facts and not str(wrong.message).is_empty(),"Wrong curtain check is funny feedback with unchanged layout/facts")
	for move:Dictionary in [{"axis":"xOffset","delta":1},{"axis":"xOffset","delta":1},{"axis":"yOffset","delta":-1},{"axis":"rotationQuarterTurns","delta":1}]:
		move.kind="step";event(move)
	check(Model.ready_to_record(state.d.native.c4_media_studio),"Physical curtain steps reach original registration")
	var authorized_state:Dictionary=state.d.duplicate(true)
	state.d.native.scene="library_interior"
	state.act("c4_solve_media_alignment",Model.source().registration.media.duplicate())
	check(state.d.chapter4.factIds==original_facts,"Direct record outside original A3 scene is rejected")
	state.d=authorized_state
	var main_script:Script=load("res://scripts/main.gd")
	check(main_script.can_instantiate(),"Shared Main seam compiles with the ordinary autoload")
	var aligned:Dictionary=state.d.native.c4_media_studio.duplicate(true)
	event({"kind":"step","axis":"rotationQuarterTurns","delta":-1});event({"kind":"step","axis":"rotationQuarterTurns","delta":1})
	check(state.d.native.c4_media_studio==aligned,"Counter-turn reverses a curtain turn without clearing translation")
	state.act("c4_solve_media_alignment",Model.source().registration.media.duplicate())
	check("a3_media_alignment_completed" in state.d.chapter4.factIds,"Only original controller fact path records completed studio")
	var facts:Array=state.d.chapter4.factIds.duplicate()
	state.act("c4_solve_media_alignment",Model.source().registration.media.duplicate());event({"kind":"swap","a":0,"b":1})
	check(state.d.chapter4.factIds==facts and state.d.native.c4_media_studio==aligned,"Repeated final submission and post-completion events are idempotent")
	check(state.save_game(),"Completed two-stage checkpoint saves normally")
	state.d=state.initial();check(state.load_game() and Model.canonical(state.d.native.c4_media_studio)==Model.canonical(aligned),"Completed ordinary reload retains checkpoint")
	var old_complete:Dictionary=state.d.duplicate(true);old_complete.native.erase("c4_media_studio")
	check(state.validate_snapshot(old_complete),"Old completed fact with no new field remains compatible")
	panel=load("res://scripts/objects/room302_studio_panel.gd").new();check(panel.configure("media_alignment",old_complete,game_font),"Old completed save opens settled studio")
	root.add_child(panel);await frames(3)
	check(panel.session.completed and panel.view.displayed_stage=="recorded" and panel.view.motion.is_empty() and Model.ready_to_record(panel.checkpoint),"Old completed fact directly restores final pose without replay or fabricated saved history")
	panel.dispose_session();panel.queue_free();await frames()
	var no_film:Dictionary=old_complete.duplicate(true);no_film.chapter4.factIds.erase("a3_archive_film_retrieved");no_film.chapter4.factIds.erase("a3_media_alignment_completed")
	panel=load("res://scripts/objects/room302_studio_panel.gd").new();check(panel.configure("media_alignment",no_film,game_font),"Missing-film original information page still opens")
	root.add_child(panel);await frames(2)
	check(panel.session.operation_locked() and not panel.view.interactive and button_count(panel)==1,"Missing original film disables all new lamp/curtain controls")
	panel.dispose_session();panel.queue_free();await frames()
	for illegal:Dictionary in [dict_with_extra(first),dict_with_repeat(first)]:
		var snapshot:Dictionary=state.d.duplicate(true);snapshot.native.c4_media_studio=illegal;check(not state.validate_snapshot(snapshot),"State rejects malformed optional studio checkpoint")
	print("ROOM302_STUDIO_CHECKS ",checks," FAILURES ",failures);quit(0 if failures==0 else 1)
func dict_with_extra(value:Dictionary)->Dictionary:
	var copy:Dictionary=value.duplicate(true);copy.wardrobe_done=true;return copy
func dict_with_repeat(value:Dictionary)->Dictionary:
	var copy:Dictionary=value.duplicate(true);copy.hats=["stairs","stairs","entrance"];return copy

func button_count(node:Node)->int:
	var count:=1 if node is Button else 0
	for child:Node in node.get_children():count+=button_count(child)
	return count
func check_layout(panel:Control,dimensions:Vector2i,mode:String)->void:
	root.size=dimensions;panel.set_input_mode(mode);await frames(2)
	panel.layout_fullscreen(Rect2(Vector2.ZERO,Vector2(dimensions)),Vector4(13,29,17,23));await frames(5)
	check(panel.color.a==1 and panel.size==Vector2(dimensions),"Opaque viewport "+mode+str(dimensions))
	check(panel.close_button.get_global_rect().end.x<=dimensions.x-17 and panel.close_button.get_global_rect().position.y>=29,"Return stays in safe area "+mode+str(dimensions))
	check(button_count(panel)==1,"Only Return is a button; no simulated controls "+mode+str(dimensions))
	check(panel.header.size.y<=48.1 and panel.close_button.size.y<=48.1,"Compact one-line header stays48px "+mode+str(dimensions))
	check(not panel.view.play_area.intersects(panel.feedback.get_rect()),"Scene reclaims former control-bar area "+mode+str(dimensions))
	check(panel.hint.get_global_transform().get_scale().is_equal_approx(Vector2.ONE),"Text stays unscaled while native scene grows "+mode+str(dimensions))
	check(panel.input_mode==mode and panel.view.touch_mode==(mode=="touch"),"Explicit profile, not width, chooses input layout")
func check_physical_inputs(panel:Control)->void:
	var trace:Array=[]
	var observer:Callable=func(value:Dictionary):trace.append(value.duplicate())
	panel.studio_event_requested.connect(observer)
	for handle:Dictionary in panel.view.handle_definitions():
		var point:Vector2=panel.view.origin+Vector2(handle.point)*panel.view.fit
		var count:int=trace.size();panel.view._pointer_down(point)
		check(trace.size()==count+1 and trace.back().axis==handle.axis and trace.back().delta==handle.delta,"Visible physical handle emits its exact reversible operation")
		panel.resolve_studio_event(state.d,{"message":""})
	var middle:Vector2=panel.view.origin+panel.view.curtain_rect().get_center()*panel.view.fit
	panel.view._pointer_down(middle);panel.view._pointer_up(middle+Vector2(70,4))
	check(not trace.is_empty() and trace.back().axis=="xOffset" and trace.back().delta==1,"Coarse cloth swipe snaps one horizontal step")
	panel.resolve_studio_event(state.d,{"message":""})
	panel.view._pointer_down(middle);var count:int=trace.size()
	panel.set_input_mode("touch" if panel.input_mode=="keyboard" else "keyboard")
	panel.view._pointer_up(middle+Vector2(70,0))
	check(trace.size()==count and not panel.view.dragging,"Mode switch cancels unfinished gesture without dispatch or checkpoint change")
	panel.studio_event_requested.disconnect(observer)
	check(panel.view.check_station.contains_source_point(panel.view.check_station.position+Vector2(0,-45)),"Visible scanner glass is alpha-pickable for validation")
