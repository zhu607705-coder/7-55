extends Control
## Read-only, short feedback over the surface already visible to the player.
## Skipping this node NEVER acknowledges a source presentation or calls State.act.
const Motion=preload("res://scripts/presentation/chapter4_time_feedback_model.gd")
const Room=preload("res://scripts/games/chapter4_room204_model.gd")
var world: Control
var world_surface: Control
var phone: Control
var read_state: Callable
var read_context: Callable
var owner_state: Dictionary={}
var owner_key: Array=[]
var initial_context: Dictionary={}
var seen: Dictionary={}
var cue: String=""
var elapsed: float=0
var reduced: bool=false
var serial: int=0
var motion: Tween
var skip_button: Button
var font: Font
var textures: Dictionary={}
var source: Dictionary={}
var baseline_world_visible: bool=false
var last_surface: Rect2
var accepted_count: int=0
var previous_focus: Control

func setup(world_view: Control,display_surface: Control,phone_view: Control,state_reader: Callable,context_reader: Callable) -> void:
	name="Chapter4TimeFeedback";world=world_view;world_surface=display_surface;phone=phone_view;read_state=state_reader;read_context=context_reader
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT);clip_contents=true
	font=load("res://scripts/ui/native_typography.gd").body_font()
	source=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-three-floor-maze.layout.json"))
	skip_button=Button.new();skip_button.name="SkipTimeFeedback";skip_button.text="略过动画";skip_button.flat=true
	skip_button.tooltip_text="只略过本次视觉效果；Tab 定位后 Enter / 空格，或点击 / 轻点"
	skip_button.add_theme_font_override("font",font);skip_button.add_theme_font_size_override("font_size",14)
	skip_button.focus_mode=Control.FOCUS_ALL;skip_button.pressed.connect(cancel);add_child(skip_button)
	# Never grab focus, install a fullscreen hit shield or intercept gameplay keys.
	visible=false;set_process(false)

func observe(action: String,previous: Dictionary,current: Dictionary,_result: Dictionary) -> void:
	if not read_state.is_valid(): return
	var live: Dictionary=read_state.call()
	if not is_same(live,owner_state): cancel();seen.clear();owner_state=live
	var next:=Motion.cue_for(action,previous,current)
	if next.is_empty() or seen.has(next): return
	seen[next]=true;serial+=1
	# Main's normal surface/old-game cleanup completes first; do not navigate.
	_begin.call_deferred(next,serial,live,_key(live),is_instance_valid(world_surface) and world_surface.is_visible_in_tree())

func _key(state: Dictionary) -> Array:
	var c: Dictionary=state.get("chapter4",{})
	return [state.get("native",{}).get("scene",""),c.get("floor",""),c.get("phase",""),c.get("roomId",""),state.get("native",{}).get("page",""),state.get("runtimeMode","")]

func _begin(next: String,ticket: int,live: Dictionary,expected_key: Array,expected_world: bool) -> void:
	if ticket!=serial: return
	if not is_inside_tree() or not is_same(read_state.call(),live) or _key(live)!=expected_key: cancel();return
	if expected_key[0]!=Motion.SCENE: cancel();return
	baseline_world_visible=is_instance_valid(world_surface) and world_surface.is_visible_in_tree()
	if baseline_world_visible!=expected_world: cancel();return
	# Physical furniture/clock feedback does not force the world open behind a phone.
	if next!="comparison" and not baseline_world_visible: cancel();return
	initial_context=read_context.call() if read_context.is_valid() else {}
	for key: String in ["game","modal","document"]:
		if _object_id(initial_context.get(key))!=0: cancel();return
	if bool(initial_context.get("control",false)): cancel();return
	var surface: Control=world_surface if baseline_world_visible else phone
	if not is_instance_valid(surface) or not surface.is_visible_in_tree() or not (surface.size.x>0 and surface.size.y>0): cancel();return
	_stop_motion();owner_state=live;owner_key=expected_key
	previous_focus=get_viewport().gui_get_focus_owner()
	if not is_instance_valid(previous_focus) and baseline_world_visible: previous_focus=world.get_viewport().gui_get_focus_owner()
	cue=next;elapsed=0;reduced=bool(live.get("native",{}).get("settings",{}).get("reduced_motion",false))
	accepted_count+=1;visible=true;set_process(true);_layout_feedback();_sample_time(0)
	if cue!=next: return
	motion=create_tween();motion.tween_method(_sample_time,0.0,float(Motion.DURATIONS[cue]),float(Motion.DURATIONS[cue]))
	motion.tween_callback(func(): if serial==ticket: cancel())

func _sample_time(value: float) -> void:
	elapsed=value;queue_redraw()

func _object_id(value: Variant) -> int:
	return value.get_instance_id() if is_instance_valid(value) and not value.is_queued_for_deletion() else 0

