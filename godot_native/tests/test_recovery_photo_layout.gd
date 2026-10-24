extends SceneTree
## Source-backed Control fixture, never an earned playthrough or photo solution.
const Pages=preload("res://scripts/ui/chapter3_phone_pages.gd")
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const Sequence=preload("res://scripts/ui/c35_photo_sequence.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, description: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(description)
func collect(node: Node, images: Array, buttons: Array) -> void:
	if node is TextureRect and node.name=="RecoveredPhoto": images.append(node)
	if node is Button: buttons.append(node)
	for child: Node in node.get_children(): collect(child,images,buttons)
func frames(count: int=6) -> void:
	for i in count: await process_frame
func physical_rect(control: Control) -> Rect2:
	var transform:=control.get_global_transform_with_canvas()
	return Rect2(transform.origin,control.size*transform.get_scale())
func nearest_filter(node: CanvasItem) -> bool:
	# INHERIT is valid: the native theme/project owns nearest filtering.
	var current: Node=node
	while current is CanvasItem:
		if current.texture_filter!=CanvasItem.TEXTURE_FILTER_PARENT_NODE:
			return current.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST
		current=current.get_parent()
	return int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"))==0
func run() -> void:
	var s: Dictionary=root.get_node("State").initial()
	s.native.page="c35_photos";s.native.chapter=3;s.native.scene="";s.runtimeMode="phone"
	s.qizhenLake.phase="complete"
	var controller: RefCounted=Chapter.new()
	controller.dispatch(s,"c35_begin"); controller.dispatch(s,"c35_journal","safe_return")
	var state: Node=root.get_node("State");state.developer_mode=true;state.d=s
	var shell: Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell.set_process(false);shell.world.set_process(false)
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		root.size=dimensions;shell.size=Vector2(dimensions);shell.mobile_world=false
		state.d.native.page="c35_photos";shell._refresh();await frames()
		var view: Control=shell.page_body.find_child("C35App_c35_photos",true,false)
		check(view!=null,"actual Main mounts recovered photos at "+str(dimensions))
		if view==null: continue
		var before:=JSON.stringify(state.d.chapterThreeInterlude)
		var images: Array=[];var buttons: Array=[];collect(view,images,buttons)
		var scroll: ScrollContainer=view.scroll
		var viewport:=physical_rect(scroll)
		check(shell.phone.size==Vector2(430,860) and view.size==Vector2(424,814),"canonical logical phone and app dimensions are retained")
		check(physical_rect(shell.phone_content).grow(.5).encloses(physical_rect(view)),"scaled app fits actual phone content")
		check(images.size()==7,"all seven original frames retained")
		check(buttons.any(func(b): return b.text=="重排"),"source reorder control visible")
		for b: Button in buttons:
			if b.text=="重排": check(b.size.x>=72,"reorder label has a readable dedicated target")
		for i: int in range(images.size()):
			var photo: TextureRect=images[i]
			# Include its caption so integer scroll offsets do not leave the image
			# exactly on a fractional clipping boundary.
			scroll.ensure_control_visible(photo.get_parent().get_parent().get_parent());await frames()
			viewport=physical_rect(scroll)
			check(absf(photo.size.x/photo.size.y-0.78)<0.002,"portrait clue aspect preserved")
			check(photo.size.y>120,"source image is no longer an eighty-pixel landscape strip")
			check(photo.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"complete original image fits uniformly without cropping evidence")
			check(photo.texture!=null and photo.texture.resource_path.ends_with("chapter35_live_"+Pages.Interlude.FRAMES[i].image+".webp"),"original source photograph retained")
			check(nearest_filter(photo),"effective inherited pixel filtering remains nearest")
			check(photo.flip_h==bool(Pages.Interlude.FRAMES[i].get("mirror",false)),"mirror decoys retained")
			check(viewport.grow(.5).encloses(physical_rect(photo)),"each card hit image can be revealed completely inside the real phone scroll: "+str(dimensions)+" frame "+str(i)+" scroll "+str(viewport)+" photo "+str(physical_rect(photo)))
			var portrait: Control=photo.get_parent().get_parent()
			var cell: Node=portrait.get_parent()
			check(physical_rect(cell.get_child(1)).position.y>=physical_rect(photo).end.y-0.1,"caption follows full portrait without overlap")
		check(JSON.stringify(state.d.chapterThreeInterlude)==before,"scrolling and layout never grant recovery evidence")
	await shell.shutdown();shell.queue_free();await frames()
	controller.dispatch(s,"c35_select_photo","lake_memory_a")
	controller.dispatch(s,"c35_select_photo","mirrored_a")
	controller.dispatch(s,"c35_select_photo","mirrored_b")
	controller.dispatch(s,"c35_photos",s.native.c35_photo_selection.duplicate())
	check(not s.chapterThreeInterlude.photoSequenceSolved,"wrong and mirror choices cannot grant proof")
	controller.dispatch(s,"c35_photo_reset")
	check(s.native.c35_photo_selection.is_empty(),"reorder clears only draft choices")
	check(not s.chapterThreeInterlude.photoSequenceSolved,"reorder cannot solve")
	# Seeded solved presentation tests are separate from manual selection acceptance.
	controller.dispatch(s,"c35_photos",["paper_left","paper_middle","paper_right"])
	var earned: Dictionary=s.chapterThreeInterlude.duplicate(true)
	controller.dispatch(s,"c35_photo_reset")
	check(s.chapterThreeInterlude==earned,"reorder preserves accepted evidence")
	var animation: TextureRect=Sequence.new(); animation.configure(false)
	root.add_child(animation); animation.set_process(false)
	var state_before: String=JSON.stringify(s)
	for i: int in range(9):
		check(animation.frame_index==i%3,"source frame sequence and wrap")
		check(animation.texture==animation.frames[i%3],"original source frame texture")
		animation.advance_frame(0.55)
	check(JSON.stringify(s)==state_before,"preview cannot mutate puzzle state")
	animation.hide(); var before: float=animation.elapsed
	animation._process(0.2)
	check(animation.elapsed==before,"hidden page stops animation clock")
	animation.configure(true); animation.advance_frame(1.2)
	check(animation.frame_index==0 and animation.elapsed==0,"reduced motion uses first original frame")
	var id: int=animation.get_instance_id(); animation.queue_free(); await process_frame
	check(not is_instance_id_valid(id),"closing page retires its sole animation owner")
	print("RECOVERY_PHOTO_LAYOUT ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
