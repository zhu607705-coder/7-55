extends SceneTree
## Emulated root input + real Main/audio consumers. Presentation fixtures do not
## grant story facts, and every stage uses the native test save sandbox.
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Notice=preload("res://scripts/ui/native_phone_notice.gd")
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
func check_paper_caption(view:Control,label:String)->void:
	var face:StyleBox=view.panel.get_theme_stylebox("panel")
	check(face is StyleBoxFlat and face.bg_color==Notice.PAPER and face.border_color==Notice.INK,label+" shares the opaque notice paper")
	check(view.body.get_theme_color("font_color")==Notice.INK and Ui._contrast(Notice.INK,Notice.PAPER)>=4.5,label+" retains readable dark ink")
func click(control:Control)->void:
	var at:=control.get_global_transform_with_canvas()*(control.size/2)
	for down in [true,false]:
		var e:=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e,true);await frames(1)
func reset_phone()->void:
	state.d=state.initial();state.d.native.page="phone_home";state.story_reset.emit();shell._refresh();shell.mobile_world=false;shell._layout();await frames()
	shell.set_process(false);shell.audio_director.set_process(false);shell.audio_director.reset()
	for host in [shell.c3_narrative_host,shell.c3_scene_host,shell.library_story_host]:
		if is_instance_valid(host):host.set_process(false)
	shell.world.set_process(false)
