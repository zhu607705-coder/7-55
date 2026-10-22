extends RefCounted
## Exact animatePromoAndQueueShift authored beats, source CanteenInteriorScene.ts2820.
## Outputs presentation only. Caller owns its issued session and story acknowledgement.
static func beat(reduced: bool,short_ms: int,normal_ms: int) -> int:
	return short_ms if reduced else int(floor(normal_ms*1.286+.5))
static func timing(reduced: bool=false) -> Dictionary:
	var focus: int=beat(reduced,90,260)
	var blink_at: int=focus+beat(reduced,20,20)
	var blink_duration: int=beat(reduced,45,80)
	var insert_at: int=blink_at+blink_duration*(2 if reduced else 4)
	var reveal_at: int=insert_at+beat(reduced,110,410)
	var queue_focus_at: int=reveal_at+beat(reduced,120,430)
	var queue_focus: int=beat(reduced,100,280)
	var turn_at: int=queue_focus_at+queue_focus+beat(reduced,20,20)
	var wave_at: int=turn_at+beat(reduced,70,220)
	var wave_step: int=beat(reduced,65,145)
	var move: int=beat(reduced,100,310)
	var return_at: int=wave_at+wave_step*2+move+beat(reduced,40,40)
	var return_duration: int=beat(reduced,120,480)
	return {"focus":focus,"blinkAt":blink_at,"blinkDuration":blink_duration,"insertAt":insert_at,"revealAt":reveal_at,"queueFocusAt":queue_focus_at,"queueFocus":queue_focus,"turnAt":turn_at,"waveAt":wave_at,"waveStep":wave_step,"move":move,"returnAt":return_at,"returnDuration":return_duration,"completeAt":return_at+return_duration+beat(reduced,30,30)}
static func sine(t: float) -> float: return (1-cos(PI*clampf(t,0,1)))/2
static func back_out(t: float) -> float:
	var p: float=clampf(t,0,1)-1
	return p*p*(2.70158*p+1.70158)+1
static func snapshot(elapsed_ms: float,reduced: bool=false) -> Dictionary:
	var t: float=maxf(0,elapsed_ms)
	var b: Dictionary=timing(reduced)
	var revealed: bool=t>=b.revealAt
	var empty_alpha: float=1
	if t>=b.blinkAt and t<b.insertAt:
		var x: float=fmod((t-b.blinkAt)/b.blinkDuration,2)
		empty_alpha=lerpf(1,.34,x if x<=1 else 2-x)
	var active_alpha: float=0
	var active_scale: float=.46
	if revealed:
		var p: float=(t-b.revealAt)/beat(reduced,90,180)
		active_alpha=clampf(back_out(p),0,1); active_scale=lerpf(.46,.5,back_out(p))
		var flash_at: float=b.revealAt+beat(reduced,90,190)
		var flash_duration: float=beat(reduced,55,80)
		if t>=flash_at and t<flash_at+flash_duration*(2 if reduced else 4):
			var x: float=fmod((t-flash_at)/flash_duration,2)
			active_alpha=lerpf(1,.46,x if x<=1 else 2-x)
	var offsets: Array=[]; var collisions: Array=[]; var prompts: Array=[]
	for row in range(3):
		var move_at: float=b.waveAt+b.waveStep*row
		offsets.append(36*sine((t-move_at)/b.move))
		collisions.append(t<b.waveAt or t>=b.returnAt)
		var age: float=t-move_at
		var duration: float=beat(reduced,90,300)
		var ratio: float=clampf(age/duration,0,1)
		prompts.append({"visible":age>=0 and age<duration,"frame":3 if row==0 else 4,"alpha":1-sin(ratio*PI/2),"dy":-78-8*sin(ratio*PI/2)})
	return {"complete":t>=b.completeAt,"emptyVisible":not revealed,"emptyAlpha":empty_alpha,"insertVisible":t>=b.insertAt and not revealed,"insertFrame":mini(3,int(maxf(0,t-b.insertAt)/100)),"activeVisible":revealed,"activeAlpha":active_alpha,"activeScale":active_scale,"bubblesVisible":revealed,"bubblesFrame":int(maxf(0,t-b.revealAt)*6/1000)%3,"glowAlpha":.34*(1-sin(clampf((t-b.revealAt)/beat(reduced,100,420),0,1)*PI/2)) if revealed else 0.0,"glowScale":1+.08*sin(clampf((t-b.revealAt)/beat(reduced,100,420),0,1)*PI/2),"turnVisible":t>=b.turnAt and t<b.waveAt,"queueOffsets":offsets,"queueCollidable":collisions,"prompts":prompts}
static func camera(elapsed_ms: float,reduced: bool,initial: Vector2,initial_zoom: float,player: Vector2) -> Dictionary:
	var b: Dictionary=timing(reduced)
	var t: float=maxf(0,elapsed_ms)
	var promo:=Vector2(1232,158)
	var queue:=Vector2(1011,210)
	if t<b.queueFocusAt:
		var a: float=sine(t/b.focus)
		return {"point":initial.lerp(promo,a),"zoom":lerpf(initial_zoom,2.1,a)}
	if t<b.returnAt:
		var a: float=sine((t-b.queueFocusAt)/b.queueFocus)
		return {"point":promo.lerp(queue,a),"zoom":lerpf(2.1,1.55,a)}
	var a: float=sine((t-b.returnAt)/b.returnDuration)
	return {"point":queue.lerp(player,a),"zoom":lerpf(1.55,1,a)}
