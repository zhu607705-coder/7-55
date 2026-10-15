extends SceneTree
## Actual non-headless native-render fixtures. Not manual gameplay or hardware VRAM.
const V4=preload("res://campuses/buct_changping/scripts/registered_hd_north_large.gd")
const BASE=preload("res://campuses/buct_changping/scripts/registered_hd_region.gd")
const PROFILE="res://campuses/buct_changping/data/north_large_hd_region.json"
var checks:=0
var failures:Array[String]=[]
var records:Array=[]
var out:=""
var viewport:SubViewport
var campus:Node2D
var preview:Sprite2D
var owner_mask:PackedByteArray
var _external_output_ready:=false
var _gpu_render_run:=false
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func frame()->void:
 await process_frame;await process_frame
 await RenderingServer.frame_post_draw
func compare(a:Image,b:Image,mode:String="all")->Dictionary:
 var aa:=a.get_data();var bb:=b.get_data();var changed:=0;var maximum:=0;var tested:=0
 var expected_counts:={"all":1572864,"terrain_core":1256064,"original_bodies":84096}
 if not expected_counts.has(mode) or a.get_size()!=Vector2i(1536,1024) or b.get_size()!=a.get_size() or aa.size()!=1536*1024*4 or bb.size()!=aa.size():
  check(false,"Comparison uses a complete native RGBA8 ROI and a known mode: "+mode)
  return {"changed_pixels":-1,"max_delta":255,"tested_pixels":0}
 var width:=a.get_width();var channels:=4
 for y in range(a.get_height()):
  for x in range(width):
   if mode!="all":
    var sx:=floori(x/4.0);var sy:=floori(y/4.0)
    if mode=="terrain_core" and (sx<12 or sx>=372 or sy<12 or sy>=244 or owner_mask[sy*384+sx]!=0):continue
    if mode=="original_bodies" and owner_mask[sy*384+sx]==0:continue
   tested+=1
   var offset:=(y*width+x)*channels;var delta:=0
   for c in range(channels):delta=maxi(delta,absi(int(aa[offset+c])-int(bb[offset+c])))
   if delta>0:changed+=1;maximum=maxi(maximum,delta)
 check(tested==expected_counts[mode],"Exact nonempty native comparison sample count: "+mode)
 return {"changed_pixels":changed,"max_delta":maximum,"tested_pixels":tested}
func image(label:String)->Image:
 var im:=viewport.get_texture().get_image();im.convert(Image.FORMAT_RGBA8)
 _gpu_render_run=true
 check(im.save_png(out.path_join(label+".png"))==OK,"Save actual engine frame: "+label)
 return im
