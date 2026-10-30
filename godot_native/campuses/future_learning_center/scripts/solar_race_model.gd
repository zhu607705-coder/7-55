extends RefCounted
## Deterministic teaching simulation, dimensionless distance, no production state writes.
const DT := 0.05
const TICKS := 600
const PANELS := [{"area":1.0,"mass":0.4}, {"area":1.65,"mass":1.1}]
const TILTS := [0,30,60]
const RATIOS := [1.0,1.6,2.4]
const BASELINE := {"panel":0,"tilt":0,"gear":2}
var setup := BASELINE.duplicate()
var sky := 0
var history: Array[Dictionary] = []
var revision := 0
var run_revision := -1
var ticks := 0
var accumulator := 0.0
var running := false
var complete := false
var earned := false
var outcome := "ready"
var cars := [{"distance":0.0,"speed":0.0}, {"distance":0.0,"speed":0.0}]
var trace: Array[Dictionary] = []
var last_trial: Dictionary = {}
var best := {}

func elapsed() -> float: return ticks*DT
func sun_angle() -> int: return 30 if sky==0 else 60
func intensity_at(time: float) -> float:
	if sky==2: return 0.0
	if sky==1: return 0.15 if time>=10 and time<18 else 0.8
	return 0.2 if time>=10 and time<16 else 1.0
func light_phase() -> String:
	if sky==2: return "遮光试验"
	return "阴影" if intensity_at(elapsed())<0.3 else ("复光" if elapsed()>=16 else "日照")
func configure(key: String, value: int) -> bool:
	var limit: int = {"panel":2,"tilt":3,"gear":3,"sky":3}.get(key,0)
	if value<0 or value>=limit: return false
	if (sky if key=="sky" else int(setup.get(key,-1)))==value: return false
	history.append({"setup":setup.duplicate(),"sky":sky})
	if key=="sky": sky=value
	else: setup[key]=value
	_invalidate(); return true
func undo() -> bool:
	if history.is_empty(): return false
	var previous: Dictionary=history.pop_back(); setup=previous.setup.duplicate(); sky=previous.sky
	_invalidate(); return true
func _invalidate() -> void:
	revision+=1; cancel(); complete=false; outcome="edited"
	if history.size()>32: history.pop_front()
func start() -> bool:
	if running: return false
	ticks=0; accumulator=0; cars=[{"distance":0.0,"speed":0.0},{"distance":0.0,"speed":0.0}]
	trace.clear(); complete=false; running=true; run_revision=revision; outcome="running"
	return true
func pause() -> void:
	if running: running=false; outcome="paused"
func resume() -> bool:
	if outcome!="paused" or run_revision!=revision or ticks>=TICKS: return false
	running=true; outcome="running"; return true
func return_to_start() -> void:
	cancel(); ticks=0; accumulator=0; complete=false; run_revision=-1; outcome="ready"
	cars=[{"distance":0.0,"speed":0.0},{"distance":0.0,"speed":0.0}]; trace.clear()
func step(dt: float) -> void:
	if not running or dt<=0 or not is_finite(dt): return
	if run_revision!=revision: cancel(); return
	accumulator+=dt
	while accumulator+0.000001>=DT and running:
		accumulator-=DT
		_advance(cars[0],setup,intensity_at(elapsed()))
		_advance(cars[1],BASELINE,intensity_at(elapsed()))
		ticks+=1
		if ticks%10==0: trace.append({"time":elapsed(),"player":cars[0].distance,"reference":cars[1].distance})
		if ticks>=TICKS:
			running=false; accumulator=0
			complete=float(cars[0].distance)>float(cars[1].distance)+0.01
			earned=earned or complete; outcome="passed" if complete else "compare"
			last_trial={"setup":setup.duplicate(),"sky":sky,"distance":cars[0].distance,"reference":cars[1].distance,"trace":trace.duplicate(true)}
			best[sky]=maxf(float(best.get(sky,0)),float(cars[0].distance))
func _advance(car: Dictionary, parts: Dictionary, light: float) -> void:
	var panel: Dictionary=PANELS[int(parts.panel)]
	var mass: float=.8+float(panel.mass)
	var ratio: float=RATIOS[int(parts.gear)]
	var alignment: float=maxf(0,cos(deg_to_rad(float(TILTS[int(parts.tilt)]-sun_angle()))))
	var force: float=light*float(panel.area)*alignment*2.4/ratio*maxf(0,1.0-float(car.speed)/(ratio*4.0))
	var drag: float=.08*mass+.012*float(car.speed)*float(car.speed)
	car.speed=maxf(0,float(car.speed)+(force-drag)/mass*DT)
	car.distance=float(car.distance)+float(car.speed)*DT
func cancel() -> void:
	if running or outcome=="paused": outcome="cancelled"
	running=false; accumulator=0
func message() -> String:
	return {"ready":"同样的零件箱、同一束光。改装后，看看 30 秒能跑多远。", "edited":"改装已保存；重新发车才能比较。", "running":"两车同时出发。看起步、阴影与复光时，差距怎样变化。", "compare":"这一轮没有超过基准车。留住轨迹，只改一个地方再试。", "passed":"超过基准车了！换一束侧光，还能保持领先吗？", "cancelled":"试跑已中止；完整跑完 30 秒才记入本次最佳。"}.get(outcome,"")
