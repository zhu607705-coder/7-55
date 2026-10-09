extends RefCounted
## Read-only presentation math. The rhythm model remains the sole clock and judge.
## Four authored poses: anticipation -> fish thrust -> player pull -> recovery.

static func sample(model: RefCounted, reduced: bool=false) -> Dictionary:
	var rhythm: Vector2 = model.rhythm_position(model.elapsed)
	var beat: int = int(rhythm.x)
	var u: float = rhythm.y
	var fighting: bool = model.stage=="fighting" and model.phase=="running"
	var held: bool = model.controls.has("hook")
	var tension: float = clampf(model.tension/100.0,0,1)
	# Existing model tension is physical load. Press/release does not invent a
	# tension drop; the model must actually relax before the line becomes slack.
	var stress: float = clampf((tension-.15)/.85,0,1)
	var anticipation: float = smoothstep(.52,.95,u) if fighting and beat==0 else 0.0
	var thrust: float = sin(PI*clampf(u/.82,0,1)) if fighting and beat==1 else 0.0
	var pull: float = sin(PI*u) if fighting and beat==2 and held else 0.0
	var recovery: float = 1.0-smoothstep(0,.8,u) if fighting and beat==3 else 0.0
	var tail: float = 0.0
	var bend: float = 0.0
	if fighting:
		if beat==0:
			bend=-.8*anticipation
			tail=.85*anticipation
		elif beat==1:
			# Tail reverses before the mid-body, a thrust instead of whole-sprite wobble.
			bend=-.8*(1.0-smoothstep(0,.22,u))+sin(u*TAU*1.25-.7)*thrust
			tail=.85*(1.0-smoothstep(0,.14,u))+sin(u*TAU*1.75+1.3)*thrust
		elif beat==2:
			bend=-.34*sin(u*PI)
			tail=.36*sin(u*TAU)*sin(u*PI)
		elif beat==3:
			bend=.16*sin(u*TAU)*recovery
			tail=-.22*sin(u*TAU)*recovery
	# Resistance reduces excursion, not the fish's independent thrust cadence.
	bend*=1.0-stress*.42
	tail*=1.0-stress*.38
	var load: float = stress
	var effort: float = pow(stress,1.15) if held else 0.0
	var body_lean: float = -(7+pull*17)*effort+thrust*3*(1-effort) if held else 6*stress
	if not fighting:body_lean=0
	if model.stage=="casting":
		load=clampf(model.cast_power()*.70,0,.70)
		body_lean=-7*load if held else 0.0
	var pose: String = ["anticipation","fish_thrust","player_pull","recovery"][beat] if fighting else "rest"
	if reduced:
		bend=0;tail=0;body_lean=0
	return {"tension":model.tension,"stress":stress,"effort":effort,"held":held,"pose":pose,"beat":beat,"phase":u,"body_bend":bend,"tail_thrust":tail,"load":load,"human_lean":body_lean,"fish_force":thrust,"player_pull":pull,"recovery":recovery,"reduced":reduced}

static func fish_point(uv: Vector2, width: float, motion: Dictionary) -> Vector2:
	# The logical target anchor (source 646,269) and the head stay fixed.
	# Continuous body bend and a stronger tail lever alter the actual silhouette.
	var x: float=uv.x
	var body_weight: float=pow(clampf((646.0/1014.0-x)/(646.0/1014.0),0,1),1.6)
	var tail_weight: float=pow(clampf((.30-x)/.30,0,1),1.2)
	var offset: float=float(motion.body_bend)*width*.08*body_weight+float(motion.tail_thrust)*width*.26*tail_weight
	var taper: float=1.0-.13*absf(float(motion.body_bend))*body_weight
	return Vector2((uv.x*1014.0-646.0)*width/1014.0,(uv.y*465.0-269.0)*width/1014.0*taper+offset)

