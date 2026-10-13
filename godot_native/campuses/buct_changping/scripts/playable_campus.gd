extends Node2D
const STUDENT_PIN_LAYOUT = preload("res://campuses/buct_shared/student/scripts/landmark_pin_layout.gd")
const VISITOR = preload("res://campuses/buct_changping/scripts/campus_visitor.gd")
var SOURCE: Texture2D
var WORLD: Vector2
const CELL := 2.0
var data: Dictionary
var world: Node2D
var objects: Node2D
var visitor: CharacterBody2D
var camera: Camera2D
var font: Font
var walk_polys: Array[PackedVector2Array] = []
var blockers: Array[PackedVector2Array] = []
var landmark_hit_polys := {}
var grid := AStarGrid2D.new()
var walk_cells: Array[Vector2i] = []
var current_path := PackedVector2Array()
var path_index := 0
var guide_active := false
var guide_index := 0
var guide_pause := 0.0
var tour_speed := 106.0
var visited: Array[String] = []
var overview := false
var zoom_level := 2.1
var info_id := ""
var ui: CanvasLayer
var status: Label
var progress: Label
var place_label: Label
var info_panel: Panel
var info_title: Label
var info_text: Label
var hint_label: Label
var pins: Array[Control] = []
var pin_layer: CanvasLayer
var route_visual: Line2D
var canopy_locator: Line2D
var canopy_masks: Dictionary = {}
var boundary_message_until := 0.0
var elapsed := 0.0

var leaving := false
var initialized := false
var owned_actions: Array[String] = []
var ui_controls := {}
var map_area := Rect2()
var compact := false
var return_button: Button
var info_scroll: ScrollContainer

func pts(values: Array, offset := Vector2.ZERO) -> PackedVector2Array:
	var p := PackedVector2Array()
	for value in values: p.append(Vector2(value[0],value[1])-offset)
	return p

