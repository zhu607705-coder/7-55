extends SceneTree
const View=preload("res://scripts/presentation/chapter4_endless_stair_view.gd")
var game
var started:=false
var completing:=false
var frames:=0
var limit_ticks:=720
var max_markers:=0
var events:Array=[]
var captured:Dictionary={}
func _initialize()->void:start.call_deferred()
func start()->void:
	DirAccess.make_dir_recursive_absolute("user://endless_stair_b3")
	if "--final-preview" in OS.get_cmdline_user_args():limit_ticks=1560
	if "--full-run" in OS.get_cmdline_user_args():limit_ticks=7200
	root.size=Vector2i(1280,720);root.position=Vector2i(40,120)
	game=View.new();root.add_child(game)
	await process_frame
	game.set_process(false);game.set_physics_process(false)
	game.demo_mode=true;game.capture_frames.clear();game._start();game._present(0)
	started=true
func _process(_delta:float)->bool:
	if not started or completing:return false
	game._physics_process(1.0/60)
	game._present(1.0/60)
	frames+=1
	var m=game.model
	var marker_count:=0
	for marker in game.floor_markers:
		if marker.modulate.a>.001:marker_count+=1
	max_markers=maxi(max_markers,marker_count)
	if not m.pursuit_event.is_empty():
		var state:Dictionary=m.pursuit_state();state["tick"]=m.tick;state["gap"]=m.player.x-m.guard.x
		events.append(state)
	var key:String=m.pursuit_phase+"_"+m.pursuit_pattern
	if not captured.has(key) and m.pursuit_phase_ticks>=int(m.pursuit_phase_duration*.65):
		captured[key]=true
		save_frame.call_deferred(key)
	if m.tick>=limit_ticks or m.status!="running":
		completing=true
		var result={"ticks":m.tick,"status":m.status,"gates":m.gates_passed,"guard_fell":m.guard_fell,"rendered_frames":frames,"max_simultaneous_04":max_markers,"events":events,"audio_cues":game.rhythm_feedback.cues_played,"input":"one distinct 60Hz simulated input step per frame; native offline MovieWriter, not human play"}
		FileAccess.open("user://endless_stair_b3/B3_native_capture.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
		print("B3_NATIVE_CAPTURE ",JSON.stringify(result))
		finish.call_deferred()
	return false
func save_frame(key:String)->void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://endless_stair_b3/endless_stair_captures"))
	root.get_texture().get_image().save_png("user://endless_stair_b3/endless_stair_captures/B3_"+key+".png")
func finish()->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://endless_stair_b3/endless_stair_captures/B3_native_finish.png")
	var failed:bool=game.model.status=="failed"
	game.rhythm_feedback.pause_audio()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