static func angler_point(uv: Vector2, dimensions: Vector2, motion: Dictionary) -> Vector2:
	# All boat texels begin below y=.60. The lower body/hull are exactly stationary.
	# This is a localized torso lean of the original pose, not a new arm keyframe.
	var weight: float=1.0-smoothstep(.31,.60,uv.y)
	var displacement: float=float(motion.human_lean)*weight*dimensions.x/224.0
	return Vector2((uv.x-.5)*dimensions.x,-dimensions.y+uv.y*dimensions.y)+Vector2(displacement,-absf(displacement)*.10)

static func angler_pose(motion: Dictionary) -> String:
	if motion.is_empty() or str(motion.pose)=="rest":return "rest"
	if not bool(motion.held):return "release" if float(motion.stress)>.10 else "rest"
	return "pull" if float(motion.stress)>=.25 and (int(motion.beat)==2 or float(motion.stress)>=.72) else "rest"

static func rod_points(hand: Vector2, scale: float, lean: float, motion: Dictionary,grip_direction: Vector2=Vector2(.64,-.77)) -> PackedVector2Array:
	var load: float=float(motion.load)
	var end:=hand+Vector2(90+lean*10+load*22,-99+load*67)*scale
	var control1:=hand+grip_direction.normalized()*38*scale
	var control2:=hand+Vector2(55,-125+load*30)*scale
	var points:=PackedVector2Array()
	for i in range(33):
		var u: float=i/32.0
		points.append(hand*pow(1-u,3)+control1*3*pow(1-u,2)*u+control2*3*(1-u)*u*u+end*u*u*u)
	return points

static func line_points(a: Vector2,b: Vector2,motion: Dictionary) -> PackedVector2Array:
	var points:=PackedVector2Array()
	var load: float=float(motion.load)
	var slack: float=(1-load)*(1-load)*62
	var vibration: float=0 if bool(motion.reduced) else sin(float(motion.phase)*TAU*4)*float(motion.fish_force)*load*2.5
	for i in range(33):
		var u: float=i/32.0
		points.append(a.lerp(b,u)+Vector2(sin(u*PI)*vibration,sin(u*PI)*slack))
	return points

static func depth_sample(model: RefCounted, motion: Dictionary) -> Dictionary:
	# Depth is presentation only. A judged miss never counts as retrieval progress.
	var landed: int=0
	for note: Dictionary in model.notes:
		if str(note.get("judgment","")) in ["perfect","great","good"]:landed+=1
	var progress: float=float(landed)/maxi(1,model.notes.size())
	var bite: float=0.0
	if model.cast_at>=0 and model.stage in ["count_in","fighting"]:
		bite=smoothstep(0,maxf(.01,4*model.beat_sec),maxf(0,model.elapsed-model.cast_at))
	var surface: float=clampf(bite*.35+progress*.65,0,1)
	var failed: bool=model.phase=="failed" or (model.phase=="completed" and not bool(model.final_result.get("passed",false)))
	if failed:surface=0.0
	elif model.phase=="completed" and bool(model.final_result.get("passed",false)):surface=1.0
	var strain: float=0.0
	var draw_up: float=0.0
	if model.stage=="fighting" and model.phase=="running" and not bool(motion.reduced):
		# The fish can dive against a loaded line. High tension is not free progress.
		strain=float(motion.fish_force)*float(motion.stress)
		draw_up=float(motion.player_pull)*float(motion.stress)
	return {
		"successful_notes":landed,"progress":progress,"bite":bite,"surface":surface,
		"creature_depth":lerpf(.16,.012,surface)+strain*.012-draw_up*.008,
		"creature_alpha":lerpf(.76,1.0,surface),
		"creature_veil":lerpf(.34,.04,surface),
		"target_veil":lerpf(.28,.10,surface),
		"surface_wake":smoothstep(.55,.92,surface),
		"fish_merge":smoothstep(.42,.92,surface),
		"target_alpha":1.0-smoothstep(.42,.92,surface)
	}