func run()->void:
 out=OS.get_environment("BUCT_NORTH_LARGE_QA_DIR")
 if out.is_empty() or not out.is_absolute_path() or out.begins_with("user://") or out.begins_with("res://"):
  check(false,"BUCT_NORTH_LARGE_QA_DIR must be an explicit absolute external directory")
  finish();return
 if DirAccess.make_dir_recursive_absolute(out)!=OK:
  check(false,"External GPU QA output directory is writable")
  finish();return
 _external_output_ready=true
 check(DisplayServer.get_name()!="headless","Proof uses actual desktop display server")
 if DisplayServer.get_name()=="headless":finish();return
 owner_mask=FileAccess.get_file_as_bytes("res://campuses/buct_changping/data/north_large_body_ownership.r8.bin")
 check(owner_mask.size()==384*256,"Native pixel selections use the complete source-sized ownership mask")
 if owner_mask.size()!=384*256:finish();return
 viewport=SubViewport.new();viewport.size=Vector2i(1536,1024);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var scene:PackedScene=load("res://campuses/buct_changping/scenes/playable.tscn")
 campus=scene.instantiate();campus.enable_north_large_hd_region=false;viewport.add_child(campus);await frame()
 check(campus.initialized,"Exact restored production campus initializes")
 if not campus.initialized:finish();return
 campus.set_process(false);campus.visitor.set_physics_process(false);campus.ui.hide();campus.route_visual.hide();campus.canopy_locator.hide()
 campus.pin_layer.hide();campus.visitor.hide()
 var layout_callback:=Callable(campus,"_layout_ui")
 if viewport.size_changed.is_connected(layout_callback):viewport.size_changed.disconnect(layout_callback)
 campus.camera.position_smoothing_enabled=false;campus.camera.limit_left=-100000;campus.camera.limit_top=-100000;campus.camera.limit_right=100000;campus.camera.limit_bottom=100000
 campus.camera.zoom=Vector2.ONE*4;campus.camera.position=Vector2(542,295);campus.camera.reset_smoothing()
 preview=Sprite2D.new();preview.centered=false;preview.texture=viewport.get_texture();preview.scale=Vector2.ONE*.70;preview.position=Vector2(102,0);root.add_child(preview)
 await frame()
 check((viewport.get_canvas_transform()*Vector2(350,167)).distance_to(Vector2.ZERO)<0.01,"Native ROI camera maps exact source origin to pixel zero")
 var predecessor:=image("north-large-old-source-engine")
 var upper=V4.install_region(campus,PROFILE)
 check(is_instance_valid(upper),"Candidate v4 installs all real registered textures")
 if not is_instance_valid(upper):finish();return
 await frame();var normal:=image("north-large-candidate-engine")
 var bodies:=compare(predecessor,normal,"original_bodies");records.append({"fixture":"unaccepted_original_bodies_remain_exact","comparison":bodies});check(bodies.changed_pixels==0,"All 5256 fallback source cells retain exact original engine pixels")
 check(upper.get_diagnostics().new_gpu_texture_bytes==9689195,"Real imported resources use complete charged 9689195-byte layer budget")
 # A synthetic opaque backing catches accidental discards as well as old-source
 # sampler use. It is fixture-only and directly below this owner's ground.
 var sentinel_image:=Image.create(1,1,false,Image.FORMAT_RGBA8);sentinel_image.fill(Color(1,0,1,1))
 var sentinel:=Sprite2D.new();sentinel.name="ProofOnlyMagentaBacking";sentinel.centered=false
 sentinel.texture=ImageTexture.create_from_image(sentinel_image);sentinel.position=Vector2(350,167)-upper.position;sentinel.scale=Vector2(384,256)
 upper.add_child(sentinel);upper.move_child(sentinel,0)
 upper.ground_sprite.hide();await frame()
 var control:=viewport.get_texture().get_image();control.convert(Image.FORMAT_RGBA8)
 var sentinel_control:=compare(normal,control,"terrain_core")
 records.append({"fixture":"magenta_backing_control","comparison":sentinel_control})
 check(sentinel_control.changed_pixels>0,"Synthetic backing is observable when the new ground is absent")
 upper.ground_sprite.show()
 var poison:=Image.create(950,1656,false,Image.FORMAT_RGBA8);poison.fill(Color(1,0,1,1));var poison_texture:=ImageTexture.create_from_image(poison)
 upper.ground_sprite.material.set_shader_parameter("original_source",poison_texture);await frame();var poisoned:=image("north-large-source-poison-engine")
 var core:=compare(normal,poisoned,"terrain_core");records.append({"fixture":"entire_owner_zero_core_source_poison","comparison":core});check(core.changed_pixels==0,"All 78504 terrain-core cells are independent of old RGB")
 var outer:=compare(normal,poisoned);check(outer.changed_pixels>0,"Source-poison control changes the intentional exterior transition")
 upper.ground_sprite.material.set_shader_parameter("original_source",campus.SOURCE);sentinel.queue_free();await frame()
 upper.hide();await frame();var hidden:=image("north-large-hidden-restore-engine");var hidden_delta:=compare(predecessor,hidden);records.append({"fixture":"hidden_upper_restores_exact_lower_render","comparison":hidden_delta});check(hidden_delta.changed_pixels==0,"Upper hide restores exact predecessor and both lower guards")
 upper.show();await frame();upper.uninstall();upper=null;await frame();var unloaded:=viewport.get_texture().get_image();unloaded.convert(Image.FORMAT_RGBA8);var unload_delta:=compare(predecessor,unloaded);records.append({"fixture":"uninstall_restores_exact_predecessor","comparison":unload_delta});check(unload_delta.changed_pixels==0,"Upper uninstall restores exact predecessor render")
 campus.set_west_hd_resident(false);campus.north_hd_region.uninstall();campus.north_hd_region=null;await frame()
 upper=V4.install_region(campus,PROFILE);check(is_instance_valid(upper),"Upper can prepare before lower visual owners")
 if not is_instance_valid(upper):finish();return
 campus.north_hd_region=BASE.install(campus,"res://campuses/buct_changping/data/north_hd_region.json");check(campus.set_west_hd_resident(true),"Old accepted atomic pair reinstalls after upper")
 await frame();await frame();var reversed:=image("north-large-reverse-order-engine");var order_delta:=compare(normal,reversed);records.append({"fixture":"reverse_installation_order","comparison":order_delta});check(order_delta.changed_pixels==0,"All native band pixels are insertion-order independent")
 # Last preview is a fresh, unmodified production entry, not the opt-in fixture.
 campus.queue_free();await frame();campus=scene.instantiate();viewport.add_child(campus);await frame()
 check(is_instance_valid(campus.north_large_hd_region) and campus.north_large_hd_region.get_diagnostics().active,"Fresh production entry installs northern HD by default")
 campus.set_process(false);campus.visitor.set_physics_process(false);campus.visitor.hide();campus.ui.hide();campus.pin_layer.hide();campus.route_visual.hide();campus.canopy_locator.hide()
 layout_callback=Callable(campus,"_layout_ui")
 if viewport.size_changed.is_connected(layout_callback):viewport.size_changed.disconnect(layout_callback)
 campus.camera.position_smoothing_enabled=false;campus.camera.limit_left=-100000;campus.camera.limit_top=-100000;campus.camera.limit_right=100000;campus.camera.limit_bottom=100000
 campus.camera.zoom=Vector2.ONE*4;campus.camera.position=Vector2(542,295);campus.camera.reset_smoothing();await frame()
 var default_frame:=image("north-large-default-engine")
 var default_delta:=compare(normal,default_frame);records.append({"fixture":"fresh_default_matches_accepted_candidate","comparison":default_delta});check(default_delta.changed_pixels==0,"Actual default northern band matches the accepted candidate exactly")
 viewport.size=Vector2i(950,1656);campus.camera.zoom=Vector2.ONE;campus.camera.position=Vector2(475,828);campus.camera.reset_smoothing();preview.scale=Vector2.ONE*.43;preview.position=Vector2(435,0)
 await frame()
 check((viewport.get_canvas_transform()*Vector2.ZERO).distance_to(Vector2.ZERO)<0.01,"Full-campus native capture maps original source origin to pixel zero")
 image("changping-five-regions-full-engine")
 records.append({"scope":"One new northern terrain candidate; buildings remain original; other two campuses unchanged","logical_core_pixels":83520,"source_body_fallback_core_pixels":5016,"hd_terrain_core_pixels":78504,"conditional_changping_hd_terrain_core_percent":16.852784134248665,"real_display_server":DisplayServer.get_name(),"video_adapter":RenderingServer.get_video_adapter_name(),"video_api":RenderingServer.get_video_adapter_api_version(),"manual_gameplay":false,"new_physics":0})
 finish()
func finish()->void:
 var result:={"checks":checks,"failures":failures,"records":records,"status":"passed" if failures.is_empty() else "failed","gpu_render_run":_gpu_render_run,"manual_gameplay":false}
 if _external_output_ready:
  var file:=FileAccess.open(out.path_join("north-large-gpu-result.json"),FileAccess.WRITE)
  if file!=null:file.store_string(JSON.stringify(result,"  "));file.close()
 print("BUCT_NORTH_LARGE_GPU "+JSON.stringify(result))
 if is_instance_valid(campus):campus.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
