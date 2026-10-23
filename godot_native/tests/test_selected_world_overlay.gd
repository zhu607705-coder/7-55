extends SceneTree
const Overlay=preload("res://scripts/ui/world_selected_overlay.gd")
const Selected=preload("res://scripts/ui/selected_ui_theme.gd")
var checks:=0
var failures:=0
class Surface extends Control:
	var mobile_exploration:=false
	var pointer_events:=0
	func _gui_input(event:InputEvent)->void:
		if event is InputEventMouseButton and event.pressed:pointer_events+=1
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func run()->void:
	var surface:=Surface.new();root.add_child(surface)
	var overlay:=Overlay.new();surface.add_child(overlay)
	var worlds:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json")).worlds
	for id:String in worlds:
		for physical:Vector2 in [Vector2(1440,900),Vector2(1280,720),Vector2(430,860),Vector2(390,844),Vector2(667,375),Vector2(568,320)]:
			for scale_value:float in [1.0,.65,1.45]:
				var extent:=physical/scale_value
				surface.mobile_exploration=physical.x<1000
				var goal:="保留原有目标，查看已获得的线索，再返回当前场景继续调查。".repeat(6)
				var plaque_text:="查看这件物品，核对现有调查记录"
				overlay.sync_view(extent,scale_value,"通往启真湖的路",goal,plaque_text,"浅色操作",Rect2(extent.x-100/scale_value,0,100/scale_value,44/scale_value),extent.y-70/scale_value,"07:55:23 不可信","查看已获得的记录，核对眼前物件。")
				await process_frame;await process_frame
				overlay.sync_view(extent,scale_value,"通往启真湖的路",goal,plaque_text,"浅色操作",Rect2(extent.x-100/scale_value,0,100/scale_value,44/scale_value),extent.y-70/scale_value,"07:55:23 不可信","查看已获得的记录，核对眼前物件。")
				await process_frame
				var bounds:=Rect2(Vector2.ZERO,physical)
				check(bounds.encloses(Rect2(overlay.task.position,overlay.task.size)),id+" task contained "+str(physical))
				check(bounds.encloses(Rect2(overlay.plaque.position,overlay.plaque.size)),id+" plaque contained "+str(physical))
				check(is_equal_approx(overlay.plaque.position.y+overlay.plaque.get_combined_minimum_size().y,physical.y-78),id+" prompt stays eight pixels above the supplied lower safe edge")
				check(not Rect2(overlay.task.position,overlay.task.size).intersects(Rect2(overlay.plaque.position,overlay.plaque.size)),id+" task and plaque separate")
				check(not overlay.task.visible and not overlay.mode.visible,"exploration has no persistent task column or top mode label")
				check(overlay.objective.text==goal and overlay.object_heading.text==plaque_text,"authored content retained")
				check(overlay.objective.get_theme_font_size("font_size")==13 and overlay.object_heading.get_theme_font_size("font_size")==18,"locked sizes not enlarged")
				check(overlay.mouse_filter==Control.MOUSE_FILTER_IGNORE and overlay.plaque.mouse_filter==Control.MOUSE_FILTER_IGNORE,"world pointer owner preserved")
				check(overlay.plaque.get_child_count()==3 and overlay.plaque.get_child(1) is Label,"interaction has no background card")
				check(is_equal_approx(overlay.task.modulate.a,1) and is_equal_approx(overlay.plaque.modulate.a,1),"foreground opacity remains full; only scrim fades")
	# Real scrolling owns input only while text overflows; passive HUD passes
	# through to the original world floor-tap coordinate contract.
	surface.size=Vector2(390,700);root.size=Vector2i(390,700)
	# Keep the retained review-column scrolling contract separate from the
	# production exploration direction, which leaves this column hidden.
	overlay.show_task_column=true
	for goal:String in ["从寝室门出发","保留完整的任务说明。".repeat(30)]:
		for unused:int in range(3):
			overlay.sync_view(Vector2(390,700),1,"寝室",goal,"","浅色操作",Rect2(290,0,100,44),630,"07:55")
			await process_frame;await process_frame
		var scrolling:bool=overlay.task_scroll.get_v_scroll_bar().max_value>overlay.task_scroll.get_v_scroll_bar().page+.5
		check(scrolling==(goal.length()>20),"fixture distinguishes a readable short goal from actual overflow")
		check(overlay.task_column.mouse_filter==Control.MOUSE_FILTER_IGNORE,"HUD text column never captures floor taps")
		check(overlay.task_scroll.mouse_filter==Control.MOUSE_FILTER_IGNORE,"task text never owns world pointer drags")
		var point:Vector2=overlay.task_scroll.get_global_rect().get_center()
		var pointer_before:int=surface.pointer_events
		var scroll_before:int=overlay.task_scroll.scroll_vertical
		var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;root.push_input(motion,true)
		for down:bool in [true,false]:
			var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_WHEEL_DOWN if scrolling else MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event,true)
			await process_frame
		check(surface.pointer_events==pointer_before if scrolling else surface.pointer_events==pointer_before+1,"real pointer reaches underlying surface only for passive HUD")
		if scrolling:check(overlay.task_scroll.scroll_vertical>scroll_before,"real wheel scrolls overflowing task without leaking")
		if scrolling:
			for boundary:int in [0,100000]:
				overlay.task_scroll.scroll_vertical=boundary;await process_frame
				var count:int=surface.pointer_events
				var wheel:=InputEventMouseButton.new();wheel.position=point;wheel.global_position=point;wheel.button_index=MOUSE_BUTTON_WHEEL_UP if boundary==0 else MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=true;root.push_input(wheel,true);await process_frame
				check(surface.pointer_events==count,"overflow wheel at either boundary cannot leak to world")
			var count:int=surface.pointer_events
			for down:bool in [true,false]:
				var click:=InputEventMouseButton.new();click.position=point;click.global_position=point;click.button_index=MOUSE_BUTTON_LEFT;click.pressed=down;root.push_input(click,true);await process_frame
			check(surface.pointer_events==count+1,"overflow text still passes actual world pointer through")
			var bar:=overlay.task_scroll.get_v_scroll_bar()
			check(bar.visible and bar.mouse_filter==Control.MOUSE_FILTER_STOP,"visible native scrollbar retains pointer ownership")
			overlay.task_scroll.scroll_vertical=0;await process_frame
			var handle:Vector2=Vector2(bar.get_global_rect().get_center().x,bar.get_global_rect().position.y+20)
			var hover:=InputEventMouseMotion.new();hover.position=handle;hover.global_position=handle;root.push_input(hover,true)
			var press:=InputEventMouseButton.new();press.position=handle;press.global_position=handle;press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;root.push_input(press,true);await process_frame
			var drag:=InputEventMouseMotion.new();drag.position=handle+Vector2(0,40);drag.global_position=drag.position;drag.relative=Vector2(0,40);drag.button_mask=MOUSE_BUTTON_MASK_LEFT;root.push_input(drag,true);await process_frame
			press.position=drag.position;press.global_position=drag.position;press.pressed=false;root.push_input(press,true);await process_frame
			check(overlay.task_scroll.scroll_vertical>0,"native scrollbar still accepts actual pointer drag")
			overlay.task_scroll.scroll_vertical=0;await process_frame
			var touch:=InputEventScreenTouch.new();touch.index=4;touch.position=handle;touch.pressed=true;root.push_input(touch,true);await process_frame
			var finger:=InputEventScreenDrag.new();finger.index=4;finger.position=Vector2(handle.x,bar.get_global_rect().end.y-20);finger.relative=finger.position-handle;root.push_input(finger,true);await process_frame
			touch.position=finger.position;touch.pressed=false;root.push_input(touch,true);await process_frame
			check(overlay.task_scroll.scroll_vertical>=bar.max_value-bar.page-1,"touch scrollbar drag can reach final long-goal line")
			# Exercise Input's real parser with the project's enabled emulation,
			# rather than only the viewport injection used by other fixtures.
			overlay.task_scroll.scroll_vertical=0;await process_frame
			touch.index=7;touch.position=handle;touch.pressed=true;Input.parse_input_event(touch);await process_frame
			check(overlay._scroll_touch_id==7,"real input parser starts exactly one scrollbar finger")
			var duplicate:=InputEventMouseMotion.new();duplicate.device=InputEvent.DEVICE_ID_EMULATION;duplicate.position=finger.position;duplicate.global_position=finger.position;duplicate.relative=finger.relative;duplicate.button_mask=MOUSE_BUTTON_MASK_LEFT;root.push_input(duplicate,true);await process_frame
			check(overlay.task_scroll.scroll_vertical==0,"platform-emulated duplicate cannot advance the owned native drag")

			var unrelated:=InputEventScreenDrag.new();unrelated.index=9;unrelated.position=finger.position;unrelated.relative=finger.relative;root.push_input(unrelated,true);await process_frame
			check(overlay.task_scroll.scroll_vertical==0,"unrelated finger cannot move owned scrollbar")
			overlay.hide();await process_frame
			check(overlay._scroll_touch_id==-1,"hiding overlay cancels native scrollbar gesture")
			touch.pressed=false;Input.parse_input_event(touch);await process_frame
			overlay.show();await process_frame
			touch.index=8;touch.position=handle;touch.pressed=true;Input.parse_input_event(touch);await process_frame
			finger.index=8;Input.parse_input_event(finger);await process_frame
			touch.position=finger.position;touch.pressed=false;Input.parse_input_event(touch);await process_frame
			check(overlay._scroll_touch_id==-1 and overlay.task_scroll.scroll_vertical>=bar.max_value-bar.page-1,"after hide a fresh parsed finger reaches final line and releases")



	# A single update after a long goal must self-settle without Main._process
	# repeatedly calling sync_view. This was the initial Room204 drag blocker.
	surface.set_process(false)
	overlay.sync_view(Vector2(390,700),1,"寝室","从寝室门出发","","浅色操作",Rect2(290,0,100,44),630,"07:55")
	for unused:int in range(8):await process_frame
	check(overlay.task.size.y<150 and overlay.task_scroll.get_v_scroll_bar().max_value<=overlay.task_scroll.get_v_scroll_bar().page+.5,"single update settles short HUD bounds without polling")
	check(overlay.task_scroll.mouse_filter==Control.MOUSE_FILTER_IGNORE,"single update clears stale STOP after container layout")
	var point:Vector2=overlay.task_scroll.get_global_rect().get_center()
	var before:int=surface.pointer_events
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;root.push_input(motion,true)
	for down:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event,true);await process_frame
	check(surface.pointer_events==before+1,"settled HUD releases real pointer with Main processing stopped")
	# Repeated resize/long-to-short transitions must settle without another
	# Main update and without a same-idle deferred queue feedback loop.
	for dims:Vector2 in [Vector2(390,844),Vector2(667,375),Vector2(1440,900),Vector2(390,844)]:
		for goal:String in ["完整目标说明。".repeat(40),"从寝室门出发"]:
			overlay.sync_view(dims,1,"剧场",goal,"查看海报","浅色操作",Rect2(dims.x-100,0,100,44),dims.y-70,"07:55")
			for unused:int in range(12):await process_frame
			check(not overlay._settle_queued,"single resize/text transition reaches quiescence without Main polling")
			var settled:Rect2=Rect2(overlay.task.position,overlay.task.size)
			for unused:int in range(3):await process_frame
			check(settled==Rect2(overlay.task.position,overlay.task.size) and not overlay._settle_queued,"settled container does not oscillate across frames")
	print("SELECTED_WORLD_OVERLAY: ",checks," checks; ",failures," failures; ",worlds.size()," world IDs")
	quit(1 if failures else 0)
