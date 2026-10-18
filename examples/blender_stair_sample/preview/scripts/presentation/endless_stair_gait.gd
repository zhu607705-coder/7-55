extends Node
## Stair-only presentation rig. Original texture pixels; shared full-body gait phase.
const Pose = preload("res://scripts/presentation/endless_stair_step_pose.gd")
var view
var player_pose: Dictionary = {"active": false}
var guard_pose: Dictionary = {"active": false}
var limbs: Array[MeshInstance3D] = []
var meshes: Array[ImmediateMesh] = []
var guard_cells: Dictionary = {}
var floor_buckets: Dictionary = {}
var upper_nodes: Array[MeshInstance3D] = []
var upper_meshes: Array[ImmediateMesh] = []
var upper_mesh_builds := 0
var pixel_weight_cache: Array[Dictionary] = [{}, {}]
var last_tick := -1
var last_player := Vector2(INF, INF)
var last_guard := Vector2(INF, INF)
var contact_events: Array[Dictionary] = []
var previous_tokens := ["", ""]
var poses_built := 0
var visual_offsets := [0.0, 0.0]
var previous_grounded := [true, true]
var landing_anchors := [-INF, -INF]
var landing_corrections := [0.0, 0.0]
var airborne_offsets := [0.0, 0.0]
var airborne_ticks := [0, 0]
var mesh_keys := [Vector3(INF, INF, INF), Vector3(INF, INF, INF)]

func setup(owner_view) -> void:
	view = owner_view
	floor_buckets = Pose.cache_floors(view.model.geometry.floors)
	for index in 2:
		# Reuse original trouser/shoe pixels on a bent two-link strip.
		# No new character bitmap, palette or outline is painted here.
		var material := StandardMaterial3D.new()
		material.albedo_texture = view.guard_frames.side if index else view.player_frames.side[2]
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.alpha_scissor_threshold = .5
		material.roughness = 1.0
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		var instance := MeshInstance3D.new()
		var mesh := ImmediateMesh.new()
		instance.name = "GuardStairLegs" if index else "PlayerStairLegs"
		instance.mesh = mesh
		instance.material_override = material
		instance.layers = 2
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		view.world.add_child(instance)
		limbs.append(instance)
		meshes.append(mesh)
	for index in 2:
		var material := StandardMaterial3D.new()
		material.albedo_texture = view.guard_frames.side if index else view.player_frames.side[0]
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.alpha_scissor_threshold = .5
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.roughness = 1.0
		var node := MeshInstance3D.new()
		var mesh := ImmediateMesh.new()
		node.name = "GuardStairUpper" if index else "PlayerStairUpper"
		node.mesh = mesh
		node.material_override = material
		node.layers = 2
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		view.world.add_child(node)
		upper_nodes.append(node)
		upper_meshes.append(mesh)
	for direction in view.guard_frames:
		var cells: Array[AtlasTexture] = []
		for frame in 8:
			var cell := AtlasTexture.new()
			cell.atlas = view.guard_frames[direction]
			cell.region = Rect2(frame * 96, 0, 96, 128)
			cells.append(cell)
		guard_cells[direction] = cells

func reset() -> void:
	last_tick = -1
	last_player = Vector2(INF, INF)
	last_guard = Vector2(INF, INF)
	previous_tokens = ["", ""]
	mesh_keys = [Vector3(INF, INF, INF), Vector3(INF, INF, INF)]
	contact_events.clear()
	visual_offsets = [0.0, 0.0]
	previous_grounded = [true, true]
	landing_anchors = [-INF, -INF]
	landing_corrections = [0.0, 0.0]
	airborne_offsets = [0.0, 0.0]
	airborne_ticks = [0, 0]
	player_pose = {"active": false}
	guard_pose = {"active": false}
	for node in limbs: node.visible = false
	for node in upper_nodes: node.visible = false
	view.actor.visible = true
	view.pursuer.visible = true

