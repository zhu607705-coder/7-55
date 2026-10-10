extends "res://tests/test_phone_anchor01_absence.gd"
## Original waterDrop transaction and source-bound short motion, one anchor.
const WATER_SOUND="18_p07_weather_water_drop_collect"
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("ANCHOR03: "+message)
func fixture(dimensions: Vector2i,reduced: bool=false) -> void:
	shell._close_modal(); shell.audio_director.reset()
	check(state.begin_checkpoint("c1-code-hunt"),"original scattered-code checkpoint loads")
	state.d.native.settings.reduced_motion=reduced
	state.open_page("phone_home")
	root.size=dimensions; shell.size=Vector2(dimensions)
	shell.phone_chrome.set_inventory_top(240)
	shell._refresh(); shell._layout(); await frames(4)
	host.set_process(false); cues.clear(); actions.clear()
	check(named("HomeLiveWaterDrop")!=null and named("HomeCollectibleDropGlyph")!=null,"source collectible drop has actual visible glyph and hotspot")
func collect(touch: bool=false) -> void:
	var before: int=host.started_count
	var open_before: bool=state.d.ui.inventoryOpen
	var world_before: Rect2=rect(named("SourceHomeArtwork"))
	await click(named("HomeLiveWaterDrop"),touch)
	check(state.d.flags.waterDropTaken and state.d.items.waterDrop,"original controller commits water before340ms picture")
	check(actions.count("c1_rain_drop")==1 and host.started_count==before+1,"one gesture starts one accepted water presentation")
	check(not host.current.is_empty() and host.current.spec.anchor=="03","accepted water rise starts the source-bound copy")
	check(host.z_index==80,"water presentation retains original layer while digit-only toast fix stays scoped")
	check(named("HomeLiveWaterDrop")==null and named("HomeCollectibleDropGlyph")==null,"old collectible is visibly removed and cannot be picked twice")
	check(state.d.ui.inventoryOpen==open_before,"collection never auto-opens or closes the user's inventory")
	check(shell.phone_chrome.owned.has("waterDrop") and shell.phone_chrome.inventory.visible,"existing visible inventory immediately reflects real acquired item")
	check(rect(named("SourceHomeArtwork"))==world_before,"home plate and clouds do not move")
	check(not shell.phone_chrome.acquisition.visible and shell.phone_chrome.recent_item=="","generic acquisition VFX is retired for this water receipt only")
	check(cues.count(WATER_SOUND)==1,"existing18_ sound plays once without a new duplicate route")
