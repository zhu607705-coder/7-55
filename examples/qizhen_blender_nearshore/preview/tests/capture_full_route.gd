extends SceneTree
const Driver=preload("res://tests/route_driver.gd")
var view: Node2D
var driver: RefCounted
var finished: bool=false
var final_frames: int=0
var phases: Dictionary={}
var frames: int=0
var inputs: FileAccess
func _initialize() -> void:
	call_deferred("start")
func start() -> void:
	view=load("res://scenes/qizhen_large_world.tscn").instantiate();root.add_child(view);view.auto_control=true;view.title_open=false;view.capture_mode=true
	driver=Driver.new();inputs=FileAccess.open("../runtime/reviewed-capture-inputs.jsonl",FileAccess.WRITE)
func _process(_dt: float) -> bool:
	if view==null:return false
	frames+=1
	driver.control(view.game)
	view.test_thrust=driver.throttle;view.test_turn=driver.turn;view.test_brake=driver.brake;view.test_use=driver.use
	if frames%6==0:inputs.store_line(JSON.stringify({"frame":frames,"thrust":driver.throttle,"turn":driver.turn,"brake":driver.brake,"use":driver.use,"game":view.game.result()}))
	var phase: int=view.game.progress
	if not phases.has(phase) and view.game.elapsed>2:
		phases[phase]=true;call_deferred("capture_phase",phase)
	if view.game.status!="running":
		final_frames+=1
		if final_frames==1:
			var f:=FileAccess.open("../runtime/reviewed-captured-route-result.json",FileAccess.WRITE);f.store_string(JSON.stringify(view.game.result(),"  "));inputs.flush();print("CAPTURED_RESULT ",JSON.stringify(view.game.result()))
		if final_frames>120:quit(0 if view.game.status=="won" else 1)
	if frames>60*240:quit(2)
	return false
func capture_phase(phase: int) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("../captures/reviewed-play-%02d.png"%phase)
