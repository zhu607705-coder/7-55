extends RefCounted
## Runtime-only proof minted by c3_lake and bound to the actual source-map host.
## Never accepts caller-supplied distances, stroke arrays, or completion dictionaries.
const Pressure=preload("res://scripts/games/qizhen_swan_pressure.gd")
const SwanVisual=preload("res://scripts/ui/qizhen_swan_visual.gd")
const StatusView=preload("res://scripts/ui/kayak_status_view.gd")
const FINISH_X: float=190
const CATCH_DISTANCE: float=104
const GRACE: float=4
var _world: WeakRef
var _state: Dictionary
var _zone: String
var _attempt: int
var _model: RefCounted
var _previous: Vector2
var _motion_remainder: float=0
var status: String="running"
var elapsed: float=0
var start_x: float=0
var swan_x: float=0
var swan_y: float=0
var swan: Vector2:
	get: return Vector2(swan_x,swan_y)
	set(value): swan_x=value.x; swan_y=value.y
var swan_speed: float=0
var actual_gap: float=230
var intensity: float=0
var pressure_state: Dictionary
var pressure_view: Dictionary={}
var last_progress: float=0
var recovery_elapsed: float=0
var recovery_reason: String=""
var telegraph_voice: bool=false
var final_voice: bool=false
var pending_strokes: Array=[]
var _issued_finish: bool=false
var _announced: bool=false
var visual: RefCounted=SwanVisual.new()
var cue_age: float=100
var cue_kind: String="none"
var _content: Dictionary={}

func _init(s: Dictionary={},host: Node=null) -> void:
	if host==null: status="cancelled"; return
	_state=s; _world=weakref(host); _zone=str(s.qizhenLake.zone); _attempt=int(s.qizhenLake.chaseAttempts)
	_model=host.kayak; _previous=host.player
	_motion_remainder=float(_model.remainder)
	reset_chase(host.player)

static func eligible_host(s: Dictionary,host: Node) -> bool:
	return is_instance_valid(host) and host.get_script()!=null and host.get_script().resource_path=="res://scripts/world.gd" and str(host.scene_id)=="qizhen_lake" and str(s.native.get("scene",""))=="qizhen_lake" and s.qizhenLake.active and s.qizhenLake.vehicle=="kayak" and host.kayak!=null and str(host.last_zone)==str(s.qizhenLake.zone)

func same_binding(s: Dictionary,host: Node) -> bool:
	return is_same(s,_state) and _world!=null and _world.get_ref()==host and eligible_host(s,host) and _model==host.kayak and _zone==str(s.qizhenLake.zone) and _attempt==int(s.qizhenLake.chaseAttempts)

func valid(s: Dictionary,host: Node) -> bool:
	return status not in ["cancelled","consumed"] and same_binding(s,host)

func cancel() -> void:
	status="cancelled"
	pending_strokes.clear()

func reset_chase(point: Vector2) -> void:
	start_x=point.x; elapsed=0; actual_gap=230; swan_speed=0; intensity=0; last_progress=0
	pressure_state=Pressure.initial(point.y); pressure_view={}
	telegraph_voice=false; final_voice=false
	swan=Vector2(minf(1672-70,point.x+230),point.y)
	_issued_finish=false

func stroke(s: Dictionary,host: Node,side: String,reverse: bool) -> bool:
	if not valid(s,host) or status!="running" or side not in ["left","right"]: return false
	# A real paddle may expand its rotated body into an adjacent solid. Validate
	# the previous pose before accepting the input, then allow only that bounded
	# physical separation. This cannot authorize a caller's changed/teleported pose.
	if host.player.distance_to(_previous)>0.01 or host.player.distance_to(_model.position)>0.01 or not host.can_stand(host.player):
		cancel()
		return false
	var previous_heading: float=_model.heading
	# Exact source tutorial allowance uses the controller's count before this stroke.
	_model.capsize_allowance=0.0 if s.qizhenLake.boardingTutorialCompleted else maxf(0,0.3-int(s.qizhenLake.boardingStrokeCount)*0.045)
	_model.stroke(side,reverse)
	if host.resolve_kayak_rotation(previous_heading): _previous=host.player
	pending_strokes.append({"side":side,"direction":"reverse" if reverse else "forward"})
	return true

func take_strokes() -> Array:
	var result: Array=pending_strokes
	pending_strokes=[]
	return result

func begin_recovery(reason: String) -> void:
	status="recovering"; recovery_reason=reason; recovery_elapsed=0
	_model.speed=0
	if reason=="swan_caught":
		var host: Node=_world.get_ref()
		swan=host.player+Vector2.from_angle(_model.heading+PI)*CATCH_DISTANCE
		actual_gap=CATCH_DISTANCE; swan_speed=0

