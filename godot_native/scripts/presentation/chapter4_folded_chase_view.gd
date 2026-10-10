extends Control
## Reconstructed standalone preview. No campaign state or save writes.
signal finished(result: Dictionary)
signal exited
const Model = preload("res://scripts/games/chapter4_folded_chase_model.gd")
const JUMP_PATH = "res://assets/native/chapter4_side_chase/player_jump_atlas.png"
const JUMP_ROOTS = [Vector2(284,686),Vector2(252,657.25),Vector2(280,615.25),Vector2(242,681)]
var model = Model.new()
var surface: SubViewportContainer
var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var actor: Sprite3D
var pursuer: Sprite3D
var torch: SpotLight3D
var torch_case: MeshInstance3D
var actor_fill: SpotLight3D
var phone_hand_fill: OmniLight3D
var guard_hand_world := Vector3.ZERO
var player_hand_world := Vector3.ZERO
var phone: Node3D
var phone_screen: MeshInstance3D
var torch_lens: MeshInstance3D
var torch_path: MeshInstance3D
var light_occluders: Array[MeshInstance3D] = []
var beam_ray_lengths: Array[float] = []
var beam_origin := Vector3.ZERO
var torch_path_vertex_count := 0
var menu: PanelContainer
var instruction: Label
var start_button: Button
var active := false
var focus_paused := false
var queued_jump := false
var primary_touch := -99
var touch_origin := Vector2.ZERO
var touch_point := Vector2.ZERO
var touch_started := 0
var touch_axis := 0
var swipe_used := false
var held_screen_axis := 0
var held_route_direction := 0
var retained_heading := Vector3.RIGHT
var guard_heading := Vector3.RIGHT
var follow_center := Vector3(-6,3.4,-1.3)
var player_frames: Dictionary = {}
var guard_frames: Dictionary = {}
var jump_frames: Array[AtlasTexture] = []
var jump_ticks := 0
var land_ticks := 0
var groups: Array[Node3D] = []
var materials: Dictionary = {}
var build_group: Node3D
var mesh_cache: Dictionary = {}
var textures: Dictionary = {}
var solid_count := 0
var view_rect := Rect2()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_art()
	_load_materials()
	_build_stage()
	_build_ui()
	resized.connect(_fit)
	get_window().focus_exited.connect(_lose_focus)
	_fit()
	_show_menu("北教楼梯间 · 恢复开发预览\nA/D 或 ←→ 移动，Space 跳跃\n触屏：按左右侧移动，上滑或第二指点跳\n按住会顺梯转角；松开即停，再按按画面选方向\n小阶可跑上，断阶和挡物需要跳\n原跳跃四姿态图暂缺，当前使用原角色全帧", "开始")
	_present(0.0)

func _texture(path: String) -> Texture2D:
	# Normal imported/exported assets must use ResourceLoader, not raw PNG bytes.
	if ResourceLoader.exists(path) and (FileAccess.file_exists(path+".import") or not OS.has_feature("editor")):
		return load(path) as Texture2D
	# The lightweight diagnostic harness can run before the first editor import.
	if FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null and not image.is_empty():
			return ImageTexture.create_from_image(image)
	return null

func _load_art() -> void:
	for direction in ["up","down","side"]:
		var frames: Array[Texture2D] = []
		for index in 8:
			frames.append(_texture("res://assets/rpg/player/player_%s_%d.png" % [direction,index]))
		player_frames[direction] = frames
		var suffix: String = "" if direction == "side" else "_" + direction
		guard_frames[direction] = _texture("res://assets/rpg/npcs/finale/guard_walk%s_8frame.png" % suffix)
	player_frames["idle"] = _texture("res://assets/rpg/player/player_side_idle.png")
	var atlas := _texture(JUMP_PATH)
	if atlas != null and atlas.get_size() == Vector2(1086,1448):
		for index in 4:
			var region := AtlasTexture.new()
			region.atlas = atlas
			region.region = Rect2((index % 2)*543,(index >> 1)*724,543,724)
			jump_frames.append(region)

