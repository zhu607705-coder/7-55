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
const LANE=25.0
var position=START
var velocity=Vector2.ZERO
var completed=0
var integrity=1.0
var clock=0.0
var retries=0
var travelled=0.0
var pulse=0.0
var trail=PackedVector2Array([START])
var receipts: Array=[PackedVector2Array([START])]
var saved_trail=PackedVector2Array([START])

func reset() -> void:
	position=START;velocity=Vector2.ZERO;completed=0;integrity=1;clock=0;retries=0;travelled=0;pulse=0
	trail=PackedVector2Array([START]);saved_trail=trail.duplicate();receipts=[saved_trail.duplicate()]

func start_distance() -> float: return 0.0 if completed==0 else GATE_FRACTIONS[mini(completed-1,9)]*LENGTH
func end_distance() -> float: return GATE_FRACTIONS[mini(completed,9)]*LENGTH
func checkpoint() -> Vector2: return at_distance(start_distance())
func goal() -> Vector2: return at_distance(end_distance())
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
	return 1.0 if completed==10 else float(projection().fraction)

func interference() -> Dictionary:
	if completed not in [3,5,7,8]:return {}
	var d=lerpf(start_distance(),end_distance(),.55)
	var normal=(at_distance(d+1)-at_distance(d-1)).normalized().orthogonal()
	return {"center":at_distance(d)+normal*sin(clock*1.8)*12,"radius":28.0}

func stop() -> void: velocity=Vector2.ZERO

func restore_segment() -> void:
	position=checkpoint();velocity=Vector2.ZERO;integrity=1;travelled=0;retries+=1;pulse=-1
	trail=saved_trail.duplicate()

func advance(delta: float,direction: Vector2,throttle: float,braking: bool=false) -> String:
	# A suspended/slow frame cannot replay stale held input over a long interval.
	if delta<=0 or delta>.2 or completed>=10:stop();return ""
	var dt=minf(delta,.05);clock+=dt;pulse=move_toward(pulse,0,dt*2)
	if direction.is_zero_approx() or throttle<=0:stop();return ""
	var desired=direction.normalized()*(SLOW_SPEED if braking else SPEED)*clampf(throttle,0,1)
	velocity=velocity.move_toward(desired,dt*600)
	var before=position;position+=velocity*dt;travelled+=before.distance_to(position)
	var nearest: Vector2=projection().point
	var off_lane=position.distance_to(nearest)>LANE
	var hazard=interference()
	var rushing=not hazard.is_empty() and position.distance_to(hazard.center)<hazard.radius and velocity.length()>80
	integrity=clampf(integrity+dt*(-2.8 if off_lane else -2.2 if rushing else .65),0,1)
	if integrity<=0:
		restore_segment();return "lost"
	if trail[-1].distance_to(position)>3:trail.append(position)
	if position.distance_to(goal())<13 and travelled>=(end_distance()-start_distance())*.65 and integrity>.35:
		position=goal();trail.append(position);saved_trail=trail.duplicate();receipts.append(saved_trail.duplicate());completed+=1;travelled=0;integrity=1;pulse=1
		return "checkpoint"
	return "warning" if rushing or off_lane else ""
