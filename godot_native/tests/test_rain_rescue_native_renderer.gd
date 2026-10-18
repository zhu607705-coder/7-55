extends SceneTree
const Renderer=preload("res://scripts/media/c3_rain_rescue_native/renderer.gd")
const Timeline=preload("res://scripts/media/c3_rain_rescue_native/timeline.gd")
const Geometry=preload("res://scripts/media/c3_rain_rescue_native/pose_geometry.gd")
const Model=preload("res://scripts/media/c3_rain_rescue_model.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("TEST FAILED: "+label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	check(Renderer.available(),"all production renderer assets available inside native project")
	check(Timeline.DURATION*1000==Model.NATIVE_CINEMATIC_SOURCE_START_MS+Model.NATIVE_CINEMATIC_DURATION_MS,"native continuation offset plus duration matches authored sequence")
	check(Model.NATIVE_CINEMATIC_SOURCE_START_MS==Timeline.SPLASH*1000,"production starts at exact post-splash hold_hull boundary")
	check(Timeline.phase_at(Model.native_source_ms(0)/1000)=="hold_hull" and Timeline.phase_at(Model.native_source_ms(-100)/1000)=="hold_hull","first and negative-clock samples cannot replay wind or fall")
	check(Model.native_source_ms(Model.NATIVE_CINEMATIC_DURATION_MS)==15000 and Model.native_source_ms(999999)==15000,"continuation ends on the same authored safe wet idle pose")
	var renderer: Control=Renderer.new(); renderer.size=Vector2(960,540); root.add_child(renderer)
	await process_frame
	check(renderer.atlas is Texture2D and renderer.atlas_v2 is Texture2D and renderer.officer_contact is Texture2D,"all imported generated pose textures load, including PCK resource remaps")
	check(renderer.atlas_regions.size()==12 and renderer.atlas_v2_regions.size()==8,"both generated pose region catalogs load")
	check(not renderer.is_processing() and not renderer.is_processing_input() and not renderer.is_processing_unhandled_key_input(),"renderer has no autonomous process or input")
	check(renderer.mouse_filter==Control.MOUSE_FILTER_IGNORE and renderer.focus_mode==Control.FOCUS_NONE,"renderer cannot steal skip or world input")
	check(not renderer.has_signal("preview_finished") and not renderer.has_method("replay") and not renderer.has_method("skip"),"preview callbacks and replay never enter production")
	check(renderer.clip_contents,"sample background is clipped to logical viewport")
	var seen: Dictionary={}
	var previous: Vector2=Timeline.point_at(0)
	for index: int in range(901):
		var time: float=index/60.0
		renderer.present(time*1000)
		var point: Vector2=Timeline.point_at(time)
		seen[Timeline.phase_at(time)]=true
		check(point.is_finite() and point.distance_to(previous)<3,"production player has finite continuous motion")
		if time>=Timeline.DOCK and time<Timeline.LANDED:
			check((Timeline.officer_at(time)+Geometry.OFFICER_HAND_OFFSET).distance_to(Timeline.ring_at(time)+Geometry.RING_CONTACT_OFFSET)<.001,"production officer palms stay on ring rim")
			check((Timeline.teacher_at(time)+Vector2(34,-7)).distance_to(point+Vector2(-22,-1))<.001,"production teacher hands stay on player wrists")
		check(renderer.footprints.size()<=6,"footprint budget stays bounded")
		previous=point
	check(seen.size()==11,"all sample presentation stages survive adapter")
	renderer.present(13600)
	var before: Array=renderer.footprints.duplicate(true)
	await create_timer(.12).timeout
	check(renderer.elapsed==13.6 and renderer.wet_time==13.6 and renderer.footprints==before,"wall time alone changes no renderer pose or particle")
	renderer.present(13600)
	check(renderer.footprints==before,"repeated sample is deterministic")
	renderer.present(-10,true)
	check(renderer.elapsed==0 and renderer.footprints.is_empty() and renderer.reduced_motion,"bounded reduced-motion sample resets transient marks")
	renderer.present(999999)
	check(renderer.elapsed==Timeline.DURATION,"out-of-range samples clamp without completion callbacks")
	# Exercise every original caption at compact scale without any session or
	# story mutation. The actual graphical test separately covers root touch.
	var presenter: Control=load("res://scripts/media/c3_rain_rescue.gd").new()
	presenter.set_process(false); presenter.font=renderer.font
	presenter.caption=Label.new(); presenter.caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	presenter.caption.add_theme_font_override("font",renderer.font); presenter.add_child(presenter.caption)
	presenter.native_renderer=Renderer.new(); presenter.add_child(presenter.native_renderer); root.add_child(presenter)
	var compact_state: Dictionary={"native":{"host":{"world_display_scale":.37346938252449}}}
	for source_time: float in [0,2100,2800,3550,4600,7700,10500,11450,12700,15000]:
		presenter.native_renderer.present(source_time)
		presenter._layout_caption(compact_state)
		check(presenter.caption.text==presenter.native_renderer.caption_text(),"compact wrapper retains original sample caption")
		check(presenter.native_renderer.external_caption and presenter.caption.visible,"compact caption has exactly one visible owner")
		check(presenter.caption.get_theme_font_size("font_size")*.37346938252449>=14,"every compact caption meets minimum physical type size")
		check(presenter.caption.get_line_count()<=2 and presenter.caption.get_visible_line_count()==presenter.caption.get_line_count(),"every original caption fits at most two complete lines")
		check(Rect2(0,424,960,116).encloses(presenter.caption.get_rect()),"every compact caption remains in authored footer")
	presenter._layout_caption({"native":{"host":{"world_display_scale":1.0}}})
	check(not presenter.native_renderer.external_caption and not presenter.caption.visible,"desktop retains original renderer caption without duplicate Label")
	presenter.native_renderer.hide(); presenter.caption.text="值班老师和安全员把你救上岸。"
	presenter._layout_caption({"native":{"host":{"world_display_scale":1.0}}})
	check(presenter.caption.visible and presenter.caption.position==Vector2(24,440) and presenter.caption.size==Vector2(912,78) and presenter.caption.get_theme_font_size("font_size")==20,"desktop route/dock caption layout remains unchanged")
	presenter.queue_free(); renderer.queue_free(); await process_frame
	print("Rain rescue native renderer: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
