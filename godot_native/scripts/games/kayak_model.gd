extends RefCounted
## Stroke dynamics from QizhenLakeScene; swan pressure from QizhenSwanChasePressureModel.
## This bounded travel channel does not replace source-map collision geometry.
var bounded: bool=true
var phase: String="boarding"
var goal: float=4
var status: String="running"
var position: Vector2=Vector2(0,270)
var heading: float=0
var speed: float=0
var roll: float=0
var tick: int=0
var elapsed: float=0
var remainder: float=0
var last_stroke: float=-10
var last_side: String=""
var last_direction: String=""
var same_side_streak: int=0
var strokes: Array=[]
var inputs: Array=[]
var alternations: int=0
var tutorial_streak: int=0
var capsizes: int=0
# Live source-map tutorial sets its controller-owned allowance; bounded replay is unchanged.
var capsize_allowance: float=0
var collision_count: int=0
var distance: float=0
var feedback: String="交替划动左右桨，保持平衡；S + 划桨可后退"
var swan: Vector2=Vector2(-230,270)
var swan_speed: float=0
var gap: float=230
var pressure: String="release_warning"
var pressure_elapsed: float=0
var cycle_index: int=0
var aim_y: float=270
var segment: String="opening"

func configure(configuration: Dictionary) -> void:
	phase=configuration.get("phase","boarding")
	bounded=bool(configuration.get("bounded",phase!="world"))
	goal=float(configuration.get("goal",1000 if phase=="chase" else (220 if phase=="travel" else 4)))

func stroke(side: String, reverse: bool=false, record: bool=true) -> void:
	if status!="running": return
	var direction: String="reverse" if reverse else "forward"
	if record: inputs.append({"tick":tick,"side":side,"direction":direction})
	var cadence: bool=elapsed-last_stroke<=1.45
	var same_direction: bool=cadence and last_direction==direction
	var alternating: bool=same_direction and not last_side.is_empty() and last_side!=side
	var repeated: bool=same_direction and last_side==side
	same_side_streak=same_side_streak+1 if repeated else 1
	var direction_sign: float=-1 if reverse else 1
	var side_sign: float=1 if side=="left" else -1
	var impulse: float=(84 if reverse else 104) if alternating else (42 if reverse else 52)
	speed=clampf(speed+direction_sign*impulse,-230,340)
	var turn: float=0.16+minf(0.13,same_side_streak*0.025)
	heading+=side_sign*direction_sign*turn*(2 if alternating else 1)
	if alternating:
		roll*=0.36
		same_side_streak=1
		alternations+=1
	else: roll+=side_sign*(0.23+minf(0.18,same_side_streak*0.035))
	if not reverse:
		strokes.append(side)
		tutorial_streak=tutorial_streak+1 if alternating else 1
	else: tutorial_streak=0
	last_stroke=elapsed
	last_side=side
	last_direction=direction
	var allowance: float=maxf(0,0.3-strokes.size()*0.045) if phase in ["boarding","rain"] else capsize_allowance
	if same_side_streak>=4 or absf(roll)>=0.92+allowance:
		capsizes+=1
		status="lost"
		feedback="连续同侧划桨导致翻船；重试从安全点出发"
	elif phase in ["boarding","rain"] and tutorial_streak>=4:
		status="won"
		distance=4
	else: feedback="交替划桨，船身恢复了平衡" if alternating else "船正在侧倾，换另一侧划桨"

func update(delta: float) -> void:
	remainder+=clampf(delta,0,5)
	while remainder>=1.0/120.0 and status=="running":
		step()
		remainder-=1.0/120.0

func step() -> void:
	if status!="running": return
	var dt: float=1.0/120.0
	tick+=1
	elapsed=tick/120.0
	speed*=exp(-0.68*dt)
	if absf(speed)<0.4: speed=0
	roll*=exp(-1.05*dt)
	var velocity: Vector2=Vector2(cos(heading),sin(heading))*speed
	var next: Vector2=position+velocity*dt
	# Only current into-surface velocity is stopped; reverse clears stale blocking.
	if bounded and ((next.y<150 and velocity.y<0) or (next.y>365 and velocity.y>0) or (next.x<0 and velocity.x<0)):
		speed=0
		collision_count+=1
		feedback="岸边挡住了船；按住 S 并交替划桨可退出"
	else: position=next
	distance=maxf(distance,position.x)
	if phase in ["travel","chase"] and distance>=goal:
		distance=goal
		status="won"
		return
	if phase=="chase": update_swan(dt)

