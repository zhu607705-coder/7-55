extends SceneTree
const Layout=preload("res://scripts/ui/compact_overlay_layout.gd")
var checks:=0
var failures:=0
var shell: Control
var state: Node
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("COMPACT OVERLAY: "+message)
func frames(count: int=3) -> void:
	for i in range(count): await process_frame
func screen_rect(node: Control) -> Rect2:
	var transform:=node.get_global_transform_with_canvas()
	return Rect2(transform.origin,node.size*transform.get_scale())
func mouse_click(node: Control) -> void:
	var point:=screen_rect(node).get_center()
	var motion:=InputEventMouseMotion.new(); motion.position=point; root.push_input(motion)
	for down: bool in [true,false]:
		var event:=InputEventMouseButton.new(); event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down; root.push_input(event)
	await frames(2)
func touch(node: Control,index: int,down: bool) -> void:
	var event:=InputEventScreenTouch.new(); event.index=index; event.position=screen_rect(node).get_center(); event.pressed=down; root.push_input(event)
func run() -> void:
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(5)
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1280,720),Vector2i(1440,900)]:
		root.size=dimensions; shell.size=Vector2(dimensions)
		state.begin_checkpoint("c3-canteen-drinks"); shell._refresh(); await frames(5)
		shell.mobile_world=true; shell._layout(); await frames(3)
		var world: Control=shell.world
		var player_before: Vector2=world.player
		var camera_before: Vector2=world.camera
		var world_size_before: Vector2=world.world_size
		var scale: float=world.hud_display_scale()
		for line: String in ["WASD 移动  /  空格 交互  /  滚轮 缩放","太远了，请靠近订单回收槽。", "这是一段完整的现场反馈，保留全部文字并根据窗口换行。".repeat(5)]:
			var hud: Dictionary=world.hud_metrics(line)
			check(hud.title_font*scale>=13.99,"world title physical14px at "+str(dimensions))
			check(hud.mode_font*scale>=11.99 and hud.body_font*scale>=11.99,"world mode/subtitle physical12px at "+str(dimensions))
			check(hud.header_height+hud.body_height+hud.body_gap*2<=540.1,"HUD bars remain contained at "+str(dimensions))
			if hud.compact:
				var needed: Vector2=world.font.get_multiline_string_size(line,HORIZONTAL_ALIGNMENT_CENTER,hud.body_width,hud.body_font)
				check(needed.y+hud.body_inset*2<=hud.body_height+0.1,"full feedback fits grown bar at "+str(dimensions))
		check(world.player==player_before and world.camera==camera_before and world.world_size==world_size_before,"HUD metrics do not mutate world geometry")
		check(Layout.font_size(21,12,scale)*scale>=11.99,"touch captions keep12px physical text without moving controls")
		var mode_rect: Rect2=world.hud_mode_rect()
		check(Rect2(Vector2.ZERO,world.size).encloses(mode_rect),"mode hitbox is inside world HUD")
		if scale<0.7 or world.mobile_exploration: check(mode_rect.size.y*scale>=28 and mode_rect.size.x*scale>=28,"compact mode hitbox exceeds28px")
		var previous_mode: String=state.d.native.mode
		var view_transform: Transform2D=shell.world_view.get_global_transform_with_canvas()
		var mode_point: Vector2=view_transform*mode_rect.get_center()
		var mode_motion:=InputEventMouseMotion.new(); mode_motion.position=mode_point; root.push_input(mode_motion)
		for down: bool in [true,false]:
			var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.position=mode_point; event.pressed=down; root.push_input(event)
		await frames(3)
		check(state.d.native.mode!=previous_mode,"real pointer toggles source mode at reflowed HUD location")
		shell._open_game({"type":"chase","title":"755 米 · 追上纸条","viewport":[960,540],"instructions":"左右转向，蓄力跳跃、铃铛清道，托盘和风力道具只在本局有效。"}); await frames(7)
		var game: Control=shell.active_game
		game.set_process(false)
		var playfield:=screen_rect(game.chase_view)
		var game_scale: float=game.get_global_transform_with_canvas().get_scale().x
		check(game.size==Vector2(dimensions) and game.scale==Vector2.ONE,"all native chase controls use physical viewport coordinates")
		check(game.native_chase_view.surface.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED and game.native_chase_view.camera.keep_aspect==Camera3D.KEEP_HEIGHT,"all orientations contain the original16:9 camera film inside the field")
		check(game.model.tick>=0 and game.model.distance==0,"opening overlay never starts simulation")
		check(is_equal_approx(game.native_chase_view.WORLD_PER_METER,1.05) and game.background==null,"original3D road scale is used without the legacy flat projection")
		if dimensions.x<700:
			check(game.overlay_layout.compact,"portrait branch enabled")
			for node: Control in [game.headline,game.status,game.hint,game.pause_button,game.retry_button,game.exit_button,game.start_button]:
				var rect:=screen_rect(node)
				check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(rect),"visible overlay contained: "+str(node.get_class())+" / "+node.text)
				var minimum:=13.0 if node==game.status else 14.0
				check(node.get_theme_font_size("font_size")*game_scale>=minimum-0.01,"physical font floor: "+node.text)
				if node is Button: check(rect.size.y>=43.99 and rect.size.x>=43.99,"minimum44px toolbar/start targets")
			for toolbar: Button in [game.pause_button,game.retry_button,game.exit_button]:
				check(screen_rect(toolbar).end.y<=screen_rect(game.status).position.y+0.01,"toolbar never overlaps status text")
			check(not playfield.intersects(screen_rect(game.status)) and not playfield.intersects(screen_rect(game.pause_button)),"top UI stays in portrait letterbox")
			await mouse_click(game.start_button)
			check(game.running and not game.start_button.visible,"actual start pointer activates")
			for button: Button in game.control_buttons.values():
				var rect:=screen_rect(button)
				check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(rect),"running control contained: "+button.text)
				check(rect.size.x>=43.99 and rect.size.y>=55.99,"minimum56px running touch target: "+button.text)
				check(not rect.intersects(playfield),"running controls never cover chase playfield")
			var before_lane: float=game.model.lane
			touch(game.control_buttons.left,4,true)
			check(game.model.held.has("left"),"real touch press uses existing left action")
			game._process(0.1)
			touch(game.control_buttons.left,4,false)
			check(not game.model.held.has("left") and game.model.lane<before_lane,"touch release retains source steering proof")
			touch(game.control_buttons.jump,5,true); game._process(0.1); touch(game.control_buttons.jump,5,false)
			check(game.model.air_velocity>0 and not game.model.held.has("jump"),"actual touch hold/release preserves charged jump")
			await mouse_click(game.pause_button)
			check(game.paused and game.start_button.visible,"letterbox pause accepts real pointer")
			var tick_before: int=game.model.tick; game._process(1.0)
			check(game.model.tick==tick_before,"paused reflow never advances simulation")
			await mouse_click(game.start_button)
			check(game.running and not game.paused,"actual resume preserves same run")
			await mouse_click(game.retry_button)
			check(not game.running and game.model.tick==0 and game.model.distance==0,"letterbox retry uses existing reset")
			var compact_jump: Rect2=screen_rect(game.control_buttons.jump)
			game.begin(); touch(game.control_buttons.right,7,true); game._process(0.1)
			var before_resize: Array=game.model.inputs.duplicate(true)
			root.size=Vector2i(1280,720); shell.size=Vector2(1280,720); shell._layout(); game._refresh(); await frames(3)
			check(not game.activity_compact and game.headline.get_theme_font_size("font_size")==24,"active portrait-to-desktop resize restores readable desktop typography")
			check(Rect2(Vector2.ZERO,Vector2(1280,720)).encloses(screen_rect(game.control_buttons.jump)) and not screen_rect(game.control_buttons.jump).intersects(screen_rect(game.chase_view)),"desktop jump target stays reachable outside the source field")
			root.size=dimensions; shell.size=Vector2(dimensions); shell._layout(); game._refresh(); await frames(3)
			check(game.overlay_layout.compact and screen_rect(game.control_buttons.jump).is_equal_approx(compact_jump),"active resize returns to exact compact targets")
			check(game.model.inputs.size()==before_resize.size()+1 and game.model.inputs[-1].type=="neutral" and game.model.held.is_empty(),"responsive resize cancels held controls through recorded source neutral")
			touch(game.control_buttons.right,7,false)
			check(not game.model.held.has("right") and game.model.inputs.size()==before_resize.size()+1,"stale touch cannot release a jump or add input after resize")
			print("COMPACT overlay ",dimensions,": body=",game.hint.get_theme_font_size("font_size")*game_scale,"px; control=",screen_rect(game.control_buttons.jump).size)
		else:
			check(not game.activity_compact and game.activity_layout_configured,"desktop uses the native activity layout")
			check(game.headline.get_theme_font_size("font_size")==24 and not screen_rect(game.headline).intersects(playfield),"desktop heading remains readable outside the source film")
			check(screen_rect(game.control_buttons.jump).size.y>=44 and not screen_rect(game.control_buttons.jump).intersects(playfield),"desktop jump control remains reachable without covering hazards")
		game.cancel_game(); await frames(3)
	await shell.shutdown(); shell.queue_free(); await frames(3)
	print("Compact overlay: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
