extends Control
## Source: ActOneVirtualRun.tsx / library-v2-phone.css. Presentation and the
## local ten-fix attempt live here; chapter1_2 remains the result authority.
signal finished(result: Dictionary)
signal cancelled

const Ui = preload("res://scripts/ui/native_ui_theme.gd")
const Track = preload("res://scripts/games/virtual_run_track.gd")
const Motion=preload("res://scripts/games/virtual_run_motion.gd")
var motion=Motion.new()
var copy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/virtual-run-copy.json"))
var pointer_id=-2
var pointer_target=Vector2.ZERO
var held: Dictionary={}
var has_moved=false
const FIX_NAMES = ["西南弯", "西直道南", "西直道北", "西北弯", "北弯道", "东北弯", "东直道北", "东直道南", "东南弯", "终点线"]
var POINTS=Motion.gates()
const BLUE = Color("1a63ad")
const INK = Color("12365c")
const GREEN = Color("256b43")
var completed = 0
var closed = false
var pending_result = false
var accepted = false
var result_rejected = false
var status: Label
var exit_button: Button
var return_button: Button
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
var feedback := ""
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
	track = Track.new();track.motion=motion;track.name="VirtualRunTrack"
	add_child(track)
	visibility_changed.connect(func():if not is_visible_in_tree():_release_input())
	gps = _label(track,"GPS · 等待首个点",13,INK)
	gps.name="RunSignal"
	progress_label = _label(self,"",14,INK)
	progress_label.name="RunProgress"
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
	footer = _label(self,copy.controls,13,Color("51677c"))
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
	feedback = copy.intro
	motion.reset();held.clear();pointer_id=-2;has_moved=false
	if is_node_ready(): _update_target()

func _process(delta: float) -> void:
	var display_scale := get_global_transform_with_canvas().get_scale().x
	if size != last_size or not is_equal_approx(display_scale,last_scale): _layout()
	_step(delta)

func _step(delta: float) -> void:
	if closed or pending_result or accepted:return
	var direction=Vector2(float(held.get(KEY_RIGHT,false))-float(held.get(KEY_LEFT,false)),float(held.get(KEY_DOWN,false))-float(held.get(KEY_UP,false)))
	var throttle=1.0
	if pointer_id!=-2:
		direction=pointer_target-motion.position;throttle=clampf(direction.length()/42,0,1)
		if direction.length()<2:direction=Vector2.ZERO
	var event: String=motion.advance(delta,direction,throttle,bool(held.get(KEY_SPACE,false)))
	if not direction.is_zero_approx():has_moved=true
	completed=motion.completed
	if event=="lost":
		_release_input();feedback=copy.lost;feedback_warning=true
	elif event=="checkpoint":
		feedback=copy.segment;feedback_warning=false
		if completed==10:
			pending_result=true;result_rejected=false;_release_input()
			feedback="十个定位点已完成，正在提交锻炼记录。"
			_update_target(false)
			finished.emit({"failed":false,"points":10,"elapsedSeconds":600,"distanceMeters":3000})
			return
	elif event=="warning":feedback=copy.slow;feedback_warning=true
	_update_target(false)

func _release_input() -> void:
	pointer_id=-2;held.clear();motion.stop()
	if is_instance_valid(track):track.dragging=false

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_PAUSED]:_release_input()

func _input(event: InputEvent) -> void:
	if closed or accepted or pending_result or not is_visible_in_tree():return
	if event is InputEventKey and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_SPACE]:
		if event.echo:return
		held[event.keycode]=event.pressed;get_viewport().set_input_as_handled();return
	if event is InputEventScreenTouch:
		if event.pressed and pointer_id==-2 and track.to_route(event.position).distance_to(motion.position)<30:
			pointer_id=event.index;pointer_target=track.to_route(event.position);get_viewport().set_input_as_handled()
		elif (not event.pressed or event.canceled) and pointer_id==event.index:
			_release_input();feedback=copy.paused;feedback_warning=false;get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and pointer_id==event.index:
		pointer_target=track.to_route(event.position);get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.device!=-1:
		if event.pressed and pointer_id==-2 and track.to_route(event.position).distance_to(motion.position)<30:
			pointer_id=-1;pointer_target=track.to_route(event.position);get_viewport().set_input_as_handled()
		elif not event.pressed and pointer_id==-1:
			_release_input();feedback=copy.paused;feedback_warning=false;get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and pointer_id==-1:
		pointer_target=track.to_route(event.position);get_viewport().set_input_as_handled()

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
		motion.completed=9;motion.saved_trail=motion.receipts[9].duplicate();motion.receipts=motion.receipts.slice(0,10);motion.restore_segment()
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

func _update_target(_focus_current: bool = true) -> void:
	if not is_instance_valid(track):return
	stat_values[0].text="%02d:00"%completed
	stat_values[1].text="%.2f"%(completed*.3)
	stat_values[2].text="--′--″" if completed==0 else "03′20″"
	progress.value=completed+motion.fraction() if completed<10 else 10
	progress_label.text="已记录 %d / 10 点"%completed
	gps.text="GPS · 轨迹锁定" if accepted else "GPS · 核验记录" if pending_result else "GPS · %d%%"%roundi(motion.integrity*100)
	title.text="课外锻炼已同步" if accepted else "10 分钟跑完 3 km"
	next_title.text="10 / 10 · 锻炼记录正式生效" if accepted else "10 / 10 · 正在核验记录" if pending_result else "下一站 %02d · %s"%[completed+1,FIX_NAMES[completed]]
	next_detail.text="10:00 · 3.00 km · 03′20″ / km" if accepted else "10:00 · 3.00 km · 提交锻炼记录" if pending_result else copy.slow if not motion.interference().is_empty() else copy.intro if not has_moved else copy.segment
	status.text="" if feedback==next_detail.text else feedback
	status.add_theme_color_override("font_color",Color("8b3d1c") if feedback_warning else GREEN)
	next_card.add_theme_stylebox_override("panel",Ui.box(Color("e0f1df") if accepted else Color("fff7d6"),Color("70a880") if accepted else Color("d8bc55"),1,10))
	return_button.visible=accepted;footer.visible=not accepted;exit_button.disabled=closed
	track.aim=pointer_target;track.dragging=pointer_id!=-2;track.queue_redraw()

func _cancel() -> void:
	if closed: return
	closed = true
	_release_input()
	exit_button.disabled = true
	cancelled.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE):
		_cancel()
		get_viewport().set_input_as_handled()
