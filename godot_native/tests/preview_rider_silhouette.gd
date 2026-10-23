extends SceneTree
## Disposable neutral-lit art comparison. No State or progression mutations.
const Rider=preload("res://scripts/presentation/chase3d/source_rider.gd")
var raw_model: Node3D
var posed_rider: Node3D
var view_index: int=0
var view_label: Label
class InputBridge extends Node:
	var fixture: SceneTree
	func _input(event: InputEvent) -> void:fixture.handle_input(event)
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.title="7:55 · 肩背检查：静止模型 / 骑行变形"
	root.size=Vector2i(1440,900)
	var scene:=Node3D.new();root.add_child(scene)
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("c9cdcf")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.7
	world.environment=env;scene.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-25,-25,0);sun.light_energy=.8;scene.add_child(sun)
	var candidate: bool="--candidate" in OS.get_cmdline_user_args()
	var original_path: String="res://docs/art/reference/student_v3/candidate/campus_student_unrigged.glb" if candidate else "res://assets/native_755/ride/rodin/campus_student_rigged.glb"
	var original: Node3D=load(original_path).instantiate()
	scene.add_child(original);original.position.x=-1.35
	var rider:=Rider.new();rider.asset_directory="res://assets/native_755/ride/"
	rider.pelican_enabled=false # This fixture compares the superseded human art only.
	if candidate:rider.human_asset_path="res://docs/art/reference/student_v3/candidate/campus_student_rigged.glb"
	scene.add_child(rider)
	raw_model=original;posed_rider=rider
	rider.position.x=1.35;rider.visual.hide();rider.apply_pose(0,0)
	for patch: Node in rider.campus_human.find_children("ZjuBackPrint","MeshInstance3D",true,false):patch.hide()
	var camera:=Camera3D.new();scene.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.2
	camera.position=Vector3(0,1.7,8);camera.look_at(Vector3(0,1.55,0));camera.make_current()
	for entry: Array in [["静止模型（未施加骑行姿态）",140],["现有骨骼骑行变形（隐藏背印）",830]]:
		var label:=Label.new();label.text=entry[0];label.position=Vector2(entry[1],65);label.add_theme_font_size_override("font_size",24);label.add_theme_color_override("font_color",Color("16272f"));root.add_child(label)
	view_label=Label.new();view_label.position=Vector2(24,15);view_label.add_theme_font_size_override("font_size",20);view_label.add_theme_color_override("font_color",Color("16272f"));root.add_child(view_label)
	var bridge:=InputBridge.new();bridge.fixture=self;root.add_child(bridge)
	update_view()
	print("SILHOUETTE_REVIEW neutral raw mesh vs existing ride pose; progression untouched")
func update_view() -> void:
	var angle: float=[0,PI,PI/2,-PI/2][view_index]
	raw_model.rotation.y=angle;posed_rider.rotation.y=angle
	view_label.text=["背面","正面","左侧","右侧"][view_index]+" · V 切换视角"
func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_V:
		view_index=(view_index+1)%4;update_view()
