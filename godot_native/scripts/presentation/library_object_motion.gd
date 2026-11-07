extends RefCounted
## Disposable object feedback from accepted library actions. Never writes state,
## moves a physics body, grants evidence, waits on, or completes a story session.
const CATALOG_MS:=780.0
const SIT_MS:=420.0
const TRANSFER_MS:=1010.0
const REDUCED_MS:=180.0
var bound_state:Dictionary={}
var active:=false
var reduced:=false
var catalog_unlocked:=false
var seated:=false
var staff_ms:=-1.0
var catalog_ms:=-1.0
var sit_ms:=-1.0
var packets:Array=[]
var player_at:=Vector2.ZERO
var sit_from:=Vector2.ZERO
var seat_at:=Vector2(1302,500)
var catalog_screen:=Rect2(624,519,58,36)
var state_ref:WeakRef
var view_ref:WeakRef
var action_listener:Callable
var hide_listener:Callable
var exit_listener:Callable

func sync(state:Dictionary,replaced:=false)->void:
	var here:bool=state.get("native",{}).get("scene","")=="library_interior"
	if replaced or not is_same(state,bound_state) or not here:cancel()
	bound_state=state;active=here
	var puzzle:Dictionary=state.get("ui",{}).get("libraryFinalsPuzzle",{})
	reduced=bool(state.get("native",{}).get("settings",{}).get("reduced_motion",false))
	catalog_unlocked=bool(puzzle.get("catalogUnlocked",false))
	seated=bool(puzzle.get("playerSeated",false))
	var loop:MainLoop=Engine.get_main_loop()
	var owner:Node=(loop as SceneTree).root.get_node_or_null("State") if loop is SceneTree else null
	if active and owner!=null and is_same(owner.get("d"),state):_bind_state(owner)
	else:_disconnect_state()
	if not _visible():cancel()

func set_anchors(actor:Vector2,chair:Vector2,screen:Rect2)->void:
	if actor.is_finite():player_at=actor
	if chair.is_finite():seat_at=chair
	if screen.has_area():catalog_screen=screen

static func gained(before:Dictionary,next:Dictionary,key:String)->bool:
	return not bool(before.get("ui",{}).get("libraryFinalsPuzzle",{}).get(key,false)) and bool(next.get("ui",{}).get("libraryFinalsPuzzle",{}).get(key,false))

static func accepted(action:String,before:Dictionary,next:Dictionary,result:Dictionary)->String:
	if not result.get("handled",false):return ""
	for snapshot:Dictionary in [before,next]:
		if snapshot.get("native",{}).get("scene","")!="library_interior":return ""
		if int(snapshot.get("native",{}).get("chapter",1))!=2:return ""
	match action:
		"lib_front_desk":return "staff"
		"lib_catalog_terminal":return "catalog" if gained(before,next,"catalogUnlocked") else ""
		"lib_sit":return "sit" if gained(before,next,"playerSeated") else ""
		"lib_note":return "note" if gained(before,next,"occupancyNoteCollected") and next.get("items",{}).get("occupancyNote",false) else ""
		"lib_receipt":return "receipt" if gained(before,next,"seatReceiptCollected") and next.get("items",{}).get("seat022Receipt",false) else ""
		"lib_scan":return "proof" if gained(before,next,"nonPersonProofStamped") and next.get("items",{}).get("bagNonPersonProof",false) else ""
	return ""

func observe(action:String,before:Dictionary,next:Dictionary,result:Dictionary)->void:
	if not active or not _visible():return
	var owner:Node=state_ref.get_ref() if state_ref!=null else null
	if state_ref!=null and (not is_instance_valid(owner) or not is_same(owner.get("d"),bound_state)):
		cancel();return
	var kind:=accepted(action,before,next,result)
	match kind:
		"staff":staff_ms=0
		"catalog":catalog_ms=0
		"sit":sit_ms=0;sit_from=player_at
		"note":_packet("occupancyNote",Vector2(1282,422),Color("e7d38f"),0)
		"receipt":_packet("seat022Receipt",Vector2(1400,421),Color("78a9df"),520)
		"proof":_packet("bagNonPersonProof",Vector2(398,624),Color("5ed68d"),810)

