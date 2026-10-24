extends SceneTree
const View=preload("res://scripts/games/theater_shadow_rehearsal.gd")
const Proof=preload("res://tests/helpers/theater_rehearsal_proof.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("REHEARSAL NOTEBOOK: "+label)
func frames()->void:
	for i:int in range(4):await process_frame
func key(code:Key)->void:
	for pressed:bool in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;root.push_input(event,true);await frames()
func durable(state:Node)->Dictionary:
	return {"primary":FileAccess.get_file_as_string(state.SAVE_PATH) if FileAccess.file_exists(state.SAVE_PATH) else "","backup":FileAccess.get_file_as_string(state.BACKUP_PATH) if FileAccess.file_exists(state.BACKUP_PATH) else ""}
func click(button:Button,touch:bool=false)->void:
	var point:Vector2=button.get_global_rect().get_center()
	if touch:
		var down:=InputEventScreenTouch.new();down.index=1;down.position=point;down.pressed=true;root.push_input(down,true)
		var up:=InputEventScreenTouch.new();up.index=1;up.position=point;up.pressed=false;root.push_input(up,true)
	else:
		var down:=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.position=point;down.pressed=true;root.push_input(down,true)
		var up:=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.position=point;up.pressed=false;root.push_input(up,true)
	await frames()
func run()->void:
	var shared:Node=root.get_node("State");var before_shared:Dictionary=shared.d.duplicate(true);var before_saved:Dictionary=durable(shared)
	var view=View.new();view.setup({"session":{"nonce":"notebook-only"},"settings":{"reducedMotion":true}});root.size=Vector2i(1280,720);root.add_child(view);view.configure_activity_layout(Vector2(root.size),false);await frames()
	view._close_help();if view.menu_open:view._close_menu()
	view._help();await frames()
	check(view.notebook.visible and view.help_previous.disabled and not view.help_next.disabled,"physical programme opens the first illustrated leaf")
	check(view.trial_records.is_empty(),"reading never invents a rehearsal attempt")
	var original:Dictionary=view.model.snapshot()
	await click(view.help_next);await click(view.help_next)
	check(view.notebook_page==2 and view.help_next.disabled and view.help_body.text.contains("尚未留影"),"last leaf is an honest empty record until the player tries")
	check(view.state.objects==original.objects and view.state.lampX==original.lampX and view.state.lampDepth==original.lampDepth and view.state.attempts==0 and view.state.completedRounds==0,"turning pages grants no pose, attempt or completion")
	check(view.state.hintTier==3 and view.help_panel.turn_amount==0,"optional reading keeps the existing hint trace and respects reduced motion")
	var actions:int=view.model.actions.size()
	await click(view.help_previous);await click(view.help_next)
	check(view.model.actions.size()==actions,"rereading an opened leaf does not add hint actions")
	await key(KEY_PAGEUP);check(view.notebook_page==1,"Page Up turns the paper without moving a stage object")
	await key(KEY_PAGEDOWN);check(view.notebook_page==2 and view.model.actions.size()==actions,"Page Down rereads the leaf without duplicate hint actions")
	await click(view.help_close);view._help();await frames()
	check(view.notebook_page==2,"reopening remembers the current leaf")
	view._close_help();view._try_stage();var record:Dictionary=view.trial_records[0].duplicate(true)
	check(record.failure=="shadow_position" and record.attempts==1,"an accepted failed trial supplies the actual recorded projection")
	view._move_prop("left_fan",Vector2(-1,5));view._help();await frames()
	check(view.notebook.trial==record and view.notebook.trial.objects!=view.state.objects,"later manipulation cannot silently rewrite the old ink trace")
	check(view.help_body.text.contains("上回试演") and not view.help_body.text.contains("尚未留影"),"recorded ink is labelled as a previous attempt")
	view.notebook.trial.objects[0].x=100
	check(view.trial_records[0]==record,"illustration owns a detached read-only copy of the attempt")
	for extent:Vector2i in [Vector2i(1280,720),Vector2i(1440,900),Vector2i(844,390),Vector2i(390,844)]:
		root.size=extent;view.configure_activity_layout(Vector2(extent),extent.x<extent.y);view._help();await frames()
		var bounds:=Rect2(Vector2.ZERO,Vector2(extent))
		check(bounds.encloses(view.help_panel.get_global_rect()),"entire folio stays in the viewport "+str(extent))
		for button:Button in [view.help_close,view.help_previous,view.help_next]:
			check(view.help_panel.get_global_rect().encloses(button.get_global_rect()) and button.size.y>=44,"paper navigation is reachable with a 44-pixel touch target "+str(extent)+" "+button.name)
		check(view.help_panel.get_global_rect().encloses(view.help_body.get_global_rect()) and view.help_body.size.y>=100,"longer annotations scroll within the paper "+str(extent))
		check(view.notebook.size.y>=170 and view.notebook.visible,"ink diagram retains readable space "+str(extent))
		await click(view.help_previous,true);check(view.notebook_page==1,"real finger turns to the previous leaf "+str(extent))
		await click(view.help_next,true);check(view.notebook_page==2,"real finger returns to the comparison leaf "+str(extent))
	view._close_help();if view.menu_open:view._close_menu()
	root.size=Vector2i(1280,720);view.configure_activity_layout(Vector2(root.size),false);await frames()
	check(Proof.solve_round(view.model),"optional reading leaves the original first-round solution available");view._refresh();view._continue_stage();view._help();await frames()
	check(view.notebook_page==0 and view.help_body.text.contains("卷二") and view.notebook.trial.is_empty(),"new round has its own pages and no borrowed trial trace")
	var before:Dictionary=view.model.snapshot();view._focus_out();await click(view.help_close)
	check(view.menu_open and view.paused and view.model.snapshot()==before,"closing a book after focus loss exposes resume without mutating the stage")
	view._close_menu();check(Proof.solve_round(view.model),"second-round solution remains available");view._refresh();view._continue_stage();view._try_stage();view._help()
	view._next_hint();view._next_hint();await frames()
	check(view.notebook.round_index==2 and view.notebook.trial.failure=="light_axis" and view.help_body.text.contains("木钉"),"last volume ties the real shared-light failure to the fixed-pin diagram")
	view.dispose_presentation();check(shared.d==before_shared and durable(shared)==before_saved,"reading and trial illustrations leave shared progression and primary/backup saves unchanged")
	view.queue_free();await frames()
	print("THEATER_REHEARSAL_NOTEBOOK: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
