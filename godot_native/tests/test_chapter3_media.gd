extends SceneTree
const Chapter = preload("res://scripts/chapters/chapter3.gd")
const Host = preload("res://scripts/media/c3_media_host.gd")
const Charge = preload("res://scripts/media/c3_charging_session.gd")
const Prank = preload("res://scripts/media/c3_battery_prank.gd")
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
	await create_timer(3.25).timeout
	check(s.native.get("c35_listened",[]).has("lake"),"actual AudioStreamPlayer crossed80 percent")
	check(not s.native.get("c35_reviewed",[]).has("lake"),"audio success is distinct from fallback review")
	var full: RefCounted = request.media.session
	request = controller.dispatch(s,"c35_excerpt",{"id":"lake","index":2})
	check(absf(request.media.session.start_ms-440)<1 and absf(request.media.session.end_ms-2840)<1,"source event seek has180ms lead and220ms tail")
	check(not request.media.session.marks_heard,"event excerpt cannot mark full audition")
	host.apply(request.media)
	await create_timer(0.12).timeout
	check(host.player.get_playback_position()>0.4,"real player seeks to excerpt offset")
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
	# Exact station guards and source elapsed time, with one-use receipt.
	s.native = {"chapter":3,"page":"c3_theater","scene":"theater_interior","mode":"light","player":{"x":665.0,"y":790.0}}
	s.rpgScene="theater_interior"; s.runtimeMode="rpg"; s.theaterHunt.active=true; s.phoneBattery.percent=1
	# This focused station fixture enters the theater normally; complete the
	# source entry dialogue before interacting with physical charging hardware.
	var story: RefCounted=controller.narrative_session(s)
	if story!=null:
		var narrator:=Node.new(); root.add_child(narrator)
		check(story.attach(s,narrator),"source theater introduction begins before station use")
		while story.status=="playing": story.frame(s,100,narrator,true)
		controller.dispatch(s,"c3_story_complete",story); narrator.queue_free()
	controller.dispatch(s,"c3_charge_result",{"elapsed_ms":2200,"success":true})
	check(s.phoneBattery.percent==1,"forged charging dictionary cannot recharge")
	var charge_request: Dictionary=controller.dispatch(s,"c3_target:theater_charging_station")
	check(charge_request.has("world_effect") and s.phoneBattery.percent==1,"connecting cable starts timeline only")
	if not charge_request.has("world_effect"): quit(1); return
	var charge: RefCounted=charge_request.world_effect.session
	check(charge.begin(s),"source stand accepted")
	controller.dispatch(s,"c3_charge_result",charge)
	check(s.phoneBattery.percent==1,"real but premature receipt rejected")
	var start: int=Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<2300:
		await create_timer(0.016).timeout
		charge.sample(s)
	controller.dispatch(s,"c3_charge_result",charge)
	check(s.phoneBattery.percent==45 and s.phoneBattery.rechargeCount==1,"2200ms elapsed restores45 percent once")
	controller.dispatch(s,"c3_charge_result",charge)
	check(s.phoneBattery.rechargeCount==1,"charge receipt single-use")
	s.phoneBattery.percent=2
	charge=Charge.new(); charge.begin(s); s.native.player.x=740
	charge.sample(s)
	check(charge.phase=="cancelled" and s.phoneBattery.percent==2,"source rectangle edge range cancels cable")
	s.native.player.x=665
	charge=Charge.new(); charge.begin(s); s.native.mode="dark"; charge.sample(s)
	check(charge.phase=="cancelled","changing reality mode cancels cable")
	s.native.mode="light"
	charge=Charge.new(); charge.begin(s); s.native.page="phone_home"; charge.sample(s)
	check(charge.phase=="cancelled","opening phone cancels charging")
	var prank: Control=Prank.new()
	root.add_child(prank); prank.setup(func() -> Dictionary: return s)
	prank.consume_reserve(2)
	check(prank.deadline<0,"prank only starts on reserve-used1 percent")
	prank.consume_reserve(1)
	var deadline: int=prank.deadline
	check(prank.view(deadline-10000).seconds==10 and prank.view(deadline-1).seconds==1,"exact warning countdown")
	check(prank.view(deadline).text=="吓吓你的" and prank.view(deadline+3500).is_empty(),"source joke lasts3500ms")
	prank.consume_reserve(1)
	check(prank.deadline==deadline,"reserve repeats do not restart prank")
	prank.reset(); prank.consume_reserve(1)
	check(prank.used,"recharge/reset can rearm prank")
	if not await host.shutdown():
		errors+=1
	check(await prank.shutdown(),"notification audio releases actual mixer references")
	prank.queue_free(); host.queue_free()
	await process_frame
	await process_frame
	print("Chapter 3 actual media and charging checks: ",checks,"; failures: ",errors)
	quit(0 if errors==0 else 1)
