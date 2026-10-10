extends SceneTree
const Director=preload("res://scripts/media/audio_director.gd")
var director: Node
var state: Dictionary
var played: Array=[]
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,id: String,detail: Variant=null) -> void:
	var item={"id":id,"passed":ok,"detail":detail}; checks.append(item)
	if not ok: failures.append(item); push_error(id)
func drain() -> void:
	await process_frame;await process_frame;await process_frame
func publish(action: String,previous: Dictionary,next: Dictionary) -> void:
	director.update_state(action,previous,next,{"handled":true})
	await drain()
func count(asset: String) -> int:
	return played.filter(func(value: Array):return value[1]==asset).size()
func check_effect(asset: String,gain: float,id: String) -> void:
	var matches=director.effects.filter(func(e: Dictionary):return e.asset==asset)
	check(matches.size()==1,id+"-one-player",matches.size())
	if matches.size()==1:
		check(absf(matches[0].gain-gain)<.0001,id+"-source-gain",matches[0].gain)
		check(matches[0].player.playing and absf(db_to_linear(matches[0].player.volume_db)-gain*.6)<.0001,id+"-effective-master-gain")
func reset() -> void:
	director.reset();played.clear();await drain()
func run() -> void:
	state=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"page":"bonsai","scene":"","settings":{"music":true,"effects":true,"volume":.6}}
	state.ui.musicPlaying=false
	var immutable_before=JSON.stringify(state)
	director=Director.new();root.add_child(director);director.setup(func() -> Dictionary:return state)
	director.playback_started.connect(func(channel: String,asset: String):played.append([channel,asset]))
	var original_catalog=JSON.stringify(director.source)
	await publish("c1_plant",state,state)
	check(count("04_global_ui_invalid_drag_reject")==1,"wrong-drop-one-reject")
	check_effect("04_global_ui_invalid_drag_reject",.5,"wrong-drop")
	await reset()
	director.update_state("c1_plant",state,state,{"handled":true});director.update_state("c1_plant",state,state,{"handled":true});await drain()
	check(count("04_global_ui_invalid_drag_reject")==2,"two-real-attempts-two-rejects-no-extra")
	await reset()
	for flag in ["plantWatered","plantLit","plantFertilized"]:
		var next=state.duplicate(true);next.flags[flag]=true
		var asset={"plantWatered":"22_p10_plant_water_growth_step","plantLit":"23_p10_plant_light_growth_step","plantFertilized":"24_p10_plant_fertilizer_growth_step"}[flag]
		await publish("c1_plant_light" if flag=="plantLit" else "c1_plant",state,next)
		check(count(asset)==1,"successful-"+flag+"-once")
		check(count("04_global_ui_invalid_drag_reject")==0,"successful-"+flag+"-no-reject")
		check_effect(asset,.9,flag)
		await reset()
		if flag=="plantLit":
			await publish("c1_plant_light",next,next)
			check(played.is_empty(),"repeated-light-no-success-sound")
		else:
			await publish("c1_plant",next,next)
			check(count(asset)==0 and count("04_global_ui_invalid_drag_reject")==1,"already-applied-"+flag+"-rejects-once")
		await reset()
	await publish("c1_flower",state,state)
	check(played.is_empty(),"unbloomed-flower-silent")
	var bloomed=state.duplicate(true);bloomed.flags.flowerBloomed=true
	var revealed=bloomed.duplicate(true);revealed.native.flower_eight_visible=true
	await publish("c1_flower",bloomed,revealed)
	check(count("02_global_ui_button_tap_soft")==1,"flower-reveal-one-source-tap")
	check_effect("02_global_ui_button_tap_soft",.9,"flower-reveal")
	await reset();await publish("c1_flower",revealed,revealed)
	check(count("02_global_ui_button_tap_soft")==1,"repeated-valid-flower-click-preserves-source-tap")
	await reset()
	var taken=revealed.duplicate(true);taken.flags.flowerEightTaken=true;taken.native.flower_eight_visible=false;taken.digits.d4="8"
	await publish("c1_collect_flower",revealed,taken)
	check(count("10_global_digit_collect_fly_to_slot")==1,"collect-eight-one-source-sound")
	check_effect("10_global_digit_collect_fly_to_slot",.9,"collect-eight")
	await reset();await publish("c1_collect_flower",taken,taken);await publish("c1_flower",taken,taken)
	check(played.is_empty(),"collected-flower-repeat-silent")
	await publish("c1_collect_flower",bloomed,bloomed)
	check(played.is_empty(),"unrevealed-digit-collect-silent")
	var unrelated=state.duplicate(true);unrelated.flags.gearFallen=true
	await publish("c1_gear_rotated",state,unrelated)
	check_effect("17_p08_settings_gear_drop_flip",.8,"unrelated-default-gain-preserved")
	check(JSON.stringify(state)==immutable_before,"presentation-does-not-write-reader-state")
	check(JSON.stringify(director.source)==original_catalog,"source-catalog-unchanged")
	check(await director.shutdown(),"audio-thread-clean-shutdown")
	director.queue_free();await drain()
	var output=OS.get_environment("BONSAI_AUDIO_QA_REPORT")
	if output.is_empty():output="user://bonsai-audio-parity.json"
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"real_cua":false,"audible_acceptance":false},"  "))
	print("BONSAI_AUDIO_PARITY ",checks.size()," checks; ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
