extends RefCounted
## Direct fixed-120 Hz port of ChaseStuntModel.ts and ChaseGeometry.ts.
const BEATS = [42,68,94,120,146,172,204,227,250,273,296,319,342,365,394,412,430,448,466,484,502,520,538,556,579,594,609,624,639,654,669,684,699,714,726]
const KINDS = [["bicycle","cone","runner","bicycle"],["runner","crowd","bicycle","cone"],["barrier","cone","barrier","car"],["bicycle","runner","cone","crowd"]]
const HEIGHTS = {"cone":0.65,"barrier":0.95,"bicycle":1.05,"car":1.7,"crowd":2.1,"runner":2.1}
const RAMPS = [[76,0],[245,2],[434,0],[610,2]]
const PICKUPS = [[26,1,"tray"],[151,0,"gust"],[330,2,"tray"],[490,1,"gust"],[680,0,"tray"]]
var status: String = "running"
var distance: float = 0.0
var lane: float = 1.0
var lives: int = 3
var collisions: int = 0
var invulnerable: float = 0.0
var air_height: float = 0.0
var air_velocity: float = 0.0
var charge: float = 0.0
var bell_cooldown: float = 0.0
var bell_pulse: float = 0.0
var boost: float = 0.0
var shield: bool = false
var powerup: String = ""
var combo: int = 0
var best_combo: int = 0
var stunts: int = 0
var score: int = 0
var speed: float = 13.2
var paper_lane: float = 1.0
var paper_gap: float = 27.0
var feedback: String = "起跳越过路障，响铃让纸障让路"
var elapsed: float = 0.0
var tick: int = 0
var held: Dictionary = {}
var cleared: Dictionary = {}
var collected: Dictionary = {}
var crossed: Dictionary = {}
var ramps_crossed: Dictionary = {}
var velocity: float = 0.0
var jump_cooldown: float = 0.0
var remainder: float = 0.0
var airborne_trick: bool = false
var inputs: Array = []
var obstacles: Array = []

func _init() -> void:
	for i: int in range(BEATS.size()):
		var d: int = BEATS[i]
		var open_lane: int = [0,1,2,1][i%4]
		var stage: int = 0 if d<188 else (1 if d<377 else (2 if d<566 else 3))
		var slot: int = 0
		for l: int in range(3):
			if l == open_lane: continue
			obstacles.append({"id":"rush-%d-%d"%[i,l],"distance":d,"lane":l,"kind":KINDS[stage][(i+slot)%4],"side":-1 if l<open_lane else 1})
			slot += 1
	for i: int in range(4):
		for l: int in range(3): obstacles.append({"id":"stunt-hurdle-%d-%d"%[i,l],"distance":[96,274,454,630][i],"lane":l,"kind":"barrier","side":-1 if l==0 else 1})
	obstacles.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.distance < b.distance)

func press(action: String, record: bool = true) -> void:
	if status != "running" or held.has(action): return
	if record: inputs.append({"tick":tick,"type":"press","action":action})
	held[action] = true
	if action == "bell": ring_bell()
	if action == "item": use_item()

func release(action: String, record: bool = true) -> void:
	if not held.has(action): return
	if record: inputs.append({"tick":tick,"type":"release","action":action})
	held.erase(action)
	if action == "jump" and status == "running" and air_height<=0.001 and jump_cooldown<=0:
		air_velocity=5.6+charge*2.4
		jump_cooldown=0.22
		airborne_trick=false
		feedback="蓄力飞跃！" if charge>0.45 else "轻跳"
		charge=0

func neutral(record: bool = true) -> void:
	if record: inputs.append({"tick":tick,"type":"neutral","action":"jump"})
	held.clear()
	charge=0
	velocity=0

func update(delta: float) -> void:
	remainder += clampf(delta,0,5)
	while remainder >= 1.0/120.0 and status == "running":
		step()
		remainder -= 1.0/120.0

