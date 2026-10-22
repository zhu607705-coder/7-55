extends SceneTree
## Actual Window logical rect and GUI transform, without story fixtures.
const Policy = preload("res://scripts/platform/web_display.gd")
var checks := 0
var failures := 0
var presses := 0
var viewport_changes := 0
var rows: Array = []
func _initialize() -> void: run.call_deferred()
func frames(count: int = 3) -> void:
	for _i in range(count): await process_frame
func check(ok: bool,message: String) -> void:
	checks += 1; rows.append({"ok":ok,"label":message})
	if not ok:
		failures += 1; push_error("WEB DISPLAY SCALE: "+message)
func click_native(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point; motion.global_position = point; root.push_input(motion,false)
	await frames(1)
	for down: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		# False applies the real native-pixel -> logical content transform.
		root.push_input(event,false); await frames(1)
func run() -> void:
	var state: Node = root.get_node("State")
	var state_before := JSON.stringify(state.d)
	var display: Node = root.get_node("WebDisplay")
	if not OS.has_feature("web"):
		check(not display.is_processing(),"native autoload does not poll/apply Web density")
		check(is_equal_approx(root.content_scale_factor,1.0),"native startup retains its original scale")
	for invalid: float in [0.0,-1.0,NAN,INF,-INF]:
		check(is_equal_approx(Policy.normalized_scale(invalid),1.0),"invalid/nonfinite density safely normalizes to1: "+str(invalid))
	check(is_equal_approx(Policy.normalized_scale(.8),.8),"zoom below100% remains fractional")
	check(is_equal_approx(Policy.normalized_scale(1.25),1.25),"fractional density is not rounded")
	check(not Policy.apply_to_window(null,2.0),"missing window is a no-op")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	var host := Control.new(); root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var button := Button.new(); button.position = Vector2(100,120); button.size = Vector2(200,60)
	button.text = "DPI input target"; host.add_child(button)
	button.pressed.connect(func(): presses += 1)
	root.size = Vector2i(2880,1800); root.content_scale_factor = 1.0; await frames()
	check(host.size.is_equal_approx(Vector2(2880,1800)),"negative control: factor1 exposes physical2880x1800 layout")
	await click_native(Vector2(400,300))
	check(presses==0,"negative control: old layout misses intended CSS200x150 target")
	root.size_changed.connect(func(): viewport_changes += 1)
	for record: Array in [[Vector2i(2880,1800),2.0,Vector2(1440,900)],[Vector2i(1800,1125),1.25,Vector2(1440,900)],[Vector2i(1152,720),.8,Vector2(1440,900)],[Vector2i(1440,900),1.0,Vector2(1440,900)],[Vector2i(780,1688),2.0,Vector2(390,844)]]:
		root.size = record[0]; Policy.apply_to_window(root,record[1]); await frames()
		check(root.size==record[0],"DPR"+str(record[1])+": physical backing unchanged")
		check(root.get_visible_rect().size.is_equal_approx(record[2]),"DPR"+str(record[1])+": logical viewport matches CSS")
		check(host.size.is_equal_approx(record[2]),"DPR"+str(record[1])+": full-rect anchors use logical dimensions")
		var count_before := viewport_changes
		check(not Policy.apply_to_window(root,record[1]),"DPR"+str(record[1])+": equal ratio does not write")
		await frames(1)
		check(viewport_changes==count_before,"DPR"+str(record[1])+": equal ratio causes no resize recursion")
		var before := presses
		await click_native(Vector2(200,150)*float(record[1]))
		check(presses==before+1,"DPR"+str(record[1])+": engine input transform reaches rendered target")
	root.size = Vector2i(2560,1440); await frames()
	check(root.get_visible_rect().size.is_equal_approx(Vector2(1280,720)),"same-density resize retains logical1280x720")
	Policy.apply_to_window(root,NAN); await frames()
	check(is_equal_approx(root.content_scale_factor,1.0),"invalid density applies safe factor1")
	check(JSON.stringify(state.d)==state_before,"display policy leaves story/items/save state unchanged")
	var report := {"success":failures==0,"checks":checks,"failures":failures,"rows":rows,"scope":"Actual native Window logical rect/GUI transform; invalid/fractional density and native autoload isolation. Browser DPR is a separate export gate."}
	var report_path := OS.get_environment("WEB_DISPLAY_REPORT")
	if not report_path.is_empty():
		var file := FileAccess.open(report_path,FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"\t")+"\n")
	print("WEB DISPLAY SCALE ","PASS" if failures==0 else "FAIL",": ",checks," checks")
	quit(0 if failures==0 else 1)
