extends RefCounted
## Canteen hinged leaves and source-calibrated theater door motion.
## The layer owns no save facts, departure permission, or chapter completion.
const Metrics=preload("res://scripts/player_metrics.gd")
const CanteenLayout=preload("res://scripts/space/canteen_layout.gd")
const DoorFrames=preload("res://scripts/presentation/c3_door_frames.gd")
const PHASES=["tray_search","drink_mix","menu_order","pickup_search","chase_ready"]
var scene_id: String=""
var opening: Rect2
var progress: float=0
var visual_progress: float=0
var from_progress: float=0
var from_visual: float=0
var target_progress: float=0
var elapsed_ms: float=0
var duration_ms: float=460
var sensor_open: bool=false
var source_rects: Array[Rect2]=[]
var texture: Texture2D
var canteen_closed: Texture2D
var canteen_frame: Texture2D
var canteen_leaves: Texture2D
var canteen_door_scale := 0.0
var canteen_face := Rect2()
var spec: Dictionary={}
var transitioning: bool=false
var departure_held:bool=false
var departure_clock_owned:bool=false

func configure(id: String,reduced: bool=false) -> void:
	scene_id=id; progress=0; visual_progress=0; from_progress=0; target_progress=0
	from_visual=0; elapsed_ms=0; sensor_open=false; transitioning=false; departure_held=false; departure_clock_owned=false; source_rects.clear(); texture=null; spec={};opening=Rect2()
	if id=="canteen_interior":
		spec=CanteenLayout.data().side_exit
		opening=bounds(spec.opening)
		canteen_closed=load(DoorFrames.SOURCE_ASSET)
		canteen_frame=load(DoorFrames.FRAME_ASSET)
		canteen_leaves=load(DoorFrames.LEAVES_ASSET)
		canteen_door_scale=float(spec.frame.width)/DoorFrames.SOURCE_REGION.size.x
		var size:=DoorFrames.SOURCE_REGION.size*canteen_door_scale
		canteen_face=Rect2(opening.get_center().x-size.x/2,float(spec.frame.baseY)-size.y,size.x,size.y)
		duration_ms=120 if reduced else 460
	else:
		canteen_closed=null;canteen_frame=null;canteen_leaves=null;canteen_face=Rect2()
	if id=="theater_interior":
		opening=Rect2(748,845,176,70)
		source_rects.assign([Rect2(0,0,88,70),Rect2(88,0,88,70)])
		texture=load("res://assets/rpg/interiors/theater_center_exit_closed_v03.png")
		duration_ms=120 if reduced else 520

func restore(state:Dictionary)->void:
	# A new scene/ordinary Continue derives a settled pose from the actual
	# restored actor. No animation timer, door flag or callback enters the save.
	if scene_id not in ["canteen_interior","theater_interior"]:return
	var p:Dictionary=state.get("native",{}).get("player",{})
	var point:=Vector2(p.get("x",0),p.get("y",0))
	if scene_id=="canteen_interior":
		sensor_open=str(p.get("scene",scene_id))==scene_id and _canteen_can_open(state) and _canteen_threshold().intersects(Metrics.foot_rect(point))
	else:
		sensor_open=absf(point.x-836)<124 and point.y>776 or _occupied(point)
	progress=1.0 if sensor_open else 0.0;visual_progress=progress
	from_progress=progress;from_visual=progress;target_progress=progress;transitioning=false

func begin_departure(owned_clock:bool=false)->bool:
	if scene_id!="theater_interior":return false
	departure_held=true;departure_clock_owned=owned_clock;sensor_open=true;set_open(true);return true

func cancel_departure()->void:
	departure_held=false;departure_clock_owned=false

func theater_exit_reached(point: Vector2) -> bool:
	if scene_id != "theater_interior" or not passable(): return false
	var feet := Metrics.foot_rect(point, scene_id)
	if feet.get_center().y < opening.end.y: return false
	var leaves := leaf_rects()
	return feet.position.x >= leaves[0].end.x and feet.end.x <= leaves[1].position.x

func _occupied(point:Vector2)->bool:
	return scene_id=="theater_interior" and Rect2(opening.position.x,opening.end.y-20,opening.size.x,28).intersects(Metrics.foot_rect(point))

func collision_rects()->Array[Rect2]:
	var out:Array[Rect2]=[]
	if scene_id=="canteen_interior":
		var threshold:=_canteen_threshold()
		if not passable():
			out.append(threshold)
		else:
			var frame:=DoorFrames.frame_index(visual_progress, true)
			# A pixel of tolerance keeps the foot box off the visible hinge edges.
			var clear_width:=maxf(0.0,DoorFrames.clear_width(frame,canteen_door_scale)-1.0)
			var blocked_width:=(threshold.size.x-clear_width)/2.0
			out.append(Rect2(threshold.position.x,threshold.position.y,blocked_width,threshold.size.y))
			out.append(Rect2(threshold.end.x-blocked_width,threshold.position.y,blocked_width,threshold.size.y))
		return out
	if scene_id!="theater_interior" or progress>=1.0:return out
	# The physical base follows each visible leaf's horizontal extent. A single
	# full-width threshold would allow walking through a partially open leaf.
	for leaf:Rect2 in leaf_rects():out.append(Rect2(leaf.position.x,opening.end.y-12,leaf.size.x,12))
	return out