func _ready() -> void:
	if not ResourceLoader.exists("res://campuses/buct_changping/scenes/registered_layers.tscn"):
		_show_initialization_error("校园素材暂时无法加载，请返回入口");return
	data=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct_changping/data/playable_route.json"))
	SOURCE=load("res://campuses/buct_changping/"+str(data.source))
	WORLD=SOURCE.get_size()
	font=load("res://campuses/buct_changping/assets/ui-font.otf").duplicate()
	font.fallbacks.append(load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"))
	_install_inputs()
	world=load("res://campuses/buct_changping/scenes/registered_layers.tscn").instantiate()
	world.name="RegisteredCampus"
	add_child(world)
	world.get_node("GroundRepairTiles").render_target_update_mode=SubViewport.UPDATE_ONCE
	objects=world.get_node("IndependentRegisteredObjects")
	for poly in data.walkable_polygons: walk_polys.append(pts(poly))
	var building_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct_changping/data/layers.json"))
	_prepare_depth_layers(building_data)
	var landmark_ids: Array=[]
	for landmark in data.landmarks: landmark_ids.append(str(landmark.id))
	for item in building_data.objects:
		if str(item.id) in landmark_ids:
			landmark_hit_polys[item.id]=[pts(item.silhouette)]
			for poly in item.get("visual_polygons",[]):landmark_hit_polys[item.id].append(pts(poly))
		for footprint in item.footprints:
			for expanded in Geometry2D.offset_polygon(pts(footprint),3.2): blockers.append(expanded)
	_add_tree_occluders()
	_build_grid()
	visitor=CharacterBody2D.new()
	visitor.set_script(VISITOR)
	visitor.map=self
	objects.add_child(visitor)
	visitor.position=Vector2(data.spawn[0],data.spawn[1])
	canopy_locator=Line2D.new();canopy_locator.name="UnderCanopyFootLocator"
	canopy_locator.width=0.8;canopy_locator.default_color=Color(0.84,0.97,0.87,0.95)
	canopy_locator.z_index=100
	for i in range(25):canopy_locator.add_point(Vector2.from_angle(i*TAU/24.0)*5.0)
	add_child(canopy_locator);canopy_locator.hide()
	camera=Camera2D.new()
	camera.name="WalkingCamera"
	camera.position_smoothing_enabled=true
	camera.position_smoothing_speed=7.0
	camera.zoom=Vector2.ONE*zoom_level
	camera.limit_left=0; camera.limit_top=0; camera.limit_right=int(WORLD.x); camera.limit_bottom=int(WORLD.y)
	add_child(camera)
	camera.position=visitor.position+Vector2(0,-50)
	camera.reset_smoothing()
	_create_route_visual()
	_make_ui()
	_make_pins()
	initialized=true
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()
	status.text="点击步道前往第一教学楼与图书馆"

func _prepare_depth_layers(building_data: Dictionary) -> void:
	# Baked ground shadows must not cover a visitor. Preserve their exact source pixels,
	# but place them between repaired ground and depth-sorted solid objects.
	var shadows:=Node2D.new();shadows.name="StaticSourceGroundShadows"
	world.add_child(shadows);world.move_child(shadows,objects.get_index())
	for item in building_data.objects:
		var count: int=item.get("shadow_polygons",[]).size()
		if count==0:continue
		var node=objects.get_node(item.id)
		for child in node.get_children():
			if child is Polygon2D and str(child.name)!="SourcePixelSilhouette" and count>0:
				# Serialized anonymous @ names can collide after earlier scenes used the name counter.
				child.name="%s_GroundShadow_%d" % [str(item.id),count]
				child.reparent(shadows,true);count-=1
	# Some long or recessed facades need separate foot-depth bands. The bands
	# are traced for this source and declared per object, never borrowed coordinates.
	for item in building_data.objects:
		if item.get("depth_regions",[]).is_empty(): continue
		var node=objects.get_node(item.id)
		var original: Polygon2D=node.get_node("SourcePixelSilhouette")
		var absolute:=PackedVector2Array()
		for p in original.uv:absolute.append(p)
		node.y_sort_enabled=true
		# Clipping an exact source edge can alter GPU top-left coverage at fractional
		# intersections. Keep an exact original-polygon raster guard below every
		# depth slice; it fills only sampling seams and cannot override a front slice.
		var minimum_baseline:=INF
		for region in item.depth_regions:minimum_baseline=minf(minimum_baseline,float(region.baseline))
		var guard:=Node2D.new();guard.name="SourceRasterGuardDepth"
		guard.position=Vector2(0,minimum_baseline-node.source_position.y-0.25)
		node.add_child(guard)
		var guard_body:=Polygon2D.new();guard_body.name="ExactUncutSourceBody"
		var guard_points:=PackedVector2Array()
		for vertex in absolute:guard_points.append(vertex-node.source_position-guard.position)
		guard_body.polygon=guard_points;guard_body.uv=absolute;guard_body.texture=SOURCE
		guard_body.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;guard.add_child(guard_body)
		for region in item.depth_regions:
			var depth:=Node2D.new();depth.name=str(region.name)+"Depth"
			depth.position=Vector2(0,float(region.baseline)-node.source_position.y)
			node.add_child(depth)
			for cut in Geometry2D.intersect_polygons(absolute,pts(region.clip)):
				var polygon:=Polygon2D.new();polygon.name="ExactSourceBody"
				var local:=PackedVector2Array()
				for vertex in cut:local.append(vertex-node.source_position-depth.position)
				polygon.polygon=local;polygon.uv=cut;polygon.texture=SOURCE
				polygon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
				depth.add_child(polygon)
			original.hide()

func landmark_at(point: Vector2) -> String:
	for id in landmark_hit_polys:
		for poly in landmark_hit_polys[id]:
			if Geometry2D.is_point_in_polygon(point,poly):return id
	return ""

func _install_inputs() -> void:
	var bindings={"buct_changping_walk_left":[KEY_A,KEY_LEFT],"buct_changping_walk_right":[KEY_D,KEY_RIGHT],"buct_changping_walk_up":[KEY_W,KEY_UP],"buct_changping_walk_down":[KEY_S,KEY_DOWN],"buct_changping_walk_fast":[KEY_SHIFT]}
	for action in bindings:
		if InputMap.has_action(action):continue
		InputMap.add_action(action);owned_actions.append(action)
		for key in bindings[action]:
			# Desktop key events may carry logical-only arrows or physical letter codes.
			for physical in [false,true]:
				var event:=InputEventKey.new()
				if physical:event.physical_keycode=key
				else:event.keycode=key
				if not InputMap.action_has_event(action,event):InputMap.action_add_event(action,event)

func _add_tree_occluders() -> void:
	for item in data.get("occluders",[]):
		var tree:=Node2D.new();tree.name=item.id
		var anchor:=Vector2(item.anchor[0],item.anchor[1]);tree.position=anchor
		var canopy:=Polygon2D.new();canopy.name="OriginalCanopyOccluder"
		canopy.polygon=pts(item.polygon,anchor);canopy.uv=pts(item.polygon)
		canopy.texture=SOURCE;canopy.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		if item.has("alpha_mask"):
			var texture: Texture2D=load("res://campuses/buct_changping/"+str(item.alpha_mask))
			canopy_masks[item.id]=texture.get_image()
			var shader:=Shader.new()
			shader.code="shader_type canvas_item; uniform sampler2D foliage_mask : filter_nearest; void fragment(){vec4 s=texture(TEXTURE,UV); COLOR=vec4(s.rgb,s.a*texture(foliage_mask,UV).r);}"
			var material:=ShaderMaterial.new();material.shader=shader;material.set_shader_parameter("foliage_mask",texture)
			canopy.material=material
		tree.add_child(canopy)
		var body:=StaticBody2D.new();body.name="TrunkFeetCollision";body.collision_layer=1
		var shape:=CollisionShape2D.new();var circle:=CircleShape2D.new()
		circle.radius=float(item.get("trunk_radius",2.0));shape.shape=circle
		body.add_child(shape);tree.add_child(body)
		objects.add_child(tree)
		var poly:=PackedVector2Array()
		for j in range(12):poly.append(anchor+Vector2.from_angle(j*TAU/12.0)*(circle.radius+3.2))
		blockers.append(poly)

func _in_paving(p: Vector2) -> bool:
	for poly in walk_polys:
		if Geometry2D.is_point_in_polygon(p,poly):return true
	return false

func is_walkable(p: Vector2) -> bool:
	for offset in [Vector2.ZERO,Vector2(3,0),Vector2(-3,0),Vector2(0,3),Vector2(0,-3)]:
		if not _in_paving(p+offset):return false
	for poly in blockers:
		if Geometry2D.is_point_in_polygon(p,poly):return false
	return true

func _build_grid() -> void:
	var bounds:=Rect2(walk_polys[0][0],Vector2.ZERO)
	for poly in walk_polys:
		for p in poly:bounds=bounds.expand(p)
	var start:=Vector2i(floori(bounds.position.x/CELL)-1,floori(bounds.position.y/CELL)-1)
	var end:=Vector2i(ceili(bounds.end.x/CELL)+1,ceili(bounds.end.y/CELL)+1)
	grid.region=Rect2i(start,end-start)
	grid.cell_size=Vector2(CELL,CELL);grid.offset=Vector2(CELL/2,CELL/2)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic=AStarGrid2D.HEURISTIC_OCTILE
	grid.default_estimate_heuristic=AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	for x in range(start.x,end.x):
		for y in range(start.y,end.y):
			var cell:=Vector2i(x,y)
			var allowed:=is_walkable(grid.get_point_position(cell))
			grid.set_point_solid(cell,not allowed)
			if allowed:walk_cells.append(cell)

func nearest_cell(p: Vector2) -> Vector2i:
	var guess:=Vector2i(floori(p.x/CELL),floori(p.y/CELL))
	if grid.is_in_boundsv(guess) and not grid.is_point_solid(guess):return guess
	var best:=walk_cells[0];var best_distance:=INF
	for cell in walk_cells:
		var d:=grid.get_point_position(cell).distance_squared_to(p)
		if d<best_distance:best_distance=d;best=cell
	return best

func path_to(p: Vector2) -> bool:
	current_path=grid.get_point_path(nearest_cell(visitor.position),nearest_cell(p))
	path_index=0
	if current_path.size()>1: path_index=1
	return current_path.size()>0

func route_direction(p: Vector2) -> Vector2:
	if guide_pause>0:return Vector2.ZERO
	while path_index<current_path.size() and p.distance_to(current_path[path_index])<2.5:path_index+=1
	if path_index<current_path.size():return p.direction_to(current_path[path_index])
	if guide_active:_guide_arrived()
	return Vector2.ZERO

func movement_paused() -> bool:
	return leaving or not initialized or overview or (not info_id.is_empty() and not guide_active) or guide_pause>0

func cancel_route_for_manual_input() -> void:
	current_path.clear()
	if guide_active:
		guide_active=false;guide_pause=0;close_info()
		status.text="已切换为自由行走"

func _guide_arrived() -> void:
	if guide_index<data.route_waypoints.size():
		var target:=Vector2(data.route_waypoints[guide_index][0],data.route_waypoints[guide_index][1])
		if visitor.position.distance_to(target)>8.0:
			guide_active=false;guide_pause=0;current_path.clear();close_info()
			status.text="未到达此段终点，请回到南门重试"
			push_warning("Guide stopped before arrival: actual feet are away from waypoint")
			return
	if guide_index>=data.route_waypoints.size():
		guide_active=false
		show_landmark("library")
		status.text="已到图书馆前广场，可继续探索开放步道"
		return
	for landmark in data.landmarks:
		if int(landmark.route_index)==guide_index:
			show_landmark(str(landmark.id));guide_pause=0.8
	guide_index+=1
	if guide_index<data.route_waypoints.size():
		if not path_to(Vector2(data.route_waypoints[guide_index][0],data.route_waypoints[guide_index][1])):
			guide_active=false;guide_pause=0;close_info()
			status.text="此段路线未连通，请回到南门或自由行走"
			push_warning("Guide paused: next waypoint is unreachable, no arrival credited")

func start_guide() -> void:
	if not initialized or leaving:return
	return_to_gate()
	guide_active=true;guide_index=0
	var length:=0.0
	for i in range(1,data.route_waypoints.size()):length+=Vector2(data.route_waypoints[i-1][0],data.route_waypoints[i-1][1]).distance_to(Vector2(data.route_waypoints[i][0],data.route_waypoints[i][1]))
	tour_speed=maxf(106.0,length/9.5)
	path_to(Vector2(data.route_waypoints[0][0],data.route_waypoints[0][1]))
	status.text="自动导览中 · 随时按方向键接管"

func return_to_gate() -> void:
	if not initialized or leaving:return
	guide_active=false;guide_pause=0;current_path.clear();close_info()
	overview=false;visitor.position=Vector2(data.spawn[0],data.spawn[1]);visitor.velocity=Vector2.ZERO
	_layout_ui();camera.reset_smoothing()
	status.text="已回到南门"

func show_landmark(id: String) -> void:
	for item in data.landmarks:
		if str(item.id)==id:
			info_id=id;info_title.text=str(item.name);info_text.text=str(item.description)
			info_panel.show()
			if not visited.has(id):visited.append(id)
			progress.text="已探访 %d / 3"%visited.size()
			return

func close_info() -> void:
	info_id=""
	if is_instance_valid(info_panel):info_panel.hide()

func toggle_overview() -> void:
	if not initialized or leaving:return
	overview=not overview;close_info();_layout_ui()
	status.text="全图 · 仅南门至图书馆主线可走" if overview else "返回步行视角"

func notify_boundary() -> void:
	if not guide_active and visitor.manual_input.length_squared()>0:
		boundary_message_until=elapsed+1.0
		status.text="请沿已开放的铺装步道行走"

func _create_route_visual() -> void:
	route_visual=Line2D.new();route_visual.name="OptionalRouteGuide"
	route_visual.points=pts(data.route_waypoints);route_visual.width=1.8
	route_visual.default_color=Color(0.27,0.57,0.52,0.50)
	route_visual.z_index=5;route_visual.visible=false;world.add_child(route_visual)

func _make_pins() -> void:
	pin_layer=CanvasLayer.new();pin_layer.name="LandmarkPins";pin_layer.layer=5;add_child(pin_layer)
	for item in data.landmarks:
		var button:=Button.new();button.text=str(item.name)
		button.position=Vector2(item.position[0],item.position[1])+Vector2(8,-25)
		button.custom_minimum_size=Vector2(92,40)
		button.add_theme_font_override("font",font);button.add_theme_font_size_override("font_size",18)
		button.add_theme_stylebox_override("normal",box(Color(0.95,0.94,0.87,0.91),7))
		button.add_theme_color_override("font_color",Color("38574b"))
		button.pressed.connect(show_landmark.bind(str(item.id)))
		pin_layer.add_child(button);pins.append(button)

func box(color: Color, radius: int=12) -> StyleBoxFlat:
	var b:=StyleBoxFlat.new();b.bg_color=color
	b.corner_radius_top_left=radius;b.corner_radius_top_right=radius;b.corner_radius_bottom_left=radius;b.corner_radius_bottom_right=radius
	b.content_margin_left=12;b.content_margin_right=12;b.content_margin_top=7;b.content_margin_bottom=7
	return b

func label(text: String, p: Vector2, size: int=18) -> Label:
	var l:=Label.new();l.text=text;l.position=p
	l.add_theme_font_override("font",font);l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",Color("38574b"));ui.add_child(l);return l

func button(text: String, rect: Rect2, action: Callable) -> Button:
	var b:=Button.new();b.text=text;b.position=rect.position;b.size=rect.size
	b.add_theme_font_override("font",font);b.add_theme_font_size_override("font_size",17)
	b.add_theme_color_override("font_color",Color("34574c"));b.add_theme_color_override("font_hover_color",Color("27483d"))
	b.add_theme_stylebox_override("normal",box(Color("e7e8d9"),8));b.add_theme_stylebox_override("hover",box(Color("d6dfce"),8))
	b.add_theme_stylebox_override("pressed",box(Color("c6d6c2"),8));b.pressed.connect(action);ui.add_child(b);return b

func _make_ui() -> void:
	ui=CanvasLayer.new();ui.name="ExplorationInterface";ui.layer=10;add_child(ui)
	for key in ["top", "bottom"]:
		var panel:=Panel.new()
		panel.add_theme_stylebox_override("panel",box(Color("f1f0e5"),0))
		ui.add_child(panel);ui_controls[key]=panel
	ui_controls.title=label("北京化工大学 · 昌平校园漫游",Vector2.ZERO,25)
	ui_controls.route=label("南门 → 第一教学楼 → 图书馆",Vector2.ZERO,20)
	progress=label("已探访 0 / 3",Vector2.ZERO,17)
	ui_controls.back=button("返回入口",Rect2(),return_to_entry)
	ui_controls.back.name="ChangpingReturnToEntry";return_button=ui_controls.back
	status=label("",Vector2.ZERO,18)
	hint_label=label("WASD / 方向键 · 点击路面寻路 · E 地标 · 滚轮缩放",Vector2.ZERO,15)
	ui_controls.guide=button("自动导览",Rect2(),start_guide)
	ui_controls.reset=button("回南门",Rect2(),return_to_gate)
	ui_controls.overview=button("查看全图",Rect2(),toggle_overview)
	ui_controls.nearby=button("附近地标",Rect2(),show_nearby_landmark)
	ui_controls.zoom_out=button("−",Rect2(),func(): zoom_level=clampf(zoom_level-0.2,1.4,2.8))
	ui_controls.zoom_in=button("+",Rect2(),func(): zoom_level=clampf(zoom_level+0.2,1.4,2.8))
	info_panel=Panel.new()
	info_panel.add_theme_stylebox_override("panel",box(Color(0.96,0.95,0.89,0.98),12));ui.add_child(info_panel)
	info_title=Label.new();info_title.position=Vector2(16,10);info_title.add_theme_font_override("font",font);info_title.add_theme_font_size_override("font_size",23);info_title.add_theme_color_override("font_color",Color("36594c"));info_panel.add_child(info_title)
	info_scroll=ScrollContainer.new();info_scroll.position=Vector2(16,49);info_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;info_panel.add_child(info_scroll)
	info_text=Label.new();info_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;info_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	info_text.add_theme_font_override("font",font);info_text.add_theme_font_size_override("font_size",17);info_text.add_theme_color_override("font_color",Color("536257"));info_scroll.add_child(info_text)
	var close:=Button.new();close.text="返回地图";close.name="CloseLandmark"
	close.add_theme_font_override("font",font);close.add_theme_font_size_override("font_size",17)
	close.pressed.connect(close_info);info_panel.add_child(close);ui_controls.close=close
	info_panel.hide()

func _unhandled_input(event: InputEvent) -> void:
	if leaving:return
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
		if code==KEY_ESCAPE:
			if not info_id.is_empty():close_info()
			elif overview:toggle_overview()
			else:return_to_entry()
			get_viewport().set_input_as_handled();return
		if not initialized:return
		match code:
			KEY_M:toggle_overview()
			KEY_R:return_to_gate()
			KEY_E:show_nearby_landmark()
	if not initialized:return
	if event is InputEventScreenTouch and event.pressed:
		_pointer_pressed(event.position);get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:zoom_level=clampf(zoom_level+.15,1.4,2.8)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:zoom_level=clampf(zoom_level-.15,1.4,2.8)
		if event.button_index==MOUSE_BUTTON_LEFT:_pointer_pressed(event.position)

func is_head_under_canopy(feet: Vector2) -> bool:
	for item in data.get("occluders",[]):
		var head:=feet+Vector2(0,-13)
		if feet.y<float(item.anchor[1]) and Geometry2D.is_point_in_polygon(head,pts(item.polygon)):
			if canopy_masks.has(item.id):
				var mask: Image=canopy_masks[item.id]
				if mask.get_pixelv(Vector2i(head)).r<0.5: continue
			return true
	return false

func _fit_overview_camera() -> void:
	camera.limit_left=-100000;camera.limit_top=-100000;camera.limit_right=100000;camera.limit_bottom=100000
	camera.position_smoothing_enabled=false
	var view:=get_viewport_rect().size
	var usable:=map_area
	var fit:=minf(usable.size.x/WORLD.x,usable.size.y/WORLD.y)
	camera.zoom=Vector2.ONE*fit
	camera.position=WORLD/2-(usable.get_center()-view/2)/fit

func _process(delta: float) -> void:
	if not initialized or leaving:return
	elapsed+=delta
	if boundary_message_until>0 and elapsed>=boundary_message_until:
		boundary_message_until=0
		if not guide_active:status.text="沿开放的铺装步道探索校园"
	if guide_pause>0:
		guide_pause=maxf(0,guide_pause-delta)
		if guide_pause<=0:close_info()
	if is_instance_valid(visitor):
		canopy_locator.position=visitor.position+Vector2(0,1)
		canopy_locator.visible=not overview and is_head_under_canopy(visitor.position)
		if overview:
			_fit_overview_camera()
		else:
			camera.limit_left=-100000;camera.limit_top=-100000;camera.limit_right=100000;camera.limit_bottom=100000
			camera.position_smoothing_enabled=true
			camera.position=_walking_camera_position()
			camera.zoom=camera.zoom.lerp(Vector2.ONE*_walking_zoom(),1-exp(-delta*8))
		route_visual.visible=overview
		for i in range(pins.size()):
			var p:=Vector2(data.landmarks[i].position[0],data.landmarks[i].position[1])
			pins[i].visible=overview or visitor.position.distance_to(p)<130
			if overview:
				var width: float=(get_viewport_rect().size.x-40)/3
				pins[i].position=Vector2(12+i*(width+8),map_area.position.y-50)
				pins[i].size=Vector2(width,40)
			else:
				var screen: Vector2=get_canvas_transform()*p+Vector2(8,-52)
				pins[i].size=Vector2(100,40)
				pins[i].position=STUDENT_PIN_LAYOUT.place(screen,pins[i].size,STUDENT_PIN_LAYOUT.student_screen_bounds(visitor),map_area)

func _layout_ui() -> void:
	if not initialized:return
	var view:=get_viewport_rect().size
	compact=view.x<800 or view.y<500
	var top_height:=88.0 if view.x<600 else 70.0
	ui_controls.zoom_in.disabled=overview
	ui_controls.zoom_out.disabled=overview
	var stacked:=view.x<800 and view.y>=500
	var bottom_height:=168.0 if stacked else 110.0
	ui_controls.top.size=Vector2(view.x,top_height)
	ui_controls.bottom.position=Vector2(0,view.y-bottom_height)
	ui_controls.bottom.size=Vector2(view.x,bottom_height)
	ui_controls.title.position=Vector2(12,10)
	ui_controls.title.add_theme_font_size_override("font_size",18 if view.x<600 else 24)
	ui_controls.title.text="北化 · 昌平校园漫游" if view.x<600 else "北京化工大学 · 昌平校园漫游"
	ui_controls.back.position=Vector2(view.x-104,10);ui_controls.back.size=Vector2(92,44)
	progress.position=Vector2(12,50) if view.x<600 else Vector2(view.x-238,22)
	ui_controls.route.visible=view.x>=950
	ui_controls.route.position=Vector2(480,20)
	var bottom_y:=view.y-bottom_height
	status.position=Vector2(12,bottom_y+8)
	status.size=Vector2(view.x-24,42 if stacked else 25)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size",15 if compact else 18)
	hint_label.position=Vector2(12,bottom_y+48 if stacked else bottom_y+35)
	hint_label.text="点击步道行走 · 点击建筑查看介绍" if view.x<800 else "WASD / 方向键 · 点击步道 · E 地标 · 滚轮缩放"
	hint_label.add_theme_font_size_override("font_size",13 if compact else 15)
	var buttons: Array=[ui_controls.guide,ui_controls.reset,ui_controls.overview,ui_controls.nearby,ui_controls.zoom_out,ui_controls.zoom_in]
	var columns:=3 if stacked else 6
	var width: float=(view.x-24.0-8.0*(columns-1))/columns
	var start_y:=view.y-96 if stacked else view.y-52
	for i in range(buttons.size()):
		buttons[i].position=Vector2(12+(i%columns)*(width+8),start_y+(i/columns)*48)
		buttons[i].size=Vector2(width,44)
		buttons[i].add_theme_font_size_override("font_size",16 if compact else 17)
	var map_top:=top_height+(58 if overview else 12)
	map_area=Rect2(12,map_top,view.x-24,maxf(40,view.y-map_top-bottom_height-12))
	var panel_width:=minf(398,view.x-24)
	var panel_height:=230.0 if view.x>=600 else 254.0
	panel_height=minf(panel_height,view.y-top_height-bottom_height-12)
	info_panel.size=Vector2(panel_width,panel_height)
	info_panel.position=Vector2(view.x-panel_width-12,view.y-bottom_height-panel_height-8)
	info_scroll.size=Vector2(panel_width-32,panel_height-104)
	info_text.custom_minimum_size.x=panel_width-52
	info_text.size.x=panel_width-52
	info_text.add_theme_font_size_override("font_size",14 if view.y<500 else 17)
	ui_controls.close.position=Vector2(16,panel_height-49)
	ui_controls.close.size=Vector2(panel_width-32,40)
	if overview:_fit_overview_camera()
	elif is_instance_valid(camera):
		camera.position=_walking_camera_position()
		camera.zoom=Vector2.ONE*_walking_zoom()
		camera.reset_smoothing()


func _walking_camera_position() -> Vector2:
	var area_center:=map_area.get_center() if map_area.has_area() else get_viewport_rect().size/2
	return visitor.position-(area_center-get_viewport_rect().size/2+Vector2(0,24))/_walking_zoom()


func _walking_zoom() -> float:
	return zoom_level*clampf(get_viewport_rect().size.x/1280.0,0.48,1.1)


func show_nearby_landmark() -> void:
	if not initialized or leaving:return
	var nearest: Dictionary={};var distance:=60.0
	for item in data.landmarks:
		var d:=visitor.position.distance_to(Vector2(item.position[0],item.position[1]))
		if d<distance:nearest=item;distance=d
	if not nearest.is_empty():show_landmark(str(nearest.id))
	else:status.text="靠近南门、第一教学楼或图书馆，或直接点击建筑"


func _pointer_pressed(screen_position: Vector2) -> void:
	if not initialized or leaving or not info_id.is_empty() or not map_area.has_point(screen_position):return
	var target: Vector2=get_canvas_transform().affine_inverse()*screen_position
	var landmark:=landmark_at(target)
	if not landmark.is_empty():show_landmark(landmark)
	elif not overview and is_walkable(target):
		guide_active=false;guide_pause=0;path_to(target);status.text="沿开放步道前往点击位置"


func _stop_motion() -> void:
	guide_active=false;guide_pause=0;current_path.clear()
	for action in owned_actions:Input.action_release(action)
	if is_instance_valid(visitor):visitor.velocity=Vector2.ZERO;visitor.manual_input=Vector2.ZERO


func return_to_entry() -> void:
	if leaving:return
	leaving=true;_stop_motion()
	if is_instance_valid(visitor):visitor.set_physics_process(false)
	_change_to_entry.call_deferred()


func _change_to_entry() -> void:
	var error:=get_tree().change_scene_to_file("res://scenes/entry.tscn")
	if error!=OK:
		leaving=false
		if is_instance_valid(visitor):visitor.set_physics_process(true)
		if is_instance_valid(status):status.text="暂时无法返回，请重试"


func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:_stop_motion()


func _exit_tree() -> void:
	_stop_motion()
	for action in owned_actions:InputMap.erase_action(action)
	owned_actions.clear()
	if get_viewport().size_changed.is_connected(_layout_ui):get_viewport().size_changed.disconnect(_layout_ui)


func _show_initialization_error(message: String) -> void:
	ui=CanvasLayer.new();ui.layer=10;add_child(ui)
	var panel:=VBoxContainer.new();panel.position=Vector2(16,16);ui.add_child(panel)
	status=Label.new();status.text=message;status.add_theme_font_override("font",load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"));panel.add_child(status)
	return_button=Button.new();return_button.name="ChangpingReturnToEntry";return_button.text="返回入口";return_button.add_theme_font_override("font",load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"));return_button.custom_minimum_size=Vector2(160,48);return_button.pressed.connect(return_to_entry);panel.add_child(return_button)
