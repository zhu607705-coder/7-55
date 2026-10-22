extends SceneTree
const VISUAL=preload("res://campuses/buct_shared/student/scripts/registered_character_visual.gd")
var checks:=0
func expect(value:bool,message:String)->void:
	checks+=1
	if not value:push_error(message);quit(1)
func _initialize()->void:call_deferred("run")
func run()->void:
	var image:=Image.create(256,256,false,Image.FORMAT_RGBA8);image.fill(Color.TRANSPARENT)
	var texture:=ImageTexture.create_from_image(image)
	var data={"reference_body_height":100,"cycle_stride_body_heights":0.8,"directions":{}}
	for direction in ["down","left","right","up"]:
		data.directions[direction]={"idle":[{"region":[0,0,20,100],"foot":[10,99]}],"walk":[]}
		for i in range(8):data.directions[direction].walk.append({"region":[i*25,0,20,100],"foot":[10,99]})
	var results:=[]
	for fps in [24,30,60,144,240,480]:
		var visual:=Node2D.new();visual.set_script(VISUAL);root.add_child(visual)
		expect(visual.configure(data,texture,10),"fixture profile accepted")
		for i in range(fps):visual.advance_motion(Vector2(11.5/fps,0),1.0/fps)
		expect(is_equal_approx(visual.distance_phase,0.4375),"phase uses11.5 world distance, not render frames")
		expect(visual.frame_index==3,"same visible phase at all render rates")
		var saved:float=visual.distance_phase
		visual.advance_motion(Vector2.ZERO,0)
		var idle_texture=visual.sprite.texture
		for i in range(20):visual.advance_motion(Vector2.ZERO,1.0/fps)
		expect(is_equal_approx(visual.distance_phase,saved) and not visual.walking,"blocked/stopped movement does not advance gait")
		expect(visual.frame_index==0,"stop settles to stable idle")
		expect(visual.sprite.texture==idle_texture,"idle AtlasTexture reused without tick allocation")
		visual.advance_motion(Vector2(0,-0.5),1.0/fps)
		expect(visual.facing=="up" and visual.current_foot_global().distance_to(visual.global_position)<0.0001,"turn keeps registered foot")
		visual.reset_pose();expect(visual.distance_phase==0,"reset clears motion phase")
		visual.queue_free();await process_frame
	print("DISTANCE_ANIMATION PASS ",checks," fixture checks,24/30/60/144/240/480fps; no artwork gait or slip claim")
	quit()