func _packet(item:String,at:Vector2,color:Color,delay:float)->void:
	# Physical note/drawer/stamp clocks keep their existing owners. This is only
	# the source scene's small screen-space evidence packet and receiver pulse.
	packets.append({"item":item,"at":at,"color":color,"ageMs":-delay})

func advance(delta:float)->void:
	if not active or not _visible():cancel();return
	if not is_finite(delta) or delta<=0:return
	var ms:=minf(delta,.1)*1000
	if staff_ms>=0:staff_ms=_clock(staff_ms,ms,1300)
	if catalog_ms>=0:catalog_ms=_clock(catalog_ms,ms,CATALOG_MS)
	if sit_ms>=0:sit_ms=_clock(sit_ms,ms,SIT_MS)
	for packet:Dictionary in packets:packet.ageMs+=ms
	packets=packets.filter(func(packet:Dictionary):return float(packet.ageMs)<(REDUCED_MS if reduced else TRANSFER_MS))

func _clock(age:float,ms:float,duration:float)->float:
	var next:=age+ms
	return -1.0 if next>=(REDUCED_MS if reduced else duration) else next

func cancel()->void:
	staff_ms=-1;catalog_ms=-1;sit_ms=-1;packets.clear()

static func _step(value:float)->float:return 0.0 if value<=0 else 1.0
static func _pulse(age:float,half:float)->float:
	var phase:=fposmod(maxf(age,0),half*2)/half
	return phase if phase<=1 else 2-phase

func catalog_pose()->Dictionary:
	var scale_value:=1.0
	var alpha:=1.0
	if catalog_ms>=0 and not reduced:
		var pulse:=_pulse(catalog_ms,130)
		scale_value=lerpf(1,1.8,pulse);alpha=lerpf(1,.35,pulse)
	return {"unlocked":catalog_unlocked,"indicatorScale":scale_value,"indicatorAlpha":alpha,"scanVisible":catalog_ms>=0 and not reduced and catalog_ms<420,"scanY":_step(catalog_ms/420),"scanAlpha":lerpf(.9,.25,_step(catalog_ms/420))}

func actor_pose(anchor:Vector2)->Dictionary:
	# Only the drawn cel moves. Caller retains the actual collision-resolved
	# player, fixed shared body, controller facts and save position.
	if not active or not seated:return {"point":anchor,"facing":"","moving":false}
	var point:Vector2=seat_at
	if sit_ms>=0 and not reduced:point=sit_from.lerp(seat_at,_step(sit_ms/SIT_MS))
	return {"point":point,"facing":"up","moving":sit_ms>=0}

func evidence_poses(context:Dictionary,viewport_size:Vector2,inventory_bounds:=Rect2())->Array:
	var result:Array=[]
	var factor:=minf(viewport_size.x/960,viewport_size.y/540)
	var origin:Vector2=(viewport_size-Vector2(960,540)*factor)/2
	var destination:Vector2=inventory_bounds.get_center() if inventory_bounds.has_area() else origin+Vector2(872,470)*factor
	for packet:Dictionary in packets:
		var age:float=packet.ageMs
		if age<0:continue
		var start:Vector2=Vector2(context.get("origin",Vector2.ZERO))+Vector2(packet.at)*float(context.get("zoom",1))
		var progress:float=clampf(age/(REDUCED_MS if reduced else 650),0,1)
		var stepped:float=progress if reduced else _step(progress)
		result.append({"item":packet.item,"point":destination if reduced else start.lerp(destination,stepped),"destination":destination,"color":packet.color,"rotation":0.0 if reduced else PI/2*stepped,"scale":factor if reduced else factor*lerpf(1,.28,stepped),"alpha":1-progress if reduced else lerpf(1,.2,stepped) if age<650 else 0.0,"receiverAlpha":(1-progress)*.55 if reduced else 1-_pulse(maxf(0,age-610),180) if age>=610 else minf(1,age/180),"receiverScale":1.0 if reduced else 1+_pulse(minf(age,970),180)*.55})
	return result