func prepare() -> void:
	var model = view.model
	# No phase advances on render-only frames, pause or stopped travel.
	if last_tick == model.tick and last_player == model.player and last_guard == model.guard:
		return
	player_pose = Pose.sample(model, model.player.x, model.player.y, model.player_grounded, floor_buckets.get(floori(model.player.x / 1.2), []))
	guard_pose = Pose.sample(model, model.guard.x, model.guard.y, model.guard_grounded, floor_buckets.get(floori(model.guard.x / 1.2), []))
	for index in 2:
		var pose: Dictionary = guard_pose if index else player_pose
		var point: Vector2 = model.guard if index else model.player
		var grounded: bool = model.guard_grounded if index else model.player_grounded
		if grounded:
			var offset: float = float(pose.body_y) - point.y if pose.get("active", false) else 0.0
			if not previous_grounded[index]:
				landing_anchors[index] = point.x
				landing_corrections[index] = -offset
			if is_finite(landing_anchors[index]):
				# Re-enter the distance gait without a landing-time downward pop.
				# Stopping also freezes this blend; no timed foot/body slide.
				var blend := clampf(absf(point.x - landing_anchors[index]) / .50, 0, 1)
				offset += landing_corrections[index] * (1.0 - blend)
				if blend >= 1: landing_anchors[index] = -INF
			visual_offsets[index] = offset
		else:
			if previous_grounded[index]:
				airborne_offsets[index] = visual_offsets[index]
				airborne_ticks[index] = 0
			else: airborne_ticks[index] += maxi(0, model.tick - last_tick)
			var clearance: float = maxf(0, point.y - model.route_surface_height(point.x))
			visual_offsets[index] = maxf(-clearance, airborne_offsets[index] * maxf(0, 1-float(airborne_ticks[index])/8.0))
		previous_grounded[index] = grounded
		pose.body_y = point.y + visual_offsets[index]
		var token: String = pose.get("contact_token", "") if pose.get("active", false) else ""
		if token != previous_tokens[index] and not token.is_empty():
			contact_events.append({"tick": model.tick, "guard": bool(index),
				"token": token, "support_foot": pose.support_foot})
		previous_tokens[index] = token
	last_tick = model.tick
	last_player = model.player
	last_guard = model.guard

func source_frame(guard: bool, fallback: int) -> int:
	var pose: Dictionary = guard_pose if guard else player_pose
	if not pose.get("active", false): return fallback
	# The old eight-cell upper cycle contains two similar back-to-front arm
	# sweeps, not opposite halves. Reusing it would double arm frequency.
	# Preserve source cell 0 and articulate its pixels from the shared phase.
	return 0

func apply(guard: bool, direction: String, frame: int) -> void:
	var index := 1 if guard else 0
	var sprite: Sprite3D = view.pursuer if guard else view.actor
	var pose: Dictionary = guard_pose if guard else player_pose
	sprite.position.y += visual_offsets[index]
	var active: bool = pose.get("active", false) and direction == "side"
	limbs[index].visible = active
	upper_nodes[index].visible = active
	sprite.visible = not active
	if not active:
		mesh_keys[index] = Vector3(INF, INF, INF)
		return
	if guard:
		sprite.texture = guard_cells[direction][frame]
		sprite.hframes = 1
		sprite.frame = 0
	# Crop, never repaint, the old flat-ground legs. Pixel-space hand anchors stay exact.
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 96, 98)
	sprite.offset = Vector2(0, 77)
	var key := Vector3(view.model.guard.x if guard else view.model.player.x, float(pose.body_y), float(frame))
	if mesh_keys[index] != key:
		_build_upper(index, sprite, guard)
		_build_legs(index, sprite, pose, guard)
		mesh_keys[index] = key

