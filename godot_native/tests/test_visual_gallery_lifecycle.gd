extends SceneTree
## DEV gallery must remain cancellable and bounded even without window focus.
class FrozenSession extends RefCounted:
	var kind="opening"
	var elapsed_ms=0.0
	func snapshot() -> Dictionary: return {"phase":"frozen","beatIndex":0}
class FrozenHost extends Node:
	var current=FrozenSession.new()
	func tick(_delta: float,_focused: bool=true) -> void: pass
	func _advance() -> void: pass
class PreviewStub extends Control:
	var c3_scene_host: Node
var failed=0
var checks=0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failed+=1;push_error("VISUAL GALLERY: "+message)
func _run() -> void:
	var state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	var main=load("res://scenes/main.tscn").instantiate();root.add_child(main)
	for i in 5:await process_frame
	state.begin_checkpoint("c2-seat-dialogue");main._refresh();main.mobile_world=true;main._layout()
	for i in 4:await process_frame
	main.c3_scene_host.set_process(false);main.world.set_process(false)
	main.c3_scene_host.tick(0,true)
	check(main.c3_scene_host.current!=null,"real source opening session issued")
	var gallery=load("res://tests/visual_gallery.gd").new();root.add_child(gallery);gallery.preview=main;gallery.restored=true
	main.c3_scene_host.tick(0,false)
	check(main.c3_scene_host.current.paused,"real source session starts focus-paused")
	var reached: bool=await gallery._advance_opening_gallery_phase("record_scan")
	check(reached and main.c3_scene_host.current!=null and main.c3_scene_host.current.snapshot().phase=="record_scan","focused DEV ticks advance paused session through real actions")
	check(state.d.ui.libraryFinalsPuzzle.nextQuestId==null,"intermediate gallery phase does not claim chapter completion")
	var before: int=main.c3_scene_host.current.beat_index
	gallery.cancelled=true
	check(not await gallery._advance_opening_gallery_phase("arrival"),"cancelled gallery stops without busy wait")
	check(main.c3_scene_host.current.beat_index==before,"cancel leaves current source phase unchanged")
	gallery.cancelled=false
	var stub=PreviewStub.new();var frozen=FrozenHost.new();stub.c3_scene_host=frozen;stub.add_child(frozen);root.add_child(stub);gallery.preview=stub
	var start: int=Time.get_ticks_msec()
	check(not await gallery._advance_opening_gallery_phase("unreachable",25),"no-progress opening exits at deadline")
	check(Time.get_ticks_msec()-start<1000 and gallery.report[-1].has("snapshot"),"timeout is prompt and records actual snapshot")
	start=Time.get_ticks_msec()
	check(not await gallery._advance_canteen_gallery_time(1000,25),"no-progress canteen tick exits at deadline")
	check(Time.get_ticks_msec()-start<1000,"canteen timeout yields control promptly")
	gallery.queue_free();stub.queue_free()
	await main.shutdown();main.queue_free();await process_frame
	print("VISUAL_GALLERY_LIFECYCLE: ",checks," checks; ",failed," failures")
	quit(1 if failed else 0)