func draw_catalog(canvas:CanvasItem)->void:
	var pose:=catalog_pose()
	var at:=catalog_screen.position+Vector2(catalog_screen.size.x*.92,-4)
	canvas.draw_circle(at,3*float(pose.indicatorScale),Color("65dca0",pose.indicatorAlpha) if catalog_unlocked else Color("d2aa54"))
	if pose.scanVisible:
		canvas.draw_rect(Rect2(catalog_screen.position+Vector2(0,catalog_screen.size.y*float(pose.scanY)),Vector2(catalog_screen.size.x,2)),Color("65dca0",pose.scanAlpha))

func draw_overlay(canvas:CanvasItem,context:Dictionary,viewport_size:Vector2,inventory_bounds:=Rect2())->void:
	canvas.draw_set_transform(Vector2.ZERO)
	for pose:Dictionary in evidence_poses(context,viewport_size,inventory_bounds):
		var ink:Color=pose.color
		ink.a=pose.receiverAlpha*.3
		canvas.draw_arc(pose.destination,18*pose.receiverScale,0,TAU,24,ink,2)
		if pose.alpha<=0:continue
		canvas.draw_set_transform(pose.point,pose.rotation,Vector2.ONE*float(pose.scale))
		ink.a=pose.alpha;canvas.draw_rect(Rect2(-14,-11,28,22),ink)
		canvas.draw_rect(Rect2(-14,-11,28,22),Color("16201e",pose.alpha),false,2)
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(4,-11),Vector2(14,-11),Vector2(14,-1)]),Color("f4ead1",pose.alpha))
		canvas.draw_line(Vector2(-9,1),Vector2(2,1),Color("27322f",pose.alpha),2)
		canvas.draw_line(Vector2(-9,6),Vector2(7,6),Color("27322f",pose.alpha),2)
	canvas.draw_set_transform(Vector2.ZERO)

static func handoff_pose(age_ms:float,reduced_motion:=false)->Dictionary:
	var duration:=180.0 if reduced_motion else 960.0
	if age_ms<0 or age_ms>=duration:return {"visible":false}
	if reduced_motion:return {"visible":true,"washAlpha":.12*sin(age_ms/180*PI),"bookAlpha":1-age_ms/180,"bookScale":1.0,"bookAngle":0.0}
	var book:float=clampf(age_ms/340,0,1) if age_ms<=620 else 1-clampf((age_ms-620)/340,0,1)
	var wash:float=clampf(age_ms/220,0,1) if age_ms<=580 else 1-clampf((age_ms-580)/220,0,1)
	return {"visible":true,"washAlpha":maxf(0,wash)*.68,"bookAlpha":book,"bookScale":lerpf(.25,1.2,_step(book)),"bookAngle":deg_to_rad(-4)*_step(book)}

