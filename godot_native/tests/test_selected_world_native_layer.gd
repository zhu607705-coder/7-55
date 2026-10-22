extends "res://tests/test_native_surface_modes.gd"
func run()->void:
 state=root.get_node("State")
 for dimensions:Vector2i in [Vector2i(1440,900),Vector2i(390,844),Vector2i(667,375),Vector2i(568,320)]:
  await create_shell(dimensions,"library_interior")
  var world:Control=shell.world
  world.transition_alpha=0;world.subtitle="";shell._layout();await frames()
  var region:Rect2=shell.world_view.get_global_rect()
  check(world.selected_overlay.get_parent()==shell,"Main installs native overlay without test-side reparent")
  await frames()
  var overlay:Control=world.selected_overlay
  check(overlay.get_viewport()==root and overlay.get_parent()==shell,"selected text renders in native root viewport, never world texture")
  check(overlay.scale==Vector2.ONE,"no inverse scale or downstream world resampling")
  check(overlay.size.is_equal_approx(region.size),"native overlay uses actual displayed world size")
  var first_line_bottom:float=overlay.objective.get_global_rect().position.y+overlay.objective.get_theme_font("font").get_height(13)
  check(first_line_bottom<=overlay.task_scroll.get_global_rect().end.y+.01,"actual short-world viewport leaves the first objective line visible")
  check(overlay.objective.get_theme_font_size("font_size")==13 and overlay.object_heading.get_theme_font_size("font_size")==18,"locked native font sizes preserved")
  var world_rect_before:Rect2=shell.world_view.get_global_rect()
  var camera_before:Vector2=world.camera
  var viewport_before:Vector2i=shell.world_viewport.size
  world.subtitle="保留这条反馈";world.subtitle_left=4
  shell._show_journal();await frames();world._sync_selected_overlay()
  check(not overlay.visible and not world.overflow_feedback.visible,"journal hides exploration labels over transparent reading surface")
  check(shell.world_view.get_global_rect().is_equal_approx(world_rect_before) and shell.world_viewport.size==viewport_before and world.camera.is_equal_approx(camera_before),"journal leaves world viewport and camera unchanged")
  for control:Control in [shell.mobile_back,shell.world_tasks,shell.inventory_handle,shell.inventory_dock]:
   check(is_zero_approx(control.modulate.a),"journal hides external exploration chrome without changing its layout")
  world._process(.05)
  check(world.subtitle=="保留这条反馈" and is_equal_approx(world.subtitle_left,4),"hidden feedback does not expire behind journal")
  shell._close_modal();await frames();world._sync_selected_overlay()
  check(overlay.visible,"closing journal restores native HUD")
  check(shell.world_view.get_global_rect().is_equal_approx(world_rect_before) and shell.world_viewport.size==viewport_before and world.camera.is_equal_approx(camera_before),"journal close preserves original framing")
  for control:Control in [shell.mobile_back,shell.world_tasks,shell.inventory_handle,shell.inventory_dock]:
   check(is_equal_approx(control.modulate.a,1),"closing journal restores external chrome opacity")
  shell._show_phone_surface();await frames();world._sync_selected_overlay()
  check(not overlay.visible,"native HUD never remains over phone")
 await close_shell()
 print("SELECTED_WORLD_NATIVE_LAYER: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
