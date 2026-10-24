extends Button
## Illustrated evidence and signal cards. They never determine puzzle answers.
var kind:="source"
var id:=""
var spec:Dictionary={}
var chosen:=false
var font:Font
var samples:=0
var caption:=""
var drift:=0.0
var settled:=false
var reduced:=false
var phase:=0.0
const INK=Color("34463c")
const MUTED=Color("8a948b")
const BRASS=Color("ac8247")
const RED=Color("b16a51")
func _ready()->void:
	text="";mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	if kind=="drift" and settled and not reduced:
		var animation=create_tween();animation.tween_property(self,"drift",0.0,.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	elif kind=="drift" and settled:drift=0
func _process(dt:float)->void:
	if kind=="source" and id=="hall" and not reduced:phase=fmod(phase+dt,3.0);queue_redraw()
	elif kind=="drift":queue_redraw()
func words(at:Vector2,value:String,points:int=18,ink:Color=INK)->void:
	if font:draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,points,ink)
func clock_face(at:Vector2,r:float,h:float,m:float)->void:
	draw_circle(at,r,Color("f5efde"));draw_arc(at,r,0,TAU,48,BRASS,2,false)
	for i in 12:
		var unit:=Vector2.from_angle(i*TAU/12-PI/2);draw_line(at+unit*r*.86,at+unit*r*.98,INK,2,false)
	draw_line(at,at+Vector2.from_angle((h+m/60)*TAU/12-PI/2)*r*.53,INK,3,false)
	draw_line(at,at+Vector2.from_angle(m*TAU/60-PI/2)*r*.77,INK,2,false);draw_circle(at,3,BRASS)
func stamp(at:Vector2,mark:String,r:float=14)->void:
	draw_arc(at,r,0,TAU,32,BRASS,1.5,false)
	if mark=="麦":
		draw_line(at+Vector2(0,-9),at+Vector2(0,9),BRASS,2,false)
		for y in [-5,0,5]:
			draw_line(at+Vector2(0,y),at+Vector2(-6,y-4),BRASS,2,false);draw_line(at+Vector2(0,y),at+Vector2(6,y-4),BRASS,2,false)
	elif mark=="书":
		draw_polyline(PackedVector2Array([at+Vector2(-8,-6),at+Vector2(0,-3),at+Vector2(8,-6),at+Vector2(8,7),at+Vector2(0,9),at+Vector2(-8,7),at+Vector2(-8,-6)]),BRASS,1.5,false);draw_line(at+Vector2(0,-3),at+Vector2(0,9),BRASS,1.5,false)
	elif mark=="修":
		draw_line(at+Vector2(-6,8),at+Vector2(5,-6),BRASS,4,false);draw_arc(at+Vector2(5,-6),5,.5,4.2,12,BRASS,2,false)
	else:draw_arc(at,8,-1.3,1.6,18,BRASS,3,false)
func paper(at:Vector2,extent:Vector2)->void:
	draw_rect(Rect2(at+Vector2(3,4),extent),Color(0,0,0,.08));draw_rect(Rect2(at,extent),Color("f8f3e7"));draw_rect(Rect2(at,extent),Color("bcb39e"),false,1)
func event_icon(at:Vector2,mark:String)->void:
	if mark=="麦":
		draw_rect(Rect2(at+Vector2(-39,-4),Vector2(78,10)),INK,false,2)
		for x in [-30,-10,10,30]:draw_circle(at+Vector2(x,11),5,BRASS)
		draw_rect(Rect2(at+Vector2(-6,-21),Vector2(14,15)),BRASS);draw_line(at+Vector2(24,-28),at+Vector2(24,5),RED,2,false)
	elif mark=="书":
		draw_rect(Rect2(at+Vector2(-34,-25),Vector2(68,45)),INK,false,2);draw_line(at+Vector2(0,20),at+Vector2(0,31),INK,2,false)
		for i in 3:draw_line(at+Vector2(-22,-15+i*9),at+Vector2(18,-15+i*9),MUTED,2,false)
		draw_line(at+Vector2(25,-22),at+Vector2(25,16),BRASS,4,false)
	else:
		draw_circle(at+Vector2(-24,3),4,INK);draw_circle(at+Vector2(24,3),4,INK);draw_line(at+Vector2(-24,3),at+Vector2(14,-20),BRASS,4,false)
		draw_line(at+Vector2(-43,3),at+Vector2(-28,3),INK,2,false);draw_line(at+Vector2(28,3),at+Vector2(43,3),INK,2,false)
func pulse(at:Vector2,width:float,offset:float,ink:Color)->void:
	var points:=PackedVector2Array([at,at+Vector2(width*.38+offset,0),at+Vector2(width*.38+offset,-15),at+Vector2(width*.45+offset,-15),at+Vector2(width*.45+offset,0),at+Vector2(width,0)])
	draw_polyline(points,ink,2,false)
