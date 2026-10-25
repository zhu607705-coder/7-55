extends Control
## Material sprites, index cards and one owned gesture. No story or save writes.
signal choice_requested(key: String, value: String)
signal drawer_requested
signal motion_finished
const ATLAS = preload("res://assets/rpg/interiors/finale/chapter4-755/props/chapter4_a3_archive_film_v01.png")
const InsetKey=preload("res://scripts/objects/inset_option_key.gd")
const Art=preload("res://scripts/objects/room301_archive_art.gd")
# Physical closeup of the case's drawer; controls sit on its paper channels.
const REGIONS := {"case":Rect2(Vector2.ZERO,Art.SIZE),"drawer":Rect2(7,58,82,20),"card":Rect2(25,20,41,22),"film":Rect2(53,30,18,17)}
const KEYS := ["yearBand","floor","purpose"]
const DRAFT_KEYS := ["archiveYearBand","archiveFloor","archivePurpose"]
const TITLES := ["年代", "楼层", "用途"]
var index_keys:Array[Control]=[]
var handle_key:Control
var source: Dictionary = {}
var draft: Dictionary = {}
var interactive := false
var completed := false
var observation := false
var touch_mode := false
var reduced := false
var focused_row := 0
var play_area := Rect2()
var cabinet := Rect2()
var drawer := Rect2()
var handle_base := Rect2()
var handle: Rect2:
	get:
		return Rect2(handle_base.position+Vector2(0,_entry_pull()),handle_base.size)
var film := Rect2()
var index_targets: Array[Dictionary] = []
var narrow := false
var dragging := false
var pointer_kind := ""
var pointer_index := -1
var pointer_device := 0
var gesture := ""
var gesture_card: Dictionary = {}
var drag_start := Vector2.ZERO
var drag_current := Vector2.ZERO
var last_touch_at := -10000
var motion := ""
var motion_time := 0.0
var drawer_open := 0.0
var entry_ms := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	for i:int in 3:
		var key:=InsetKey.new();key.name="IndexInset_"+KEYS[i];add_child(key);index_keys.append(key)
	handle_key=InsetKey.new();handle_key.name="DrawerHandleInset";add_child(handle_key)
	resized.connect(func(): cancel_gesture(); _layout())
	_layout()

func layout_scene(area: Rect2) -> void:
	if area != play_area: cancel_gesture()
	play_area = area
	_layout()

func present(data: Dictionary, value: Dictionary, done: bool, dark: bool) -> void:
	source = data
	draft = value.duplicate(true)
	completed = done
	observation = dark
	if completed and motion.is_empty(): drawer_open = 0.0
	_layout()

func _fit_rect(region: Rect2, bounds: Rect2) -> Rect2:
	var factor := minf(bounds.size.x / region.size.x, bounds.size.y / region.size.y)
	var extent := region.size * factor
	return Rect2(bounds.position + (bounds.size-extent)/2.0,extent)

func _layout() -> void:
	if not play_area.has_area(): play_area = Rect2(Vector2.ZERO,size)
	index_targets.clear()
	narrow = play_area.size.x < 680
	var short_view:=play_area.size.y<330
	var object_bounds:=Rect2(play_area.position+Vector2(0,2 if short_view else 18),Vector2(play_area.size.x,maxf(1,play_area.size.y-(8 if short_view else 52))))
	# Leave room below the box for its real downward drawer travel.
	if short_view:
		object_bounds.size.x=play_area.size.x*.39
	cabinet = _fit_rect(REGIONS["case"],object_bounds)
	var scale_factor := cabinet.size.x/96.0
	drawer = Rect2(cabinet.position+REGIONS.drawer.position*scale_factor,REGIONS.drawer.size*scale_factor)
	handle_base = Rect2(drawer.position+drawer.size*Vector2(.24,.32),drawer.size*Vector2(.52,.56))
	if handle_base.size.y < 44: handle_base = handle_base.grow((44-handle_base.size.y)/2.0)
	film = _fit_rect(REGIONS.film,Rect2(cabinet.position+Vector2(cabinet.size.x*.17,cabinet.size.y*.19),cabinet.size*Vector2(.66,.54)))
	var width:=cabinet.size.x*.72
	var height:=maxf(44.0,9.4*scale_factor)
	for row in range(3):
		if source.is_empty(): continue
		var center:=cabinet.position+Vector2(48,17+18*row)*scale_factor
		var rect:=Rect2(center-Vector2(width,height)/2,Vector2(width,height))
		if short_view:
			rect=Rect2(Vector2(play_area.position.x+play_area.size.x*.43,play_area.get_center().y-86+row*60),Vector2(play_area.size.x*.55,52))
		index_targets.append({"row":row,"key":KEYS[row],"rect":rect})
	_sync_insets();queue_redraw()