static func bounds(value: Dictionary) -> Rect2:
	return Rect2(value.left,value.top,value.right-value.left,value.bottom-value.top)

static func within(point: Vector2,value: Dictionary) -> bool:
	return point.x>=value.left and point.x<=value.right and point.y>=value.top and point.y<=value.bottom

func set_open(value: bool) -> void:
	var target: float=1.0 if value else 0.0
	if target_progress==target: return
	from_progress=progress; from_visual=visual_progress; target_progress=target; elapsed_ms=0; transitioning=true

func _canteen_can_open(state: Dictionary) -> bool:
	var hunt: Dictionary=state.get("canteenHunt",{})
	return not hunt.get("active",false) or str(hunt.get("phase","")) in PHASES

func tick(delta: float,state: Dictionary,story_session: RefCounted=null) -> void:
	var id: String=state.get("native",{}).get("scene","")
	if id!=scene_id: configure(id,bool(state.get("native",{}).get("settings",{}).get("reduced_motion",false)))
	if scene_id!="canteen_interior" and texture==null: return
	var player: Dictionary=state.native.get("player",{})
	var point:=Vector2(player.get("x",0),player.get("y",0))
	var desired: bool=sensor_open
	if scene_id=="canteen_interior":
		var allowed:=_canteen_can_open(state)
		desired=allowed and within(point,spec.holdOpenBounds if sensor_open else spec.approachBounds)
		if story_session!=null and story_session.sequence_id=="canteen_escape":
			var lines: Array=story_session.lines
			if not lines.is_empty():
				var last: Dictionary=lines.back()
				desired=story_session.elapsed_ms<float(story_session.spec.delayMs) or story_session.elapsed_ms>=float(last.get("atMs",0))+float(last.get("durationMs",0))+120
		if allowed and passable() and _canteen_threshold().intersects(Metrics.foot_rect(point)):
			desired=true
	else:
		var dx: float=absf(point.x-836)
		if not sensor_open and dx<124 and point.y>776: desired=true
		elif sensor_open and (dx>156 or point.y<746): desired=false
		if departure_held or _occupied(point):desired=true
		if _occupied(point) and target_progress<1.0:
			progress=1.0;visual_progress=1.0;from_progress=1.0;from_visual=1.0;target_progress=1.0;transitioning=false
	sensor_open=desired; set_open(desired)
	if not departure_held or not departure_clock_owned:advance(delta*1000)

func advance(ms: float) -> void:
	if not transitioning: return
	elapsed_ms=minf(duration_ms,elapsed_ms+maxf(0,ms))
	var ratio: float=elapsed_ms/duration_ms
	progress=lerpf(from_progress,target_progress,ratio)
	# Runtime progress is linear; source leaf/spill tweens use Sine.easeInOut.
	visual_progress=lerpf(from_visual,target_progress,(1-cos(PI*ratio))/2)
	if elapsed_ms>=duration_ms: transitioning=false; progress=target_progress; visual_progress=target_progress

func passable() -> bool: return progress>=0.38

func leaf_rects() -> Array[Rect2]:
	var width:=opening.size.x/2*lerpf(1,0.18,visual_progress)
	return [Rect2(opening.position,Vector2(width,opening.size.y)),Rect2(Vector2(opening.end.x-width,opening.position.y),Vector2(width,opening.size.y))]

func _canteen_threshold() -> Rect2:
	return bounds(spec.threshold)

func canteen_pick_rect() -> Rect2:
	return canteen_face.merge(opening)

func draw_canteen_exit(canvas: CanvasItem) -> void:
	if scene_id!="canteen_interior" or canteen_closed==null: return
	var pose:=DoorFrames.sample(visual_progress,passable(),canteen_face.position,canteen_door_scale)
	if pose.closed:
		canvas.draw_texture_rect_region(canteen_closed,canteen_face,DoorFrames.SOURCE_REGION)
		return
	canvas.draw_texture_rect(canteen_frame,canteen_face,false)
	canvas.draw_texture_rect_region(canteen_leaves,pose.rect,pose.source)

func draw_back(canvas: CanvasItem,context: Dictionary,_state: Dictionary) -> void:
	if scene_id!="canteen_interior": return
	canvas.draw_set_transform(context.origin,0,Vector2.ONE*float(context.zoom))
	draw_canteen_exit(canvas)
	canvas.draw_set_transform(Vector2.ZERO)

func draw_front(canvas: CanvasItem,context: Dictionary,_state: Dictionary) -> void:
	if texture==null: return
	var zoom: float=context.zoom; var origin: Vector2=context.origin
	var rects: Array[Rect2]=leaf_rects()
	for index in range(2):
		var rect: Rect2=rects[index]
		canvas.draw_texture_rect_region(texture,Rect2(origin+rect.position*zoom,rect.size*zoom),source_rects[index],Color(1,1,1,1-visual_progress))
