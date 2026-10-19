extends SceneTree
## Actual accepted student PNGs and the production pilot. Synthetic fixtures are
## tested separately by test_buct_student_visual.gd / test_buct_student_distance.gd.
const ROOT := "res://campuses/buct_shared/student/"
const PILOT := "res://campuses/buct_pilots/chaoyang/scenes/promenade.tscn"
const DIRECTIONS := {"down":Vector2.DOWN,"left":Vector2.LEFT,"right":Vector2.RIGHT,"up":Vector2.UP}
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:run.call_deferred()
func check(value: bool, message: String) -> void:
	checks+=1
	if not value:failures.append(message);push_error("BUCT_STUDENT: "+message)

func run() -> void:
	var profile: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"data/student-movement-profile.json"))
	check(float(profile.cycle_stride_body_heights)>0,"actual walk profile has a positive distance stride")
	var provenance: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"data/provenance.json"))
	check(provenance.outputs.size()==10,"exactly the ten accepted RGBA atlases are disclosed")
	var provenance_text:=FileAccess.get_file_as_string(ROOT+"data/provenance.json")
	check(not provenance_text.contains("chatgpt.com") and not provenance_text.contains("libfile_") and not provenance_text.contains("/workspace/"),"public provenance excludes private service identities and local paths")
	var accepted_files: Dictionary={}
	for output in provenance.outputs:
		var path: String=ROOT+str(output.file)
		check(FileAccess.get_sha256(path)==str(output.sha256),"accepted original PNG hash: "+str(output.file))
		var texture: Texture2D=load(path)
		check(texture.get_size()==Vector2(output.canvas_size[0],output.canvas_size[1]),"original source dimensions are exact: "+str(output.file))
		accepted_files[str(output.file).get_file()]=true
	var atlas_paths: Dictionary={"idle":str(profile.atlas)}
	atlas_paths.merge(profile.available_walk_atlases)
	for key in atlas_paths:
		check(accepted_files.has(str(atlas_paths[key])),"runtime consumes only a documented accepted atlas: "+key)
		var texture: Texture2D=load(ROOT+"assets/"+str(atlas_paths[key]))
		check(texture!=null,"actual atlas loads: "+key)
		if texture==null:continue
		var picture: Image=texture.get_image()
		check(picture.get_format()==Image.FORMAT_RGBA8,"actual atlas is RGBA: "+key)
		check(picture.get_pixel(0,0).a<float(profile.alpha_cutoff),"actual atlas corner is transparent under the documented alpha cutoff: "+key)
	var app=load(PILOT).instantiate();root.add_child(app);await process_frame
	app.visitor.set_physics_process(false)
	var visitor: CharacterBody2D=app.visitor
	var visual: Node2D=visitor.character_visual
	check(visitor.scale==Vector2.ONE,"character body uses world/source units")
	check(is_equal_approx(visitor.get_node("FeetCollision").shape.radius,3.0*0.55),"unchanged effective foot collider from #120")
	check(visual.get_parent()==visitor and visual.position==Vector2.ZERO,"visual is a child anchored at the native feet")
	check(not visitor.show_registration_ring,"diagnostic ring is hidden")
	check(is_equal_approx(visual.target_height,10.0),"Chaoyang visual height is explicit, independent of physics")
	check(is_equal_approx(visitor.speed,8.0) and is_equal_approx(app.tour_speed,8.0),"short pilot uses the matched character pace for both manual and guided motion")
	check(visual.has_walk_animation,"publication requires accepted walking frames in all four directions")
	check(visual.available_walk_directions.size()==4,"no missing walk direction is silently shipped")
	for direction in DIRECTIONS:
		var frames: Array=profile.directions[direction].get("walk",[])
		check(frames.size()=={"down":8,"left":8,"right":8,"up":6}[direction],"accepted distinct walking pose count: "+direction)
		if frames.size()<2:continue
		visual.reset_pose()
		var seen: Dictionary={}
		var fixed_position: Vector2=visitor.position
		var fixed_velocity: Vector2=visitor.velocity
		var stride: float=visual.target_height*float(profile.cycle_stride_body_heights)
		for step in range(64):
			visual.advance_motion(DIRECTIONS[direction]*stride/64.0,1.0/60)
			seen[visual.frame_index]=true
			check(visual.current_foot_global().distance_to(visitor.global_position)<0.0001,"actual registered foot stays fixed: "+direction)
		check(seen.size()==frames.size(),"all accepted phases are reachable: "+direction)
		check(visitor.position==fixed_position and visitor.velocity==fixed_velocity,"visual cannot mutate physical movement: "+direction)
		var saved_phase: float=visual.distance_phase
		visual.advance_motion(Vector2.ZERO,100.0)
		check(not visual.walking and visual.frame_index==0 and visual.facing==direction,"stop holds correct directional idle: "+direction)
		check(is_equal_approx(visual.distance_phase,saved_phase),"blocked movement does not invent distance: "+direction)
	# The controller reports the post-collision displacement, not requested speed.
	app.reset_demo();app.visitor.set_physics_process(true)
	Input.action_press("buct_pilot_walk_right")
	await physics_frame;await physics_frame;await physics_frame
	check(visual.walking and visual.facing=="right","actual namespaced input moves and animates the actor")
	# Holding towards an excluded trunk foot must stop both position and gait.
	visitor.position=app.trees[0].source_anchor+Vector2(-4.15,0)
	for i in range(4):await physics_frame
	var blocked_position: Vector2=visitor.position
	var blocked_phase: float=visual.distance_phase
	for i in range(8):await physics_frame
	check(visitor.position.is_equal_approx(blocked_position) and not visual.walking,"blocked requested input cannot walk in place")
	check(is_equal_approx(visual.distance_phase,blocked_phase),"blocked native controller does not advance the distance clock")
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not visual.walking and visitor.velocity==Vector2.ZERO,"focus loss settles immediately, even before another physics tick")
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await physics_frame
	check(not visual.walking,"focus return cannot resurrect a held pose")
	app.start_guide();await physics_frame;await physics_frame
	app.reset_demo()
	check(visitor.position==app.spawn and not visual.walking and visual.facing=="down" and visual.distance_phase==0,"reset and teleport start from exact idle without counting teleport distance")
	var rest: Transform2D=visual.sprite.transform
	for i in range(5):
		app.start_guide();await physics_frame;await physics_frame
		app.reset_demo()
		check(visual.sprite.transform.is_equal_approx(rest),"repeated guide/reset is deterministic")
	var visual_ref: WeakRef=weakref(visual);var sprite_ref: WeakRef=weakref(visual.sprite)
	app.queue_free()
	for i in range(5):await process_frame
	check(visual_ref.get_ref()==null and sprite_ref.get_ref()==null,"scene exit frees the real visual and its sprite")
	print("BUCT_STUDENT_ARTWORK ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," failures=",failures.size(),"; actual PNGs, four-way publication gate, native controller")
	quit(0 if failures.is_empty() else 1)