func index_label(row: int) -> String:
	if observation: return ["齿孔残号", "剖面取景", "胶片边角"][row]
	var current: String=draft.get(DRAFT_KEYS[row],"")
	for option: Dictionary in source.options[KEYS[row]]:
		if not current.is_empty() and option.value==current: return str(option.label)
	return "已确认" if completed else "点按选择"

func cycle_index(row: int, direction: int) -> void:
	if not interactive or row<0 or row>=3 or abs(direction)!=1:return
	var options: Array=source.options[KEYS[row]].slice(1)
	var selected: String=draft.get(DRAFT_KEYS[row],"")
	var index: int=-1
	for i in range(options.size()):
		if options[i].value==selected:index=i;break
	var next: int=(0 if direction>0 else options.size()-1) if index<0 else posmod(index+direction,options.size())
	choice_requested.emit(KEYS[row],str(options[next].value))

func _text(point: Vector2, text: String, pixels := 15, ink := Color("e7d8b9"), centered := false) -> void:
	var font: Font = get_theme_default_font()
	var at := point
	if centered: at.x -= font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x/2.0
	draw_string(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,ink)

func _sprite(id: String, target: Rect2, tint := Color.WHITE) -> void:
	draw_texture_rect_region(ATLAS,target,REGIONS[id],tint,false,true)

func visual_drawer() -> Rect2:
	var pull := drawer_open
	if gesture == "drawer": pull = clampf((drag_current.y-drag_start.y)/90.0,0.0,.65)
	var offset := Vector2(0,_entry_pull()+cabinet.size.y*.18*pull)
	if motion == "reject": offset.y += sin(motion_time*30.0)*(1.0-minf(1,motion_time/.44))*5.0
	return Rect2(drawer.position+offset,drawer.size)

func _entry_pull() -> float:
	if completed or reduced: return 0.0
	return 5.0*cabinet.size.x/96.0*smoothstep(0,220,entry_ms)

func _draw() -> void:
	if source.is_empty() or not cabinet.has_area(): return
	var shade := Color("90c4cf") if observation else Color.WHITE
	# The paper channels stay registered while the real wooden front moves.
	var pull:float=(visual_drawer().position.y-drawer.position.y)/(cabinet.size.x/96.0)
	Art.render(self,cabinet,pull,0.0 if completed else 1.0,Vector2.ZERO,shade)
	if completed:
		# The saved terminal state contains no duplicate film. The acquisition
		# lift runs only after the first successful panel closes in the world.
		_text(Vector2(cabinet.get_center().x,cabinet.end.y+12),"旧导视胶片 · 已取出",16,Color("f1d18a"),true)
	else:
		_text(Vector2(cabinet.get_center().x,cabinet.position.y-8),"301 · 胶片索引抽屉",preload("res://scripts/ui/device_layout.gd").font_size(size,20),Color("c6b68e"),true)

