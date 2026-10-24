extends Control
## A loose tracing slips over registration marks; no guessed click submits it.
signal aligned
const Typography=preload("res://scripts/ui/native_typography.gd")
const PAPER=Color("F4EAD5")
const INK=Color("45423B")
const RED=Color("9A514A")
const TARGET=Vector2(170,100)
const EXTENT=Vector2(148,110)
var sheet:=Vector2(30,128)
var evidence_ready:=false
var sealed:=false
var round_id:=0
var pointer_owner:=-99
var offset:=Vector2.ZERO
var touch_time:=-1000
var placements:Dictionary={}
var evidence:Dictionary={}

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL
	resized.connect(func():cancel_drag();queue_redraw())
	visibility_changed.connect(func():if not is_visible_in_tree():cancel_drag())

func configure(id:int,record:Dictionary)->void:
	cancel_drag();round_id=id;evidence=record.duplicate(true)
	evidence_ready=bool(record.get("ready",false));sealed=bool(record.get("sealed",false))
	sheet=TARGET if sealed else placements.get(id,Vector2(30,128));queue_redraw()

func fit()->float:return minf(size.x/360.0,size.y/270.0)
func origin()->Vector2:return (size-Vector2(360,270)*fit())/2
func local_point(point:Vector2)->Vector2:return (point-origin())/maxf(.01,fit())
func sheet_rect()->Rect2:return Rect2(sheet,EXTENT)
func target_rect()->Rect2:return Rect2(TARGET,EXTENT)
func cancel_drag()->void:pointer_owner=-99;offset=Vector2.ZERO
func begin(id:int,point:Vector2)->bool:
	if not evidence_ready or sealed or pointer_owner!=-99 or not sheet_rect().has_point(point):return false
	pointer_owner=id;offset=point-sheet;grab_focus();return true
func move_sheet(point:Vector2)->void:
	sheet=(point-offset).clamp(Vector2(12,65),Vector2(200,128));placements[round_id]=sheet;queue_redraw()
func finish(id:int,cancelled:bool=false)->void:
	if pointer_owner!=id:return
	cancel_drag()
	if not cancelled:check_alignment()
func check_alignment()->void:
	if not evidence_ready or sealed or sheet.distance_to(TARGET)>8:return
	sheet=TARGET;placements[round_id]=sheet;sealed=true;queue_redraw();aligned.emit()
func handle_key(event:InputEventKey)->bool:
	if not event.pressed or event.echo or not has_focus() or not evidence_ready or sealed:return false
	var step:Vector2=Vector2.ZERO
	match event.keycode:
		KEY_LEFT:step.x=-4
		KEY_RIGHT:step.x=4
		KEY_UP:step.y=-4
		KEY_DOWN:step.y=4
		KEY_SPACE,KEY_ENTER,KEY_KP_ENTER:check_alignment();return true
		_:return false
	offset=Vector2.ZERO;move_sheet(sheet+step);return true
func _gui_input(event:InputEvent)->void:
	if event is InputEventKey:
		if handle_key(event):accept_event()
	elif event is InputEventScreenTouch:
		touch_time=Time.get_ticks_msec()
		if event.pressed:
			if begin(event.index,local_point(event.position)):accept_event()
		elif pointer_owner==event.index:finish(event.index,event.canceled);accept_event()
	elif event is InputEventScreenDrag and pointer_owner==event.index:
		move_sheet(local_point(event.position));accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and Time.get_ticks_msec()-touch_time>650:
		if event.pressed:
			if begin(-1,local_point(event.position)):accept_event()
		elif pointer_owner==-1:finish(-1);accept_event()
	elif event is InputEventMouseMotion and pointer_owner==-1:
		move_sheet(local_point(event.position));accept_event()

func label(at:Vector2,text:String,color:Color=INK,points:int=16)->void:
	draw_string(Typography.body_font(),at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,points,color)
