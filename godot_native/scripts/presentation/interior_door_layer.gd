extends RefCounted
## Source RpgInteriorDoor.ts double-fold motion and source-pixel leaf footprints.
## The layer owns no save facts, departure permission, or chapter completion.
const Metrics=preload("res://scripts/player_metrics.gd")
var worlds: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json"))
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
var spec: Dictionary={}
var transitioning: bool=false
var departure_held:bool=false
var departure_clock_owned:bool=false

func configure(id: String,reduced: bool=false) -> void:
	scene_id=id; progress=0; visual_progress=0; from_progress=0; target_progress=0
	from_visual=0; elapsed_ms=0; sensor_open=false; transitioning=false; departure_held=false; departure_clock_owned=false; source_rects.clear(); texture=null; spec={}
	if id=="canteen_interior":
		spec=worlds.worlds.canteen_interior.constants.CANTEEN_SOUTHEAST_EXIT_DOOR
		opening=bounds(spec.opening)
		for side in ["leftLeafSource","rightLeafSource"]:
			var crop: Dictionary=spec[side]
			source_rects.append(Rect2(crop.x,crop.y,crop.width,crop.height))
		texture=load("res://assets/rpg/interiors/canteen_interior.png")
		duration_ms=120 if reduced else 460
	elif id=="theater_interior":
		opening=Rect2(748,845,176,70)
		source_rects.assign([Rect2(0,0,88,70),Rect2(88,0,88,70)])
		texture=load("res://assets/rpg/interiors/theater_center_exit_closed_v03.png")
		duration_ms=120 if reduced else 520

func restore(state:Dictionary)->void:
	# A new scene/ordinary Continue derives a settled pose from the actual
	# restored actor. No animation timer, door flag or callback enters the save.
	if scene_id!="theater_interior":return
	var p:Dictionary=state.get("native",{}).get("player",{})
	var point:=Vector2(p.get("x",0),p.get("y",0))
	sensor_open=absf(point.x-836)<124 and point.y>776 or _occupied(point)
	progress=1.0 if sensor_open else 0.0;visual_progress=progress
	from_progress=progress;from_visual=progress;target_progress=progress;transitioning=false

func begin_departure(owned_clock:bool=false)->bool:
	if scene_id!="theater_interior":return false
	departure_held=true;departure_clock_owned=owned_clock;sensor_open=true;set_open(true);return true

func cancel_departure()->void:
	departure_held=false;departure_clock_owned=false

func _occupied(point:Vector2)->bool:
	return scene_id=="theater_interior" and Rect2(opening.position.x,opening.end.y-20,opening.size.x,28).intersects(Metrics.foot_rect(point))

func collision_rects()->Array[Rect2]:
	var out:Array[Rect2]=[]
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

func tick(delta: float,state: Dictionary,story_session: RefCounted=null) -> void:
	var id: String=state.get("native",{}).get("scene","")
	if id!=scene_id: configure(id,bool(state.get("native",{}).get("settings",{}).get("reduced_motion",false)))
	if texture==null: return
	var player: Dictionary=state.native.get("player",{})
	var point:=Vector2(player.get("x",0),player.get("y",0))
	var desired: bool=sensor_open
	if scene_id=="canteen_interior":
		var hunt: Dictionary=state.get("canteenHunt",{})
		var allowed: bool=not hunt.get("active",false) or str(hunt.get("phase","")) in PHASES
		desired=allowed and within(point,spec.holdOpenBounds if sensor_open else spec.approachBounds)
		if story_session!=null and story_session.sequence_id=="canteen_escape":
			var lines: Array=story_session.lines
			if not lines.is_empty():
				var last: Dictionary=lines.back()
				desired=story_session.elapsed_ms>=float(last.get("atMs",0))+float(last.get("durationMs",0))+120
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
	var width: float=opening.size.x/2*lerpf(1,0.18,visual_progress)
	return [Rect2(opening.position,Vector2(width,opening.size.y)),Rect2(Vector2(opening.end.x-width,opening.position.y),Vector2(width,opening.size.y))]

func draw_back(canvas: CanvasItem,context: Dictionary,_state: Dictionary) -> void:
	if texture==null or scene_id!="canteen_interior": return
	var zoom: float=context.zoom; var origin: Vector2=context.origin
	canvas.draw_rect(Rect2(origin+opening.position*zoom,opening.size*zoom),Color("111716"))
	var spill:=Rect2(opening.get_center()+Vector2(0,opening.size.y*.18)-opening.size*Vector2(.4,.33),opening.size*Vector2(.8,.66))
	canvas.draw_rect(Rect2(origin+spill.position*zoom,spill.size*zoom),Color("c8e7dc",.12*visual_progress))

func draw_front(canvas: CanvasItem,context: Dictionary,_state: Dictionary) -> void:
	if texture==null: return
	var zoom: float=context.zoom; var origin: Vector2=context.origin
	var rects: Array[Rect2]=leaf_rects()
	for index in range(2):
		var rect: Rect2=rects[index]
		canvas.draw_texture_rect_region(texture,Rect2(origin+rect.position*zoom,rect.size*zoom),source_rects[index],Color(1,1,1,1-visual_progress))