func acknowledge_attempt(s: Dictionary) -> void:
	_attempt=int(s.qizhenLake.chaseAttempts)

func _consume_motion_time(delta: float) -> float:
	# The 120 Hz model can consume a fraction carried from the previous frame.
	# Charge only time actually integrated, never its still-pending remainder.
	var remainder: float=float(_model.remainder)
	if not is_finite(delta) or not is_finite(_motion_remainder) or not is_finite(remainder) or _motion_remainder<0 or remainder<0: return -1
	var consumed: float=clampf(delta,0,5)+_motion_remainder-remainder
	if consumed < -0.0000001: return -1
	_motion_remainder=remainder
	return maxf(0,consumed)

func tick(s: Dictionary,host: Node,delta: float) -> Dictionary:
	if not valid(s,host): return {}
	if status=="recovering":
		recovery_elapsed+=maxf(0,delta)
		if recovery_elapsed>=1.04:
			var safe: Dictionary=host.spec.zones[_zone].kayakSpawn
			_model.heading=float(safe.heading)
			# Apply the same full-hull spawn placement as a normal world reload.
			# The dock's authored center alone overlaps its edge by 1.5 source px.
			host.player=host._find_safe(Vector2(float(safe.x),float(safe.y))); _model.position=host.player
			_model.speed=0; _model.roll=0; _model.same_side_streak=0
			_model.last_side=""; _model.last_direction=""; _model.last_stroke=-10; _model.status="running"
			_previous=host.player; status="running"; reset_chase(host.player)
			_motion_remainder=float(_model.remainder)
			return {"restarted":s.qizhenLake.phase=="swan_chase"}
		return {}
	if status!="running": return {}
	if _model.status=="lost":
		begin_recovery("same_side_strokes")
		return {"failure":"same_side_strokes"}
	var point: Vector2=host.player
	var simulated_seconds: float=_consume_motion_time(delta)
	# A discontinuous teleport or out-of-map pose cannot mint an escape receipt.
	if simulated_seconds<0 or not point.is_finite() or not host.can_stand(point) or point.distance_to(_model.position)>0.01 or point.distance_to(_previous)>340*simulated_seconds+2:
		cancel()
		return {"invalid":true}
	_previous=point
	if s.qizhenLake.phase!="swan_chase" or _zone!="channel": return {}
	var dt: float=clampf(delta,0,0.05)
	elapsed+=dt; cue_age+=dt
	var progress: float=maxf(float(s.qizhenLake.chaseDistance),start_x-point.x)
	pressure_view=Pressure.step(pressure_state,{"deltaMs":dt*1000,"elapsedSeconds":elapsed,"actualGap":gap_to(point),"catchDistance":104.0,"nearDistance":150.0,"farDistance":360.0,"catchReady":elapsed>=GRACE,"progressRatio":progress/maxf(1,start_x-FINISH_X),"playerY":point.y})
	pressure_state=pressure_view.state
	var grace: float=clampf(elapsed/GRACE,0,1)
	grace=grace*grace*(3-2*grace)
	swan_speed=lerpf(swan_speed,lerpf(76,pressure_view.targetSpeed,grace),1-exp(-4.8*dt))
	var dx: float=point.x-swan_x
	var dy: float=float(pressure_state.aimY)+sin(elapsed*4.2)*16*float(pressure_view.lateralSwayScale)-swan_y
	var pursuit_distance: float=sqrt(dx*dx+dy*dy)
	if pursuit_distance>0.001:
		var travel: float=minf(pursuit_distance,swan_speed*dt)
		swan_x+=dx/pursuit_distance*travel
		swan_y+=dy/pursuit_distance*travel
	actual_gap=gap_to(point)
	if elapsed<GRACE and actual_gap<CATCH_DISTANCE+18:
		var away_x: float=swan_x-point.x
		var away_y: float=swan_y-point.y
		var length: float=maxf(0.001,sqrt(away_x*away_x+away_y*away_y))
		swan_x=point.x+away_x/length*(CATCH_DISTANCE+18)
		swan_y=point.y+away_y/length*(CATCH_DISTANCE+18)
		actual_gap=CATCH_DISTANCE+18
	intensity=1-clampf((actual_gap-CATCH_DISTANCE)/(360-CATCH_DISTANCE),0,1)
	var result: Dictionary={}
	if not _announced: result.started=true; _announced=true
	if pressure_view.cue!="none":
		cue_kind=pressure_view.cue; cue_age=0
		result.cue=cue_kind
	if progress>=last_progress+20:
		last_progress=progress; result.progress=roundi(progress)
	if point.x<=FINISH_X:
		status="finished"; _issued_finish=true; _model.speed=0
		result.finished=true
	elif elapsed>=GRACE and actual_gap<=CATCH_DISTANCE:
		begin_recovery("swan_caught")
		result.failure="swan_caught"
	return result