func _process(_delta: float) -> void:
	if cue.is_empty(): return
	var live: Dictionary=read_state.call()
	if not is_same(live,owner_state) or _key(live)!=owner_key:
		cancel();return
	if not is_instance_valid(world) or not is_instance_valid(world_surface) or baseline_world_visible!=world_surface.is_visible_in_tree(): cancel();return
	var context: Dictionary=read_context.call() if read_context.is_valid() else {}
	for key: String in ["game","modal","document"]:
		var now:=_object_id(context.get(key))
		if now!=0 and now!=_object_id(initial_context.get(key)): cancel();return
	if bool(context.get("control",false)): cancel();return
	# Turning reduced motion on immediately settles the existing read-only clip.
	# Turning it off cannot replay an already settled clip.
	reduced=reduced or bool(live.get("native",{}).get("settings",{}).get("reduced_motion",false))
	if is_instance_valid(motion):
		if get_window().has_focus():
			if not motion.is_running(): motion.play()
		else: motion.pause()
	_layout_feedback();queue_redraw()

func surface_rect() -> Rect2:
	var surface: Control=world_surface if baseline_world_visible else phone
	if not is_instance_valid(surface): return Rect2()
	var transform:=get_global_transform_with_canvas().affine_inverse()*surface.get_global_transform_with_canvas()
	return transform*Rect2(Vector2.ZERO,surface.size)

func _layout_feedback() -> void:
	var surface: Control=world_surface if baseline_world_visible else phone
	if not is_instance_valid(surface) or not surface.is_visible_in_tree() or not (get_parent() is CanvasItem): cancel();return
	var transform: Transform2D=get_parent().get_global_transform_with_canvas().affine_inverse()*surface.get_global_transform_with_canvas()
	var bounds: Rect2=transform*Rect2(Vector2.ZERO,surface.size)
	position=bounds.position;size=bounds.size
	last_surface=surface_rect()
	if not last_surface.has_area(): cancel();return
	skip_button.size=Vector2(82,32)
	skip_button.position=last_surface.position+Vector2(maxf(8,last_surface.size.x-90),8)

func _stop_motion() -> void:
	if is_instance_valid(motion): motion.kill()
	motion=null

func cancel() -> void:
	var restore_focus:=is_instance_valid(skip_button) and skip_button.has_focus() and _can_restore_focus()
	serial+=1;_stop_motion();cue="";elapsed=0;visible=false;set_process(false)
	if is_instance_valid(skip_button) and skip_button.has_focus(): skip_button.release_focus()
	if restore_focus:
		if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
		elif baseline_world_visible and is_instance_valid(world): world.grab_focus()
	queue_redraw()

func _can_restore_focus() -> bool:
	if not read_state.is_valid() or not is_same(read_state.call(),owner_state) or _key(owner_state)!=owner_key: return false
	if not is_instance_valid(world_surface) or world_surface.is_visible_in_tree()!=baseline_world_visible: return false
	var context: Dictionary=read_context.call() if read_context.is_valid() else {}
	for key: String in ["game","modal","document"]:
		if _object_id(context.get(key))!=0: return false
	return not bool(context.get("control",false))

func reset() -> void:
	cancel();seen.clear();owner_state={}

func _exit_tree() -> void:
	serial+=1;_stop_motion()

func presentation_sample() -> Dictionary:
	return Motion.sample(cue,elapsed,reduced)

func _draw() -> void:
	if cue.is_empty() or not font: return
	var pose:=presentation_sample()
	if cue=="comparison": _draw_comparison(pose)
	elif cue=="restoration": _draw_restoration(pose)
	elif cue=="minute": _draw_minute(pose)

func _text(text: String,point: Vector2,height: int,color: Color,center: bool=false) -> void:
	if center: point.x-=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,height).x*.5
	draw_string(font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,height,color)

func comparison_layout() -> Dictionary:
	var area:=surface_rect();var width:=minf(338,area.size.x-24)
	# Two small evidence strips, not a modal or a new task page. The ordinary
	# 07:55:23 stale phone reading and six-second elevator proof are not changed.
	var origin:=Vector2(area.get_center().x-width*.5,area.position.y+48)
	var stacked:=width<280
	return {"origin":origin,"width":width,"strip_width":width if stacked else (width-12)*.5,"height":149 if stacked else 86,"stacked":stacked}

func _draw_comparison(pose: Dictionary) -> void:
	var geometry:=comparison_layout();var origin: Vector2=geometry.origin;var width: float=geometry.width;var strip: float=geometry.strip_width
	var alpha: float=pose.alpha;var offset: float=pose.offset
	for i in 2:
		var p:=origin+(Vector2(0,i*63) if geometry.stacked else Vector2(i*(strip+12),0))+Vector2(offset if i==0 else -offset,0)
		draw_rect(Rect2(p,Vector2(strip,53)),Color("17252d",.94*alpha))
		draw_line(p+Vector2(0,53),p+Vector2(strip,53),Color("a8c8c6",alpha),2)
		_text("本地回放" if i==0 else "教室记录",p+Vector2(strip*.5,17),14,Color("dce6dd",alpha),true)
		_text("07:47:05" if i==0 else "07:55:00",p+Vector2(strip*.5,42),21,Color("f1dfaf",alpha),true)
	var center:=origin+Vector2(width*.5,127 if geometry.stacked else 64)
	draw_line(center+Vector2(-width*.36,0),center+Vector2(width*.36*float(pose.settle),0),Color("b6d7d1",alpha),1.5)
	_text("相差 7分55秒",center+Vector2(0,19),16,Color("f0e9d7",alpha),true)

