extends Control
const SharedPauseOverlay = preload("res://scripts/ui/native_pause_overlay.gd")
signal finished(result: Dictionary)
signal cancelled
const TARGET: Array = [34.0,52.0,70.0]
const WIND: Array = [5.5,6.5,7.5]
const KEYS: Array = [[KEY_Z,KEY_C],[KEY_A,KEY_D],[KEY_Q,KEY_E]]
const NO_POINTER: int = -1
const MOUSE_POINTER: int = -2
const TRACK_LEFT: float = 145.0
const TRACK_UNIT: float = 6.6
var shared_pause_overlay
var positions: Array = [78.0,22.0,38.0]
var directions: Array = [0,0,0]
var controlled: Array = [false,false,false]
var moves: int = 0
var elapsed: float = 0
var stable: float = 0
var started: bool = false
var paused: bool = false
var settled: bool = false
var label: Label
var start_button: Button
var exit_button: Button
var row_centers: Array = [175.0,265.0,355.0]
var presentation_scale: float = -1
var compact_presentation: bool = false
var cloud_size := Vector2(68,48)
var layout_transform := Transform2D.IDENTITY
var layout_viewport := Vector2.ZERO
var pointer_owner: int = NO_POINTER
var pointer_band: int = -1
var pointer_target: float = 0.0
var pointer_offset: float = 0.0
var pointer_origin := Vector2.ZERO
var pointer_moved: bool = false
var held_keys: Dictionary = {}
var skip_resume_frame: bool = false
var show_controls: bool = false
var FONT: Font = preload("res://scripts/ui/native_typography.gd").body_font()

func setup(_config: Dictionary) -> void:
	_clear_controls()
	positions=[78.0,22.0,38.0]; controlled=[false,false,false]
	moves=0; elapsed=0; stable=0
	started=false; paused=false; settled=false; skip_resume_frame=false; show_controls=false
	if is_node_ready():
		start_button.disabled=false; exit_button.disabled=false
		_sync_shared_pause(); refresh()

func _ready() -> void:
	shared_pause_overlay=SharedPauseOverlay.mount(self,_resume_shared_pause)
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	size=Vector2(960,540)
	label=Label.new()
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",FONT)
	label.add_theme_color_override("font_color",Color("eaf1f7"))
	add_child(label)
	start_button=Button.new()
	_style_button(start_button)
	start_button.text="开始调整"
	start_button.pressed.connect(func() -> void:
		if started and not paused: _pause_game()
		else: _resume_shared_pause())
	add_child(start_button)
	exit_button=Button.new()
	_style_button(exit_button)
	exit_button.text="返回天气"
	exit_button.pressed.connect(_cancel_game)
	add_child(exit_button)
	_apply_presentation_layout(true)
	refresh()

func _notification(what: int) -> void:
	if what==NOTIFICATION_EXIT_TREE:
		_clear_controls(); started=false; settled=true
	elif what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_PAUSED]:
		_pause_game()
	elif what==NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree() and not is_visible_in_tree():
		_pause_game()
	elif what==NOTIFICATION_WM_MOUSE_EXIT and pointer_owner==MOUSE_POINTER:
		_pause_game()

func _can_control() -> bool:
	return started and not paused and not settled and is_inside_tree() and is_visible_in_tree() and not get_tree().paused

func cloud_center(band: int) -> Vector2:
	return Vector2(TRACK_LEFT+float(positions[band])*TRACK_UNIT,float(row_centers[2-band]))

func cloud_rect(band: int) -> Rect2:
	return Rect2(cloud_center(band)-cloud_size/2,cloud_size)

func _gui_input(event: InputEvent) -> void:
	# Only the visible cloud can begin a gesture. GUI dispatch respects other
	# controls/overlays; once captured, _input receives moves and outside releases.
	if not _can_control() or pointer_owner!=NO_POINTER: return
	if event is InputEventMouseButton and event.device!=InputEvent.DEVICE_ID_EMULATION and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		if _begin_drag(MOUSE_POINTER,event.position): accept_event()
	elif event is InputEventScreenTouch and event.pressed and not event.canceled:
		if _begin_drag(event.index,event.position): accept_event()

func _begin_drag(owner: int, point: Vector2) -> bool:
	for band: int in range(3):
		if not cloud_rect(band).has_point(point): continue
		pointer_owner=owner; pointer_band=band; pointer_origin=point
		pointer_offset=point.x-cloud_center(band).x
		pointer_target=float(positions[band]); pointer_moved=false
		queue_redraw()
		return true
	return false

