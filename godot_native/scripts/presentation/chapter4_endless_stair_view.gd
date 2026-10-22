extends Control
## Version B: a finite, continuous 12-flight stairwell. No campaign or save writes.
## Geometry stays at fixed world coordinates. Only the camera follows the ascent.
signal finished(result: Dictionary)
signal exited
const BeamClip = preload("res://scripts/presentation/endless_stair_beam_clipper.gd")
const StairGait = preload("res://scripts/presentation/endless_stair_gait.gd")
const RhythmFeedback=preload("res://scripts/presentation/endless_stair_guard_feedback.gd")
const Model = preload("res://scripts/games/chapter4_endless_stair_model.gd")
const JUMP_PATH = "res://assets/native/endless_stair_b3/player_jump_atlas.png"
const JUMP_ROOTS = [Vector2(284,686),Vector2(252,657.25),Vector2(280,615.25),Vector2(242,681)]
var model = Model.new()
var rhythm_feedback
var stair_gait
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
const JUMP_BUFFER_TICKS := 7 # 117 ms at the unchanged 60 Hz model tick.
var queued_jump := false
var jump_buffer_ticks := 0
var jump_pressed_last := false
var input_rearm_keys: Dictionary = {}
var camera_route_direction := 1.0
var camera_route_intent := 1.0
var input_view_size := Vector2.ZERO
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
var blocker_cache: Array[Dictionary] = []
var near_blockers: Array[Dictionary] = []
var shadow_groups: Array[Dictionary] = []
var visual_batches: Array[Dictionary] = []
var floor_markers: Array[Label3D] = []
var floor_marker_captions: Array[Label3D] = []
var highest_visual_progress := 1.0
var last_beam_tick := -1
var beam_candidate_count := 0
var active_marker := -1
var marker_alpha := 0.0
var static_mesh_instances_before := 0
var static_mesh_instances_after := 0

var view_rect := Rect2()
var subtitle: Label
var corner_label: Label
var current_beat := -1
var subtitle_until := 0
var demo_mode := false
var capture_tick := 0
var capture_frames: Array[int] = [330, 780, 1260, 1740, 3340, 3460]
var font: Font


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/native/endless_stair_b3/stair_text.ttf"):
		font = load("res://assets/native/endless_stair_b3/stair_text.ttf")
	_load_art()
	_load_materials()
	_build_stage()
	_build_ui()
	rhythm_feedback=RhythmFeedback.new()
	add_child(rhythm_feedback)
	rhythm_feedback.setup(self)
	stair_gait = StairGait.new()
	add_child(stair_gait)
	stair_gait.setup(self)
	resized.connect(_fit)
	get_window().focus_exited.connect(_lose_focus)
	_fit()
	_show_menu("北教楼梯间 · B\n楼梯怎么还没到头？\n\nA / D 或 ← / →：沿楼梯移动\nSpace：跳过断阶和挡物\n按住方向键会沿平台转弯\n触屏：按左右移动，上滑跳跃\nEsc：暂停", "开始向上")
	_present(0.0)
	demo_mode = "--demo" in OS.get_cmdline_user_args()
	if demo_mode: _start.call_deferred()

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

func _pixel_texture(kind: String) -> Texture2D:
	# Authored pixel blocks, fixed palette; no photoreal texture or filtering.
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var hash_value: int = (x * 73 + y * 151 + (x / 3) * (y / 5) * 19) % 97
			var tone := 1.0
			if kind == "wall":
				tone = .88 if hash_value < 5 else (.95 if hash_value < 25 else 1.0)
				if y > 55 and (x / 4) % 3 == 0: tone *= .89
			elif kind == "skirt":
				tone = .67 if x % 16 == 0 or y % 16 == 0 else (.88 if hash_value < 10 else 1.0)
				if y % 16 == 1: tone = 1.07
			elif kind == "stone":
				tone = .73 if y % 32 == 0 else (.88 if hash_value < 14 else 1.0)
				if hash_value == 57: tone = 1.13
			elif kind == "metal":
				tone = .75 if hash_value < 8 else (.92 if x % 12 < 2 else 1.0)
			image.set_pixel(x, y, Color(tone, tone, tone, 1))
	return ImageTexture.create_from_image(image)

func _load_materials() -> void:
	var palette := {"wall":"a6b1aa","skirt":"476868","stone":"879597","metal":"344a51","edge":"a3b4ad","dark":"111d24","glass":"203943","warn":"a7804e","paper":"c2bda4","rust":"624e3d","shadow":"1c3038","trim":"687f7d","door":"384f51","green":"679085"}
	for key in palette:
		var surface_material := StandardMaterial3D.new()
		surface_material.albedo_color = Color(palette[key])
		surface_material.roughness = 1.0
		surface_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		if key in ["wall", "skirt", "stone", "metal"]:
			surface_material.albedo_texture = _pixel_texture(key)
			surface_material.uv1_scale = Vector3(2, 2, 1) if key == "wall" else Vector3.ONE
		materials[key] = surface_material

func _wall_label(text: String, at: Vector3, scale_px: float = .008, tint: Color = Color("a9b8af")) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 40
	label.pixel_size = scale_px
	label.modulate = tint
	label.outline_size = 0
	label.no_depth_test = false
	label.shaded = true
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if font: label.font = font
	build_group.add_child(label)
	return label

