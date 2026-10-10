extends SubViewportContainer
## Read-only renderer of the approved Blender low-glow lamp. The closure owns time.
## No input, save, audio, progression, or independent process loop belongs here.
const MODEL_PATH := "res://assets/native/canruo/canruo_star_lamp_lowglow_LOD1.glb"
const CAMERA_START := Vector3(0.5, 0.5, 7.9)
const CAMERA_END := Vector3(0.5, 1.7, 6.4)
const TARGET_START := Vector3(0.0, 6.12, 0.0)
const TARGET_END := Vector3(0.0, 7.12, 0.0)
const VERTICAL_FOV := 29.839371711
const STAR_COUNT := 640
const LED_NAME := "MAT_LED_Warm"
const CORE_NAME := "MAT_Core_Ivory"
const SPILL_SHADER = preload("res://scripts/presentation/chapter4_lamp_spill.gdshader")
const LED_EMISSION_PEAK := 6.0
const CORE_EMISSION_PEAK := 5.0
const SPILL_STRENGTHS := {"MAT_CageSteel": 0.8, "MAT_SilverSatin": 0.65, "MAT_DarkTrim": 0.22, "MAT_CoreSeams": 0.28}
var viewport: SubViewport
var scene: Node3D
var model: Node3D
var camera: Camera3D
var environment: Environment
var stars: MultiMeshInstance3D
var materials: Dictionary = {}
var imported_materials: Dictionary = {}
var spill_materials: Dictionary = {}
var lit_albedos: Dictionary = {}
var mesh_count := 0
var triangle_count := 0
var available := false
var disposed := false
var update_count := 0
var last_frame: Dictionary = {}
var last_visual_frame: Dictionary = {}
var last_stage := ""
var last_size := Vector2.ZERO
var force_redraw := true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	stretch = true
	viewport = SubViewport.new()
	viewport.name = "LampRenderViewport"
	viewport.own_world_3d = true
	viewport.gui_disable_input = true
	viewport.handle_input_locally = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	# Full-resolution rendering is retained. Supersampled per-pixel lighting was
	# the measured software-renderer bottleneck, not the instanced star geometry.
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	add_child(viewport)
	scene = Node3D.new()
	scene.name = "CanruoScene"
	viewport.add_child(scene)
	_build_environment()
	_build_stars()
	camera = Camera3D.new()
	camera.name = "ReferenceLowAngleCamera"
	camera.near = 0.05
	camera.far = 140.0
	camera.current = true
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	scene.add_child(camera)
	var packed := load(MODEL_PATH) as PackedScene
	if packed == null:
		return
	model = packed.instantiate() as Node3D
	if model == null:
		return
	model.name = "BlenderLampLOD1"
	scene.add_child(model)
	_bind_materials(model)
	available = materials.has(LED_NAME) and materials.has(CORE_NAME) and mesh_count == 14
	resized.connect(func(): force_redraw = true)

func _build_environment() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.003, 0.006, 0.020)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.36, 0.46, 0.62)
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# Compatibility has no post-process Glow. Brightness belongs to the actual
	# luminous surfaces and bounded warm reflection on nearby metal. No broad
	# halo, exposure lift, or extra point-light passes are needed. The original
	# directional key still reveals the genuine metal geometry.
	environment.glow_enabled = false
	var world := WorldEnvironment.new()
	world.environment = environment
	scene.add_child(world)
	var key := DirectionalLight3D.new()
	key.name = "SilhouetteKey"
	key.rotation_degrees = Vector3(-35, -35, 0)
	key.light_color = Color(0.72, 0.82, 1.0)
	key.light_energy = 0.65
	key.shadow_enabled = false
	scene.add_child(key)

func _build_stars() -> void:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.045, 0.045)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(0.68, 0.78, 1.0)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material = material
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = STAR_COUNT
	var rng := RandomNumberGenerator.new()
	rng.seed = 7552026
	for i in STAR_COUNT:
		var origin := Vector3(rng.randf_range(-40, 40), rng.randf_range(-12, 36), rng.randf_range(-65, -18))
		var scale_value := rng.randf_range(0.5, 1.7)
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale_value), origin))
		var brightness := rng.randf_range(0.45, 1.0)
		multi.set_instance_color(i, Color(brightness, brightness, brightness, 1))
	stars = MultiMeshInstance3D.new()
	stars.name = "SeededDepthStars"
	stars.multimesh = multi
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene.add_child(stars)

