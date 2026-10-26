extends SceneTree
const Pages=preload("res://scripts/ui/phone_pages.gd")
const Identity=preload("res://scripts/ui/native_tiyi_identity.gd")
const Seven=preload("res://scripts/ui/tiyi_seven_art.gd")
var checks=0
var failures=0
var b=Pages.new()
var s: Dictionary
var page: Control
var actions: Array=[]
var routes: Array=[]
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("TIYI LAYOUT: "+message)
func frames() -> void:
	for i in range(4):await process_frame
func show() -> void:
	if is_instance_valid(page):page.free()
	page=b.build("tiyi",{},s);root.add_child(page);await frames()
func button(name_value: String) -> Button:return page.find_child(name_value,true,false)
func click(target: Button) -> void:
	check(target!=null,"rendered input exists")
	if not target:return
	var point=target.get_global_rect().get_center()
	var motion=InputEventMouseMotion.new();motion.position=point;root.push_input(motion)
	for pressed in [true,false]:
		var event=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;root.push_input(event)
	await frames()
func run() -> void:
	root.size=Vector2i(430,860)
	b.action_requested.connect(func(id,value):actions.append([id,value]))
	b.page_requested.connect(func(id):routes.append(id))
	for text_scale in [.85,1.0,1.35]:
		for started in [false,true]:
			s=root.get_node("State").initial();s.native.page="tiyi";s.networkMode="cellular"
			s.native.settings.text_scale=text_scale;s.actOne.phase="movement_required";s.actOne.tiyiUpdateStage="installed";s.actOne.characterNamed=true;s.actOne.exerciseStarted=started
			b.entry_session.route(s);b.entry_session.advance(1400);await show()
			var exercise=button("TiyiExercise");var scroll: ScrollContainer=page.find_child("TiyiScroll",true,false)
			check(exercise!=null and exercise.disabled==started,"exercise availability follows controller state")
			check(scroll.size.x==378 and scroll.horizontal_scroll_mode==ScrollContainer.SCROLL_MODE_DISABLED,"one bounded vertical scroll owner")
			for label in exercise.find_children("*","Label",true,false):
				check(exercise.get_global_rect().encloses(label.get_global_rect()),"exercise owns complete text bounds at font scale "+str(text_scale))
				check(label.size.y+1>=label.get_minimum_size().y,"exercise does not clip wrapped Chinese")
			var previous_end=0.0
			for id in Identity.TITLES:
				var control=button("TiyiMenu_"+id)
				check(control.size.y>=52 and control.position.y>=previous_end,"menu hit areas are ordered without overlap")
				check(control.get_global_rect().end.x<=page.get_global_rect().end.x,"menu stays within phone width")
				previous_end=control.get_rect().end.y
			var saved=JSON.stringify(s)
			for id in Identity.TITLES:
				await click(button("TiyiMenu_"+id));await show()
				check(b.tiyi_identity.detail==id and button("PhoneNav_back")!=null,"menu opens a native page with local back: "+id)
				check(b.back_navigation(page),"keyboard/back uses actual local return")
				await show();check(b.tiyi_identity.detail.is_empty(),"back restores dashboard")
			check(JSON.stringify(s)==saved,"read-only menus do not fabricate progress or records")
			check(actions.all(func(event):return event[0]=="phone_refresh"),"browsing emits presentation refresh only")
			actions.clear()
			await click(button("TiyiMenu_settings"));await show()
			await click(button("TiyiOpenControlCenter"));check(routes.back()=="control_center","settings opens actual control center")
			b.tiyi_identity.route(s,"control_center");check(b.tiyi_identity.detail=="settings","control center retains detail navigation")
			b.tiyi_identity.route(s,"phone_home");check(b.tiyi_identity.detail.is_empty(),"leaving app resets local navigation")
			actions.clear();routes.clear()
	s=root.get_node("State").initial();s.native.page="tiyi";s.networkMode="cellular"
	b.entry_session.route(s);b.entry_session.advance(1400);await show()
	var count=button("TiyiCount47");var marker: Control=page.find_child("TiyiSevenPickupSource",true,false);var plate: TextureRect=page.find_child("TiyiSourcePlate",true,false)
	check(count.get_global_rect().grow(.1).encloses(marker.get_global_rect()),"seven pickup has a real overlapping hit target")
	check(plate.texture.atlas==Seven.SOURCE and plate.texture.region==Seven.COUNT_REGION,"original gold seven stays a source crop")
	await click(count);check(actions==[["c1_tiyi_digit",null]],"one ordinary count click emits original pickup intent")
	for polygon in Identity.Runner.LIMBS:
		for point in polygon:check(Rect2(8,8,64,64).has_point(point),"runner silhouette retains an inset on all sides")
	page.free()
	print("TIYI_VISUAL_LAYOUT: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
