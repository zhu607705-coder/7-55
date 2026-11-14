extends "res://tests/capture_checkin_receipt_buttons.gd"
## Actual production controls + registry, all material states and native input.
const Flat=preload("res://scripts/ui/phone_flat_button_material.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
var checks:=0
var failures:=0
var activations:=0
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("RECEIPT BUTTONS: "+message)
func click(button:Button)->void:
	var center:=button.get_global_rect().get_center()
	pointer(center,true);pointer(center,false);await frames()
func key(code:Key)->void:
	for down:bool in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;root.push_input(event)
	await frames()
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	create_timer(90).timeout.connect(func():push_error("Receipt button watchdog");quit(2))
	var state:Node=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	state.d.native.settings.music=false;state.d.native.settings.effects=false;state.d.native.settings.reduced_motion=true
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(8)
	shell.set_process(false);shell.world.set_process(false);shell.battery_prank.set_process(false)
	if is_instance_valid(shell.audio_director):shell.audio_director.reset();shell.audio_director.set_process(false)
	await shell._open_game_now({"script":"res://scripts/games/prologue_interception.gd","type":"interception","viewport":[430,820]})
	game=shell.active_game;game.set_process(false)
	game.success_continue.pressed.connect(func():activations+=1)
	var before_story:Dictionary=state.d.duplicate(true)
	for extent:Vector2i in [Vector2i(390,844),Vector2i(1440,900)]:
		root.size=extent;shell.size=Vector2(extent);await frames();shell._layout();game._layout_controls()
		await reset_receipt()
		for button:Button in [game.success_continue,game.resume_button,game.lock_help_button]:
			check(button.get_meta("phone_ui_scope",false),"phone ownership declared on actual button "+str(button.name))
			check(button.get_theme_font("font")==Typography.body_font(),"phone body font preserved "+str(button.name))
			check(button.get_theme_font_size("font_size")==16,"authored font size preserved "+str(button.name))
			for mode:String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
				var style:StyleBox=button.get_theme_stylebox(mode)
				check(style is Flat,"flat material "+str(button.name)+":"+mode)
				if not style is StyleBoxFlat:continue
				check(style.shadow_size==0 and style.shadow_offset==Vector2.ZERO and style.shadow_color.a==0,"no elevation "+mode)
				check(style.corner_radius_top_left==4 and style.corner_radius_bottom_right==4 and style.corner_detail==2 and not style.anti_aliasing,"shared micro-corner "+mode)
				check(style.border_width_left==2 and style.border_width_right==2,"phone ink edge "+mode)
			check(button.get_theme_stylebox("normal").bg_color==Ui.PAPER and button.get_theme_color("font_color")==Ui.INK,"phone palette")
			check(button.get_theme_stylebox("hover").bg_color!=button.get_theme_stylebox("normal").bg_color,"hover distinguishable")
			check(button.get_theme_stylebox("pressed").bg_color!=button.get_theme_stylebox("hover").bg_color,"pressed distinguishable")
			check(Ui._contrast(button.get_theme_color("font_disabled_color"),button.get_theme_stylebox("disabled").bg_color)>=4.5,"disabled label readable")
		check(game.success_continue.size.is_equal_approx(Vector2(180,48)) and game.success_continue.position.is_equal_approx(game.field.position+Vector2(125,704)*game.display_scale),"receipt hit geometry unchanged")
		check(game.success_view.headline.text=="签到成功" and game.success_view.receipt.size==Vector2(304,420),"receipt content and art dimensions preserved")
		check(game.success_view.print_complete and game.success_view.receipt.rotation==0,"receipt pose unchanged")
		var rect:Rect2=game.success_continue.get_global_rect()
		var activation_before:=activations
		pointer(rect.get_center(),true);await frames()
		check(game.success_continue.is_pressed() and game.phase=="success","pointer down stays on receipt")
		check(game.success_continue.get_global_rect()==rect,"pressed geometry does not move")
		motion(Vector2(1,1));pointer(Vector2(1,1),false);await frames()
		check(game.phase=="success" and activations==activation_before,"release outside cancels receipt button")
		game.success_continue.disabled=true;await click(game.success_continue)
		check(game.phase=="success" and activations==activation_before,"disabled button cannot advance")
		game.success_continue.disabled=false;await click(game.success_continue)
		check(game.phase=="error" and activations==activation_before+1,"ordinary click advances once to original error beat")
		await click(game.success_continue)
		check(game.phase=="error","repeat click does not skip error beat")
		await reset_receipt();game.success_continue.grab_focus();await key(KEY_ENTER)
		check(game.phase=="error","native Enter activates receipt")
		await reset_receipt();game.grab_focus();await key(KEY_SPACE)
		check(game.phase=="error","original scene Space shortcut preserved")
		await reset_receipt();game._pause();game._layout_controls();await frames()
		check(not game.pause_overlay.is_open() and game.success_continue.visible,"receipt has no pause UI and keeps its real action")
		game._layout_controls()
		check(not game.paused and game.phase=="success","receipt cannot enter a player pause latch")
		game._switch("lock");game._layout_controls();await click(game.lock_help_button)
		check(game.lock_help_open and game.lock_help_button.text=="收起键盘帮助","keyboard help opens through same flat button")
		await click(game.lock_help_button)
		check(not game.lock_help_open and game.lock_help_button.text=="键盘帮助","keyboard help closes without phase advance")
		game.paused = false; game.done = false; game.reduced_motion = false
		game._switch("success")
		game.elapsed = game.success_view.interruption_time() - .02
		game._process(0)
		check(not game.success_continue.visible and game.phase == "success", "normal receipt has no dismiss control before interruption")
		game._process(.04)
		check(game.phase == "signal_loss" and not game.success_continue.visible, "normal receipt automatically enters signal loss")
		game.elapsed = game.SuccessPresentation.GLITCH_DURATION
		game._process(0)
		check(game.phase == "error", "normal receipt preserves the automatic error handoff")
		game.reduced_motion=true
	check(state.d.flags==before_story.flags and state.d.digits==before_story.digits and state.d.native.chapter==before_story.native.chapter,"presentation controls grant no story progress")
	await shell.shutdown();shell.queue_free();await frames()
	print("CHECKIN_RECEIPT_BUTTONS: ",checks," checks; ",failures," failures");quit(1 if failures else 0)
