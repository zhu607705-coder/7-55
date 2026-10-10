extends RefCounted
## Read-only presentation of the existing controller-owned ticket gate.
const ACTORS="res://assets/rpg/theater/generated/actors/"
static func sample(elapsed_ms: float,admitted: bool,reduced: bool=false) -> Dictionary:
	var pose: Dictionary={"asset":ACTORS+"ticket_inspector_idle_front.png","offset":Vector2.ZERO,"angle":0.0,"accepted":admitted,"check_progress":1.0 if admitted else 0.0,"pulse":0.0}
	if not admitted or not is_finite(elapsed_ms) or elapsed_ms>=9000: return pose
	# Reader starts from the original accepted fact.
	pose.check_progress=1.0 if reduced else clampf(elapsed_ms/260.0,0,1)
	pose.pulse=0.0 if reduced else sin(clampf(elapsed_ms/650.0,0,1)*PI)
	var scan_end: float=160.0 if reduced else 900.0
	if elapsed_ms<scan_end:
		pose.asset=ACTORS+("ticket_inspector_scan_front.png" if reduced or elapsed_ms<350 else "ticket_inspector_scan_side.png")
		return pose
	pose.asset=ACTORS+"ticket_inspector_idle_right.png"
	if reduced: return pose
	var p: float=clampf((elapsed_ms-scan_end)/520.0,0,1)
	if p<1:
		pose.asset=ACTORS+"ticket_inspector_idle_front.png"
		pose.offset=Vector2(0,sin(p*PI)*4)
		pose.angle=sin(p*PI)*3
	return pose
