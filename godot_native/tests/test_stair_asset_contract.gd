extends SceneTree
## Runs the candidate renderer, not a parallel implementation of its animation.
## Requires imported resources in --path. Source files are never modified.
var checks := 0
var failures := 0
var game: Control
var Model: Script
var require_assets := true
var pivot_errors: Dictionary = {}
var rider_errors: Dictionary = {}
var source_pose: Dictionary = {}
var textures_seen: Dictionary = {}
var door_sweep_samples:=0
var door_sweep_hits:=0
var door_wrong_direction_samples:=0

func _initialize() -> void:
	require_assets = true
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func settle() -> bool:
	var deadline: int = Time.get_ticks_msec() + 30000
	while game.busy and Time.get_ticks_msec() < deadline: await process_frame
	check(not game.busy, "runtime animation settles")
	return not game.busy

func descendants(node: Node) -> Array:
	var out: Array = []
	for child in node.get_children():
		out.append(child)
		out.append_array(descendants(child))
	return out

func mesh_box_clearance(mesh:MeshInstance3D,world_point:Vector3)->float:
	var point:Vector3=mesh.to_local(world_point)
	var bounds:AABB=mesh.mesh.get_aabb()
	var nearest:=Vector3(clampf(point.x,bounds.position.x,bounds.end.x),clampf(point.y,bounds.position.y,bounds.end.y),clampf(point.z,bounds.position.z,bounds.end.z))
	return mesh.to_global(nearest).distance_to(world_point)

func boxes_penetrate(a:MeshInstance3D,b:MeshInstance3D)->bool:
	# Separating-axis test on actual imported box geometry. Frame contact within
	# 0.1 mm is not penetration; the original z=0 axis fails by about 60 mm.
	var box_a:AABB=a.mesh.get_aabb();var box_b:AABB=b.mesh.get_aabb()
	var offset:Vector3=b.to_global(box_b.get_center())-a.to_global(box_a.get_center())
	var basis_a:Array=[a.global_basis.x,a.global_basis.y,a.global_basis.z]
	var basis_b:Array=[b.global_basis.x,b.global_basis.y,b.global_basis.z]
	var axes:Array=basis_a.duplicate();axes.append_array(basis_b)
	for va:Vector3 in basis_a:
		for vb:Vector3 in basis_b:axes.append(va.cross(vb))
	for raw:Vector3 in axes:
		if raw.length_squared()<.0000000001:continue
		var axis:Vector3=raw.normalized()
		var radius_a:=0.0;var radius_b:=0.0
		for i in range(3):
			radius_a+=absf(axis.dot(basis_a[i]))*box_a.size[i]*.5
			radius_b+=absf(axis.dot(basis_b[i]))*box_b.size[i]*.5
		if absf(offset.dot(axis))>=radius_a+radius_b-.0001:return false
	return true

