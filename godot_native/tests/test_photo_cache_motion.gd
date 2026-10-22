extends SceneTree
const Surface=preload("res://scripts/ui/photo_evidence_surface.gd")
const Pages=preload("res://scripts/ui/phone_pages.gd")
const VALUES=[0.0,20.0,20.001,25.0,50.0,75.0,80.0,100.0]
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,why:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("PHOTO CACHE/MOTION: "+why)
func visible_lines(surface:Control)->bool:
	for i in range(7):
		var line:Label=surface.get_node("PhotoPaper/PhotoClueLine%d"%i)
		if not is_equal_approx(line.modulate.a,1.0):return false
	return true
func active_tweens()->Array:
	return get_processed_tweens().filter(func(tween):return tween.is_valid() and tween.is_running())
func run()->void:
	var flags={"backpackInspected":true,"photoCaptured":true,"photoDimmed":true}
	var original_flags:=flags.duplicate(true)
	var cached_texture:=Surface.paper_texture()
	var cached_image:=Surface.paper_image()
	check(cached_texture.get_image().get_data()==cached_image.get_data(),"texture uses unchanged paper pixels")
	for i in range(12):
		check(Surface.paper_texture()==cached_texture,"shared texture identity across refreshes")
		check(Surface.paper_image()==cached_image,"shared image identity across refreshes")
	var state:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"chapter":2,"page":"photos","scene":"library_interior","mode":"light","selected_item":"","settings":{"reduced_motion":false}}
	state.actOne.phase="complete";state.ui.libraryFinalsPhase="evidence_gathering"
	state.ui.libraryFinalsPuzzle.backpackInspected=true;state.ui.libraryFinalsPuzzle.investigationOpened=true;state.ui.libraryFinalsPuzzle.photoCaptured=true;state.ui.libraryFinalsPuzzle.photoDimmed=true
	var pages:=Pages.new()
	var host:=Control.new();root.add_child(host)
	var prior_tweens:=active_tweens().size()
	for reduced in [false,true]:
		for b in [20.0,0.0,19.0,20.0]:
			var surface:=Surface.new();surface.configure(b,flags,reduced);host.add_child(surface)
			check(surface.get_node("PhotoPaper/PaperFibres").texture==cached_texture,"each visible surface uses shared paper texture")
			if reduced:
				check(visible_lines(surface),"reduced-motion text is immediate before any frame")
				check(active_tweens().size()==prior_tweens,"reduced-motion creates no focus tween")
			else:
				check(not visible_lines(surface),"normal motion retains reviewed focus-in")
				for tween in get_processed_tweens():tween.custom_step(1.0)
				check(visible_lines(surface),"every repeated readable refresh settles all seven lines")
			surface.free();await process_frame
			check(active_tweens().size()==prior_tweens,"completed/free surface leaves no pending tween")
		state.native.settings.reduced_motion=reduced;state.ui.brightness=20
		var page:Control=pages.build("photos",{},state);host.add_child(page)
		var actual:Control=page.find_child("PhotoEvidenceSurface",true,false)
		check(visible_lines(actual)==reduced,"actual PhonePages passes reduced-motion preference")
		page.free();await process_frame
	for i in range(8):
		var interrupted:=Surface.new();interrupted.configure(20,flags,false);host.add_child(interrupted)
		for tween in get_processed_tweens():tween.custom_step(.03)
		interrupted.free();await process_frame
		check(active_tweens().size()==prior_tweens,"interrupted focus-in releases all node-bound tweens")
	var resumed:=Surface.new();resumed.configure(20,flags,true);host.add_child(resumed)
	check(visible_lines(resumed),"refresh after interruption/reduced-mode switch is completely readable")
	resumed.free()
	for reduced in [false,true]:
		for missing in ["photoDimmed","photoCaptured","backpackInspected"]:
			var hidden_flags:=flags.duplicate(true);hidden_flags[missing]=false
			var hidden:=Surface.new();hidden.configure(0,hidden_flags,reduced);host.add_child(hidden)
			check(hidden.get_node_or_null("PhotoPaper/PhotoClueLine0")==null,"reduced motion never bypasses "+missing)
			hidden.free()
		var boundary:=Surface.new();boundary.configure(20.001,flags,reduced);host.add_child(boundary)
		check(boundary.get_node_or_null("PhotoPaper/PhotoClueLine0")==null,"threshold unchanged with reduced-motion preference")
		boundary.free()
	check(flags==original_flags,"no puzzle state mutation or leaked state")
	host.free()
	print("PHOTO_CACHE_MOTION: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
