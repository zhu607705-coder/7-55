extends "res://tests/test_phone_anchor01_absence.gd"
## Reuse only Main fixture/input helpers. Anchor02 has independent outcomes.
const Seven=preload("res://scripts/ui/tiyi_seven_art.gd")
const SEVEN_SOUND="10_global_digit_collect_fly_to_slot"
const SEVEN_VOICE="vo_legacy_tiyi_47"
var seven_events: Array=[]
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("ANCHOR02: "+message)
func fixture(dimensions: Vector2i,reduced: bool=false) -> void:
	shell._close_modal(); shell._close_phone_document(); shell.audio_director.reset()
	check(state.begin_checkpoint("c1-code-hunt"),"original scattered-code checkpoint loads")
	state.d.native.settings.reduced_motion=reduced
	state.act("c1_network","cellular"); state.open_page("tiyi")
	root.size=dimensions; shell.size=Vector2(dimensions)
	shell._refresh(); shell._layout(); await frames(4)
	host.set_process(false)
	check(named("TiyiCount47")==null,"source1400ms entry is not shortened")
	shell._process(1.399); await frames()
	check(named("TiyiCount47")==null,"count still hidden at1399ms")
	shell._process(.001); await frames()
	check(named("TiyiCount47")!=null and named("TiyiSevenPickupSource")!=null,"real accepted entry reveals original right-hand7")
	cues.clear(); actions.clear(); seven_events.clear()
func collect(touch: bool=false) -> void:
	var before: int=host.started_count
	var plate: Control=named("TiyiSourcePlate")
	var original_rect:=rect(plate); var original_texture: Texture2D=plate.texture
	await click(named("TiyiCount47"),touch)
	check(state.d.flags.tiyiCountTaken and state.d.digits.d2=="7","original action commits7 before its picture moves")
	check(actions.count("c1_tiyi_digit")==1 and host.started_count==before+1,"one gesture starts one accepted anchor02")
	check(not host.current.is_empty() and host.current.spec.anchor=="02","true flag edge starts the7 cutout")
	check(host.z_index==111 and host.z_index>shell.toast.z_index,"moving7 stays visible through its authored text-only taunt")
	check(named("TiyiSevenPickupSource")==null,"taken7 source cannot be extracted again")
	check(rect(named("TiyiSourcePlate"))==original_rect and named("TiyiSourcePlate").texture==original_texture,"entire original plate stays fixed and byte-identical")
	check(named("TiyiSourcePlate").material.shader.code==Seven.TAKEN_SHADER,"terminal patch is limited to the native7 region")
	check(cues.count(SEVEN_SOUND)==1 and seven_events.count("tiyi_47")==1,"original10_ and authored tiyi_47 event each occur once")
	check(cues.count(SEVEN_VOICE)==0 and shell.audio_director.last_subtitle.text=="就差一次，真绝望","existing native text-only taunt policy remains intact")
