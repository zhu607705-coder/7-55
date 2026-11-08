extends Node3D
const Model=preload("res://campuses/campus_letter/scripts/experience_model.gd")
const World=preload("res://campuses/campus_letter/scripts/world_3d.gd")
const FONT=preload("res://ui_assets/fonts/SelectedCoverage-Regular.otf")
const Pad=preload("res://campuses/campus_letter/scripts/navigation_pad.gd")
const TITLES={"library":"空着的座位","liuhu":"柳湖交接","bridge":"纸桥来信","light":"母校之光"}
const HELP={"library":"查看座位状态，点击预约终端，再把校园卡拖到感应区。点击自己的椅子坐下；拨动摇杆或点地面即可起身，再回终端结束使用。","liuhu":"拖动岸边方向轮与俯仰轮，使三个浮环回到观测位置。对齐后逐个记录；被装置遮住的点位可以换个位置观察。","bridge":"拖动两个支点调整跨度，点击纸面折起两侧。把三枚砝码分别拖到桥面；桌旁的托盘可以收回砝码。","light":"沿轨道拖动灯座，把投影对入墙上刻线。走到左侧观察位置，拿起旁边的来信，投入装置旁的信箱。"}
var model:=Model.new()
var world: Node3D
var camera: Camera3D
var hud: Control
var message_label: Label
var object_label: Label
var progress_label: Label
var title_label: Label
var help_panel: PanelContainer
var tabs: Dictionary={}
var pointer: int=-2
var picked: String=""
var snapshot: Dictionary={}
var start_screen:=Vector2.ZERO
var last_screen:=Vector2.ZERO
var start_world:=Vector3.ZERO
var object_origin:=Vector3.ZERO
var initial_value: float=0
var has_dragged:=false
var orbit_start:=Vector3.ZERO
var camera_home:=Vector3.ZERO
var ui_scale: float=1
var report_clock: float=0
var player: CharacterBody3D
var overview:bool=false
var view_button:Button
var restart_button:Button
var help_button:Button
var pad:Control
var pad_direction:=Vector2.ZERO
var fp_yaw:float=0
var fp_pitch:float=0
var look_start:=Vector2.ZERO
var move_target:=Vector3.INF
var press_floor:=Vector3.INF
var drag_height:float=0
var eye_height:float=1.65
var seated:bool=false

func _ready() -> void:
	var env:=WorldEnvironment.new();env.name="CampusDaylight"
	var e:=Environment.new();e.background_mode=Environment.BG_SKY
	var sky:=Sky.new();var atmosphere:=ProceduralSkyMaterial.new()
	atmosphere.sky_top_color=Color("7598b3");atmosphere.sky_horizon_color=Color("c5d2d3")
	atmosphere.ground_bottom_color=Color("596257");atmosphere.ground_horizon_color=Color("b6c3bd")
	atmosphere.sun_angle_max=5.0;sky.sky_material=atmosphere;e.sky=sky
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("a2acae");e.ambient_light_energy=.26;e.ambient_light_sky_contribution=0.0
	e.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode=Environment.TONE_MAPPER_ACES;e.tonemap_exposure=.9
	env.environment=e;add_child(env)
	var sun:=DirectionalLight3D.new();sun.name="AfternoonSun";sun.rotation_degrees=Vector3(-38,-32,0);sun.light_color=Color("fff8ec");sun.light_energy=.42;sun.shadow_enabled=true;sun.directional_shadow_max_distance=35;sun.shadow_blur=4;sun.light_angular_distance=2.0
	add_child(sun)
	camera=Camera3D.new();camera.name="PerspectiveCamera";camera.current=true;camera.fov=43;camera.near=.08;camera.far=90;add_child(camera)
	player=CharacterBody3D.new();player.name="FirstPersonBody";player.collision_layer=4;player.collision_mask=1;add_child(player)
	var capsule:=CapsuleShape3D.new();capsule.radius=.22;capsule.height=1.6
	var collision:=CollisionShape3D.new();collision.shape=capsule;collision.position.y=.8;player.add_child(collision)
	_create_ui()
	get_viewport().size_changed.connect(_layout)
	get_window().size_changed.connect(_window_resized)
	open_sample("light")
	_layout()
	if OS.has_feature("web"):JavaScriptBridge.eval("window.campusLetterReady = true",true)

