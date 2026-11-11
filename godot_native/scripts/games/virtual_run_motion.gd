extends RefCounted
## Runtime-only continuous steering. Chapter controller still accepts the final proof.
# The same stadium curve drives lane rendering, checkpoints and collision.
const RADIUS=83.0
const STRAIGHT=130.0
const LENGTH=TAU*RADIUS+2*STRAIGHT
const GATE_FRACTIONS=[.075,.175,.275,.375,.475,.575,.675,.775,.875,1.0]
const START=Vector2(180,328)

static func at_distance(distance: float, radius: float=RADIUS) -> Vector2:
	var d=clampf(distance,0,LENGTH)
	var quarter=PI*RADIUS/2
	if d<=quarter: return Vector2(180,245)+Vector2.from_angle(PI/2+d/RADIUS)*radius
	d-=quarter
	if d<=STRAIGHT: return Vector2(180-radius,245-d)
	d-=STRAIGHT
	if d<=PI*RADIUS: return Vector2(180,115)+Vector2.from_angle(PI+d/RADIUS)*radius
	d-=PI*RADIUS
	if d<=STRAIGHT: return Vector2(180+radius,115+d)
	d-=STRAIGHT
	return Vector2(180,245)+Vector2.from_angle(d/RADIUS)*radius

static func gates() -> Array:
	var result=[]
	for fraction in GATE_FRACTIONS: result.append(at_distance(fraction*LENGTH)/360)
	return result

static func path_between(start: float=0,finish: float=LENGTH,radius: float=RADIUS) -> PackedVector2Array:
	var result=PackedVector2Array()
	var count=maxi(1,ceili((finish-start)/4))
	for i in range(count+1): result.append(at_distance(lerpf(start,finish,float(i)/count),radius))
	return result

const SPEED=126.0
const SLOW_SPEED=58.0
const LANE=13.0
const FIX_RADIUS=10.0
const FIX_SPEED=27.0
const FIX_DWELL={3:.60,5:.70,7:.75,8:.85,9:.85}
const SIGNAL_SPEED_LIMIT := 80.0
const COURSE_KM := 3.0
const SIMULATED_SECONDS_PER_SECOND := 24.0
const PACE_SMOOTHING_SECONDS := .55
var position:=START
var velocity:=Vector2.ZERO
var completed:=0
var integrity=1.0
var clock=0.0
var retries=0
var pulse=0.0
var fix_elapsed=0.0
var active_seconds := 0.0
var verified_segment_distance := 0.0
var furthest_projection := 0.0
var measured_speed := 0.0
var projected_fraction := 0.0
var trail=PackedVector2Array([START])
var receipts: Array=[PackedVector2Array([START])]
var saved_trail=PackedVector2Array([START])

func reset() -> void:
	position=START;velocity=Vector2.ZERO;completed=0;integrity=1;clock=0;retries=0;pulse=0;fix_elapsed=0
	active_seconds=0.0
	_reset_segment_measurements()
	trail=PackedVector2Array([START]);saved_trail=trail.duplicate();receipts=[saved_trail.duplicate()]

func start_distance() -> float: return 0.0 if completed==0 else GATE_FRACTIONS[mini(completed-1,9)]*LENGTH
func end_distance() -> float: return GATE_FRACTIONS[mini(completed,9)]*LENGTH
func checkpoint() -> Vector2: return at_distance(start_distance())
func goal() -> Vector2: return at_distance(end_distance())
func fix_duration() -> float: return float(FIX_DWELL.get(completed,0.0))
func projection() -> Dictionary:
	var path=path_between(start_distance(),end_distance())
	var best=INF
	var nearest=path[0]
	var progress=0.0
	for i in range(path.size()-1):
		var point=Geometry2D.get_closest_point_to_segment(position,path[i],path[i+1])
		var distance=point.distance_squared_to(position)
		if distance<best:
			best=distance;nearest=point
			progress=(i+path[i].distance_to(point)/maxf(.01,path[i].distance_to(path[i+1])))/(path.size()-1)
	return {"point":nearest,"fraction":progress}
func fraction() -> float:
	return 1.0 if completed==10 else projected_fraction