func _school_wall(section: Dictionary) -> void:
	var route_group := build_group
	var architecture := Node3D.new()
	architecture.name = "Architecture"
	architecture.set_meta("materials",{})
	route_group.add_child(architecture)
	build_group = architecture
	var n := int(section.flight) - 1
	var y := float(section.fromY)
	# Identical architecture repeats; these are real, stacked storeys.
	_box(Vector3(0,y+1.65,-4.6),Vector3(16.6,3.3,.22),"wall",true)
	_box(Vector3(0,y+.53,-4.46),Vector3(16.6,1.06,.06),"skirt")
	_box(Vector3(0,y+1.08,-4.41),Vector3(16.6,.055,.06),"trim")
	_box(Vector3(0,y+3.24,-4.42),Vector3(16.6,.10,.09),"shadow")
	# Cement joints and the vertical pipe are recurring alignment anchors.
	for xx in [-7.8,7.8]:
		_box(Vector3(xx,y+1.65,-4.36),Vector3(.08,3.3,.09),"trim")
		_box(Vector3(xx+.08,y+.6,-4.34),Vector3(.14,.08,.13),"metal")
	var wx := .9
	_box(Vector3(wx,y+2.03,-4.37),Vector3(2.24,1.64,.18),"shadow")
	_box(Vector3(wx,y+2.03,-4.25),Vector3(2.10,1.49,.05),"glass")
	# Rain streaks and silhouettes are geometry, not a bright window light.
	for k in 8:
		var xx := wx-.88+float(k)*.25
		var offset := float((k*17+n*3)%7)*.03
		_box(Vector3(xx,y+1.86+offset,-4.205),Vector3(.018,.43+float(k%3)*.14,.008),"trim")
	for xx in [wx-1.07,wx,wx+1.07]:
		_box(Vector3(xx,y+2.03,-4.16),Vector3(.075,1.57,.10),"metal")
	for yy in [y+1.27,y+2.05,y+2.81]:
		_box(Vector3(wx,yy,-4.16),Vector3(2.22,.075,.10),"metal")
	_box(Vector3(wx,y+1.22,-4.12),Vector3(2.40,.10,.26),"stone")
	# Every sign still reads 04. Put it over the entry-side quarter of each flight.
	var sign_x := -3.0 if n%2==0 else 3.0
	_box(Vector3(sign_x,y+2.13,-4.34),Vector3(1.02,.79,.12),"skirt")
	var marker := _wall_label("04",Vector3(sign_x,y+2.18,-4.24),.013,Color("c1cbbd"))
	marker.set_meta("route_start",float(section.start))
	marker.modulate.a = 0.0
	floor_markers.append(marker)
	var caption:=_wall_label("北教 / UP",Vector3(sign_x,y+1.91,-4.23),.0034)
	caption.modulate.a=0
	floor_marker_captions.append(caption)
	for k in mini(n/2+1,6):
		_box(Vector3(sign_x-.35+float(k)*.075,y+1.62,-4.27),Vector3(.019,.14,.018),"rust")
	# Notice, taped corner and one subtly changing curled sheet.
	_box(Vector3(4.62,y+1.85,-4.32),Vector3(.92,1.04,.09),"metal")
	_box(Vector3(4.62,y+1.85,-4.25),Vector3(.80,.92,.025),"paper")
	_box(Vector3(4.62,y+2.18,-4.22),Vector3(.63,.08,.018),"warn")
	for k in 5:
		_box(Vector3(4.59,y+2.03-float(k)*.11,-4.22),Vector3(.48-float(k%2)*.11,.025,.018),"trim")
	if n >= 4: _box(Vector3(4.95,y+1.43,-4.20),Vector3(.13,.16,.04),"wall")
	if n >= 8: _box(Vector3(4.27,y+2.28,-4.18),Vector3(.12,.05,.03),"warn")
	# A repeated landing door reinforces the school stairwell scale.
	_box(Vector3(-6.6,y+1.25,-4.34),Vector3(1.32,2.50,.12),"shadow")
	_box(Vector3(-6.6,y+1.22,-4.24),Vector3(1.18,2.35,.08),"door")
	_box(Vector3(-6.6,y+1.73,-4.18),Vector3(.71,.63,.045),"glass")
	_box(Vector3(-6.18,y+1.06,-4.13),Vector3(.07,.23,.06),"edge")
	_wall_label("关 闭",Vector3(-6.6,y+2.62,-4.22),.004)
	build_group = route_group

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
	settings.background_color = Color("080e15")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("9aafb4")
	settings.ambient_light_energy = float(model.geometry.lighting.ambient)
	environment.environment = settings
	world.add_child(environment)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6.0
	camera.near = .05
	camera.far = 90
	world.add_child(camera)
	camera.current = true
	for section in model.geometry.routes:
		build_group = Node3D.new()
		build_group.name = str(section.id)
		build_group.set_meta("center_y", (float(section.fromY)+float(section.toY))*.5)
		build_group.set_meta("fade", -1.0)
		build_group.set_meta("route_start", float(section.start))
		build_group.set_meta("route_kind", str(section.kind))
		build_group.set_meta("visibility_alpha", 1.0)
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
			tread.set_meta("route_at",center)
			var nosing := _box(model.route_position(float(r[0])+.015,float(r[1])+float(r[3])-.015),Vector3(.025,.025,2.02),"edge")
			nosing.rotation.y = tread.rotation.y
			nosing.set_meta("route_at",float(r[0]))
		for obstacle in model.geometry.obstacles:
			var r: Array = obstacle.rect
			var center: float = float(r[0])+float(r[2])*.5
			if center < float(section.start) or center >= float(section.start)+float(section.length): continue
			var barrier := _box(model.route_position(center,float(r[1])+float(r[3])*.5),Vector3(float(r[2]),float(r[3]),1.65),"metal",true)
			var heading: Vector3 = model.route_heading(center)
			barrier.rotation.y = -atan2(heading.z,heading.x)
			barrier.set_meta("route_at",center)
			var marker := _box(model.route_position(center,float(r[1])+float(r[3])+.015),Vector3(float(r[2])+.03,.035,1.68),"warn")
			marker.rotation.y = barrier.rotation.y
			marker.set_meta("route_at",center)
		var begin: float = float(section.start)
		var end: float = begin+float(section.length)
		var tangent: Vector3 = model.route_heading(begin+.01)
		var lateral := Vector3(-tangent.z,0,tangent.x)
		for side in [-1.0,1.0]:
			var a: Vector3 = model.route_position(begin,float(section.fromY)) + lateral*side
			var b: Vector3 = model.route_position(end,float(section.toY)) + lateral*side
			if begin > float(model.geometry.bounds[0])+.1:
				var prev: Vector3 = model.route_heading(begin-.01)
				if absf(prev.dot(tangent)) < .1: a += Vector3(-prev.z,0,prev.x)*side
			if end < float(model.geometry.bounds[1])-.1:
				var next: Vector3 = model.route_heading(end+.01)
				if absf(next.dot(tangent)) < .1: b += Vector3(-next.z,0,next.x)*side
			# Handrails assemble in short bays with their corresponding treads.
			var bays := maxi(1,ceili(float(section.length)/.6))
			for bay in bays:
				var t0 := float(bay)/bays
				var t1 := float(bay+1)/bays
				var at: float=lerpf(begin,end,(t0+t1)*.5)
				for h in [.98,.44]:
					var rail := _rail(a.lerp(b,t0)+Vector3.UP*h,b.lerp(a,1-t1)+Vector3.UP*h)
					rail.set_meta("route_at",at)
				if str(section.kind)=="flight":
					var p0:=a.lerp(b,t0)-Vector3.UP*.24
					var p1:=a.lerp(b,t1)-Vector3.UP*.24
					var under := _box((p0+p1)*.5,Vector3(.13,p0.distance_to(p1),.19),"shadow")
					under.quaternion=Quaternion(Vector3.UP,(p1-p0).normalized())
					under.set_meta("route_at",at)
			var count: int = ceili(a.distance_to(b)/1.3)
			for index in count+1:
				var t: float = float(index)/count
				var foot: Vector3 = a.lerp(b,t)
				var post:=_box(foot+Vector3.UP*.47,Vector3(.055,.94,.055),"metal")
				post.set_meta("route_at",lerpf(begin,end,t))
				var footplate:=_box(foot+Vector3.UP*.018,Vector3(.13,.035,.13),"metal")
				footplate.set_meta("route_at",lerpf(begin,end,t))

		if str(section.kind) == "flight": _school_wall(section)
		if str(section.kind) == "exit":
			var end_pos: Vector3 = model.route_position(float(section.start)+5.1,float(section.fromY))
			_box(end_pos+Vector3(0,1.3,-.8),Vector3(.14,2.6,1.5),"green")
			_box(end_pos+Vector3(.01,1.3,-.8),Vector3(.18,2.35,1.25),"dark")
			_wall_label("05 / 出口",end_pos+Vector3(0,2.9,-.70),.008,Color("9fc6ae"))

	build_group = null
	actor = _sprite(false)
	pursuer = _sprite(true)
	actor_fill = SpotLight3D.new()
	actor_fill.light_cull_mask = 2
	actor_fill.light_color = Color("286bff")
	actor_fill.light_energy = 2.4
	actor_fill.spot_range = 1.05
	actor_fill.spot_angle = 18
	actor_fill.spot_attenuation = 1.0
	actor_fill.name = "PhoneFaceLight"
	world.add_child(actor_fill)
	phone_hand_fill = OmniLight3D.new()
	phone_hand_fill.light_cull_mask = 2
	phone_hand_fill.light_color = Color("286bff")
	phone_hand_fill.light_energy = .45
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
	torch.light_energy = 8.0
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
	_finalize_static_stage()

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
	node.set_meta("material_key",material_key)
	if build_group != null and (solid or (material_key in ["metal","shadow","door","stone"] and dimensions.length()>.30)):
		node.set_meta("blocks_light",true)
	if solid:
		node.set_meta("solid_box",true)
		# Movement collisions are the unchanged fixed-tick model rectangles.
		# Static rendering boxes do not duplicate a second physics world.
		solid_count += 1
		light_occluders.append(node)
	return node