func _load_materials() -> void:
	var files := {"plaster":"Plaster001_1K-JPG_Color.jpg","concrete":"Concrete010_1K-JPG_Color.jpg","metal":"Metal012_1K-JPG_Color.jpg"}
	for family in files:
		var texture := _texture("res://assets/rpg/chapter4-stair/materials/" + files[family])
		if texture != null: textures[family] = texture
	var palette := {"wall":"e7d9b9","skirt":"7d908e","stone":"cbd4cb","metal":"31444b","edge":"bfaf91","dark":"17252d","glass":"173c5a","warn":"d89262"}
	for key in palette:
		var surface_material := StandardMaterial3D.new()
		surface_material.albedo_color = Color(palette[key])
		surface_material.roughness = .95
		surface_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		var family: String = {"wall":"plaster","skirt":"plaster","stone":"concrete","metal":"metal"}.get(key, "")
		if textures.has(family): surface_material.albedo_texture = textures[family]
		materials[key] = surface_material

func _build_stage() -> void:
	surface = SubViewportContainer.new()
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.stretch = true
	add_child(surface)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.positional_shadow_atlas_size = 1024
	surface.add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color.BLACK
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("a6b2b8")
	settings.ambient_light_energy = .105
	environment.environment = settings
	world.add_child(environment)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.0
	camera.near = .05
	camera.far = 90
	world.add_child(camera)
	camera.current = true
	for section in model.geometry.routes:
		build_group = Node3D.new()
		build_group.name = str(section.id)
		build_group.set_meta("center_y", (float(section.fromY)+float(section.toY))*.5)
		build_group.set_meta("fade", -1.0)
		build_group.set_meta("materials", {})
		world.add_child(build_group)
		groups.append(build_group)
		for floor_box in model.geometry.floors:
			var r: Array = floor_box.rect
			var center: float = float(r[0])+float(r[2])*.5
			if center < float(section.start) or center >= float(section.start)+float(section.length): continue
			var position_3d: Vector3 = model.route_position(center,float(r[1])+float(r[3])*.5)
			var tread := _box(position_3d,Vector3(float(r[2]),float(r[3]),2),"stone",true)
			var heading: Vector3 = model.route_heading(center)
			tread.rotation.y = -atan2(heading.z,heading.x)
			var nosing := _box(model.route_position(float(r[0])+.015,float(r[1])+float(r[3])-.015),Vector3(.025,.025,2.02),"edge")
			nosing.rotation.y = tread.rotation.y
		for obstacle in model.geometry.obstacles:
			var r: Array = obstacle.rect
			var center: float = float(r[0])+float(r[2])*.5
			if center < float(section.start) or center >= float(section.start)+float(section.length): continue
			var barrier := _box(model.route_position(center,float(r[1])+float(r[3])*.5),Vector3(float(r[2]),float(r[3]),1.65),"metal",true)
			var heading: Vector3 = model.route_heading(center)
			barrier.rotation.y = -atan2(heading.z,heading.x)
			var marker := _box(model.route_position(center,float(r[1])+float(r[3])+.015),Vector3(float(r[2])+.03,.035,1.68),"warn")
			marker.rotation.y = barrier.rotation.y
		var begin: float = float(section.start)
		var end: float = begin+float(section.length)
		var tangent: Vector3 = model.route_heading(begin+.01)
		var lateral := Vector3(-tangent.z,0,tangent.x)
		for side in [-1.0,1.0]:
			var a: Vector3 = model.route_position(begin,float(section.fromY)) + lateral*side
			var b: Vector3 = model.route_position(end,float(section.toY)) + lateral*side
			_rail(a+Vector3.UP*.98,b+Vector3.UP*.98)
			var count: int = ceili(float(section.length)/1.8)
			for index in count+1:
				var u: float = lerpf(begin+.02,end-.02,float(index)/count)
				var floor_y: float = model.floor_height_at(u)
				if not is_finite(floor_y): continue
				var foot: Vector3 = model.route_position(u,floor_y)+lateral*side
				_box(foot+Vector3.UP*.47,Vector3(.065,.94,.065),"metal")
				_box(foot+Vector3.UP*.018,Vector3(.15,.035,.15),"metal")
		if str(section.kind) == "flight":
			var y: float = float(section.fromY)
			_box(Vector3(0,y+1.65,-4.6),Vector3(16,3.3,.22),"wall",true)
			_box(Vector3(0,y+.45,-4.46),Vector3(16,.9,.06),"skirt")
			var window_x: float = -2.8 if int(round(y/3.3))%2 == 0 else 2.8
			_box(Vector3(window_x,y+2.0,-4.4),Vector3(1.5,1.65,.12),"metal")
			_box(Vector3(window_x,y+2.0,-4.32),Vector3(1.28,1.42,.05),"glass")
			_box(Vector3(window_x,y+2.0,-4.27),Vector3(.055,1.42,.06),"metal")
			var label := Label3D.new()
			label.text = "%dF" % (int(round(y/3.3))+2)
			label.position = Vector3(-5,y+2,-4.3)
			label.font_size = 40
			label.pixel_size = .009
			label.modulate = Color("bec8c3")
			build_group.add_child(label)
	build_group = null
	actor = _sprite(false)
	pursuer = _sprite(true)
	actor_fill = SpotLight3D.new()
	actor_fill.light_cull_mask = 2
	actor_fill.light_color = Color("286bff")
	actor_fill.light_energy = 4.0
	actor_fill.spot_range = 1.05
	actor_fill.spot_angle = 18
	actor_fill.spot_attenuation = 1.0
	actor_fill.name = "PhoneFaceLight"
	world.add_child(actor_fill)
	phone_hand_fill = OmniLight3D.new()
	phone_hand_fill.light_cull_mask = 2
	phone_hand_fill.light_color = Color("286bff")
	phone_hand_fill.light_energy = .8
	phone_hand_fill.omni_range = .16
	world.add_child(phone_hand_fill)
	phone = Node3D.new()
	phone.name = "PlayerPhone"
	world.add_child(phone)
	var phone_body := _box(Vector3.ZERO,Vector3(.10,.16,.025),"dark")
	phone_body.reparent(phone)
	phone_screen = _box(Vector3(0,0,.016),Vector3(.085,.135,.006),"glass")
	phone_screen.reparent(phone)
	phone_screen.name = "Screen"
	var screen_material := StandardMaterial3D.new()
	screen_material.albedo_color = Color("286bff")
	screen_material.emission_enabled = true
	screen_material.emission = Color("286bff")
	screen_material.emission_energy_multiplier = 1.6
	phone_screen.material_override = screen_material
	phone_screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	torch = SpotLight3D.new()
	torch.light_color = Color("ffd166")
	torch.light_energy = 10
	torch.spot_range = float(model.geometry.lighting.torchRange)
	torch.spot_angle = float(model.geometry.lighting.torchAngle)
	torch.spot_attenuation = 1.2
	torch.shadow_enabled = true
	world.add_child(torch)
	torch_case = _box(Vector3.ZERO,Vector3(.18,.085,.085),"dark")
	torch_case.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	torch_lens = _box(Vector3.ZERO,Vector3(.008,.07,.08),"edge")
	var lens_material := StandardMaterial3D.new()
	lens_material.albedo_color = torch.light_color
	lens_material.emission_enabled = true
	lens_material.emission = torch.light_color
	torch_lens.material_override = lens_material
	torch_lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Compatibility rendering has no volumetric fog. This subtle depth-tested
	# scattering ribbon approximates the narrow air path, not a world light.
	torch_path = MeshInstance3D.new()
	torch_path.name = "GuardLightAirPath"
	torch_path.mesh = ImmediateMesh.new()
	var air_material := StandardMaterial3D.new()
	air_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	air_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	air_material.vertex_color_use_as_albedo = true
	air_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	air_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	air_material.no_depth_test = false
	torch_path.material_override = air_material
	torch_path.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(torch_path)

