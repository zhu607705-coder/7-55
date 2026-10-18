extends Control
## PR144's cove shot only; the actual channel world remains the sole simulation.
## No model, obstacle set, story callback, or progression write lives here.
signal event(action: String, value: Variant) # Generic world_effect host contract; never emitted.
signal dismissed(reason: String)
const Session = preload("res://scripts/media/c3_swan_entrance_session.gd")
const Entrance = preload("res://scripts/games/qizhen_swan_entrance.gd")
const KayakArt = preload("res://scripts/ui/kayak_visual.gd")
# Same opaque full-body atlas regions/anchors as the unchanged PR144 preview.
const REGIONS: Array[Rect2] = [Rect2(40,180,385,214),Rect2(452,70,365,325),Rect2(871,180,440,220),Rect2(1345,100,400,300),Rect2(40,451,405,380),Rect2(447,548,420,285),Rect2(910,600,440,225),Rect2(1430,570,310,242)]
const ANCHORS: Array[Vector2] = [Vector2(201,185),Vector2(197,293),Vector2(261,183),Vector2(195,263),Vector2(201,344),Vector2(209,247),Vector2(244,175),Vector2(160,209)]
const REDUCED_HOLD: float = 1.2
var session: RefCounted
var world: Control
var read_state: Callable
var timeline: RefCounted = Entrance.new()
var kayak_art: RefCounted = KayakArt.new()
var lake_plate: Texture2D
var cleanplate: Texture2D
var atlas: Texture2D
var font: Font
var caption: Label
var pose: Dictionary = {}
var camera: Vector2 = Vector2(925,440)
var world_zoom: float = 1.0
var hud_scale: float = 1.0
var hud_height: float = 82.0
var elapsed: float = 0.0
var reported: bool = false
var focus_paused: bool = false
var pointer_owners: Dictionary = {}

func setup(config: Dictionary) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	z_index = 110
	set_meta("blocks_input",true)
	session = config.get("session")
	world = config.get("world")
	read_state = config.get("read_state",Callable())
	if not session is Session or not read_state.is_valid() or not is_instance_valid(world) or not session.begin(State.d,world,self): cancel(); return
	lake_plate = load("res://assets/rpg/interiors/qizhen_lake_swan_cove.png")
	cleanplate = load("res://assets/native/chapter3/swan_cove_gate_cleanplate.png")
	atlas = load("res://assets/native/chapter3/black_swan_entrance_atlas.png")
	font = world.font
	# Discard any old cove gesture, including a pending touch release. Do not
	# touch the host's player, model, camera, collision or chase proof.
	world.cancel_exploration_gestures()
	caption = Label.new()
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.max_lines_visible = 2
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_override("font",font)
	caption.add_theme_font_size_override("font_size",19)
	caption.add_theme_color_override("font_color",Color("e7efe4"))
	add_child(caption)
	if session.reduced_motion: timeline.skip()
	_update_pose()
	grab_focus()

func _context_valid() -> bool:
	if not session is Session or not is_instance_valid(world) or not session.matches(State.d,world,self): return false
	var host: Dictionary = read_state.call().get("native",{}).get("host",{})
	return bool(host.get("world_visible",true)) and not bool(host.get("minigame_open",false)) and not bool(host.get("phone_modal_open",false))

func _focused() -> bool:
	return not focus_paused and bool(read_state.call().get("native",{}).get("host",{}).get("focused",true))

func _process(delta: float) -> void:
	if reported: return
	if not _context_valid(): cancel(); return
	if not _focused():
		pointer_owners.clear()
		world.cancel_exploration_gestures()
		return
	if not is_finite(delta) or delta <= 0: return
	elapsed += minf(delta,0.05)
	var done: bool = elapsed >= REDUCED_HOLD if session.reduced_motion else timeline.advance(minf(delta,0.05))
	_update_pose()
	if done: _dismiss("completed")

func _update_pose() -> void:
	pose = timeline.pose()
	camera = Vector2(925,440) if session.reduced_motion else pose.camera
	world_zoom = 1.0 if session.reduced_motion else float(pose.zoom)
	# Only UI scales against the shell. Keep touch targets and prose legible
	# when the single 960x540 surface is letterboxed on a compact phone.
	var display_scale: float = float(read_state.call().get("native",{}).get("host",{}).get("world_display_scale",1.0))
	hud_scale = clampf(1.0/maxf(0.1,display_scale),1.0,3.0)
	hud_height = maxf(82.0,52.0*hud_scale)
	var compact: bool = hud_scale>1.6
	caption.position = Vector2(20,size.y-hud_height-14)
	caption.size = Vector2(maxf(0,skip_rect().position.x-32),hud_height)
	caption.add_theme_font_size_override("font_size",roundi(14*hud_scale) if compact else roundi(19*hud_scale))
	# The preview's south-mouth controls are not the formal westbound route.
	if compact:
		caption.text = "纸条已固定\n黑天鹅冲出了围栏" if timeline.elapsed<5.85 else "进入浮排河道\n左右交替划桨，向西返航"
	else:
		caption.text = "纸条已固定，黑天鹅冲出了围栏" if timeline.elapsed<5.85 else "接下来进入浮排河道 · 交替划桨，向西返回小码头"
	queue_redraw()

