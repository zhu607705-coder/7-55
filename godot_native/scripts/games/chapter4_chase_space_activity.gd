extends "res://scripts/games/chapter4_activity.gd"
## New geometry/input consumer, retaining the original session/capture protocol.
const ChaseSpace=preload("res://scripts/games/chapter4_chase_space.gd")
const SpaceView=preload("res://scripts/presentation/chapter4_chase_space_view.gd")
var geometry:RefCounted=ChaseSpace.new()
var frozen_trace_size:=0

func _build()->void:
	if built:return
	built=true;kind="chase_stairwell";source={};size=Vector2(960,600)
	title=Label.new();title.text="楼梯间 · 障碍追逐";title.add_theme_color_override("font_color",Color("edf4dc"));add_child(title)
	body=Label.new();body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_theme_color_override("font_color",Color("edf4dc"));add_child(body)
	controls=HBoxContainer.new();add_child(controls)
	chase_view=SpaceView.new();chase_view.geometry=geometry;chase_view.reduced=bool(config.get("settings",{}).get("reduced_motion",false));add_child(chase_view)
	chase_overview=SpaceView.new();chase_overview.geometry=geometry;chase_overview.overview=true;add_child(chase_overview);chase_overview.hide()
	chase_status=Label.new();chase_status.add_theme_color_override("font_color",Color("d9d6b9"));add_child(chase_status)
	resized.connect(func():_clear_chase_pointer();_layout_chase())
	_reset_chase()

func _reset_chase()->void:
	landing=clampi(int(config.get("startLanding",0)),0,2)
	var entry:Dictionary=geometry.guard_entry(landing,float(config.get("guardLeadDistance",650)))
	elapsed=0;player=entry.player;guard=entry.guard;guard_delay_ms=entry.delayMs;chase_animation_ms=0
	trail=[];frozen_trace_size=0;guard_trail=[player];stage="chase";snapshot_clock=0;guard_target=null;guard_repath=0;running=true;done=false
	chase_progress_pending=false;chase_request_remaining_ms=0;chase_capture.cancel();_clear_chase_pointer()
	body.text="WASD / 方向键移动；按住地面指向移动，松开即停。"
	chase_view.reset_view(player,guard);chase_overview.reset_view(player,guard)
	_chase_buttons();_present_chase();_layout_chase()

func _chase_buttons()->void:
	_clear_controls();_button("返回",_leave_chase);_layout_chase()

func _layout_chase()->void:
	if not built or not is_instance_valid(chase_view):return
	var portrait:=size.y>size.x
	var short_landscape:=not portrait and size.y<500
	title.position=Vector2(14,12);title.size=Vector2(maxf(180,size.x-122),30);title.add_theme_font_size_override("font_size",20)
	controls.position=Vector2(size.x-94,8);controls.size=Vector2(80,44)
	for button in controls.get_children():
		button.custom_minimum_size=Vector2(80,44);NativeUi.apply_button(button,Color("163c3e"),Color("fff0c2"),Color("b4a77b"),0,2,16,Vector2(8,5),Color("76dfc9"))
	body.position=Vector2(14,54);body.size=Vector2(size.x-28,44 if portrait else 24);body.add_theme_font_size_override("font_size",14 if short_landscape else 16)
	chase_status.position=Vector2(14,104 if portrait else 80);chase_status.size=Vector2(size.x-28,22);chase_status.add_theme_font_size_override("font_size",14 if short_landscape else 15)
	var top:=134.0 if portrait else 110.0
	chase_view.position=Vector2(8,top);chase_view.size=Vector2(size.x-16,maxf(120,size.y-top-8))
	chase_overview.hide();chase_pad=Rect2();queue_redraw()

func _present_chase()->void:
	if not is_instance_valid(chase_view):return
	chase_view.present(player,guard,chase_animation_ms,running,landing,elapsed>=guard_delay_ms)
	chase_status.text="平台 %d / 2 · 顺地面箭头前行，绕开堆放物"%landing

func _foot(point:Vector2)->bool:return geometry.body_open(point)

func _chase_input(event:InputEvent)->bool:
	var local:InputEvent=event
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		local=event.duplicate();local.position=event.position-global_position
	return super._chase_input(local)

func _chase_proof_payload()->Dictionary:
	# Issued platform proofs are immutable prefixes, including their last point.
	frozen_trace_size=trail.size()
	var proof:=super._chase_proof_payload();proof.geometryVersion=str(config.get("geometryVersion",""));return proof

func _record_chase_sample()->void:
	if elapsed<=0 or (not trail.is_empty() and float(trail.back().t)>=elapsed):return
	var record:={"x":player.x,"y":player.y,"t":elapsed}
	# Coalesce only the unissued tail, at most 80ms from its retained anchor.
	# Check the entire replacement sweep: corners that would cross a solid stay.
	# This avoids a frame-rate-dependent 20,000-point failure on high-refresh PCs.
	if trail.size()>frozen_trace_size:
		var anchor:Vector2=geometry.vec(geometry.layout.landings[int(config.get("startLanding",0))].spawn)
		var anchor_time:=0.0
		if trail.size()>1:
			anchor=Vector2(trail[-2].x,trail[-2].y);anchor_time=float(trail[-2].t)
		if elapsed-anchor_time<=80 and geometry.segment_open(anchor,player):
			trail[-1]=record;return
	trail.append(record)

func source_stair_handoff()->Dictionary:
	var lead:float=geometry.distance(guard,player)+maxf(0,guard_delay_ms-elapsed)*geometry.GUARD_SPEED/1000
	return {"attempt":int(config.get("expectedAttempt",-1)),"destination":"A2","leadDistance":lead}

func _chase(delta:float)->void:
	var direction:=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if direction==Vector2.ZERO and pointer_moving:
		direction=pointer_target-player
		if direction.length()<8:direction=Vector2.ZERO
	var movement:Vector2=direction.normalized()*geometry.PLAYER_SPEED*delta
	var candidate:=player+movement
	if geometry.segment_open(player,candidate):player=candidate
	elif geometry.segment_open(player,player+Vector2(movement.x,0)):player+=Vector2(movement.x,0)
	elif geometry.segment_open(player,player+Vector2(0,movement.y)):player+=Vector2(0,movement.y)
	# Keep each swept step unless a bounded, collision-free chord replaces it.
	_record_chase_sample()
	if chase_progress_pending:
		chase_request_remaining_ms-=delta*1000
		if chase_request_remaining_ms<=0:chase_progress_pending=false
	if landing<2 and not chase_progress_pending and geometry.gates[landing].has_point(player):
		_record_chase_sample();chase_progress_pending=true;chase_request_remaining_ms=2000
		var proof:=_chase_proof_payload();proof.landing=landing+1;progress_requested.emit(proof)
	if landing==2 and geometry.exit.has_point(player):
		_record_chase_sample();var proof:=_chase_proof_payload();proof.escaped=true;proof.failures=0;_finish(proof);return
	if elapsed>=guard_delay_ms:
		guard_repath-=delta*1000
		if guard_repath<=0 or guard_target==null or guard.distance_to(guard_target)<1:
			var route:Array=geometry.path(guard,player);guard_target=route[0] if not route.is_empty() else null;guard_repath=260
		if guard_target!=null:
			var guard_candidate:=guard.move_toward(guard_target,geometry.GUARD_SPEED*delta)
			if geometry.segment_open(guard,guard_candidate,geometry.GUARD_BODY):guard=guard_candidate
		if GuardModel.chase_contact(guard,Rect2(player-PlayerMetrics.FOOT_SIZE/2,PlayerMetrics.FOOT_SIZE)):_capture_chase()
