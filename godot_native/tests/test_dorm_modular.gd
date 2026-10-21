extends SceneTree
const Scene = preload("res://scenes/objects/dorm_modular_candidate.tscn")
const Art = preload("res://scripts/presentation/c3_paper_art.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var room := Scene.instantiate()
	root.add_child(room)
	await process_frame
	var furnishings: Node2D = room.get_node("Furnishings")
	check(furnishings.get_child_count()==18,"18 independent furniture roots")
	var desks := 0
	for object in furnishings.get_children():
		check(object is StaticBody2D,"independent collision owner "+str(object.name))
		check(object.get_node("Art").texture is AtlasTexture,"alpha atlas sprite "+str(object.name))
		check(object.get_node("Footprint").shape is RectangleShape2D,"footprint "+str(object.name))
		check(object.get_meta("pivot")=="bottom_center","documented depth pivot")
		if str(object.name).begins_with("desk_"):desks+=1
	check(desks==4,"exactly four joined desks")
	for i in range(1,4):
		var a: Node2D=furnishings.get_node("desk_"+str(i))
		var b: Node2D=furnishings.get_node("desk_"+str(i+1))
		var b_region: Rect2=b.get_meta("source_region")
		check(is_equal_approx(a.position.y,b.position.y-b_region.size.y),"adjacent desk ends share exact seam")
	var desk: Node2D=furnishings.get_node("desk_1")
	var lamp: Sprite2D=desk.get_node("lamp_blue_0")
	var before: Vector2=lamp.global_position
	desk.position+=Vector2(10,0)
	check(lamp.global_position.is_equal_approx(before+Vector2(9,0)),"loose prop follows its owner transform")
	desk.position-=Vector2(10,0)
	var image: Image=load("res://assets/native/dorm_modular/furniture_atlas.png").get_image()
	check(image.get_pixel(470,800).a==0,"aisle genuinely alpha, not baked floor")
	check(image.get_pixel(470,250).a>.9,"cabinet remains opaque")
	var paper: Node2D=room.get_node("Canonical0755Paper")
	check(paper.commands()==Art.frame_commands(-1),"paper resting art exact shared source")
	paper.set_process(false)
	paper.animate=true
	for i in range(4):
		paper.elapsed=i*.13
		paper._process(0)
		check(paper.commands()==Art.frame_commands(i),"paper animated pose exact shared source "+str(i))
	paper.reduced_motion=true
	paper._process(0)
	check(paper.frame==-1,"reduced motion retains canonical resting paper")
	check(furnishings.scale.x==furnishings.scale.y,"one uniform furniture scale")
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/native/dorm_modular/manifest.json"))
	check(manifest.status=="candidate_not_production","review boundary explicit")
	check("unverified" in str(manifest.sink),"real sink uncertainty explicit")
	room.queue_free()
	await process_frame
	print("DORM_MODULAR_CHECKS ",checks," FAILURES ",failures)
	quit(1 if failures else 0)
