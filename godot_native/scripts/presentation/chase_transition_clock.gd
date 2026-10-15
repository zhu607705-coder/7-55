extends Control
## Bounded, runtime-only clock and accessible controls for source 755m transitions.
## No State, wallet, save, model, collision or story mutation is permitted here.
## Source timing: CanteenBikeTransitionTimeline.ts, 24fps, 91 / 133 frames.
## A host owns the sole completion callback and must retain its controller proof.
signal completed(stage: String, skipped: bool)
signal cancelled(stage: String)
signal pause_changed(paused: bool)

const FPS := 24.0
const LOGICAL_SIZE := Vector2(960,540)
const START_SEGMENTS := [[0,9,"departure"],[10,40,"mount"],[41,70,"pedal"],[71,90,"handoff"]]
const FINISH_SEGMENTS := [[0,9,"arrival"],[10,39,"brake"],[40,90,"dismount"],[91,120,"parking"],[121,132,"door"]]

var stage: String=""
var status: String="idle"
var frame: int=0
var elapsed: float=0.0
var paused: bool=false
var reduced_motion: bool=false
var skipped: bool=false
var generation: int=0
var manual_clock: bool=false
var touch_buttons: Dictionary={}
var _layout_size:=Vector2.ZERO
var skip_button: Button
var pause_button: Button
var exit_button: Button
var caption: Label
class Film extends Control:
	var presenter: Control
	func _ready() -> void:
		clip_contents=true;mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if presenter!=null:presenter.draw_film(self)

var film: Film
var _font: Font

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	focus_mode=Control.FOCUS_ALL
	clip_contents=true
	_font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	film=Film.new();film.presenter=self;add_child(film)
	caption=Label.new();caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_override("font",_font)
	caption.add_theme_color_override("font_color",Color("eff4e8"))
	add_child(caption)
	pause_button=_button("暂停",func():set_paused(not paused))
	skip_button=_button("跳过动画",skip)
	exit_button=_button("退出",cancel)
	resized.connect(_layout)
	_layout();hide()

func _button(text: String,callback: Callable) -> Button:
	var button:=Button.new();button.text=text
	button.add_theme_font_override("font",_font)
	button.add_theme_font_size_override("font_size",16)
	button.pressed.connect(callback);add_child(button)
	return button

## Replacing a presentation invalidates pending deferred callbacks. The host may
## pass retry=true for the departure only; it has no effect on the earned ending.
func play(next_stage: String, retry: bool=false, reduce: bool=false) -> bool:
	if next_stage not in ["start","finish"]:return false
	generation+=1
	stage=next_stage;status="playing";frame=0;elapsed=0
	paused=false;reduced_motion=reduce;skipped=retry and stage=="start"
	show();_layout();grab_focus()
	if reduced_motion or skipped:
		frame=last_frame();elapsed=float(frame)/FPS
		_complete_generation.call_deferred(generation)
	_redraw()
	return true

func last_frame() -> int:return 90 if stage=="start" else 132
func is_playing() -> bool:return status=="playing"
func _process(delta: float) -> void:
	if not manual_clock:advance(delta)

## Visible time only; no catch-up after minimisation. Explicitly driven in tests.
func advance(delta: float) -> void:
	if status!="playing" or paused or not is_finite(delta) or delta<=0:return
	elapsed+=minf(delta,0.25)
	frame=mini(last_frame(),int(floor(elapsed*FPS+0.00001)))
	_redraw()
	if frame>=last_frame():_complete_generation(generation)

func skip() -> void:
	if status!="playing":return
	skipped=true;frame=last_frame();elapsed=float(frame)/FPS
	_redraw();_complete_generation(generation,true)

func set_paused(value: bool) -> void:
	if status!="playing" or paused==value:return
	paused=value
	touch_buttons.clear()
	if is_instance_valid(pause_button):pause_button.text="继续" if paused else "暂停"
	pause_changed.emit(paused);_redraw()

func cancel() -> void:
	if status!="playing":return
	var previous: String=stage
	generation+=1;status="cancelled";paused=false;touch_buttons.clear();hide()
	cancelled.emit(previous)

## Silent teardown is used by a replacing host; cancellation cannot release a
## success proof or cause an old start callback after scene replacement.
func dispose() -> void:
	generation+=1;status="disposed";paused=false;touch_buttons.clear();hide()
	set_process(false)

func _exit_tree() -> void:
	generation+=1;status="disposed"

func _complete_generation(expected: int,allow_paused: bool=false) -> void:
	if expected!=generation or status!="playing" or (paused and not allow_paused):return
	status="complete";paused=false;hide()
	completed.emit(stage,skipped)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:set_paused(true)

func _input(event: InputEvent) -> void:
	if not visible or status not in ["playing","failed"]:return
	if event is InputEventScreenTouch:
		var point: Vector2=get_global_transform_with_canvas().affine_inverse()*event.position
		if event.pressed:
			for button: Button in [pause_button,skip_button,exit_button]:
				if button.visible and not button.disabled and button.get_rect().has_point(point):
					touch_buttons[event.index]=button;get_viewport().set_input_as_handled();return
		elif touch_buttons.has(event.index):
			var button: Button=touch_buttons[event.index];touch_buttons.erase(event.index)
			get_viewport().set_input_as_handled()
			if not event.canceled and is_instance_valid(button) and button.visible and not button.disabled and button.get_rect().has_point(point):button.pressed.emit()
		return
	if status!="playing":return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_ESCAPE:set_paused(not paused);get_viewport().set_input_as_handled()
		elif event.physical_keycode==KEY_ENTER:skip();get_viewport().set_input_as_handled()