func verify_poses(dimensions: Vector2i) -> void:
	if host.current.is_empty(): return
	var original: String=JSON.stringify(state.d)
	var source: Rect2=host.current.source
	var first: Dictionary=host.sample_at(0)
	check(first.scale.is_equal_approx(Vector2(.88,1.18)) and first.shape_mix==0,"K1 stretches only the original drop")
	check(is_equal_approx(first.center.y-source.size.y*1.18/2,source.position.y),"K1 fixes top contact as its end extends")
	var impact: Dictionary=host.sample_at(120)
	check(impact.center.is_equal_approx(source.get_center()+Vector2(0,18)) and impact.scale.is_equal_approx(Vector2(1.32,.58)),"K2 reaches18px fall and exact contact squash")
	check(impact.ripple==1,"K2 has two bounded4px ripples")
	var settled: Dictionary=host.sample_at(260)
	check(settled.shape_mix==1 and settled.scale==Vector2.ONE,"K3 becomes existing standard water inventory silhouette")
	check(settled.arc_length<=60.01,"transfer arc never exceeds60 logical pixels")
	if bool(host.current.nearby_slot):
		check(settled.center.is_equal_approx(host.current.target.get_center()),"nearby visible slot is the actual geometric landing")
	else:
		check(settled.center.is_equal_approx(source.get_center()+Vector2(0,18)),"hidden or distant slot uses local fall with real inventory receipt")
		check(not state.d.ui.inventoryOpen or host.current.receipt_kind=="visible-slot","fallback never invents a hidden target")
	for ms: int in [0,60,120,190,260,339]:
		var pose: Dictionary=host.sample_at(ms)
		samples.append({"viewport":[dimensions.x,dimensions.y],"ms":ms,"center":[pose.center.x,pose.center.y],"scale":[pose.scale.x,pose.scale.y],"shape_mix":pose.shape_mix,"receipt_kind":host.current.receipt_kind,"nearby_slot":host.current.nearby_slot,"arc_length":pose.arc_length})
	check(JSON.stringify(state.d)==original,"all water poses and branches leave state untouched")
	host._process(.339); check(not host.current.is_empty(),"water visual remains before340ms")
	host._process(.0011); check(host.current.is_empty() and state.d.items.waterDrop,"340ms retires only water copy")
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		push_error("Refusing anchor03 persistence outside isolated /tmp profile"); quit(2); return
	create_timer(80).timeout.connect(func(): push_error("Anchor03 watchdog"); quit(2))
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(5); shell.set_process(false); host=shell.phone_object_pickup
	shell.audio_director.playback_started.connect(func(_channel: String,asset: String): cues.append(asset))
	state.action_completed.connect(func(id: String,_before: Dictionary,_after: Dictionary,_result: Dictionary): actions.append(id))
	var touch_before: bool=Input.emulate_mouse_from_touch; Input.emulate_mouse_from_touch=true
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812)]:
		await fixture(dimensions); await collect(); check(not host.current.nearby_slot,"default closed backpack uses bounded local feedback"); verify_poses(dimensions)
		var starts: int=host.started_count
		shell._on_phone_action("c1_rain_drop",null); await frames()
		check(host.current.is_empty() and host.started_count==starts and cues.count(WATER_SOUND)==1,"repeat cannot create a second pickup or sound")
		await fixture(dimensions); state.d.ui.inventoryOpen=true; shell.phone_chrome.set_inventory_top(108); shell._refresh(); await frames()
		await collect(true)
		check(host.current.nearby_slot and host.current.receipt_kind=="visible-slot","pre-existing open nearby drawer permits actual short handoff")
		var target: Dictionary=shell.phone_chrome.item_receipt_geometry("waterDrop")
		check(host.current.target==target.rect,"new slot position matches settled Container layout")
		verify_poses(dimensions)
		await fixture(dimensions); state.d.ui.inventoryOpen=true; shell._refresh(); await frames(); await collect()
		check(not host.current.nearby_slot and host.current.receipt_kind=="visible-slot","visible but distant slot still respects60px bound")
		verify_poses(dimensions)
		await fixture(dimensions,true); await collect()
		var a: Dictionary=host.sample_at(0); var b: Dictionary=host.sample_at(260)
		check(a==b and a.ripple==0 and a.scale==Vector2.ONE,"reduced motion has no fall, squash or ripple")
	for cancellation: String in ["page","rebuild","replacement","modal","reset","next-input"]:
		await fixture(Vector2i(430,860)); await collect()
		match cancellation:
			"page": state.open_page("wechat")
			"rebuild": shell._refresh()
			"replacement": state.d=state.d.duplicate(true); shell._refresh()
			"modal": shell._show_settings(); host._process(0)
			"reset": state.story_reset.emit()
			"next-input":
				var event:=InputEventMouseButton.new(); event.pressed=true; event.button_index=MOUSE_BUTTON_LEFT; event.position=Vector2.ZERO; root.push_input(event,true)
				event=event.duplicate(); event.pressed=false; root.push_input(event,true)
		await frames()
		check(host.current.is_empty() and host.pending.is_empty(),"water owner clears after "+cancellation)
		check(state.d.items.waterDrop and state.d.flags.waterDropTaken,"accepted water survives "+cancellation)
	await fixture(Vector2i(430,860)); state.d.flags.codeScattered=false; shell._refresh(); await frames()
	shell._on_phone_action("c1_rain_drop",null); await frames()
	check(not state.d.items.waterDrop and host.current.is_empty(),"early rejected action has no reward or animation")
	await fixture(Vector2i(430,860)); await collect(); state.developer_mode=false
	check(state.save_game(),"accepted water saves during340ms effect")
	state.d=state.initial(); check(state.load_game(),"ordinary water save reload succeeds")
	shell._refresh(); await frames()
	check(state.d.items.waterDrop and named("HomeLiveWaterDrop")==null and host.current.is_empty(),"reload restores acquired item and no collectible source or replay")
	Input.emulate_mouse_from_touch=touch_before; state.developer_mode=true
	await shell.shutdown(); shell.queue_free(); await frames()
	var report: String=OS.get_environment("PHONE_ANCHOR_REPORT")
	if not report.is_empty(): FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"anchor":"03","checks":checks,"failures":failures,"samples":samples,"fixture":"source c1-code-hunt; inventory open/top preferences are fixture layout inputs","actual_cua":false,"physical_phone":false,"geometry_adaptation":"no auto-open; distant/hidden slots use local fall with real item/count receipt"},"  "))
	print("PHONE_ANCHOR03: ",checks," checks; ",failures," failures; one design anchor")
	quit(1 if failures else 0)