func _input(event: InputEvent) -> void:
	if not _can_control(): return
	if event is InputEventKey:
		var code: int=event.physical_keycode if event.physical_keycode else event.keycode
		for pair: Array in KEYS:
			if code not in pair: continue
			if event.pressed and not event.echo: held_keys[code]=true
			elif not event.pressed: held_keys.erase(code)
			get_viewport().set_input_as_handled()
			return
	if pointer_owner==NO_POINTER: return
	var local: InputEvent=make_input_local(event)
	if event is InputEventScreenTouch and event.index==pointer_owner:
		if event.canceled: _pause_game()
		elif not event.pressed: _release_drag()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==pointer_owner:
		_move_drag(local.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and pointer_owner==MOUSE_POINTER and event.device!=InputEvent.DEVICE_ID_EMULATION and event.button_index==MOUSE_BUTTON_LEFT:
		if event.canceled: _pause_game()
		elif not event.pressed: _release_drag()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and pointer_owner==MOUSE_POINTER and event.device!=InputEvent.DEVICE_ID_EMULATION:
		if not event.button_mask&MOUSE_BUTTON_MASK_LEFT: _pause_game()
		else: _move_drag(local.position)
		get_viewport().set_input_as_handled()

func _move_drag(point: Vector2) -> void:
	if not Rect2(Vector2.ZERO,size).has_point(point):
		_pause_game()
		return
	if absf(point.x-pointer_origin.x)*presentation_scale>=4.0: pointer_moved=true
	# This is a player-selected aim, never the authored TARGET. Cloud positions
	# are written only by the original bounded velocity step below.
	pointer_target=clampf((point.x-pointer_offset-TRACK_LEFT)/TRACK_UNIT,2,98)
	queue_redraw()

func _release_drag() -> void:
	if pointer_band>=0: directions[pointer_band]=0
	pointer_owner=NO_POINTER; pointer_band=-1; pointer_moved=false
	queue_redraw()

func _clear_controls() -> void:
	_release_drag()
	held_keys.clear(); directions=[0,0,0]

func set_direction(band: int, direction: int) -> void:
	if directions[band]!=direction and direction!=0:
		moves+=1
		controlled[band]=true
	directions[band]=direction

func _process(delta: float) -> void:
	_apply_presentation_layout()
	_sync_shared_pause()
	if not _can_control(): return
	if skip_resume_frame:
		skip_resume_frame=false
		return
	for band: int in range(3):
		var dir: int=int(held_keys.has(KEYS[band][1]))-int(held_keys.has(KEYS[band][0]))
		if pointer_band==band:
			# The captured pointer owns its band; another device cannot override it.
			var error: float=pointer_target-float(positions[band])
			dir=int(signf(error)) if pointer_moved and absf(error)*TRACK_UNIT*presentation_scale>2.0 else 0
		set_direction(band,dir)
	var dt: float=clampf(delta,0,0.05) if is_finite(delta) else 0.0
	elapsed+=dt*1000
	var aligned: bool=true
	for band: int in range(3):
		positions[band]=clampf(positions[band]+(-WIND[band]+directions[band]*30.0)*dt,2,98)
		aligned=aligned and absf(positions[band]-TARGET[band])<=8
	stable=minf(1000,stable+dt*1000) if aligned else 0.0
	refresh()
	if stable>=1000 and controlled.all(func(v: Variant) -> bool: return bool(v)):
		# Retire before emitting: synchronous host removal or repeated callbacks
		# cannot submit a second result or a cancellation after success.
		settled=true; started=false
		_clear_controls(); start_button.disabled=true; exit_button.disabled=true
		finished.emit({"moves":moves,"cloudOffsets":positions.duplicate(),"controlledBands":controlled.duplicate(),"stableMs":stable,"elapsedMs":elapsed})

func _pause_game() -> void:
	_clear_controls()
	if not started or settled: return
	paused=true
	_sync_shared_pause()
	refresh()

func _cancel_game() -> void:
	if settled: return
	settled=true; started=false; paused=false; stable=0; show_controls=false
	_clear_controls()
	start_button.disabled=true; exit_button.disabled=true
	_sync_shared_pause()
	cancelled.emit()

func _style_button(button: Button) -> void:
	button.set_meta("tactile_keep_layout",true)
	button.set_meta("tactile_compensated_type",true)
	button.add_theme_font_override("font",FONT)
	button.add_theme_color_override("font_color",Color("14212a"))
	button.add_theme_color_override("font_hover_color",Color("14212a"))
	button.add_theme_color_override("font_pressed_color",Color("14212a"))
	for state: String in ["normal","hover","pressed","focus"]:
		var style:=StyleBoxFlat.new()
		style.bg_color=Color("c9e96e") if state=="pressed" else Color("e8e6db")
		style.border_color=Color("15243a") if state=="focus" else Color("9aafae")
		style.set_border_width_all(3 if state=="focus" else 2); style.set_corner_radius_all(4)
		button.add_theme_stylebox_override(state,style)

func _apply_presentation_layout(force: bool=false) -> void:
	if not is_instance_valid(exit_button): return
	var transform: Transform2D=get_global_transform_with_canvas()
	var viewport_size: Vector2=get_viewport_rect().size
	var factor: float=maxf(.15,minf(transform.x.length(),transform.y.length()))
	if not force and transform==layout_transform and viewport_size==layout_viewport: return
	if presentation_scale>0 and (transform!=layout_transform or viewport_size!=layout_viewport): _pause_game()
	layout_transform=transform; layout_viewport=viewport_size
	presentation_scale=factor; compact_presentation=960*factor<620
	var body_font: int=maxi(20,int(ceil(15.0/factor)))
	var button_font: int=maxi(18,int(ceil(14.0/factor)))
	label.add_theme_font_size_override("font_size",body_font)
	label.position=Vector2(40,4 if compact_presentation else 25)
	label.size=Vector2(880,ceil(FONT.get_height(body_font)))
	cloud_size=Vector2(1.4,1.0)*maxf(48,ceil(44.0/factor))
	var footer_h: float=maxf(48,ceil(44.0/factor))
	var footer_y: float=540-10-footer_h if compact_presentation else 445
	if compact_presentation:
		var first: float=label.position.y+label.size.y+4+cloud_size.y/2
		var last: float=footer_y-4-cloud_size.y/2
		row_centers=[first,(first+last)/2,last]
	else: row_centers=[175.0,265.0,355.0]
	for button: Button in [start_button,exit_button]: button.add_theme_font_size_override("font_size",button_font)
	start_button.size=Vector2(maxf(180,FONT.get_string_size("开始调整",HORIZONTAL_ALIGNMENT_LEFT,-1,button_font).x+24),footer_h)
	start_button.position=Vector2(480-start_button.size.x/2,footer_y)
	exit_button.size=Vector2(maxf(150,FONT.get_string_size(exit_button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button_font).x+24),footer_h)
	exit_button.position=Vector2(40,footer_y)
	refresh()

func refresh() -> void:
	if is_instance_valid(label):
		label.text="拖云吹风 %d/3 · 稳定 %.1f/1.0 秒" % [controlled.count(true),stable/1000.0]
	if is_instance_valid(start_button):
		start_button.text="暂停" if started else "开始调整"
		start_button.visible=not paused and not settled
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540),Color("15243a"))
	for row: int in range(3):
		var band: int=2-row
		var y: float=float(row_centers[row])
		var h: float=cloud_size.y
		draw_rect(Rect2(TRACK_LEFT,y-h/2,660,h),Color("233b54"))
		var target_rect:=Rect2(TRACK_LEFT+(TARGET[band]-8)*TRACK_UNIT,y-h/2,16*TRACK_UNIT,h)
		draw_rect(target_rect,Color("427b68"))
		draw_line(target_rect.position,target_rect.position+Vector2(0,h),Color("a2c6aa"),2)
		draw_line(target_rect.end-Vector2(0,h),target_rect.end,Color("a2c6aa"),2)
		var center:=cloud_center(band)
		var ink:=Color("c9e96e") if pointer_band==band else Color("eaf1f7")
		# The silhouette grows with the measured touch target, not an invisible
		# full-row hit zone. Its center and motion use the same source mapping.
		draw_circle(center,h*.5,ink)
		draw_circle(center+Vector2(-h*.35,h*.15),h*.35,ink)
		draw_circle(center+Vector2(h*.35,h*.15),h*.35,ink)
		if pointer_band==band and pointer_moved and directions[band]!=0:
			var wind_end:=center+Vector2(-directions[band]*h*.9,0)
			for dy: float in [-h*.15,h*.15]:
				draw_line(wind_end+Vector2(0,dy),center+Vector2(-directions[band]*h*.55,dy),ink,2)

func _sync_shared_pause() -> void:
	if not is_instance_valid(shared_pause_overlay): return
	var pause_actions: Array[Dictionary]=[]
	if is_instance_valid(exit_button) and exit_button.visible:
		pause_actions.append({"text":exit_button.text,"callback":_cancel_game,"disabled":exit_button.disabled})
	if paused:
		pause_actions.append({"text":"操作说明","callback":_show_controls})
	shared_pause_overlay.set_actions(pause_actions)
	shared_pause_overlay.present(is_visible_in_tree() and paused and not settled)
	if paused and show_controls:
		shared_pause_overlay.body.text="按住云朵，向左右拖动吹风。\n高层 Q/E · 中层 A/D · 低层 Z/C"
		shared_pause_overlay.body.show()
	if paused and is_instance_valid(start_button): start_button.hide()

func _show_controls() -> void:
	show_controls=true
	_sync_shared_pause()

func _resume_shared_pause() -> void:
	if settled or not is_inside_tree() or not is_visible_in_tree() or get_tree().paused: return
	skip_resume_frame=paused
	_clear_controls()
	started=true; paused=false; show_controls=false
	_sync_shared_pause(); refresh()
