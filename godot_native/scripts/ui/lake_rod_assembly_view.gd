extends Control
## Native object close-up. Inventory is committed before this view is constructed.
signal event(action: String,value: Variant)
const Motion=preload("res://scripts/presentation/lake_rod_assembly.gd")
const PARTS_PATH: String="res://scenes/objects/lake_assembly_parts.tscn"
var elapsed_ms: float=0
var closed: bool=false
var read_state: Callable
var reduced_motion: bool=false
var source_font: Font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
var viewport3d: SubViewport
var parts: Node3D
var camera3d: Camera3D
var surface: TextureRect
var heading_label: Label
var detail_label: Label
var captions: Dictionary={"frame":"网框套上竿端","rope":"绕绳 · 收紧","clasp":"磁性扣贴合框沿","tug":"拉紧检查","stow":"磁吸钓竿已收好"}
func setup(config: Dictionary) -> void:
	read_state=config.get("read_state",Callable())
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL;grab_focus();z_index=100
	if read_state.is_valid():reduced_motion=bool(read_state.call().get("native",{}).get("settings",{}).get("reduced_motion",false))
	_build_stage()
	resized.connect(_layout_stage)
	_layout_stage();render_pose(6350 if reduced_motion else elapsed_ms)
func uses_responsive_exploration() -> bool:return true
func _material(hex: String,roughness: float=1) -> StandardMaterial3D:
	var material:=StandardMaterial3D.new();material.albedo_color=Color(hex);material.roughness=roughness;return material
func _build_stage() -> void:
	viewport3d=SubViewport.new();viewport3d.name="AssemblyObjectViewport";viewport3d.size=Vector2i(900,590);viewport3d.own_world_3d=true;viewport3d.msaa_3d=Viewport.MSAA_DISABLED;viewport3d.render_target_update_mode=SubViewport.UPDATE_ONCE;add_child(viewport3d)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("11272c");environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("b8c7c5");environment.environment.ambient_light_energy=.62;viewport3d.add_child(environment)
	camera3d=Camera3D.new();camera3d.name="AssemblyCloseCamera";camera3d.projection=Camera3D.PROJECTION_ORTHOGONAL;camera3d.size=2.55;camera3d.near=.05;camera3d.far=30;viewport3d.add_child(camera3d);camera3d.position=Vector3(.0,3.35,4.8);camera3d.look_at(Vector3(0,0,0),Vector3.UP);camera3d.current=true
	var key:=DirectionalLight3D.new();key.name="WarmContactLight";key.light_color=Color("fff0d8");key.light_energy=.88;key.shadow_enabled=true;key.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL;viewport3d.add_child(key);key.rotation_degrees=Vector3(-48,-30,-15)
	var fill:=DirectionalLight3D.new();fill.name="LakeFill";fill.light_color=Color("9fc4cf");fill.light_energy=.42;viewport3d.add_child(fill);fill.rotation_degrees=Vector3(-30,140,0)
	var table:=Node3D.new();table.name="StaticWorkbench";viewport3d.add_child(table)
	for i in 7:
		var plank:=MeshInstance3D.new();plank.name="Plank_%d"%i;var box:=BoxMesh.new();box.size=Vector3(5.3,.055,.47);plank.mesh=box;plank.material_override=_material(["3e3b32","464034","403b30"][i%3]);plank.position=Vector3(0,-.315,-1.43+i*.48);table.add_child(plank)
		for j in 3:
			var grain:=MeshInstance3D.new();var strip:=BoxMesh.new();strip.size=Vector3(1.15+j*.25,.001,.008);grain.mesh=strip;grain.material_override=_material("565044");grain.position=Vector3(-1.75+j*1.42,-.284,-1.57+i*.48+j*.045);table.add_child(grain)
	var scene: PackedScene=load(PARTS_PATH)
	if scene!=null:parts=scene.instantiate();viewport3d.add_child(parts)
	surface=TextureRect.new();surface.name="NativeAssemblySurface";surface.texture=viewport3d.get_texture();surface.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;surface.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;surface.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;surface.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(surface)
	heading_label=_label(24);heading_label.name="AssemblyPhaseCaption";add_child(heading_label)
	detail_label=_label(15);detail_label.name="AssemblyMaterialsCaption";detail_label.text="原钓竿  ·  断裂网框  ·  尼龙绳  ·  磁性扣";add_child(detail_label)
func _label(font_size: int) -> Label:
	var label:=Label.new();label.add_theme_font_override("font",source_font);label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",Color("efe4cb"));label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;return label
