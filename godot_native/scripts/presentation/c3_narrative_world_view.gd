extends Control
const Paper=preload("res://scripts/presentation/c3_paper_art.gd")
const Reversal=preload("res://scripts/presentation/c3_reversal_view.gd")
var reversal: RefCounted=Reversal.new()
var world: Control
var session: RefCounted
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func screen(p: Vector2) -> Vector2: return (p-world.camera)*world.zoom+world.size/2
func _draw() -> void:
	if session==null or not is_instance_valid(world) or world.scene_id!=session.scene: return
	if session.sequence_id=="theater_reversal": reversal.draw(self,session,world.size)
	if session.sequence_id=="theater_admission":
		var tail: float=float(session.spec.get("tailMs",0))
		if tail>0: draw_rect(Rect2(Vector2.ZERO,world.size),Color("08060a",clampf((session.elapsed_ms-session.duration_ms+tail)/tail,0,1)))
	for drop: Dictionary in session.trail():
		var center: Vector2=screen(drop.point)
		var polygon:=PackedVector2Array()
		for index in range(25):
			var angle: float=TAU*index/24
			polygon.append(center+Vector2(cos(angle)*float(drop.width)/2,sin(angle)*float(drop.height)/2)*world.zoom)
		draw_colored_polygon(polygon,Color("8fd8e6",drop.alpha))
	var pose: Dictionary=session.paper_pose()
	if pose.is_empty() or float(pose.alpha)<=0: return
	if not pose.wet:
		Paper.draw(self,screen(pose.point),world.zoom*float(pose.scale),float(pose.angle),-1,float(pose.alpha)); return
	# QizhenLoopScene.ensureWetPaperTexture: same 52x34 generated paper geometry.
	draw_set_transform(screen(pose.point),deg_to_rad(float(pose.angle)),Vector2.ONE*world.zoom*float(pose.scale))
	var points:=PackedVector2Array([Vector2(-22,-13),Vector2(17,-16),Vector2(21,8),Vector2(-18,12)])
	draw_colored_polygon(points,Color("dce6df",pose.alpha))
	points.append(points[0]); draw_polyline(points,Color("315f6b",pose.alpha),3)
	for edge: Array in [[Vector2(-14,-7),Vector2(8,-9)],[Vector2(-15,-1),Vector2(12,-3)],[Vector2(-11,5),Vector2(7,3)]]:
		draw_line(edge[0],edge[1],Color("577a82",float(pose.alpha)*.86),2)
	draw_set_transform(Vector2.ZERO)