func gap_to(point: Vector2) -> float:
	var dx: float=swan_x-point.x
	var dy: float=swan_y-point.y
	return sqrt(dx*dx+dy*dy)

func consume_finish(s: Dictionary,host: Node) -> bool:
	if not valid(s,host) or not _issued_finish or status!="finished" or host.player.x>FINISH_X: return false
	_issued_finish=false; status="consumed"
	return true

func actor_presentation() -> Dictionary:
	if status!="recovering": return {"offset":Vector2.ZERO,"scale":1.0,"alpha":1.0}
	var t: float=clampf(recovery_elapsed/1.04,0,1)
	var factor: float=pow(t/0.375,3) if t<0.375 else (1.0 if t<0.625 else pow((1-t)/0.375,3))
	return {"offset":Vector2(0,10*factor),"scale":lerpf(1,0.82,factor),"alpha":lerpf(1,0.38,factor)}

func draw(canvas: CanvasItem,origin: Vector2,zoom: float,reduced: bool=false) -> void:
	if status in ["cancelled","consumed"]: return
	var host: Node=_world.get_ref()
	if not is_instance_valid(host): return
	draw_status(canvas,host,reduced)
	if _state.qizhenLake.phase!="swan_chase" or _zone!="channel": return
	var heading: float=(host.player-swan).angle()
	var beat: float=0 if reduced else sin(Time.get_ticks_msec()/float(pressure_view.get("wingBeatPeriodMs",138)))*(0.42+intensity*0.78)
	visual.draw(canvas,origin+swan*zoom,zoom,heading,beat,clampf(intensity+float(pressure_view.get("visualIntensityBoost",0)),0,1))
	var duration: float=0.32 if reduced else (0.36 if cue_kind=="surge" else 0.54)
	if cue_age<duration:
		var c: Color=Color("ff785e") if cue_kind=="surge" else (Color("ffd85f") if cue_kind=="final_bank" else Color("dffcff"))
		var t: float=clampf(cue_age/duration,0,1)
		var eased: float=1-pow(1-t,3)
		c.a=0.6 if reduced else 0.88*(1-eased)
		var growth: Vector2=Vector2.ONE*1.18 if reduced else Vector2(lerpf(1,1.9 if cue_kind=="surge" else 1.55,eased),lerpf(1,1.65 if cue_kind=="surge" else 1.38,eased))
		var radii: Vector2=Vector2(66,27) if cue_kind=="final_bank" else Vector2(46,20)
		visual.ellipse(canvas,origin+swan*zoom,radii*zoom*growth,c,(4 if cue_kind=="surge" else 3)*zoom)

func draw_status(canvas: CanvasItem,host: Node,reduced: bool) -> void:
	if _content.is_empty(): _content=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter3-qizhen-lake.content.json"))
	var boarding: Dictionary=_content.boarding
	var tilt: int=roundi(minf(1,absf(_model.roll))*100)
	var critical: bool=not pressure_view.is_empty() and pressure_view.dangerBand=="critical"
	var travel_mode: String=str(boarding.reverseMode if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) else (boarding.reverseCoast if _model.speed < -0.4 else boarding.forwardMode))
	# Controls remain in the existing bottom hint and phone. This panel only
	# carries changing boat/pursuit information, measured in the visible viewport.
	var text: String="%s · %s %d%%%s" % [travel_mode,boarding.tilt,tilt," · "+str(boarding.capsizeWarning) if tilt>=70 else ""]
	var label: String=""
	var progress_text: String=""
	var alpha: float=1
	var risk: float=-1
	var pressured: bool=false
	if _state.qizhenLake.phase=="swan_chase" and not pressure_view.is_empty():
		var chase: Dictionary=_content.chase
		alpha=0.84+sin(Time.get_ticks_msec()/82.0)*0.12 if pressure_state.phase=="charge_warning" and not reduced else 1.0
		label="%s · %s · %s %d" % [chase.phaseLabels[pressure_state.phase],chase.dangerLabels[pressure_view.dangerBand],chase.gapLabel,maxi(0,roundi(actual_gap))]
		var progress: float=clampf((start_x-float(host.player.x))/maxf(1,start_x-FINISH_X),0,1)
		progress_text="%s %d%%" % [chase.segmentLabels[pressure_state.segment],roundi(progress*100)]
		risk=float(pressure_view.riskRatio)
		pressured=pressure_view.dangerBand=="pressured"
	var metrics: Dictionary=StatusView.layout(host.font,host.size,host.hud_display_scale(),float(host.hud_metrics("").header_height),text,label,progress_text)
	StatusView.draw(canvas,host.font,metrics,tilt>=70 or critical,alpha,risk,critical,pressured)
