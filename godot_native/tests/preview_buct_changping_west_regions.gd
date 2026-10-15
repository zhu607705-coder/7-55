extends SceneTree
## Same proven native manual boot shape as manual_buct_changping_wenli.gd.
## Production default is used without enable-flag overrides.
var campus:Node2D
var positions:Array=[]
func _initialize()->void:run.call_deferred()
func run()->void:
	campus=load("res://campuses/buct_changping/scenes/playable.tscn").instantiate()
	root.add_child(campus)
	current_scene=campus
	await process_frame;await physics_frame;await process_frame
	campus.visitor.position=Vector2(566,836)
	campus._layout_ui();campus.camera.reset_smoothing()
	campus.status.text="西邻连续高清 · WASD实际行走 · 鼠标查看楼体 · Esc关闭卡片"
	physics_frame.connect(record)
	create_timer(150.0).timeout.connect(finish)
func record()->void:
	if not is_instance_valid(campus) or not is_instance_valid(campus.visitor):return
	var p:Vector2=campus.visitor.position
	if positions.is_empty() or p.distance_to(Vector2(positions[-1][0],positions[-1][1]))>.2:positions.append([p.x,p.y,campus.is_walkable(p)])
func finish()->void:
	var f=FileAccess.open(OS.get_environment("BUCT_WEST_QA_DIR").path_join("west-manual-movement.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"observed_actual_positions":positions,"source":"actual human native input; production default enabled with no flag overrides"},"  "));f.close();quit(0)
