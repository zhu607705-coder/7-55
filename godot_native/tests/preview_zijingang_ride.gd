extends SceneTree
## Isolated visual fixture: actual production controls/model, no story completion.
## Not exported. F1..F4 inspect scenic stages without changing a campaign save.
const Host=preload("res://scripts/ui/minigame_host.gd")
var game: Control
var inspecting: bool=false
var seconds: float=0
var hidden_for_inspection: Array[CanvasItem]=[]
var camera_view: int=0
class InputBridge extends Node:
	var fixture: SceneTree
	func _input(event: InputEvent) -> void:fixture.handle_input(event)
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.title="7:55 · 紫金港骑行场景验收"
	root.size=Vector2i(1280,800)
	game=Host.new();game.setup({"type":"chase","title":"755 米 · 紫金港骑行"});root.add_child(game)
	game.configure_activity_layout(Vector2(root.size),false)
	root.size_changed.connect(func():game.configure_activity_layout(Vector2(root.size),root.size.x<1000))
	game.cancelled.connect(func():quit())
	game.finished.connect(func(_result):pass)
	var input_bridge:=InputBridge.new();input_bridge.fixture=self;root.add_child(input_bridge)
	# Default diagnostic view exposes the actual production skin and bicycle.
	set_inspection(true)
func set_inspection(enabled: bool) -> void:
	inspecting=enabled;game.set_process(not enabled)
	if enabled:
		hidden_for_inspection.clear()
		for child: Node in game.get_children():
			if child is CanvasItem and child!=game.native_chase_view and child.visible:
				hidden_for_inspection.append(child);child.hide()
	else:
		for child: CanvasItem in hidden_for_inspection:
			if is_instance_valid(child):child.show()
		hidden_for_inspection.clear();game.restart()
func _process(delta: float) -> bool:
	if not inspecting or not is_instance_valid(game):return false
	seconds+=minf(delta,.05)
	var view: Control=game.native_chase_view
	view.update_view(game.model,minf(delta,.05),false,true)
	view.hero.apply_pose(sin(seconds*.5)*.14,seconds*3.0)
	view.hero.spin_wheels(-seconds*6.6)
	var camera_offset: Vector3=[Vector3(4.3,2.3,2.6),Vector3(2.6,2.4,-4.5),Vector3(-1.3,2.5,4.8)][camera_view]
	view.camera.position=view.hero.position+camera_offset
	view.camera.look_at(view.hero.position+Vector3(0,1.5,0));view.camera.fov=38
	view.viewport3d.render_target_update_mode=SubViewport.UPDATE_ONCE
	return false
func handle_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	if event.keycode==KEY_V:camera_view=(camera_view+1)%3;return
	if event.keycode in [KEY_F6,KEY_F7,KEY_F8]:camera_view=[KEY_F6,KEY_F7,KEY_F8].find(event.keycode);return
	if event.keycode in [KEY_F5,KEY_P]:
		set_inspection(not inspecting)
		return
	var index: int=[KEY_F1,KEY_F2,KEY_F3,KEY_F4].find(event.keycode)
	if index<0:index=[KEY_1,KEY_2,KEY_3,KEY_4].find(event.keycode)
	if index<0:return
	game.restart();game.model.distance=[0,230,430,680][index];game.model.tick=int(game.model.distance)*120
	game.native_chase_view.update_view(game.model,0,false,false)
	game._refresh()
