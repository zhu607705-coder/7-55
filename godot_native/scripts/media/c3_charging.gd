extends Control
## Nonmodal station overlay: player motion stays enabled, moving away cancels.
signal event(action: String,value: Variant)
const PIXEL_FONT = preload("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
const Session = preload("res://scripts/media/c3_charging_session.gd")
var session: RefCounted
var read_state: Callable
var project_position: Callable
var callback: String = "c3_charge_result"
var reported: bool = false

func setup(config: Dictionary) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	session = config.get("session")
	read_state = config.get("read_state",Callable())
	project_position = config.get("project_position",Callable())
	callback = str(config.get("on_event",callback))
	if not session is Session or not read_state.is_valid(): queue_free(); return
	if not session.begin(read_state.call()): session.cancel()

func _process(_delta: float) -> void:
	if session == null or reported: return
	session.sample(read_state.call())
	queue_redraw()
	if session.phase in ["complete","cancelled"]:
		reported = true
		event.emit(callback,session)
		queue_free()

func cancel() -> void:
	if session != null: session.cancel()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: cancel()

func _exit_tree() -> void:
	if session != null and not reported:
		session.cancel()
		event.emit(callback,session)

func _draw() -> void:
	if session == null: return
	var origin: Vector2 = project_position.call(Vector2(595,773)) if project_position.is_valid() else Vector2(size.x/2,size.y-106)
	var drawing_scale: float=1.0
	if project_position.is_valid():
		var adjacent: Vector2=project_position.call(Vector2(596,773))
		drawing_scale=adjacent.distance_to(origin)
	draw_set_transform(origin,0,Vector2.ONE*drawing_scale)
	var anchor: Vector2=Vector2.ZERO
	# Source cabinet retrofit and tethered phone: retained wood plate stays below.
	draw_rect(Rect2(anchor+Vector2(-31,-42),Vector2(62,18)),Color("172f32"))
	draw_rect(Rect2(anchor+Vector2(-31,-42),Vector2(62,18)),Color("96d9c8"),false,2)
	draw_string(PIXEL_FONT,anchor+Vector2(-13,-28),"充电",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("d4f7e6"))
	draw_rect(Rect2(anchor+Vector2(-28,-17),Vector2(56,52)),Color("142d30"))
	draw_rect(Rect2(anchor+Vector2(-28,-17),Vector2(56,52)),Color("71897f"),false,2)
	draw_rect(Rect2(anchor+Vector2(-15,-11),Vector2(28,12)),Color("c5e8da"),false,2)
	draw_rect(Rect2(anchor+Vector2(14,-8),Vector2(3,6)),Color("c5e8da"))
	draw_rect(Rect2(anchor+Vector2(-12,-8),Vector2(22*clampf(session.elapsed_ms/2200.0,0,1),6)),Color("72dfad"))
	for offset: float in [-15.0,15.0]:
		draw_rect(Rect2(anchor+Vector2(offset-5,8),Vector2(10,5)),Color("9db2ad"))
		draw_polyline(PackedVector2Array([anchor+Vector2(offset,13),anchor+Vector2(offset,25),anchor+Vector2(offset-7,25),anchor+Vector2(offset-7,18)]),Color("a1c1b5"),2)
	draw_rect(Rect2(anchor+Vector2(4.5,10),Vector2(15,24)),Color("121e26"))
	draw_rect(Rect2(anchor+Vector2(4.5,10),Vector2(15,24)),Color("bad5cf"),false,2)
	draw_rect(Rect2(anchor+Vector2(7.5,13),Vector2(9,14)),Color("72dfad"))
	draw_string(PIXEL_FONT,anchor+Vector2(-32,60),"补电 %d%%" % int(session.elapsed_ms/22),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("d4f7e6"))
