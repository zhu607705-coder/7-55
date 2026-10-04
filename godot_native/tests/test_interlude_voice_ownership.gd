extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const Host=preload("res://scripts/media/c3_media_host.gd")
const Session=preload("res://scripts/media/c3_voice_session.gd")
var checks:int=0
var failures:int=0
var events:Array=[]
var controller=Chapter.new()
var state:Dictionary
var host:Node
func _initialize(): run.call_deferred()
func check(ok:bool,label:String):
 checks+=1
 if not ok: failures+=1;push_error(label)
func event_received(id:String,value:Variant):
 var result=controller.dispatch(state,id,value)
 events.append({"session":value,"message":str(result.get("message",""))})
func play(id:String):
 var request=controller.dispatch(state,"c35_listen",id)
 host.apply(request.media)
 return request.media.session
func frames():
 await process_frame
 await process_frame
func run():
 state=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
 state.native={"page":"c35_voice"};state.qizhenLake.phase="complete"
 controller.dispatch(state,"c35_begin");controller.dispatch(state,"c35_journal","safe_return")
 host=Host.new();root.add_child(host);host.setup(func()->Dictionary:return state)
 host.event.connect(event_received)
 var first=play("lake")
 await create_timer(.2).timeout
 var offset=events.size()
 var second=play("stone")
 check(first.phase=="stopped","switch stops previous actual audio owner")
 check(host.current==second and second.phase=="playing","switch starts one new actual owner")
 check(events.slice(offset).all(func(e):return e.session==second and e.message.is_empty()),"active switch emits only current receipt without expired toast")
 check(not controller.interlude.voice_reviewed(state,"lake"),"short interrupted clip cannot earn receipt")
 var fake=Session.new("stone",second.path)
 check(controller.dispatch(state,"c35_media_event",fake).get("message","")=="录音播放回执已失效。","forged receipt remains rejected")
 check(controller.dispatch(state,"c35_media_event",first).get("message","")=="录音播放回执已失效。","stale capability remains rejected outside host")
 var paused=controller.dispatch(state,"c35_listen","stone");host.apply(paused.media)
 check(second.phase=="paused" and host.player.stream_paused,"same clip pauses actual current player")
 var position=second.position_ms
 await create_timer(.15).timeout
 check(second.position_ms==position,"pause does not advance receipt")
 var resumed=controller.dispatch(state,"c35_listen","stone");host.apply(resumed.media)
 check(second.phase=="playing" and not host.player.stream_paused,"resume retains exact current player")
 var deadline=Time.get_ticks_msec()+7000
 while second.phase=="playing" and Time.get_ticks_msec()<deadline:await process_frame
 check(second.phase=="finished" and second.heard_ready,"real source clip finishes and earns sampled receipt")
 check(state.native.get("c35_listened",[]).count("stone")==1,"finished receipt retained exactly once")
 offset=events.size()
 var repeat=play("stone")
 check(repeat!=second and second.phase=="stopped","repeat retires finished session")
 check(events.slice(offset).all(func(e):return e.session==repeat and e.message.is_empty()),"finished repeat does not publish expired receipt")
 check(state.native.get("c35_listened",[]).count("stone")==1,"repeat does not duplicate earned receipt")
 offset=events.size();state.native.page="c35_recovery";await frames()
 check(host.current==null and repeat.phase=="stopped","Back retires player")
 check(events.slice(offset).size()==1 and events[-1].session==repeat and events[-1].message.is_empty(),"Back publishes one valid terminal receipt")
 state.native.page="c35_voice";var returned=play("lake")
 offset=events.size();var stop=controller.dispatch(state,"c35_voice_exit");var stopped_player=host.player;host.apply(stop.media)
 check(returned.phase=="stopped" and not stopped_player.playing,"explicit stop cancels actual audio")
 state.native.page="c35_recovery";await frames()
 check(host.current==null,"explicit stop retires host owner before later page cleanup")
 check(events.slice(offset).size()==1 and events[-1].session==returned and events[-1].message.is_empty(),"explicit stop preserves valid receipt notification")
 check(await host.shutdown(),"all stopped playback resources retire")
 host.queue_free();await frames()
 print("VOICE_RECEIPT_SWITCH ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