func skip_intro() -> void:
	if reported: return
	if not _context_valid(): cancel(); return
	if not _focused(): return
	timeline.skip()
	_dismiss("skipped")

func cancel() -> void:
	_dismiss("cancelled")

func _dismiss(reason: String) -> void:
	if reported: return
	reported = true
	pointer_owners.clear()
	if session is Session: session.dismiss(self,reason == "cancelled")
	if is_instance_valid(world): world.cancel_exploration_gestures()
	# Keep blocking through queue_free so the release/skip event cannot reach
	# a channel paddle in the same dispatch. Main returns focus on tree_exited.
	dismissed.emit(reason)
	queue_free()

func _exit_tree() -> void:
	if reported: return
	reported = true
	pointer_owners.clear()
	if session is Session: session.dismiss(self,true)
	if is_instance_valid(world): world.cancel_exploration_gestures()
	dismissed.emit("cancelled")

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT] and is_inside_tree():
		# Keep blocking the formal world while unfocused; its physical chase
		# must not start behind a suspended presentation.
		focus_paused = true
		pointer_owners.clear()
		if is_instance_valid(world): world.cancel_exploration_gestures()
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_WM_WINDOW_FOCUS_IN]: focus_paused = false
	elif what == NOTIFICATION_RESIZED:
		pointer_owners.clear()
		if is_instance_valid(caption) and not reported: _update_pose()

func skip_rect() -> Rect2:
	var dimensions := Vector2(maxf(104,74*hud_scale),maxf(50,44*hud_scale))
	return Rect2(Vector2(size.x-18,size.y-24)-dimensions,dimensions)

func _gui_input(input: InputEvent) -> void:
	if reported: accept_event(); return
	if input is InputEventKey:
		if input.pressed and not input.echo and input.keycode in [KEY_SPACE,KEY_ENTER,KEY_ESCAPE]: skip_intro()
	elif input is InputEventMouseButton and input.button_index == MOUSE_BUTTON_LEFT:
		# Native touch owns its gesture; Godot's emulated mouse never dismisses.
		if input.device != -1: _pointer(input.position,input.pressed,-1,false)
	elif input is InputEventScreenTouch:
		_pointer(input.position,input.pressed,input.index,input.canceled)
	accept_event()

func _pointer(point: Vector2, pressed: bool, id: int, cancelled: bool) -> void:
	if cancelled: pointer_owners.erase(id); return
	if pressed:
		if skip_rect().has_point(point): pointer_owners[id] = true
	elif pointer_owners.has(id):
		pointer_owners.erase(id)
		if skip_rect().has_point(point): skip_intro()

func _scale_factor() -> float:
	return world_zoom * minf(size.x/1280.0,size.y/720.0)

func _screen(point: Vector2) -> Vector2:
	return size/2+_frame_offset()+(point-camera)*_scale_factor()

func _frame_offset() -> Vector2:
	# Frame the same cove actors above the taller compact caption; this
	# shifts the presentation crop only, never the underlying host camera.
	return Vector2(0,-maxf(0,hud_height-82)*0.85)

func _ellipse(point: Vector2,radii: Vector2,color: Color,width: float=1.5) -> void:
	var points := PackedVector2Array()
	for i: int in range(33): points.append(point+Vector2(cos(TAU*i/32),sin(TAU*i/32))*radii)
	draw_polyline(points,color,width,true)