func _layout() -> void:
	if not is_instance_valid(caption):return
	if size!=_layout_size:touch_buttons.clear();_layout_size=size
	var film_bounds: Rect2=film_rect()
	film.position=film_bounds.position;film.size=LOGICAL_SIZE;film.scale=Vector2.ONE*(film_bounds.size.x/960)
	var mobile: bool=size.x<600
	var button_y: float=maxf(0,size.y-60)
	var gap: float=10
	var bw: float=minf(140,(size.x-40-2*gap)/3)
	var left: float=(size.x-(bw*3+gap*2))/2
	for pair: Array in [[pause_button,0],[skip_button,1],[exit_button,2]]:
		pair[0].position=Vector2(left+(bw+gap)*pair[1],button_y)
		pair[0].size=Vector2(bw,46)
	caption.position=Vector2(16,maxf(8,button_y-66 if mobile else button_y-47))
	caption.size=Vector2(maxf(1,size.x-32),56 if mobile else 36)
	caption.add_theme_font_size_override("font_size",16 if mobile else 19)
	caption.text="纸条沿主干道飞走。" if stage=="start" else "755 米骑行完成，纸条钻进剧院。"
	pause_button.text="继续" if paused else "暂停"
	_redraw()

## Same full-scene sizing seam as the live chase; controls stay physical pixels.
func uses_activity_layout() -> bool:return true
func configure_activity_layout(available: Vector2,_compact: bool) -> void:
	custom_minimum_size=Vector2.ZERO
	position=Vector2.ZERO;scale=Vector2.ONE
	size=available
	_layout()

func film_rect() -> Rect2:
	var available:=Vector2(maxf(1,size.x),maxf(1,size.y-136))
	var scale_factor: float=minf(available.x/LOGICAL_SIZE.x,available.y/LOGICAL_SIZE.y)
	var extent:=LOGICAL_SIZE*scale_factor
	return Rect2((available-extent)/2,extent)

func snapshot() -> Dictionary:
	return {"stage":stage,"status":status,"frame":frame,"last_frame":last_frame(),"elapsed":elapsed,"paused":paused,"skipped":skipped,"generation":generation,"pose":pose_at(stage,frame),"film_rect":film_rect()}

static func _progress(at: int, first: int,last: int) -> float:
	var p: float=clampf(float(at-first)/maxf(1,last-first),0,1)
	return p*p*(3-2*p)

## This mapping contains presentation values only. It preserves the authored
## order: stand/grip/leg-over/pedal -> ride -> brake/foot-down/park -> paper escape.
static func pose_at(which: String, at: int) -> Dictionary:
	var current: int=clampi(at,0,90 if which=="start" else 132)
	var result: Dictionary={"pose":"ride","progress":1.0,"segment":"", "pedal":0.0,"wheel":0.0,"speed":0.0,"mount":1.0,"travel":0.0,"park":0.0,"walk":0.0,"paper":true,"door":0.0}
	for entry: Array in (START_SEGMENTS if which=="start" else FINISH_SEGMENTS):
		if current>=entry[0] and current<=entry[1]:result.segment=entry[2];break
	if which=="start":
		if current<=16:result.pose="stand_left";result.mount=0
		elif current<=23:result.pose="grip";result.progress=_progress(current,17,23);result.mount=0
		elif current<=33:result.pose="leg_over";result.progress=_progress(current,24,33);result.mount=result.progress
		elif current<=40:result.pose="seated_balance";result.progress=_progress(current,34,40)
		elif current<=70:
			var p: float=_progress(current,41,70)
			result.pose="pedal_press";result.progress=p;result.pedal=-PI/4*p;result.wheel=-.35*p;result.speed=.22*p;result.paper=false
		else:
			var p: float=_progress(current,71,90)
			result.progress=p;result.pedal=-PI/4-p*PI*1.25;result.wheel=-.35-p*PI*2.6;result.speed=lerpf(.22,1,p);result.travel=p
	else:
		result.pedal=-PI/4
		if current<=9:result.pose="brake";result.progress=0;result.speed=1;result.wheel=-float(current)/9*PI*1.6
		elif current<=39:
			var p: float=_progress(current,10,39)
			result.pose="brake";result.progress=p;result.speed=lerpf(1,.35,p);result.wheel=-PI*1.6-p*PI*2.1;result.paper=false
		elif current<=55:
			var p: float=_progress(current,40,55)
			result.pose="brake";result.speed=lerpf(.35,0,p);result.wheel=-PI*3.7-p*.8;result.travel=p
		elif current<=66:result.pose="left_foot_down";result.progress=_progress(current,56,66);result.travel=1
		elif current<=82:
			result.pose="dismount_leg_over";result.progress=_progress(current,67,82);result.mount=1-result.progress;result.travel=1
		elif current<=90:result.pose="stand_with_bike";result.progress=_progress(current,83,90);result.mount=0;result.travel=1
		elif current<=107:
			result.pose="push_bike";result.progress=_progress(current,91,107);result.park=result.progress;result.mount=0;result.travel=1
		elif current<=120:
			result.pose="stand_left";result.walk=_progress(current,108,120);result.park=1;result.mount=0;result.travel=1
		else:
			result.pose="stand_left";result.walk=1;result.park=1;result.mount=0;result.travel=1;result.door=_progress(current,121,126)
	return result

func _redraw() -> void:
	queue_redraw()
	if is_instance_valid(film):film.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("101b20"))

func draw_film(_canvas: CanvasItem) -> void:
	# Rendered by the native 3D specialization. This base has no art fallback.
	pass