func _box(at: Vector3, dimensions: Vector3, material_key: String, solid: bool=false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var key := str(dimensions)
	if not mesh_cache.has(key):
		var mesh := BoxMesh.new()
		mesh.size = dimensions
		mesh_cache[key] = mesh
	node.mesh = mesh_cache[key]
	var surface_material: StandardMaterial3D = materials[material_key]
	if build_group != null:
		var local_materials: Dictionary = build_group.get_meta("materials")
		if not local_materials.has(material_key):
			local_materials[material_key] = surface_material.duplicate()
			local_materials[material_key].set_meta("base_color",surface_material.albedo_color)
		surface_material = local_materials[material_key]
		node.material_override = surface_material
		build_group.add_child(node)
	else:
		node.material_override = surface_material
		world.add_child(node)
	node.position = at
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = dimensions
		collision.shape = shape
		node.add_child(body)
		body.add_child(collision)
		solid_count += 1
		light_occluders.append(node)
	return node

func _beam_ray_distance(origin: Vector3, direction: Vector3, maximum: float) -> float:
	# Analytic ray/OBB slabs use the exact meshes of the existing solid boxes.
	# No extra collider or movement rule is introduced for this visual effect.
	if maximum <= 0 or direction.length_squared() < .000001: return 0.0
	var ray := direction.normalized()
	var limit := maximum
	for occluder in light_occluders:
		if not is_instance_valid(occluder): continue
		var box := occluder.mesh as BoxMesh
		if box == null: continue
		var inverse := occluder.global_transform.affine_inverse()
		var local_origin := inverse*origin
		var local_ray := inverse.basis*ray
		var half := box.size*.5
		var entry := 0.0
		var leave := limit
		var hit := true
		for axis in 3:
			if absf(local_ray[axis]) < .000001:
				if absf(local_origin[axis]) > half[axis]:
					hit = false
					break
			else:
				var a: float = (-half[axis]-local_origin[axis])/local_ray[axis]
				var b: float = (half[axis]-local_origin[axis])/local_ray[axis]
				entry = maxf(entry,minf(a,b))
				leave = minf(leave,maxf(a,b))
				if leave < entry:
					hit = false
					break
		if hit: limit = minf(limit,maxf(0.0,entry-.012))
	return limit

func _beam_vertex(mesh: ImmediateMesh, ray: Vector3, distance: float, cross_fraction: float, length_fraction: float) -> void:
	var edge_fade: float = pow(maxf(0.0,1.0-absf(cross_fraction)),.7)
	var tail_fade: float = pow(maxf(0.0,1.0-length_fraction),.65)
	var source_fade: float = minf(1.0,.45+distance*5.0)
	var color := torch.light_color
	color.a = .16*edge_fade*tail_fade*source_fade
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(beam_origin+ray*distance)
	torch_path_vertex_count += 1

func _update_beam_path() -> void:
	var mesh := torch_path.mesh as ImmediateMesh
	mesh.clear_surfaces()
	torch_path_vertex_count = 0
	beam_origin = torch.global_position
	beam_ray_lengths.clear()
	var forward := -torch.global_basis.z.normalized()
	var across := forward.cross(camera.global_basis.z).normalized()
	if across.length_squared() < .000001: across = torch.global_basis.x
	var rays: Array[Vector3] = []
	const RAYS := 13
	const STEPS := 8
	for index in RAYS:
		var cross_fraction := float(index)/(RAYS-1)*2.0-1.0
		var angle := deg_to_rad(torch.spot_angle)*cross_fraction
		var ray: Vector3 = forward*cos(angle)+across*sin(angle)
		rays.append(ray)
		beam_ray_lengths.append(_beam_ray_distance(beam_origin,ray,torch.spot_range))
	var any_visible := false
	for index in RAYS-1:
		if minf(beam_ray_lengths[index],beam_ray_lengths[index+1]) > .02:
			any_visible = true
			break
	if not any_visible: return
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in RAYS-1:
		# Conservatively stop each wedge at its nearer edge-ray obstruction.
		var reach := minf(beam_ray_lengths[index],beam_ray_lengths[index+1])
		if reach <= .02: continue
		var c0 := float(index)/(RAYS-1)*2.0-1.0
		var c1 := float(index+1)/(RAYS-1)*2.0-1.0
		for step in STEPS:
			var t0 := float(step)/STEPS
			var t1 := float(step+1)/STEPS
			_beam_vertex(mesh,rays[index],reach*t0,c0,t0)
			_beam_vertex(mesh,rays[index+1],reach*t0,c1,t0)
			_beam_vertex(mesh,rays[index+1],reach*t1,c1,t1)
			_beam_vertex(mesh,rays[index],reach*t0,c0,t0)
			_beam_vertex(mesh,rays[index+1],reach*t1,c1,t1)
			_beam_vertex(mesh,rays[index],reach*t1,c0,t1)
	mesh.surface_end()

func _rail(a: Vector3,b: Vector3) -> void:
	var node := _box((a+b)*.5,Vector3(.055,a.distance_to(b),.055),"metal")
	node.quaternion = Quaternion(Vector3.UP,(b-a).normalized())

func _sprite(guard: bool) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = true
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = 1.7/128.0
	sprite.offset = Vector2(0,62)
	sprite.layers = 2
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if guard: sprite.hframes = 8
	world.add_child(sprite)
	return sprite

func _build_ui() -> void:
	menu = PanelContainer.new()
	add_child(menu)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	menu.add_child(column)
	instruction = Label.new()
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_font_size_override("font_size",19)
	column.add_child(instruction)
	start_button = Button.new()
	start_button.custom_minimum_size.y = 48
	start_button.pressed.connect(_menu_action)
	column.add_child(start_button)
	var back := Button.new()
	back.text = "离开预览"
	back.custom_minimum_size.y = 42
	back.pressed.connect(func(): active=false; _clear_input(); exited.emit())
	column.add_child(back)

func _fit() -> void:
	if surface == null: return
	view_rect = Rect2(Vector2.ZERO,size)
	surface.position = Vector2.ZERO
	surface.size = size
	# Container owns its child viewport dimensions when stretching is enabled.
	surface.stretch_shrink = maxi(1,ceili(maxf(size.x/960.0,size.y/660.0)))
	camera.size = 16.0 if size.y>size.x else 13.0
	menu.size = Vector2(minf(590,maxf(200,size.x-24)),0)
	menu.position = (size-menu.size)*.5

func _show_menu(text: String, button: String) -> void:
	active = false
	_clear_input()
	instruction.text = text
	start_button.text = button
	menu.show()
	_fit.call_deferred()

func _start() -> void:
	model.reset()
	_clear_input()
	jump_ticks = 0
	land_ticks = 0
	retained_heading = Vector3.RIGHT
	guard_heading = Vector3.RIGHT
	follow_center = Vector3(-6,3.4,-1.3)
	focus_paused = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	active = true
	menu.hide()

func _menu_action() -> void:
	if focus_paused and model.status == "running":
		focus_paused = false
		active = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		menu.hide()
	else: _start()

func _adjust_input_mask(mask: int) -> int:
	var axis: int = int((mask&Model.RIGHT)!=0)-int((mask&Model.LEFT)!=0)
	if axis == 0:
		held_screen_axis = 0
		held_route_direction = 0
	elif held_screen_axis == 0:
		held_route_direction = int(model.screen_direction(model.player.x,axis,camera.global_basis.x))
	elif axis != held_screen_axis:
		held_route_direction = -held_route_direction
	held_screen_axis = axis
	return (mask&Model.JUMP) | (Model.RIGHT if held_route_direction>0 else (Model.LEFT if held_route_direction<0 else 0))

func _physics_process(_delta: float) -> void:
	if not active: return
	var left: bool = Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
	var right: bool = Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	var mask: int = (Model.LEFT if left or touch_axis<0 else 0) | (Model.RIGHT if right or touch_axis>0 else 0)
	if queued_jump or Input.is_physical_key_pressed(KEY_SPACE): mask |= Model.JUMP
	queued_jump = false
	var grounded: bool = model.player_grounded
	model.step(_adjust_input_mask(mask))
	if not model.player_grounded: jump_ticks += 1
	elif not grounded: land_ticks=7; jump_ticks=0
	elif land_ticks>0: land_ticks-=1
	if model.status != "running":
		if model.status == "finished":
			_show_menu("本段已抵达上层\n开发切片，尚未接入剧情及下一层迷宫", "重新试玩")
			finished.emit(model.proof())
		else: _show_menu("被追上或失足\n观察踏步、挡物和前方短光后再试", "重试")

func _process(delta: float) -> void:
	if camera != null: _present(delta)

func _present(delta: float) -> void:
	var p: Vector3 = model.route_position(model.player.x,model.player.y)
	var g: Vector3 = model.route_position(model.guard.x,model.guard.y)
	var ground_y: float = model.route_surface_height(model.player.x)
	var center := Vector3(clampf(p.x*.5,-6,3),ground_y+3,-1.3)
	if size.y>size.x:
		center = p+model.route_heading(model.player.x)*1.5
		center.y = ground_y+3
	follow_center = center if delta<=0 else follow_center.lerp(center,1-exp(-delta*3))
	camera.position = follow_center+Vector3(-7,14.5,22.25)
	camera.look_at(follow_center)
	if absf(model.player_velocity.x)>.001: retained_heading=model.route_heading(model.player.x,signf(model.player_velocity.x))
	if absf(model.guard_velocity.x)>.001: guard_heading=model.route_heading(model.guard.x,signf(model.guard_velocity.x))
	actor.position = p
	pursuer.position = g
	var facing: Dictionary = Model.visible_facing(retained_heading,camera.global_basis)
	var direction: String = facing.facing
	actor.flip_h = direction=="side" and bool(facing.left)
	actor.pixel_size = 1.7/128.0
	actor.offset = Vector2(0,62)
	var frame: int = floori(model.tick/7.0)%8
	actor.texture = player_frames[direction][frame if absf(model.player_velocity.x)>.001 else 0]
	if direction=="side" and absf(model.player_velocity.x)<.001: actor.texture=player_frames.idle
	if direction=="side" and jump_frames.size()==4 and (not model.player_grounded or land_ticks>0):
		var index: int = 3 if model.player_grounded else (0 if jump_ticks<=2 else (1 if jump_ticks<=7 else 2))
		actor.texture = jump_frames[index]
		actor.pixel_size = 1.7/724.0
		var anchor: Vector2 = JUMP_ROOTS[index]
		actor.offset = Vector2((271.5-anchor.x)*(-1 if actor.flip_h else 1),anchor.y-362)
	var guard_facing: Dictionary = Model.visible_facing(guard_heading,camera.global_basis)
	pursuer.texture = guard_frames[guard_facing.facing]
	pursuer.flip_h = guard_facing.facing=="side" and bool(guard_facing.left)
	pursuer.frame = frame
	# Pixel anchors follow each whole-body source frame, including the billboard basis.
	guard_hand_world = _sprite_socket(pursuer,_hand_pixel(true,guard_facing.facing,frame))
	var hand_pixel: Vector2 = Vector2(45,89) if direction=="side" and absf(model.player_velocity.x)<.001 else _hand_pixel(false,direction,frame if absf(model.player_velocity.x)>.001 else 0)
	player_hand_world = _sprite_socket(actor,hand_pixel)
	phone.position = player_hand_world+camera.global_basis.z*.07
	phone.global_basis = camera.global_basis
	actor_fill.position = phone_screen.global_position
	phone_hand_fill.position = phone_screen.global_position
	var face_pixel := Vector2(57,43) if direction=="side" else Vector2(48,43)
	actor_fill.look_at(_sprite_socket(actor,face_pixel))
	var pose: Dictionary = model.torch_pose(guard_hand_world)
	var guard_tangent: Vector3 = (Vector3(pose.position)-Vector3(pose.case_position)).normalized()
	torch.position = pose.position
	torch.look_at(pose.target)
	torch_case.position = pose.case_position
	torch_case.rotation.y = -atan2(guard_tangent.z,guard_tangent.x)
	torch_lens.position = torch.position-guard_tangent*.012
	torch_lens.rotation.y = torch_case.rotation.y
	_update_beam_path()
	for group in groups:
		var y: float = group.get_meta("center_y")
		group.visible = absf(y-ground_y)<8 or absf(y-model.guard.y)<4
		var fade: float = clampf(1-absf(y-ground_y-1.65)/7,.05,1)
		if absf(fade-float(group.get_meta("fade")))>.04:
			for surface_material in group.get_meta("materials").values():
				var color: Color = surface_material.get_meta("base_color")
				surface_material.albedo_color = Color(color.r*fade,color.g*fade,color.b*fade,color.a)
			group.set_meta("fade",fade)

func _sprite_socket(sprite: Sprite3D, pixel: Vector2) -> Vector3:
	var x: float = (pixel.x-48)*(-1 if sprite.flip_h else 1)+sprite.offset.x
	var y: float = 64-pixel.y+sprite.offset.y
	return sprite.position+(camera.global_basis.x*x+camera.global_basis.y*y)*sprite.pixel_size

func _hand_pixel(guard: bool, direction: String, frame: int) -> Vector2:
	# Authored from the visible hand/wrist of unchanged 96×128 source cells.
	# Back-view frame 4 has a covered left wrist: use its cuff, never switch hands.
	var anchors: Dictionary
	if guard:
		anchors = {"side":[Vector2(57,84),Vector2(60,84),Vector2(64,82),Vector2(62,81),Vector2(56,84),Vector2(59,90),Vector2(61,84),Vector2(66,87)],
		"up":[Vector2(67,83),Vector2(66,85),Vector2(66,84),Vector2(68,87),Vector2(66,89),Vector2(66,88),Vector2(67,90),Vector2(66,88)],
		"down":[Vector2(69,84),Vector2(69,87),Vector2(69,84),Vector2(67,83),Vector2(67,84),Vector2(68,86),Vector2(69,81),Vector2(69,87)]}
	else:
		anchors = {"side":[Vector2(63,84),Vector2(45,91),Vector2(45,91),Vector2(60,85),Vector2(62,79),Vector2(47,90),Vector2(47,90),Vector2(47,90)],
		"up":[Vector2(28,89),Vector2(27,90),Vector2(27,86),Vector2(28,88),Vector2(33,84),Vector2(28,89),Vector2(27,92),Vector2(28,87)],
		"down":[Vector2(67,83),Vector2(67,91),Vector2(66,90),Vector2(65,89),Vector2(65,90),Vector2(67,91),Vector2(68,81),Vector2(68,83)]}
	return anchors[direction][frame%8]

func _input(event: InputEvent) -> void:
	# Release is processed even over the menu; a lost release must never keep running.
	if event is InputEventKey and not event.pressed and event.physical_keycode in [KEY_A,KEY_D,KEY_LEFT,KEY_RIGHT]:
		if not (Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_RIGHT)):
			held_screen_axis=0; held_route_direction=0
	if event is InputEventScreenTouch and not event.pressed: _pointer_press(event.index,event.position,false)
	if event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed: _pointer_press(-1,event.position,false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		if active:
			focus_paused=true; _show_menu("已暂停", "继续")
		elif focus_paused: _menu_action()
		get_viewport().set_input_as_handled()
		return
	if not active: return
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode==KEY_SPACE or event.keycode==KEY_SPACE):
		queued_jump=true; get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed: _pointer_press(event.index,event.position,true)
	elif event is InputEventScreenDrag: _pointer_move(event.index,event.position)
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.button_index==MOUSE_BUTTON_LEFT and event.pressed: _pointer_press(-1,event.position,true)
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION: _pointer_move(-1,event.position)