func update_swan(dt: float) -> void:
	gap=position.distance_to(swan)
	segment="final_bank" if distance/goal>=0.78 else ("mid_channel" if distance/goal>=0.24 else "opening")
	var old: String=pressure
	var after: float=pressure_elapsed+dt
	var ready: bool=elapsed>=4
	var readable: bool=gap>=122 and gap<=384
	if elapsed<1.1: pressure="release_warning"
	elif pressure=="release_warning": pressure="tracking"
	elif pressure=="charge_warning":
		if ready and after>=0.62: pressure="charge"
	elif not ready:
		pressure="charge_warning" if pressure=="tracking" and cycle_index==0 and elapsed>=2.7 and readable else "tracking"
	elif pressure=="charge":
		if after>=0.56: pressure="recovery"
	elif pressure=="recovery":
		if after>=0.76: pressure="tracking"
	elif after>=(0.98 if segment=="final_bank" else (1.58 if segment=="mid_channel" else 1.9)) and readable: pressure="charge_warning"
	pressure_elapsed=0 if old!=pressure else after
	if old=="recovery" and pressure=="tracking": cycle_index+=1
	if pressure=="charge_warning" and old!=pressure: aim_y=position.y
	elif pressure not in ["charge_warning","charge"]: aim_y=lerpf(aim_y,position.y,1-exp(-5.4*dt))
	var profiles: Dictionary={"release_warning":Vector2(90,348),"tracking":Vector2(168,440),"charge_warning":Vector2(142,348),"charge":Vector2(268,500),"recovery":Vector2(132,352)}
	var profile: Vector2=profiles[pressure]
	if segment=="final_bank" and pressure not in ["release_warning","charge_warning"]: profile+=Vector2(18,20) if pressure=="charge" else Vector2(12,14)
	var factor: float=clampf((gap-150)/210,0,1)
	factor=factor*factor*(3-2*factor)
	var target: float=lerpf(profile.x,profile.y,factor)
	var grace: float=clampf(elapsed/4,0,1)
	grace=grace*grace*(3-2*grace)
	swan_speed=lerpf(swan_speed,lerpf(76,target,grace),1-exp(-4.8*dt))
	var sway: float={"release_warning":0.3,"charge_warning":0.08,"charge":0.02,"recovery":0.5,"tracking":1.0}[pressure]
	var pursuit: Vector2=Vector2(position.x,aim_y+sin(elapsed*4.2)*16*sway)
	swan=swan.move_toward(pursuit,swan_speed*dt)
	gap=position.distance_to(swan)
	if elapsed<4 and gap<122:
		swan=position+(swan-position).normalized()*122
		gap=122
	if elapsed>=4 and gap<=104:
		status="lost"
		feedback="天鹅追上了船；抓住预警间隙，交替加速"
	elif pressure=="charge_warning": feedback="天鹅收翅蓄力！保持交替划桨"
	elif pressure=="charge": feedback="天鹅冲刺！不要停下"

func result() -> Dictionary:
	return {"protocol":"kayak-strokes-v1","success":status=="won","phase":phase,"distance":distance,"goal":goal,"stroke_count":inputs.size(),"strokes":strokes.duplicate(),"alternations":alternations,"capsizes":capsizes,"ticks":tick,"inputs":inputs.duplicate(true)}

static func validate_result(value: Dictionary, configuration: Dictionary) -> bool:
	if value.get("protocol")!="kayak-strokes-v1" or value.get("success")!=true or value.get("phase")!=configuration.get("phase"): return false
	if not value.get("inputs") is Array or value.inputs.size()>4096 or not _whole(value.get("ticks")) or value.ticks<0 or value.ticks>72000: return false
	var replay: RefCounted=load("res://scripts/games/kayak_model.gd").new()
	replay.configure(configuration)
	var last: int=0
	for event: Variant in value.inputs:
		if not event is Dictionary or not _whole(event.get("tick")) or event.tick<last or event.tick>value.ticks or event.get("side") not in ["left","right"] or event.get("direction") not in ["forward","reverse"]: return false
		while replay.tick<event.tick and replay.status=="running": replay.step()
		if replay.status!="running": return false
		replay.stroke(event.side,event.direction=="reverse",false)
		last=event.tick
	while replay.tick<value.ticks and replay.status=="running": replay.step()
	return replay.status=="won" and replay.tick==value.ticks and absf(replay.distance-float(value.get("distance",-1)))<0.00001 and replay.strokes==value.get("strokes") and replay.alternations==value.get("alternations")

static func _whole(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value))
