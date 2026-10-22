extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var scene=load("res://scenes/kenney_visual_slice.tscn").instantiate()
	root.add_child(scene);await process_frame
	scene.set_physics_process(false)
	root.size=Vector2i(390,844);scene.layout();await process_frame
	check(scene.screen.size.x<=390 and scene.screen.size.y<=844,"compact scene fits window")
	check(scene.screen.size.y>500,"portrait world is not a tiny landscape strip")
	check(scene.mouse_filter==Control.MOUSE_FILTER_IGNORE,"root passes world clicks")
	for button in [scene.comparison,scene.pixel_button,scene.reset_button,scene.action]:
		check(button.focus_mode==Control.FOCUS_NONE,"toolbar cannot steal Space")
	root.size=Vector2i(1280,900);scene.layout();await process_frame
	var state_before: String=JSON.stringify(root.get_node("State").d)
	check(scene.room.get_node("Furnishings").get_child_count()==18,"18 objects retained")
	check(scene.view.size==Vector2i(960,540),"baseline resolution unchanged")
	check(scene.sprite.texture.resource_path.ends_with("player_down_0.png"),"source actor retained")
	scene.actor.position=Vector2(531,900);scene.refresh_focus()
	check(scene.focus_id=="paper","paper reachable")
	var space=InputEventKey.new();space.keycode=KEY_SPACE;space.pressed=true
	Input.parse_input_event(space);await process_frame
	check(scene.note_open and scene.observed,"routed Space opens paper")
	check(not scene.tutorial.visible and not scene.selected_overlay.object_hint.visible,"first real interaction dismisses onboarding")
	var click=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	click.position=scene.world_to_screen(Vector2(531,1100))
	Input.parse_input_event(click);await process_frame
	check(not scene.note_open and scene.pointer_walk,"floor navigation dismisses open note")
	scene.pointer_walk=false;scene.interact()
	scene.interact();check(not scene.note_open,"repeat main action closes paper")
	for i in range(5):scene.interact();scene.interact()
	check(not scene.note_open,"repeated paper cycles stable")
	scene.actor.position=scene.get_object("lamp").stand;scene.refresh_focus()
	check(scene.focus_id=="lamp","lamp reachable")
	scene.interact();check(scene.lamp_on,"lamp on")
	scene.interact();check(not scene.lamp_on,"lamp off")
	scene.reduced_motion=true;scene.interact();check(not scene.tween.is_running(),"reduced motion has no running pulse")
	scene.toggle_feedback();check(not scene.marker.active,"baseline comparison hides marker")
	scene.toggle_feedback();check(scene.marker.active,"candidate feedback restored")
	var old_zoom:float=scene.camera.zoom.x
	scene.toggle_pixels();check(scene.view.size.y==480,"optional 480 render")
	check(is_equal_approx(scene.camera.zoom.x/old_zoom,480.0/540),"field of view preserved")
	check(not scene.view.is_ancestor_of(scene.note),"UI outside low resolution viewport")
	for point in [Vector2(.123,9.8),Vector2(-1.2,25.8),Vector2(431.1,932.7)]:
		var snap:Vector2=scene.snapped_camera(point,scene.camera.zoom.x)*scene.camera.zoom.x
		check(snap.is_equal_approx(snap.round()),"camera aligns to render pixels")
	scene.toggle_pixels();check(scene.view.size==Vector2i(960,540),"baseline resolution restored")
	scene.keyboard=Vector2.ONE;scene.pointer_walk=true;scene._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(scene.keyboard==Vector2.ZERO and not scene.pointer_walk,"focus loss clears motion")
	scene.actor.position=Vector2(531,1000);scene.keyboard=Vector2(0,-1)
	var before:Vector2=scene.actor.position
	for i in range(30):scene._physics_process(1.0/60);await physics_frame
	check(scene.actor.position.y<before.y-30,"actual physics movement in aisle")
	scene.keyboard=Vector2.ZERO
	for target in [Vector2(531,700),Vector2(650,700),scene.get_object("lamp").stand]:
		scene.pointer_target=target;scene.pointer_walk=true
		for i in range(120):scene._physics_process(1.0/60);await physics_frame
	check(scene.focus_id=="lamp","lamp reached through actual furniture collisions")
	scene.toggle_journal();check(scene.journal.get_script().resource_path.ends_with("native_journal_view.gd"),"real locked journal component")
	check(not scene.action.visible and not scene.tutorial.visible,"journal hides unrelated world actions")
	check(scene.selected_overlay.get_script().resource_path.ends_with("world_selected_overlay.gd"),"real HUD2 and interaction1 component")
	check(scene.selected_overlay.object_heading.get_theme_font_size("font_size")==18,"locked interaction heading role")
	scene.close_journal()
	scene.reset_trial();check(scene.actor.position==Vector2(531,1000) and not scene.observed and not scene.lamp_on,"reset clears only trial")
	check(state_before==(JSON.stringify(root.get_node("State").d)),"no story state mutation")
	scene.queue_free();await process_frame
	print("KENNEY_SLICE_CHECKS ",checks," FAILURES ",failures);quit(1 if failures else 0)
