extends SceneTree
const View=preload("res://campuses/future_learning_center/scripts/puzzles/formula_view.gd")
var failures:=0
var checks:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("FORMULA_3D: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var v=View.new();root.add_child(v);v.open();v.set_process(false)
 var render=v.miniature
 check(render.camera.projection==Camera3D.PROJECTION_ORTHOGONAL,"same fixed orthographic camera")
 check(render.viewport.own_world_3d and render.viewport.size==Vector2i(1440,810),"actual separate 3D world, not raster background")
 check(render.pool.has("lane0") and render.pool.lane0 is MeshInstance3D,"track is mesh geometry")
 var lane_arrays:Array=render.pool.lane0.mesh.surface_get_arrays(0)
 check(lane_arrays[Mesh.ARRAY_NORMAL][0].y>0.99,"track top faces actual overhead camera, not culled underside")
 check(render.pool.has("assembly_carbody") and render.pool.has("assembly_carpanelframe"),"car chassis and articulated panel are distinct meshes")
 check(v.model.get_script().resource_path.ends_with("puzzles/formula_model.gd"),"original energy-budget authority retained")
 for at:Vector2 in [v.BENCH_CAR,v.TILT_KNOB,v.GATE,v.LAMP,v.PANEL_TRAYS[1],v.GEAR_TRAYS[1]]:
  var world:Vector3=render.visible_p(at,25)
  check(render.screen(world).distance_to(at)<.001,"logical grip inverse projection")
  var actual:Vector2=render.camera.unproject_position(world)/1.5
  check(actual.distance_to(at)<.02,"real Camera3D matches original hit plane")
 v.press(v.TILT_KNOB);v.motion(v.TILT_KNOB-Vector2(0,12));render.present(v)
 check(v.panel_tilt()==15 and v.model.tilt==0,"preview changes actual panel before committing detent")
 check(render.pool.assembly_carpanelframe.basis!=Basis.IDENTITY,"panel mesh actually tilts, not text-only angle")
 v.cancel_pointer();render.present(v)
 check(v.model.tilt==0,"cancel preserves original model")
 v.press(v.PANEL_TRAYS[1]+Vector2(12,4));v.motion(Vector2(280,300));render.present(v)
 var frame:MeshInstance3D=render.pool.loose_panel1frame
 check(absf(render.screen(frame.position).x-v.held_position().x)<.01,"dragged mesh retains grip offset")
 v.cancel_pointer();render.present(v)
 v.press(v.PANEL_TRAYS[1]);v.motion(v.BENCH_CAR);v.release(v.BENCH_CAR)
 v.press(v.GEAR_TRAYS[1]);v.motion(v.BENCH_CAR);v.release(v.BENCH_CAR)
 v.press(v.TILT_KNOB);v.motion(v.TILT_KNOB-Vector2(0,24));v.release(v.TILT_KNOB-Vector2(0,24))
 v.press(v.BENCH_CAR);v.motion(v.race_point(0,0));v.release(v.race_point(0,0));v.press(v.GATE);v.release(v.GATE)
 v.model.step(11);render.present(v)
 check(render.pool.has("cloud_shutter") and render.pool.cloud_shutter.visible,"same model clock moves physical shared shutter")
 check(render.lamp.light_energy<.2,"model shadow changes real shared illumination")
 v.model.step(19);render.present(v)
 check(v.model.completed and absf(v.model.cars[0].distance-62.51707176)<.001,"3D renderer preserves exact original 30-second trial")
 check(render.pool.has("sample_paper") and render.pool.sample_paper.visible,"saved configuration has distinct physical sample base")
 var nodes:int=render.pool.size()
 for i:int in 5:render.present(v)
 check(render.pool.size()==nodes,"mesh pooling does not allocate nodes per frame")
 v.close();check(render.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"hidden bench stops GPU updates")
 v.open();check(render.viewport.render_target_update_mode==SubViewport.UPDATE_ALWAYS,"reopening reactivates shared renderer")
 v.queue_free();await process_frame
 print("FLC_FORMULA_PRESENTATION: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
