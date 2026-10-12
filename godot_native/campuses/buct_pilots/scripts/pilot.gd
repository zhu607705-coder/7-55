extends Node2D
## Bounded artwork pilot. No story state or persistence authority.
const TREE_SCRIPT = preload("res://campuses/buct_pilots/scripts/layered_tree.gd")
const VISITOR_SCRIPT = preload("res://campuses/buct_pilots/scripts/campus_visitor.gd")
const ENTRY_SCENE := "res://scenes/entry.tscn"
const WALK_ACTIONS := ["buct_pilot_walk_left","buct_pilot_walk_right","buct_pilot_walk_up","buct_pilot_walk_down","buct_pilot_walk_fast"]
@export var asset_manifest_path := "res://campuses/buct_pilots/chaoyang/data/asset-contract.json"
@export var asset_root := "res://campuses/buct_pilots/chaoyang/assets/"
var visitor: CharacterBody2D
var camera: Camera2D
var actors: Node2D
var trees: Array[Node2D] = []
var guide_active := false
var tour_speed := 8.0
var route := PackedVector2Array()
var route_index := 0
var paused := false
var leaving := false
var world_size := Vector2(256,160)
var spawn := Vector2(70,127)
var config: Dictionary
var status: Label
var selected_tree: Node2D
var installed_actions: Array[String] = []
var pointer_moves: Dictionary = {}
var ui: CanvasLayer
var ui_controls: Dictionary = {}
var map_area := Rect2()

func _ready() -> void:
	config=JSON.parse_string(FileAccess.get_file_as_string(asset_manifest_path))
	world_size=Vector2(config.world_size[0],config.world_size[1])
	spawn=Vector2(config.spawn[0],config.spawn[1])
	var required: Array[String]=[str(config.ground)]
	for item in config.objects:
		for key in ["canopy","trunk","shadow"]:required.append(str(item[key]))
	for path in required:
		if not ResourceLoader.exists(asset_root+path):
			push_error("Missing pilot artwork: "+path)
			return_to_entry()
			return
	_install_inputs()
	var ground:=Sprite2D.new();ground.name="ContinuousReconstructedGround";ground.centered=false
	ground.texture=load(asset_root+str(config.ground));ground.scale=world_size/ground.texture.get_size()
	ground.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;ground.z_index=-10;add_child(ground)
	var shadows:=Node2D.new();shadows.name="IndependentGroundShadows";shadows.z_index=-5;add_child(shadows)
	actors=Node2D.new();actors.name="DepthSortedTrunksCrownsAndVisitor";actors.y_sort_enabled=true;add_child(actors)
	for item in config.objects:
		var tree:=Node2D.new();tree.set_script(TREE_SCRIPT);actors.add_child(tree)
		tree.configure(item,shadows,asset_root);trees.append(tree)
	visitor=CharacterBody2D.new();visitor.set_script(VISITOR_SCRIPT);visitor.map=self
	visitor.scale=Vector2.ONE;visitor.speed=8.0;visitor.position=spawn;actors.add_child(visitor)
	camera=Camera2D.new();camera.name="PilotCamera";camera.position=world_size*0.5;add_child(camera)
	_build_ui();get_viewport().size_changed.connect(_fit_view);_fit_view()

func _install_inputs() -> void:
	var keys={"buct_pilot_walk_left":[KEY_A,KEY_LEFT],"buct_pilot_walk_right":[KEY_D,KEY_RIGHT],"buct_pilot_walk_up":[KEY_W,KEY_UP],"buct_pilot_walk_down":[KEY_S,KEY_DOWN],"buct_pilot_walk_fast":[KEY_SHIFT]}
	for action in keys:
		if InputMap.has_action(action):continue
		InputMap.add_action(action);installed_actions.append(action)
		for key in keys[action]:
			var event:=InputEventKey.new();event.physical_keycode=key;InputMap.action_add_event(action,event)