func step() -> void:
	if status != "running": return
	var dt: float=1.0/120.0
	tick+=1
	elapsed=tick/120.0
	invulnerable=maxf(0,invulnerable-dt*1000)
	bell_cooldown=maxf(0,bell_cooldown-dt)
	bell_pulse=maxf(0,bell_pulse-dt*1.8)
	jump_cooldown=maxf(0,jump_cooldown-dt)
	boost=maxf(0,boost-dt)
	var axis: float=float(held.has("right"))-float(held.has("left"))
	velocity+=(axis*1.9-velocity)*minf(1,dt*12)
	lane=clampf(lane+velocity*dt,0,2)
	if air_height<=0 and held.has("jump"): charge=clampf(charge+dt*1.5,0,1)
	if air_height>0 or air_velocity>0:
		air_velocity-=11.6*dt
		air_height+=air_velocity*dt
		if air_height<=0:
			air_height=0
			air_velocity=0
			if airborne_trick: reward("稳稳落地",35)
	var target_speed: float=21.5 if boost>0 else 13.2+minf(2.4,combo*0.25)
	speed+=(target_speed-speed)*minf(1,dt*4)
	var before: float=distance
	distance=minf(755,distance+speed*dt)
	for marker: int in [188,377,566]:
		if before<marker and distance>=marker and lives<3:
			lives+=1
			feedback="路边补给 · 恢复一次机会"
	paper_lane=clampf(1+sin(distance*0.029)*0.82+sin(elapsed*1.7)*0.1,0,2)
	paper_gap=maxf(6,27-distance/755*16-minf(4,combo*0.5)-(3 if boost>0 else 0))
	for i: int in range(PICKUPS.size()):
		var p: Array=PICKUPS[i]
		if collected.has(i) or absf(distance-p[0])>1.6 or absf(lane-p[1])>0.35: continue
		collected[i]=true
		if powerup.is_empty():
			powerup=p[2]
			feedback="捡到餐盘护具 · E 使用" if powerup=="tray" else "捡到顺风纸团 · E 使用"
		else: reward("顺手一捞",20)
	for i: int in range(RAMPS.size()):
		var ramp: Array=RAMPS[i]
		if ramps_crossed.has(i) or ramp[0]<before or ramp[0]>distance: continue
		ramps_crossed[i]=true
		if absf(lane-ramp[1])<0.45:
			air_velocity=8.4
			air_height=maxf(0.08,air_height)
			boost=maxf(boost,1.6)
			airborne_trick=true
			stunts+=1
			reward("飞跃捷径！",100)
	for o: Dictionary in obstacles:
		if o.distance<before or o.distance>distance or crossed.has(o.id): continue
		crossed[o.id]=true
		if cleared.has(o.id): continue
		var lateral: float=absf(lane-o.lane)
		if lateral<0.36:
			if air_height>=HEIGHTS[o.kind]:
				cleared[o.id]=true
				airborne_trick=true
				stunts+=1
				reward("飞越路障",65)
			elif invulnerable<=0:
				if shield:
					shield=false
					invulnerable=900
					feedback="餐盘弹开了这次碰撞"
				else:
					lives-=1
					collisions+=1
					combo=0
					speed=8
					invulnerable=1050
					feedback="撞到了！稳住，再追"
					if lives<=0:
						status="lost"
						neutral(false)
						return
		elif lateral<0.68: reward("擦身而过",18)
	if distance>=755:
		status="won"
		neutral(false)

func ring_bell() -> void:
	if bell_cooldown>0:
		feedback="车铃还在回响"
		return
	bell_cooldown=2.6
	bell_pulse=1
	var count: int=0
	for o: Dictionary in obstacles:
		if o.distance>=distance and o.distance<=distance+27 and o.kind in ["cone","bicycle","crowd","runner"] and absf(o.lane-lane)<1.15 and not cleared.has(o.id):
			cleared[o.id]=true
			count+=1
	feedback="叮——借过！" if count>0 else "叮——纸条抖了一下"
	if count>0: reward("车铃开路",count*20)

func use_item() -> void:
	if powerup.is_empty():
		feedback="先捡起路上的道具"
		return
	if powerup=="tray":
		shield=true
		feedback="餐盘护体 · 抵挡一次碰撞"
	else:
		boost=3.2
		feedback="顺风起飞 · 加速追纸！"
	powerup=""

func reward(text: String, points: int) -> void:
	combo+=1
	best_combo=maxi(best_combo,combo)
	score+=points
	feedback=text
	if combo%4==0: boost=maxf(boost,1.2)

func result() -> Dictionary:
	return {"mode":"story","distance":distance,"lives":lives,"collisions":collisions,"protocol":"chase-stunt-v1","ticks":tick,"inputs":inputs.duplicate(true),"score":score,"stunts":stunts,"success":status=="won"}

static func validate_result(value: Dictionary) -> bool:
	if value.get("protocol")!="chase-stunt-v1" or value.get("mode")!="story" or value.get("success")!=true: return false
	if not value.get("inputs") is Array or not _whole(value.get("ticks")): return false
	if value.ticks<1 or value.ticks>18000 or value.inputs.size()>4096: return false
	var replay: RefCounted=load("res://scripts/games/chase_stunt_model.gd").new()
	var last: int=0
	for event: Variant in value.inputs:
		if not event is Dictionary or not _whole(event.get("tick")): return false
		if event.tick<last or event.tick>value.ticks or event.get("action") not in ["left","right","jump","bell","item"] or event.get("type") not in ["press","release","neutral"]: return false
		while replay.tick<event.tick and replay.status=="running": replay.step()
		if replay.status!="running": return false
		if event.type=="press": replay.press(event.action,false)
		elif event.type=="release": replay.release(event.action,false)
		else: replay.neutral(false)
		last=event.tick
	while replay.tick<value.ticks and replay.status=="running": replay.step()
	return replay.status=="won" and replay.tick==value.ticks and value.get("distance")==755 and replay.lives==value.get("lives") and replay.collisions==value.get("collisions") and replay.score==value.get("score") and replay.stunts==value.get("stunts")

static func _whole(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value))
