extends SceneTree
const LAYOUT=preload("res://campuses/buct_shared/student/scripts/landmark_pin_layout.gd")
var failures: Array[String]=[]
var checks:=0
func _init() -> void:call_deferred("run")
func frames(count:=2) -> void:
	for i in range(count):await physics_frame
func expect(value: bool,label: String) -> void:
	checks+=1;print("PASS " if value else "FAIL ",label)
	if not value:failures.append(label)
func run() -> void:
	for campus in ["buct","buct_haidian","buct_changping"]:
		var app=load("res://campuses/"+campus+"/scenes/playable.tscn").instantiate();root.add_child(app);await frames(3)
		app.visitor.set_physics_process(false)
		var problem:=Vector2(752,815) if campus=="buct" else (Vector2(515,1210) if campus=="buct_changping" else Vector2(762,402))
		app.visitor.position=problem;app.current_path.clear();app.close_info()
		for size in [Vector2i(1280,800),Vector2i(392,844),Vector2i(667,375)]:
			root.size=size;await frames(3);app._layout_ui();app.camera.position=app._walking_camera_position();app.camera.reset_smoothing();app.camera.force_update_scroll();app._process(0)
			var body: Rect2=LAYOUT.student_screen_bounds(app.visitor)
			var positions: Array[Vector2]=[]
			for pin in app.pins:
				positions.append(pin.position)
				if not pin.visible:continue
				expect(not Rect2(pin.position,pin.size).intersects(body),campus+" visible landmark avoids real student "+str(size)+" "+pin.text)
				expect(app.map_area.grow(0.01).encloses(Rect2(pin.position,pin.size)),campus+" pin stays within usable map area "+str(size))
			for i in range(30):app._process(0)
			for i in range(app.pins.size()):expect(app.pins[i].position==positions[i],campus+" repeated updates never accumulate label drift "+str(size))
			var visual=app.visitor.character_visual
			visual.advance_motion(Vector2(4,0),1.0/60);var walking_body: Rect2=LAYOUT.student_screen_bounds(app.visitor)
			expect(walking_body==body,campus+" registered full-cycle rectangle prevents animation edge jitter "+str(size))
			visual.advance_motion(Vector2.ZERO,0)
			app.toggle_overview();app._process(0)
			for pin in app.pins:expect(pin.visible and pin.size.y>=40,campus+" overview keeps visible clickable landmark buttons "+str(size))
			app.toggle_overview()
		app.queue_free();await frames(3)
	# Narrow corners exercise clamping independently of the camera's central player framing.
	var area:=Rect2(12,80,368,140)
	for feet in [Vector2(24,96),Vector2(360,96),Vector2(24,200),Vector2(360,200)]:
		var body:=Rect2(feet-Vector2(8,18),Vector2(16,20)).grow(8)
		var result:=LAYOUT.place(feet-Vector2(20,32),Vector2(120,40),body,area)
		expect(area.encloses(Rect2(result,Vector2(120,40))) and not Rect2(result,Vector2(120,40)).intersects(body),"Narrow map corner fits pin and keeps student clear "+str(feet))
	print("BUCT_STUDENT_PIN_LAYOUT ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," errors=",failures)
	quit(0 if failures.is_empty() else 1)