func _world_transform() -> Transform2D:
	var context: Dictionary=world._render_context()
	# World lives in a SubViewport. Its canvas transform alone is NOT a screen
	# transform: include the existing displayed viewport's resize/DPR mapping.
	var scale_to_display: Vector2=world_surface.size/world.get_viewport_rect().size
	var display:=world_surface.get_global_transform_with_canvas()*Transform2D(0,scale_to_display,0,Vector2.ZERO)*world.get_global_transform_with_canvas()
	return get_global_transform_with_canvas().affine_inverse()*display*Transform2D(0,Vector2.ONE*float(context.zoom),0,context.origin)

func _frame(sheet_id: String,frame_id: String,position: Vector2,scale_value: float,tint: Color=Color.WHITE,angle: float=0) -> void:
	var sheet: Dictionary=Room.data().sheets[sheet_id];var frame: Dictionary=sheet.frames[frame_id]
	if not textures.has(sheet.path): textures[sheet.path]=load(sheet.path)
	var art: Texture2D=textures[sheet.path]
	if not art: return
	var src:=Room.rect(frame.sourceTrim);var pivot:=Room.point(frame.pivot)
	draw_set_transform_matrix(_world_transform()*Transform2D(angle,Vector2.ONE*scale_value,0,position))
	draw_texture_rect_region(art,Rect2(src.position-pivot,src.size),src,tint)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _draw_restoration(pose: Dictionary) -> void:
	var c: Dictionary=owner_state.chapter4
	if not Room.complete(c.get("room204Placements",[])): return
	var layout: Dictionary=Room.data().layout;var slots: Dictionary={}
	for slot: Dictionary in layout.slotTargets: slots[slot.slotId]=Room.point(slot.center)
	var placements: Dictionary={}
	for placement: Dictionary in c.room204Placements: placements[placement.pieceId]=placement.slotId
	for piece: Dictionary in layout.initialPiecePairs:
		if not placements.has(piece.pieceId): continue
		var point: Vector2=slots[placements[piece.pieceId]]
		# Reuse this actual completed 204 placement, not the separate 3F reference.
		_frame("chapter4_room204_residual",piece.residualFrame,point+Vector2(0,-float(pose.offset)),.25,Color(.47,.875,1,.64*float(pose.alpha)))
	for entity: Dictionary in Room.entities(owner_state):
		if entity.kind not in ["desk","chair"]: continue
		_frame("chapter4_room204_furniture",entity.frame,entity.position,.25,Color(.78,.94,1,.23*float(pose.alpha)),deg_to_rad(entity.angle))

func _draw_minute(pose: Dictionary) -> void:
	var registration: Dictionary=source.finalClockRuntime.visualRegistration
	var point:=Room.point(registration.axis);var radius: float=registration.statePlateFaceRadius
	# Repaint only the clock's authored blank face. Its world pivot, dimensions,
	# collisions and the already committed trusted state remain untouched.
	_frame("chapter4_clock_states","blank_face",point,float(registration.uniformScale))
	draw_set_transform_matrix(_world_transform())
	var hour_angle: float=(7.0+55.0/60.0)*TAU/12.0
	_hand(point,hour_angle,radius*.49,3.2,Color("26312c"))
	_hand(point,float(pose.minute_angle),radius*.77,2.2,Color("38423a"))
	draw_circle(point,3,Color("785128"));draw_set_transform_matrix(Transform2D.IDENTITY)
	var anchor: Vector2=_world_transform()*point
	var area:=surface_rect();anchor.x=clampf(anchor.x+radius+16,area.position.x+12,area.end.x-114)
	anchor.y=clampf(anchor.y-20,area.position.y+48,area.end.y-58)
	var alpha: float=pose.phone_alpha*pose.alpha
	draw_rect(Rect2(anchor,Vector2(98,45)),Color("17252d",.96*alpha))
	draw_rect(Rect2(anchor+Vector2(5,7),Vector2(15,29)),Color("bfccc2",alpha),false,1.5)
	_text("07:55",anchor+Vector2(28,25),21,Color("f1dfaf",alpha))
	_text("手机已同步",anchor+Vector2(26,40),12,Color("dce6dd",alpha))

func _hand(point: Vector2,angle: float,length: float,width: float,color: Color) -> void:
	draw_line(point,point+Vector2(sin(angle),-cos(angle))*length,color,width)
