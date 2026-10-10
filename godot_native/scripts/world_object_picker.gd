extends RefCounted
## Invisible geometry recorded in the same order as the world paint commands.
## A pick never reads item requirements, recipes, selection, or story solutions.
var surfaces: Array=[]
var images: Dictionary={}

static func record(canvas: CanvasItem, ids: Array, geometry: Variant) -> void:
	if not canvas.has_method("register_object_surface"): return
	canvas.call("register_object_surface",ids,{"rect":geometry} if geometry is Rect2 else geometry)

func clear() -> void:
	surfaces.clear()

func add(ids: Array, geometry: Dictionary, painted: bool=true) -> void:
	surfaces.append({"ids":ids,"geometry":geometry,"painted":painted})

func contains(geometry: Dictionary, point: Vector2) -> bool:
	var local: Vector2=Transform2D(geometry.get("transform",Transform2D.IDENTITY)).affine_inverse()*point
	if geometry.has("polygon"):
		return Geometry2D.is_point_in_polygon(local,geometry.polygon)
	if geometry.has("radius"):
		return local.distance_squared_to(geometry.get("center",Vector2.ZERO))<=pow(float(geometry.radius),2)
	var bounds: Rect2=geometry.get("rect",Rect2())
	if not bounds.has_point(local): return false
	var texture: Texture2D=geometry.get("texture")
	if texture==null: return true
	var key: int=texture.get_instance_id()
	if not images.has(key):
		var image: Image=texture.get_image()
		if image!=null and image.is_compressed(): image.decompress()
		images[key]=image
	var pixels: Image=images[key]
	if pixels==null or pixels.is_empty(): return true
	var source: Rect2=geometry.get("source",Rect2(Vector2.ZERO,texture.get_size()))
	var uv: Vector2=(local-bounds.position)/bounds.size
	if geometry.get("flip_h",false): uv.x=1-uv.x
	var sample: Vector2=source.position+uv*source.size
	return pixels.get_pixel(clampi(int(sample.x),0,pixels.get_width()-1),clampi(int(sample.y),0,pixels.get_height()-1)).a>0.05

func pick(point: Vector2, current_targets: Array, inventory_drop: bool=false) -> Dictionary:
	var active: Dictionary={}
	for target: Dictionary in current_targets:
		if not target.get("decorative",false): active[str(target.get("id",""))]=target
	for index in range(surfaces.size()-1,-1,-1):
		var surface: Dictionary=surfaces[index]
		if not contains(surface.geometry,point): continue
		# Multiple actions on one rendered object are supplied in state-owned order.
		# This is independent of the dragged or selected inventory item.
		for id in surface.ids:
			if not active.has(str(id)): continue
			var target: Dictionary=active[str(id)]
			# A visible non-drop object still occludes objects behind it. Filtering
			# eligibility must never make a compatible hidden target win instead.
			if inventory_drop and str(target.get("item","")).is_empty() and target.get("acceptedItems",[]).is_empty(): return {}
			return target
		if surface.painted: return {}
	return {}

func pick_near_visible(point: Vector2,current_targets: Array,inventory_drop: bool,tolerance: float,visible: Rect2,covered: Array=[]) -> Dictionary:
	if not visible.has_point(point) or _covered(point,covered): return {}
	var exact:=pick(point,current_targets)
	if not exact.is_empty(): return _drop_eligible(exact,inventory_drop)
	# Exact painted occlusion wins over tolerance. No item compatibility or
	# puzzle requirement is consulted while choosing the physical object.
	for surface: Dictionary in surfaces:
		if surface.painted and contains(surface.geometry,point): return {}
	for ring in [0.35,0.65,1.0]:
		for index in range(16):
			var sample:Vector2=point+Vector2.from_angle(TAU*index/16)*tolerance*ring
			if not visible.has_point(sample) or _covered(sample,covered): continue
			var candidate:=pick(sample,current_targets)
			if not candidate.is_empty(): return _drop_eligible(candidate,inventory_drop)
	return {}

func _drop_eligible(target: Dictionary,inventory_drop: bool) -> Dictionary:
	if inventory_drop and str(target.get("item","")).is_empty() and target.get("acceptedItems",[]).is_empty(): return {}
	return target

func _covered(point: Vector2,rects: Array) -> bool:
	for rect: Rect2 in rects:
		if rect.has_point(point): return true
	return false