func _layout_stage() -> void:
	if not is_instance_valid(surface):return
	var width:=minf(size.x-24,1040);var height:=minf(size.y-126,width*590/900)
	surface.size=Vector2(width,height);surface.position=(size-surface.size)/2
	heading_label.position=Vector2(12,maxf(14,surface.position.y-46));heading_label.size=Vector2(size.x-24,36)
	detail_label.position=Vector2(12,minf(size.y-40,surface.position.y+surface.size.y+10));detail_label.size=Vector2(size.x-24,28)
	queue_redraw()
func _hand_at(name: String,point: Vector3,grip: float,angle: float=0) -> void:
	var hand: Node3D=parts.get_node(name);hand.rotation=Vector3(0,angle,0)
	parts.set_hand_grip("left" if name=="LeftHand" else "right",grip)
	var anchor: Node3D=hand.get_node_or_null("GripAnchor")
	hand.position=point-hand.basis*(anchor.position if anchor!=null else Vector3.ZERO)
func render_pose(at_ms: float) -> void:
	var pose:=Motion.sample(at_ms)
	if heading_label!=null:heading_label.text=captions[pose.phase]
	if parts==null:return
	parts.set_rod_flex(float(pose.tug)/.12)
	parts.get_node("Frame").position=pose.frame;parts.get_node("Frame").rotation=pose.frame_rotation
	parts.get_node("Rope").position=pose.rod_tip;parts.set_rope_progress(pose.wrap,pose.tension)
	parts.get_node("MagneticClasp").position=pose.clasp;parts.get_node("MagneticClasp").rotation=Vector3(0,2.627+float(pose.detent)*2,.056)
	_hand_at("LeftHand",parts.get_anchor("rod_grip").position,.9,-.18)
	var frame_grip: Vector3=parts.to_local(parts.get_anchor("frame_grip").global_position)
	var rope_end: Vector3=parts.to_local(parts.get_anchor("rope_tip").global_position)
	var clasp_grip: Vector3=parts.to_local(parts.get_anchor("clasp_grip").global_position)
	var right_target: Vector3=frame_grip
	if pose.phase=="rope":right_target=frame_grip.lerp(rope_end,Motion._ease((at_ms-2000)/250))
	elif pose.phase=="clasp":right_target=rope_end.lerp(clasp_grip,Motion._ease((at_ms-3800)/250))
	elif pose.phase in ["tug","stow"]:right_target=clasp_grip.lerp(pose.rod_tip,Motion._ease((at_ms-5000)/250))
	var clasp_hand: float=Motion._ease((at_ms-3800)/250)*(1-Motion._ease((at_ms-4950)/300))
	_hand_at("RightHand",right_target,.75,lerpf(-.28,1.15,clasp_hand))
	parts.get_node("MagneticClasp/DetentPivot").rotation.y=clampf((at_ms-4650)/180,0,1)*-.35
	var close: float=Motion._ease((at_ms-1700)/600)*(1-Motion._ease((at_ms-5150)/450))
	var focus:=Vector3(.62,0,0)*close
	camera3d.size=lerpf(2.55,1.35,close);camera3d.position=focus+Vector3(0,3.35,4.8);camera3d.look_at(focus,Vector3.UP)
	var stow: float=pose.stow
	parts.position=Vector3(.95,-.06,.8)*stow;parts.rotation.y=.28*stow;parts.scale=Vector3.ONE*lerpf(1,.24,stow)
	parts.get_node("LeftHand").visible=stow<.12;parts.get_node("RightHand").visible=stow<.12
	viewport3d.render_target_update_mode=SubViewport.UPDATE_ONCE
func cancel() -> void:
	if closed:return
	closed=true
	if viewport3d!=null:viewport3d.render_target_update_mode=SubViewport.UPDATE_DISABLED
	queue_free()
func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:cancel()
func _process(delta: float) -> void:
	if closed:return
	if read_state.is_valid():
		var current: Dictionary=read_state.call()
		if not current.get("qizhenLake",{}).get("magneticRodCombined",false) or not current.get("items",{}).get("magneticFishingRod",false):cancel();return
	elapsed_ms+=minf(delta,.05)*1000
	if elapsed_ms>=(1100.0 if reduced_motion else Motion.DURATION_MS):cancel();return
	render_pose(6350 if reduced_motion else elapsed_ms)
func _gui_input(input: InputEvent) -> void:
	if input is InputEventKey and input.pressed and input.keycode==KEY_ESCAPE:cancel();accept_event()
func _draw() -> void:
	if not closed:draw_rect(Rect2(Vector2.ZERO,size),Color("071a21",.93))
