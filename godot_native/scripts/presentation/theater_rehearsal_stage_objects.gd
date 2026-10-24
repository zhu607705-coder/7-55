extends RefCounted
## Stage hardware shares the plate's logical coordinates, never a screen toolbar.
const IDS=["programme","curtain","exit"]
const BOOK=Rect2(62,342,72,30)
const CORD=Rect2(850,292,40,58)
const EXIT=Rect2(18,220,40,78)
const PAPER=Color("E5D7B4")
const BRASS=Color("C2A46F")
const INK=Color("45423B")

static func rect(id:String)->Rect2:
	return {"programme":BOOK,"curtain":CORD,"exit":EXIT}.get(id,Rect2())

static func draw(canvas:CanvasItem,active:String,pressed:String,amount:float,clock:float,reduced:bool)->void:
	draw_programme(canvas,active=="programme",amount if pressed=="programme" else 0.0)
	# Curtain rope runs from the side-wing pulley to a graspable wooden toggle.
	var pull:float=amount*28 if pressed=="curtain" else 0.0
	var sway:float=0.0 if reduced else sin(clock*1.4)*1.1
	var grip:=Vector2(870+sway,316+pull)
	canvas.draw_circle(Vector2(870,34),7,Color("665C42"))
	canvas.draw_circle(Vector2(870,34),3,BRASS)
	canvas.draw_line(Vector2(870,41),grip,Color("45423B"),5)
	canvas.draw_line(Vector2(869,41),grip-Vector2(1,0),BRASS,2)
	canvas.draw_rect(Rect2(grip-Vector2(14,3),Vector2(28,7)),Color("665C42"))
	canvas.draw_line(grip+Vector2(-13,-3),grip+Vector2(13,-3),BRASS if active=="curtain" else Color("9D875E"),2)
	canvas.draw_line(grip+Vector2(0,4),grip+Vector2(0,18),Color("9A514A"),5)
	for i:int in range(-2,3):canvas.draw_line(grip+Vector2(i,18),grip+Vector2(i*2,28),Color("9A514A"),1)
	# The narrow dark passage lies behind the left curtain, away from puzzle props.
	var edge:float=amount*8 if pressed=="exit" else (4.0 if active=="exit" else 0.0)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(28,220),Vector2(46+edge,223),Vector2(48+edge,292),Vector2(21,298)]),Color("202B35"))
	canvas.draw_line(Vector2(49+edge,222),Vector2(50+edge,291),BRASS if active=="exit" else Color("665C42"),2)
	canvas.draw_line(Vector2(22,298),Vector2(49+edge,292),Color("9D875E"),2)

static func draw_programme(canvas:CanvasItem,active:bool,amount:float=0.0)->void:
	# An open stitched programme rests on the existing table. Its fore-edge lifts.
	var lift:float=amount*12 if amount>0 else (3.0 if active else 0.0)
	var spine:=Vector2(98,359)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(62,354),Vector2(95,346),Vector2(134,354),Vector2(136,375),Vector2(99,380),Vector2(64,374)]),Color("202B354A"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(62,347),Vector2(94,342),Vector2(98,348),Vector2(134,344),Vector2(134,370),Vector2(98,375),Vector2(64,371)]),Color("9A514A"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(64,346),Vector2(94,344),spine,Vector2(97,372),Vector2(66,369)]),PAPER)
	canvas.draw_colored_polygon(PackedVector2Array([spine,Vector2(130,345-lift),Vector2(132,367-lift),Vector2(99,372)]),Color("F4EAD5"))
	canvas.draw_line(Vector2(94,345),Vector2(98,372),Color("9D875E"),1)
	# A fan diagram and light-ray sketch make the book readable as rehearsal notes.
	for i:int in range(5):canvas.draw_line(Vector2(82,365),Vector2(70+i*5,351),INK,1)
	canvas.draw_line(Vector2(105,364),Vector2(122,351-lift),INK,1)
	canvas.draw_line(Vector2(105,364),Vector2(125,361-lift),INK,1)
	canvas.draw_line(Vector2(125,350-lift),Vector2(125,362-lift),Color("9A514A"),2)
	canvas.draw_line(Vector2(99,370),Vector2(102,382),Color("9A514A"),2)
	if active:canvas.draw_line(Vector2(66,369),Vector2(97,372),BRASS,2)
