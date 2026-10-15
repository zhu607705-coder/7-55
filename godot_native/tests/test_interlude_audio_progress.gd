extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const Host=preload("res://scripts/media/c3_media_host.gd")
var checks:int=0
var failures:int=0
func _initialize():run.call_deferred()
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;push_error(label)
func run():
	var controller=Chapter.new()
	var state:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"page":"c35_voice"};state.qizhenLake.phase="complete"
	controller.dispatch(state,"c35_begin");controller.dispatch(state,"c35_journal","safe_return")
	var host=Host.new();root.add_child(host);host.setup(func()->Dictionary:return state)
	host.event.connect(func(id:String,value:Variant):controller.dispatch(state,id,value))
	var request=controller.dispatch(state,"c35_listen","lake");host.apply(request.media)
	var session=request.media.session
	var deadline=Time.get_ticks_msec()+int(session.duration_ms)+5000
	while session.phase=="playing" and Time.get_ticks_msec()<deadline:await process_frame
	check(session.phase=="finished" and not session.fallback,"actual source playback finishes naturally")
	check(is_equal_approx(session.position_ms,session.end_ms),"finished caption and progress reach the actual endpoint")
	check(session.heard_ready and state.native.get("c35_listened",[]).has("lake"),"genuine sampled playback retains its earned receipt")
	request=controller.dispatch(state,"c35_listen","stone");host.apply(request.media);session=request.media.session
	await create_timer(.15).timeout
	var verified:float=session.verified_ms
	session.finish();controller.dispatch(state,"c35_media_event",session)
	check(session.position_ms==session.end_ms,"completed presentation has a stable endpoint")
	check(session.verified_ms<session.duration_ms*.8 and session.verified_ms>=verified,"finish does not invent verified listening duration")
	check(not session.heard_ready and not controller.interlude.voice_reviewed(state,"stone"),"premature finish cannot create an audition receipt")
	check(await host.shutdown(),"actual playback resources retire")
	host.queue_free();await process_frame;await process_frame
	print("INTERLUDE_AUDIO_PROGRESS ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
