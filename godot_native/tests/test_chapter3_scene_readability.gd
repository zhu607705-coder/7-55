extends SceneTree
const Overlay=preload("res://scripts/ui/world_overlay_layout.gd")
var checks: int=0
var errors: int=0
var state: Node
var shell: Control
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: errors+=1; push_error(label)
func _initialize() -> void: call_deferred("run")
func opening_state() -> void:
	state.d=state.initial(); state.developer_mode=true
	state.d.native.chapter=2; state.d.native.scene="library_interior"; state.d.native.page="library_022_dialogue"
	state.d.runtimeMode="rpg"; state.d.rpgScene="library_interior"
	state.d.ui.libraryFinalsPhase="seat_recovered"; state.d.ui.libraryFinalsPuzzle.playerSeated=true
	state.d.rpgCheckpoint="library_seat_022"
func run() -> void:
	state=root.get_node("State"); opening_state()
	root.size=Vector2i(1280,720)
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell)
	await process_frame; await process_frame
	shell.world.set_process(false); shell.c3_scene_host.set_process(false)
	var host: Control=shell.c3_scene_host
	for extent: Vector2i in [Vector2i(390,844),Vector2i(430,844),Vector2i(844,390),Vector2i(1280,720),Vector2i(3840,2160)]:
		var width := extent.x
		opening_state(); state.story_reset.emit(); state.changed.emit()
		root.size=extent
		shell.mobile_world=true; shell._layout(); await process_frame; await process_frame
		host.tick(0,true)
		var session: RefCounted=host.current
		check(session!=null and session.kind=="opening","actual shell issues original opening at "+str(width))
		var view: Control=host.opening
		var beats: int=0
		while host.current!=null and beats<40:
			view.tick()
			var source: Dictionary=session.snapshot()
			var expected_subtitle: String="" if str(source.text).is_empty() else str(source.speaker)+"："+str(source.text)
			check(view.subtitle.text==expected_subtitle,"exact source text remains on beat "+str(beats))
			var triangle: PackedVector2Array=view.advance_triangle()
			check(triangle.size()==(0 if source.phase=="arrival" else 3),"native source down-triangle appears only before arrival")
			for vertex: Vector2 in triangle:
				check(Rect2(Vector2.ZERO,view.advance_button.size).has_point(vertex),"advance triangle stays inside unchanged button hitbox")
			if triangle.size()==3:
				check(is_equal_approx(triangle[1].x-triangle[0].x,minf(view.advance_button.size.x,view.advance_button.size.y)*.32),"advance mark scales with its button")
			var display:=Rect2(view.origin,Vector2(960,540)*view.scale_factor)
			check(Rect2(Vector2.ZERO,view.size).encloses(view.subtitle_panel),"opening panel stays inside the window")
			if not display.encloses(view.subtitle_panel):
				check(view.size.y>view.size.x and view.subtitle_panel.position.y>=display.get_center().y,"only a portrait caption can extend below the film")
			check(view.subtitle.get_theme_font_size("font_size")==roundi(18*Overlay.ui_scale(display.size)),"opening text scales with the film, with a narrow-screen floor")
			check(view.subtitle.get_visible_line_count()==view.subtitle.get_line_count(),"the actual label shows every wrapped row")
			check(view.subtitle_panel.encloses(view.subtitle.get_rect()),"wrapped label remains inside its card")
			if view.narrow:
				check(view.subtitle_panel.encloses(view.advance_button.get_rect()) and not view.subtitle.get_rect().intersects(view.advance_button.get_rect()),"actual next control remains inside panel without covering text")
			else:
				check(is_equal_approx(view.subtitle_panel.size.x,908*Overlay.ui_scale(display.size)) and view.subtitle_panel.encloses(view.advance_button.get_rect()),"wide caption card and next button scale together")
			host._advance(); beats+=1
		check(beats==27,"all27source beats tested through genuine advance controls")
		state.d=state.initial(); state.d.native.chapter=3; state.d.native.scene="canteen_interior"; state.d.native.page="c3_canteen"
		state.d.runtimeMode="rpg"; state.d.rpgScene="canteen_interior"; state.d.canteenHunt.active=true; state.d.canteenHunt.phase="tray_search"
		state.story_reset.emit(); state.changed.emit(); await process_frame
		shell.world.player=Vector2(1053,660); shell.world._sync_player(); host.tick(0,true)
		var paper: Control=host.paper
		check(is_equal_approx(paper.display_scale,shell.world_frame.scale.x),"paper reads actual Main display scale")
		check(paper.narrow_text()==(shell.world.size.x*shell.world_frame.scale.x<620),"paper narrow decision uses displayed width rather than logical960")
		for text: String in ["玩家：找到了。","纸条：！","旁白：纸条钻进了食堂。","系统：先别跟丢。"]:
			for tail: bool in [true,false]:
				var layout: Dictionary=paper.text_layout(text,Vector2(-10,800),70,.8,tail)
				check(layout.fontSize*paper.display_scale>=Overlay.BODY_PX*Overlay.ui_scale(shell.world.size*paper.display_scale)-.01,"paper source text follows displayed game size")
				check(Rect2(Vector2.ZERO,shell.world.size).encloses(layout.rect),"paper bubble/tail clamped inside real world")
				check(layout.rect.size.y<=shell.world.size.y*.5,"paper text panel does not cover more than world half")
				check("".join(layout.lines)==text,"wrapping preserves exact complete source text")
				for line: String in layout.lines:
					check(paper.font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,layout.fontSize).x<=layout.rect.size.x-layout.padding*2+.01,"paper wrapped glyphs fit available width")
		for i in range(72): host.tick(100,true)
		check(state.d.canteenHunt.entryPaperEscaped and paper.tail_lines.size()==2,"source entry timing and actual tail handoff preserved")
	await shell.shutdown(); shell.queue_free(); await process_frame
	print("Chapter3 scene readability: %d checks, %d failures" % [checks,errors]); quit(0 if errors==0 else 1)