func _bind_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_count += 1
		for surface in instance.mesh.get_surface_count():
			var indices: int = instance.mesh.surface_get_array_index_len(surface)
			triangle_count += (indices if indices > 0 else instance.mesh.surface_get_array_len(surface)) / 3
			var source := instance.get_active_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var key := source.resource_name
			if not materials.has(key):
				var local := source.duplicate(true) as StandardMaterial3D
				local.resource_local_to_scene = true
				# The reviewed mesh is closed and opaque. Blender's exported default
				# doubleSided flag needlessly shades invisible backs of the cage rods.
				local.cull_mode = BaseMaterial3D.CULL_BACK
				if key in [LED_NAME, CORE_NAME]:
					local.emission_enabled = true
					local.emission = (Color(1.0, 0.91, 0.72) if key == LED_NAME else Color(1.0, 0.85, 0.56)).linear_to_srgb()
					local.emission_energy_multiplier = 0.0
				materials[key] = local
				imported_materials[key] = source
				lit_albedos[key] = source.albedo_color.srgb_to_linear()
				if SPILL_STRENGTHS.has(key):
					var spill := ShaderMaterial.new()
					spill.shader = SPILL_SHADER
					spill.resource_local_to_scene = true
					spill.set_shader_parameter("surface_color", local.albedo_color)
					spill.set_shader_parameter("surface_metallic", local.metallic)
					spill.set_shader_parameter("surface_roughness", local.roughness)
					spill.set_shader_parameter("spill_strength", SPILL_STRENGTHS[key])
					spill_materials[key] = spill
			instance.set_surface_override_material(surface, spill_materials.get(key, materials[key]))
	for child in node.get_children():
		_bind_materials(child)

func apply_frame(frame: Dictionary, stage: String) -> void:
	if disposed or not available or size.x < 2 or size.y < 2:
		return
	# Caption and unused legacy PNG/glow curves do not dirty the 3D scene.
	# The reveal opacity is a 2D composite and does not require another mesh pass.
	modulate = Color(1, 1, 1, float(frame.reveal) if stage == "playback" else (1.0 if stage == "final" else 0.30))
	last_frame = frame.duplicate()
	var visual_frame := {"rise":float(frame.rise),"led":float(frame.led),"core":float(frame.core)}
	if not force_redraw and visual_frame == last_visual_frame and stage == last_stage and size == last_size:
		return
	last_visual_frame = visual_frame
	last_stage = stage
	last_size = size
	force_redraw = false
	var rise := float(frame.rise)
	camera.position = CAMERA_START.lerp(CAMERA_END, rise)
	camera.look_at(TARGET_START.lerp(TARGET_END, rise), Vector3.UP)
	# Widen the vertical field only when a narrow viewport would clip the cage.
	var aspect := size.x / size.y
	var fit_tangent := maxf(tan(deg_to_rad(VERTICAL_FOV) * 0.5), 0.155 / maxf(0.1, aspect))
	camera.fov = rad_to_deg(atan(fit_tangent)) * 2.0
	var led := clampf(float(frame.led) / 0.7, 0, 1)
	var core := clampf(float(frame.core) / 0.62, 0, 1)
	materials[LED_NAME].emission_energy_multiplier = led * LED_EMISSION_PEAK
	materials[CORE_NAME].emission_energy_multiplier = core * CORE_EMISSION_PEAK
	materials[LED_NAME].albedo_color = Color(0.14, 0.17, 0.19).lerp(lit_albedos[LED_NAME], led).linear_to_srgb()
	materials[CORE_NAME].albedo_color = Color(0.42, 0.46, 0.50).lerp(lit_albedos[CORE_NAME], core).linear_to_srgb()
	for material in spill_materials.values():
		material.set_shader_parameter("lamp_on", maxf(led * 0.30, core))
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	update_count += 1

func dispose() -> void:
	disposed = true
	if is_instance_valid(viewport):
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	set_process(false)

func _exit_tree() -> void:
	dispose()
