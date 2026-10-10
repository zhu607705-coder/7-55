extends SceneTree
var shell: Control
var state: Node
var checks: Array=[]
var failures: Array=[]
var audio_starts: Array=[]
var completions: Array=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,id: String,detail: Variant=null) -> void:
	var item={"id":id,"passed":ok,"detail":detail}; checks.append(item)
	if not ok:failures.append(item);push_error(id)
func frame(count: int=3) -> void:
	for i in count:await process_frame
func click(button: BaseButton) -> void:
	var center=button.get_global_rect().get_center()
	for down in [true,false]:
		var event=InputEventMouseButton.new();event.position=center;event.global_position=center;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
		root.push_input(event,true);await process_frame
func headphone() -> Button:
	return shell.control_center.find_child("ControlHeadphones",true,false) as Button if is_instance_valid(shell.control_center) else null
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	state.d.native.page="phone_home";state.d.currentScene="phone_home";state.d.native.chapter=1
	state.d.ui.controlCenterOpen=true;state.d.ui.musicPlaying=false;state.d.native.settings.volume=.6
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frame(8)
	state.action_completed.connect(func(action: String,previous: Dictionary,next: Dictionary,_result: Dictionary):
		if action=="c1_headphone" and not previous.flags.headphoneFallen and next.flags.headphoneFallen:completions.append(Time.get_ticks_usec()))
	shell.audio_director.playback_started.connect(func(channel: String,asset: String):
		if asset=="15_p05_control_center_earphone_icon_drop":audio_starts.append({"time_us":Time.get_ticks_usec(),"channel":channel,"flag":state.d.flags.headphoneFallen,"item":state.d.items.headphone}))
	var button=headphone();check(button!=null,"real-control-center-headphone-present")
	if button==null:quit(2);return
	await click(button);await frame()
	check(not state.d.flags.headphoneFallen and not state.d.items.headphone,"rejected-without-music-does-not-grant-item")
	check(audio_starts.is_empty(),"rejected-without-music-has-no-fall-sfx")
	state.act("c1_music");await frame(5);button=headphone()
	check(button!=null and state.d.ui.musicPlaying,"real-music-action-enables-fall")
	var start_position: float=button.position.y
	var clicked: int=Time.get_ticks_usec();await click(button);await frame(2)
	check(audio_starts.size()==1,"accepted-fall-emits-one-source-sfx-at-start")
	check(not state.d.flags.headphoneFallen and not state.d.items.headphone,"fall-sound-precedes-controller-item-grant")
	if not audio_starts.is_empty():
		check(not audio_starts[0].flag and not audio_starts[0].item,"audio-event-observes-pre-completion-state")
		check(audio_starts[0].time_us-clicked<250000,"audio-request-within-first-animation-segment-us",audio_starts[0].time_us-clicked)
	var fx=shell.audio_director.effects.filter(func(entry: Dictionary):return entry.asset=="15_p05_control_center_earphone_icon_drop")
	check(fx.size()==1 and absf(fx[0].gain-.9)<.001,"exact-source-default09-gain")
	check(button.disabled,"fall-guards-repeat-click")
	await click(button);await create_timer(.15).timeout
	check(audio_starts.size()==1,"rapid-second-click-does-not-duplicate-cue")
	check(is_instance_valid(button) and button.position.y>start_position,"existing-fall-animation-still-progresses")
	check(not state.d.flags.headphoneFallen,"no-early-controller-completion")
	await create_timer(.6).timeout
	check(state.d.flags.headphoneFallen and state.d.items.headphone,"original-completion-callback-grants-item")
	check(completions.size()==1,"exactly-one-controller-completion")
	check(audio_starts.size()==1,"completion-flag-does-not-replay-sound")
	if completions.size()==1 and audio_starts.size()==1:
		check(completions[0]>audio_starts[0].time_us+300000,"sound-precedes-completion-by-animation-interval-us",completions[0]-audio_starts[0].time_us)
	shell._refresh_control_center();await frame()
	check(headphone()==null,"completed-item-does-not-recreate-falling-control")
	check(audio_starts.size()==1,"panel-refresh-does-not-replay-drop")
	check(await shell.audio_director.shutdown(),"audio-thread-clean-shutdown")
	shell.queue_free();await frame()
	var output=OS.get_environment("HEADPHONE_AUDIO_QA_REPORT")
	if output.is_empty():output="user://headphone-audio-timing.json"
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"audio_starts":audio_starts,"completions":completions,"real_cua":false,"audible_acceptance":false},"  "))
	print("HEADPHONE_AUDIO_TIMING ",checks.size()," checks; ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
