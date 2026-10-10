extends "res://tests/test_portrait_exploration.gd"
## Presentation-only fixture. Uses real Main/HUD; never injects story completion.
class SourceLine extends RefCounted:
	var line:="盖章完成。书包不再算022的使用者。"
	var status:="playing"
	func cancel()->void:status="cancelled"
	func snapshot()->Dictionary:return {"rawText":line,"text":line,"speaker":"系统","requiresConfirmation":false,"sequenceId":"layout_fixture"}
func configure(dimensions:Vector2i)->void:
	root.size=dimensions;shell.size=Vector2(dimensions)
	state.begin_checkpoint("c3-canteen-drinks")
	shell.mobile_world=true;shell.compact_inventory_open=false;shell._refresh();await frames(5)
	shell.world.set_process(false);shell.c3_narrative_host.set_process(false);shell.c3_scene_host.set_process(false);shell.library_story_host.set_process(false)
	shell.library_story_host.view.text_scale=1.0
func run()->void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"isolated UI test profile")
	if failures:quit(1);return
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	for dimensions:Vector2i in [Vector2i(1440,900),Vector2i(390,844),Vector2i(844,390)]:
		await configure(dimensions)
		var world:Control=shell.world
		world.player=Vector2(1380,852);world.pan_offset=Vector2.ZERO
		var original_player:Vector2=world.player
		var facts:String=JSON.stringify(state.d)
		for zoom:float in [.45,.85,1.6]:
			world.zoom=zoom;world.subtitle="";world._update_camera()
			var hud:Dictionary=world.hud_metrics(world._hud_line())
			var door:Vector2=(Vector2(1352,935)-world.camera)*zoom+world.size/2
			check(door.y<hud.body_rect.position.y,"door mat remains above feedback: %s/%s"%[dimensions,zoom])
			check(world.player==original_player and world.zoom==zoom,"safe framing does not move player or change zoom")
			check(not world.touch_controls if dimensions.x>1000 else world.mobile_exploration,"desktop stays keyboard and compact keeps touch")
			var inverse:Vector2=(door-world.size/2)/zoom+world.camera
			check(inverse.distance_to(Vector2(1352,935))<.01,"world screen inverse remains exact")
		# Reproduce the real ordering: result notice created while another
		# surface owns feedback, then the exploration layout becomes visible.
		world.subtitle="旧消息";world.subtitle_left=4
		shell.PhoneNotice.set_message(shell.toast,"获得书包非本人证明。","系统");shell.toast_time=3.25
		shell._layout_toast()
		check(not shell.toast.visible and shell.toast.text.is_empty(),"world handoff retires the old root notice")
		check(world.subtitle=="获得书包非本人证明。" and is_equal_approx(world.subtitle_left,3.25),"handoff preserves exact message and remaining lifetime")
		world.subtitle="旧消息"
		shell.PhoneNotice.set_message(shell.toast,"获得书包非本人证明。","系统");shell.toast_time=.04;shell._layout_toast()
		check(world.subtitle=="获得书包非本人证明。" and is_equal_approx(world.subtitle_left,.04),"fresh notice replaces stale world feedback without extending its final40ms")
		world.subtitle_left=3.25
		var view:Control=shell.library_story_host.view
		view.session=SourceLine.new();shell.library_story_host.current=view.session;view.tick();shell._layout();await frames(2);view.tick()
		var hud:Dictionary=world.hud_metrics(world._hud_line())
		var surface:Rect2=shell.world_view.get_global_rect()
		var feedback_rect:=Rect2(surface.position+hud.body_rect.position*world.hud_display_scale(),hud.body_rect.size*world.hud_display_scale())
		check(not feedback_rect.intersects(view.panel.get_global_rect()),"earned feedback and library dialogue never overlap")
		check(view.body.get_theme_font("font").get_multiline_string_size(view.body.text,HORIZONTAL_ALIGNMENT_LEFT,view.body.size.x,view.body.get_theme_font_size("font_size")).y<=view.body.size.y,"full library line is visible")
		view.session=null;shell.library_story_host.current=null;view.tick();shell._layout();await frames(2)
		world.subtitle="";world._update_camera()
		var plain:Dictionary=world.hud_metrics("")
		check(is_equal_approx(plain.body_rect.end.y,world.size.y-plain.body_gap),"closing story restores the regular footer")
		check(JSON.stringify(state.d)==facts,"layout and notice transfer never mutate story/save state")
		var text_scale_before:float=state.d.native.settings.text_scale
		for scale:float in [1.25,3.0]:
			state.d.native.settings.text_scale=scale
			view.text_scale=scale
			world.subtitle="系统保留全部反馈文字，可以上下滚动查看。\n第二行仍然使用用户选择的字号。\n第三行不覆盖移动按钮。\n第四行不改变地图缩放。\n第五行保留原始内容。";world.subtitle_left=60;world.queue_redraw();await frames(3)
			view.session=SourceLine.new();shell.library_story_host.current=view.session;view.tick();shell._layout();await frames(2);view.tick()
			var stacked:Dictionary=world.hud_metrics(world.subtitle)
			var shown:Rect2=shell.world_view.get_global_rect()
			var stacked_rect:=Rect2(shown.position+stacked.body_rect.position*world.hud_display_scale(),stacked.body_rect.size*world.hud_display_scale())
			check(not stacked_rect.intersects(view.panel.get_global_rect()),"enlarged Library dialogue and full feedback share a disjoint budget")
			view.session=null;shell.library_story_host.current=null;view.tick();shell._layout();world.queue_redraw();await frames(2)
			var large:Dictionary=world.hud_metrics(world.subtitle)
			var controls:Dictionary=world.mobile_control_metrics()
			check(Rect2(Vector2.ZERO,world.size).encloses(large.body_rect),"enlarged feedback stays inside viewport")
			if world.mobile_exploration:
				check(controls.stick_rect.position.y>=large.header_height and not controls.stick_rect.intersects(large.body_rect),"enlarged feedback preserves header and movement target")
			if large.body_overflow:
				check(world.overflow_feedback.visible and world.overflow_feedback.label.text==world.subtitle,"overflow retains every original character")
				var zoom_before:float=world.zoom
				var player_before:Vector2=world.player;var pan_before:Vector2=world.pan_offset
				var center:Vector2=world_screen(world.overflow_feedback.get_rect().get_center())
				touch(center,true);await frames(2);finger(center-Vector2(0,20),Vector2(0,-20));await frames(2);touch(center-Vector2(0,20),false);await frames(2)
				check(world.overflow_feedback.scroll_vertical>0 and world.zoom==zoom_before and world.player==player_before and world.pan_offset==pan_before,"touch scroll reaches long feedback without zooming map")
				for direction:int in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
					world.overflow_feedback.scroll_vertical=0 if direction==MOUSE_BUTTON_WHEEL_UP else 100000
					var wheel:=InputEventMouseButton.new();wheel.position=center;wheel.global_position=center;wheel.button_index=direction;wheel.pressed=true
					root.push_input(wheel);await frames(2)
					check(world.zoom==zoom_before,"wheel at either scroll boundary cannot leak to world zoom")
		state.d.native.settings.text_scale=text_scale_before
		world.subtitle=""

	await shell.shutdown();shell.queue_free();await frames()
	print("WORLD_OVERLAY_INTEGRATION: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