func _beam_ray_distance(origin: Vector3, direction: Vector3, maximum: float) -> float:
	if maximum<=0 or direction.length_squared()<.000001:return 0.0
	var limit:=maximum
	for box in near_blockers:
		var inverse: Transform3D=box.inverse
		var local_origin: Vector3=inverse*origin
		var ray: Vector3=inverse.basis*direction.normalized()
		var half: Vector3=box.half
		var entry:=0.0
		var leave:=limit
		var hit:=true
		for axis in 3:
			if absf(ray[axis])<.000001:
				if absf(local_origin[axis])>half[axis]:hit=false;break
			else:
				var aa: float=(-half[axis]-local_origin[axis])/ray[axis]
				var bb: float=(half[axis]-local_origin[axis])/ray[axis]
				entry=maxf(entry,minf(aa,bb));leave=minf(leave,maxf(aa,bb))
				if leave<entry:hit=false;break
		if hit:limit=minf(limit,maxf(0,entry-.018))
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
	var reaches: Array[float] = []
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
		var reach := BeamClip.all_boxes_reach(beam_origin,rays[index],rays[index+1],torch.spot_range,near_blockers,.012)
		reaches.append(reach)
		if reach > .02:any_visible = true
	if not any_visible: return
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in RAYS-1:
		# Clip the WHOLE triangle, including thin blockers between the edge rays.
		var reach: float = reaches[index]
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