func seal_marks(at:Vector2,color:Color,half:bool)->void:
	for p:Vector2 in [Vector2(12,12),Vector2(136,12),Vector2(12,98)]:
		var q:Vector2=at+p
		draw_line(q+Vector2(-6,0),q+Vector2(0,0) if half else q+Vector2(6,0),color,2)
		draw_line(q+Vector2(0,-6),q+Vector2(0,0) if half else q+Vector2(0,6),color,2)
func old_print()->void:
	var faded:=Color("AEA184")
	var at:Vector2=TARGET+Vector2(74,75)
	if round_id==0:
		for i:int in 7:
			var angle:float=deg_to_rad(-140+i*16)
			var end:Vector2=at+Vector2(cos(angle),sin(angle))*46
			draw_line(at,end,faded,1)
		draw_arc(at,46,deg_to_rad(-140),deg_to_rad(-75),18,faded,1.5)
		draw_circle(at,3,RED)
	elif round_id==1:
		draw_polyline(PackedVector2Array([at+Vector2(-38,12),at+Vector2(-38,-48),at+Vector2(34,-48),at+Vector2(34,-16)]),faded,2)
		for i:int in 4:draw_line(at+Vector2(-18+i*12,8-i*7),at+Vector2(-12+i*12,8-i*7),RED,2)
	else:
		draw_circle(at+Vector2(-48,-12),8,faded,false,2)
		draw_line(at+Vector2(-48,-4),at+Vector2(-48,14),faded,2)
		for endpoint:Vector2 in [Vector2(42,-40),Vector2(42,8)]:draw_dashed_line(at+Vector2(-38,-12),at+endpoint,faded,1,4)
		draw_line(at+Vector2(44,-37),at+Vector2(44,10),RED,2)
func _draw()->void:
	if fit()<=0:return
	draw_set_transform(origin(),0,Vector2.ONE*fit())
	label(Vector2(16,24),["残谱 · 扇骨页","残谱 · 门前页","残谱 · 同灯页"][round_id],RED,20)
	label(Vector2(16,46),"两影相照，缺笔可续",Color("AEA184"),14)
	draw_rect(target_rect(),Color("C9BA98"),false,1);seal_marks(TARGET,RED,false);old_print()
	if not evidence_ready:
		draw_rect(sheet_rect(),Color("C5B79240"));seal_marks(sheet,INK,true)
		label(sheet+Vector2(17,48),"影拓未成对",INK,16)
		label(Vector2(16,256),"页角夹着一张空试纸。",Color("AEA184"),14)
	else:
		draw_rect(Rect2(sheet+Vector2(3,4),EXTENT),Color("202B3520"));draw_rect(sheet_rect(),Color("E5D7B4CC"));seal_marks(sheet,INK,true)
		# Two real projections produce the difference shown on the tracing sheet.
		var pair:Dictionary=evidence.pairs.values()[0]
		for i:int in 2:
			var record:Dictionary=pair.before if i==0 else pair.after
			var shadow:Dictionary=record.projections[0]
			var reference:Vector2=sheet+Vector2(38+i*68,58)
			draw_line(reference+Vector2(0,-34),reference+Vector2(0,34),Color("9A514A55"),1)
			var at:Vector2=reference+Vector2(clampf(float(shadow.center)*5,-16,16),0)
			var radius:float=clampf(float(shadow.radius)*23,12,34)
			var span:float=radius*float(shadow.spread)
			draw_line(at+Vector2(0,-radius),at+Vector2(0,radius),INK,1)
			draw_polyline(PackedVector2Array([at+Vector2(0,-radius),at+Vector2(span,-radius*.7),at+Vector2(span, radius*.65),at+Vector2(0,radius)]),INK,1.5)
		label(sheet+Vector2(28,92),"前          后",INK,13)
		label(Vector2(16,256),"把影拓覆到旧印上。" if not sealed else "断笔相接，墨痕成句。",RED,14)
	if has_focus() and evidence_ready and not sealed:draw_rect(sheet_rect().grow(3),Color("AEA184"),false,1)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