func warp_pixel(pixel: Vector2, guard: bool) -> Vector2:
	var pose: Dictionary = guard_pose if guard else player_pose
	if not pose.get("active", false): return pixel
	var phase := float(pose.phase)
	var cycle := (float(pose.support_foot) + phase) * PI
	var lateral: Vector3 = Vector3(-pose.heading.z, 0.0, pose.heading.x)
	var near_foot := 1 if lateral.dot(view.camera.global_basis.z) > 0 else 0
	var exchange := (1.0 + cos(cycle) * (1.0 if near_foot == 1 else -1.0)) * .5
	var point := pixel
	# Near arm counters the near leg ONCE per two-step cycle. The backpack
	# stays attached; only the sleeve/hand zone receives the shoulder rotation.
	var near_shoulder := Vector2(41,66) if not guard else Vector2(36,65)
	var weights := _pixel_weights(pixel, guard)
	var near_weight := weights[0]
	var near_turn := -.43 * exchange
	point += ((pixel-near_shoulder).rotated(near_turn)+near_shoulder-pixel) * near_weight
	# Far arm is the opposing half. Guard's explicit raised-torch gesture
	# still owns its warning overlay; this small base swing never changes it.
	var far_weight := weights[1]
	var far_shoulder := Vector2(53,66) if not guard else Vector2(49,65)
	point += ((pixel-far_shoulder).rotated(.36*exchange)+far_shoulder-pixel) * far_weight
	var transfer := pow(sin(PI*phase),2.0)
	var lean := .060 + .030*transfer
	var pelvis := Vector2(47,93)
	# A small pelvis lead and counter-twist support the step; do not bounce
	# the complete upper sprite up/down as a rigid block.
	point = (point-pelvis).rotated(lean)+pelvis
	point.x += .60*sin(cycle)
	var shoulder_weight := weights[2]
	point.x -= .85*sin(cycle)*shoulder_weight
	var neck := (Vector2(48,55)-pelvis).rotated(lean)+pelvis
	var head_weight := weights[3]
	point += ((point-neck).rotated(-lean*.60)-point+neck)*head_weight
	return point

func _pixel_weights(pixel: Vector2, guard: bool) -> PackedFloat64Array:
	# Original texture-space anatomy is immutable. Do not solve sleeve bands
	# and smooth masks again for every vertex on every simulation tick.
	var cache: Dictionary = pixel_weight_cache[1 if guard else 0]
	if cache.has(pixel): return cache[pixel]
	var near_shoulder := Vector2(41,66) if not guard else Vector2(36,65)
	var near_elbow := Vector2(35,79) if not guard else Vector2(29,80)
	var near_wrist := Vector2(36,91) if not guard else Vector2(30,94)
	var line_a := Geometry2D.get_closest_point_to_segment(pixel, near_shoulder, near_elbow)
	var line_b := Geometry2D.get_closest_point_to_segment(pixel, near_elbow, near_wrist)
	var sleeve_distance := minf(pixel.distance_to(line_a),pixel.distance_to(line_b))
	var near_weight := (1.0-smoothstep(4.2,7.0,sleeve_distance))*smoothstep(64,83,pixel.y)
	var result := PackedFloat64Array([near_weight,
		smoothstep(54,60,pixel.x)*smoothstep(63,76,pixel.y),
		1.0-smoothstep(65,93,pixel.y),1.0-smoothstep(48,61,pixel.y)])
	cache[pixel] = result
	return result

