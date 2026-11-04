extends SceneTree
## Entry skin and shared opt-in contract. Synthetic native input is not device proof.
const PaperInk=preload("res://scripts/ui/paper_ink_material.gd")
var checks:=0
var failures:=0
var presses:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, note: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("PAPER INK: "+note)
func frames() -> void:
	for unused in 5: await process_frame
func contrast(a: Color,b: Color) -> float:
	var x:=a.srgb_to_linear();var y:=b.srgb_to_linear()
	var l1:=0.2126*x.r+0.7152*x.g+0.0722*x.b
	var l2:=0.2126*y.r+0.7152*y.g+0.0722*y.b
	return (maxf(l1,l2)+0.05)/(minf(l1,l2)+0.05)
func mouse(at: Vector2, down: bool) -> void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT
	event.position=at;event.pressed=down;root.push_input(event)
func run() -> void:
	var state: Node=root.get_node("State")
	var before:=JSON.stringify(state.d)
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(390,844),Vector2i(568,320)]:
		root.size=dimensions
		var entry: Control=load("res://scenes/entry.tscn").instantiate();root.add_child(entry);await frames()
		check(bool(entry.card.get_meta("tactile_paper_ink",false)),"entry paper panel opted in")
		for button: Button in [entry.story_button,entry.flc_button]:
			var face: StyleBox=button.get_theme_stylebox("normal")
			check(face.paper_ink,"entry actions have ink-paper material")
			check(button.size.y>=44,"existing 44px minimum target preserved")
			check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(button.get_global_rect()),"entry action remains inside viewport")
			var rect:=button.get_global_rect()
			button.get_node("TactileMaterialState")._process(0.2)
			check(button.get_global_rect()==rect,"presentation does not move hit region")
			check(button.get_theme_stylebox("focus").border_color==PaperInk.FOCUS,"static red keyboard focus")
			check(button.get_signal_connection_list("pressed").size()==1,"original navigation signal has one owner")
		if is_instance_valid(entry.preview_button):
			check(entry.preview_button.get_theme_stylebox("normal").paper_ink,"all visible entry navigation shares material")
		entry.queue_free();await frames()
	check(JSON.stringify(state.d)==before,"view and layout never modify story state")
	for variant: String in ["primary","secondary"]:
		for hover: float in [0.0,1.0]:
			check(contrast(PaperInk.label_color(variant),PaperInk.face_color(variant,hover))>=4.5,"normal/hover text contrast")
		check(contrast(PaperInk.label_color(variant,true),PaperInk.face_color(variant,0,1))>=4.5,"disabled remains readable")
	var button:=Button.new();button.text="测试";button.position=Vector2(20,20);button.size=Vector2(180,48)
	button.set_meta("tactile_paper_ink",true);root.add_child(button)
	button.pressed.connect(func():presses+=1);await frames()
	var hit:=button.get_global_rect()
	mouse(Vector2(60,40),true);await frames();mouse(Vector2(60,40),false);await frames()
	check(presses==1,"paper action emits original pointer signal once")
	button.disabled=true;mouse(Vector2(60,40),true);mouse(Vector2(60,40),false);await frames()
	check(presses==1,"disabled paper action refuses pointer input")
	button.disabled=false;button.grab_focus()
	var key:=InputEventKey.new();key.keycode=KEY_ENTER;key.pressed=true;root.push_input(key)
	key=InputEventKey.new();key.keycode=KEY_ENTER;root.push_input(key);await frames()
	check(presses==2,"keyboard activation remains available")
	check(button.get_global_rect()==hit,"all input states retain measured hit rect")
	button.queue_free();await frames()
	# Endpoint-only palette checks miss ink crossing a still-dark primary face.
	var primary:=Button.new();primary.text="已保存的线索";primary.size=Vector2(220,48)
	primary.set_meta("tactile_paper_ink",true);primary.set_meta("tactile_variant","primary")
	primary.disabled=true;root.add_child(primary);await frames()
	var material:StyleBox=primary.get_theme_stylebox("disabled")
	check(material.disabled_amount==1.0,"initially disabled primary adopts its readable face immediately")
	check(contrast(primary.get_theme_color("font_disabled_color"),material.bg_color)>=4.5,"initially disabled primary remains readable")
	var primary_hit:=primary.get_global_rect()
	for disabled_now:bool in [false,true,false,true]:
		primary.disabled=disabled_now
		for step:float in [0.0,0.001,0.02,0.05,0.12]:
			primary.get_node("TactileMaterialState")._process(step)
			var actual_face:=PaperInk.face_color(material.variant,material.hover_amount,material.disabled_amount)
			var actual_ink:Color=primary.get_theme_color("font_disabled_color" if disabled_now else "font_color")
			check(contrast(actual_ink,actual_face)>=4.5,"disabled and re-enabled primary stay readable at every transition step")
			check(material.bg_color.is_equal_approx(actual_face),"material compatibility color equals the actually drawn face")
	check(primary.get_global_rect()==primary_hit,"readable disabled transitions preserve the original hit rectangle")
	primary.queue_free();await frames()
	var apparatus:=Button.new();apparatus.set_meta("tactile_exempt",true);apparatus.set_meta("tactile_paper_ink",true)
	root.add_child(apparatus);await frames()
	check(apparatus.get_node_or_null("TactileMaterialState")==null,"apparatus exemption still wins over skin request")
	apparatus.queue_free();await frames()
	print("PAPER_INK_ENTRY: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