func _pointer_press(index: int, point: Vector2, pressed: bool) -> void:
	point -= global_position
	if pressed:
		if not active or not view_rect.has_point(point): return
		if primary_touch != -99 and primary_touch != index: queued_jump=true; return
		primary_touch=index; touch_origin=point; touch_point=point
		touch_started=Time.get_ticks_msec(); swipe_used=false
		_steer_touch()
	elif primary_touch==index:
		if active and Time.get_ticks_msec()-touch_started<180 and point.distance_to(touch_origin)<22: queued_jump=true
		primary_touch=-99; touch_axis=0; held_screen_axis=0; held_route_direction=0

func _pointer_move(index: int, point: Vector2) -> void:
	if primary_touch!=index: return
	touch_point=point-global_position
	_steer_touch()
	if not swipe_used and touch_origin.y-touch_point.y>34: queued_jump=true; swipe_used=true

func _steer_touch() -> void:
	var point: Vector2 = camera.unproject_position(actor.position)
	point *= size/Vector2(viewport.size)
	var difference: float = touch_point.x-point.x
	touch_axis = int(signf(difference)) if absf(difference)>24 else 0

func _clear_input() -> void:
	primary_touch=-99; touch_axis=0; queued_jump=false; swipe_used=false
	held_screen_axis=0; held_route_direction=0

func _lose_focus() -> void:
	if not active: return
	focus_paused=true
	_show_menu("已暂停，点击继续", "继续")
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
