extends SceneTree
## Emulated root input + real Main/audio consumers. Presentation fixtures do not
## grant story facts, and every stage uses the native test save sandbox.
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
var checks:=0
var failures:=0
var shell:Control
var state:Node
class SourceLine extends RefCounted:
	var status:="playing"
	func cancel()->void:status="cancelled"
	func snapshot()->Dictionary:return {"rawText":"一段正在阅读的场景对白。","text":"一段正在阅读的场景对白。","speaker":"系统","requiresConfirmation":false,"sequenceId":"notice_pause_fixture"}
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("NOTICE QUEUE: "+label)
func frames(count:int=3)->void:
	for i in count:await process_frame
func click(control:Control)->void:
	var at:=control.get_global_transform_with_canvas()*(control.size/2)
	for down in [true,false]:
		var e:=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e,true);await frames(1)
func reset_phone()->void:
	state.d=state.initial();state.d.native.page="phone_home";state.story_reset.emit();shell._refresh();shell.mobile_world=false;shell._layout();await frames()
	shell.set_process(false);shell.audio_director.set_process(false);shell.audio_director.reset()
	for host in [shell.c3_narrative_host,shell.c3_scene_host,shell.library_story_host]:host.set_process(false)
	shell.world.set_process(false)
func run()->void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial();state.d.native.page="phone_home"
	root.size=Vector2i(430,860);shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(5)
	await reset_phone()
	shell._feedback("第一条通知");shell._feedback("第二条通知");shell._feedback("第二条通知")
	check(shell.toast.text=="第一条通知","burst preserves the currently read message")
	shell._process(2.5)
	check(shell.toast.text=="第二条通知" and is_equal_approx(shell.toast_time,2.4),"next unique notice starts with its full reading lifetime")
	shell._process(2.5)
	check(shell.toast.text.is_empty(),"pending repeated messages merge rather than replay")
	await reset_phone()
	shell._feedback("活动前的通知");shell._process(.7)
	var remaining:float=shell.toast_time
	shell._open_game({"script":"res://scripts/games/c3_weather.gd"});await frames()
	var game:Control=shell.active_game;game.set_process(false)
	shell._feedback("活动期间到达的通知")
	check(not shell.toast.visible,"an activity-time notice is hidden immediately before any lifetime elapses")
	shell._process(8)
	check(not shell.toast.visible,"full-screen activity never receives the generic z110 notice")
	await click(game.exit_button);await frames();shell._process(0)
	check(shell.active_game==null and shell.toast.text=="活动前的通知" and is_equal_approx(shell.toast_time,remaining),"actual Return resumes the old message without consuming its hidden reading time")
	shell._process(remaining+.01)
	check(shell.toast.text=="活动期间到达的通知","activity-time result follows rather than replacing the interrupted notice")
	await reset_phone()
	shell._feedback("对白前的通知");shell._process(.5);remaining=shell.toast_time
	var line:=SourceLine.new();var library:Control=shell.library_story_host
	library.current=line;library.view.session=line;library.view.tick();shell._layout();shell._process(8)
	check(not shell.toast.visible,"library dialogue suspends the generic notice")
	check(library.view.panel.get_theme_stylebox("panel").bg_color==Ui.PAPER,"library caption is opaque warm paper")
	library.current=null;library.view.session=null;library.view.tick();shell._layout();shell._process(0)
	check(shell.toast.text=="对白前的通知" and is_equal_approx(shell.toast_time,remaining),"dialogue close resumes exactly the unread lifetime")
	var c3_view:Control=shell.c3_narrative_host.view
	# The production portrait-film host reparents its caption into root space.
	c3_view.reparent(shell.c3_narrative_host,false);c3_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c3_view.surface_visible=true;c3_view.session=SourceLine.new();c3_view.tick();shell._layout()
	check(c3_view.is_visible_in_tree(),"C3 pause fixture is actually visible outside the hidden SubViewport")
	shell._process(6)
	check(not shell.toast.visible and c3_view.panel.get_theme_stylebox("panel").bg_color==Ui.PAPER,"visible C3 caption also suspends ordinary notices on opaque paper")
	c3_view.session=null;c3_view.tick();shell._layout();shell._process(0)
	check(shell.toast.text=="对白前的通知" and is_equal_approx(shell.toast_time,remaining),"C3 caption hands back the same unread notice")
	await reset_phone()
	shell._feedback("等待口播的通知");shell._process(.4);remaining=shell.toast_time
	var director:Node=shell.audio_director
	director.source.events.notice_test_voice={"cues":[{"channel":"voice","asset":"vo_prologue_narrator_caught","subtitleKey":"prologue_narrator_caught","durationMs":180}]}
	director.cue("notice_test_voice");director._process(0);await frames()
	check(director.last_subtitle.get("presentationRole","")=="dialogue","exact source kind identifies immediate dialogue independently of notice tone")
	var caption:Variant=shell.get("story_caption")
	check(is_instance_valid(caption) and caption.is_visible_in_tree(),"voice subtitle is visible immediately despite a pending ordinary notice")
	check(not shell.toast.visible,"ordinary notification pauses while the spoken caption is visible")
	if is_instance_valid(caption):
		check(caption.body.text==director.last_subtitle.text,"caption retains exact Chinese source text")
		check(not caption.is_processing_input(),"read-only shell caption cannot consume underlying Space/Enter/Tab input")
		check(shell.phone.get_global_rect().encloses(caption.panel.get_global_rect()),"spoken caption stays inside the canonical phone safe region")
		check(is_equal_approx(caption.panel.get_global_rect().end.y,(shell.phone.position+Vector2(0,820)*shell.phone.scale).y),"phone dialogue is anchored in the bottom reading lane")
		check(caption.panel.get_global_rect().position.y>=(shell.phone.position+Vector2(0,100)*shell.phone.scale).y,"caption preserves status, app header and task safe space")
		for viewport:Vector2i in [Vector2i(390,844),Vector2i(667,375)]:
			root.size=viewport;shell.size=Vector2(viewport);shell._layout();await frames()
			var rect:Rect2=caption.panel.get_global_rect()
			check(shell.phone.get_global_rect().encloses(rect),"scaled caption remains in phone: "+str(viewport))
			check(is_equal_approx(rect.end.y,(shell.phone.position+Vector2(0,820)*shell.phone.scale).y),"scaled caption retains bottom reading lane: "+str(viewport))
			check(rect.position.y>=(shell.phone.position+Vector2(0,100)*shell.phone.scale).y,"scaled caption preserves upper safe region: "+str(viewport))
		root.size=Vector2i(430,860);shell.size=Vector2(root.size);shell._layout()
	shell._process(.64)
	check(shell.toast.text=="等待口播的通知" and is_equal_approx(shell.toast_time,remaining),"exact 180+450ms voice-caption lifetime never spends or extends the ordinary notice")
	await reset_phone()
	shell._feedback("任务到来前的通知")
	director.scheduled.append({"id":"notice_task_fixture","at":0,"story":{"text":"任务：核对当前记录。","durationMs":4200}})
	director._process(0)
	check(director.last_subtitle.get("presentationRole","")=="notification" and shell.toast.text=="任务到来前的通知","timed task feedback stays FIFO without posing as spoken dialogue")
	shell._process(10)
	check(shell.toast.text=="任务：核对当前记录。" and is_equal_approx(shell.toast_time,4.2),"queued task retains its exact authored reading duration")
	await reset_phone()
	shell._show_settings();shell._feedback("设置里的通知");await frames();shell._process(0)
	check(shell.modal_notice_slot.visible and shell.modal_notice_slot.get_global_rect().encloses(shell.toast.get_global_rect()),"generic modal keeps its reserved notice row")
	check(shell.toast.mouse_filter==Control.MOUSE_FILTER_IGNORE and root.gui_get_focus_owner()!=shell.toast,"queued notices never take pointer or keyboard ownership")
	await shell.shutdown();shell.queue_free();await frames()
	print("NOTICE_QUEUE_LIFECYCLE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