func verify_poses(dimensions: Vector2i) -> void:
	if host.current.is_empty(): return
	var source: Rect2=host.current.source; var target: Rect2=host.current.target
	check(host.glyph_texture!=null and host.glyph_texture.texture is AtlasTexture,"only the original cropped7 becomes a moving texture")
	check(host.glyph_texture.texture.region==Seven.SEVEN_REGION,"source cutout excludes left-hand4")
	check(host.glyph_texture.mouse_filter==Control.MOUSE_FILTER_IGNORE,"moving cutout cannot intercept the next action")
	var first: Dictionary=host.sample_at(0)
	check(first.anchor.is_equal_approx(source.position+Vector2(0,-3)) and is_equal_approx(first.rotation,deg_to_rad(6)),"K1 lifts3px around upper-left source contact at6degrees")
	var peel: Dictionary=host.sample_at(140)
	check(peel.anchor.is_equal_approx(source.position+Vector2(10,-10)) and is_equal_approx(peel.rotation,deg_to_rad(14)),"K2 peels right/up10px at14degrees")
	var landed: Dictionary=host.sample_at(360)
	check(landed.center.is_equal_approx(target.get_center()) and landed.rotation==0,"K3 reaches actual second clue digit at360ms")
	check(host.sample_at(479)==landed,"landed7 holds readable pose for120ms")
	var saved: String=JSON.stringify(state.d)
	for ms: int in [0,70,140,250,360,479]:
		var pose: Dictionary=host.sample_at(ms)
		samples.append({"viewport":[dimensions.x,dimensions.y],"ms":ms,"center":[pose.center.x,pose.center.y],"rotation":pose.rotation,"scale":pose.scale.x})
		check(Rect2(Vector2.ZERO,host.size).has_point(pose.center),"7 pose remains in phone "+str(ms))
	check(JSON.stringify(state.d)==saved,"all7 poses remain read-only")
	host._process(.479); check(not host.current.is_empty(),"7 hold remains before480ms")
	host._process(.0011); check(host.current.is_empty() and host.glyph_texture==null,"480ms clears only copied artwork")
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		push_error("Refusing anchor02 persistence outside isolated /tmp profile"); quit(2); return
	create_timer(80).timeout.connect(func(): push_error("Anchor02 watchdog"); quit(2))
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(5); shell.set_process(false); host=shell.phone_object_pickup
	shell.audio_director.playback_started.connect(func(_channel: String,asset: String): cues.append(asset))
	shell.audio_director.cue_published.connect(func(id: String,_payload: Dictionary): seven_events.append(id))
	state.action_completed.connect(func(id: String,_before: Dictionary,_after: Dictionary,_result: Dictionary): actions.append(id))
	var touch_before: bool=Input.emulate_mouse_from_touch; Input.emulate_mouse_from_touch=true
	check(Seven.SOURCE.get_size()==Vector2(852,1846),"verified original source dimensions")
	check(Seven.SEVEN_REGION.position.x==126 and Seven.SEVEN_REGION.end.x==194,"crop starts strictly after the complete4 atx118")
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812)]:
		await fixture(dimensions); await collect(); verify_poses(dimensions)
		var starts: int=host.started_count
		await click(named("TiyiCount47"))
		check(host.current.is_empty() and host.started_count==starts and cues.count(SEVEN_SOUND)==1 and seven_events.count("tiyi_47")==1,"repeated count inspection cannot repeat extraction or sound")
		await fixture(dimensions); await collect(true)
		await click(named("PhoneNav_exit"),true)
		check(state.d.native.page=="phone_home" and host.current.is_empty(),"touch exit cancels flight without undoing7")
		check(state.d.flags.tiyiCountTaken and state.d.digits.d2=="7","touch exit retains accepted clue")
		await fixture(dimensions,true); await collect()
		check(host.sample_at(0)==host.sample_at(360),"reduced motion keeps7 at terminal slot without peeling")
	for cancellation: String in ["rebuild","replacement","modal","control-center","document","reset"]:
		await fixture(Vector2i(430,860)); await collect()
		match cancellation:
			"rebuild": shell._refresh()
			"replacement": state.d=state.d.duplicate(true); shell._refresh()
			"modal": shell._show_settings(); host._process(0)
			"control-center": shell._on_phone_page("control_center"); host._process(0)
			"document": shell._open_phone_document({"item_id":"waterDrop"}); host._process(0)
			"reset": state.story_reset.emit()
		await frames()
		check(host.current.is_empty() and host.glyph_texture==null,"interruption retires copied7: "+cancellation)
		check(state.d.flags.tiyiCountTaken and state.d.digits.d2=="7","interruption preserves accepted7: "+cancellation)
		if state.d.ui.controlCenterOpen: shell._on_phone_action("native_control_center_close",null)
		if is_instance_valid(shell.phone_document): shell._close_phone_document()
	await fixture(Vector2i(430,860)); state.act("c1_network","campus_wifi"); await frames(); await collect()
	check(state.get_phone_entry_session().entry_allowed,"accepted mount snapshot remains valid after network switch")
	state.open_page("phone_home"); state.open_page("tiyi"); await frames()
	check(named("TiyiCount47")==null,"new blocked mount still uses original loader")
	# Fresh rejected mount must not accept7 or create any effect.
	state.begin_checkpoint("c1-code-hunt"); state.act("c1_network","campus_wifi"); state.open_page("tiyi"); await frames()
	shell._on_phone_action("c1_tiyi_digit",null); await frames()
	check(not state.d.flags.tiyiCountTaken and host.current.is_empty(),"blocked original action produces no7 or animation")
	await fixture(Vector2i(430,860)); await collect()
	state.developer_mode=false; check(state.save_game(),"accepted7 saves during its480ms visual")
	state.d=state.initial(); check(state.load_game(),"ordinary7 save reload succeeds")
	shell._refresh(); await frames(); shell._process(1.4); await frames()
	check(named("TiyiSourcePlate")!=null and named("TiyiSourcePlate").material!=null and named("TiyiSevenPickupSource")==null,"reload displays taken source crop after original entry delay")
	check(host.current.is_empty() and state.d.digits.d2=="7","reload never replays7 extraction")
	Input.emulate_mouse_from_touch=touch_before; state.developer_mode=true
	await shell.shutdown(); shell.queue_free(); await frames()
	var report: String=OS.get_environment("PHONE_ANCHOR_REPORT")
	if not report.is_empty(): FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"anchor":"02","checks":checks,"failures":failures,"samples":samples,"fixture":"source c1-code-hunt; actual1400ms entry contract","actual_cua":false,"physical_phone":false},"  "))
	print("PHONE_ANCHOR02: ",checks," checks; ",failures," failures; one design anchor")
	quit(1 if failures else 0)
