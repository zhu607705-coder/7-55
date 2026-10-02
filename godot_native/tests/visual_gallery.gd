extends Node
## Explicit DEV-only real-render gallery. No formal save is written. Screenshots
## are viewport pixels, not generated artwork or proof of a story playthrough.
var host: Control
var saved_state: Dictionary
var saved_formal: Dictionary
var saved_developer:=false
var viewport: SubViewport
var preview: Control
var gallery_root: Control
var label: Label
var cancelled:=false
var restored:=false
var report: Array=[]
const SAMPLES=[
	["c2-dorm-exit","phone_home","home"],
	["c2-dorm-exit","settings","settings"],
	["c2-dorm-exit","settings","settings_desktop","desktop"],
	["c2-dorm-exit","weather","weather"],
	["c2-dorm-exit","zjuding","zjuding"],
	["c2-dorm-exit","wechat","wechat"],
	["c2-dorm-exit","campus_card","campus_card"],
	["c2-dorm-exit","cc98","cc98"],
	["c2-dorm-exit","directory","directory"],
	["c2-dorm-exit","tiyi","tiyi"],
	["c2-dorm-exit","library_app","library"],
	["c3-interlude-reboot","c35_recovery","recovery"],
	["c3-interlude-reboot","c35_voice","voice_memos"],
	["c3-interlude-reboot","c35_photos","recovery_photos"],
	["c3-interlude-reboot","c35_network","network_records"],
	["c3-qizhen-open-water","c3_journal_camera","lake_camera"],
	["c3-qizhen-open-water","c3_journal","lake_journal"]
]
func start(main: Control) -> void:
	host=main
	if DisplayServer.get_name()=="headless": host._feedback("视觉回归需要实际图形窗口。"); queue_free(); return
	saved_state=State.d.duplicate(true); saved_formal=State.formal_snapshot.duplicate(true); saved_developer=State.developer_mode
	State.developer_mode=true
	host._close_modal(); host.hide(); host.set_process(false)
	if host.world: host.world.set_process(false)
	gallery_root=Control.new(); gallery_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); get_tree().root.add_child(gallery_root)
	var backdrop:=ColorRect.new(); backdrop.color=Color("101e28"); backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); gallery_root.add_child(backdrop)
	label=Label.new(); label.text="正在渲染原生页面回归图…"; label.position=Vector2(28,24); label.add_theme_font_override("font",host.font); gallery_root.add_child(label)
	var cancel:=Button.new(); cancel.text="取消视觉回归"; cancel.position=Vector2(28,68); cancel.size=Vector2(180,44); cancel.add_theme_font_override("font",host.font); cancel.pressed.connect(func(): cancelled=true); gallery_root.add_child(cancel)
	var container:=SubViewportContainer.new(); container.position=Vector2(240,16); container.size=Vector2(430,860); gallery_root.add_child(container)
	viewport=SubViewport.new(); viewport.size=Vector2i(430,860); viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS; viewport.gui_disable_input=true; container.add_child(viewport)
	preview=load("res://scenes/main.tscn").instantiate(); viewport.add_child(preview)
	_run.call_deferred()
func _settle_world_fade() -> void:
	# Observe the real transition lifecycle before freezing a visual sample.
	preview.world.set_process(true)
	var deadline: int=Time.get_ticks_msec()+2500
	while preview.world.transition_alpha>0 and Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

func _settle() -> void:
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
func _capture(path: String, metadata: Dictionary = {}) -> void:
	await _settle()
	var image:=viewport.get_texture().get_image()
	var error:=image.save_png(path)
	var entry: Dictionary={"path":path,"width":image.get_width(),"height":image.get_height(),"error":error}
	entry.merge(metadata,true)
	report.append(entry)