func _style(bg: String,border: String="",pad: int=12) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=Color(bg);s.corner_radius_top_left=5;s.corner_radius_top_right=5;s.corner_radius_bottom_left=5;s.corner_radius_bottom_right=5
	s.content_margin_left=pad;s.content_margin_right=pad;s.content_margin_top=8;s.content_margin_bottom=8
	if not border.is_empty():s.border_color=Color(border);s.set_border_width_all(1)
	return s

func _button(parent: Node, words: String, action: Callable) -> Button:
	var b:=Button.new();b.text=words;b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;b.custom_minimum_size=Vector2(88,40);b.pressed.connect(action)
	for state_color:String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
		b.add_theme_color_override(state_color,Color("24464c"))
	b.add_theme_color_override("font_disabled_color",Color("596b69"))
	b.add_theme_stylebox_override("normal",_style("e7e8dd"));b.add_theme_stylebox_override("hover",_style("ffffff"));b.add_theme_stylebox_override("pressed",_style("c1d3cc"));b.add_theme_stylebox_override("focus",_style("d1dfd9","26636a"))
	parent.add_child(b);return b

func _create_ui() -> void:
	var layer:=CanvasLayer.new();add_child(layer)
	hud=Control.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(hud)
	var theme_:=Theme.new();theme_.default_font=FONT;theme_.default_font_size=18;theme_.set_color("font_color","Button",Color("24464c"));hud.theme=theme_
	var top:=PanelContainer.new();top.name="Header";top.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_theme_stylebox_override("panel",_style("00000000"));hud.add_child(top)
	var row:=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_theme_constant_override("separation",16);top.add_child(row)
	var brand:=VBoxContainer.new();brand.name="Brand";brand.custom_minimum_size.x=165;row.add_child(brand);brand.hide()
	title_label=Label.new();title_label.add_theme_color_override("font_color",Color("23464d"));title_label.add_theme_font_size_override("font_size",25);brand.add_child(title_label)
	var sub:=Label.new();sub.text="7:55  /  校园来信";sub.add_theme_color_override("font_color",Color("52665f"));sub.add_theme_font_size_override("font_size",13);brand.add_child(sub)
	var space:=Control.new();space.mouse_filter=Control.MOUSE_FILTER_IGNORE;space.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(space)
	for id: String in Model.IDS:
		tabs[id]=_button(row,TITLES[id],open_sample.bind(id));tabs[id].custom_minimum_size.x=100
	view_button=_button(row,"场景总览",_toggle_view);view_button.custom_minimum_size.x=100
	restart_button=_button(row,"重来",_restart);restart_button.custom_minimum_size.x=60
	help_button=_button(row,"?",_help);help_button.custom_minimum_size.x=42
	var bottom:=PanelContainer.new();bottom.name="Feedback";bottom.add_theme_stylebox_override("panel",_style("183b43ed"));hud.add_child(bottom)
	var feed:=HBoxContainer.new();feed.add_theme_constant_override("separation",18);bottom.add_child(feed)
	progress_label=Label.new();progress_label.custom_minimum_size=Vector2(190,48);progress_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;progress_label.add_theme_font_size_override("font_size",15);progress_label.add_theme_color_override("font_color",Color("d7bc83"));feed.add_child(progress_label)
	message_label=Label.new();message_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;message_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;message_label.custom_minimum_size=Vector2(860,48);message_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;message_label.add_theme_color_override("font_color",Color("f1f0e6"));feed.add_child(message_label)
	object_label=Label.new();object_label.name="ObjectCaption";object_label.add_theme_color_override("font_color",Color("ffffff"));object_label.add_theme_color_override("font_shadow_color",Color("153139"));object_label.add_theme_constant_override("shadow_offset_x",1);object_label.add_theme_constant_override("shadow_offset_y",2);object_label.add_theme_font_size_override("font_size",18);object_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(object_label)
	help_panel=PanelContainer.new();help_panel.name="Help";help_panel.add_theme_stylebox_override("panel",_style("eff0e9"));hud.add_child(help_panel);help_panel.visible=false
	var helpbox:=VBoxContainer.new();helpbox.add_theme_constant_override("separation",16);help_panel.add_child(helpbox)
	var h:=Label.new();h.text="物件就在场景里";h.add_theme_font_size_override("font_size",24);h.add_theme_color_override("font_color",Color("24464c"));helpbox.add_child(h)
	var copy:=Label.new();copy.name="Copy";copy.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;copy.add_theme_color_override("font_color",Color("24464c"));helpbox.add_child(copy)
	_button(helpbox,"回到场景",func():help_panel.hide())
	var tip:=Label.new();tip.name="OrbitTip";tip.text="第一人称 · 拖动空白处转头 · 点地面或拨动摇杆行走";tip.add_theme_font_size_override("font_size",13);tip.add_theme_color_override("font_color",Color("294c50"));hud.add_child(tip)
	pad=Pad.new();pad.name="WalkJoystick";pad.direction_changed.connect(func(v:Vector2):pad_direction=v;move_target=Vector3.INF);hud.add_child(pad);pad.size=Vector2(132,132)
	# The current presentation intentionally has no explanatory text by default.
	bottom.hide();tip.hide();object_label.hide();help_button.hide()

