extends RefCounted
const Driver=preload("res://tests/helpers/clock_chain_driver.gd")
const Model=preload("res://scripts/games/chapter4_clock_chain.gd")
static func key(event:Dictionary)->String:
	match event.kind:
		"source","evidence","repair","verify":return event.kind+"_"+event.id
		"link","sample","compare_wheels","balance":return event.kind
		"lock":return event.axis+"_lock"
		"trim":return "trim_"+event.channel
	return ""
static func play(panel:Control,click:Callable,boundary:Callable=Callable())->bool:
	var stage:=-1
	for event in Driver.events(panel.required_time):
		if panel.checkpoint.step!=stage:
			stage=int(panel.checkpoint.step)
			if boundary.is_valid():await boundary.call(stage)
		if event.kind=="wheel":
			if not await turn_wheel(panel,event.axis,int(event.delta)):return false
			continue
		if event.kind=="target":
			while panel.draft_hour!=int(event.hour):await click.call(panel.controls.draft_hour_plus)
			while panel.draft_minute!=int(event.minute):await click.call(panel.controls.draft_minute_plus)
			await click.call(panel.controls.target_commit)
			continue
		if event.kind=="trim":
			if not await drag_delay(panel,event.channel,int(event.correction)):return false
			continue
		var id:String=key(event)
		if not panel.controls.has(id):push_error("Missing clock control "+id+" at stage "+str(panel.checkpoint.step));return false
		var ancestor:Node=panel.controls[id].get_parent()
		while ancestor!=null:
			if ancestor is ScrollContainer:ancestor.ensure_control_visible(panel.controls[id])
			ancestor=ancestor.get_parent()
		for i in 3:await panel.get_tree().process_frame
		await click.call(panel.controls[id])
		if panel.pending:push_error("Clock control left pending "+id);return false
	if boundary.is_valid():await boundary.call(7)
	if panel.checkpoint.step!=7:return false
	await click.call(panel.controls.commit)
	return true

static func turn_wheel(panel:Control,axis:String,direction:int)->bool:
	var view:Control=panel.face
	var ancestor:Node=view.get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer:ancestor.ensure_control_visible(view)
		ancestor=ancestor.get_parent()
	for i in 4:await panel.get_tree().process_frame
	var root:Window=panel.get_tree().root
	var origin:Vector2=view.get_global_transform_with_canvas()*view.gear_point(axis)
	var start:Vector2=origin+Vector2(0,-18)
	var finish:Vector2=origin+Vector2.from_angle(-PI/2+direction*PI/4)*18
	var before:int=int(panel.checkpoint[axis])
	if panel.mobile:
		var down=InputEventScreenTouch.new();down.index=2;down.position=start;down.pressed=true;root.push_input(down,true)
		await panel.get_tree().process_frame
		var move=InputEventScreenDrag.new();move.index=2;move.position=finish;move.relative=finish-start;root.push_input(move,true)
		await panel.get_tree().process_frame
		var up=InputEventScreenTouch.new();up.index=2;up.position=finish;up.pressed=false;root.push_input(up,true)
	else:
		var hover=InputEventMouseMotion.new();hover.position=start;hover.global_position=start;root.push_input(hover,true)
		await panel.get_tree().process_frame
		var down=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=start;down.global_position=start;root.push_input(down,true)
		await panel.get_tree().process_frame
		var move=InputEventMouseMotion.new();move.button_mask=MOUSE_BUTTON_MASK_LEFT;move.position=finish;move.global_position=finish;move.relative=finish-start;root.push_input(move,true)
		await panel.get_tree().process_frame
		var up=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.position=finish;up.global_position=finish;up.pressed=false;root.push_input(up,true)
	for i in 4:await panel.get_tree().process_frame
	var expected:int=posmod(before+direction*(5 if axis=="minute" else 1),60 if axis=="minute" else 24)
	if panel.checkpoint[axis]!=expected:push_error("Physical gear gesture failed: "+axis);return false
	return view.dragging_axis.is_empty()

static func drag_delay(panel:Control,channel:String,goal:int)->bool:
	var root:Window=panel.get_tree().root
	for attempt:int in 12:
		var value:int=int(panel.checkpoint.trims.get(channel,0))
		if value==goal and panel.checkpoint.trims.has(channel):return true
		var amount:int=clampi(goal-value,-12,12)
		var board:Control=panel.controls.circuit
		var ancestor:Node=board.get_parent()
		while ancestor!=null:
			if ancestor is ScrollContainer:ancestor.ensure_control_visible(board)
			ancestor=ancestor.get_parent()
		for i in 4:await panel.get_tree().process_frame
		var start:Vector2=board.get_global_transform_with_canvas()*board.knob(board.CHANNELS.find(channel))
		var finish:Vector2=start+Vector2(amount*4*board.scale_factor()*panel.phone.scale.x,0)
		if panel.mobile:
			var down=InputEventScreenTouch.new();down.index=3;down.position=start;down.pressed=true;root.push_input(down,true)
			await panel.get_tree().process_frame
			var move=InputEventScreenDrag.new();move.index=3;move.position=finish;move.relative=finish-start;root.push_input(move,true)
			await panel.get_tree().process_frame
			var up=InputEventScreenTouch.new();up.index=3;up.position=finish;up.pressed=false;root.push_input(up,true)
		else:
			var hover=InputEventMouseMotion.new();hover.position=start;hover.global_position=start;root.push_input(hover,true)
			await panel.get_tree().process_frame
			var down=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.position=start;down.global_position=start;down.pressed=true;root.push_input(down,true)
			await panel.get_tree().process_frame
			var move=InputEventMouseMotion.new();move.button_mask=MOUSE_BUTTON_MASK_LEFT;move.position=finish;move.global_position=finish;move.relative=finish-start;root.push_input(move,true)
			await panel.get_tree().process_frame
			var up=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.position=finish;up.global_position=finish;root.push_input(up,true)
		for i in 4:await panel.get_tree().process_frame
		if int(panel.checkpoint.trims.get(channel,0))!=value+amount:push_error("Delay knob gesture failed "+channel);return false
	return false
