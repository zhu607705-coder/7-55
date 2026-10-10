extends Control
## Source door presentation only. This owns no story facts, answers or proof.
signal opened
var source: Dictionary={}
var read_state: Callable
var project_position: Callable
var elapsed_ms := 0.0
var finished := false
var cancelled := false
var plate: Texture2D
func setup(state_reader: Callable, projector: Callable) -> void:
	read_state=state_reader; project_position=projector
	source=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter4-context-source.json"))
	plate=load("res://assets/rpg/interiors/finale/chapter4-755/states/a1_0755_morning.png")
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_meta("blocks_input",true)
func valid_context() -> bool:
	if not read_state.is_valid(): return false
	var s: Dictionary=read_state.call(); var c: Dictionary=s.get("chapter4",{})
	return s.get("native",{}).get("scene","")=="duan_yongping_temporal_maze" and c.get("phase","")=="exterior_closure" and c.get("floor","")=="A1" and c.get("roomId","")=="a1_exterior"
func _process(delta: float) -> void:
	if finished or cancelled or source.is_empty(): return
	if not valid_context(): cancel(); return
	if not get_window().has_focus(): return
	elapsed_ms+=minf(delta,.05)*1000
	queue_redraw()
	if elapsed_ms>=float(source.presentationMs):
		finished=true; set_meta("blocks_input",false); opened.emit()
func progress() -> float:
	if source.is_empty(): return 0
	var t:=clampf((elapsed_ms-float(source.door.startDelayMs))/float(source.door.openingDurationMs),0,1)
	return (1-cos(t*PI))*.5
func cancel() -> void:
	cancelled=true; set_meta("blocks_input",false); queue_free()
func _draw() -> void:
	if source.is_empty() or not project_position.is_valid() or cancelled: return
	var origin: Vector2=project_position.call(Vector2.ZERO)
	var zoom: float=origin.distance_to(project_position.call(Vector2.RIGHT))
	draw_set_transform(origin,0,Vector2.ONE*zoom)
	var doorway: Dictionary=source.door.doorwayBounds
	var box:=Rect2(doorway.x,doorway.y,doorway.width,doorway.height)
	# Original source gradient and threshold marks, beneath original plate crops.
	for y in range(int(box.size.y)):
		draw_rect(Rect2(box.position+Vector2(0,y),Vector2(box.size.x,1)),Color("081018").lerp(Color("40515a"),float(y)/box.size.y))
	draw_line(box.position+Vector2(8,58),box.position+Vector2(box.size.x-8,58),Color("9ebbc2",.28),2)
	draw_line(box.position+Vector2(24,78),box.position+Vector2(box.size.x-24,78),Color("9ebbc2",.28),2)
	draw_rect(Rect2(box.position+Vector2(7,box.size.y-9),Vector2(box.size.x-14,8)),Color("d8e7d9",.58*progress()))
	var scale_x:=lerpf(1,float(source.door.finalLeafScaleX),progress())
	for leaf: Dictionary in source.door.leaves:
		var b: Dictionary=leaf.bounds; var target:=Rect2(b.x,b.y,b.width*scale_x,b.height)
		if leaf.hinge=="right": target.position.x+=float(b.width)-target.size.x
		draw_texture_rect_region(plate,target,Rect2(b.x,b.y,b.width,b.height))
	draw_set_transform(Vector2.ZERO)
