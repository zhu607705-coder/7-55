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
				check(not Rect2(overlay.task.position,overlay.task.size).intersects(Rect2(overlay.plaque.position,overlay.plaque.size)),id+" task and plaque separate")
				var first_line_bottom:float=overlay.objective.get_global_rect().position.y+overlay.objective.get_theme_font("font").get_height(13)*overlay.scale.y
				check(first_line_bottom<=overlay.task_scroll.get_global_rect().end.y+.01,"first objective glyph line visible without scrolling "+str(physical))
				check(overlay.objective.text==goal and overlay.object_heading.text==plaque_text,"authored content retained")
				check(overlay.objective.get_theme_font_size("font_size")==13 and overlay.object_heading.get_theme_font_size("font_size")==18,"locked sizes not enlarged")
				check(overlay.mouse_filter==Control.MOUSE_FILTER_IGNORE and overlay.plaque.mouse_filter==Control.MOUSE_FILTER_IGNORE,"world pointer owner preserved")
				check(overlay.plaque.get_child_count()==3 and overlay.plaque.get_child(1) is Label,"interaction has no background card")
				check(is_equal_approx(overlay.task.modulate.a,1) and is_equal_approx(overlay.plaque.modulate.a,1),"foreground opacity remains full; only scrim fades")
	# Real scrolling owns input only while text overflows; passive HUD passes
	# through to the original world floor-tap coordinate contract.
	surface.size=Vector2(390,700);root.size=Vector2i(390,700)
	for goal:String in ["从寝室门出发","保留完整的任务说明。".repeat(30)]:
		for unused:int in range(3):
			overlay.sync_view(Vector2(390,700),1,"寝室",goal,"","浅色操作",Rect2(290,0,100,44),630,"07:55")
			await process_frame;await process_frame
		var scrolling:bool=overlay.task_scroll.get_v_scroll_bar().max_value>overlay.task_scroll.get_v_scroll_bar().page+.5
		check(scrolling==(goal.length()>20),"fixture distinguishes a readable short goal from actual overflow")
		check(overlay.task_column.mouse_filter==Control.MOUSE_FILTER_IGNORE,"HUD text column never captures floor taps")
		check(overlay.task_scroll.mouse_filter==(Control.MOUSE_FILTER_STOP if scrolling else Control.MOUSE_FILTER_IGNORE),"only actual overflow owns pointer scrolling")
		var point:Vector2=overlay.task_scroll.get_global_rect().get_center()
		var pointer_before:int=surface.pointer_events
		var scroll_before:int=overlay.task_scroll.scroll_vertical
		var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;root.push_input(motion,true)
		for down:bool in [true,false]:
			var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_WHEEL_DOWN if scrolling else MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event,true)
			await process_frame
		check(surface.pointer_events==pointer_before if scrolling else surface.pointer_events==pointer_before+1,"real pointer reaches underlying surface only for passive HUD")
		if scrolling:check(overlay.task_scroll.scroll_vertical>scroll_before,"real wheel scrolls overflowing task without leaking")
	print("SELECTED_WORLD_OVERLAY: ",checks," checks; ",failures," failures; ",worlds.size()," world IDs")
	quit(1 if failures else 0)