func _rail(a: Vector3,b: Vector3) -> MeshInstance3D:
	var node := _box((a+b)*.5,Vector3(.055,a.distance_to(b),.055),"metal")
	node.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	return node

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
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.025,.045,.055,.95)
	style.border_color = Color("53676b")
	style.set_border_width_all(1)
	style.set_content_margin_all(24)
	menu.add_theme_stylebox_override("panel",style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	menu.add_child(column)
	instruction = Label.new()
	instruction.add_theme_font_override("font",preload("res://scripts/ui/native_typography.gd").body_font())
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_font_size_override("font_size",19)
	column.add_child(instruction)
	start_button = Button.new()
	start_button.custom_minimum_size.y = 48
	start_button.pressed.connect(_menu_action)
	start_button.add_theme_font_override("font",preload("res://scripts/ui/native_typography.gd").body_font())
	column.add_child(start_button)
	var back := Button.new()
	back.text = "离开预览"
	back.custom_minimum_size.y = 42
	back.pressed.connect(_request_exit)
	back.add_theme_font_override("font",preload("res://scripts/ui/native_typography.gd").body_font())
	column.add_child(back)
	corner_label = Label.new()
	corner_label.add_theme_font_override("font",preload("res://scripts/ui/native_typography.gd").body_font())
	corner_label.text = "7:55  /  B"
	corner_label.position = Vector2(24,20)
	corner_label.add_theme_font_size_override("font_size",16)
	corner_label.modulate = Color("95a5a6")
	corner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(corner_label)
	subtitle = Label.new()
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size",21)
	subtitle.add_theme_color_override("font_color",Color("c3c9bf"))
	subtitle.add_theme_color_override("font_outline_color",Color("0b151c"))
	subtitle.add_theme_constant_override("outline_size",7)
	subtitle.add_theme_font_override("font",preload("res://scripts/ui/native_typography.gd").body_font())
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

func _request_exit() -> void:
	active = false
	focus_paused = false
	if rhythm_feedback: rhythm_feedback.pause_audio()
	if viewport: viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_clear_input()
	exited.emit()

func _exit_standalone_preview() -> void:
	# The canonical preview scene connects this signal. Embedded hosts keep
	# ownership of their application and handle `exited` themselves.
	if get_tree().current_scene == self:
		get_tree().quit()

func _fit() -> void:
	if surface == null: return
	if input_view_size != Vector2.ZERO and not input_view_size.is_equal_approx(size):
		_clear_input()
	input_view_size = size
	view_rect = Rect2(Vector2.ZERO,size)
	surface.position = Vector2.ZERO
	surface.size = size
	# Container owns its child viewport dimensions when stretching is enabled.
	# A tall phone must not collapse to a 130 px-wide render target. Preserve
	# source-pixel detail while keeping the original landscape render budget.
	surface.stretch_shrink = maxi(1, floori(size.x / 360.0)) if size.y > size.x else maxi(1, ceili(maxf(size.x / 640.0, size.y / 360.0)))
	if subtitle:
		subtitle.position = Vector2(24,size.y-66)
		subtitle.size = Vector2(size.x-48,40)
	# Keep horizontal warning distance on a narrow phone, without cropping the
	# next landing. The same fixed isometric basis is used in both orientations.
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = _camera_size()
	if active: _update_camera(0.0)
	menu.size = Vector2(minf(590,maxf(200,size.x-24)),0)
	menu.position = (size-menu.size)*.5

func _show_menu(text: String, button: String) -> void:
	active = false
	if rhythm_feedback: rhythm_feedback.pause_audio()
	_clear_input()
	instruction.text = text
	start_button.text = button
	menu.show()
	_fit.call_deferred()

func _start() -> void:
	model.reset()
	if stair_gait: stair_gait.reset()
	if rhythm_feedback:rhythm_feedback.reset()
	highest_visual_progress = model.player.x
	last_beam_tick=-1
	active_marker=-1
	marker_alpha=0
	for marker in floor_markers:marker.modulate.a=0
	for caption in floor_marker_captions:caption.modulate.a=0
	for batch in visual_batches:
		batch.settled_count=0
		batch.visible_count=0
		if not batch.always:batch.mesh.visible_instance_count=0
	_clear_input()
	jump_ticks = 0
	land_ticks = 0
	actor.scale = Vector3.ONE
	retained_heading = Vector3.RIGHT
	guard_heading = Vector3.RIGHT
	follow_center = Vector3(-6,3.4,-1.3)
	camera_route_direction = 1.0
	camera_route_intent = 1.0
	_update_camera(0.0)
	focus_paused = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	active = true
	menu.hide()
	current_beat = -1
	subtitle_until = 0
	subtitle.text = ""

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

func _key_down(key: Key) -> bool:
	var pressed := Input.is_physical_key_pressed(key)
	if input_rearm_keys.has(key):
		if not pressed: input_rearm_keys.erase(key)
		return false
	return pressed

func _buffered_jump_mask(mask: int, pressed: bool, requested: bool = false) -> int:
	# Buffer the intent in the input adapter. The model still records/replays
	# only the consumed raw edge; physics, proof version and jump height stay intact.
	if requested or (pressed and not jump_pressed_last):
		jump_buffer_ticks = JUMP_BUFFER_TICKS
	jump_pressed_last = pressed
	var result := mask & ~Model.JUMP
	if jump_buffer_ticks > 0:
		if model.player_grounded and not (model.last_input & Model.JUMP):
			result |= Model.JUMP
			jump_buffer_ticks = 0
		else:
			jump_buffer_ticks -= 1
	return result

func _camera_size() -> float:
	# 7.8 m horizontal world span preserves the feet, the 4.5 m warning horizon
	# and a side margin on a 390x844 phone. No black bars or extra overlay.
	var aspect := maxf(size.x, 1.0) / maxf(size.y, 1.0)
	return maxf(6.0, 7.8 / aspect)

func _camera_ground(progress: float) -> Vector3:
	var at := clampf(progress, float(model.geometry.bounds[0]), float(model.geometry.exit.x))
	return model.route_position(at, model.route_surface_height(at))

func _camera_target() -> Vector3:
	# Sample route position, not the discontinuous tangent at a landing.
	# A triangular footprint smooths the corner before the player reaches it.
	var ahead: float = model.player.x + camera_route_direction * 1.45
	var target := (_camera_ground(ahead - .45) + _camera_ground(ahead) * 2.0 + _camera_ground(ahead + .45)) * .25
	return target + Vector3(0, 1.25, -.35)

func _update_camera(delta: float) -> void:
	if absf(model.player_velocity.x) > .001:
		camera_route_intent = signf(model.player_velocity.x)
	camera_route_direction = camera_route_intent if delta <= 0 else move_toward(camera_route_direction, camera_route_intent, delta * 4.0)
	var center := _camera_target()
	# Never use actor.y here: jump, step-pose and landing bob are not camera input.
	if delta <= 0:
		follow_center = center
	else:
		# Reversing A/D blends the lead over half a second; a bounded camera
		# speed prevents a large single-frame catch-up even after rapid reversals.
		var smoothed := follow_center.lerp(center, 1.0 - exp(-delta * 8.0))
		follow_center = follow_center.move_toward(smoothed, delta * 6.0)
	camera.position = follow_center + Vector3(-2.5, 7.5, 18.0)
	camera.look_at(follow_center)

func _physics_process(_delta: float) -> void:
	if not active: return
	var left: bool = _key_down(KEY_A) or _key_down(KEY_LEFT)
	var right: bool = _key_down(KEY_D) or _key_down(KEY_RIGHT)
	var mask: int = (Model.LEFT if left or touch_axis<0 else 0) | (Model.RIGHT if right or touch_axis>0 else 0)
	mask = _buffered_jump_mask(mask, _key_down(KEY_SPACE), queued_jump)
	queued_jump = false
	var grounded: bool = model.player_grounded
	if demo_mode:
		# Only the explicit capture mode drives raw fixed-tick inputs.
		mask = model.reference_input()
		model.step(mask)
	else:
		model.step(_adjust_input_mask(mask))
	_story_beat()
	if demo_mode and model.tick in capture_frames:
		_capture_frame.call_deferred(model.tick)
	if demo_mode and model.tick == 2100:
		_capture_frame.call_deferred(model.tick)
		if "--short-demo" in OS.get_cmdline_user_args(): get_tree().quit()
	if not model.player_grounded: jump_ticks += 1
	elif not grounded: land_ticks=7; jump_ticks=0
	elif land_ticks>0: land_ticks-=1
	if model.status != "running":
		if model.status == "finished":
			_show_menu("终于，不再是四楼。\n十二段连续楼梯已走完\n这是独立 B 版，未接入主线", "重新试玩")
			finished.emit(model.proof())
		else: _show_menu("被追上或失足\n留意断阶与平台挡物，Space 跳过", "重试")

func _process(delta: float) -> void:
	if camera != null: _present(delta)

func _present(delta: float) -> void:
	var p: Vector3 = model.route_position(model.player.x,model.player.y)
	var g: Vector3 = model.route_position(model.guard.x,model.guard.y)
	_update_camera(delta)
	if absf(model.player_velocity.x)>.001: retained_heading=model.route_heading(model.player.x,signf(model.player_velocity.x))
	if absf(model.guard_velocity.x)>.001: guard_heading=model.route_heading(model.guard.x,signf(model.guard_velocity.x))
	actor.region_enabled = false
	pursuer.region_enabled = false
	pursuer.hframes = 8
	pursuer.offset = Vector2(0, 62)
	actor.position = p
	pursuer.position = g
	if stair_gait:
		stair_gait.prepare()
		if stair_gait.player_pose.get("active", false): retained_heading = stair_gait.player_pose.heading * (-1 if model.player_velocity.x < 0 else 1)
		if stair_gait.guard_pose.get("active", false): guard_heading = stair_gait.guard_pose.heading * (-1 if model.guard_velocity.x < 0 else 1)
	var facing: Dictionary = Model.visible_facing(retained_heading,camera.global_basis)
	var direction: String = facing.facing
	actor.flip_h = direction=="side" and bool(facing.left)
	actor.pixel_size = 1.7/128.0
	actor.offset = Vector2(0,62)
	var frame: int = floori(model.tick/7.0)%8
	if stair_gait: frame = stair_gait.source_frame(false, frame)
	actor.scale = Vector3.ONE
	# Front/back have no dedicated jump atlas. Keep the original identity but
	# stop playing a complete walking cycle in mid-air: extend, gather, land.
	# Side-view authored jump cells and planted stair IK retain their ownership.
	if direction != "side":
		if not model.player_grounded:
			frame = 1 if jump_ticks <= 3 or model.player_velocity.y < -1.0 else 5
			if jump_ticks <= 3: actor.scale = Vector3(.98, 1.025, 1)
		elif land_ticks > 0:
			frame = 1
			var absorb: float = sin(PI * (7.0-land_ticks) / 7.0)
			actor.scale = Vector3(1.0 + .04*absorb, 1.0 - .075*absorb, 1)
	actor.texture = player_frames[direction][frame if absf(model.player_velocity.x)>.001 or not model.player_grounded or land_ticks>0 else 0]
	if direction=="side" and absf(model.player_velocity.x)<.001: actor.texture=player_frames.idle
	if direction=="side" and jump_frames.size()==4 and (not model.player_grounded or land_ticks>0) and not (stair_gait and stair_gait.player_pose.get("active", false)):
		var index: int = 3 if model.player_grounded else (0 if jump_ticks<=2 else (1 if jump_ticks<=7 else 2))
		actor.texture = jump_frames[index]
		actor.pixel_size = 1.7/724.0
		var anchor: Vector2 = JUMP_ROOTS[index]
		actor.offset = Vector2((271.5-anchor.x)*(-1 if actor.flip_h else 1),anchor.y-362)
	var guard_facing: Dictionary = Model.visible_facing(guard_heading,camera.global_basis)
	pursuer.texture = guard_frames[guard_facing.facing]
	pursuer.flip_h = guard_facing.facing=="side" and bool(guard_facing.left)
	rhythm_feedback.advance()
	var guard_frame:int=rhythm_feedback.frame()
	if stair_gait: guard_frame = stair_gait.source_frame(true, guard_frame)
	pursuer.frame = guard_frame
	if stair_gait:
		stair_gait.apply(false, direction, frame)
		stair_gait.apply(true, guard_facing.facing, guard_frame)
	# Pixel anchors follow each whole-body source frame, including the billboard basis.
	guard_hand_world = _sprite_socket(pursuer,_hand_pixel(true,guard_facing.facing,guard_frame))
	guard_hand_world=rhythm_feedback.hand_pose(guard_hand_world,guard_facing.facing,delta)
	var hand_pixel: Vector2 = Vector2(45,89) if direction=="side" and absf(model.player_velocity.x)<.001 else _hand_pixel(false,direction,frame if absf(model.player_velocity.x)>.001 else 0)
	if stair_gait and stair_gait.player_pose.get("active", false): hand_pixel = Vector2(36,91)
	player_hand_world = _sprite_socket(actor,hand_pixel)
	phone.position = player_hand_world+camera.global_basis.z*.07
	phone.global_basis = camera.global_basis
	actor_fill.position = phone_screen.global_position
	phone_hand_fill.position = phone_screen.global_position
	var face_pixel := Vector2(57,43) if direction=="side" else Vector2(48,43)
	actor_fill.look_at(_sprite_socket(actor,face_pixel))
	var pose: Dictionary = rhythm_feedback.torch_pose(model.torch_pose(guard_hand_world))
	var guard_tangent: Vector3 = (Vector3(pose.target)-Vector3(pose.position)).normalized()
	torch.position = pose.position
	torch.look_at(pose.target)
	torch_case.position = Vector3(pose.position)-guard_tangent*.09
	torch_case.quaternion = Quaternion(Vector3.RIGHT,guard_tangent)
	torch_lens.position = torch.position-guard_tangent*.012
	torch_lens.quaternion = torch_case.quaternion
	_update_floor_marker(delta)
	# 60 Hz scene state is authoritative. Do not rebuild the same light mesh
	# twice when the display renders faster than the simulation.
	if last_beam_tick != model.tick or delta<=0:
		_update_stage_reveal(delta)
		_update_near_blockers()
		_update_beam_path()
		last_beam_tick=model.tick

func _sprite_socket(sprite: Sprite3D, pixel: Vector2) -> Vector3:
	if stair_gait and sprite.region_enabled:
		pixel = stair_gait.warp_pixel(pixel, sprite == pursuer)
	var x: float = (pixel.x-48)*(-1 if sprite.flip_h else 1)+sprite.offset.x
	var source_half_height: float = sprite.region_rect.size.y * .5 if sprite.region_enabled else 64.0
	var y: float = source_half_height-pixel.y+sprite.offset.y
	# Motion stretch is rooted at the same sole; the held phone/light must
	# follow the scaled source wrist rather than remain at its unscaled pixel.
	return sprite.position+(camera.global_basis.x*x*sprite.scale.x+camera.global_basis.y*y*sprite.scale.y)*sprite.pixel_size

func _hand_pixel(guard: bool, direction: String, frame: int) -> Vector2:
	# Authored from the visible hand/wrist of unchanged 96×128 source cells.
	# Back-view frame 4 has a covered left wrist: use its cuff, never switch hands.
	var anchors: Dictionary
	if guard:
		anchors = {"side":[Vector2(57,84),Vector2(60,84),Vector2(64,82),Vector2(62,81),Vector2(56,84),Vector2(59,90),Vector2(61,84),Vector2(66,87)],
		"up":[Vector2(67,83),Vector2(66,85),Vector2(66,84),Vector2(68,87),Vector2(66,89),Vector2(66,88),Vector2(67,90),Vector2(66,88)],
		"down":[Vector2(69,84),Vector2(69,87),Vector2(69,84),Vector2(67,83),Vector2(67,84),Vector2(68,86),Vector2(69,81),Vector2(69,87)]}
	else:
		anchors = {"side":[Vector2(36,91),Vector2(44,91),Vector2(43,91),Vector2(44,91),Vector2(38,91),Vector2(46,90),Vector2(46,90),Vector2(46,90)],
		"up":[Vector2(28,89),Vector2(27,90),Vector2(27,86),Vector2(28,88),Vector2(33,84),Vector2(28,89),Vector2(27,92),Vector2(28,87)],
		"down":[Vector2(67,83),Vector2(67,91),Vector2(66,90),Vector2(65,89),Vector2(65,90),Vector2(67,91),Vector2(68,81),Vector2(68,83)]}
	return anchors[direction][frame%8]

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.canceled:
		var owned_primary: bool = primary_touch == event.index
		_cancel_touch(event.index)
		if owned_primary:
			get_viewport().set_input_as_handled()
		return
	# Release is processed even over the menu; a lost release must never keep running.
	if event is InputEventKey and not event.pressed:
		input_rearm_keys.erase(event.physical_keycode)
		input_rearm_keys.erase(event.keycode)
	if event is InputEventKey and not event.pressed and event.physical_keycode in [KEY_A,KEY_D,KEY_LEFT,KEY_RIGHT]:
		if not (Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_RIGHT)):
			held_screen_axis=0; held_route_direction=0
	if event is InputEventScreenTouch and not event.pressed: _pointer_press(event.index,event.position,false)
	if event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed: _pointer_press(-1,event.position,false)

