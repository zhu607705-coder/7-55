extends RefCounted
## Pure geometric clipping for a planar flashlight air-path triangle.
## This does not replace the real light's shadow casting.
## Cache each static box only after its final global transform is set.
const CLIP_EPSILON := 0.000001

static func cache_box(world_transform: Transform3D, half_extents: Vector3) -> Dictionary:
	return {
		"inverse": world_transform.affine_inverse(),
		"transform": world_transform,
		"half": half_extents.abs(),
		# Conservative sphere also supports rotation, scale and shear.
		"center": world_transform.origin,
		"radius": world_transform.basis.x.length()*absf(half_extents.x)
			+world_transform.basis.y.length()*absf(half_extents.y)
			+world_transform.basis.z.length()*absf(half_extents.z),
	}

static func wedge_reach(origin: Vector3, left_ray: Vector3, right_ray: Vector3,
	maximum: float, box: Dictionary, safety_inset: float = 0.012) -> float:
	if maximum <= 0.0:
		return 0.0
	if left_ray.length_squared() < CLIP_EPSILON*CLIP_EPSILON or right_ray.length_squared() < CLIP_EPSILON*CLIP_EPSILON:
		return 0.0
	var world_transform: Transform3D = box["transform"]
	var inverse: Transform3D = box["inverse"]
	var half: Vector3 = box["half"]
	if box.has("center") and box.has("radius"):
		if origin.distance_to(Vector3(box["center"])) > maximum+float(box["radius"])+CLIP_EPSILON:
			return maximum
	var local_origin := inverse*origin
	# An emitter inside (or on) a closed opaque box emits no visible ribbon.
	if absf(local_origin.x)<=half.x+CLIP_EPSILON and absf(local_origin.y)<=half.y+CLIP_EPSILON and absf(local_origin.z)<=half.z+CLIP_EPSILON:
		return 0.0
	var left_end:=inverse*(origin+left_ray.normalized()*maximum)
	var right_end:=inverse*(origin+right_ray.normalized()*maximum)
	# Exact conservative separation tests before allocating any clipped polygon.
	# A triangle wholly outside a box slab cannot intersect that box.
	for axis in 3:
		if minf(local_origin[axis],minf(left_end[axis],right_end[axis]))>half[axis]+CLIP_EPSILON:return maximum
		if maxf(local_origin[axis],maxf(left_end[axis],right_end[axis])) < -half[axis]-CLIP_EPSILON:return maximum
	# The ribbon plane must also cross the OBB. The support radius is exact
	# in box-local space, including rotated and nonuniformly scaled boxes.
	var plane_normal:Vector3=(left_end-local_origin).cross(right_end-local_origin)
	var plane_radius:float=plane_normal.abs().dot(half)
	if absf(plane_normal.dot(local_origin))>plane_radius+CLIP_EPSILON*plane_normal.length():return maximum
	var polygon: Array[Vector3] = [local_origin,left_end,right_end]
	for axis in 3:
		polygon = _clip_plane(polygon,axis,1.0,half[axis]+CLIP_EPSILON)
		if polygon.is_empty(): return maximum
		polygon = _clip_plane(polygon,axis,-1.0,half[axis]+CLIP_EPSILON)
		if polygon.is_empty(): return maximum
	# The intersection polygon lies in the same plane as the emitter.
	# Outside a convex polygon in this plane, the nearest point is on an edge.
	# Convert back before measuring to preserve WORLD metres under nonuniform scale.
	var nearest := maximum
	var previous: Vector3 = world_transform*polygon.back()
	for local_point in polygon:
		var current: Vector3 = world_transform*local_point
		nearest = minf(nearest, _distance_to_segment(origin,previous,current))
		previous = current
	return maxf(0.0,nearest-maxf(0.0,safety_inset))

static func all_boxes_reach(origin: Vector3,left_ray: Vector3,right_ray: Vector3,
	maximum: float,boxes: Array,safety_inset: float=0.012) -> float:
	var reach := maxf(0.0,maximum)
	for box: Dictionary in boxes:
		reach = minf(reach,wedge_reach(origin,left_ray,right_ray,reach,box,safety_inset))
		if reach <= 0.0: break
	return reach

static func _clip_plane(polygon: Array[Vector3],axis: int,sign_value: float,extent: float) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if polygon.is_empty(): return result
	var previous: Vector3 = polygon.back()
	var previous_distance: float = sign_value*previous[axis]-extent
	for current in polygon:
		var current_distance: float = sign_value*current[axis]-extent
		var previous_inside := previous_distance<=0.0
		var current_inside := current_distance<=0.0
		if previous_inside != current_inside:
			# Opposite signs guarantee a nonzero denominator.
			var t := previous_distance/(previous_distance-current_distance)
			result.append(previous.lerp(current,clampf(t,0.0,1.0)))
		if current_inside: result.append(current)
		previous = current
		previous_distance = current_distance
	return result

static func _distance_to_segment(point: Vector3,a: Vector3,b: Vector3) -> float:
	var segment := b-a
	var denominator := segment.length_squared()
	if denominator<=CLIP_EPSILON*CLIP_EPSILON: return point.distance_to(a)
	var t := clampf((point-a).dot(segment)/denominator,0.0,1.0)
	return point.distance_to(a+segment*t)