func _button(key: String,text: String,action: Callable) -> Button:
	var button:=Button.new();button.name=key;button.text=text
	button.pressed.connect(action);ui.add_child(button);ui_controls[key]=button
	button.add_theme_font_override("font",load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"))
	button.add_theme_font_size_override("font_size",16)
	return button

func _label(key: String,text: String) -> Label:
	var label:=Label.new();label.text=text;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"))
	label.add_theme_font_size_override("font_size",16);label.add_theme_color_override("font_color",Color("34584a"))
	ui.add_child(label);ui_controls[key]=label;return label

func _build_ui() -> void:
	ui=CanvasLayer.new();ui.name="PilotControls";ui.layer=10;add_child(ui)
	for key in ["top","bottom"]:
		var panel:=ColorRect.new();panel.color=Color("f1f0e5");ui.add_child(panel);ui_controls[key]=panel
	_label("title","朝阳中央步道 · 两株分层试点")
	_button("back","返回入口",return_to_entry)
	_button("guide","绕树导览",start_guide)
	_button("select","选择下一株",select_next)
	_button("left_crown","树冠左摆",nudge_selected.bind(-0.035))
	_button("right_crown","树冠右摆",nudge_selected.bind(0.035))
	_button("wind","暂停微风",toggle_wind)
	_button("reset","复位",reset_demo)
	status=_label("status","点选树冠/树干 · WASD 或按住方向按钮行走")
	for item in [["left","←",Vector2.LEFT],["up","↑",Vector2.UP],["down","↓",Vector2.DOWN],["right","→",Vector2.RIGHT]]:
		var button:=_button(item[0],item[1],func():pass);button.focus_mode=Control.FOCUS_NONE
		button.gui_input.connect(_movement_gui_input.bind(item[2]))
	_refresh_selection_controls()

func _fit_view() -> void:
	if not is_instance_valid(camera) or ui_controls.is_empty():return
	var size:=get_viewport_rect().size
	var narrow:=size.x<600
	var bottom_height:=180.0 if narrow else 128.0
	var top_height:=64.0
	ui_controls.top.position=Vector2.ZERO;ui_controls.top.size=Vector2(size.x,top_height)
	ui_controls.bottom.position=Vector2(0,size.y-bottom_height);ui_controls.bottom.size=Vector2(size.x,bottom_height)
	ui_controls.title.position=Vector2(12,12);ui_controls.title.size=Vector2(size.x-128,42)
	ui_controls.title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	ui_controls.title.text="朝阳步道 · 两株试点" if narrow else str(config.title)
	ui_controls.back.position=Vector2(size.x-108,10);ui_controls.back.size=Vector2(96,44)
	var keys: Array[String]=["guide","select","left_crown","right_crown","wind","reset"]
	var columns:=3 if narrow else 6
	var width: float=(size.x-24.0-6.0*(columns-1))/columns
	for i in range(keys.size()):
		var button: Button=ui_controls[keys[i]]
		button.position=Vector2(12+(i%columns)*(width+6),size.y-bottom_height+8+(i/columns)*50)
		button.size=Vector2(width,44)
	var direction_y:=size.y-68.0
	for i in range(4):
		var key: String=["left","up","down","right"][i]
		ui_controls[key].position=Vector2((size.x-194)/2+i*50,direction_y)
		ui_controls[key].size=Vector2(44,44)
	status.position=Vector2(12,size.y-22);status.size=Vector2(size.x-24,20)
	status.add_theme_font_size_override("font_size",13 if narrow else 15)
	status.clip_text=true
	map_area=Rect2(10,top_height+4,maxf(1,size.x-20),maxf(1,size.y-top_height-bottom_height-8))
	var fit:=minf(map_area.size.x/world_size.x,map_area.size.y/world_size.y)
	camera.zoom=Vector2.ONE*fit
	camera.offset=(size*0.5-map_area.get_center())/fit
	camera.force_update_scroll()

func walk_input() -> Vector2:
	var direction:=Input.get_vector("buct_pilot_walk_left","buct_pilot_walk_right","buct_pilot_walk_up","buct_pilot_walk_down")
	for value in pointer_moves.values():direction+=value
	return direction.limit_length()

func _movement_gui_input(event: InputEvent,direction: Vector2) -> void:
	if paused or leaving:return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:pointer_moves["mouse"]=direction
		else:pointer_moves.erase("mouse")
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed:pointer_moves[event.index]=direction
		else:pointer_moves.erase(event.index)
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	# Releases must still stop walking after the pointer leaves a button.
	if event is InputEventMouseButton and not event.pressed:pointer_moves.erase("mouse")
	elif event is InputEventScreenTouch and not event.pressed:pointer_moves.erase(event.index)
	# Space is the documented wind shortcut, even after a toolbar button has
	# keyboard focus. Enter remains available for normal button activation.
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_SPACE:
		if not movement_paused() and not trees.is_empty():
			toggle_wind();get_viewport().set_input_as_handled()

func movement_paused() -> bool:return paused or leaving

func is_walkable(point: Vector2) -> bool:
	var on_paving:=false
	for rect in config.paving_rects:
		if Rect2(rect[0],rect[1],rect[2],rect[3]).has_point(point):on_paving=true;break
	if not on_paving:return false
	for tree in trees:
		if tree.visible and point.distance_to(tree.position)<4.1:return false
	return true

func notify_boundary() -> void:pass

func cancel_route_for_manual_input() -> void:
	guide_active=false;route.clear()

func route_direction(point: Vector2) -> Vector2:
	if not guide_active or route_index>=route.size():return Vector2.ZERO
	if point.distance_to(route[route_index])<=1.0:
		route_index+=1
		if route_index>=route.size():guide_active=false;return Vector2.ZERO
	return point.direction_to(route[route_index])

func start_guide() -> void:
	if leaving:return
	_release_movement();visitor.stop_motion(true);visitor.position=spawn;route.clear()
	for point in config.route:route.append(Vector2(point[0],point[1]))
	route_index=0;guide_active=true

func reset_demo() -> void:
	_release_movement();visitor.stop_motion(true);visitor.position=spawn
	for tree in trees:tree.reset_pose()
	select_at(Vector2(-1,-1));ui_controls.wind.text="开启微风"

func toggle_wind() -> void:
	var enabled: bool=not trees[0].wind_enabled
	for tree in trees:tree.wind_enabled=enabled
	ui_controls.wind.text="暂停微风" if enabled else "开启微风"

func nudge_selected(angle: float) -> void:
	if is_instance_valid(selected_tree):selected_tree.nudge_crown(angle)

func select_next() -> void:
	var index:=trees.find(selected_tree)
	_set_selection(trees[(index+1)%trees.size()])

func select_at(point: Vector2) -> void:
	var selected: Node2D=null
	for tree in trees:
		if tree.hit_test_world(point):selected=tree
	_set_selection(selected)

func _set_selection(value: Node2D) -> void:
	selected_tree=value
	for tree in trees:tree.set_selected(tree==value)
	status.text="已选树：树冠可摆动，树干与地影独立" if value!=null else "点选树冠/树干 · WASD 或按住方向按钮行走"
	_refresh_selection_controls()

func _refresh_selection_controls() -> void:
	for key in ["left_crown","right_crown"]:ui_controls[key].disabled=not is_instance_valid(selected_tree)

func _unhandled_input(event: InputEvent) -> void:
	if movement_paused():return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		if map_area.has_point(event.position):select_at(get_canvas_transform().affine_inverse()*event.position)
	elif event is InputEventScreenTouch and event.pressed:
		if map_area.has_point(event.position):select_at(get_canvas_transform().affine_inverse()*event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_G:start_guide()
			KEY_R:reset_demo()
			KEY_Q:nudge_selected(-0.035)
			KEY_E:nudge_selected(0.035)
			KEY_ESCAPE:
				if guide_active:cancel_route_for_manual_input()
				elif selected_tree!=null:_set_selection(null)
				else:return_to_entry()

func _release_movement() -> void:
	pointer_moves.clear();cancel_route_for_manual_input()
	for action in WALK_ACTIONS:
		if InputMap.has_action(action):Input.action_release(action)
	if is_instance_valid(visitor):visitor.stop_motion()

func return_to_entry() -> void:
	if leaving:return
	leaving=true;_release_movement();_change_to_entry.call_deferred()

func _change_to_entry() -> void:
	var error:=get_tree().change_scene_to_file(ENTRY_SCENE)
	if error!=OK:leaving=false;push_error("Cannot return to entry: %s"%error)

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:paused=true;_release_movement()
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN:paused=false

func _exit_tree() -> void:
	_release_movement()
	for action in installed_actions:
		if InputMap.has_action(action):InputMap.erase_action(action)
