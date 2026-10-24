extends Control
## Paper, drawer bands and their stamp are the controls, not a duplicate action list.
signal paper_event(event:Dictionary)
signal archive_choice(key:String,value:String)
signal check_requested
const Duty=preload("res://scripts/games/chapter4_duty_board.gd")
const Type=preload("res://scripts/ui/native_typography.gd")
const INK=Color("3f443c")
const RED=Color("9a514a")
const PAPER=Color("eee2c5")
var seal_key:Control
var session:RefCounted
var picked:=""
var pointer:=-99
var down_point:=Vector2.ZERO
var moved:=false
var drag_point:=Vector2.ZERO
var focus_index:=0
var last_touch:=-1000
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL
	custom_minimum_size=Vector2(0,384)
	tooltip_text="拖动纸片换位，轻点翻面；方向键选纸/换位，空格翻面，选中印章后按空格。" if session.puzzle_id=="duty_board" else "点签的两端或横拖换签；方向键选择，空格操作。";size_flags_horizontal=Control.SIZE_EXPAND_FILL
	seal_key=preload("res://scripts/objects/inset_option_key.gd").new();add_child(seal_key)
	resized.connect(_resize_paper);visibility_changed.connect(cancel);_resize_paper()
func _resize_paper()->void:
	cancel();custom_minimum_size.y=384*factor()
func factor()->float:return size.x/360.0
func point(local:Vector2)->Vector2:return local/maxf(.01,factor())
func row_rect(i:int)->Rect2:return Rect2(20,40+i*88,320,76)
func seal_rect()->Rect2:return Rect2(240,309,100,65)
func cancel()->void:pointer=-99;picked="";moved=false;queue_redraw()
func _notification(what:int)->void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:cancel()
func begin(id:int,at:Vector2)->void:
	if pointer!=-99 or session.pending:return
	pointer=id;down_point=point(at);drag_point=down_point;moved=false;grab_focus()
	for i:int in 3:
		if row_rect(i).has_point(down_point):focus_index=i;picked=session.draft.dutyOrder[i] if session.puzzle_id=="duty_board" else str(i)
	queue_redraw()
func finish(id:int,at:Vector2,canceled:bool=false)->void:
	if pointer!=id:return
	var finish_point:Vector2=point(at);var selected:String=picked
	var start:Vector2=down_point
	cancel()
	if canceled:return
	if seal_rect().has_point(start) and seal_rect().has_point(finish_point):check_requested.emit();return
	if selected.is_empty():return
	if session.puzzle_id=="duty_board":
		for i:int in 3:
			if not row_rect(i).has_point(finish_point):continue
			var other:String=session.draft.dutyOrder[i]
			if other!=selected:paper_event.emit({"kind":"swap","a":selected,"b":other})
			elif finish_point.distance_to(start)<18:paper_event.emit({"kind":"flip","id":selected})
			return
	else:
		var direction:int=1 if finish_point.x>=180 else -1
		if absf(finish_point.x-start.x)>20:direction=1 if finish_point.x>start.x else -1
		choose(int(selected),direction)
func choose(index:int,direction:int)->void:
	var key:String=["yearBand","floor","purpose"][index]
	var draft_key:String=["archiveYearBand","archiveFloor","archivePurpose"][index]
	var options:Array=session.source.options[key];var current:=-1
	for i:int in options.size():
		if options[i].value==session.draft[draft_key]:current=i
	var target:int=posmod(current+direction,options.size())
	archive_choice.emit(key,options[target].value)
