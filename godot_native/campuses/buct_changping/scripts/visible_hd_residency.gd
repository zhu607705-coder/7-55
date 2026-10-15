extends Node
## Display-only visible-region residency. Existing factories own all admission/restoration.
const BASE := preload("res://campuses/buct_changping/scripts/registered_hd_region.gd")
const PREFETCH_SOURCE_PX := 48.0
const RETAIN_SOURCE_PX := 96.0
const UPDATE_SECONDS := 0.15
const LOAD_ORDER := ["north_adjacent","west_pair","north_large","north_west_upper"]
var campus: Node2D
var specs: Dictionary = {}
var _busy := false
var _stopped := false
var _cooldown := 0.0
var _retry_after: Dictionary = {}
var _clock := 0.0
var _last_selected: Array[String] = []
var _last_omitted_visible: Array[String] = []

static func install(map: Node2D) -> Node:
	if not is_instance_valid(map) or not map.initialized or not map.is_inside_tree():return null
	var node=load("res://campuses/buct_changping/scripts/visible_hd_residency.gd").new()
	node.name="VisibleHDResidency";node.campus=map;node._configure();map.add_child(node)
	return node

func _configure() -> void:
	_add("north_adjacent",Rect2(630,399,240,240),1,8587240,Callable(self,"_set_north_resident"),func():return [campus.north_hd_region],"enable_north_hd_region")
	_add("west_pair",Rect2(398,399,256,456),2,18203202,Callable(campus,"set_west_hd_resident"),func():return campus.west_hd_regions,"enable_west_hd_regions")
	_add("north_large",Rect2(350,167,384,256),1,9689195,Callable(campus,"set_north_large_hd_resident"),func():return [campus.north_large_hd_region],"enable_north_large_hd_region",[{"id":"west_pair","band":Rect2(398,399,256,24)},{"id":"north_adjacent","band":Rect2(630,399,104,24)}])
	_add("north_west_upper",Rect2(118,167,256,256),1,6204069,Callable(campus,"set_north_west_upper_hd_resident"),func():return [campus.north_west_upper_hd_region],"enable_north_west_upper_hd_region",[{"id":"north_large","band":Rect2(350,167,24,256)}])

func _add(id: String, roi: Rect2, slots: int, bytes: int, toggle: Callable, members: Callable, flag: String, dependencies: Array = []) -> void:
	specs[id]={"id":id,"roi":roi,"slots":slots,"bytes":bytes,"toggle":toggle,"members":members,"flag":flag,"dependencies":dependencies}

# Future seventh registered owner supplies its already-authenticated campus setter and
# member reader. This does not bypass the adapter's source/profile/cap admission.
func register_visual_region(id: String, roi: Rect2, layer_bytes: int, toggle: Callable, members: Callable, dependencies: Array = []) -> bool:
	if not id.is_valid_identifier() or specs.has(id) or not roi.has_area() or not Rect2(Vector2.ZERO,campus.WORLD).encloses(roi):return false
	if layer_bytes<=0 or layer_bytes>BASE.MAX_REGION_LAYER_BYTES or not toggle.is_valid() or not members.is_valid():return false
	for dependency in dependencies:
		if not dependency is Dictionary or not specs.has(dependency.get("id","")) or not dependency.get("band",null) is Rect2:return false
	_add(id,roi,1,layer_bytes,toggle,members,"",dependencies);_cooldown=0.0
	return true

# Symmetric v2 display hook held locally; existing campus loading API stays unchanged.
func _set_north_resident(wanted: bool) -> bool:
	if not wanted:
		if is_instance_valid(campus.north_hd_region):campus.north_hd_region.uninstall()
		campus.north_hd_region=null
		return true
	if is_instance_valid(campus.north_hd_region) and campus.north_hd_region.get_diagnostics().active:return true
	var installed: Node2D=BASE.install(campus,"res://campuses/buct_changping/data/north_hd_region.json")
	if not is_instance_valid(installed):return false
	campus.north_hd_region=installed
	return true

func _members(spec: Dictionary) -> Array:
	var result: Variant=spec.members.call()
	return result if result is Array else []

func _resident(spec: Dictionary) -> bool:
	var members:=_members(spec)
	if members.size()!=spec.slots:return false
	for member in members:
		if not is_instance_valid(member) or not member.has_method("get_diagnostics") or not member.get_diagnostics().get("active",false):return false
	return true

func _enabled(spec: Dictionary) -> bool:
	return spec.flag=="" or campus.get(spec.flag)==true

func _bounds(spec: Dictionary) -> Rect2:
	var bounds: Rect2=spec.roi
	# Keep an already loaded whole HD body until it leaves the retention area,
	# even if its image extends past its owning ground ROI. No body is re-anchored.
	for member in _members(spec):
		if not is_instance_valid(member):continue
		var bodies: Variant=member.get("bodies")
		if not bodies is Dictionary:continue
		for body in bodies.values():
			if is_instance_valid(body):bounds=bounds.merge(Rect2(body.source_anchor+body.body_local_origin,Vector2(body.raw_size)*body.image_scale))
	return bounds

func _visible_source_rect() -> Rect2:
	var inverse: Transform2D=campus.world.get_global_transform_with_canvas().affine_inverse()
	var size:=campus.get_viewport_rect().size
	var result:=Rect2(inverse*Vector2.ZERO,Vector2.ZERO)
	for corner in [Vector2(size.x,0),Vector2(0,size.y),size]:result=result.expand(inverse*corner)
	return result