func run()->void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial();state.d.native.page="phone_home"
	root.size=Vector2i(430,860);shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(5)
	# These notice fixtures exercise previously visited dialogue surfaces.
	# Visit their owning content before resetting to the phone; initial Main
	# intentionally has no later-story hosts anymore.
	state.begin_checkpoint("c3-canteen-entry");shell._refresh();await frames()
	state.d=state.initial();state.d.native.chapter=2;state.d.native.scene="library_interior"
	state.d.ui.libraryFinalsPhase="evidence_gathering";shell._refresh();await frames()
	await reset_phone()
	shell._feedback("第一条通知");shell._feedback("第二条通知");shell._feedback("第二条通知")
	check(shell.toast.text=="第二条通知","burst immediately replaces the old message")
	shell._process(1)
	check(shell.toast.text=="第二条通知" and is_equal_approx(shell.toast_time,1.4),"latest notice counts down from its refreshed full lifetime")
	shell._process(2.5)
	check(shell.toast.text.is_empty(),"expired latest message never replays its predecessors")
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
	check(shell.active_game==null and shell.toast.text.is_empty() and shell.notice_queue.current.is_empty(),"actual Return cannot revive notices that expired while hidden")
	shell._process(remaining+.01)
	check(shell.toast.text.is_empty() and shell.notice_queue.pending.is_empty(),"activity-time replacement leaves no delayed backlog")
	await reset_phone()
	shell._feedback("对白前的通知");shell._process(.5);remaining=shell.toast_time
	var line:=SourceLine.new();var library:Control=shell.library_story_host
	library.current=line;library.view.session=line;library.view.tick();shell._layout();shell._process(8)
	check(not shell.toast.visible,"library dialogue hides the generic notice while its clock continues")
	var phone_paper:StyleBox=library.view.panel.get_theme_stylebox("panel")
	check(library.view.on_phone and phone_paper is StyleBoxFlat and phone_paper.bg_color==Color.WHITE and phone_paper.border_width_top>0,"library phone caption uses its opaque reader paper")
	check(library.view.body.get_theme_color("font_color")==Notice.INK and Ui._contrast(Notice.INK,Color.WHITE)>=4.5,"library phone caption retains readable dark ink")
	library.current=null;library.view.session=null;library.view.tick();shell._layout();shell._process(0)
	check(shell.toast.text.is_empty() and shell.notice_queue.current.is_empty(),"dialogue close cannot revive an expired notice")
	shell._feedback("C3对白前的通知")
	var c3_view:Control=shell.c3_narrative_host.view
	# The production portrait-film host reparents its caption into root space.
	c3_view.reparent(shell.c3_narrative_host,false);c3_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c3_view.surface_visible=true;c3_view.session=SourceLine.new();c3_view.tick();shell._layout()
	check(c3_view.is_visible_in_tree(),"C3 pause fixture is actually visible outside the hidden SubViewport")
	shell._process(6)
	check(not shell.toast.visible,"visible C3 caption hides ordinary notices")
	check_paper_caption(c3_view,"C3 caption")
	c3_view.session=null;c3_view.tick();shell._layout();shell._process(0)
	check(shell.toast.text.is_empty() and shell.notice_queue.current.is_empty(),"C3 caption close cannot replay expired ordinary feedback")
	await reset_phone()
	shell._feedback("等待口播的通知");shell._process(.4);remaining=shell.toast_time
	var director:Node=shell.audio_director
	director.source.events.notice_test_voice={"cues":[{"channel":"voice","asset":"vo_prologue_narrator_caught","subtitleKey":"prologue_narrator_caught","durationMs":180}]}
	director.cue("notice_test_voice");director._process(0);await frames()
	check(director.last_subtitle.get("presentationRole","")=="dialogue","exact source kind identifies immediate dialogue independently of notice tone")
	var caption: Label=shell.phone_story_caption
	check(is_instance_valid(caption) and caption.is_visible_in_tree(),"voice subtitle is visible immediately despite a pending ordinary notice")
	check(not shell.toast.visible,"ordinary notification hides while the spoken caption is visible")
	if is_instance_valid(caption):
		check(caption.text==director.last_subtitle.text,"caption retains exact Chinese source text")
		check(caption.mouse_filter==Control.MOUSE_FILTER_IGNORE and not shell.story_caption.is_processing_input(),"read-only shell captions cannot consume underlying input")
		check(shell.phone.get_global_rect().encloses(caption.get_global_rect()),"spoken caption stays inside the canonical phone safe region")
		check(is_equal_approx(caption.get_global_rect().end.y,(shell.phone.position+Vector2(0,820)*shell.phone.scale).y),"phone dialogue is anchored in the bottom reading lane")
		check(caption.get_global_rect().position.y>=(shell.phone.position+Vector2(0,100)*shell.phone.scale).y,"caption preserves status, app header and task safe space")
		for viewport:Vector2i in [Vector2i(390,844),Vector2i(667,375)]:
			root.size=viewport;shell.size=Vector2(viewport);shell._layout();await frames()
			var rect:Rect2=caption.get_global_rect()
			check(shell.phone.get_global_rect().encloses(rect),"scaled caption remains in phone: "+str(viewport))
			check(is_equal_approx(rect.end.y,(shell.phone.position+Vector2(0,820)*shell.phone.scale).y),"scaled caption retains bottom reading lane: "+str(viewport))
			check(rect.position.y>=(shell.phone.position+Vector2(0,100)*shell.phone.scale).y,"scaled caption preserves upper safe region: "+str(viewport))
		root.size=Vector2i(430,860);shell.size=Vector2(root.size);shell._layout()
	shell._process(.64)
	check(shell.toast.text=="等待口播的通知" and is_equal_approx(shell.toast_time,remaining-.64),"exact 180+450ms voice-caption lifetime does not freeze or extend the ordinary notice")
	await reset_phone()
	shell._feedback("任务到来前的通知")
	director.scheduled.append({"id":"notice_task_fixture","at":0,"story":{"text":"任务：核对当前记录。","durationMs":4200}})
	director._process(0)
	check(director.last_subtitle.get("presentationRole","")=="notification" and shell.toast.text=="任务：核对当前记录。" and is_equal_approx(shell.toast_time,4.2),"timed task feedback replaces ordinary feedback without posing as spoken dialogue")
	shell._process(10)
	check(shell.toast.text.is_empty() and shell.notice_queue.pending.is_empty(),"task expires at its authored deadline without replaying old feedback")
	await reset_phone()
	shell._show_settings();shell._feedback("设置里的通知");await frames();shell._process(0)
	check(shell.modal_notice_slot.visible and shell.modal_notice_slot.get_global_rect().encloses(shell.toast.get_global_rect()),"generic modal keeps its reserved notice row")
	check(shell.toast.z_index>shell.modal.z_index,"reserved notice is drawn above its modal")
	check(shell.toast.mouse_filter==Control.MOUSE_FILTER_IGNORE and root.gui_get_focus_owner()!=shell.toast,"latest notices never take pointer or keyboard ownership")
	await shell.shutdown();shell.queue_free();await frames()
	print("NOTICE_QUEUE_LIFECYCLE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