func _unhandled_input(event: InputEvent) -> void:
	# Also guard direct dispatch and unusual canceled+pressed platform events.
	if event is InputEventScreenTouch and event.canceled:
		_cancel_touch(event.index)
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		if active:
			focus_paused=true; rhythm_feedback.pause_audio(); _show_menu("已暂停", "继续")
		elif focus_paused: _menu_action()
		get_viewport().set_input_as_handled()
		return
	if not active: return
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode==KEY_SPACE or event.keycode==KEY_SPACE):
		if not input_rearm_keys.has(KEY_SPACE): queued_jump=true
		get_viewport().set_input_as_handled()
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
		# Releasing a movement touch never creates a new jump. Use the existing
		# upward swipe or a second finger for an explicit jump intent.
		primary_touch=-99; touch_axis=0; held_screen_axis=0; held_route_direction=0

func _cancel_touch(index: int) -> void:
	if primary_touch == index:
		_clear_input()

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
	# A key held through pause/focus-loss must be released before it can drive
	# the resumed scene. No movement or buffered jump survives a lifecycle reset.
	for key in [KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT, KEY_SPACE]:
		if Input.is_physical_key_pressed(key): input_rearm_keys[key] = true
	primary_touch=-99; touch_axis=0; queued_jump=false; swipe_used=false
	jump_buffer_ticks=0; jump_pressed_last=false
	held_screen_axis=0; held_route_direction=0

