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
	var sweep:=sin(clampf((ms-180)/380.0,0,1)*TAU)*5.0
	var retreat:=smooth((ms-580)/200.0)
	var flutter:=sin(clampf((ms-630)/610.0,0,1)*TAU*1.5)*1.7*smooth((ms-630)/90.0)*(1-smooth((ms-1030)/210.0))
	return {"brush_contact":Vector2(958,158).lerp(VENT_LIP,arrive)+Vector2(sweep,0)+Vector2(22,26)*retreat,
		"brush_angle":120+sweep*.55,"brush_alpha":smooth(ms/90.0)*(1-retreat),"paper":PAPER,
		"flutter":flutter,"paper_alpha":smooth(ms/120.0),"edge":smooth((ms-650)/650.0),
		"phase":"contact" if ms<180 else "sweep" if ms<560 else "airflow" if ms<650 else "edge_flutter" if ms<1240 else "settle"}

static func grains(ms: float)->Array:
	var out: Array=[]
	# A small, matte powder stream follows the original wind route. The first
	# grain reaches the right paper edge at650ms, before its mark can appear.
	for i in 6:
		var p: float=(ms-260-i*38)/390.0
		if p<0 or p>1.16:continue
		var start:=VENT_LIP+Vector2((i%3)*2-2,4)
		var end:=PAPER+Vector2(20+(i%2)*2,(i%3)*7-5)
		var travel:=minf(1,p)
		var point:=start.lerp(end,travel)+Vector2(0,sin(travel*PI)*4)
		out.append({"point":point.round(),"alpha":smooth(p*5)*(1-smooth((p-1)/.16)),"size":1+i%2})
	return out
