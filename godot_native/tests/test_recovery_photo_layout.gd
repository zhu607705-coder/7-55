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
func run() -> void:
	var s: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"page":"c35_photos","settings":{"reduced_motion":false}}
	s.qizhenLake.phase="complete"
	var controller: RefCounted=Chapter.new()
	controller.dispatch(s,"c35_begin"); controller.dispatch(s,"c35_journal","safe_return")
	var pages: RefCounted=Pages.new()
	var surface: Control=Control.new(); root.add_child(surface)
	for width: int in [338,380,424]:
		surface.size=Vector2(width,800)
		var view: Control=pages.build("c35_photos",{},s)
		view.size.x=width; surface.add_child(view)
		for i: int in range(6): await process_frame
		var images: Array=[]; var buttons: Array=[]; collect(view,images,buttons)
		check(images.size()==7,"all seven original frames retained")
		check(view.size.x<=width+0.1,"photo content fits the phone scroll width")
		check(buttons.any(func(b): return b.text=="重排"),"source reorder control visible")
		for b: Button in buttons:
			if b.text=="重排": check(b.size.x>=72,"reorder label has a readable dedicated target")
		for i: int in range(images.size()):
			var photo: TextureRect=images[i]
			check(absf(photo.size.x/photo.size.y-0.78)<0.002,"portrait clue aspect preserved")
			check(photo.size.y>120,"source image is no longer an eighty-pixel landscape strip")
			check(photo.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_COVERED,"uniform source cover crop")
			check(photo.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"original pixel filtering")
			check(photo.flip_h==bool(Pages.Interlude.FRAMES[i].get("mirror",false)),"mirror decoys retained")
			check(photo.get_global_rect().end.x<=width+0.1,"all card hit images remain inside phone")
			var portrait: Control=photo.get_parent().get_parent()
			var cell: Node=portrait.get_parent()
			check(cell.get_child(1).get_global_rect().position.y>=photo.get_global_rect().end.y-0.1,"caption follows full portrait without overlap")
		view.queue_free(); await process_frame
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
	surface.queue_free(); await process_frame
	print("RECOVERY_PHOTO_LAYOUT ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
