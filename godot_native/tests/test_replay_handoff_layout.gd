extends SceneTree
const Activity=preload("res://scripts/games/chapter4_activity.gd")
var checks:=0
var failures:=0
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
	checks+=1
	if not ok: failures+=1;push_error(message)
func frames():
	await process_frame;await process_frame
func run():
	for view in [Vector2(390,844),Vector2(430,860),Vector2(844,390),Vector2(1180,812)]:
		var a=Activity.new();a.theme=load("res://scripts/ui/native_ui_theme.gd").make_theme(load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"),18,18);root.add_child(a);a.set_process(false)
		# Match Main's external audio owner; this fixture measures layout only.
		a.presentation_requested.connect(func(_cue,_payload):pass)
		a.setup({"kind":"prologue","session":"layout","video":"res://missing.ogv","settings":{"reduced_motion":true}})
		a.configure_activity_layout(view,true);await frames()
		check(a.uses_activity_layout() and a.scale==Vector2.ONE,"unscaled full-scene handoff")
		check(is_equal_approx(a.prologue_field.size.x/a.prologue_field.size.y,16.0/9.0),"original film aspect")
		var area=Rect2(Vector2.ZERO,view)
		check(area.encloses(a.prologue_field),"film inside viewport")
		check(a.body.get_theme_font_size("font_size")>=18,"caption readable physical size")
		for b in a.controls.get_children():
			check(b.get_global_rect().size.y>=44 and area.encloses(b.get_global_rect()),"playback controls inside viewport and44px")
		a._skip_prologue();await frames()
		check(a.stage=="card" and not a.done,"task waits for explicit acknowledgment")
		check(area.encloses(a.prologue_card.get_rect()),"task card in viewport")
		check(a.body.get_rect().end.y<=a.controls.position.y,"task text area does not overlap controls: %s body%s controls%s lines%d"%[view,a.body.get_rect(),a.controls.get_rect(),a.body.get_line_count()])
		check(a.body.get_line_count()<=a.body.get_visible_line_count(),"all original task lines fit")
		for b in a.controls.get_children():
			check(b.get_global_rect().size.y>=44 and area.encloses(b.get_global_rect()),"task control visible44px")
		var before=a.elapsed;a.configure_activity_layout(Vector2(430,860),true);await frames()
		check(a.elapsed==before and a.stage=="card","rotation does not advance or remount movie")
		a._restart_prologue();await frames()
		check(a.elapsed==0 and a.stage=="playback","replay restores movie composition and clock")
		a.queue_free();await frames()
	print("REPLAY_HANDOFF_LAYOUT ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
