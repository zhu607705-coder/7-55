extends SceneTree
const Evidence = preload("res://scripts/ui/photo_evidence_surface.gd")
const Pages = preload("res://scripts/ui/phone_pages.gd")
const Controller = preload("res://scripts/chapters/chapter1_2.gd")
const VALUES = [0.0,19.999,20.0,20.001,21.0,25.0,50.0,56.0,72.0,75.0,80.0,100.0]
var failures := 0
var checks := 0
var source_cases: Array=[]
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error("PHOTO EVIDENCE: "+message)
func labels(node: Node) -> String:
	var result: String=node.text if node is Label else ""
	for child in node.get_children(): result += "\n"+labels(child)
	return result
func luma(c: Color) -> float:
	var linear := c.srgb_to_linear()
	return .2126*linear.r+.7152*linear.g+.0722*linear.b
func ratio(a: Color,b: Color) -> float:
	return (maxf(luma(a),luma(b))+.05)/(minf(luma(a),luma(b))+.05)
func run() -> void:
	var state: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"chapter":2,"page":"photos","scene":"library_interior","mode":"light","selected_item":""}
	state.actOne.phase="complete"
	state.ui.libraryFinalsPhase="evidence_gathering"
	state.ui.libraryFinalsPuzzle.backpackInspected=true
	state.ui.libraryFinalsPuzzle.investigationOpened=true
	state.ui.libraryFinalsPuzzle.photoCaptured=true
	state.ui.libraryFinalsPuzzle.photoDimmed=true
	var host:=Control.new()
	var theme:=Theme.new()
	theme.default_font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	host.theme=theme
	root.add_child(host)
	for mode in ["light","dark"]:
		state.native.mode=mode
		for b in VALUES:
			state.ui.brightness=b
			var expected: bool=b<=20
			var before:=JSON.stringify(state)
			var surface:=Evidence.new()
			surface.configure(b,state.ui.libraryFinalsPuzzle)
			host.add_child(surface)
			await process_frame
			source_cases.append({"brightness":b,"mode":mode,"parameters":surface.exposure.duplicate()})
			check(bool(surface.exposure.readable)==expected,"exact threshold %s %s"%[mode,b])
			check(JSON.stringify(state)==before,"render does not mutate state")
			for clue in Evidence.CLUE_LINES:
				check(labels(surface).contains(clue)==expected,"no hidden clue node: %s @%s %s"%[clue,b,mode])
			check(surface.get_node("PhotoArtwork").stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"uniform photo scaling")
			var glare: Control=surface.get_node("PhotoPaper/LocalizedPaperGlare")
			check(Evidence.LABEL_RECT.encloses(Rect2(Evidence.LABEL_RECT.position+glare.position,glare.size)),"glare bounded to paper")
			check(Evidence.LABEL_RECT.position.x>=165,"backpack never has a white veil")
			if expected:
				check(surface.get_node_or_null("PhotoScanLine")==null,"scan line never crosses decoded text")
				for i in range(Evidence.CLUE_LINES.size()):
					var line: Label=surface.get_node("PhotoPaper/PhotoClueLine%d"%i)
					check(line.get_minimum_size().x<=155,"clue fits horizontal bounds: "+line.text)
					check(line.position.y+line.size.y<=Evidence.LABEL_RECT.size.y-2,"clue fits paper vertically: "+line.text)
					check(line.get_theme_font_size("font_size")==15,"clue font does not shrink")
			for viewport in [Vector2(390,844),Vector2(430,860),Vector2(1440,900)]:
				var shell_scale:=minf(1.0,minf((viewport.y-36)/860,(viewport.x-36)/430))
				surface.scale=Vector2.ONE*shell_scale*424.0/378.0
				check(is_equal_approx(surface.scale.x,surface.scale.y),"no aspect distortion")
				check(15.0*surface.scale.x>=13.5,"clue remains legible at "+str(viewport))
				check(surface.size.x*surface.scale.x<viewport.x,"photo fits "+str(viewport))
			surface.free()
	for missing in ["backpackInspected","photoCaptured","photoDimmed"]:
		var puzzle: Dictionary=state.ui.libraryFinalsPuzzle.duplicate(true)
		puzzle[missing]=false
		for b in [0.0,20.0]: check(not Evidence.parameters(b,puzzle).readable,"missing "+missing+" cannot reveal")
	for b in [NAN,INF,-INF]: check(not Evidence.parameters(b,state.ui.libraryFinalsPuzzle).readable,"nonfinite brightness cannot reveal")
	var pages:=Pages.new()
	for mode in ["light","dark"]:
		state.native.mode=mode
		for b in [20.0,20.001,100.0]:
			state.ui.brightness=b
			var page: Control=pages.build("photos",{},state)
			host.add_child(page)
			await process_frame
			var canvas: Node=page.find_child("PhotoEvidenceSurface",true,false)
			check(canvas!=null,"gallery mounts native evidence surface")
			check(page.size.x==424,"phone page width unchanged")
			check(labels(page).contains("人格：加载失败")== (b<=20),"actual gallery follows gate")
			page.free()
	# Negative/repeated/reversal state checks through the existing controller.
	var controller:=Controller.new()
	for b in [0.0,19.999,20.0,20.001,25.0,100.0]:
		state.ui.brightness=b
		state.ui.libraryFinalsPuzzle.photoDimmed=false
		controller.dispatch(state,"lib_dim_photo",null)
		check(bool(state.ui.libraryFinalsPuzzle.photoDimmed)==(b<=20),"controller threshold unchanged at "+str(b))
		controller.dispatch(state,"lib_dim_photo",null)
		check(bool(state.ui.libraryFinalsPuzzle.photoDimmed)==(b<=20),"repeat cannot bypass threshold")
	state.ui.libraryFinalsPuzzle.photoDimmed=true
	check(not Evidence.parameters(20.001,state.ui.libraryFinalsPuzzle).readable,"raising brightness re-obscures, even after unlock")
	# Actual source pixels retain backpack contrast; former whole-frame white overlay did not.
	var texture: Texture2D=load(Evidence.ART)
	var original: Image=texture.get_image()
	if original.is_compressed(): original.decompress()
	var original_edge_ratio:=ratio(original.get_pixel(220,455),original.get_pixel(459,455))
	for b in [0.0,25.0,50.0,75.0,80.0,100.0]:
		var info: Dictionary=Evidence.parameters(b,state.ui.libraryFinalsPuzzle)
		var output: Image=Evidence.toned_image(original,info)
		var dark:=output.get_pixel(220,455)
		var light:=output.get_pixel(459,455)
		var old_alpha:=0.0 if b<=20 else maxf(.08,.94-clampf((72-b)/52,0,1)*.78)
		var old_dark:=original.get_pixel(220,455).lerp(Color.WHITE,old_alpha)
		var old_light:=original.get_pixel(459,455).lerp(Color.WHITE,old_alpha)
		print("PHOTO_PIXELS brightness=%s old_edge=%.3f new_edge=%.3f"%[b,ratio(old_light,old_dark),ratio(light,dark)])
		check(ratio(light,dark)>=1.0+(original_edge_ratio-1.0)*.8,"preserves source backpack edge contrast at "+str(b))
		if b>=75:
			check(ratio(light,dark)>ratio(old_light,old_dark)+.3,"improves perceptual contrast over full-frame wash at "+str(b))
		var global_alpha:=clampf((70-b)/70,0,1)*.3
		var veil:=Color("05060c")
		check(ratio(Evidence.LABEL_INK.lerp(veil,global_alpha),Evidence.LABEL_PAPER.lerp(veil,global_alpha))>=7,"decoded text contrast with system dimmer at "+str(b))
		var glare:=Evidence.glare_image(float(info.glare))
		var covered:=0
		for y in range(glare.get_height()):
			for x in range(glare.get_width()):
				if glare.get_pixel(x,y).a>.5: covered+=1
		check(float(covered)/(346*300)<.18,"no broad saturated area at "+str(b))
	host.free()
	var fixture_path:=OS.get_environment("PHOTO_QA_FIXTURE")
	if fixture_path.is_empty(): fixture_path="user://photo_exposure_cases.json"
	var fixture:=FileAccess.open(fixture_path,FileAccess.WRITE)
	fixture.store_string(JSON.stringify(source_cases,"\t"));fixture.close()
	print("PHOTO_EVIDENCE: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