static func draw_handoff(canvas:CanvasItem,viewport_size:Vector2,opening_snapshot:Dictionary,reduced_motion:=false)->void:
	# Integrate into the existing controller-issued opening view's ARRIVAL beat.
	# Sampling its clock cannot start/skip/delay the authoritative chapter gate.
	if opening_snapshot.get("phase","")!="arrival":return
	var age:float=float(opening_snapshot.get("beatProgress",0))*(900 if reduced_motion else 1300)
	var pose:=handoff_pose(age,reduced_motion)
	if not pose.visible:return
	var scale_value:=minf(viewport_size.x/960,viewport_size.y/540)
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_rect(Rect2(Vector2.ZERO,viewport_size),Color("f7f2df",pose.washAlpha))
	canvas.draw_set_transform(viewport_size/2+Vector2(0,-110)*scale_value,pose.bookAngle,Vector2.ONE*scale_value*float(pose.bookScale))
	for x:int in [-36,0]:
		canvas.draw_rect(Rect2(x,-29,36,58),Color("ede3c3",pose.bookAlpha))
		canvas.draw_rect(Rect2(x,-29,36,58),Color("3c3025",pose.bookAlpha),false,3)
	canvas.draw_rect(Rect2(-2,-29,4,58),Color("b54b43",pose.bookAlpha))
	canvas.draw_set_transform(Vector2.ZERO)

func _bind_state(owner:Node)->void:
	if state_ref!=null and state_ref.get_ref()==owner:return
	_disconnect_state();state_ref=weakref(owner)
	var receiver:WeakRef=weakref(self)
	action_listener=func(action:String,before:Dictionary,next:Dictionary,result:Dictionary):
		var motion:RefCounted=receiver.get_ref()
		if motion!=null:motion.observe(action,before,next,result)
	owner.connect("action_completed",action_listener)

func _disconnect_state()->void:
	var owner:Node=state_ref.get_ref() if state_ref!=null else null
	if is_instance_valid(owner) and action_listener.is_valid() and owner.is_connected("action_completed",action_listener):owner.disconnect("action_completed",action_listener)
	state_ref=null;action_listener=Callable()

func bind_view(view:CanvasItem)->void:
	if view_ref!=null and view_ref.get_ref()==view:return
	_disconnect_view();view_ref=weakref(view)
	var receiver:WeakRef=weakref(self)
	hide_listener=func():
		var motion:RefCounted=receiver.get_ref()
		if motion!=null and not motion._visible():motion.cancel()
	exit_listener=func():
		var motion:RefCounted=receiver.get_ref()
		if motion!=null:motion.dispose()
	view.visibility_changed.connect(hide_listener);view.tree_exiting.connect(exit_listener)
	if not _visible():cancel()

func _visible()->bool:
	var view:CanvasItem=view_ref.get_ref() if view_ref!=null else null
	return view_ref==null or (is_instance_valid(view) and view.is_inside_tree() and view.is_visible_in_tree())

func _disconnect_view()->void:
	var view:CanvasItem=view_ref.get_ref() if view_ref!=null else null
	if is_instance_valid(view):
		if hide_listener.is_valid() and view.visibility_changed.is_connected(hide_listener):view.visibility_changed.disconnect(hide_listener)
		if exit_listener.is_valid() and view.tree_exiting.is_connected(exit_listener):view.tree_exiting.disconnect(exit_listener)
	view_ref=null;hide_listener=Callable();exit_listener=Callable()

func dispose()->void:
	cancel();active=false;bound_state={};_disconnect_state();_disconnect_view()

func _notification(what:int)->void:
	if what!=NOTIFICATION_PREDELETE:return
	var owner:Node=state_ref.get_ref() if state_ref!=null else null
	if is_instance_valid(owner) and action_listener.is_valid() and owner.is_connected("action_completed",action_listener):owner.disconnect("action_completed",action_listener)
	var view:CanvasItem=view_ref.get_ref() if view_ref!=null else null
	if is_instance_valid(view):
		if hide_listener.is_valid() and view.visibility_changed.is_connected(hide_listener):view.visibility_changed.disconnect(hide_listener)
		if exit_listener.is_valid() and view.tree_exiting.is_connected(exit_listener):view.tree_exiting.disconnect(exit_listener)

func snapshot()->Dictionary:
	return {"active":active,"catalogMs":catalog_ms,"staffMs":staff_ms,"sitMs":sit_ms,"packets":packets.duplicate(true),"stateConnected":state_ref!=null and state_ref.get_ref()!=null}
