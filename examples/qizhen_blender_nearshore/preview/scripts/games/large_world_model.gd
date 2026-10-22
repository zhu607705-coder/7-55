extends RefCounted
const Geo=preload("res://scripts/games/lake_geometry.gd")
const STEP=1.0/120.0
const MAX_SPEED=285.0
# Optional sample route and solid platforms. Defaults retain the full lake contract.
var route_goals: Array[Dictionary]=Geo.goals()
var navigation_check: Callable
var interaction_check: Callable
var position: Vector2=Geo.dock()
var heading: float=PI*.84
var speed: float=0
var elapsed: float=0
var active_time: float=0
var travel: float=0
var progress: int=0
var status: String="running"
var paused: bool=false
var remainder: float=0
var paddle_clock: float=.46
var next_side: String="left"
var strokes: int=0
var collisions: int=0
var damage: int=0
var action_hold: float=0
var feedback: String="从蓝色教学浮码头出发。按 M 查看全湖路线。"
var feedback_age: float=0
var events: Array[Dictionary]=[]
var last_stroke: String=""
var swan: Vector2=Geo.p(803,476)
var swan_origin: Vector2=Geo.p(803,476)
var swan_phase: String="rest"
var swan_timer: float=0
var swan_heading: float=0
var swan_lock: Vector2=Vector2.ZERO
var hit_cooldown: float=0
var completed_at: Array[float]=[]
var inspected: bool=false
var recovered: bool=false
var checkpoint_pos: Vector2=position
var swan_warnings: int=0
var swan_charges: int=0
var steering: float=0
var throttle: bool=false
var brake: bool=false
var interact: bool=false
func reset() -> void:
	position=Geo.dock();heading=PI*.84;speed=0;elapsed=0;active_time=0;travel=0;progress=0;status="running";paused=false;remainder=0;paddle_clock=.46;next_side="left";strokes=0;collisions=0;damage=0;action_hold=0;events.clear();completed_at.clear();inspected=false;recovered=false;swan=swan_origin;swan_phase="rest";swan_timer=0;hit_cooldown=0;feedback_age=0;feedback="从蓝色教学浮码头出发。按 M 查看全湖路线。";steering=0;throttle=false;brake=false;interact=false;last_stroke="";swan_heading=0;swan_lock=Vector2.ZERO;checkpoint_pos=position;swan_warnings=0;swan_charges=0
func input(thrust: bool, turn: float, stop: bool, use: bool) -> void:
	throttle=thrust;steering=clampf(turn,-1,1);brake=stop;interact=use
func step(dt: float) -> void:
	if paused or status!="running":return
	remainder+=clampf(dt,0,.5)
	while remainder>=STEP:
		remainder-=STEP;_tick(STEP)
		if status!="running":break
func _tick(dt: float) -> void:
	elapsed+=dt;feedback_age+=dt;hit_cooldown=maxf(0,hit_cooldown-dt)
	if throttle or absf(steering)>.1 or brake or interact:active_time+=dt
	var candidate_heading: float=wrapf(heading+steering*1.5*dt,-PI,PI)
	# Optional sample solids validate rotation as well as translation.
	if not navigation_check.is_valid() or navigation_check.call(position,candidate_heading):heading=candidate_heading
	paddle_clock+=dt
	if throttle and not brake and paddle_clock>=.46:
		paddle_clock=0;strokes+=1;last_stroke=next_side;next_side="right" if next_side=="left" else "left"
		speed=minf(MAX_SPEED,speed+70)
		events.append({"kind":"stroke","side":last_stroke,"time":elapsed})
	var damping: float=3.9 if brake else .43
	speed=maxf(0,speed*exp(-damping*dt))
	var next: Vector2=position+Vector2.from_angle(heading)*speed*dt
	if Geo.water(next,31) and (not navigation_check.is_valid() or navigation_check.call(next,heading)):
		travel+=position.distance_to(next);position=next
	else:
		if speed>25 and hit_cooldown<=0:
			collisions+=1;hit_cooldown=.7;feedback="擦到岸边。按 S 收桨，再转向开阔水面。";feedback_age=0
		speed*=.15
	_update_swan(dt)
	var goal: Dictionary=route_goals[progress]
	var close: bool=position.distance_to(goal.point)<float(goal.radius)
	if goal.type=="gate":
		if close:_advance_goal()
	elif close:
		var eligible: bool=speed<(45 if goal.type=="dock" else 55)
		if goal.type=="dock":eligible=eligible and absf(angle_difference(heading,-PI/2))<.5 and recovered
		if interaction_check.is_valid():eligible=eligible and interaction_check.call(self,goal)
		if interact and eligible:
			action_hold+=dt
			if action_hold>=1.25:
				if goal.type=="inspect":inspected=true;feedback="发现南端防水袋的信号。沿长岛西侧继续。"
				elif goal.type=="collect":recovered=true;feedback="防水袋已收好。沿岛东侧返航。"
				_advance_goal()
		else:action_hold=maxf(0,action_hold-dt*2)
	else:action_hold=0
func _advance_goal() -> void:
	events.append({"kind":"goal","index":progress,"time":elapsed,"travel":travel});completed_at.append(elapsed)
	checkpoint_pos=position;progress+=1;action_hold=0;feedback_age=0
	if progress>=route_goals.size():
		progress=route_goals.size()-1;status="won";speed=0;feedback="防水袋带回了浮码头。大地图独立路线完成。"
func _update_swan(dt: float) -> void:
	var near: bool=position.distance_to(swan_origin)<980 and progress>=2
	if not near:
		swan_phase="rest";swan_timer=0;swan=swan.move_toward(swan_origin,55*dt);return
	swan_timer+=dt
	if swan_phase=="rest":swan_phase="tracking";swan_timer=0
	if swan_phase=="tracking":
		swan_heading=(position-swan).angle()
		var next: Vector2=swan+Vector2.from_angle(swan_heading)*100*dt
		if Geo.water(next,35):swan=next
		if swan_timer>2.4 and swan.distance_to(position)<650:
			swan_phase="warning";swan_warnings+=1;swan_timer=0;swan_lock=swan;swan_heading=(position-swan).angle();feedback="黑天鹅将沿橙线冲刺。向侧面转弯避开。";feedback_age=0
	elif swan_phase=="warning":
		if swan_timer>1.3:swan_phase="charge";swan_charges+=1;swan_timer=0
	elif swan_phase=="charge":
		var next: Vector2=swan+Vector2.from_angle(swan_heading)*380*dt
		if Geo.water(next,30):swan=next
		if swan_timer>1.1:swan_phase="recover";swan_timer=0
	elif swan_phase=="recover":
		if swan_timer>2.8:swan_phase="tracking";swan_timer=0
	if swan.distance_to(position)<53 and hit_cooldown<=0:
		damage+=1;hit_cooldown=3;speed*=.3;feedback="被撞了一下。保持划行，离开冲刺区域。";feedback_age=0
		if damage>=3:status="lost";feedback="小艇失去平衡。按 R 从头重试。"
func result() -> Dictionary:
	return {"status":status,"elapsed":elapsed,"active_time":active_time,"distance":travel,"strokes":strokes,"collisions":collisions,"damage":damage,"swan_warnings":swan_warnings,"swan_charges":swan_charges,"progress":progress,"inspected":inspected,"recovered":recovered,"completed_at":completed_at,"position":[position.x,position.y]}