func simulated_seconds() -> float:
	return active_seconds * SIMULATED_SECONDS_PER_SECOND

func distance_km() -> float:
	return (start_distance() + verified_segment_distance) / LENGTH * COURSE_KM

func pace_seconds_per_km(finished: bool) -> float:
	if finished:
		return simulated_seconds() / COURSE_KM
	if measured_speed < 8.0: return 0.0
	return SIMULATED_SECONDS_PER_SECOND * LENGTH / (measured_speed * COURSE_KM)

func interference() -> Dictionary:
	if completed not in [3,5,7,8]:return {}
	var d=lerpf(start_distance(),end_distance(),.55)
	var normal=(at_distance(d+1)-at_distance(d-1)).normalized().orthogonal()
	return {"center":at_distance(d)+normal*sin(clock*1.8)*12,"radius":28.0}

func stop() -> void:
	velocity=Vector2.ZERO

func _reset_segment_measurements() -> void:
	verified_segment_distance=0.0
	furthest_projection=0.0
	projected_fraction=0.0
	measured_speed=0.0

func restore_segment() -> void:
	position=checkpoint();velocity=Vector2.ZERO;integrity=1;retries+=1;pulse=-1
	fix_elapsed=0
	_reset_segment_measurements()
	trail=saved_trail.duplicate()

func advance(delta: float,direction: Vector2,throttle: float,braking: bool=false,gripped: bool=false) -> String:
	# A suspended/slow frame cannot replay stale held input over a long interval.
	if delta<=0 or delta>.2 or completed>=10:stop();fix_elapsed=0;return ""
	var dt=minf(delta,.05);clock+=dt;pulse=move_toward(pulse,0,dt*2)
	var moving := not direction.is_zero_approx() and throttle>0
	var engaged := moving or gripped or braking
	if moving or (engaged and active_seconds > 0.0): active_seconds+=dt
	var segment_length := end_distance()-start_distance()
	var warning := ""
	var accepted_delta := 0.0
	if moving:
		var desired=direction.normalized()*(SLOW_SPEED if braking else SPEED)*clampf(throttle,0,1)
		velocity=velocity.move_toward(desired,dt*600)
		var before: Vector2=position
		position+=velocity*dt
		var fix := projection()
		projected_fraction=fix.fraction
		var along := projected_fraction * segment_length
		var off_lane := position.distance_to(fix.point)>LANE
		var hazard := interference()
		var rushing: bool = not hazard.is_empty() and position.distance_to(hazard.center)<hazard.radius and velocity.length()>SIGNAL_SPEED_LIMIT
		integrity=clampf(integrity+dt*(-4.4 if off_lane else -3.8 if rushing else .65),0,1)
		if integrity<=0:
			restore_segment();return "lost"
		if not off_lane and not rushing:
			# Only new forward movement with a valid fix contributes to pace.
			accepted_delta=minf(maxf(0.0,along-furthest_projection),before.distance_to(position))
			verified_segment_distance+=accepted_delta
			if trail[-1].distance_to(position)>3:trail.append(position)
		furthest_projection=maxf(furthest_projection,along)
		if off_lane: warning="off_lane"
		elif rushing: warning="rushing"
	else:
		stop()
	measured_speed=lerpf(measured_speed,accepted_delta/dt,1.0-exp(-dt/PACE_SMOOTHING_SECONDS)) if engaged else 0.0
	var duration := fix_duration()
	var in_fix := position.distance_to(goal()) < (FIX_RADIUS if duration>0.0 else 13.0)
	if engaged and in_fix and verified_segment_distance<segment_length*.72:
		restore_segment()
		return "lost"
	var reached: bool = in_fix and integrity>.35
	if duration>0.0:
		fix_elapsed = fix_elapsed+dt if reached and (gripped or braking) and velocity.length()<=FIX_SPEED else 0.0
	if reached and (moving or duration>0.0) and fix_elapsed>=duration:
		position=goal();trail.append(position);saved_trail=trail.duplicate();receipts.append(saved_trail.duplicate());completed+=1;integrity=1;pulse=1
		verified_segment_distance=0.0;furthest_projection=0.0;projected_fraction=0.0
		fix_elapsed=0
		return "checkpoint"
	return warning