func _draw()->void:
	var center:=size/2
	if chosen:draw_rect(Rect2(3,3,size.x-6,size.y-6),BRASS,false,2)
	match kind:
		"source":
			if id=="hall":
				clock_face(Vector2(42,43),27,10,phase*10 if not reduced else 45)
				pulse(Vector2(88,50),size.x-112,sin(phase*TAU)*5,INK);words(Vector2(88,25),"现场",17)
			elif id=="phone":
				draw_rect(Rect2(20,17,40,58),INK,false,2);words(Vector2(79,39),caption,24);draw_line(Vector2(82,60),Vector2(size.x-25,60),MUTED,2,false)
			else:
				paper(Vector2(23,17),Vector2(39,53));words(Vector2(81,40),"08:00",24);words(Vector2(81,65),"缓存",17,MUTED)
		"evidence":
			paper(Vector2(9,9),size-Vector2(18,18))
			var mark:String=spec.symbol if id in ["start","delay","event"] else {"麦":"月","书":"麦","修":"书"}[spec.symbol] if id=="night" else "书"
			stamp(Vector2(size.x-29,29),mark)
			if id=="start":
				var start:Array={"麦":[12,0],"书":[18,30],"修":[22,0]}[spec.symbol]
				clock_face(Vector2(48,50),25,start[0],start[1]);words(Vector2(21,size.y-19),"%02d:%02d"%start,22)
			elif id=="delay":
				if spec.symbol=="修":
					for i in 3:draw_rect(Rect2(20+i*39,47,31,29),BRASS,false,2)
					words(Vector2(21,size.y-19),"3 × 15 min",19)
				else:
					draw_arc(Vector2(49,53),23,-PI/2,PI*1.35,36,INK,2,false);draw_line(Vector2(49,53),Vector2(49,34),BRASS,3,false)
					words(Vector2(21,size.y-19),"25 min" if spec.symbol=="麦" else "20 min",22)
			elif id=="event":event_icon(Vector2(size.x*.44,65),spec.symbol);words(Vector2(21,size.y-19),"锁定此刻",16,MUTED)
			elif id=="night":
				var old:Array={"麦":[22,45],"书":[12,25],"修":[18,50]}[spec.symbol]
				clock_face(Vector2(48,54),25,old[0],old[1]);words(Vector2(21,size.y-19),"%02d:%02d"%old,22)
			else:draw_rect(Rect2(27,38,53,34),MUTED,false,2);words(Vector2(21,size.y-19),"08:00",22)
		"timeline":
			var start:Array={"麦":[12,0],"书":[18,30],"修":[22,0]}[spec.symbol]
			clock_face(Vector2(46,44),30,start[0],start[1]);words(Vector2(12,100),"%02d:%02d"%start,20)
			words(Vector2(95,49),"+",23,BRASS)
			words(Vector2(132,48),"25 min" if spec.symbol=="麦" else "20 min" if spec.symbol=="书" else "3 × 15",23)
			draw_line(Vector2(238,43),Vector2(267,43),BRASS,2,false);draw_line(Vector2(260,37),Vector2(267,43),BRASS,2,false);draw_line(Vector2(260,49),Vector2(267,43),BRASS,2,false)
			event_icon(Vector2(320,44),spec.symbol);words(Vector2(293,100),"? : ?",22)
		"target":
			clock_face(Vector2(size.x/2,44),30,spec.hour,spec.minute);words(Vector2(size.x/2-35,103),"%02d:%02d"%[spec.hour,spec.minute],22)
		"drift":
			words(Vector2(10,23),caption,17);words(Vector2(size.x-83,23),"%+d s"%roundi(drift),18,INK if settled else RED)
			pulse(Vector2(14,60),size.x-28,0,MUTED);pulse(Vector2(14,60),size.x-28,drift*2,BRASS)
		"verify":
			words(Vector2(14,30),caption,20)
			var interval:int=spec.pulseInterval
			var values:Array=[0,interval,interval*2] if id=="live" else [0,0,0] if id=="frozen" else [0,interval,interval*2+3]
			var base:=Vector2(67,43)
			draw_line(base-Vector2(8,0),Vector2(size.x-22,43),MUTED,1,false)
			var last:=base
			for i in samples:
				var point:=base+Vector2(float(values[i])/interval*96,0)
				if i>0:draw_line(last,point,BRASS,2,false)
				draw_circle(point-Vector2(0,i*4 if id=="frozen" else 0),5,BRASS);words(point+Vector2(-6,27),str(values[i]),16);last=point
		"ready":
			clock_face(Vector2(72,75),47,spec.hour,spec.minute);pulse(Vector2(146,82),size.x-165,0,BRASS);words(Vector2(24,150),"%02d:%02d"%[spec.hour,spec.minute],28)
