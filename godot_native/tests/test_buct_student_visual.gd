extends SceneTree
const VISUAL=preload("res://campuses/buct_shared/student/scripts/registered_character_visual.gd")
var checks:=0
func expect(value: bool,message: String) -> void:
	checks+=1
	if not value:push_error(message);quit(1)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var image:=Image.create(256,256,false,Image.FORMAT_RGBA8)
	image.fill(Color(1,1,1,0))
	var texture:=ImageTexture.create_from_image(image)
	var data={"reference_body_height":100,"directions":{}}
	for direction in ["down","left","right","up"]:
		data.directions[direction]={"idle":[{"region":[10,20,60,110],"foot":[31,107]}],"walk":[{"region":[75,20,68,108],"foot":[28,106],"duration":0.1},{"region":[148,20,72,113],"foot":[39,111],"duration":0.12}]}
	var holder:=Node2D.new();root.add_child(holder)
	holder.position=Vector2(300,140);holder.rotation=0.12;holder.scale=Vector2.ONE*1.8
	var visual:=Node2D.new();visual.set_script(VISUAL);holder.add_child(visual)
	visual.position=Vector2(70,127)
	expect(visual.configure(data,texture,10),"valid profile accepted")
	expect(visual.has_walk_animation,"four-way actual-frame capability")
	for velocity in [Vector2.DOWN,Vector2.RIGHT,Vector2.LEFT,Vector2.UP]:
		for i in range(30):
			visual.set_motion(velocity,0.05)
			expect(visual.current_foot_global().distance_to(visual.global_position)<0.0001,"per-frame foot stays fixed in transformed parent")
	visual.reset_pose()
	var rest: Transform2D=visual.sprite.transform
	for i in range(30):
		visual.set_motion(Vector2.RIGHT,0.173);visual.reset_pose()
		expect(visual.sprite.transform.is_equal_approx(rest),"reset returns exact registered idle offset")
	expect(visual.facing=="down" and not visual.walking,"reset idle facing")
	var idle_only=data.duplicate(true)
	for direction in idle_only.directions:idle_only.directions[direction].erase("walk")
	expect(visual.configure(idle_only,texture,6),"idle-only genuine assets accepted without pretending walk frames")
	expect(not visual.has_walk_animation,"missing walk explicitly reported")
	visual.set_motion(Vector2.LEFT,2.0)
	expect(visual.facing=="left" and visual.frame_index==0,"idle fallback has correct facing")
	expect(visual.current_foot_global().distance_to(visual.global_position)<0.0001,"6px campus target preserves feet")
	var invalid=data.duplicate(true);invalid.directions.down.idle[0].region=[240,240,60,110]
	expect(not visual.configure(invalid,texture,10),"out-of-bounds frame refused")
	expect(not visual.sprite.visible,"invalid update does not show stale character")
	var bad_height=data.duplicate(true);bad_height.atlas_reference_body_heights={"idle":0}
	expect(not visual.configure(bad_height,texture,10),"zero per-atlas reference height rejected")
	var mixed_phase=data.duplicate(true);mixed_phase.directions.right.walk[0].phase=0.0
	expect(not visual.configure(mixed_phase,texture,10),"partially specified phases rejected")
	var unsorted_phase=data.duplicate(true);unsorted_phase.directions.right.walk[0].phase=0.5;unsorted_phase.directions.right.walk[1].phase=0.25
	expect(not visual.configure(unsorted_phase,texture,10),"descending phase registration rejected")
	expect(visual.configure(data,texture,10),"valid profile can recover after refused configuration")
	visual.queue_free();holder.queue_free();await process_frame
	print("CHARACTER_INTERFACE PASS ",checks," synthetic geometry assertions; no new character artwork or rendered preview claimed")
	quit()
