extends RefCounted
## World-local independent poster, tissue, brush, powder and hinged-paper layers.
## Observes accepted controller edges; no events, save fields, items or callbacks.
const Motion=preload("res://scripts/presentation/c3_theater_clue_motion.gd")
const ObjectsScene=preload("res://scenes/theater_clue_objects.tscn")
var bound_state:Dictionary={}
var scene_id:=""
var last_clean:=false
var last_dusted:=false
var poster_ms:=INF
var dust_ms:=INF
var object_scene:Node2D
var mount_pending:=false
var last_context:Dictionary={}
var last_snapshot:Dictionary={}
var owner:WeakRef
var owner_window:WeakRef
var owner_frame:WeakRef

func sync(s:Dictionary,reset:=false)->void:
	var scene:String=str(s.native.get("scene",""))
	var clean:bool=s.theaterHunt.posterCleaned
	var dusted:bool=s.theaterHunt.paperDusted
	if reset or not is_same(s,bound_state) or scene!=scene_id:
		bound_state=s;scene_id=scene;settle();last_clean=clean;last_dusted=dusted
	if scene=="theater_interior" and str(s.native.mode)=="light":
		if clean and not last_clean:poster_ms=0
		if dusted and not last_dusted:dust_ms=0
	last_clean=clean;last_dusted=dusted
	if scene!="theater_interior" or str(s.native.mode)!="light" or reduced(s):settle()
	if poster_ms<INF and s.theaterHunt.phase!="entry_ticket":poster_ms=INF
	if dust_ms<INF and s.theaterHunt.phase!="spotlight_ready":dust_ms=INF

func reduced(s:Dictionary)->bool:return bool(s.native.get("settings",{}).get("reduced_motion",false))
func settle()->void:
	poster_ms=INF;dust_ms=INF
	if not last_snapshot.is_empty():last_snapshot.visible=false
	if is_instance_valid(object_scene):object_scene.retire()
func paper_active()->bool:return dust_ms<Motion.DUST_MS
func _bind_owner(canvas:CanvasItem)->void:
	if owner!=null and owner.get_ref()==canvas:return
	if owner!=null:_detach_owner()
	owner=weakref(canvas);owner_window=weakref(canvas.get_window())
	canvas.visibility_changed.connect(_visibility_changed)
	canvas.tree_exiting.connect(_detach_owner)
	canvas.get_window().focus_exited.connect(settle)
	# Main hosts the world in a SubViewport. Its CanvasItem can remain visible
	# while the containing world_frame is hidden for the phone, so observe the
	# actual presented surface as well as the renderer itself.
	var host:Variant=canvas.get("host_node") if canvas.has_method("_shell_input_blocked") else null
	if is_instance_valid(host) and is_instance_valid(host.get("world_frame")):
		owner_frame=weakref(host.world_frame)
		host.world_frame.visibility_changed.connect(_visibility_changed)
func _visibility_changed()->void:
	if not surface_live():settle()
func _detach_owner()->void:
	if owner!=null and is_instance_valid(owner.get_ref()):
		var canvas:CanvasItem=owner.get_ref()
		if canvas.visibility_changed.is_connected(_visibility_changed):canvas.visibility_changed.disconnect(_visibility_changed)
		if canvas.tree_exiting.is_connected(_detach_owner):canvas.tree_exiting.disconnect(_detach_owner)
	if owner_window!=null and is_instance_valid(owner_window.get_ref()):
		var window:Window=owner_window.get_ref()
		if window.focus_exited.is_connected(settle):window.focus_exited.disconnect(settle)
	if owner_frame!=null and is_instance_valid(owner_frame.get_ref()):
		var frame:CanvasItem=owner_frame.get_ref()
		if frame.visibility_changed.is_connected(_visibility_changed):frame.visibility_changed.disconnect(_visibility_changed)
	owner=null;owner_window=null;owner_frame=null;settle()
	if is_instance_valid(object_scene):object_scene.queue_free()
	object_scene=null;mount_pending=false;last_context={};last_snapshot={}
func surface_live()->bool:
	if owner==null:return true
	var canvas:CanvasItem=owner.get_ref()
	if not is_instance_valid(canvas) or not canvas.is_visible_in_tree():return false
	if owner_frame!=null and (not is_instance_valid(owner_frame.get_ref()) or not owner_frame.get_ref().is_visible_in_tree()):return false
	if DisplayServer.get_name()!="headless" and not canvas.get_window().has_focus():return false
	var host:Variant=canvas.get("host_node") if canvas.has_method("_shell_input_blocked") else null
	return not is_instance_valid(host) or (not is_instance_valid(host.get("modal")) and not is_instance_valid(host.get("phone_document")) and not is_instance_valid(host.get("active_game")))

func tick(delta:float,s:Dictionary)->void:
	sync(s)
	# Visibility/focus signals settle hidden surfaces immediately. A slow frame
	# alone is not cancellation; retain the physical beat on modest hardware.
	if not surface_live() or s.get("ui",{}).get("controlCenterOpen",false):settle();return
	var dt:float=clampf(delta,0,.1)*1000
	poster_ms+=dt;dust_ms+=dt
	if poster_ms>=Motion.POSTER_MS:poster_ms=INF
	if dust_ms>=Motion.DUST_MS:dust_ms=INF

func entries(s:Dictionary,clock_ms:float)->Array:
	if scene_id!="theater_interior" or str(s.native.mode)!="light":return []
	var out:Array=[]
	if s.theaterHunt.phase=="entry_ticket" and (not s.theaterHunt.posterCleaned or poster_ms<INF):
		out.append({"id":"theater_poster_contact","kind":"theater_clue","part":"poster","point":Vector2(282,755),"depth":1603,"ms":poster_ms if s.theaterHunt.posterCleaned else -1.0})
	if paper_active():out.append({"id":"theater_vent_contact","kind":"theater_clue","part":"vent","point":Motion.PAPER,"depth":2100,"ms":dust_ms,"clock_ms":clock_ms})
	return out

func present(canvas:CanvasItem,context:Dictionary,s:Dictionary,clock_ms:float)->void:
	_bind_owner(canvas)
	last_context=context.duplicate()
	last_context.safe_rect=canvas.exploration_safe_rect(true) if canvas.has_method("exploration_safe_rect") else canvas.get_viewport_rect()
	last_snapshot={"visible":scene_id=="theater_interior" and str(s.native.mode)=="light" and surface_live() and not s.get("ui",{}).get("controlCenterOpen",false),
		"poster_visible":s.theaterHunt.phase=="entry_ticket" and (not s.theaterHunt.posterCleaned or poster_ms<INF),
		"poster_ms":poster_ms if s.theaterHunt.posterCleaned else -1.0,
		"paper_visible":paper_active(),"dust_ms":dust_ms,"clock_ms":clock_ms}
	if is_instance_valid(object_scene):object_scene.configure(last_context,last_snapshot)
	elif not mount_pending and bool(last_snapshot.visible):
		# Draw passes may not safely mutate their scene tree. The native children
		# mount once after this pass, then keep their own local transforms/pivots.
		mount_pending=true;_mount_objects.call_deferred(weakref(canvas))

func _mount_objects(candidate:WeakRef)->void:
	mount_pending=false
	var canvas:CanvasItem=candidate.get_ref()
	if owner==null or not is_instance_valid(canvas) or owner.get_ref()!=canvas or not canvas.is_inside_tree():return
	if not is_instance_valid(object_scene):
		object_scene=ObjectsScene.instantiate()
		canvas.add_child(object_scene)
	object_scene.configure(last_context,last_snapshot)
