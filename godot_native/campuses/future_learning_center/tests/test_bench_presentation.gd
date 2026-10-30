extends "res://campuses/future_learning_center/tests/test_object_input.gd"
## Actual rendered gestures and interruptions. Presentation cannot earn proof.
const CameraPlane=preload("res://campuses/future_learning_center/scripts/bench_projection.gd")
func run()->void:
 if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
 root.title="7:55 · 物件投影与动作"
 RenderingServer.set_default_clear_color(Color("101820"))
 host=SubViewportContainer.new();host.size=Vector2(960,540);root.add_child(host)
 viewport=SubViewport.new();viewport.size=Vector2i(960,540);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;host.add_child(viewport)
 world=load("res://campuses/future_learning_center/scripts/floor_view.gd").new();viewport.add_child(world)
 root.size_changed.connect(fit);fit();root.grab_focus();await process_frame;await process_frame
 touch=OS.get_environment("FLC_TOUCH")=="1"
 var ray:=CameraPlane.project(Vector3(100,100,100))
 check(ray.is_equal_approx(Vector2(100,0)),"equal depth and height cancel under 45-degree orthographic camera")
 for height:float in [0,17,83]:
  var screen:=Vector2(421,218)
  check(CameraPlane.project(CameraPlane.floor_point(screen,height)).is_equal_approx(screen),"projection and manipulation inverse preserve world height")
 var renderer:Node=world.motion_lab.miniature
 var actual_camera:Camera3D=renderer.camera
 check(actual_camera.projection==Camera3D.PROJECTION_ORTHOGONAL and absf(actual_camera.global_rotation_degrees.x+45)<.01,"all miniature meshes share the actual 45 degree orthographic camera")
 for at:Vector2 in [Vector2(192,215),Vector2(832,323),Vector2(350,205)]:
  var projected:Vector2=actual_camera.unproject_position(renderer.visible_p(at,52))/Vector2(renderer.viewport.size)*Vector2(960,540)
  check(projected.distance_to(at)<.1,"physical mesh and pointer anchor project to the same logical coordinate")
 var cell:Vector2=world.motion_lab.CELL
 check(is_equal_approx(cell.y/cell.x,sin(PI/4)),"square ground modules share one 45-degree depth ratio")
 var p0:=CameraPlane.panel(Vector2(100,100),80,40,0,20)
 var p1:=CameraPlane.panel(Vector2(100,100),80,40,PI/3,20)
 check(p0[0]==p1[0] and p0[1]==p1[1] and is_equal_approx(p1[2].x-p1[3].x,80),"panel rotates around a fixed physical hinge without sideways skew or size drift")
 await solar_motion();await robot_motion();await mechanical_motion();await signal_motion()
 var failed:Array=results.filter(func(r:Dictionary)->bool:return not r.passed)
 var folder:=OS.get_environment("FLC_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(folder)
 var file:=FileAccess.open(folder.path_join("presentation.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":assertions,"failures":failed.size(),"results":results,"keyboardEvents":0,"touch":touch,"viewport":[root.size.x,root.size.y],"movieFixedStep":OS.get_environment("FLC_RECORDING")=="1"},"  "));file.close()
 print("FLC_BENCH_PRESENTATION: %d checks, %d failures, keyboard events 0"%[assertions,failed.size()]);quit(1 if failed.size() else 0)

