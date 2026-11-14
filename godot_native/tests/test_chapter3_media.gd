extends SceneTree
const Chapter = preload("res://scripts/chapters/chapter3.gd")
const Host = preload("res://scripts/media/c3_media_host.gd")
var checks: int = 0
var errors: int = 0
var controller: RefCounted = Chapter.new()
var host: Node
var s: Dictionary

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: errors += 1; push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	s = JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native = {"chapter":3,"page":"c35_voice","scene":"","mode":"light","player":{},"selected_item":"","log":[],"completed":[]}
	s.qizhenLake.phase = "complete"
	controller.dispatch(s,"c35_begin")
	controller.dispatch(s,"c35_journal","safe_return")
	host = Host.new()
	root.add_child(host)
	host.setup(func() -> Dictionary: return s)
	host.event.connect(func(id: String,value: Variant) -> void: controller.dispatch(s,id,value))
	controller.dispatch(s,"c35_media_event",{"success":true,"clip_id":"lake","position_ms":5200,"heard_ready":true})
	check(not controller.interlude.voice_reviewed(s,"lake"),"forged dictionary cannot claim playback")
	var request: Dictionary = controller.dispatch(s,"c35_listen","lake")
	check(not controller.interlude.voice_reviewed(s,"lake"),"clicking play never marks heard")
	controller.dispatch(s,"c35_media_event",request.media.session)
	check(not controller.interlude.voice_reviewed(s,"lake"),"issued capability alone is not proof")
	host.apply(request.media)
	await create_timer(1.2).timeout
	check(not controller.interlude.voice_reviewed(s,"lake"),"real early playback stays unreviewed")
	host.apply(controller.dispatch(s,"c35_listen","lake").media)
	var paused: float = host.current.position_ms
	await create_timer(0.3).timeout
	check(host.current.phase=="paused" and absf(host.current.position_ms-paused)<2,"pause freezes actual offset")
	host.apply(controller.dispatch(s,"c35_listen","lake").media)
	# Wall time is not AudioServer evidence: wait for the real session receipt.
	var heard_deadline: int=Time.get_ticks_msec()+6500
	while not s.native.get("c35_listened",[]).has("lake") and Time.get_ticks_msec()<heard_deadline and host.current!=null and host.current.phase=="playing":
		await process_frame
	check(s.native.get("c35_listened",[]).has("lake"),"actual AudioStreamPlayer crossed80 percent")
	if not s.native.get("c35_listened",[]).has("lake"):
		await host.shutdown();host.queue_free();await process_frame;quit(1);return
	check(not s.native.get("c35_reviewed",[]).has("lake"),"audio success is distinct from fallback review")
	var full: RefCounted = request.media.session
	request = controller.dispatch(s,"c35_excerpt",{"id":"lake","index":2})
	check(request.has("media"),"a genuine heard receipt permits the source excerpt")
	if not request.has("media"):
		await host.shutdown();host.queue_free();await process_frame;quit(1);return
	var recording: Dictionary=controller.interlude.voice_recording("lake")
	var part: Dictionary=recording.soundEvents[2]
	var start:=maxf(0.0,float(part.startMs)-180.0)
	var end:=minf(float(request.media.session.duration_ms),float(part.endMs)+220.0)
	check(absf(request.media.session.start_ms-start)<1 and absf(request.media.session.end_ms-end)<1,"source event seek has180ms lead and220ms tail")
	check(not request.media.session.marks_heard,"event excerpt cannot mark full audition")
	host.apply(request.media)
	await create_timer(0.12).timeout
	check(host.player.get_playback_position()>start/1000.0-.04,"real player seeks to excerpt offset")
	controller.dispatch(s,"c35_media_event",full)
	check(controller.interlude.voice_session!=full,"replaced capability cannot become current")
	# Missing-media route is visibly timed captions, never invented audio-heard.
	request = controller.dispatch(s,"c35_listen","stone")
	request.media.session.path = "res://missing-test-audio.mp3"
	host.apply(request.media)
	check(host.current.fallback,"missing media selects readable source-event fallback")
	await create_timer(4.25).timeout
	check(s.native.get("c35_reviewed",[]).has("stone") and not s.native.get("c35_listened",[]).has("stone"),"fallback review unblocks selection without claiming heard")
	controller.dispatch(s,"c35_select_voice","stone")
	check(s.native.c35_voice_selection.has("stone"),"source-compatible missing-audio path remains usable")
	s.native.page = "c35_recovery"
	await process_frame
	await process_frame
	check(host.current==null,"leaving voice page cancels audition")
	if not await host.shutdown():
		errors+=1
	host.queue_free()
	await process_frame
	await process_frame
	print("Chapter 3 actual media checks: ",checks,"; failures: ",errors)
	quit(0 if errors==0 else 1)