func run() -> void:
	root.size = Vector2i(960,540)
	Model = load("res://scripts/games/chapter4_stair_model.gd")
	var Renderer: Script = load("res://scripts/games/chapter4_stairs.gd")
	game = Renderer.new()
	root.add_child(game)
	game.setup({"session":"independent-asset-contract"})
	await process_frame
	if not await settle(): quit(1); return
	game.level_index = 1
	game._load_level()
	await process_frame
	if not await settle(): quit(1); return
	check(game.level.id == "stair_b", "real renderer enters original stair_b")
	check(game.actor is Sprite3D and not game.actor.no_depth_test, "original billboard actor keeps real depth occlusion")
	check(is_equal_approx(game.actor.pixel_size,1.75/128.0), "source actor world size preserved")
	check(game.frames.size() == 25, "all 24 walking frames plus source side idle are present")
	var collider_count := 0
	for node in descendants(game.root3d):
		if node is CollisionObject3D: collider_count += 1
	check(collider_count == 0, "asset renderer introduces no competing collision authority")
	if require_assets and is_instance_valid(game.door_hinge):
		var leaf:MeshInstance3D=game.door_hinge.find_child("b_deco_fire_door_leaf",true,false)
		check(leaf!=null,"actual independent door leaf is available for sweep clearance")
		if leaf!=null:
			check(game.door_group.to_local(leaf.global_position).distance_to(Vector3(0,1.03,0))<.00003,"closed leaf preserves original source position after hinge-axis correction")
			var frame_meshes:Array=[]
			for name in ["Door fixed jamb -1","Door fixed jamb 1","Door fixed lintel"]:
				var frame:MeshInstance3D=game.door_group.find_child(name,true,false)
				check(frame!=null,"actual source frame mesh exists for sweep "+name)
				if frame!=null:frame_meshes.append(frame)
			var waiting_foot:Vector3=game.root3d.to_global(Model.position(game.level,game.state,"B_EXIT"))
			var saved_angle:float=game.door_hinge.rotation.y
			var opening_clearance:=INF
			var reversed_clearance:=INF
			for degrees in range(91):
				game.door_hinge.rotation.y=deg_to_rad(float(degrees))
				for frame:MeshInstance3D in frame_meshes:
					check(not boxes_penetrate(leaf,frame),"actual leaf does not penetrate actual frame at "+str(degrees)+" degrees / "+frame.name)
				opening_clearance=minf(opening_clearance,mesh_box_clearance(leaf,waiting_foot))
				opening_clearance=minf(opening_clearance,mesh_box_clearance(leaf,waiting_foot+Vector3(0,.875,0)))
				game.door_hinge.rotation.y=-deg_to_rad(float(degrees))
				reversed_clearance=minf(reversed_clearance,mesh_box_clearance(leaf,waiting_foot+Vector3(0,.875,0)))
			game.door_hinge.rotation.y=saved_angle
			check(opening_clearance>.20,"actual leaf geometry clears waiting foot/torso throughout outward opening")
			check(reversed_clearance<.01,"negative-control inward opening demonstrably sweeps through waiting actor")
	if require_assets: check(game.has_method("_apply_mechanism_frame"), "runtime exposes source-owned continuous mechanism frame")
	if game.has_method("_apply_mechanism_frame"):
		for definition in game.level.mechanisms:
			for source_value in range(int(definition.stateCount)):
				for delta in [-1,1]:
					game.state.values[definition.id]=source_value
					game.state.node="B_START"
					game._update()
					var stationary_actor: Vector3=game.actor.position
					for t in [0.0,0.125,0.5,0.875,1.0]:
						game._apply_mechanism_frame(definition.id,source_value,delta,t)
						var expected:=Transform3D.IDENTITY
						var value:float=source_value+delta*t
						if definition.kind=="rotate":
							var pivot:Vector3=Model.v3(definition.pivot)
							var basis:=Basis(Vector3.UP,value*PI/2.0)
							expected=Transform3D(basis,pivot-basis*pivot)
						else:
							value=lerpf(float(source_value),float(posmod(source_value+delta,int(definition.stateCount))),t)
							expected.origin[{"x":0,"y":1,"z":2}[definition.axis]]=float(definition.stepSize)*value
						check(game.mechanism_nodes[definition.id].transform.is_equal_approx(expected), "signed quarter-turn or linear shift, including wrap " + definition.id)
						check(game.actor.position.is_equal_approx(stationary_actor), "actor on unrelated static owner stays stationary")
		game.state=Model.initial(game.level)
		game._update()
	# Imported asset surfaces must preserve source position, width, run and rise.
	for stairs in game.level.geometry.stairs:
		var mechanism: Node3D = game.mechanism_nodes[stairs.ownerId]
		var start: Vector3 = Model.v3(stairs.from)
		var finish: Vector3 = Model.v3(stairs.to)
		var flat: Vector3 = finish-start; flat.y=0
		var expected_size := Vector3(flat.length()/int(stairs.steps)+0.07,0.26,float(stairs.width))
		var expected_basis := Basis(Vector3.UP,-atan2(flat.z,flat.x))
		var treads_found := 0
		for index in range(int(stairs.steps)):
			var tread: MeshInstance3D = mechanism.find_child("%s_tread_%02d" % [stairs.id,index],true,false)
			if tread == null: continue
			treads_found += 1
			var relative: Transform3D = mechanism.global_transform.affine_inverse()*tread.global_transform
			var center: Vector3 = start.lerp(finish,(index+0.5)/int(stairs.steps))-Vector3(0,0.13,0)
			check(relative.origin.distance_to(center)<0.00002, "actual imported source tread center " + tread.name)
			check(tread.mesh.get_aabb().size.distance_to(expected_size)<0.00002, "actual imported source tread dimensions " + tread.name)
			check(relative.basis.is_equal_approx(expected_basis), "actual imported tread orientation " + tread.name)
		if require_assets: check(treads_found == int(stairs.steps), "all source treads use the imported " + stairs.ownerId + " asset")
	# Both directions and wrap-around transitions are sampled during the actual tween.
	for definition in game.level.mechanisms:
		var mechanism: Node3D = game.mechanism_nodes[definition.id]
		var node_id: String = {"b_lower_stair":"B_LOWER_HIGH","b_mid_lift":"B_MID_LIFT_LOW","b_upper_stair":"B_UPPER_HIGH","b_exit_slide":"B_EXIT_SLIDE"}[definition.id]
		pivot_errors[definition.id] = 0.0
		rider_errors[definition.id] = 0.0
		for state_index in range(int(definition.stateCount)):
			for delta in [-1,1]:
				game.state.values[definition.id] = state_index
				game.state.node = node_id
				game._update()
				var old_local: Vector3 = mechanism.global_transform.affine_inverse() * (game.actor.global_position-Vector3(0,0.875,0))
				var original_door: Transform3D = game.door_group.global_transform
				var local_pivot: Vector3 = Model.v3(definition.pivot)
				var max_pivot_error := 0.0
				var max_rider_error := 0.0
				var samples := 0
				var deadline: int = Time.get_ticks_msec()+30000
				game._step(definition.id,delta)
				while game.busy and Time.get_ticks_msec()<deadline:
					await process_frame
					if definition.kind == "rotate":
						max_pivot_error=maxf(max_pivot_error,(mechanism.transform*local_pivot).distance_to(local_pivot))
					else:
						var orthogonal: Vector3 = mechanism.position
						orthogonal[{"x":0,"y":1,"z":2}[definition.axis]]=0
						max_pivot_error=maxf(max_pivot_error,orthogonal.length())
					var actual_local: Vector3 = mechanism.global_transform.affine_inverse()*(game.actor.global_position-Vector3(0,0.875,0))
					max_rider_error=maxf(max_rider_error,actual_local.distance_to(old_local))
					check(game.door_group.global_transform.is_equal_approx(original_door), "door remains independent during " + definition.id)
					samples += 1
				check(not game.busy and samples>2, "actual tween sampled and settled " + definition.id)
				check(max_pivot_error<0.0001, "pivot or translation axis invariant " + definition.id + " " + str(state_index) + " delta " + str(delta) + " drift=" + str(max_pivot_error))
				check(max_rider_error<0.0001, "rider remains fixed to its moving owner " + definition.id + " drift=" + str(max_rider_error))
				pivot_errors[definition.id]=maxf(pivot_errors[definition.id],max_pivot_error)
				rider_errors[definition.id]=maxf(rider_errors[definition.id],max_rider_error)
	# Exercise the source action route against actual animation and imported visuals.
	game.state = Model.initial(game.level)
	game.actions_log = []
	game._update()
	var actions: Array = [{"type":"step","id":"b_lower_stair","delta":-1},{"type":"step","id":"b_lower_stair","delta":-1},{"type":"view","value":"south_west"},{"type":"walk","node":"B_MID_LIFT_LOW"},{"type":"step","id":"b_mid_lift","delta":1},{"type":"step","id":"b_mid_lift","delta":1},{"type":"walk","node":"B_UPPER_HIGH"},{"type":"step","id":"b_upper_stair","delta":1},{"type":"view","value":"top_oblique"},{"type":"walk","node":"B_HIGH_ISLAND"},{"type":"step","id":"b_exit_slide","delta":1},{"type":"step","id":"b_exit_slide","delta":1},{"type":"walk","node":"B_EXIT"}]
	for action in actions:
		if action.type=="step": game._step(action.id,action.delta)
		elif action.type=="view": game._change_view(action.value)
		else: game._walk(action.node)
		var deadline: int = Time.get_ticks_msec()+30000
		while game.busy and Time.get_ticks_msec()<deadline:
			await process_frame
			if game.walking and game.actor.texture != null: textures_seen[game.actor.texture.resource_path]=true
			if game.level.id=="stair_b" and game.state.node=="B_EXIT" and game.campaign.is_empty() and is_instance_valid(game.door_hinge):
				var leaf:MeshInstance3D=game.door_hinge.find_child("b_deco_fire_door_leaf",true,false)
				if leaf!=null:
					door_sweep_samples+=1
					if mesh_box_clearance(leaf,game.actor.global_position)<.10:door_sweep_hits+=1
					if game.door_hinge.rotation.y<-.00001:door_wrong_direction_samples+=1
		check(not game.busy, "actual source route animation settles")
		if game.level.id=="stair_b":
			check(game.actor.position.distance_to(Model.position(game.level,game.state,game.state.node)+Vector3(0,0.875,0))<0.0001, "rendered actor reaches actual model node")
	check(game.campaign.size()==1 and game.campaign[0].id=="stair_b", "real route traverses door and writes one source record")
	if game.campaign.size()==1:
		check(game.campaign[0].actions==actions, "recorded actions remain exactly the original thirteen-action solution")
	check(game.level.id=="stair_c", "door hands off to original next authored level")
	check(textures_seen.size()>2, "walking used multiple real source sprite frames")
	if require_assets:
		check(door_sweep_samples>5,"actual door tween and traversal were sampled")
		check(door_sweep_hits==0,"actual door animation does not sweep through waiting/traversing actor")
		check(door_wrong_direction_samples==0,"actual door tween opens away from waiting actor")
	print("LIVE_ASSET_CONTRACT ",JSON.stringify({"checks":checks,"failures":failures,"pivot_errors":pivot_errors,"rider_errors":rider_errors,"walk_textures":textures_seen.keys(),"door_sweep_samples":door_sweep_samples,"door_sweep_hits":door_sweep_hits,"door_wrong_direction_samples":door_wrong_direction_samples}))
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