func solar_motion()->void:
 await enter("solar");var lab:Control=world.motion_lab
 await create_timer(.32).timeout;await capture("solar_hinge_before")
 var before:Image=viewport.get_texture().get_image().get_region(Rect2i(125,125,150,105))
 var grip:Vector2=lab.panel_grip()
 await point(grip,"down")
 for i:int in 12:await point(grip+Vector2(0,-23*(i+1)/12.0),"move")
 check(lab.solar.setup.tilt==0 and lab.panel_angle>10 and lab.panel_angle<31,"panel preview articulates before configuration commits")
 await capture("solar_hinge_mid")
 var during:Image=viewport.get_texture().get_image().get_region(Rect2i(125,125,150,105))
 check(before.get_data()!=during.get_data(),"real renderer changes the physical panel region during its gesture")
 await point(grip-Vector2(0,23),"up");await create_timer(.32).timeout
 check(lab.solar.setup.tilt==1 and absf(lab.panel_angle-30)<.1 and not lab.solar.complete,"hinge settles without granting a race result")
 await capture("solar_hinge_after")
 var thirty:Image=viewport.get_texture().get_image().get_region(Rect2i(125,125,150,105))
 await stroke(lab.panel_grip(),lab.panel_grip()-Vector2(0,23));await create_timer(.4).timeout
 await capture("solar_60_stable")
 var sixty:Image=viewport.get_texture().get_image().get_region(Rect2i(125,125,150,105))
 check(lab.solar.setup.tilt==2 and changed_pixels(thirty,sixty)>100,"30 and60 degrees remain visibly different through actual braces and lighting after release")
 await stroke(lab.panel_grip(),lab.panel_grip()+Vector2(0,23));await create_timer(.4).timeout
 check(lab.solar.setup.tilt==1 and changed_pixels(viewport.get_texture().get_image().get_region(Rect2i(125,125,150,105)),sixty)>100,"60 to30 reverses the same physical support and light state")
 await point(Vector2(294,387),"down");await point(Vector2(440,265),"move");await point(Vector2(440,265),"up",0,false,true)
 var returning:Vector2=lab.part_at("panel1",Vector2(294,398))
 check(returning.distance_to(Vector2(294,398))>30 and lab.solar.setup.panel==0,"cancelled component visibly returns while assembly is unchanged")
 await point(returning,"down")
 check(lab.gesture=="panel" and not lab.returns.has("panel1"),"returning part can be re-grabbed at its rendered pose")
 await point(returning,"up",0,false,true);await create_timer(.25).timeout
 lab.set_reduced_motion(true)
 await process_frame
 await capture("solar_reduced_30")
 var reduced_thirty:Image=viewport.get_texture().get_image().get_region(Rect2i(125,125,150,105))
 await stroke(lab.panel_grip(),lab.panel_grip()-Vector2(0,23));await process_frame
 check(lab.solar.setup.tilt==2 and is_equal_approx(lab.panel_angle,60) and not lab.solar.complete,"reduced motion retains tilt feedback and the same model boundary")
 await capture("solar_reduced")
 check(changed_pixels(reduced_thirty,viewport.get_texture().get_image().get_region(Rect2i(125,125,150,105)))>100,"reduced motion preserves the distinct stable30 and60 degree apparatus states")
 lab.set_reduced_motion(false)
 var base_positions:Array[Vector2]=[lab._car_at(0),lab._car_at(1)]
 await lever(lab,-42);await create_timer(.5).timeout
 check(lab.solar.cars[0].distance>0 and lab._car_at(0)==base_positions[0] and lab._car_at(1)==base_positions[1],"test belt carries real travel while both cars remain beside the distance meter")
 await lever(lab,35)
 await stroke(lab.lamp_grip(),lab.lamp_grip()+Vector2(0,36))
 check(lab.solar.sky==2,"pulling the physical sun shutter selects the unlit comparison")
 await lever(lab,-42);await create_timer(.5).timeout
 check(lab.solar.cars[0].distance==0 and lab.solar.cars[1].distance==0 and not lab.solar.complete,"closed shutter visibly tests both cars without producing solar motion")
 await capture("solar_shutter_closed")
 await click(Vector2(876,27))
 check(lab.miniature.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"hidden miniature stops its renderer")
 check(lab.cues.is_empty() and lab.returns.is_empty(),"closing apparatus clears pending presentation")

func robot_motion()->void:
 await enter("robotics");var lab:Control=world.motion_lab
 var tile:=Vector2i(2,1);var center:Vector2=lab._tile_at(tile)
 var from:Vector2=lab.rotation_grip(tile,0)
 await point(from,"down")
 var endpoint:Vector2=center+CameraPlane.offset(cos(PI/4+.6)*44,sin(PI/4+.6)*44)
 for i:int in 14:await point(from.lerp(endpoint,(i+1)/14.0),"move")
 check(lab.robot.tiles[tile].rotation==0 and absf(lab.rotation_angle-.6)<.03,"module rotates continuously in the shared plane before quarter-turn commit")
 await capture("robot_rotation_mid")
 await point(endpoint,"up",0,false,true)
 check(lab.robot.tiles[tile].rotation==0 and not lab.robot.complete,"cancelled module rotation cannot alter route or proof")
 await lever(lab,-42);await wait_robot(lab,"blocked",120 if OS.get_environment("FLC_RECORDING")=="1" else 20)
 check(lab.robot.phase=="blocked" and not lab.robot.complete,"braking feedback follows actual one-way return obstruction")
 await capture("robot_brake")
 lab._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(lab.cues.is_empty() and lab.pointer_owner==-2 and not lab.robot.running,"focus interruption cancels pending motion and input ownership")
 await click(Vector2(876,27))

