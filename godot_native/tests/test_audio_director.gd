extends SceneTree
const Director = preload("res://scripts/media/audio_director.gd")
var checks: int = 0
var errors: int = 0
var state: Dictionary = {}
var director: Node
var played: Array = []
var texts: Array = []
var published: Array = []
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: errors += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func drain() -> void:
	await process_frame; await process_frame
func fixture(id: String, cues: Array) -> void: director.source.events[id] = {"cues":cues}
func run() -> void:
	state = JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native = {"page":"phone_home","scene":"","settings":{"music":true,"effects":true,"volume":1.0}}
	var original: String = JSON.stringify(state)
	director = Director.new(); root.add_child(director); director.setup(func() -> Dictionary: return state)
	director.playback_started.connect(func(channel: String, asset: String) -> void: played.append([channel,asset]))
	director.subtitle.connect(func(text: String, surface: String) -> void: texts.append([text,surface]))
	director.cue_published.connect(func(id: String, _payload: Dictionary) -> void: published.append(id))
	check(director.source.events.size()==237,"all237 timeline IDs exported")
	check(director.source.storyLines.size()==152,"all152 exact story lines exported")
	for asset in director.source.assets:
		check(director._stream(asset) is AudioStream,"exact source media loads: "+asset)
	for id in director.source.events:
		director.cue(id)
		check(published.has(id) or id=="chapter35_voice_audition_stop","every manifestcue accepted: "+id)
		director.reset()
	played.clear(); published.clear()
	director.cue("rpg_dorm_room_opened"); director.cue("rpg_dorm_room_opened")
	await drain()
	check(director.music is AudioStreamPlayer and director.music.playing,"music actualAudioStreamPlayer")
	check(director.music_asset=="music_act2_search" and director.music.stream.loop,"exact music id and loop")
	check(played.size()==1,"same-turn duplicate event plays once")
	var original_music: AudioStreamPlayer = director.music
	fixture("test_music_update",[{"channel":"music","action":"update","volume":.23,"playbackRate":1.06}])
	director.cue("test_music_update"); await drain()
	check(director.music==original_music and absf(director.music.pitch_scale-1.06)<.001,"music update keeps playback and applies rate")
	state.ui.musicPlaying=false; await drain()
	check(director.music.playing and director.music.volume_db > -20,"puzzle musicPlaying never mutes background")
	state.ui.musicMuted=true; await drain()
	check(director.music.volume_db < -80,"source musicMuted mutes background")
	state.ui.musicMuted=false; state.native.settings.music=false; await drain()
	check(director.music.volume_db < -80,"native music toggle mutes background")
	state.native.settings.music=true
	fixture("test_voice",[{"channel":"voice","asset":"vo_prologue_narrator_caught","subtitleKey":"prologue_narrator_caught","durationMs":180,"duckMusicTo":.04}])
	director.cue("test_voice"); await drain()
	check(director.voice is AudioStreamPlayer and director.voice.playing,"voice uses actualAudioStreamPlayer")
	check(absf(db_to_linear(director.music.volume_db)-.04)<.005,"voice ducks music")
	check(not texts.is_empty(),"voiced dialogue preserves Chinese subtitle")
	await create_timer(.25).timeout
	check(director.voice==null and absf(db_to_linear(director.music.volume_db)-.23)<.005,"voice duration restores target gain")
	fixture("test_offset",[{"channel":"sfx","asset":"fx_act1_login_stamp","offsetMs":150,"durationMs":500,"startMs":100,"pan":-.75}])
	var before: int = played.size(); director.cue("test_offset"); await drain()
	check(played.size()==before,"offset is not immediate")
	await create_timer(.2).timeout
	check(played.size()==before+1 and director.effects.size()==1,"offset starts exact effect")
	var effect: Dictionary = director.effects[0]
	check(effect.player is AudioStreamPlayer and effect.player.playing and effect.player.get_playback_position()>=.1,"sfx real playback and seek")
	var bus: int = AudioServer.get_bus_index(effect.bus)
	check(bus>0 and absf(AudioServer.get_bus_effect(bus,0).pan+.75)<.001,"authored stereo pan is applied")
	await create_timer(.55).timeout
	check(director.effects.is_empty() and AudioServer.get_bus_index(effect.bus)==-1,"duration removes effect and private pan bus")
	fixture("test_once",[{"channel":"sfx","asset":"fx_act1_login_stamp","once":true,"offsetMs":100}])
	before=played.size(); director.cue("test_once"); await drain(); director.cue("test_once")
	await create_timer(.16).timeout
	check(played.size()==before+1,"once reserves at schedule time")
	director.reset(); await drain()
	fixture("test_text_taunt",[{"channel":"voice","asset":"vo_legacy_wake_flash","subtitleKey":"sys_balance"}])
	before=played.size(); director.cue("test_text_taunt"); await drain()
	check(played.size()==before and director.voice==null,"taunt stays text even with real voice asset")
	check(texts[-1][0]==director.source.storyLines.sys_balance.subtitleZh,"taunt text is exact source")
	for key in director.source.storyLines:
		var line: Dictionary = director.source.storyLines[key]
		if line.get("speaker") not in ["player","seat022"] or line.has("voiceRole"): continue
		fixture("test_unvoiced",[{"channel":"voice","asset":"vo_legacy_wake_flash","subtitleKey":key}])
		director.cue("test_unvoiced"); await drain()
		check(director.voice==null,"unvoiced player/022 never synthesized: "+key)
	fixture("test_missing",[{"channel":"voice","asset":"not-a-real-asset","subtitleKey":"prologue_narrator_caught"},{"channel":"sfx","asset":"not-a-real-asset"}])
	before=texts.size(); director.cue("test_missing"); await drain()
	check(director.voice==null and texts.size()==before+1,"missing voice gracefully retains source subtitle")
	state.native.settings.effects=false
	fixture("test_effects_off",[{"channel":"sfx","asset":"fx_act1_login_stamp"},{"channel":"voice","asset":"vo_prologue_narrator_caught","subtitleKey":"prologue_narrator_caught"}])
	before=played.size(); director.cue("test_effects_off"); await drain()
	check(played.size()==before+1 and director.voice_asset=="vo_prologue_narrator_caught","effects toggle mutes sfx only, voiceddialogue survives")
	state.native.settings.effects=true; director.reset(); await drain()
	fixture("test_ambient",[{"channel":"ambient","asset":"fx_act1_login_stamp","owner":"chapter4_test","loop":true}])
	director.cue("test_ambient"); await drain()
	check(director.ambients.chapter4_test.player is AudioStreamPlayer and director.ambients.chapter4_test.player.playing,"ambient uses actualchannel player")
	fixture("chapter4_prologue_test",[{"channel":"sfx","asset":"fx_act1_login_stamp","offsetMs":120}])
	director.cue("chapter4_prologue_test"); director.cue("chapter4_prologue_closed")
	before=played.size(); await create_timer(.16).timeout
	check(played.size()==before,"prologue close cancels delayed cues")
	director.cue("chapter4_755_scene_closed"); await drain()
	check(director.ambients.is_empty(),"sceneclose removes owned chapter4 ambience")
	fixture("chapter35_voice_audition_test",[{"channel":"voice","asset":"vo_prologue_narrator_caught","offsetMs":100}])
	director.cue("chapter35_voice_audition_test"); director.cue("chapter35_voice_audition_stop")
	await create_timer(.16).timeout
	check(director.voice==null,"memo stop cancels scheduled audition")
	director.external_cue_prefixes=["chapter35_voice_audition_","chapter4_prologue_"]
	director.cue("chapter35_voice_audition_lake"); director.cue("chapter4_prologue_started"); await drain()
	check(director.scheduled.is_empty() and director.music==null,"external media owners never duplicate")
	director.external_cue_prefixes=[]
	director.cue("chapter4_prologue_started"); await drain()
	check(director.music_asset=="music_ch4_prologue_h3_44s","unified C4 prologue reaches exact soundtrack")
	director.cue("chapter4_prologue_skip"); await drain()
	check(director.music_asset=="music_ch4_prologue_h3_44s","source skip keeps music until finished/closed")
	director.cue("rpg_dorm_room_opened"); director.cue("act2_system_departure"); await drain()
	director.cue("chapter4_prologue_closed"); await drain()
	check(director.music_asset=="music_act2_search" and director.voice_asset=="vo_act2_system_departure","C4 close cannot stop a newer owner's music/voice")
	director.reset(); await drain()
	state.native.page="wechat"; await drain()
	director.cue("xiaoying_attack"); await drain()
	check(director.voice_asset=="vo_legacy_xy_attack","legacy alias resolves exact generated voice id")
	state.native.page="phone_home"; await drain()
	check(director.voice==null,"leaving WeChat cancels scatter voice")
	before=played.size(); director.cue("tower_key_insert"); await drain()
	check(played.size()==before,"key insertion has no premature rotation sound")
	director.cue("tower_key_rotate"); await drain()
	check(played[-1]==["sfx","21_p13_home_tower_key_turn_90deg"],"key rotation plays authored sfx")
	var oracle: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/audio-state-source.json"))
	for case in oracle.cases:
		check(director.derive_state_cues(oracle.states[int(case.previous)], oracle.states[int(case.next)]) == case.expected, "original PresentationDirector parity %s to %s" % [case.previous,case.next])
	state.native.settings.music=false; state.ui.musicPlaying=true
	await drain()
	check(director.chiptune is AudioStreamPlayer and director.chiptune.playing,"puzzle chiptune plays independently of background score toggle")
	var chip: AudioStreamWAV = director.chiptune.stream
	check(chip.loop_mode==AudioStreamWAV.LOOP_FORWARD and chip.loop_end==149760 and chip.mix_rate==48000,"chiptune exact3120ms twelve-note loop")
	check(director.source.chiptune.melody.map(func(n: Variant) -> int: return int(n))==[523,587,659,587,523,440,494,523,392,440,494,523],"source square-wave melody unchanged")
	check(chip.data.decode_s16(0)==983 and abs(chip.data.decode_s16(10560*2))==33 and chip.data.decode_s16(11520*2)==0,"chiptune .03 to .001 exponential220ms envelope and240ms cutoff")
	check(chip.data.decode_s16(12480*2)==983,"260ms tick restarts next note envelope")
	state.native.settings.effects=false; await drain()
	check(director.chiptune.playing and director.chiptune.volume_db>-1,"effects toggle does not mute puzzle music")
	state.ui.musicMuted=true; await drain()
	check(director.chiptune==null,"source ui.musicMuted stops puzzle chiptune")
	state.ui.musicMuted=false; await drain()
	check(director.chiptune.playing,"unmute restarts source melody")
	director._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT); await drain()
	check(director.chiptune.stream_paused,"hidden application suspends chiptune")
	director._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN); await drain()
	check(not director.chiptune.stream_paused,"focused application resumes chiptune")
	state.ui.musicPlaying=false; await drain()
	check(director.chiptune==null,"pause puzzle music stops real chiptune")
	state.native.settings.music=true; state.native.settings.effects=true
	# Source PresentationDirector state transitions and deduped mixed event/state path.
	director.reset(); published.clear(); await drain()
	var a: Dictionary={"currentScene":"a","runtimeMode":"rpg","rpgScene":"duan_yongping_temporal_maze","chapter4":{"phase":"maintenance_repair","factIds":[],"chaseAttempt":0}}
	var b: Dictionary=a.duplicate(true); b.chapter4.factIds=["clock_gear_repaired"]
	director.update_state("",a,b,{"presentation":[{"cueId":"clock_stable_started"}]})
	check(published.count("clock_stable_started")==1,"state+event same-turn stable cue dedupes")
	b.chapter4.phase="final_chase"; var c: Dictionary=b.duplicate(true); c.chapter4.chaseAttempt=1
	var derived: Array=director.derive_state_cues(b,c)
	check(derived==[{"cueId":"final_chase_failed"},{"cueId":"final_chase_started"}],"source final chase failure sequence exact")
	c.chapter4.phase="final_minute_recovery"
	check(director.derive_state_cues(b,c)==[{"cueId":"final_chase_succeeded"}],"source final chase success exact")
	c.runtimeMode="phone"; c.rpgScene="campus_bootstrap"
	check(director.derive_state_cues(b,c)[0].cueId=="chapter4_755_scene_closed","source sceneclose transition exact")
	var mapping_before: Dictionary = {"actOne":{"characterNamed":false},"native":{},"ui":{}}
	var mapping_after: Dictionary = mapping_before.duplicate(true); mapping_after.actOne.characterNamed=true
	published.clear(); director.update_state("c2_identify",mapping_before,mapping_after,{"presentation":[{"cueId":"act2_character_named","payload":{"name":"林星宇","studentId":"3250100755"}}]})
	check(published.count("act2_character_named")==1,"explicit rich source payload supersedes fallback action map")
	await drain(); published.clear(); director.update_state("c2_identify",mapping_after,mapping_after,{})
	check(not published.has("act2_character_named"),"repeated or rejected native action cannot emit success cue")
	director.cue("act2_system_found_intro"); director.cue("act2_system_dialogue_closed")
	await create_timer(.15).timeout
	check(director.voice==null,"closing system dialogue cancels delayed narration")
	# Consumer takes snapshots without writing them; settings toggles above are test input.
	state.ui.musicPlaying=JSON.parse_string(original).ui.musicPlaying
	state.ui.musicMuted=JSON.parse_string(original).ui.musicMuted
	check(JSON.stringify(state)==original,"audio director performed zero state mutation")
	var before_state: String=JSON.stringify(b); var next_state: String=JSON.stringify(c)
	director.update_state("lib_audit",b,c,{})
	check(JSON.stringify(b)==before_state and JSON.stringify(c)==next_state,"derived transition inputs remain untouched")
	director.reset(); await drain()
	check(director.scheduled.is_empty() and director.effects.is_empty() and director.voice==null and director.music==null and director.ambients.is_empty(),"reset leaves no channels or pending work")
	check(await director.shutdown(), "all real audio playbacks released before process exit")
	director.queue_free(); await drain()
	print("NATIVE_AUDIO_DIRECTOR checks=",checks," errors=",errors)
	quit(1 if errors else 0)