func _layout() -> void:
	if not is_instance_valid(hud):return
	var size_:Vector2=get_viewport().get_visible_rect().size
	var compact:bool=DisplayServer.window_get_size().x<1000
	var header:=hud.get_node("Header") as Control;header.position=Vector2(20,16);header.size=Vector2(size_.x-40,88 if compact else 58)
	var row:HBoxContainer=header.get_child(0);row.get_node("Brand").hide()
	for child:Node in row.get_children():
		if child is Button:
			child.add_theme_font_size_override("font_size",25 if compact else 18)
			child.custom_minimum_size.y=62 if compact else 40
	for id:String in tabs:tabs[id].custom_minimum_size.x=144 if compact else 100
	view_button.custom_minimum_size.x=190 if compact else 100
	message_label.add_theme_font_size_override("font_size",23 if compact else 18)
	progress_label.add_theme_font_size_override("font_size",21 if compact else 15)
	var footer:=hud.get_node("Feedback") as Control;footer.position=Vector2(20,size_.y-(120 if compact else 83));footer.size=Vector2(size_.x-40,100 if compact else 64)
	help_panel.position=Vector2(size_.x/2-230,size_.y/2-140);help_panel.size=Vector2(460,250)
	(hud.get_node("OrbitTip") as Control).position=Vector2(25,93)
	pad.position=Vector2(22,size_.y-154)

func _window_resized() -> void:
	cancel_drag();move_target=Vector3.INF
	if is_instance_valid(pad):pad.reset()
	_layout()

func open_sample(id: String) -> void:
	cancel_drag()
	pad.reset()
	if is_instance_valid(world):remove_child(world);world.queue_free()
	model.enter(id);world=World.new();world.name="World_"+id;add_child(world);world.build(model)
	var sun:=get_node("AfternoonSun") as DirectionalLight3D
	sun.light_energy=.15 if id=="light" else .42
	sun.rotation_degrees=Vector3(-32,-155,0) if id in ["library","bridge"] else Vector3(-38,-32,0)
	var env:Environment=get_node("CampusDaylight").environment
	env.ambient_light_energy=.24 if id=="light" else (.38 if id in ["library","bridge"] else .26)
	overview=false;seated=false;player.position=world.eye_start-Vector3(0,1.65,0);player.position.y=.02;player.velocity=Vector3.ZERO;move_target=Vector3.INF;eye_height=1.65
	camera.position=world.eye_start;camera.fov=66;camera.look_at(world.eye_target,Vector3.UP);fp_yaw=camera.rotation.y;fp_pitch=camera.rotation.x
	_apply_view()
	title_label.text=TITLES[id];help_panel.hide();object_label.text=""
	for key: String in tabs:tabs[key].add_theme_stylebox_override("normal",_style("cbded6" if key==id else "e7e8dd"))
	_update_feedback()

func _toggle_view() -> void:
	cancel_drag();pad.reset();move_target=Vector3.INF;overview=not overview;_apply_view()

