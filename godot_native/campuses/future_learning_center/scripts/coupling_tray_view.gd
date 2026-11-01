extends "res://campuses/future_learning_center/scripts/physical_bench.gd"
const Model = preload("res://campuses/future_learning_center/scripts/coupling_tray_model.gd")
const CLIP_HOME := Vector2(788,440)
const PLATE_HOME := Vector2(778,190)
const HINTS := ["连起来后，哪个方向变宽了？比较滑块和窄口。", "单块过口后，试试两块一起压住终台。还缺什么？", "第二块路盘有两个方向的窄口。在哪一侧连接，才有回转空间？"]
var model = Model.new()
var selected := -1
var drag_origin := Vector2.ZERO
var drag_delta := Vector2.ZERO
var previous_outcome := ""
var collision_cooldown := 0.0

func open() -> void:
	bench_mode = "coupling"; book_open = false; book_page = 0
	cancel_gesture(); clear_motion(); show()
	notice("把两块滑块送到终台，接通两处铜触点。")

func close() -> void:
	model.cancel(); super.close()

func _lost_focus() -> void: model.cancel()

func cancel_gesture() -> void:
	model.end_drag(true); selected = -1; drag_delta = Vector2.ZERO; super.cancel_gesture()

func block_at(index: int) -> Vector2:
	return model.positions[index]-Vector2(0,23*miniature.Q)

func clip_at() -> Vector2:
	return (model.positions[0]+model.positions[1])/2-Vector2(0,36*miniature.Q) if model.linked else CLIP_HOME

func _object_press(at: Vector2) -> void:
	if model.running: return
	if at.distance_to(clip_at())<17:
		gesture = "clip"; drag_origin = clip_at(); return
	if Rect2(PLATE_HOME-Vector2(49,34),Vector2(98,68)).has_point(at) and model.level==0:
		gesture = "plate"; drag_origin = PLATE_HOME; return
	for i: int in 2:
		if Rect2(block_at(i)-Vector2(26,25),Vector2(52,55)).has_point(at):
			if model.begin_drag():
				selected = i; drag_origin = model.positions[i]; gesture = "block"
			return

func _object_move(at: Vector2) -> void:
	drag_delta = at-press_at
	if gesture == "block" and selected>=0:
		model.move_block(selected,drag_origin+drag_delta)
		if model.blocked and collision_cooldown<=0:
			cue("brake",model.collision_point); collision_cooldown = .8
			notice("这一边碰到挡墙了。滑块和连接桥都要留在槽内。")

func _object_release(at: Vector2, cancelled: bool) -> void:
	if gesture == "block": model.end_drag(cancelled); return
	if cancelled: return
	if gesture == "clip":
		if at.distance_to(press_at)<12:
			notice("握住铜桥提离卡销可拆开；把它放回两枚卡销之间可连接。")
		elif model.linked:
			if at.distance_to(clip_at())>38 and model.detach_bridge():
				cue("release",press_at); notice("铜桥已取下，两块滑块可以分别移动。")
		else:
			var middle: Vector2 = (model.positions[0]+model.positions[1])/2-Vector2(0,36*miniature.Q)
			if at.distance_to(middle)<40 and model.attach_bridge():
				cue("seat",middle); notice("铜桥已连接。拨动试验杆，查看终台。")
			else: notice("铜桥回到托架。两枚卡销要对齐，桥下也不能有挡墙。")
	elif gesture == "plate" and Model.BOUNDS.has_point(at):
		if model.next_tray():
			book_page = 0; notice("这块路盘多一个转弯，终台也转向了。再送一次。")
		else: notice("先让这块路盘上的终台导通，再更换路盘。")

func _lever_action(offset: float) -> void:
	if offset < -20:
		if not model.trial():
			match model.outcome:
				"bridge": notice("两块都压住了铜触点，但中间的回路还断着。")
				_: notice("终台还没收到完整的连接。看看两处铜触点。")
		else: notice("正在试通电，观察终台。")
	elif offset > 20:
		model.reset(); notice("滑块回到起点，已完成的路盘记录保留。")
	else: model.cancel()

func _undo() -> void:
	if model.undo(): notice("撤回了上一次移动或连接。")

func _lever_live() -> bool: return model.running or model.powered
func _assembly_stamp() -> String: return str(model.snapshot())

func _process(dt: float) -> void:
	if not visible: return
	_tick_shell(dt); collision_cooldown = maxf(0,collision_cooldown-dt); model.step(dt)
	if previous_outcome != model.outcome:
		previous_outcome = model.outcome
		if model.outcome == "passed":
			cue("seat",Vector2(747,283))
			notice("终台亮了。把右侧折线路盘移进槽里，换一条路试。" if model.level==0 else "两块路盘都接通了。通道改变，连接的位置也要重新考虑。")
	queue_redraw()

func _book_lines() -> Array[String]:
	if book_page>0: return ["过口记录",HINTS[book_page-1]]
	if model.completed[0] and model.completed[1]: return ["两次实测", "直口和折线都已接通。拉回试验杆，可以再次尝试。"]
	if model.powered: return ["当前实测", "两处触点通过铜桥接通，终台亮起。"]
	return ["两份记录", "制作同学：终台需要连成整体。试用同学：连体时被窄口挡住。"]

func _draw() -> void:
	draw_table("")
	draw_tools(false); draw_book(); draw_feedback()

func draw_room_prop(canvas: CanvasItem, box: Rect2) -> void:
	# The front-facing counterpart has visible desk surface beside its monitor.
	var at := box.position+Vector2(8,10)
	canvas.draw_rect(Rect2(at,Vector2(28,16)),Color("263f47"))
	for i: int in 2:
		canvas.draw_rect(Rect2(at+Vector2(4+i*12,4),Vector2(8,8)),Color("36777b") if i==0 else Color("244967"))
	canvas.draw_line(at+Vector2(8,8),at+Vector2(20,8),Color("db8248"),3)
	canvas.draw_circle(at+Vector2(25,3),2,Color("e6c56c") if model.completed[0] else Color("a5b4b1"))