func _unmanaged_budget() -> Vector2i:
	var managed_ids: Array[int]=[]
	for spec in specs.values():
		for member in _members(spec):
			if is_instance_valid(member):managed_ids.append(member.get_instance_id())
	var total:=Vector2i.ZERO
	for child in campus.world.get_children():
		if child.get_instance_id() in managed_ids or not child.has_method("get_diagnostics"):continue
		var diagnostic: Dictionary=child.get_diagnostics()
		if diagnostic.get("active",false) and diagnostic.has("new_gpu_texture_bytes"):
			total+=Vector2i(1,int(diagnostic.new_gpu_texture_bytes))
	return total

func _closure(id: String, view_prefetch: Rect2, result: Array[String]) -> bool:
	if id in result:return true
	if not specs.has(id) or not _enabled(specs[id]):return false
	# Existing dependencies point only towards earlier accepted lower owners.
	for dependency in specs[id].dependencies:
		if dependency.band.intersects(view_prefetch) and not _closure(dependency.id,view_prefetch,result):return false
	result.append(id);return true

func _plan(view: Rect2) -> Array[String]:
	var prefetch:=view.grow(PREFETCH_SOURCE_PX);var retention:=view.grow(RETAIN_SOURCE_PX)
	var candidates: Array=[];var selected: Array[String]=[]
	_last_omitted_visible.clear()
	for spec in specs.values():
		if not _enabled(spec):continue
		var bounds:=_bounds(spec);var resident:=_resident(spec)
		var visible:=bounds.intersects(view);var near:=bounds.intersects(prefetch)
		if not near and not (resident and bounds.intersects(retention)):continue
		candidates.append({"id":spec.id,"tier":0 if visible else (1 if near else 2),"distance":bounds.get_center().distance_squared_to(view.get_center()),"visible":visible})
	candidates.sort_custom(func(a,b):return a.tier<b.tier if a.tier!=b.tier else a.distance<b.distance)
	var fixed:=_unmanaged_budget()
	for candidate in candidates:
		var proposed: Array[String]=selected.duplicate()
		var admitted:=_closure(candidate.id,prefetch,proposed)
		var count:=fixed.x;var bytes:=fixed.y
		for id in proposed:count+=int(specs[id].slots);bytes+=int(specs[id].bytes)
		if admitted and count<=BASE.MAX_REGIONS and bytes<=BASE.MAX_RESIDENT_REGION_LAYER_BYTES:selected=proposed
		elif candidate.visible:_last_omitted_visible.append(candidate.id)
	return selected

func _process(delta: float) -> void:
	if _stopped or not is_instance_valid(campus) or not campus.initialized or campus.leaving:return
	# Registered regions may gain separately accepted bodies later. Their existing
	# depth owner follows the same unchanged actor feet, never collision geometry.
	if is_instance_valid(campus.visitor):
		for spec in specs.values():
			for member in _members(spec):
				if is_instance_valid(member):member.update_actor_foot(campus.visitor.global_position.y)
	_clock+=delta;_cooldown-=delta
	if _busy or _cooldown>0:return
	_cooldown=UPDATE_SECONDS;_refresh()

func _refresh() -> void:
	_busy=true
	var selected:=_plan(_visible_source_rect());var unloaded:=false
	var release_order: Array=LOAD_ORDER.duplicate();release_order.reverse()
	for id in specs:
		if id not in release_order:release_order.push_front(id)
	for id in release_order:
		var spec: Dictionary=specs[id]
		if id not in selected and not _members(spec).is_empty():
			var has_live:=false
			for member in _members(spec):has_live=has_live or is_instance_valid(member)
			if has_live:spec.toggle.call(false);unloaded=true
	if unloaded:
		# BASE releases materials/strips synchronously; queue_free of whole body
		# owners finishes at frame end before any replacement textures are loaded.
		await get_tree().process_frame
	if _stopped or not is_inside_tree() or not is_instance_valid(campus) or not campus.is_inside_tree():return
	if not campus.initialized or campus.leaving:_busy=false;return
	# Closure order is lower-before-upper. Missing/unapproved assets remain source
	# fallback and cannot consume fabricated slots/bytes or mutate logical roads.
	for id in selected:
		var spec: Dictionary=specs[id]
		if _resident(spec) or float(_retry_after.get(id,0.0))>_clock:continue
		if not spec.toggle.call(true):_retry_after[id]=_clock+1.0
	_last_selected=selected;_busy=false

func _resident_group_ids() -> Array[String]:
	var result: Array[String]=[]
	for id in specs:
		if _resident(specs[id]):result.append(id)
	return result

func get_diagnostics() -> Dictionary:
	return {"automatic_display_residency":true,"prefetch_source_pixels":PREFETCH_SOURCE_PX,"retention_source_pixels":RETAIN_SOURCE_PX,"planned_groups":_last_selected.duplicate(),"resident_groups":_resident_group_ids(),"visible_groups_budget_fallback":_last_omitted_visible.duplicate(),"legacy_wenli":"unmanaged resident; never unloaded here","max_regions":BASE.MAX_REGIONS,"max_region_layer_bytes":BASE.MAX_RESIDENT_REGION_LAYER_BYTES,"independent_body_bytes":"unchanged separate accounting; released/restored with their own registered owner","physics_roads_save_changed":false,"hardware_vram_claim":false}

func _exit_tree() -> void:
	_stopped=true;set_process(false)
	# Existing adapters restore themselves during campus teardown. No peer tree,
	# original collision, authored road, or user-data operation occurs here.