func _draw() -> void:
	if lake_plate == null or pose.is_empty(): return
	var z: float = _scale_factor()
	var origin: Vector2 = size/2+_frame_offset()-camera*z
	draw_rect(Rect2(Vector2.ZERO,size),Color("0b1b24"))
	draw_texture_rect(lake_plate,Rect2(origin,Vector2(1672,941)*z),false)
	var patch := Rect2(915,264,58,119)
	draw_texture_rect_region(cleanplate,Rect2(origin+patch.position*z,patch.size*z),patch)
	for edge: int in range(7):
		var blend: float = 1.0-float(edge+1)/8.0
		for strip: Rect2 in [Rect2(patch.position+Vector2(edge,0),Vector2(1,patch.size.y)),Rect2(patch.position+Vector2(patch.size.x-1-edge,0),Vector2(1,patch.size.y)),Rect2(patch.position+Vector2(0,edge),Vector2(patch.size.x,1)),Rect2(patch.position+Vector2(0,patch.size.y-1-edge),Vector2(patch.size.x,1))]:
			draw_texture_rect_region(lake_plate,Rect2(origin+strip.position*z,strip.size*z),strip,Color(1,1,1,blend))
	draw_set_transform(_screen(Vector2(938,264)),-1.15*float(pose.gate),Vector2.ONE*z)
	draw_line(Vector2.ZERO,Vector2(0,117),Color("263125"),8)
	draw_line(Vector2(-1,0),Vector2(-1,117),Color("9b7b43"),4)
	draw_line(Vector2(5,4),Vector2(5,114),Color("51462d"),3)
	for rung: int in range(8,113,16): draw_line(Vector2(-4,rung),Vector2(9,rung+4),Color("6e613a"),3)
	draw_circle(Vector2.ZERO,5,Color("b39762"))
	draw_circle(Vector2(0,117),4,Color("8f744c"))
	draw_set_transform(Vector2.ZERO)
	var p: Vector2 = pose.position
	var alpha: float = pose.reveal
	_ellipse(_screen(p+Vector2(0,2)),Vector2(42,12)*z,Color(.02,.12,.16,.35*alpha),3*z)
	var frame: int = int(pose.frame) if float(pose.blend)<0.5 else int(pose.next_frame)
	var tilt: float = clampf(wrapf(float(pose.heading)-PI,-PI,PI),-0.65,0.65)
	draw_set_transform(_screen(p),tilt,Vector2.ONE*z*0.27)
	draw_texture_rect_region(atlas,Rect2(-ANCHORS[frame],REGIONS[frame].size),REGIONS[frame],Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)
	if not session.reduced_motion and timeline.elapsed>4.75 and timeline.elapsed<6.5:
		for side: int in [-1,1]:
			for n: int in range(9):
				var age: float = fmod(timeline.elapsed-4.75+float(n)*0.073,0.65)
				var offset := Vector2(side*(20+age*65+float(n)*1.8),-sin(age/0.65*PI)*(15+float(n)*2.3)+age*10)
				draw_circle(_screen(p+offset),(1.5+(n%3))*z,Color(.82,.97,1,(1-age/0.65)*.85))
	var boat: Dictionary = session.source_pose
	kayak_art.draw(self,_screen(boat.position),z,boat,0.0 if session.reduced_motion else elapsed*1000)
	var paper: Vector2 = _screen(boat.position+Vector2(-9,-17).rotated(float(boat.heading)+PI/2))
	draw_set_transform(paper,0.0 if session.reduced_motion else sin(elapsed*3)*.08,Vector2.ONE*z)
	draw_colored_polygon(PackedVector2Array([Vector2(-7,-8),Vector2(8,-7),Vector2(7,8),Vector2(-8,7)]),Color("eee5c5"))
	draw_line(Vector2(-4,-3),Vector2(4,-3),Color("827c67"),1)
	draw_line(Vector2(-4,1),Vector2(2,1),Color("827c67"),1)
	draw_set_transform(Vector2.ZERO)
	var bars: float = 36*(0.0 if session.reduced_motion else float(pose.letterbox))
	if bars>0:
		draw_rect(Rect2(0,0,size.x,bars),Color("081219"))
		draw_rect(Rect2(0,size.y-bars,size.x,bars),Color("081219"))
	draw_rect(Rect2(12,size.y-hud_height-14,size.x-24,hud_height),Color(.025,.09,.12,.94))
	draw_rect(skip_rect(),Color("263d49"))
	var button_font: int = roundi(16*hud_scale)
	draw_string(font,skip_rect().position+Vector2(8,skip_rect().size.y/2+button_font*.35),"跳过",HORIZONTAL_ALIGNMENT_CENTER,skip_rect().size.x-16,button_font,Color("e7efe4"))
	var title_font: int = roundi(16*hud_scale) if hud_scale>1.6 else 20
	draw_rect(Rect2(0,0,size.x,maxf(36,32*hud_scale)),Color(.025,.07,.10,.92))
	draw_string(font,Vector2(18,maxf(30,23*hud_scale)),"启真湖 · 黑天鹅出场",HORIZONTAL_ALIGNMENT_LEFT,-1,title_font,Color("e6eee6"))