func _apply_view() -> void:
	view_button.text="返回第一人称" if overview else "场景总览"
	pad.visible=not overview
	if world.has_node("RoomShell"):world.get_node("RoomShell").visible=not overview
	(hud.get_node("OrbitTip") as Label).text="场景总览 · 拖动空白处环视 · 返回第一人称后操作物件" if overview else "第一人称 · 拖动空白处转头 · 点地面或拨动摇杆行走"
	if overview:camera.fov=43;camera.position=world.camera_position;camera.look_at(world.camera_target,Vector3.UP)
	else:camera.fov=66;camera.position=player.position+Vector3(0,eye_height,0);camera.rotation=Vector3(fp_pitch,fp_yaw,0)

func show_home() -> void:open_sample("light")
func _restart() -> void:
	model.completed.erase(model.active);open_sample(model.active)
func _help() -> void:
	help_panel.get_node("VBoxContainer/Copy").text=HELP[model.active]+"\n\n第一人称操作；点地面或使用摇杆走近物件。拖动空白处转头。场景总览用于查看布局。"
	help_panel.visible=not help_panel.visible

func _update_feedback() -> void:
	message_label.text=model.message
	progress_label.text="来信已完成" if model.completed.has(model.active) else "正在探索"
	world.sync()
	if OS.has_feature("web"):
		var snapshot_ := {"active":model.active,"complete":model.completed.keys(),"message":model.message}
		JavaScriptBridge.eval("window.campusLetterStatus = "+JSON.stringify(snapshot_),true)

func _pick(pos: Vector2) -> Dictionary:
	var from:=camera.project_ray_origin(pos);var dir:=camera.project_ray_normal(pos)
	var query:=PhysicsRayQueryParameters3D.create(from,from+dir*100,3)
	return get_world_3d().direct_space_state.intersect_ray(query)

