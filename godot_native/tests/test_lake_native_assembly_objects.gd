extends SceneTree
const View=preload("res://scripts/ui/lake_rod_assembly_view.gd")
const Motion=preload("res://scripts/presentation/lake_rod_assembly.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("NATIVE ASSEMBLY: "+label)
func run() -> void:
	var state: Node=root.get_node("State");state.developer_mode=true;state.begin_checkpoint("c3-qizhen-paper");state.act("c3_lake_combine")
	var initial:=JSON.stringify([state.d.items,state.d.qizhenLake])
	var view:=View.new();root.add_child(view);view.setup({"read_state":func():return state.d});view.set_process(false)
	var parts: Node3D=view.parts
	for name_string: String in ["Rod","Frame","Rope","MagneticClasp","LeftHand","RightHand"]:
		var object: Node3D=parts.get_node(name_string)
		check(object!=null and object.get_parent()==parts,"independent named native object "+name_string)
		check(object.get_child_count()>1,"own mesh/anchor children "+name_string)
	var early_vertices:=0
	for ms: float in [0,1000,1999,2000,2400,2800,3300,3600,3700,4300,4500,4730,4900,5100,5280,5700,6100,6200,6800,7200]:
		view.render_pose(ms)
		var p:=Motion.sample(ms)
		if ms>=2000:check(parts.get_anchor("rod_tip").global_position.distance_to(parts.get_anchor("frame_socket").global_position)<.00001,"actual flexed socket contact "+str(ms))
		if ms>=4850:check(parts.get_anchor("clasp_seat").global_position.distance_to(parts.get_anchor("clasp_contact").global_position)<.00001,"actual clasp rim contact "+str(ms))
		if ms<6400:check(parts.get_anchor("left_grasp").global_position.distance_to(parts.get_anchor("rod_grip").global_position)<.00001,"left hand actual rod anchor contact")
		if ms<2000:check(parts.get_anchor("right_grasp").global_position.distance_to(parts.get_anchor("frame_grip").global_position)<.00001,"right hand holds physical frame rim")
		if p.phase=="clasp" and ms>=4050:check(parts.get_anchor("right_grasp").global_position.distance_to(parts.get_anchor("clasp_grip").global_position)<.00001,"right hand holds magnetic bridge")
		if p.phase=="rope" and ms>=2250:check(parts.get_anchor("right_grasp").global_position.distance_to(parts.get_anchor("rope_tip").global_position)<.00001,"right hand follows actual cord end")
		if ms==2000:early_vertices=parts.get_node("Rope/CordCore").mesh.get_faces().size()
		if ms==3600:check(parts.get_node("Rope/CordCore").mesh.get_faces().size()>early_vertices*4,"rope reveals successive geometry rather than scaled icon")
		check(JSON.stringify([state.d.items,state.d.qizhenLake])==initial,"native rendering cannot mutate inventory or progression")
	check(not parts.get_node("LeftHand").visible and not parts.get_node("RightHand").visible,"stow releases hands")
	check(parts.scale.x<.25,"stow moves complete object hierarchy")
	var reference:=Image.load_from_file("res://assets/native/lake_assembly/parts_reference.png")
	check(reference.get_format()==Image.FORMAT_RGBA8,"web-generated reference is actual RGBA")
	for pixel: Vector2i in [Vector2i(10,10),Vector2i(900,100),Vector2i(890,740),Vector2i(500,750)]:check(reference.get_pixelv(pixel).a==0,"background and object holes have real zero alpha")
	check(reference.get_pixel(900,185).a>.98,"rod body remains opaque enough for reference sampling")
	view.cancel();await process_frame
	check(not is_instance_valid(view),"cancel frees viewport and complete object hierarchy")
	print("LAKE_NATIVE_ASSEMBLY_OBJECTS: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
