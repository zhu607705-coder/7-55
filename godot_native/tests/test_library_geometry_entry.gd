extends SceneTree
## Actual table click -> native reading -> input -> return, without player saves.
const Notebook=preload("res://scripts/objects/library_geometry_notebook.gd")
var state:Node
var shell:Control
var checks:=0
var failures:=0
var output:=OS.get_environment("LIBRARY_GEOMETRY_CAPTURE")
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("LIBRARY_GEOMETRY: "+label)
func frames(count:int=3)->void:
	for i:int in count:await process_frame
func capture(label:String)->void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	if is_instance_valid(shell.active_game):
		for card:Control in shell.active_game.cards:card.sketch.queue_redraw()
	else:shell.world.queue_redraw()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func click(viewport:Viewport,point:Vector2)->void:
	for pressed:bool in [true,false]:
		var event=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		viewport.push_input(event,true);await frames()
func tap(point:Vector2)->void:
	for pressed:bool in [true,false]:
		var event=InputEventScreenTouch.new();event.position=point;event.index=4;event.pressed=pressed
		root.push_input(event,true);await frames()
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated save")
	if failures:quit(1);return
	state=root.get_node("State")
	for dim:Vector2i in [Vector2i(1280,720),Vector2i(390,844)]:
		root.size=dim
		if DisplayServer.get_name()!="headless":DisplayServer.window_set_size(dim)
		state.story_reset.emit();state.d=state.initial();state.developer_mode=true
		state.d.native.chapter=2;state.d.native.scene="library_interior";state.d.runtimeMode="rpg";state.d.rpgScene="library_interior"
		state.d.rpgCheckpoint="library_entrance";state.d.actOne.phase="complete";state.d.ui.libraryFinalsPhase="evidence_gathering"
		state.d.native.positions={"library_interior:":{"x":Notebook.APPROACH.x,"y":Notebook.APPROACH.y}}
		shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(8)
		shell._show_world_mobile();await frames(5)
		var world:Control=shell.world
		world.player=Notebook.APPROACH;world._sync_player();world._update_camera();world.queue_redraw();await frames()
		check(world.can_stand(world.player),"notebook approach stays on the original clear floor")
		var route_bounds=Rect2(0,0,1500,900)
		var obstacles=world._floor_obstacles()
		var route=world._floor_planner.plan(Vector2(1062,520),Notebook.APPROACH,obstacles,route_bounds,world.can_stand,func(a:Vector2,b:Vector2):return world._floor_segment_clear(a,b,obstacles,true))
		check(not route.is_empty(),"original reading-area gate connects to the notebook without crossing a table")
		check(world._pick_target(Notebook.BOUNDS.get_center()).get("id")==Notebook.ID,"visible independent notebook owns the hit area")
		var before=state.d.duplicate(true)
		await capture(str(dim.x)+"_notebook")
		var at=(Notebook.BOUNDS.get_center()-world.camera)*world.zoom+world.size/2
		await click(world.get_viewport(),at);await frames(8)
		check(is_instance_valid(shell.active_game),"ordinary table click opens the native geometry reading")
		if not is_instance_valid(shell.active_game):shell.queue_free();await frames();continue
		var view:Control=shell.active_game
		view.set_process(false)
		check(view.size==Vector2(dim) and view.grid.columns==(1 if dim.x<760 else 3),"actual host supplies responsive row or scrollable single column")
		check(view.grid.position.x>=0 and view.grid.position.x+view.grid.size.x<=view.size.x,"cards stay inside the reading surface horizontally")
		var first:Control=view.cards[0].sketch
		first.intro_play=true;first.intro_age=0;first.activate()
		check(not first.active,"intro cannot be interrupted by activation")
		for card:Control in view.cards:card.sketch.quiet()
		await tap(view.cards[0].get_global_rect().get_center());first.tick(.5)
		check(first.active and first.amount>0,"real touch tap animates native geometry without hover")
		var card_rect:Rect2=view.cards[0].get_rect()
		first.release();first.tick(.12)
		check(first.amount>0 and first.amount<1 and view.cards[0].get_rect()==card_rect,"reversal follows its current pose while card bounds stay fixed")
		await capture(str(dim.x)+"_geometry")
		view.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(view.suspended and first.amount==0 and not first.active,"background settles motion and cancels touch ownership")
		view.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
		view.setup({"reduced_motion":true});first.activate(true);first.tick(.3)
		check(first.amount==0 and not first.active,"reduced motion leaves complete static geometry")
		view.back.grab_focus()
		var tab=InputEventKey.new();tab.keycode=KEY_TAB;tab.physical_keycode=KEY_TAB;tab.pressed=true;root.push_input(tab,true);await frames()
		check(root.gui_get_focus_owner()==view.cards[0],"Tab reaches the first diagram from return")
		view.cards[2].grab_focus();await frames(6)
		check(view.scroll.get_global_rect().encloses(view.cards[2].get_global_rect()),"focused last diagram scrolls completely into view")
		await capture(str(dim.x)+"_focus")
		check(state.d.items==before.items and state.d.ui.libraryFinalsPuzzle==before.ui.libraryFinalsPuzzle and state.d.ui.libraryFinalsPhase==before.ui.libraryFinalsPhase,"reading and animation cannot grant inventory or story proof")
		await click(root,view.back.get_global_rect().get_center());await frames(6)
		check(not is_instance_valid(shell.active_game) and shell.world_frame.visible and world.player.distance_to(Notebook.APPROACH)<1,"close returns to the same real table")
		await click(world.get_viewport(),at);await frames(8)
		check(is_instance_valid(shell.active_game) and not shell.active_game.intro_play,"reopening does not replay the session entrance")
		if is_instance_valid(shell.active_game):
			var key=InputEventKey.new();key.keycode=KEY_ESCAPE;key.physical_keycode=KEY_ESCAPE;key.pressed=true;root.push_input(key,true);await frames()
		check(not is_instance_valid(shell.active_game),"Escape returns through the same host cancellation path")
		state.d.native.scene="campus_bootstrap"
		check(not state.act("lib_geometry_study").has("game"),"remote/out-of-room intent cannot open the reading")
		shell.queue_free();await frames(5)
	print("LIBRARY_GEOMETRY ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