func _lose_focus() -> void:
	if not active: return
	if rhythm_feedback:rhythm_feedback.pause_audio()
	focus_paused=true
	_show_menu("已暂停，点击继续", "继续")
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE

func _story_beat() -> void:
	var n := int(floor(model.player.x / 30.6))
	if n != current_beat:
		current_beat = n
		var lines := ["", "还是四楼。", "这扇窗……刚才见过。", "楼梯怎么还没到头？", "下面的脚步声，还在。", "这次，门开着。", ""]
		subtitle.text = lines[clampi(n,0,lines.size()-1)]
		subtitle_until = model.tick+210
	subtitle.modulate.a = clampf(float(subtitle_until-model.tick)/30.0,0,1)

func _capture_frame(tick: int) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://endless_stair_captures"))
	var output := "user://endless_stair_captures/B_%04d.png" % tick
	get_viewport().get_texture().get_image().save_png(output)

func _finalize_static_stage() -> void:
	var shadow_material:=StandardMaterial3D.new()
	shadow_material.albedo_color=Color.WHITE
	shadow_material.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
	shadow_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	for group in groups:
		var sources: Array[MeshInstance3D]=[]
		for child in group.get_children():
			if child is MeshInstance3D:sources.append(child)
			elif child.name=="Architecture":
				for element in child.get_children():
					if element is MeshInstance3D:sources.append(element)
		var shadow_builder:=SurfaceTool.new()
		shadow_builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		var shadow_count:=0
		var group_boxes:Array[Dictionary]=[]
		var bounds:=AABB()
		for source in sources:
			static_mesh_instances_before+=1
			if source.has_meta("blocks_light"):
				var transform: Transform3D=source.global_transform
				var box:=source.mesh as BoxMesh
				var world_bounds:=transform*box.get_aabb()
				var cache := BeamClip.cache_box(transform,box.size*.5)
				cache["bounds"]=world_bounds
				cache["aabb_center"]=world_bounds.get_center()
				cache["aabb_half"]=world_bounds.size*.5
				blocker_cache.append(cache)
				group_boxes.append(cache)
				shadow_builder.append_from(source.mesh,0,transform)
				bounds=world_bounds if shadow_count==0 else bounds.merge(world_bounds)
				shadow_count+=1
			# Stable opaque proxy, not the growing visual, owns all shadows.
			source.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if shadow_count>0:
			var shadow:=MeshInstance3D.new()
			shadow.name="OpaqueShadow_"+str(group.name)
			shadow.mesh=shadow_builder.commit()
			shadow.material_override=shadow_material
			shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			world.add_child(shadow)
			shadow_groups.append({"node":shadow,"bounds":bounds,"solid_count":shadow_count,"boxes":group_boxes})
		_batch_static_meshes(group)
		var architecture:=group.get_node_or_null("Architecture")
		if architecture:_batch_static_meshes(architecture)
	light_occluders.clear()

