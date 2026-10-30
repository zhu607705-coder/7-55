extends Control
## Formal optional exploration. The retained story is never used as a reward ledger.
signal cancelled
signal leave_requested
const FLC_SCRIPT_PATH="res://campuses/future_learning_center/scripts/floor_view.gd"
var floor_view:Node2D
var surface:SubViewportContainer
var canvas:SubViewport
var back:Button
var disposed:=false
var suspended:=false
var configured:=false
var exit_pending:=false
var return_label:="‹ 返回入口"
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	var background:=ColorRect.new();background.color=Color("182125");background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(background);background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface=SubViewportContainer.new();surface.stretch=false;surface.size=Vector2(960,540);surface.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(surface)
	canvas=SubViewport.new();canvas.size=Vector2i(960,540);canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;canvas.handle_input_locally=true;surface.add_child(canvas)
	floor_view=load(FLC_SCRIPT_PATH).new();floor_view.persistence_enabled=true;canvas.add_child(floor_view)
	back=Button.new();back.name="ReturnFLC";back.text="‹ 返回入口";back.accessibility_name="返回入口，保存学习中心进度";back.custom_minimum_size=Vector2(120,44)
	back.pressed.connect(_leave);add_child(back)
	resized.connect(_layout)
	_layout()
func setup(config:Dictionary)->void:
	configured=true
	return_label="‹ 返回入口" if config.get("return_to_entry",false) else "‹ 返回游戏"
	back.text=return_label
	back.accessibility_name=back.text+"，保存学习中心进度"
func configure_activity_layout(available:Vector2,_compact:bool)->void:
	custom_minimum_size=Vector2.ZERO;position=Vector2.ZERO;scale=Vector2.ONE;size=available
	_layout()
func _layout()->void:
	if not is_instance_valid(surface):return
	var fit:=maxf(.1,minf(size.x/960.0,(size.y-52)/540.0))
	surface.scale=Vector2.ONE*fit
	surface.position=Vector2((size.x-960*fit)/2,52+(size.y-52-540*fit)/2)
	back.position=Vector2(8,4);back.size=Vector2(248 if exit_pending or back.text.contains("重试") else 144,44)
func activity_control_rect(control:Control)->Rect2:
	var rect:=control.get_global_rect()
	if control.get_viewport()==canvas:
		var transform:=surface.get_global_transform_with_canvas()
		return Rect2(transform*rect.position,rect.size*surface.scale)
	return rect
func cancel_browser_touch(event:InputEventScreenTouch)->void:
	# Browser cancellation carries no position. Route to the owning viewport,
	# even when the last root cursor is outside its letterboxed rectangle.
	if not disposed and is_instance_valid(canvas):canvas.push_input(event,true)
func activity_snapshot()->Dictionary:
	if not is_instance_valid(floor_view):return {}
	var room:Dictionary=floor_view.space.room_at(floor_view.player+floor_view.Body.FOOT_CENTER_OFFSET)
	var active:=""
	for key:String in floor_view.puzzle_views:
		if floor_view.puzzle_views[key]==floor_view.active_puzzle:active=key
	var anchor:Dictionary=floor_view.puzzle_anchor("formula")
	var point:=Vector2.ZERO
	if not anchor.is_empty():
		point=floor_view.get_global_transform_with_canvas()*floor_view.Space.rect(anchor.bounds).get_center()
		point=surface.get_global_transform_with_canvas()*point
	var rect:=Rect2(surface.get_global_transform_with_canvas()*Vector2.ZERO,Vector2(960,540)*surface.scale)
	var tilt:Variant=null
	var formula_complete:=false
	if floor_view.puzzle_views.has("formula"):
		var model:Object=floor_view.puzzle_views.formula.model
		tilt=model.TILTS[model.tilt]
		formula_complete=bool(model.completed)
	return {"kind":"flc","floor":floor_view.data.get("floor",0),"area":room.get("id",room.get("name","")),"player":{"x":floor_view.player.x,"y":floor_view.player.y},"activePuzzle":active,"formulaTilt":tilt,"formulaCompleted":formula_complete,"apparatusPoint":{"x":point.x,"y":point.y},"puzzleRect":{"x":rect.position.x,"y":rect.position.y,"width":rect.size.x,"height":rect.size.y},"exitPending":exit_pending}
func suspend()->void:
	if disposed or suspended or not is_instance_valid(floor_view):return
	suspended=true
	if floor_view.has_method("suspend_activity"):floor_view.suspend_activity()
	if floor_view.has_method("checkpoint_state"):floor_view.checkpoint_state()
	floor_view.process_mode=Node.PROCESS_MODE_DISABLED;canvas.gui_disable_input=true
func resume()->void:
	if disposed or exit_pending or not is_instance_valid(floor_view):return
	suspended=false;floor_view.process_mode=Node.PROCESS_MODE_INHERIT;canvas.gui_disable_input=false
func dispose_presentation()->void:
	if disposed:return
	suspend();disposed=true
func set_exit_waiting()->void:
	exit_pending=true;back.disabled=true;back.text="正在保存…";_layout()
func exit_failed()->void:
	exit_pending=false;back.disabled=false;back.text="保存未完成，重试";_layout();resume()
func finish_leave()->void:
	# The acknowledged bytes are final. Teardown must not create a new savedAt
	# envelope after the browser has confirmed the previous digest.
	floor_view.persistence_enabled=false
	disposed=true;cancelled.emit()
func _leave()->void:
	if disposed or exit_pending:return
	suspend()
	if leave_requested.get_connections().is_empty():
		if floor_view.checkpoint_state():finish_leave()
		else:exit_failed()
	else:leave_requested.emit()
func _exit_tree()->void:dispose_presentation()
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:suspend()
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_WM_WINDOW_FOCUS_IN]:resume()
func _unhandled_key_input(event:InputEvent)->void:
	if disposed:return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		_leave();get_viewport().set_input_as_handled()