func _sync_insets()->void:
	if index_keys.size()!=3 or index_targets.size()!=3 or handle_key==null:return
	for item:Dictionary in index_targets:
		var row:int=item.row;var rect:Rect2=item.rect
		if dragging and gesture=="index" and gesture_card.row==row:rect.position.x+=clampf(drag_current.x-drag_start.x,-10,10)
		index_keys[row].present(rect,TITLES[row],index_label(row),not completed and not observation,focused_row==row and interactive)
	handle_key.visible=not completed
	handle_key.present(handle,"","拉开",false,false,true)

func begin_result(success: bool) -> void:
	cancel_gesture()
	motion = "" if success else "reject"
	motion_time = 0.0
	if success: drawer_open=0.0
	if reduced:
		drawer_open = 0.0
		motion = ""
		motion_finished.emit()
	queue_redraw()

func _process(delta: float) -> void:
	if entry_ms<220:
		entry_ms=minf(220,entry_ms+clampf(delta,0,.06)*1000);queue_redraw()
	if motion.is_empty():
		_sync_insets();return
	motion_time += clampf(delta,0,.06)
	if motion == "open": drawer_open = smoothstep(0,.52,motion_time)
	if motion_time >= (.52 if motion == "open" else .44):
		motion = ""
		motion_finished.emit()
	_sync_insets();queue_redraw()

func cancel_gesture() -> void:
	dragging=false; pointer_kind=""; pointer_index=-1; pointer_device=0; gesture=""; gesture_card={}
	queue_redraw()

func _owned_pointer(kind: String, index: int, down: bool, point: Vector2, canceled := false, device := 0) -> bool:
	if canceled:
		if kind == pointer_kind and index == pointer_index and device == pointer_device: cancel_gesture(); return true
		return false
	if down:
		if not pointer_kind.is_empty() or not interactive: return false
		motion=""
		if handle.has_point(point): gesture = "drawer"
		else:
			for item: Dictionary in index_targets:
				if item.rect.has_point(point): gesture = "index"; gesture_card = item; break
		if gesture.is_empty(): return false
		pointer_kind=kind; pointer_index=index; pointer_device=device; dragging=true; drag_start=point; drag_current=point
		queue_redraw(); return true
	if kind != pointer_kind or index != pointer_index or device != pointer_device: return false
	var action := gesture
	var card := gesture_card.duplicate()
	var delta := point-drag_start
	var on_handle := handle.grow(10).has_point(point)
	cancel_gesture()
	if not interactive: return true
	if action == "drawer":
		if (delta.length()<18 and on_handle) or (delta.y>=26 and absf(delta.x)<maxf(54,handle.size.x)): drawer_requested.emit()
	elif action == "index" and play_area.has_point(point):
		if absf(delta.x)>=24 and absf(delta.x)>absf(delta.y)*1.2:cycle_index(int(card.row),1 if delta.x<0 else -1)
		elif delta.length()<18 and card.rect.grow(8).has_point(point):
			var divider:float=card.rect.position.x+(48.0 if narrow else 60.0)
			cycle_index(int(card.row),-1 if point.x<divider+26 else 1)
	return true

func _gui_input(event: InputEvent) -> void:
	var handled := false
	if event is InputEventScreenTouch:
		last_touch_at = Time.get_ticks_msec()
		handled = _owned_pointer("touch",event.index,event.pressed,event.position,event.canceled,event.device)
	elif event is InputEventScreenDrag and pointer_kind=="touch" and pointer_index==event.index and pointer_device==event.device:
		drag_current=event.position; queue_redraw(); handled=true
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.device!=InputEvent.DEVICE_ID_EMULATION:
		if Time.get_ticks_msec()-last_touch_at<400: return
		handled=_owned_pointer("mouse",0,event.pressed,event.position,false,event.device)
	elif event is InputEventMouseMotion and pointer_kind=="mouse" and pointer_device==event.device:
		drag_current=event.position; queue_redraw(); handled=true
	if handled: accept_event()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT or what==NOTIFICATION_EXIT_TREE or (what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree()): cancel_gesture()