func _batch_static_meshes(parent: Node3D) -> void:
	var collections: Dictionary={}
	for child in parent.get_children():
		if not child is MeshInstance3D:continue
		var key: String=str(child.get_meta("material_key"))+":"+str(child.mesh.get_rid())
		if not collections.has(key):collections[key]=[]
		collections[key].append({"node":child,"transform":child.transform,"progress":float(child.get_meta("route_at",-10000.0))})
	for parts in collections.values():
		parts.sort_custom(func(a,b):return a.progress<b.progress)
		var multimesh:=MultiMesh.new()
		multimesh.transform_format=MultiMesh.TRANSFORM_3D
		multimesh.mesh=parts[0].node.mesh
		multimesh.instance_count=parts.size()
		var node:=MultiMeshInstance3D.new()
		node.multimesh=multimesh
		node.material_override=parts[0].node.material_override
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(node)
		static_mesh_instances_after+=1
		var transforms: Array[Transform3D]=[]
		var progresses: Array[float]=[]
		for i in parts.size():
			transforms.append(parts[i].transform)
			progresses.append(parts[i].progress)
			multimesh.set_instance_transform(i,parts[i].transform)
			parent.remove_child(parts[i].node)
			parts[i].node.queue_free()
		multimesh.visible_instance_count=-1 if progresses[-1]<-9999 else 0
		visual_batches.append({"node":node,"mesh":multimesh,"transforms":transforms,"progresses":progresses,"settled_count":0,"visible_count":0,"always":progresses[-1]<-9999})