func _run() -> void:
	var directory: String="res://.screenshots/gallery-"+str(Time.get_ticks_msec())
	DirAccess.make_dir_recursive_absolute(directory)
	for sample in SAMPLES:
		if cancelled: break
		var checkpoint:=str(sample[0])
		if not State.begin_checkpoint(checkpoint):
			# Historical source IDs are discovered, never silently approximated.
			report.append({"checkpoint":checkpoint,"error":"checkpoint missing"}); continue
		State.d.native.scene=""; State.d.native.page=str(sample[1]); State.d.native.settings.volume=0
		State.d.ui.controlCenterOpen=false
		preview._refresh()
		if sample.size()>3 and preview.phone_builder:
			preview.phone_builder.settings_page=str(sample[3]); preview._refresh()
		label.text="真实渲染 · "+str(sample[2])+"\nDEV 会话，不覆盖正式进度"
		viewport.size=Vector2i(430,860); preview.size=Vector2(430,860); preview._layout()
		await _settle()
		# Logical phone canvas, exactly the source frame's430×860 contract.
		preview.phone.position=Vector2.ZERO; preview.phone.scale=Vector2.ONE
		await _capture(directory+"/"+str(sample[2])+"-logical430.png")
		viewport.size=Vector2i(390,844); preview.size=Vector2(390,844); preview._layout()
		await _capture(directory+"/"+str(sample[2])+"-mobile390.png")
		if str(sample[2])=="settings":
			preview._on_phone_page("control_center")
			viewport.size=Vector2i(430,860); preview.size=Vector2(430,860); preview._layout()
			await _settle(); preview.phone.position=Vector2.ZERO; preview.phone.scale=Vector2.ONE
			await _capture(directory+"/control-center-logical430.png")
			preview._on_phone_action("native_control_center_close",null)
	if not cancelled: await _render_worlds(directory)
	if not cancelled: await _render_chapter4_phase_worlds(directory)
	if not cancelled: await _render_scene_timelines(directory)
	if not cancelled: await _render_games(directory)
	var file:=FileAccess.open(directory+"/render-report.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify({"kind":"native-render-gallery","notStoryPlaythrough":true,"cancelled":cancelled,"captures":report},"\t")); file.close()
	print("NATIVE_VISUAL_GALLERY ",ProjectSettings.globalize_path(directory)," captures=",report.size())
	_restore()
	host._feedback("原生页面渲染回归已保存："+directory.get_file())
	queue_free()
func _restore() -> void:
	if restored: return
	restored=true
	if is_instance_valid(preview): preview.queue_free()
	if is_instance_valid(gallery_root): gallery_root.queue_free()
	State.d=saved_state; State.formal_snapshot=saved_formal; State.developer_mode=saved_developer
	host.show(); host.set_process(true)
	if host.world: host.world.set_process(true)
	State.story_reset.emit(); State.changed.emit()
func _exit_tree() -> void:
	if not restored and not saved_state.is_empty(): _restore()

func _render_worlds(directory: String) -> void:
	viewport.size=Vector2i(960,540); preview.size=Vector2(960,540)
	var checkpoints: Array=State.developer_checkpoints()
	for scene in ["dorm_hub","campus_bootstrap","library_interior","canteen_interior","theater_interior","campus_qizhen_loop","qizhen_lake","duan_yongping_temporal_maze"]:
		if cancelled: break
		var id: String=""
		for entry in checkpoints:
			if entry.state.rpgScene==scene and entry.state.runtimeMode=="rpg": id=str(entry.id); break
		if scene=="duan_yongping_temporal_maze": id="c4-755-bakery-1225"
		if scene=="qizhen_lake": id="c3-qizhen-open-water"
		if id.is_empty(): report.append({"scene":scene,"error":"source checkpoint missing"}); continue
		State.begin_checkpoint(id); State.d.native.settings.volume=0
		preview._refresh(); preview.mobile_world=true; preview._layout()
		label.text="真实960×540场景 · "+scene
		await _settle()
		var path: String=directory+"/world-"+scene+".png"
		var image: Image=preview.world_viewport.get_texture().get_image()
		report.append({"path":path,"width":image.get_width(),"height":image.get_height(),"error":image.save_png(path),"checkpoint":id})

func _render_games(directory: String) -> void:
	viewport.size=Vector2i(960,540); preview.size=Vector2(960,540)
	State.begin_checkpoint("c4-755-room204-1850"); State.d.native.settings.volume=0
	preview._open_game({"script":"res://scripts/games/chapter4_stairs.gd","viewport":[960,540],"session":"visual-gallery"})
	await _settle()
	for index in 4:
		if cancelled: break
		if not await _load_stair_gallery_level(preview.active_game,index):
			report.append({"requestedLevel":index+1,"error":"stair reveal did not settle on requested source level"})
			continue
		await _settle()
		preview.active_game.position=Vector2.ZERO; preview.active_game.scale=Vector2.ONE
		label.text="真实3D投影楼梯 · "+str(index+1)
		await _capture(directory+"/stairs-level-"+str(index+1)+".png",{"levelIndex":index,"levelId":preview.active_game.level.id,"revealComplete":preview.active_game.reveal_done})
	preview.active_game.queue_free(); preview.active_game=null
	await get_tree().process_frame

	if cancelled: return
	if not State.begin_checkpoint("c4-755-closure"):
		report.append({"error":"closure source checkpoint missing"}); return
	State.d.native.settings.volume=0
	var request: Dictionary={}
	for module in State.modules:
		if str(module.get_script().resource_path)=="res://scripts/chapters/chapter4.gd":
			request=module.dispatch(State.d,"c4_lamp_start"); break
	if not request.has("game"):
		report.append({"error":"source closure controller rejected gallery checkpoint","result":request}); return
	preview._open_game(request.game)
	await _settle(); preview.active_game.position=Vector2.ZERO; preview.active_game.scale=Vector2.ONE
	await _capture(directory+"/star-lamp-questions.png",{"phase":State.d.chapter4.phase,"stage":preview.active_game.stage,"controllerRequested":true})
	preview.active_game._answer("purpose","seek_truth")
	await _settle()
	await _capture(directory+"/star-lamp-second-question.png",{"phase":State.d.chapter4.phase,"stage":preview.active_game.stage,"questionIndex":preview.active_game.question_index})
	preview.active_game._answer("person","clear_minded")
	await get_tree().process_frame
	if preview.active_game.stage!="playback" or "zhu_two_questions_answered" not in State.d.chapter4.factIds:
		report.append({"error":"closure answer callbacks did not enter saved playback"})
	else:
		for stamp in [1200,3800,5800]:
			var deadline: int=Time.get_ticks_msec()+15000
			while is_instance_valid(preview.active_game) and preview.active_game.elapsed<float(stamp):
				if cancelled or Time.get_ticks_msec()>deadline: break
				await get_tree().process_frame
			if cancelled or not is_instance_valid(preview.active_game): break
			if preview.active_game.elapsed<float(stamp): report.append({"requestedMs":stamp,"error":"actual closure playback did not reach capture time"}); break
			# Pause the actual live frame for a still; never write stage/elapsed or bypass the question lifecycle.
			preview.active_game.set_process(false)
			await _capture(directory+"/star-lamp-"+str(stamp)+"ms.png",{"elapsedMs":preview.active_game.elapsed,"stage":preview.active_game.stage,"savedAnswers":State.d.chapter4.zhuQuestionAnswers,"notStoryPlaythrough":true})
			preview.active_game.set_process(true)
	preview.active_game.queue_free(); preview.active_game=null
	await get_tree().process_frame

func _load_stair_gallery_level(stairs: Control, index: int) -> bool:
	# The authored reveal locks input. Never label a rejected busy load as a
	# different level or bypass the animation lock to obtain a screenshot.
	var deadline: int=Time.get_ticks_msec()+10000
	await get_tree().process_frame
	while is_instance_valid(stairs) and (stairs.busy or not stairs.reveal_done):
		if cancelled or Time.get_ticks_msec()>deadline: return false
		await get_tree().process_frame
	if cancelled or not is_instance_valid(stairs) or index<0 or index>=stairs.source.levels.size(): return false
	stairs.level_index=index
	stairs._load_level()
	await get_tree().process_frame
	while is_instance_valid(stairs) and (stairs.busy or not stairs.reveal_done):
		if cancelled or Time.get_ticks_msec()>deadline: return false
		await get_tree().process_frame
	return is_instance_valid(stairs) and str(stairs.level.id)==str(stairs.source.levels[index].id)

func _render_scene_timelines(directory: String) -> void:
	# Capture actual controller-issued presentation hosts in a temporary DEV
	# checkpoint. Fast-forward uses the same advance action as the native button.
	# This is visual-state coverage, never a claimed full story playthrough.
	if not is_instance_valid(preview.c3_scene_host):
		report.append({"error":"chapter-three native scene host missing"}); return
	viewport.size=Vector2i(960,540); preview.size=Vector2(960,540)
	State.begin_checkpoint("c2-seat-dialogue"); State.d.native.settings.volume=0
	preview._refresh(); preview.mobile_world=true; preview._layout()
	await _settle_world_fade()
	preview.c3_scene_host.set_process(false); preview.world.set_process(false)
	preview.c3_scene_host.tick(0)
	for phase in ["conversation","record_scan","mode_unlock","paper_burst","exit_observation","cart_clear","arrival"]:
		if cancelled: break
		if not await _advance_opening_gallery_phase(phase): break
		if preview.c3_scene_host.current==null:
			report.append({"requestedPhase":phase,"error":"opening ended before requested source phase"}); break
		for i in 3: preview.c3_scene_host.tick(100)
		label.text="真实章节转场 · "+phase
		var snapshot: Dictionary=preview.c3_scene_host.current.snapshot()
		await _capture(directory+"/c3-opening-"+phase+".png",{"scene":"library_interior","timeline":snapshot,"notStoryPlaythrough":true})
	if not cancelled:
		State.begin_checkpoint("c3-canteen-entry"); State.d.native.settings.volume=0
		preview._refresh(); preview.mobile_world=true; preview._layout()
		await _settle_world_fade()
		preview.world.set_process(false); preview.c3_scene_host.set_process(false)
		preview.world.player=Vector2(1053,663); preview.world._sync_player()
		preview.c3_scene_host.tick(0)
		await _capture(directory+"/c3-canteen-entry-waiting.png",{"scene":"canteen_interior","timeline":{"phase":"waiting","sourcePoint":[1053,302]},"notStoryPlaythrough":true})
		preview.world.player=Vector2(1053,660); preview.world._sync_player(); preview.c3_scene_host.tick(0)
		for sample: Array in [[1490,"discovered"],[3850,"escape-route"],[6200,"camera-return"],[7300,"system-prompt"]]:
			if cancelled: break
			if not await _advance_canteen_gallery_time(float(sample[0])): break
			var elapsed: float=float(sample[0])
			if preview.c3_scene_host.current==null:
				for i in 19: preview.c3_scene_host.tick(10)
			label.text="真实食堂纸条 · "+str(sample[1])
			await _capture(directory+"/c3-canteen-entry-"+str(sample[1])+".png",{"scene":"canteen_interior","timeline":{"phase":sample[1],"elapsedMs":elapsed,"entryPaperEscaped":State.d.canteenHunt.entryPaperEscaped},"notStoryPlaythrough":true})
	preview.c3_scene_host.reset(); preview.c3_scene_host.set_process(true); preview.world.set_process(true)

func _advance_opening_gallery_phase(phase: String, timeout_ms: int = 10000) -> bool:
	# This DEV renderer owns the temporary preview. It explicitly supplies a
	# focused frame before using the ordinary advance action: the actual window
	# may be unfocused while the user watches progress elsewhere. Never mutate
	# beat_index, phase, or story facts merely to produce a requested screenshot.
	var deadline: int=Time.get_ticks_msec()+maxi(1,timeout_ms)
	while is_instance_valid(preview) and is_instance_valid(preview.c3_scene_host) and preview.c3_scene_host.current!=null:
		if cancelled: return false
		var current: RefCounted=preview.c3_scene_host.current
		if current.kind!="opening":
			report.append({"requestedPhase":phase,"error":"gallery no longer owns an opening session"}); return false
		if str(current.snapshot().phase)==phase: return true
		if Time.get_ticks_msec()>=deadline:
			report.append({"requestedPhase":phase,"error":"opening advance timed out without reaching requested phase","snapshot":current.snapshot()}); return false
		preview.c3_scene_host.tick(0,true)
		preview.c3_scene_host._advance()
		await get_tree().process_frame
	# The caller records the ended-before-phase condition as an explicit miss.
	return true

func _advance_canteen_gallery_time(target_ms: float, timeout_ms: int = 10000) -> bool:
	var deadline: int=Time.get_ticks_msec()+maxi(1,timeout_ms)
	var iterations: int=0
	while is_instance_valid(preview) and is_instance_valid(preview.c3_scene_host) and preview.c3_scene_host.current!=null and preview.c3_scene_host.current.elapsed_ms<target_ms:
		if cancelled: return false
		if Time.get_ticks_msec()>=deadline:
			report.append({"requestedMs":target_ms,"error":"canteen timeline timed out without reaching requested time","snapshot":preview.c3_scene_host.current.snapshot()}); return false
		preview.c3_scene_host.tick(10,true)
		iterations+=1
		# Bound each synchronous slice while preserving the existing ten-ms tick.
		if iterations%10==0: await get_tree().process_frame
	return true

func _render_chapter4_phase_worlds(directory: String) -> void:
	viewport.size=Vector2i(960,540); preview.size=Vector2(960,540)
	for sample in [["c4-755-maintenance-2245","maintenance-cart",Vector2(1060,760)],["c4-755-maintenance-2245","maintenance-clock",Vector2(996,240)],["c4-755-blackout-0754","blackout-panel",Vector2(590,590)],["c4-755-checkin","morning-readers",Vector2(836,690)],["c4-755-final-minute","room202-minute",Vector2(1453,306)],["c4-755-room204-1850","a3-honor-wall",Vector2(820,700)],["c4-755-bakery-1225","a1-honor-wall",Vector2(350,235)]]:
		if cancelled: break
		if not State.begin_checkpoint(sample[0]): report.append({"checkpoint":sample[0],"error":"chapter4 source checkpoint missing"}); continue
		State.d.native.settings.volume=0; preview._refresh(); preview.mobile_world=true; preview._layout(); await _settle_world_fade(); preview.world.set_process(false)
		preview.world.player=sample[2]; preview.world._sync_player(); preview.world._update_camera(); preview.world.chapter4_layers.tick(0,State.d); preview.world.queue_redraw()
		label.text="真实第四章场景 · "+sample[1]
		await _settle()
		var path: String=directory+"/chapter4-"+sample[1]+".png"
		var pixels: Image=preview.world_viewport.get_texture().get_image()
		report.append({"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"error":pixels.save_png(path),"checkpoint":sample[0],"sourcePosition":[sample[2].x,sample[2].y],"notStoryPlaythrough":true})
	preview.world.set_process(true)