func _plane_point(pos: Vector2, height: float) -> Vector3:
	var plane:=Plane(Vector3.UP,height)
	var point_:Variant=plane.intersects_ray(camera.project_ray_origin(pos),camera.project_ray_normal(pos))
	return point_ if point_ is Vector3 else Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		cancel_drag();help_panel.hide();return
	if help_panel.visible:return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			if not overview:return
			var zoom_:float=.92 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.08
			var offset:Vector3=camera.position-world.camera_target
			if offset.length()*zoom_>8 and offset.length()*zoom_<23:camera.position=world.camera_target+offset*zoom_
			return
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:_press(event.position,-1)
			else:_release(event.position,-1)
	elif event is InputEventMouseMotion:
		if pointer==-1:_move(event.position,-1)
		elif pointer==-2:_hover(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:_press(event.position,event.index)
		elif event.canceled and event.index==pointer:cancel_drag()
		else:_release(event.position,event.index)
	elif event is InputEventScreenDrag:_move(event.position,event.index)

func _input(event:InputEvent) -> void:
	# An active world manipulation keeps its release even when crossing the HUD.
	# Independent joystick fingers continue through the GUI input path.
	if pointer==-2:return
	if event is InputEventMouseMotion and pointer==-1:
		_move(event.position,-1);get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and pointer==-1:
		_release(event.position,-1);get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==pointer:
		_move(event.position,event.index);get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.index==pointer and not event.pressed:
		if event.canceled:cancel_drag()
		else:_release(event.position,event.index)
		get_viewport().set_input_as_handled()

func _press(pos: Vector2, finger: int) -> void:
	if pointer!=-2:return
	pointer=finger;start_screen=pos;last_screen=pos;has_dragged=false;snapshot=model.manipulation_snapshot();orbit_start=camera.position
	look_start=Vector2(fp_yaw,fp_pitch);move_target=Vector3.INF
	var hit:=_pick(pos)
	picked=str(hit.collider.get_meta("action","")) if not hit.is_empty() else ""
	press_floor=hit.position if not hit.is_empty() and hit.position.y<.25 else Vector3.INF
	if overview:picked=""
	if picked=="ground" or not world.targets.has(picked):picked=""
	if world.targets.has(picked):
		object_origin=world.targets[picked].node.position;drag_height=world.point(picked).y;start_world=_plane_point(pos,drag_height)
		object_label.text=world.targets[picked].title
		progress_label.text=object_label.text
	else:start_world=Vector3.ZERO
	match picked:
		"lamp":initial_value=model.data.lamp
		"left","right":initial_value=model.data[picked]
		"horizontal":initial_value=model.data.offset
		"vertical":initial_value=model.data.tilt
	_hover_label(pos)

func _move(pos: Vector2, finger: int) -> void:
	if pointer!=finger:return
	last_screen=pos
	if pos.distance_to(start_screen)>5:has_dragged=true
	if not has_dragged:return
	if picked.is_empty():
		if not overview:
			fp_yaw=look_start.x-(pos.x-start_screen.x)*.003
			fp_pitch=clampf(look_start.y-(pos.y-start_screen.y)*.003,-1.1,.65)
			return
		var yaw:float=(pos.x-start_screen.x)*-.004
		var offset:Vector3=orbit_start-world.camera_target
		offset=offset.rotated(Vector3.UP,clampf(yaw,-.7,.7));camera.position=world.camera_target+offset;camera.look_at(world.camera_target,Vector3.UP)
		return
	var delta_:Vector3=_plane_point(pos,drag_height)-start_world
	delta_=world.targets[picked].node.get_parent().global_transform.basis.inverse()*delta_
	match picked:
		"left","right":model.adjust(picked,initial_value+delta_.x*180)
		"lamp":model.adjust("lamp",initial_value+delta_.x*90)
		"horizontal":model.adjust("horizontal",initial_value+(pos.x-start_screen.x)*.7)
		"vertical":model.adjust("vertical",initial_value-(pos.y-start_screen.y)*.7)
		"card","weight0","weight1","weight2","letter":
			if picked=="letter":model.take_letter()
			var n:Node3D=world.targets[picked].node
			n.position=object_origin+delta_+Vector3(0,.15,0)
	world.sync() if picked in ["left","right","lamp","horizontal","vertical"] else _noop()
	_hover_label(pos)

func _noop() -> void:pass

func _release(pos: Vector2,finger: int) -> void:
	if pointer!=finger:return
	var id:=picked
	if has_dragged:
		if id=="card":
			if camera.unproject_position(world.point("scanner")).distance_to(pos)<80:model.seat_action("checkin")
			else:model.message="把校园卡放到桌边的圆形感应区。"
			if model.data.stage<2:world.objects.card.position=world.objects.card_origin
		elif id.begins_with("weight"):
			if camera.unproject_position(world.point("paper")).distance_to(pos)<130:model.place_weight(int(id.trim_prefix("weight")))
			else:model.message="把砝码放在纸桥中央，观察它是否能承住。"
		elif id=="letter":
			if camera.unproject_position(world.point("mailbox")).distance_to(pos)<100:model.deliver_light(world.objects.mailbox.position.distance_to(player.position))
			else:model.message="把来信放进信箱的投信口。"
			if not model.data.delivered:world.objects.letter.position=world.objects.letter_origin
	else:
		if not overview:
			if id.is_empty() and press_floor.is_finite():move_target=press_floor
			else:_activate(id)
	pointer=-2;picked="";snapshot={};_update_feedback()

func _activate(id: String) -> void:
	match model.active:
		"library":
			if id.begins_with("status"):model.seat_action("inspect")
			elif id.begins_with("seat"):
				if model.seat_action("sit",int(id.trim_prefix("seat"))):_sit_down()
			elif id=="terminal":model.seat_action("release" if model.data.stage==3 else "reserve",3)
			elif id=="scanner":model.message="把校园卡拖到圆形感应区完成签到。"
		"bridge":
			if id=="paper":model.fold_paper()
			elif id=="unload":model.remove_weights()
			elif id.begins_with("weight"):model.message="拿起这枚砝码，拖到纸桥中央。"
		"liuhu":
			if id.begins_with("record"):model.record_sample(int(id.trim_prefix("record")))
		"light":
			if id=="mailbox":model.deliver_light(world.objects.mailbox.position.distance_to(player.position))
			elif id=="letter":
				if world.objects.letter.position.distance_to(player.position)<2.2:model.take_letter()
				else:model.message="先走近等候处旁的信件。"

func cancel_drag() -> void:
	if pointer==-2:return
	if not snapshot.is_empty():model.cancel_manipulation(snapshot)
	if is_instance_valid(world):
		if picked in ["card","letter"] and world.targets.has(picked):world.targets[picked].node.position=object_origin
		world.sync()
	pointer=-2;picked="";snapshot={}

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_drag();move_target=Vector3.INF
		if is_instance_valid(pad):pad.reset()

func _hover(pos: Vector2) -> void:
	var hit:=_pick(pos);var id:String=str(hit.collider.get_meta("action","")) if not hit.is_empty() else ""
	object_label.text=world.targets[id].title if world.targets.has(id) and id!="ground" and not overview else ""
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if not object_label.text.is_empty() else Input.CURSOR_ARROW)
	_hover_label(pos)

