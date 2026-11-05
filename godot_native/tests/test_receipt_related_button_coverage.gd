extends SceneTree
## Full-game receipt and ending routes. No private playtest completion page.
const Flat=preload("res://scripts/ui/phone_flat_button_material.gd")
var checks:=0
var failures:=0
var state:Node
var shell:Control
func _initialize()->void:run.call_deferred()
func frames(count:int=5)->void:
	for unused in count:await process_frame
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("RECEIPT COVERAGE: "+message)
func button_states(button:Button)->void:
	check(is_instance_valid(button),"actual production navigation button exists")
	if not is_instance_valid(button):return
	for mode:String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		var style:StyleBox=button.get_theme_stylebox(mode)
		check(style is Flat and style.shadow_size==0 and style.corner_radius_top_left<=4,str(button.name)+":"+mode+" stays existing flat phone material")
func click(button:Button)->void:
	var transform:=button.get_global_transform_with_canvas()
	var point:=Rect2(transform.origin,button.size*transform.get_scale()).get_center()
	var motion:=InputEventMouseMotion.new();motion.position=point;root.push_input(motion)
	for down:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
		root.push_input(event);await frames(1)
	await frames()
func prepare(extent:Vector2i,page:String,eligible:bool)->void:
	root.size=extent;state.d=state.initial();state.d.native.page=page;state.d.currentScene=page
	state.d.flags.checkinDone=eligible;state.d.actOne.phase="prologue"
	state.d.native.settings.music=false;state.d.native.settings.effects=false;state.d.native.settings.reduced_motion=true
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(8)
	shell.set_process(false);shell.world.set_process(false);shell.battery_prank.set_process(false)
	if is_instance_valid(shell.audio_director):shell.audio_director.reset();shell.audio_director.set_process(false)
func release_shell()->void:
	await shell.shutdown();shell.queue_free();await frames()
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	create_timer(90).timeout.connect(func():push_error("Receipt coverage watchdog");quit(2))
	state=root.get_node("State");state.developer_mode=true
	for extent:Vector2i in [Vector2i(390,844),Vector2i(1440,900)]:
		for eligible:bool in [false,true]:
			await prepare(extent,"ending",eligible)
			var next:Button=shell.find_child("EndingResumeContinue",true,false)
			var review:Button=shell.find_child("EndingResumeReview",true,false)
			button_states(next);button_states(review)
			check(next.disabled==not eligible,"controller eligibility is preserved")
			var before:Dictionary=state.d.duplicate(true)
			await click(review)
			check(shell.find_child("EndingResumeInstructions",true,false).visible,"real review action opens existing controls")
			await click(review)
			check(not shell.find_child("EndingResumeInstructions",true,false).visible and state.d==before,"review closes without granting facts")
			await click(next)
			if eligible:
				check(is_instance_valid(shell.active_game),"real full-game Continue starts controller-issued activity")
				if is_instance_valid(shell.active_game):
					check(shell.active_game.config.get("resume",false) and shell.active_game.phase=="blackout","accepted check-in resumes without replaying receipt")
					check(shell.active_game.blocks==0 and shell.active_game.hold_ms==0,"resume grants no interception proof")
			else:check(not is_instance_valid(shell.active_game),"disabled unearned route cannot start activity")
			check(state.d.flags==before.flags and state.d.actOne==before.actOne and state.d.native.chapter==1,"navigation alone cannot finish chapter")
			await release_shell()
		# Enter the success receipt through the real check-in controller, rather
		# than substituting a private first-chapter completion/export screen.
		await prepare(extent,"checkin",false)
		state.d.networkMode="campus_wifi"
		shell._on_phone_action("c1_checkin","0798");await frames(8)
		check(state.d.flags.checkinDone and state.d.native.page=="ending","accepted code reaches actual full-game ending route")
		check(is_instance_valid(shell.active_game),"accepted check-in owns an actual receipt activity")
		if is_instance_valid(shell.active_game):
			var game:Control=shell.active_game;game.set_process(false)
			check(game.phase=="success" and not game.config.get("resume",false),"first accepted check-in shows the receipt")
			game.elapsed=2.6;game._process(0);game._layout_controls();await frames()
			button_states(game.success_continue)
			var accepted:Dictionary=state.d.duplicate(true)
			await click(game.success_continue)
			game._process(0)
			check(game.phase=="error" and not game.success_continue.visible,"actual receipt dismissal reaches coordinate-error beat")
			check(state.d==accepted and game.blocks==0 and game.hold_ms==0,"receipt dismissal cannot grant puzzle or chapter proof")
			check(game.config.get("on_success","")=="c1_intervention_result","later completion retains the full-game controller callback")
		await release_shell()
	print("RECEIPT_RELATED_BUTTON_COVERAGE: ",checks," checks; ",failures," failures");quit(1 if failures else 0)