func _update_stage_reveal(_delta: float) -> void:
	highest_visual_progress=maxf(highest_visual_progress,model.player.x)
	# First visible 6.2m ahead, fully seated 4.7m ahead (1.45 seconds warning).
	# A reversed player never loses a previously built tread.
	var frontier:=highest_visual_progress+6.2
	for batch in visual_batches:
		if batch.always or int(batch.settled_count)==batch.progresses.size():continue
		var count:int=batch.visible_count
		while count<batch.progresses.size() and batch.progresses[count]<frontier:count+=1
		if count!=int(batch.visible_count):
			batch.mesh.visible_instance_count=count
			batch.visible_count=count
		var settled: int=batch.settled_count
		for i in range(settled,count):
			var amount: float=clampf((frontier-float(batch.progresses[i]))/1.5,0,1)
			var ease: float=amount*amount*(3-2*amount)
			var transform: Transform3D=batch.transforms[i]
			transform.origin.y-=.40*(1-ease)
			transform.basis.y*=maxf(.002,ease)
			batch.mesh.set_instance_transform(i,transform)
			if amount>=1:batch.settled_count=i+1
	for group in groups:
		# Opaque materials are never switched into the transparent pipeline.
		var ground_y: float=model.route_surface_height(model.player.x)
		var y: float=group.get_meta("center_y")
		var fade: float=clampf(1-absf(y-ground_y)/10,.10,1)
		if absf(fade-float(group.get_meta("fade")))>.012:
			for material in group.get_meta("materials").values():
				var color: Color=material.get_meta("base_color")
				material.albedo_color=Color(color.r*fade,color.g*fade,color.b*fade,1)
			var architecture:=group.get_node_or_null("Architecture")
			if architecture:
				for material in architecture.get_meta("materials").values():
					var color: Color=material.get_meta("base_color")
					material.albedo_color=Color(color.r*fade,color.g*fade,color.b*fade,1)
			group.set_meta("fade",fade)

func _update_floor_marker(delta: float) -> void:
	var section: Dictionary=model.route_section(model.player.x)
	var previous_alpha:=marker_alpha
	var previous_marker:=active_marker
	var requested: int=-1
	if str(section.kind)=="flight":
		var into: float=model.player.x-float(section.start)
		if into>1.0 and into<float(section.length)-1.2:requested=int(section.flight)-1
	# Old 04 completely exits before the next marker can appear.
	if requested!=active_marker:
		marker_alpha=move_toward(marker_alpha,0,delta*5 if delta>0 else 1)
		if marker_alpha<=0:active_marker=requested
	else:marker_alpha=move_toward(marker_alpha,1 if requested>=0 else 0,delta*3 if delta>0 else 1)
	if previous_marker==active_marker and is_equal_approx(previous_alpha,marker_alpha):return
	for i in floor_markers.size():
		floor_markers[i].modulate.a=marker_alpha if i==active_marker else 0
		floor_marker_captions[i].modulate.a=floor_markers[i].modulate.a

func _update_near_blockers() -> void:
	near_blockers.clear()
	var origin:=torch.global_position
	var range_squared: float=torch.spot_range*torch.spot_range
	var forward:Vector3=-torch.global_basis.z.normalized()
	var across:Vector3=forward.cross(camera.global_basis.z).normalized()
	if across.length_squared()<.000001:across=torch.global_basis.x
	var plane_normal:=forward.cross(across).normalized()
	for entry in shadow_groups:
		var group_aabb:AABB=entry.bounds
		var group_nearest:=Vector3(clampf(origin.x,group_aabb.position.x,group_aabb.end.x),clampf(origin.y,group_aabb.position.y,group_aabb.end.y),clampf(origin.z,group_aabb.position.z,group_aabb.end.z))
		var in_range:=group_nearest.distance_squared_to(origin)<=range_squared
		if entry.node.visible!=in_range:entry.node.visible=in_range
		if not in_range:continue
		for box in entry.boxes:
			var aabb:AABB=box.bounds
			var nearest:=Vector3(clampf(origin.x,aabb.position.x,aabb.end.x),clampf(origin.y,aabb.position.y,aabb.end.y),clampf(origin.z,aabb.position.z,aabb.end.z))
			if nearest.distance_squared_to(origin)>range_squared:continue
			var relative:Vector3=Vector3(box.aabb_center)-origin
			var half:Vector3=box.aabb_half
			# AABB support radius proves exclusion from the shared ribbon plane.
			# Actual SpotLight shadows still use all nearby opaque proxy geometry.
			if absf(relative.dot(plane_normal))>half.dot(plane_normal.abs())+.00001:continue
			if relative.dot(forward)+half.dot(forward.abs()) < -.00001:continue
			near_blockers.append(box)
	beam_candidate_count=near_blockers.size()