func _gui_input(event:InputEvent)->void:
	if event is InputEventScreenTouch:
		last_touch=Time.get_ticks_msec()
		if event.pressed:begin(event.index,event.position)
		else:finish(event.index,event.position,event.canceled)
		accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and Time.get_ticks_msec()-last_touch>650:
		if event.pressed:begin(-1,event.position)
		else:finish(-1,event.position)
		accept_event()
	elif event is InputEventScreenDrag and pointer==event.index:
		drag_point=point(event.position);moved=drag_point.distance_to(down_point)>8;queue_redraw();accept_event()
	elif event is InputEventMouseMotion and pointer==-1:
		drag_point=point(event.position);moved=drag_point.distance_to(down_point)>8;queue_redraw();accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_UP,KEY_DOWN]:focus_index=posmod(focus_index+(1 if event.keycode==KEY_DOWN else -1),4);queue_redraw();accept_event()
		elif event.keycode in [KEY_SPACE,KEY_ENTER]:
			if focus_index==3:check_requested.emit()
			elif session.puzzle_id=="duty_board":paper_event.emit({"kind":"flip","id":session.draft.dutyOrder[focus_index]})
			else:choose(focus_index,1)
			accept_event()
		elif event.keycode in [KEY_LEFT,KEY_RIGHT] and focus_index<3:
			var direction:int=1 if event.keycode==KEY_RIGHT else -1
			if session.puzzle_id=="archive_index":choose(focus_index,direction)
			else:paper_event.emit({"kind":"swap","a":session.draft.dutyOrder[focus_index],"b":session.draft.dutyOrder[posmod(focus_index+direction,3)]})
			accept_event()
func words(at:Vector2,text:String,points:int=18,ink:Color=INK)->void:draw_string(Type.body_font(),at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,points,ink)
func _draw()->void:
	if session==null:return
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE*factor())
	draw_rect(Rect2(0,0,360,384),Color("817052"));draw_rect(Rect2(8,8,344,368),Color("b4a07a"))
	words(Vector2(20,28),"交接纸夹" if session.puzzle_id=="duty_board" else "胶片索引抽屉",19)
	for i:int in 3:
		var rect:Rect2=row_rect(i)
		if moved and picked==str(session.draft.dutyOrder[i]) and session.puzzle_id=="duty_board":
			draw_rect(rect,Color("66583f"))
			rect.position+=(drag_point-down_point).clamp(Vector2(-14,-200),Vector2(14,200))
		draw_rect(Rect2(rect.position+Vector2(3,3),rect.size),Color("4f493b"));draw_rect(rect,PAPER)
		if session.puzzle_id=="duty_board":
			var id:String=session.draft.dutyOrder[i]
			var cp:Dictionary={"version":1,"order":session.draft.dutyOrder,"backs":session.draft.dutyBacks}
			var edges:Array=Duty.endpoints(cp,id)
			var a:Vector2=rect.position+Vector2(edges[0],0);var b:Vector2=rect.position+Vector2(edges[1],rect.size.y)
			draw_polyline(PackedVector2Array([a,a+Vector2(0,18),Vector2(b.x,a.y+56),b]),RED,3)
			words(rect.position+Vector2(10,44),{"classroom_104":"104","classroom_105":"105","main_elevator":"门机"}[id],22)
			words(rect.position+Vector2(255,65),"背" if cp.backs[id] else "正",18,Color("928061"))
		else:
			var key:String=["archiveYearBand","archiveFloor","archivePurpose"][i]
			var selected:String=session.draft[key]
			var option_key:String=["yearBand","floor","purpose"][i]
			var caption:="空签"
			for option:Dictionary in session.source.options[option_key]:
				if option.value==selected:caption=option.label
			words(rect.position+Vector2(64,47),caption,21)
			for x:int in [24,292]:
				draw_arc(rect.position+Vector2(x,38),12,0,TAU,24,INK,2)
				words(rect.position+Vector2(x-5,44),"‹" if x<100 else "›",20)
			words(rect.position+Vector2(68,20),["年代","楼层","用途"][i],13,Color("928061"))
		if has_focus() and focus_index==i:draw_rect(rect.grow(2),INK,false,2)
	if session.puzzle_id=="duty_board":
		draw_line(Vector2(90,31),Vector2(90,40),RED,4);draw_line(Vector2(280,292),Vector2(280,303),RED,4)
		words(Vector2(22,335),"拾起 / 翻面",15)
	else:words(Vector2(22,335),"转签后拉开抽屉",15)
	var seal:Rect2=seal_rect()
	if seal_key!=null:seal_key.present(Rect2(seal.position*factor(),seal.size*factor()),"","压印" if session.puzzle_id=="duty_board" else "拉开",false,has_focus() and focus_index==3,true)
	draw_set_transform(Vector2.ZERO)