func mechanical_motion()->void:
 var approach:Array=world.data.workshopReference.approach;world.set_foot(Vector2(approach[0],approach[1]));await process_frame
 var desk:Dictionary=world.workshop_bench()
 await click(world.world_to_screen(world.Space.rect(desk.bounds).get_center()))
 var lab:Control=world.workbench
 await point(Vector2(238,387),"down")
 for i:int in 16:await point(Vector2(238,387).lerp(lab.AXLE,(i+1)/16.0),"move")
 await capture("gear_held")
 check(lab.model.gear<0 and lab.gesture=="gear","actual held gear stays separate until valid axle release")
 await point(lab.AXLE,"up")
 check(lab.model.gear==1 and lab.lift_at(lab.AXLE)>0,"accepted gear settles onto the actual axle")
 await capture("gear_seating");await create_timer(.3).timeout
 check(is_zero_approx(lab.lift_at(lab.AXLE)),"seating finishes without a permanent object offset")
 await stroke(Vector2(760,331),Vector2(505,205));await stroke(lab.TENSION,lab.TENSION-Vector2(0,28))
 await lever(lab,-42)
 await create_timer(.65).timeout;await capture("drive_running")
 var phase:float=lab.model.gear_phase
 await create_timer(.35).timeout
 check(lab.model.gear_phase!=phase and lab.model.travel>.12,"gear and belt motion follow actual driven travel")
 await create_timer(2.3).timeout
 check(lab.model.outcome=="passed","presentation changes preserve mechanical trial outcome")
 await click(Vector2(876,27))

func signal_motion()->void:
 world.set_foot(world.signal_sync_approach());await process_frame
 var desk:Dictionary=world.signal_sync_desk()
 await click(world.world_to_screen(world.Space.rect(desk.bounds).get_center()))
 var lab:Control=world.signal_sync
 lab.set_process(false)
 await process_frame;await RenderingServer.frame_post_draw
 var initial:Image=viewport.get_texture().get_image()
 for id:String in ["source","cache","left","right"]:lab.miniature.pool[id+"stem"].visible=false
 await process_frame;await RenderingServer.frame_post_draw
 var without_stems:Image=viewport.get_texture().get_image()
 for at:Vector2 in [Vector2(42,112),Vector2(42,252),lab.receiver_at("left"),lab.receiver_at("right")]:
  var region:=Rect2i(Vector2i(at+Vector2(83,77)),Vector2i(18,18))
  check(changed_pixels(initial.get_region(region),without_stems.get_region(region))>12,"real monitor stem contributes visible pixels between screen and base")
 for id:String in ["source","cache","left","right"]:lab.miniature.pool[id+"stem"].visible=true
 lab.set_process(true)
 await stroke(lab._port_position("split_b"),lab._port_position("right"))
 await capture("signal_plug_seated")
 await stroke(Vector2(290,397),Vector2(118,161))
 await create_timer(.23).timeout;await capture("signal_packet_inflight")
 check(lab.model.running and not lab.model.complete,"cable packet is shown only during real transmission")
 await create_timer(1.3).timeout
 check(lab.model.outcome=="one_change" and not lab.model.complete,"screen scan acknowledgement cannot replace second distinct edit")
 await stroke(Vector2(108,397),Vector2(118,161));await create_timer(1.3).timeout
 check(lab.model.complete and lab.model.displayed.left==lab.model.displayed.right,"two distinct real edits remain required despite visual effects")
 await capture("signal_settled")
 await click(Vector2(876,27))

func changed_pixels(a:Image,b:Image)->int:
 var count:=0
 for y:int in a.get_height():
  for x:int in a.get_width():
   if a.get_pixel(x,y)!=b.get_pixel(x,y):count+=1
 return count
