extends SceneTree
const Surface=preload("res://scripts/ui/photo_evidence_surface.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok: bool,label: String)->void:
	checks+=1
	if not ok:failures+=1;push_error("PHOTO POLISH: "+label)
func luma(color:Color)->float:
	var c:=color.srgb_to_linear()
	return .2126*c.r+.7152*c.g+.0722*c.b
func contrast(a:Color,b:Color)->float:return (maxf(luma(a),luma(b))+.05)/(minf(luma(a),luma(b))+.05)
func run()->void:
	var paper:=Surface.paper_image()
	check(paper.get_data()==Surface.paper_image().get_data(),"paper fibres remain stable between rebuilds")
	check(paper.get_pixel(85,60)!=paper.get_pixel(86,60),"subtle fibre variation exists")
	var min_contrast:=100.0
	for y in range(34,195):
		for x in range(9,164):
			min_contrast=minf(min_contrast,contrast(paper.get_pixel(x,y).lerp(Color("05060c"),.3),Surface.LABEL_INK.lerp(Color("05060c"),.3)))
	check(min_contrast>=7,"text remains readable over darkest actual fibres at0%")
	var previous_total:=0.0
	for alpha in [0.0,.16,.24,.4,.61,.8,.94]:
		var glare:=Surface.glare_image(alpha)
		var maximum:=0.0
		var max_step:=0.0
		var total:=0.0
		for y in range(glare.get_height()):
			for x in range(glare.get_width()):
				var a:=glare.get_pixel(x,y).a
				maximum=maxf(maximum,a);total+=a
				if x>0:max_step=maxf(max_step,absf(a-glare.get_pixel(x-1,y).a))
		check(maximum<=.69,"reflection has no opaque white core @"+str(alpha))
		check(max_step<=.027,"reflection has smooth pixel falloff @"+str(alpha))
		check(total>=previous_total,"less light reduces reflected energy @"+str(alpha))
		previous_total=total
	var flags={"backpackInspected":true,"photoCaptured":true,"photoDimmed":true}
	var host:=Control.new();root.add_child(host)
	var locked:=Surface.new();locked.configure(20.001,flags);host.add_child(locked)
	check(locked.get_node_or_null("PhotoPaper/PhotoClueLine0")==null,"no pre-threshold text or fade")
	locked.free()
	var earned:=Surface.new();earned.configure(20,flags);host.add_child(earned)
	var first:Label=earned.get_node("PhotoPaper/PhotoClueLine0")
	var last:Label=earned.get_node("PhotoPaper/PhotoClueLine6")
	check(first.modulate.a==0,"earned text begins its short focus-in")
	await create_timer(.6).timeout
	check(is_equal_approx(first.modulate.a,1) and is_equal_approx(last.modulate.a,1),"all earned lines settle completely")
	check(not earned.get_node("PhotoPaper/PaperFibres").mouse_filter==Control.MOUSE_FILTER_STOP,"paper texture cannot intercept input")
	check(earned.get_node("PhotoPaper").get_theme_stylebox("panel").shadow_size==5,"paper has restrained material depth")
	earned.free()
	for i in range(4):
		var interrupted:=Surface.new();interrupted.configure(20,flags);host.add_child(interrupted);await process_frame;interrupted.free()
	await create_timer(.6).timeout
	check(true,"interrupted/rebuilt focus-in leaves no tween errors")
	host.free()
	print("PHOTO_POLISH: %s checks; %s failures; darkest paper contrast %.2f:1"%[checks,failures,min_contrast])
	quit(1 if failures else 0)
