extends "res://tests/test_portrait_exploration.gd"
## Source/checkpoint fixtures. No earned profile, production save, or story bypass.
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	for checkpoint in ["c2-library-gate","c2-occupancy-note","c3-canteen-drinks","c3-theater-program","c4-755-hall-clock","c4-755-a2-field-records"]:
		check(state.begin_checkpoint(checkpoint),"source checkpoint exists: "+checkpoint)
		shell.mobile_world=true;shell.compact_inventory_open=true;shell._refresh();await frames()
		shell.world.set_process(false)
		for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(620,900),Vector2i(844,390),Vector2i(1440,900)]:
			var save_before:String=JSON.stringify(state.d)
			var player_before:Vector2=shell.world.player
			var collision_before:String=JSON.stringify(shell.world.collisions)
			var actor_before:Rect2=shell.world.PlayerMetrics.visual_rect(player_before,shell.world.display_scale_at(player_before))
			root.size=dimensions;shell.size=Vector2(dimensions);shell._layout();await frames()
			check(JSON.stringify(state.d)==save_before,"orientation/layout does not write save or story: "+checkpoint)
			check(shell.world.player==player_before and JSON.stringify(shell.world.collisions)==collision_before,"source player and collision coordinates survive layout: "+checkpoint)
			check(shell.world.mobile_exploration==(dimensions.x<1100),"exploration uses mobile presentation only: "+checkpoint)
			var actor:Rect2=shell.world.PlayerMetrics.visual_rect(shell.world.player,shell.world.display_scale_at(shell.world.player))
			var physical_scale:float=shell.world.hud_display_scale()
			var painted:Rect2=shell.world_view.get_global_rect()
			check(shell.world.size==Vector2(960,540) and shell.world_viewport.size==Vector2i(960,540),"every exploration keeps the canonical landscape viewport: "+checkpoint)
			check(is_equal_approx(painted.size.x/painted.size.y,16.0/9.0) and Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(painted),"narrow windows letterbox the map without stretching or overflow: "+checkpoint)
			check(actor==actor_before,"layout retains source actor dimensions: "+checkpoint)
			if dimensions.x<1100:
				check(shell.world.hud_metrics("").body_font*physical_scale>=14,"body text physical floor: "+checkpoint)
				var pan_start:=world_screen(Vector2(shell.world.size.x*.5,100))
				touch(pan_start,true);finger(pan_start+Vector2(9999,9999),Vector2(9999,9999));touch(pan_start+Vector2(9999,9999),false);await frames()
				check(absf(shell.world.pan_offset.x)<=shell.world.size.x*.35/shell.world.zoom+0.01 and absf(shell.world.pan_offset.y)<=shell.world.size.y*.35/shell.world.zoom+0.01,"touch camera pan is bounded: "+checkpoint)
				check(state.d.native.player.world_x==player_before.x and state.d.native.player.world_y==player_before.y,"camera cannot move source actor: "+checkpoint)
				shell.world.pan_offset=Vector2.ZERO;shell.world._update_camera()
			print("SCENE_MEASURE ",checkpoint," ",dimensions," world=",shell.world.size," actor_px=",actor.size*shell.world.zoom*physical_scale)
	# A real scene owner takes the same 16:9 viewport, then releases it after
	# its existing completion capability has been consumed by the controller.
	root.size=Vector2i(390,844);shell.size=Vector2(390,844)
	state.begin_checkpoint("c3-canteen-entry");shell.mobile_world=true;shell._refresh();await frames()
	shell.world.set_process(false);shell.c3_scene_host.set_process(false)
	shell.world.player=Vector2(1053,660);shell.world._sync_player();shell.c3_scene_host.tick(0,true);shell._layout();await frames()
	check(shell.c3_scene_host.current!=null and shell.c3_scene_host.blocks_world_input(),"source canteen cinematic owns actual world")
	check(shell.world.size==Vector2(960,540) and not shell.world.mobile_exploration,"cinematic preserves authored 16:9 contract")
	var progress_before:String=JSON.stringify(state.d)
	root.size=Vector2i(844,390);shell.size=Vector2(844,390);shell._layout();await frames()
	check(shell.world.size==Vector2(960,540) and JSON.stringify(state.d)==progress_before,"orientation during cinematic neither crops nor completes it")
	for i in range(712):shell.c3_scene_host.tick(10,true)
	await frames()
	check(state.d.canteenHunt.entryPaperEscaped and shell.c3_scene_host.current==null,"only authentic scene completion advances story")
	check(shell.world.mobile_exploration and shell.world.size==Vector2(960,540),"completed cinematic restores landscape exploration")
	root.size=Vector2i(390,844);shell.size=Vector2(390,844);shell._layout();await frames()
	check(shell.world.mobile_exploration and shell.world.size==Vector2(960,540),"portrait device preserves landscape exploration")
	# The preceding cinematic uses an explicit trigger-position fixture. The
	# independent input check starts from collision-valid nearby feet.
	shell.world.player=shell.world._find_safe(shell.world.player);shell.world._sync_player();shell.world._update_camera()
	check(shell.world.can_stand(shell.world.player),"post-cinematic input fixture has collision-valid feet")
	# A pending floor tap and an active collision route have the same focus boundary.
	var control_point:=floor_touch_point(Vector2.RIGHT)
	check(control_point.is_finite(),"post-cinematic scene has visible legal empty floor")
	touch(control_point,true);await frames();check(shell.world.direct_gestures.has_active(),"real floor press owns a pending gesture")
	shell.world._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(not shell.world.direct_gestures.has_active() and shell.world._floor_route.is_empty(),"focus loss clears pending floor tap and pan")
	touch(control_point,false,true)
	await tap_floor(control_point)
	check(not shell.world._floor_route.is_empty(),"fresh floor tap after focus boundary can start a collision route")
	shell.world._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(shell.world._floor_route.is_empty(),"focus loss also retires an already issued floor route")
	# Starting/replacing a session never trusts an old presentation timer.
	state.begin_checkpoint("c3-canteen-entry");shell._refresh();await frames();shell.c3_scene_host.tick(0,true);shell._layout()
	var abandoned:RefCounted=shell.c3_scene_host.current
	state.begin_checkpoint("c2-library-gate");shell._refresh();await frames()
	check(abandoned.status=="cancelled" and shell.c3_scene_host.current==null and shell.world.mobile_exploration,"checkpoint reload retires authored contract and restores new exploration")
	# Both authored minigame aspect families restore this same camera contract.
	for viewport in [[430,860],[960,540]]:
		var before:String=JSON.stringify(state.d)
		shell._open_game({"script":"res://scripts/games/virtual_run.gd","viewport":viewport});await frames()
		check(shell.world.size==Vector2(960,540) and shell.active_game.size==Vector2(viewport[0],viewport[1]),"game keeps declared aspect and hidden canonical world")
		shell.active_game.cancelled.emit();await frames()
		check(shell.world.mobile_exploration and JSON.stringify(state.d)==before,"cancelled game restores exploration without story facts")
	# Returning to a phone application never inherits the map's landscape size.
	state.d.runtimeMode="phone";state.d.native.page="phone_home";shell.mobile_world=false;shell._refresh();await frames()
	check(shell.phone.visible and shell.phone.size==Vector2(430,860) and is_equal_approx(shell.phone.scale.x,shell.phone.scale.y),"phone apps retain their portrait viewport after landscape exploration")
	var picker:=preload("res://scripts/world_object_picker.gd").new()
	var visible:=Rect2(0,0,100,100)
	var targets:Array=[{"id":"front","item":"campusCard"},{"id":"rear","item":"gamepad"}]
	picker.add(["rear"],{"rect":Rect2(50,50,10,10)})
	picker.add(["front"],{"rect":Rect2(50,50,10,10)})
	check(picker.pick_near_visible(Vector2(40,55),targets,true,14,visible).get("id")=="front","invisible tolerance resolves painted-front identity, never item compatibility")
	check(picker.pick_near_visible(Vector2(34,55),targets,true,14,visible).is_empty(),"touch tolerance remains bounded at14 physical pixels")
	check(picker.pick_near_visible(Vector2(40,55),targets,true,14,visible,[Rect2(50,50,10,10)]).is_empty(),"tolerance cannot select an object covered by a touch control")
	targets[0].erase("item")
	check(picker.pick_near_visible(Vector2(40,55),targets,true,14,visible).is_empty(),"non-drop foreground does not expose a compatible object behind it")
	picker.clear();picker.add(["rear"],{"rect":Rect2(102,40,8,8)})
	check(picker.pick_near_visible(Vector2(98,44),targets,true,14,visible).is_empty(),"near-edge tolerance cannot reveal a fully offscreen object")
	await shell.shutdown();shell.queue_free();await frames()
	print("PORTRAIT_SCENE_CONTRACTS: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
