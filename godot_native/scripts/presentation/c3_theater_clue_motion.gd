extends RefCounted
## Presentation samples only. Original controller success/consumption is already
## committed before either clock starts; these samples never award or roll back.
const POSTER_MS:=1620.0
const DUST_MS:=1580.0
const GLASS:=Rect2(174,712,230,62)
const TICKET:=Vector2(281,740)
const VENT_LIP:=Vector2(936,116)
const PAPER:=Vector2(835,180)
const WIPE_STROKES: Array[Vector2]=[Vector2(184,721),Vector2(394,727),Vector2(185,758),Vector2(402,761)]
const WIPE_TIMES: Array[float]=[160.0,460.0,760.0,1060.0]

static func smooth(value: float)->float:
	var p:=clampf(value,0,1)
	return p*p*(3-2*p)

static func poster(ms: float)->Dictionary:
	var cloth:=Vector2(422,783).lerp(WIPE_STROKES[0],smooth(ms/160.0))
	var angle:=lerpf(-18,0,smooth(ms/160.0))
	for i in 3:
		if ms>=WIPE_TIMES[i]:
			cloth=WIPE_STROKES[i].lerp(WIPE_STROKES[i+1],smooth((ms-WIPE_TIMES[i])/300.0))
			angle=lerpf(-8,8,smooth((ms-WIPE_TIMES[i])/300.0))*(-1 if i==1 else 1)
	if ms>=1060:
		cloth=WIPE_STROKES[3].lerp(Vector2(425,790),smooth((ms-1060)/230.0))
	var lift:=smooth((ms-1110)/190.0)
	var withdraw:=smooth((ms-1370)/250.0)
	return {"cloth":cloth.round(),"cloth_angle":angle,"cloth_alpha":1-smooth((ms-1150)/190.0),"lift":lift,"ticket_offset":Vector2(0,-8*lift-10*withdraw),"ticket_alpha":1-withdraw,"phase":"contact" if ms<160 else "wipe" if ms<1060 else "peel" if ms<1370 else "settle"}

static func cleared(point: Vector2,ms: float)->bool:
	# A cell is revealed only after the tissue has actually crossed it. The
	# accumulated swept area is monotone through all three physical passes.
	for i in 3:
		if ms<WIPE_TIMES[i]:continue
		var end:=WIPE_STROKES[i].lerp(WIPE_STROKES[i+1],smooth((ms-WIPE_TIMES[i])/300.0))
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point,WIPE_STROKES[i],end))<=19:return true
	return false

static func dust(ms: float)->Dictionary:
	var arrive:=smooth(ms/180.0)
	var flick:=sin(clampf((ms-180)/240.0,0,1)*PI)
	var retreat:=smooth((ms-500)/220.0)
	var recoil:=smooth((ms-430)/150.0)*(1-smooth((ms-850)/420.0))
	var crease:=smooth((ms-560)/150.0)*(1-smooth((ms-830)/380.0))
	var settle:=smooth((ms-1270)/310.0)
	return {"brush_contact":Vector2(982,163).lerp(VENT_LIP,arrive)+Vector2(34,39)*retreat,"brush_angle":-8*flick,"brush_alpha":1-retreat,"paper":PAPER+Vector2(-22*recoil,-6*recoil),"paper_angle":-10*recoil,"fold":crease*.98,"edge":smooth((ms-540)/600.0),"settle":settle,"phase":"contact" if ms<180 else "hesitate" if ms<430 else "recoil" if ms<560 else "fold" if ms<830 else "unfurl" if ms<1270 else "settle"}

static func grains(ms: float)->Array:
	var out: Array=[]
	# Twelve bounded grains follow the authored vent-to-stage path. No random
	# emission, room-wide cloud, glow, collision, or new route is introduced.
	for i in 12:
		var p: float=(ms-240-i*19)/460.0
		if p<0 or p>1:continue
		var start:=VENT_LIP+Vector2((i%3)*3-3,4)
		var end:=PAPER+Vector2((i%4)*8-14,(i%3)*10-11)
		var point:=start.lerp(end,p)+Vector2(0,sin(p*PI)*(8+i%3*3))
		out.append({"point":point.round(),"alpha":minf(1,p*8)*(1-smooth((p-.8)/.2)),"size":2+i%2})
	return out