func _build_upper(index:int, sprite:Sprite3D, guard:bool)->void:
	var mesh := upper_meshes[index]
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var xs := [0.0,24.0,30.0,36.0,42.0,46.0,50.0,57.0,64.0,96.0]
	var ys := [0.0,40.0,54.0,64.0,74.0,84.0,91.0,93.0,98.0]
	var points:Array[Vector3]=[]
	for y:float in ys:
		for x:float in xs: points.append(view._sprite_socket(sprite,Vector2(x,y)))
	for row in ys.size()-1:
		for column in xs.size()-1:
			var a:=row*xs.size()+column
			var b:=a+1
			var c:=b+xs.size()
			var d:=a+xs.size()
			var indices:=[a,b,c,a,c,d]
			mesh.surface_set_normal(view.camera.global_basis.z)
			for vertex in indices:
				var uv:=Vector2(xs[vertex%xs.size()],ys[vertex/xs.size()])
				uv/=Vector2(768 if guard else 96,128)
				mesh.surface_set_uv(uv)
				mesh.surface_add_vertex(points[vertex])
	mesh.surface_end()
	upper_mesh_builds+=1

func _build_legs(index: int, sprite: Sprite3D, pose: Dictionary, guard: bool) -> void:
	var mesh := meshes[index]
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var forward: Vector3 = pose.heading
	var right: Vector3 = view.camera.global_basis.x
	var depth: Vector3 = view.camera.global_basis.z
	var hip: Vector3 = view._sprite_socket(sprite, Vector2(46, 93))
	for leg in [1 - int(pose.support_foot), int(pose.support_foot)]:
		var layer: Vector3 = Vector3(-forward.z, 0, forward.x) * (.008 if leg == int(pose.support_foot) else -.008)
		var root: Vector3 = hip + right * (-.030 if leg else .030) + layer
		var foot: Vector3 = pose.feet[leg]
		var ankle := foot + Vector3.UP * .085 + layer
		var difference := ankle - root
		var distance := difference.length()
		var axis := difference.normalized()
		var bend := forward - axis * forward.dot(axis)
		if bend.length_squared() < .001: bend = right
		bend = bend.normalized()
		var length := maxf(.230, distance * .505)
		var knee := (root + ankle) * .5 + bend * sqrt(maxf(.0001, length * length - distance * distance * .25))
		# A shared knee cross section and original edge pixels keep the silhouette
		# continuous. Widths match the existing 13–15 px trouser volume.
		var top_side := depth.cross(knee-root).normalized() * .105
		var knee_side := depth.cross(ankle-root).normalized() * .102
		var end_side := depth.cross(ankle-knee).normalized() * .095
		var u0 := 42.0; var u1 := 56.0; var um0 := 39.0; var um1 := 54.0; var ul0 := 33.0; var ul1 := 50.0
		if guard:
			u0=39;u1=55;um0=37;um1=53;ul0=36;ul1=53
		_tex_quad(mesh,root-top_side,knee-knee_side,knee+knee_side,root+top_side,
			Vector2(u0,93),Vector2(um0,105),Vector2(um1,105),Vector2(u1,93),guard,depth)
		_tex_quad(mesh,knee-knee_side,ankle-end_side,ankle+end_side,knee+knee_side,
			Vector2(um0,105),Vector2(ul0,118),Vector2(ul1,118),Vector2(um1,105),guard,depth)
		var heel := foot - forward * .10 + layer
		var toe := foot + forward * .10 + layer
		_tex_quad(mesh,heel,toe,toe+Vector3.UP*.13,heel+Vector3.UP*.13,
			Vector2(31,126),Vector2(57,126),Vector2(57,116),Vector2(31,116),guard,depth)
	mesh.surface_end()
	poses_built += 1

func _tex_quad(mesh:ImmediateMesh,a:Vector3,b:Vector3,c:Vector3,d:Vector3,
		ua:Vector2,ub:Vector2,uc:Vector2,ud:Vector2,guard:bool,normal:Vector3)->void:
	mesh.surface_set_normal(normal)
	var points: Array[Vector3] = [a,b,c,a,c,d]
	var uvs: Array[Vector2] = [ua,ub,uc,ua,uc,ud]
	for i in 6:
		var uv:Vector2=uvs[i]
		if guard: uv.x+=384
		uv/=Vector2(768 if guard else 96,128)
		mesh.surface_set_uv(uv)
		mesh.surface_add_vertex(points[i])
