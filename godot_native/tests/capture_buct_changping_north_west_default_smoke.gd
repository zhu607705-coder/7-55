extends SceneTree
## Minimal actual default startup and two normal engine views. Existing proof is reused.
var out:=""
var viewport:SubViewport
var campus:Node2D
func _initialize()->void:run.call_deferred()
func frame()->void:
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
func run()->void:
 out=OS.get_environment("BUCT_NORTH_WEST_QA_DIR")
 if not out.is_absolute_path() or DisplayServer.get_name()=="headless":push_error("Explicit output directory and actual desktop required");quit(1);return
 viewport=SubViewport.new();viewport.size=Vector2i(2464,1024);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 campus=load("res://campuses/buct_changping/scenes/playable.tscn").instantiate();viewport.add_child(campus);await frame()
 if not campus.initialized or not is_instance_valid(campus.north_west_upper_hd_region) or not campus.north_west_upper_hd_region.get_diagnostics().active:
  push_error("Default left northern HD entry did not initialize");quit(1);return
 campus.set_process(false);campus.visitor.set_physics_process(false);campus.visitor.hide();campus.ui.hide();campus.pin_layer.hide();campus.route_visual.hide();campus.canopy_locator.hide()
 var layout:=Callable(campus,"_layout_ui")
 if viewport.size_changed.is_connected(layout):viewport.size_changed.disconnect(layout)
 campus.camera.position_smoothing_enabled=false;campus.camera.limit_left=-100000;campus.camera.limit_top=-100000;campus.camera.limit_right=100000;campus.camera.limit_bottom=100000
 var preview:=Sprite2D.new();preview.centered=false;preview.texture=viewport.get_texture();preview.scale=Vector2.ONE*.48;preview.position=Vector2(48,0);root.add_child(preview)
 campus.camera.zoom=Vector2.ONE*4;campus.camera.position=Vector2(426,295);campus.camera.reset_smoothing();await frame()
 var im:=viewport.get_texture().get_image();im.convert(Image.FORMAT_RGBA8)
 if im.save_png(out.path_join("north-west-six-regions-default-engine.png"))!=OK:push_error("Cannot save northern default view");quit(1);return
 viewport.size=Vector2i(950,1656);campus.camera.zoom=Vector2.ONE;campus.camera.position=Vector2(475,828);campus.camera.reset_smoothing();preview.scale=Vector2.ONE*.43;preview.position=Vector2(435,0);await frame()
 im=viewport.get_texture().get_image();im.convert(Image.FORMAT_RGBA8)
 if im.save_png(out.path_join("changping-six-regions-default-full-engine.png"))!=OK:push_error("Cannot save full-campus default view");quit(1);return
 var result:={"status":"passed","default_region_active":true,"captures":[{"file":"north-west-six-regions-default-engine.png","native_size":[2464,1024]},{"file":"changping-six-regions-default-full-engine.png","native_size":[950,1656]}],"diagnostics":campus.north_west_upper_hd_region.get_diagnostics(),"display_server":DisplayServer.get_name(),"video_adapter":RenderingServer.get_video_adapter_name(),"manual_gameplay":false,"scope":"Actual default startup and two normal rendered views only; prior fifth-region 29-check GPU proof and sixth-region minimal physical smoke reused"}
 var file:=FileAccess.open(out.path_join("default-smoke-result.json"),FileAccess.WRITE)
 if file==null:push_error("Cannot save smoke result");quit(1);return
 file.store_string(JSON.stringify(result,"  "));file.close();print("BUCT_NORTH_WEST_DEFAULT_SMOKE "+JSON.stringify(result));campus.queue_free();await process_frame;quit(0)
