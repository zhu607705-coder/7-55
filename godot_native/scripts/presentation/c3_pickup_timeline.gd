extends RefCounted
## Read-only sample of CanteenInteriorScene.animatePaperBurst. Milliseconds are
## presentation time only: no gameplay state, scene transitions or RNG consumption.
const DURATION_MS: float=11380.0
const WINDOW=Vector2(790,218)
const ROOM=Vector2(1672,941)
const FULL_ZOOM: float=minf(960.0/1672.0,540.0/941.0)*.985
const SHAKE_FRAMES=[0,1,0,2,3,4]
const CUES=[[0,"canteen_pickup_ticket_handoff"],[850,"canteen_pickup_cutscene_quiet"],[4030,"canteen_paper_package_wait"],[4930,"canteen_paper_package_shake"],[5980,"canteen_paper_burst_started"],[6500,"canteen_paper_camera_impact"],[9580,"canteen_paper_burst_completed"]]
static func _ratio(t:float,start:float,duration:float)->float:return clampf((t-start)/duration,0,1)
static func _sine(q:float)->float:return (1-cos(PI*q))/2
static func _out(q:float)->float:return 1-(1-q)*(1-q)
static func paper_position(t:float)->Vector2:
	var q:=_out(_ratio(t,6980,700))
	var p:=Vector2(790,242).lerp(Vector2(836,470),q)
	if t>=7680 and t<8040:
		var bounce:=fmod(t-7680,180.0)
		var up:=bounce<90
		p.y=lerpf(470,458,_out(bounce/90)) if up else lerpf(458,470,pow((bounce-90)/90,2))
	return p
static func _follow_center(t:float)->Vector2:
	# Source startFollow .07 is sampled at a fixed 60 Hz, independent of the
	# display frame rate. Phaser startFollow/setDeadzone center immediately on
	# the paper. Deadzone dimensions are source-world pixels, not zoom-scaled.
	var center:=WINDOW+Vector2(0,24)
	var age:=clampf(t-6980,0,1060)
	var cursor:=0.0
	while cursor<age:
		var dt:=minf(1000.0/60,age-cursor);cursor+=dt
		var gap:=paper_position(6980+cursor)-center
		var half:=Vector2(45,30)
		var target:=Vector2(signf(gap.x)*maxf(absf(gap.x)-half.x,0),signf(gap.y)*maxf(absf(gap.y)-half.y,0))
		center=(center+target*(1-pow(.93,dt/(1000.0/60)))).floor() # roundPixels=true
	return center
static func sample(milliseconds:float,reduced:bool=false,start_player:Vector2=Vector2(790,260),start_camera:Vector2=Vector2(790,260),start_zoom:float=1.0)->Dictionary:
	var t:=clampf(milliseconds,0,DURATION_MS)
	var camera:=start_camera;var zoom:=start_zoom
	if t>=1500:
		var push:=_sine(_ratio(t,1500,1100));camera=start_camera.lerp(WINDOW+Vector2(0,18),push);zoom=lerpf(start_zoom,2.18,push)
	if t>=6980:camera=_follow_center(t);zoom=lerpf(2.18,1.42,sin(_ratio(t,6980,700)*PI/2))
	if t>=8040:
		var pull:=sin(_ratio(t,8040,850)*PI/2);camera=_follow_center(8040).lerp(ROOM/2,pull);zoom=lerpf(1.42,FULL_ZOOM,pull)
	var shake:=Vector2.ZERO
	var shake_age:=t-5980 if t<6500 else t-6500
	var shake_duration:=120.0 if t<6500 else 90.0
	if not reduced and shake_age>=0 and shake_age<shake_duration:
		var strength:float=5.76 if t<6500 else 4.32
		shake=Vector2(sin(shake_age*.19),cos(shake_age*.27))*strength*(1-shake_age/shake_duration)
	var ticket_q:=_sine(_ratio(t,0,650));var ticket_out:=_ratio(t,650,200)
	var cart_alpha:=0.0
	# Source early preview: round(850*.48)=408, then a 90ms yoyo.
	if t>=8448 and t<8628:cart_alpha=1-absf((t-8448)/90-1)
	if t>=8930:
		cart_alpha=1.0 if t>=9330 else 1-absf(fmod(t-8930,200.0)/100-1)
	var close_q:=_ratio(t,6500,120);var back:=1+2.70158*pow(close_q-1,3)+1.70158*pow(close_q-1,2)
	var stage:="ticket" if t<850 else "quiet" if t<1500 else "camera_push" if t<2630 else "auntie_push" if t<4030 else "package_wait" if t<4930 else "package_shake" if t<5980 else "burst" if t<6500 else "camera_impact" if t<6980 else "paper_flight" if t<8040 else "pull_back" if t<8930 else "cart_reveal" if t<9580 else "dialogue" if t<DURATION_MS else "defense"
	return {
		"elapsed":t,
		"stage":stage,
		"camera":camera,
		"zoom":zoom,
		"shake":shake,
		"crowd_visible":t<8040,
		"shadow_visible":t<2630,
		"ticket_visible":t<850,
		"ticket_position":(start_player-Vector2(0,50)).lerp(WINDOW+Vector2(0,22),ticket_q),
		"ticket_scale":lerpf(1,.72,ticket_q) if t<650 else lerpf(.72,.16,ticket_out*ticket_out),
		"ticket_alpha":1-ticket_out*ticket_out,
		"glow_alpha":_ratio(t,850,300)*(1-sin(_ratio(t,8040,850)*PI/2)),
		"auntie_visible":t>=2630 and t<4290,
		"auntie_frame":clampi(int((t-2630)*3.6/1000),0,4),
		"auntie_alpha":1-_ratio(t,4030,260),
		"package_visible":t>=4030 and t<5980,
		"package_frame":SHAKE_FRAMES[clampi(int((t-4930)*5.7/1000),0,5)] if t>=4930 else 0,
		"bubble_frame":int(maxf(0,t-4030)*6/1000)%3,
		"burst_visible":t>=5980 and t<6500,
		"burst_frame":clampi(int((t-5980)*15.4/1000),0,7),
		"closeup_visible":t>=6500 and t<6980,
		"closeup_scale":lerpf(.76,1,back),
		"closeup_angle":lerpf(-5,0,back),
		"paper_visible":t>=6980,
		"paper_position":paper_position(t),
		"paper_scale":lerpf(2.15,1.12,_out(_ratio(t,6980,700))),
		"paper_angle":lerpf(-12,348,_out(_ratio(t,6980,700))),
		"cart_alpha":cart_alpha,
		"subtitle":"玩家：那是鸡吗？" if t>=9580 and t<10360 else "系统：现在不是了。" if t>=10480 and t<11260 else "",
		"done":t>=DURATION_MS
	}
