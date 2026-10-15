extends Control
## Source: ActOneVirtualRun.tsx / library-v2-phone.css. Presentation and the
## local ten-fix attempt live here; chapter1_2 remains the result authority.
signal finished(result: Dictionary)
signal cancelled

const Ui = preload("res://scripts/ui/native_ui_theme.gd")
const Track = preload("res://scripts/games/virtual_run_track.gd")
const FIX_NAMES = ["南直道", "西南弯", "西弯道", "西北弯", "北直道西", "北直道东", "东北弯", "东弯道", "东南弯", "终点线"]
# Same authored order around the track; the south endpoints are separated
# slightly to keep all ten real touch targets disjoint on a compact phone.
const POINTS = [Vector2(.44,.85),Vector2(.25,.80),Vector2(.14,.64),Vector2(.14,.40),Vector2(.30,.19),Vector2(.56,.17),Vector2(.80,.29),Vector2(.86,.51),Vector2(.78,.73),Vector2(.62,.85)]
const BLUE = Color("1a63ad")
const INK = Color("12365c")
const GREEN = Color("256b43")
var completed = 0
var closed = false
var pending_result = false
var accepted = false
var result_rejected = false
var target: Button
var status: Label
var exit_button: Button
var return_button: Button
var point_buttons: Array[Button] = []
var recorded_marks: Array[Line2D] = []
var track: Control
var header: Panel
var eyebrow: Label
var title: Label
var stat_panels: Array[Panel] = []
var stat_titles: Array[Label] = []
var stat_values: Array[Label] = []
var next_card: Panel
var next_title: Label
var next_detail: Label
var footer: Label
var progress: ProgressBar
var progress_label: Label
var gps: Label
var last_size := Vector2.ZERO
var last_scale := 0.0
var feedback := "点按黄色的 1，开始记录运动轨迹。"
var feedback_warning := false

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	header = _panel(self,BLUE,Color("174d88"),12)
	eyebrow = _label(header,"体艺 · 紫云田径场 / GPS",13,Color("d5edff"))
	title = _label(header,"10 分钟跑完 3 km",21,Color.WHITE)
	exit_button = Button.new()
	exit_button.name = "ExitRun"
	exit_button.text = "×"
	exit_button.tooltip_text = "退出本次定位（Esc），下次从第 1 点重新开始"
	Ui.apply_button(exit_button,Color("f4f8ff"),INK,Color("a9c9ef"),9,1,26,Vector2.ZERO,INK)
	exit_button.pressed.connect(_cancel)
	header.add_child(exit_button)
	for caption: String in ["记录用时", "距离 · km", "配速 / km"]:
		var panel := _panel(self,Color.WHITE,Color("bed1e2"),9)
		stat_panels.append(panel)
		stat_titles.append(_label(panel,caption,13,Color("51677c")))
		stat_values.append(_label(panel,"",23,INK))
	track = Track.new()
	track.points = POINTS
	add_child(track)
	for index in range(POINTS.size()):
		var button := Button.new()
		button.name = "Fix%d" % (index+1)
		button.pressed.connect(_point.bind(index))
		track.add_child(button)
		point_buttons.append(button)
		# The bundled source font lacks a check glyph. Use native geometry;
		# the Button retains the complete point name/state for accessibility.
		var mark := Line2D.new()
		mark.name = "RecordedCheck"
		mark.points = PackedVector2Array([Vector2(13,24),Vector2(21,32),Vector2(36,16)])
		mark.width = 3.5
		mark.default_color = Color.WHITE
		mark.antialiased = true
		mark.joint_mode = Line2D.LINE_JOINT_ROUND
		mark.begin_cap_mode = Line2D.LINE_CAP_ROUND
		mark.end_cap_mode = Line2D.LINE_CAP_ROUND
		mark.visible = false
		button.add_child(mark)
		recorded_marks.append(mark)
	gps = _label(track,"GPS · 等待首个点",13,INK)
	progress_label = _label(self,"",14,INK)
	progress = ProgressBar.new()
	progress.max_value = 10
	progress.show_percentage = false
	progress.mouse_filter = MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override("background",Ui.box(Color("cedde9"),Color.TRANSPARENT,0,4))
	progress.add_theme_stylebox_override("fill",Ui.box(GREEN,Color.TRANSPARENT,0,4))
	add_child(progress)
	next_card = _panel(self,Color("fff7d6"),Color("d8bc55"),10)
	next_title = _label(next_card,"",18,INK)
	next_detail = _label(next_card,"",14,Color("51677c"))
	status = _label(self,feedback,14,INK)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer = _label(self,"点按定位点 · Tab 切换 · Enter / 空格确认\nEsc 退出；退出后本次定位从头开始",13,Color("51677c"))
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return_button = Button.new()
	return_button.name = "ReturnToTiyi"
	return_button.text = "返回体艺首页"
	Ui.apply_button(return_button,BLUE,Color.WHITE,Color("174d88"),10,1,16,Vector2.ZERO,INK)
	return_button.pressed.connect(_cancel)
	return_button.visible = false
	add_child(return_button)
	_update_target()
	_layout()

