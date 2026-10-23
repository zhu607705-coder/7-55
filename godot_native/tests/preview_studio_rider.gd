extends SceneTree
## Production rider and bicycle on a neutral art-review floor; no game State.
const Rider=preload("res://scripts/presentation/chase3d/source_rider.gd")
var rider: Node3D
var camera: Camera3D
var seconds: float=0
var pose_paused: bool=false
var view_index: int=2
var caption: Label
class InputBridge extends Node:
	var fixture: SceneTree
	func _input(event: InputEvent) -> void:fixture.handle_input(event)
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.title="7:55 · 重建人物与骑行骨骼"
	root.size=Vector2i(1440,900)
	var scene:=Node3D.new();root.add_child(scene)
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("c9cdcf")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.65
	world.environment=env;scene.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-30,0);sun.light_energy=1.4;sun.shadow_enabled=true;scene.add_child(sun)
	var floor_mesh:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(200,200);floor_mesh.mesh=plane
	var floor_material:=StandardMaterial3D.new();floor_material.albedo_color=Color("c9cdcf");floor_material.roughness=1;floor_mesh.material_override=floor_material;floor_mesh.position.y=-.015;scene.add_child(floor_mesh)
	rider=Rider.new();rider.asset_directory="res://assets/native_755/ride/";scene.add_child(rider)
	camera=Camera3D.new();scene.add_child(camera);camera.fov=38;camera.make_current()
	caption=Label.new();caption.position=Vector2(28,24);caption.add_theme_font_size_override("font_size",22);caption.add_theme_color_override("font_color",Color("16272f"));root.add_child(caption)
	var input_bridge:=InputBridge.new();input_bridge.fixture=self;root.add_child(input_bridge)
	update_camera()
func _process(delta: float) -> bool:
	if rider==null:return false
	if not pose_paused:seconds+=minf(delta,.05)
	rider.apply_pose(sin(seconds*.5)*.12,seconds*3)
	rider.spin_wheels(-seconds*6.6)
	return false
func update_camera() -> void:
	camera.position=[Vector3(4.3,2.2,3.4),Vector3(2.2,2.4,-4.7),Vector3(-1,2.6,5.5),Vector3(5,2.1,0)][view_index]
	camera.look_at(Vector3(0,1.4,0))
	caption.text=["侧后","正面","背面","侧面"][view_index]+" · V 切换视角 · 空格暂停"
func handle_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	if event.keycode==KEY_V:view_index=(view_index+1)%4;update_camera()
	elif event.keycode==KEY_SPACE:pose_paused=not pose_paused