func _hover_label(pos: Vector2) -> void:
	object_label.visible=false
	progress_label.text=object_label.text if not object_label.text.is_empty() else ("来信已完成" if model.completed.has(model.active) else "正在探索")

func _process(delta: float) -> void:
	if not OS.has_feature("web") or not is_instance_valid(world):return
	report_clock+=delta
	if report_clock<.25:return
	report_clock=0
	# Read-only observability: acceptance drives normal pointer/touch input only.
	var points:Dictionary={}
	for id:String in world.targets:
		var p:Vector2=camera.unproject_position(world.point(id));points[id]=[p.x,p.y]
	var state_:Dictionary=model.data.duplicate(true)
	if state_.has("player_position"):state_.player_position=[state_.player_position.x,state_.player_position.y]
	var ui:Dictionary={}
	for id:String in tabs:
		var p:Vector2=tabs[id].get_global_rect().get_center();ui[id]=[p.x,p.y]
	for name_:String in ["overview","joystick","restart","help"]:
		var n:Control={"overview":view_button,"joystick":pad,"restart":restart_button,"help":help_button}[name_]
		var p:Vector2=n.get_global_rect().get_center();ui[name_]=[p.x,p.y]
	JavaScriptBridge.eval("window.campusLetterObjects = "+JSON.stringify({"points":points,"ui":ui,"state":state_,"pointer":pointer,"active":model.active,"overview":overview,"seated":seated,"eye_height":eye_height,"player":[player.position.x,player.position.y,player.position.z],"look":[fp_yaw,fp_pitch]}),true)

func _sit_down() -> void:
	seated=true;pad.reset();move_target=Vector3.INF;player.velocity=Vector3.ZERO
	player.position=Vector3(3.3,.02,1.62);eye_height=1.12
	camera.position=player.position+Vector3.UP*eye_height;camera.look_at(Vector3(3.3,.9,.1),Vector3.UP);fp_yaw=camera.rotation.y;fp_pitch=camera.rotation.x

func _leave_seat() -> void:
	seated=false;eye_height=1.65;player.position=Vector3(3.3,.02,2.55)

func _physics_process(delta:float) -> void:
	if not is_instance_valid(world) or overview or help_panel.visible:return
	var motion:Vector2=pad_direction
	motion.x+=float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
	motion.y+=float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))
	if seated and (motion.length()>.05 or move_target.is_finite()):_leave_seat()
	var desired:Vector3=Basis(Vector3.UP,fp_yaw)*Vector3(motion.x,0,motion.y).limit_length(1)
	if move_target.is_finite():
		var target_delta:=Vector3(move_target.x-player.position.x,0,move_target.z-player.position.z)
		if target_delta.length()<.15:move_target=Vector3.INF
		else:desired=target_delta.normalized()
	player.velocity.x=desired.x*2.2;player.velocity.z=desired.z*2.2;player.velocity.y=-1.0
	player.move_and_slide()
	player.position.x=clampf(player.position.x,-5.5,5.5);player.position.z=clampf(player.position.z,world.near_limit,world.far_limit)
	if move_target.is_finite() and desired.length()>.1 and Vector2(player.velocity.x,player.velocity.z).length()<.05:move_target=Vector3.INF
	camera.position=player.position+Vector3(0,eye_height,0);camera.rotation=Vector3(fp_pitch,fp_yaw,0)
	if model.active=="light":
		model.move_player(Vector2((player.position.x-.7)*55+470,(player.position.z-1.6)*38+380))
		world.sync()
		world.objects.letter.get_node("Pick_letter").collision_layer=0 if model.data.carrying or model.data.delivered else 2
		if model.data.carrying and picked!="letter":
			world.objects.letter.global_position=camera.to_global(Vector3(.31,-.23,-.65));world.objects.letter.rotation=camera.rotation+Vector3(-.65,0,0)
