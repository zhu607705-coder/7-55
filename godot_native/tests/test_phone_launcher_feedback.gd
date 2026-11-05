extends SceneTree
## Real launcher builder and native input. No route/progression is faked by feedback.
## Touch events are desktop emulation, not physical-device acceptance.
const Pages=preload("res://scripts/ui/phone_pages.gd")
const Utilities=preload("res://scripts/chapters/phone_utilities.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
var checks:=0
var failures:=0
var pages:=Pages.new()
var routes: Array=[]
var actions: Array=[]
var surface: Control
var home: Control
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("LAUNCHER FEEDBACK: "+message)
func frames(count: int=3) -> void:
	for unused in count:await process_frame
func pointer(point: Vector2,down: bool) -> void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT
	event.position=point;event.global_position=point;event.pressed=down
	root.push_input(event,true);await frames(2)
func motion(point: Vector2,pressed: bool=false) -> void:
	var event:=InputEventMouseMotion.new();event.position=point;event.global_position=point
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(event,true);await frames(2)
func key(code: Key,down: bool) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
	root.push_input(event,true);await frames(2)
func touch(point: Vector2,down: bool,index: int=0,cancelled: bool=false) -> void:
	var event:=InputEventScreenTouch.new();event.position=point;event.pressed=down
	event.index=index;event.canceled=cancelled
	Input.parse_input_event(event);Input.flush_buffered_events();await frames(2)
func center(control: Control) -> Vector2:return control.get_global_transform_with_canvas()*(control.size/2)
func build(state: Dictionary,scale_factor: float) -> void:
	if is_instance_valid(surface):surface.free();await frames()
	pages.home_editing=false;pages.home_focus_id=""
	surface=Control.new();surface.position=Vector2(20,30);surface.scale=Vector2.ONE*scale_factor
	surface.theme=Ui.make_theme(load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"))
	root.add_child(surface)
	home=pages.build("phone_home",{},state);surface.add_child(home);await frames(6)
	routes.clear();actions.clear()
func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	create_timer(80).timeout.connect(func():push_error("Launcher feedback watchdog");quit(2))
	pages.page_requested.connect(func(id: String):routes.append(id))
	pages.action_requested.connect(func(id: String,value: Variant):actions.append([id,value]))
	root.size=Vector2i(500,1000)
	for scale_factor: float in [1.0,390.0/430.0]:
		var state: Dictionary=root.get_node("State").initial();state.flags.codeScattered=true
		var original:=JSON.stringify(state)
		await build(state,scale_factor)
		var actual: Array=[]
		for app: Button in home.find_children("HomeApp_*","Button",true,false):
			var id:=str(app.name).trim_prefix("HomeApp_");actual.append(id)
			check(app.size.is_equal_approx(Vector2(48,48)),"exact authored hit frame "+id)
			check(app.tooltip_text==Utilities.LABELS[id] and app.accessibility_name==Utilities.LABELS[id],"authored app identity "+id)
			check(app.mouse_default_cursor_shape==Control.CURSOR_POINTING_HAND,"pointer affordance "+id)
			var feedback: Control=app.get_node_or_null("LauncherFeedback")
			check(feedback!=null,"actual builder installs feedback "+id)
			if feedback==null:continue
			check(feedback.mouse_filter==Control.MOUSE_FILTER_IGNORE and feedback.focus_mode==Control.FOCUS_NONE,"feedback cannot become a hit target "+id)
			check(app.get_theme_stylebox("normal").bg_color!=app.get_theme_stylebox("hover").bg_color,"real normal and hover paints differ "+id)
			check(app.get_theme_stylebox("hover").bg_color!=app.get_theme_stylebox("pressed").bg_color,"real hover and press paints differ "+id)
			for mode: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
				var style: StyleBoxFlat=app.get_theme_stylebox(mode)
				check(style.shadow_size==0 and style.shadow_color.a==0,"no raised material in "+mode+" "+id)
				check(style.expand_margin_left==0 and style.expand_margin_right==0,"state does not enlarge hit frame "+mode+" "+id)
			if id!="settings":check(app.get_node_or_null("OriginalAppArtwork_"+id)!=null,"authored brand remains "+id)
		check(actual==["wechat","tiyi","zjuding","settings","control_center"],"prologue availability and order unchanged, unavailable apps gain no interaction")
		var gear: Control=home.find_child("HomeGearObject",true,false)
		check(gear!=null and gear.get_parent()==home.find_child("HomeApp_settings",true,false).get_parent() and gear.size.is_equal_approx(Vector2(48,48)),"physical gear remains independent of app feedback")
		var button: Button=home.find_child("HomeApp_wechat",true,false)
		var feedback: Control=button.get_node_or_null("LauncherFeedback")
		if feedback==null:continue
		var before_rect:=button.get_rect();var art: Control=button.get_node("OriginalAppArtwork_wechat")
		var before_art:=art.get_transform();var point:=center(button)
		await motion(point)
		check(button.get_draw_mode()==BaseButton.DRAW_HOVER and feedback.visual_state=="hover","real pointer enters visible hover at "+str(scale_factor))
		await pointer(point,true)
		check(feedback.visual_state=="pressed" and routes.is_empty(),"press feedback precedes original release action")
		await motion(Vector2(4,4),true);await pointer(Vector2(4,4),false)
		check(routes.is_empty() and feedback.visual_state!="pressed","drag outside cancels without an app open")
		for repeat in 2:
			await motion(point);await pointer(point,true);await pointer(point,false)
		check(routes==["wechat","wechat"],"repeated native click activates exactly once per click")
		routes.clear();await motion(Vector2(4,4));button.grab_focus();await frames()
		check(button.has_focus() and feedback._last_focus,"keyboard focus has a separate shape cue")
		await key(KEY_ENTER,true);check(feedback.visual_state=="pressed","keyboard hold shows same press state")
		await key(KEY_ENTER,false);check(routes==["wechat"],"native Enter route remains single-shot")
		routes.clear();button.release_focus();await motion(Vector2(4,4))
		await touch(point,true);check(feedback.visual_state=="pressed","native touch hold uses visible press feedback")
		await touch(point,false);check(routes==["wechat"],"native touch tap opens original route exactly once")
		routes.clear();button.release_focus();await motion(Vector2(4,4))
		await touch(point,true)
		var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=Vector2(4,4);drag.relative=drag.position-point
		Input.parse_input_event(drag);Input.flush_buffered_events();await frames(2)
		await touch(Vector2(4,4),false)
		check(routes.is_empty() and feedback.visual_state!="pressed","touch drag outside cancels visual and action")
		await touch(point,true);await touch(point,false,0,true)
		check(routes.is_empty() and feedback.visual_state!="pressed","cancelled touch inside does not open an app or leave a press: routes="+str(routes)+" visual="+feedback.visual_state)
		routes.clear()
		await touch(point,true,0);await touch(point,true,1);await touch(point,false,1)
		check(routes.is_empty(),"secondary finger cannot release the primary app press")
		await touch(point,false,0)
		check(routes==["wechat"] and feedback.visual_state!="pressed","two-finger contact still produces one primary tap")
		routes.clear()
		button.disabled=true;await frames();check(feedback.visual_state=="disabled","disabled clears interactive marks")
		await motion(point);await pointer(point,true);await pointer(point,false)
		check(routes.is_empty(),"disabled cannot activate")
		button.disabled=false;button.release_focus();await motion(Vector2(4,4))
		check(button.get_rect()==before_rect and art.get_transform()==before_art,"feedback never moves frame or original app artwork")
		check(JSON.stringify(state)==original,"presentation never commits progression or a save mutation")
		# The prologue gear app remains its existing object action, not Settings.
		var settings: Button=home.find_child("HomeApp_settings",true,false)
		await motion(center(settings));await pointer(center(settings),true);await pointer(center(settings),false)
		check(actions==[["c1_gear",null]] and routes.is_empty(),"gear route and physical puzzle semantics remain exact")
	# Existing desktop rearrangement is not replaced by the feedback renderer.
	var editable_state: Dictionary=root.get_node("State").initial();editable_state.actOne.phase="complete"
	await build(editable_state,1.0)
	var editable: Button=home.find_child("HomeApp_wechat",true,false)
	editable.grab_focus();await key(KEY_F2,true);await key(KEY_F2,false)
	check(pages.home_editing and editable.editing,"native F2 still enters authored rearrangement")
	await key(KEY_RIGHT,true);await key(KEY_RIGHT,false)
	check(actions.size()==1 and actions[0][0]=="phone_app_move","rearrangement emits original controller intent")
	await key(KEY_ESCAPE,true);await key(KEY_ESCAPE,false)
	check(not pages.home_editing and actions.back()[0]=="phone_refresh","Escape still exits editing through original action")
	await motion(center(editable));await pointer(center(editable),true)
	await create_timer(.50).timeout
	check(pages.home_editing and editable.editing,"original long hold still enters rearrangement")
	await pointer(center(editable),false)
	check(routes.is_empty(),"long-hold release cannot also activate its app")
	surface.queue_free();await frames()
	print("PHONE_LAUNCHER_FEEDBACK: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