func start(_config: Dictionary) -> void:
	completed = 0
	closed = false
	pending_result = false
	accepted = false
	result_rejected = false
	feedback_warning = false
	feedback = "点按黄色的 1，开始记录运动轨迹。"
	if is_node_ready(): _update_target()

func _process(_delta: float) -> void:
	var display_scale := get_global_transform_with_canvas().get_scale().x
	if size != last_size or not is_equal_approx(display_scale,last_scale): _layout()

func _panel(parent: Node,fill: Color,border: Color,radius: int) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",Ui.box(fill,border,1,radius))
	parent.add_child(panel)
	return panel

func _label(parent: Node,value: String,font_size: int,ink: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",ink)
	parent.add_child(label)
	return label

func _rect(control: Control,x: float,y: float,w: float,h: float) -> void:
	control.position = Vector2(x,y)
	control.size = Vector2(w,h)

func _layout() -> void:
	if not is_instance_valid(track): return
	last_size = size
	last_scale = maxf(.1,get_global_transform_with_canvas().get_scale().x)
	var touch_size := maxf(48,ceilf(44/last_scale))
	var caption_size := maxi(13,ceili(12/last_scale))
	var body_size := maxi(14,ceili(13/last_scale))
	var width := size.x-28
	_rect(header,14,14,width,76)
	_rect(eyebrow,14,10,width-touch_size-38,24)
	_rect(title,14,34,width-touch_size-38,32)
	_rect(exit_button,width-touch_size-12,(76-touch_size)/2,touch_size,touch_size)
	eyebrow.add_theme_font_size_override("font_size",caption_size)
	var stat_width := (width-16)/3
	for i in range(3):
		_rect(stat_panels[i],14+i*(stat_width+8),102,stat_width,72)
		_rect(stat_titles[i],10,7,stat_width-20,24)
		_rect(stat_values[i],10,31,stat_width-20,32)
		stat_titles[i].add_theme_font_size_override("font_size",caption_size)
	# At the canonical 430 x 820 game viewport the track occupies 394px.
	# This reflows on size/scale changes without changing any recorded fix.
	var board_height := maxf(300,size.y-426)
	_rect(track,14,186,width,board_height)
	track.route_rect = Rect2(10,30,width-20,board_height-54)
	track.target_extent = touch_size
	track.display_scale = last_scale
	for i in range(POINTS.size()):
		var point: Vector2 = track.route_rect.position+track.route_rect.size*POINTS[i]
		_rect(point_buttons[i],point.x-touch_size/2,point.y-touch_size/2,touch_size,touch_size)
		point_buttons[i].add_theme_font_size_override("font_size",maxi(17,ceili(15/last_scale)))
		recorded_marks[i].scale = Vector2.ONE*(touch_size/48)
	_rect(gps,12,5,width-24,24)
	gps.add_theme_font_size_override("font_size",caption_size)
	var bottom := track.position.y+board_height
	_rect(progress_label,16,bottom+10,width-4,26)
	_rect(progress,16,bottom+42,width-4,8)
	_rect(next_card,14,bottom+62,width,72)
	_rect(next_title,12,8,width-24,28)
	_rect(next_detail,12,36,width-24,26)
	_rect(status,16,bottom+144,width-4,38)
	_rect(footer,16,bottom+184,width-4,42)
	_rect(return_button,14,bottom+176,width,maxf(50,touch_size))
	for label in [next_detail,status,progress_label]: label.add_theme_font_size_override("font_size",body_size)
	footer.add_theme_font_size_override("font_size",caption_size)
	track.queue_redraw()
	queue_redraw()

func _draw() -> void:
	draw_style_box(Ui.box(Color("e9f3fb"),Color("173d63"),2,16),Rect2(Vector2.ZERO,size))

func _point(index: int = -1) -> void:
	if closed or pending_result or accepted: return
	if index == -1: index = completed # Existing focused model-test entry.
	if index != completed:
		feedback_warning = true
		feedback = "第 %d 点已记录，请前往黄色的 %d。" % [index+1,completed+1] if index < completed else "定位漂移：先补齐黄色的第 %d 点。" % (completed+1)
		_update_target(false)
		return
	completed += 1
	feedback_warning = false
	feedback = "第 %d 分钟已记录 · +300 米" % completed
	if completed == POINTS.size():
		pending_result = true
		result_rejected = false
		feedback = "十个定位点已完成，正在提交锻炼记录。"
		_update_target(false)
		# Submit immediately. Only resolve() from the host's authoritative
		# response may turn the waiting view into the synchronized result.
		finished.emit({"failed":false,"points":10,"elapsedSeconds":600,"distanceMeters":3000})
		return
	_update_target()

func resolve(result_accepted: bool) -> void:
	if not pending_result or closed: return
	pending_result = false
	accepted = result_accepted
	result_rejected = not result_accepted
	if accepted:
		feedback = "十个定位点已完成 · 记录编号 PE-0755-3000"
		feedback_warning = false
	else:
		completed = 9
		feedback = "参加者身份失效。请退出后重新确认。"
		feedback_warning = true
	_update_target()
	if accepted: return_button.grab_focus()

func owns_result_feedback(message: String) -> bool:
	# Exact controller/audio captions only. An unrelated notice must remain
	# visible, and this never cancels the associated source voice or SFX.
	if closed: return false
	var line := message.strip_edges()
	if pending_result or accepted:
		if line in ["锻炼记录已同步。", "10:00 / 3.00km / 03′20″\n锻炼记录已同步。"]: return true
	return (pending_result or result_rejected) and line in ["本次锻炼无效。", "必须依次完成十个定位点。"]

func _update_target(focus_current: bool = true) -> void:
	if point_buttons.is_empty(): return
	stat_values[0].text = "%02d:00" % completed
	stat_values[1].text = "%.2f" % (completed*.3)
	stat_values[2].text = "--′--″" if completed == 0 else "03′20″"
	progress.value = completed
	progress_label.text = "已记录 %d / 10 点" % completed
	gps.text = "GPS · 等待首个点" if completed == 0 else "GPS · 轨迹锁定" if accepted else "GPS · 核验记录" if pending_result else "GPS · 精度 ±%d m" % maxi(4,13-completed)
	title.text = "课外锻炼已同步" if accepted else "10 分钟跑完 3 km"
	next_title.text = "10 / 10 · 锻炼记录正式生效" if accepted else "10 / 10 · 正在核验记录" if pending_result else "下一站 %02d · %s" % [completed+1,FIX_NAMES[completed]]
	next_detail.text = "10:00 · 3.00 km · 03′20″ / km" if accepted else "10:00 · 3.00 km · 提交锻炼记录" if pending_result else "点按黄色定位点 · 记录第 %d 分钟" % (completed+1)
	if completed == 9: next_detail.text = "点按终点 10，提交 10:00 / 3.00 km"
	status.text = feedback
	status.add_theme_color_override("font_color",Color("8b3d1c") if feedback_warning else GREEN)
	next_card.add_theme_stylebox_override("panel",Ui.box(Color("e0f1df") if accepted else Color("fff7d6"),Color("70a880") if accepted else Color("d8bc55"),1,10))
	return_button.visible = accepted
	footer.visible = not accepted
	exit_button.disabled = closed
	exit_button.tooltip_text = "返回体艺首页" if accepted else "退出本次定位（Esc），下次从第 1 点重新开始"
	track.completed = completed
	track.queue_redraw()
	for i in range(point_buttons.size()):
		var button := point_buttons[i]
		button.disabled = closed or pending_result or accepted
		button.text = "" if i < completed else str(i+1)
		recorded_marks[i].visible = i < completed
		button.tooltip_text = "第 %d 分钟 · %s · %s" % [i+1,FIX_NAMES[i],"已记录" if i < completed else "当前目标" if i == completed else "尚未记录"]
		button.accessibility_name = button.tooltip_text
		var fill := GREEN if i < completed else Color("ffdc53") if i == completed else Color("e6eef3")
		var ink := Color.WHITE if i < completed else Color("573916") if i == completed else Color("506477")
		Ui.apply_button(button,fill,ink,Color("1a5638") if i < completed else Color("8a651c") if i == completed else Color("698395"),30,2,17,Vector2.ZERO,Color("123b79"))
		button.add_theme_color_override("font_disabled_color",ink)
	if not closed and not pending_result and not accepted:
		target = point_buttons[completed]
		if focus_current: target.grab_focus()

func _cancel() -> void:
	if closed: return
	closed = true
	for button: Button in point_buttons: button.disabled = true
	exit_button.disabled = true
	cancelled.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE):
		_cancel()
		get_viewport().set_input_as_handled()
