extends "res://samples/future_learning_center/play.gd"
## Real-window, keyboard-free acceptance of the object-first interaction contract.
var results:Array[Dictionary]=[]
var assertions:=0
var touch:=false
func check(ok:bool,label:String)->void:
 assertions+=1;results.append({"name":label,"passed":ok})
 if not ok:push_error("FLC_OBJECT_INPUT: "+label)
func run()->void:
 if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
 root.title="7:55 · 物件交互验收"
 RenderingServer.set_default_clear_color(Color("101820"))
 host=SubViewportContainer.new();host.size=Vector2(960,540);host.stretch=false;root.add_child(host)
 viewport=SubViewport.new();viewport.size=Vector2i(960,540);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;host.add_child(viewport)
 world=load("res://campuses/future_learning_center/scripts/floor_view.gd").new();viewport.add_child(world)
 root.size_changed.connect(fit);fit();root.grab_focus();await process_frame;await process_frame
 touch=OS.get_environment("FLC_TOUCH")=="1"
 var only:=OS.get_environment("FLC_OBJECT_ONLY")
 if only.is_empty():await check_stick();await check_solar_objects()
 if only.is_empty() or only=="robotics":await check_robot_objects()
 if only.is_empty():await check_signal_objects();await check_mechanical_objects()
 var failures:Array=results.filter(func(r:Dictionary)->bool:return not r.passed)
 var folder:=OS.get_environment("FLC_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(folder)
 var file:=FileAccess.open(folder.path_join("object_input.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":assertions,"failures":failures.size(),"results":results,"touch":touch,"keyboardEvents":0,"viewport":[root.size.x,root.size.y],"timing":"actual realtime; pointer and finger gestures only"},"  "));file.close()
 print("FLC_OBJECT_INPUT: %d checks, %d failures, keyboard events 0"%[assertions,failures.size()]);quit(1 if failures.size() else 0)
func point(at:Vector2,phase:String,id:=0,force_touch:=false,cancelled:=false)->void:
 var screen:Vector2=host.position+at*host.scale
 if touch or force_touch:
  if phase=="move":
   var e:=InputEventScreenDrag.new();e.index=id;e.position=screen;root.push_input(e,true)
  else:
   var e:=InputEventScreenTouch.new();e.index=id;e.position=screen;e.pressed=phase=="down";e.canceled=cancelled;root.push_input(e,true)
 else:
  if phase=="move":
   var e:=InputEventMouseMotion.new();e.position=screen;e.button_mask=MOUSE_BUTTON_MASK_LEFT;root.push_input(e,true)
  else:
   var e:=InputEventMouseButton.new();e.position=screen;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=phase=="down";root.push_input(e,true)
 await process_frame
func stroke(from:Vector2,to:Vector2,cancelled:=false)->void:
 await point(from,"down")
 for i:int in 8:await point(from.lerp(to,(i+1)/8.0),"move")
 await point(to,"up",0,false,cancelled)
func click(at:Vector2)->void:await point(at,"down");await point(at,"up")
func lever(lab:Control,offset:float)->void:await stroke(lab.lever_grip(),lab.LEVER_BASE+Vector2(0,-42+offset))
func wait_robot(lab:Control,terminal:String,seconds:=20.0)->void:
 var deadline:=Time.get_ticks_msec()+int(seconds*1000)
 var focus_before:int=lab.focus_interruptions
 while lab.robot.phase!=terminal and Time.get_ticks_msec()<deadline:
  if not lab.robot.running:
   if lab.robot.phase in ["moving","loading","unloading"] and lab.focus_interruptions>focus_before:
    print("OBJECT_INPUT: OS focus interruption observed; restore window and resume with actual lever")
    focus_before=lab.focus_interruptions;root.grab_focus();await process_frame;await lever(lab,-42)
   else:break
  await process_frame
func enter(mode:String)->void:
 world.load_floor(2);world.set_foot(world.motion_approach(mode));await process_frame
 var bench:Dictionary=world.motion_desk(mode)
 await click(world.world_to_screen(world.Space.rect(bench.bounds).get_center()))
 await process_frame
func undo_crank(lab:Control)->void:await stroke(lab.CRANK+Vector2(-16,-16),lab.CRANK+Vector2(16,-16))
func no_action_strip(view:Control)->bool:
 var count:=0
 for child:Node in view.get_children():
  if child is Button:count+=1
 return count==1
func check_stick()->void:
 world.load_floor(2);world.set_foot(world.motion_approach("solar"));await process_frame
 if not touch:
  check(not is_instance_valid(world.joystick),"fine pointer has no on-screen movement controls");return
 check(is_instance_valid(world.joystick),"touch has one recognizable analog joystick")
 var start:Vector2=world.player
 var c:Vector2=world.joystick.position+world.joystick.CENTER
 await point(c,"down");await point(c+Vector2(26,0),"move");await create_timer(.24).timeout
 check(world.joystick.value.length()>.4 and world.joystick.value.length()<.6,"stick preserves analog amplitude")
 await capture("room_joystick")
 check(world.player.distance_to(start)>12 and world.space.can_stand(world.player),"stick moves real player on legal floor")
 await point(c,"up")
 check(world.touch_vector==Vector2.ZERO,"stick release stops locomotion")
 await point(c,"down",4,true);await point(c+Vector2(0,30),"move",4,true)
 await point(c,"up",5,true)
 check(world.joystick.pointer_owner==4,"other finger cannot release active stick")
 await point(c,"up",4,true,true)
 check(world.touch_vector==Vector2.ZERO,"cancelled touch releases stick")
func belt_pixels(lane:int)->Image:
 # Sample only the visible moving belt, away from cars, numerals and controls.
 return viewport.get_texture().get_image().get_region(Rect2i(320,190+lane*111,220,40))
func pixel_changes(a:Image,b:Image)->int:
 var count:=0
 for y:int in a.get_height():
  for x:int in a.get_width():
   if a.get_pixel(x,y)!=b.get_pixel(x,y):count+=1
 return count
func belt_luminance()->float:
 var total:=0.0
 for lane:int in 2:
  var pixels:=belt_pixels(lane)
  for y:int in pixels.get_height():
   for x:int in pixels.get_width():total+=pixels.get_pixel(x,y).get_luminance()
 return total/(2.0*220*40)
func check_solar_objects()->void:
 await enter("solar");var lab:Control=world.motion_lab
 check(lab.visible and lab.kind=="solar","tap physical solar bench enters experiment")
 check(no_action_strip(lab),"solar scene has exit navigation only, no action button row")
 await capture("solar_initial")
 var foot:Vector2=world.player
 await stroke(lab.panel_grip(),lab.panel_grip()+Vector2(0,-23))
 check(lab.solar.setup.tilt==1,"drag actual panel hinge changes tilt")
 await stroke(Vector2(294,387),Vector2(500,100))
 check(lab.solar.setup.panel==0,"off-car panel drop preserves current assembly")
 await create_timer(.24).timeout
 await stroke(Vector2(294,387),lab._car_at(0)-Vector2(0,35))
 check(lab.solar.setup.panel==1,"large physical panel installs only at car")
 await stroke(Vector2(181,387),lab._car_at(0)-Vector2(0,35))
 check(lab.solar.setup.panel==0,"small panel can be restored through same drop contract")
 await stroke(Vector2(506,391),lab._car_at(0)-Vector2(0,10))
 check(lab.solar.setup.gear==1,"drag actual transmission part changes gear")
 await stroke(Vector2(594,391),lab._car_at(0)-Vector2(0,10));await undo_crank(lab)
 check(lab.solar.setup.gear==1,"turning physical rewind wheel undoes assembly")
 await stroke(Vector2(594,391),lab._car_at(0)-Vector2(0,10))
 var original_lamp:Vector2=lab.lamp_grip()
 await point(original_lamp,"down");await point(original_lamp+Vector2(55,0),"move")
 check(lab.solar.sky==0 and lab.lamp_drag_offset().x>40,"lamp follows pending drag before light configuration commits")
 await capture("solar_lamp_drag")
 await point(Vector2(-20,10),"up")
 check(lab.solar.sky==0 and lab.lamp_drag_offset()==Vector2.ZERO,"cancelled lamp drag restores original pose and lighting")
 await stroke(lab.lamp_grip(),Vector2(843,119))
 check(lab.solar.sky==1,"move experiment lamp changes lighting direction")
 await stroke(lab.lamp_grip(),Vector2(772,119))
 check(lab.solar.sky==0,"lamp can return to initial light")
 await point(lab.panel_grip(),"down",3,true)
 await point(lab.lever_grip(),"down",4,true);await point(lab.lever_grip()+Vector2(0,-43),"move",4,true);await point(lab.lever_grip(),"up",4,true)
 check(not lab.solar.running,"second finger cannot operate lever during owned panel gesture")
 await point(lab.panel_grip()+Vector2(0,-23),"up",3,true,true)
 check(lab.solar.setup.tilt==1 and lab.gesture.is_empty(),"cancelled panel gesture cannot install preview")
 await click(Vector2(884,110));await click(lab.book_at+Vector2(139,-24));await click(lab.book_at+Vector2(139,-24));await click(lab.book_at+Vector2(139,-24))
 check(lab.book_open and lab.book_page==3 and not lab.solar.complete,"only voluntary page turns reveal clues without completion")
 await capture("solar_notebook")
 await stroke(lab.book_at-Vector2(100,120),lab.book_at+Vector2(-240,-100))
 check(lab.book_at.x<700,"physical notebook can move out of the apparatus")
 await click(lab.book_at-Vector2(90,110));check(not lab.book_open,"tap notebook puts reading away")
 await lever(lab,-42);await create_timer(1).timeout
 check(lab.solar.running and lab.solar.cars[0].distance>0,"pushing real lever starts same-clock race")
 await capture("solar_running_a")
 var moving_before:Array[Image]=[belt_pixels(0),belt_pixels(1)]
 var full_light:float=belt_luminance()
 await create_timer(.4).timeout;await capture("solar_running_b")
 for lane:int in 2:check(pixel_changes(moving_before[lane],belt_pixels(lane))>120,"moving seams contribute visible pixels on belt %d, independently of distance text"%lane)
 await lever(lab,0);var elapsed:float=lab.solar.elapsed();await create_timer(.3).timeout
 check(not lab.solar.running and is_equal_approx(lab.solar.elapsed(),elapsed),"neutral lever holds actual race clock")
 await lever(lab,-42)
 var deadline:=Time.get_ticks_msec()+44000
 while lab.solar.running and lab.solar.elapsed()<11 and Time.get_ticks_msec()<deadline:await process_frame
 await capture("solar_shadow")
 var weak_light:float=belt_luminance()
 check(full_light-weak_light>.04,"rendered shared light visibly dims both belts in the shadow interval")
 while lab.solar.running and Time.get_ticks_msec()<deadline:await process_frame
 check(lab.solar.complete and lab.solar.ticks==600,"full keyboard-free thirty-second race completes from real motion")
 await capture("solar_complete")
 await lever(lab,35)
 check(lab.solar.cars[0].distance==0 and lab.solar.earned and not lab.solar.complete,"pulling lever back returns vehicle and preserves earned session record")
 await stroke(lab.lamp_grip(),lab.lamp_grip()+Vector2(0,36))
 await lever(lab,-42);await create_timer(.5).timeout;await capture("solar_shutter_closed")
 check(weak_light-belt_luminance()>.02,"closed shutter is visibly darker than partial shadow on both belts")
 check(lab.solar.cars[0].distance==0 and lab.solar.cars[1].distance==0,"closing the shared shutter stops both solar-powered cars")
 await click(Vector2(876,27));check(not lab.visible and world.player==foot,"exit restores same legal feet")
func turn_to(lab:Control,point_value:Vector2i,target:int)->void:
 var limit:=0
 while lab.robot.tiles[point_value].rotation!=target and limit<4:
  var current:int=lab.robot.tiles[point_value].rotation
  var from:Vector2=lab.rotation_grip(point_value,current)
  var normalized:Vector2=(from-lab._tile_at(point_value))/Vector2(49,29)
  var to:Vector2=lab._tile_at(point_value)+normalized.rotated(PI/2)*Vector2(49,29)
  await stroke(from,to);limit+=1
func check_robot_objects()->void:
 await enter("robotics");var lab:Control=world.motion_lab
 check(lab.visible and no_action_strip(lab),"robot bench opens without action button row")
 await capture("robot_initial");await lever(lab,-42);await wait_robot(lab,"blocked")
 check(lab.robot.phase=="blocked" and lab.robot.delivered and not lab.robot.complete,"outbound cargo alone cannot complete gesture-led robot trial")
 check(lab.robot.visible_front().x>=2.5,"visible robot front remains outside blocked entrance")
 await capture("robot_blocked")
 var version:int=lab.robot.revision
 await stroke(Vector2(138,398),Vector2(928,464))
 check(lab.robot.revision==version,"off-grid drop retains original track")
 await stroke(Vector2(138,398),lab._tile_at(Vector2i(2,1)),touch)
 if touch:check(lab.robot.tiles[Vector2i(2,1)].kind=="oneway","cancelled module drop leaves track intact")
 await stroke(lab.part_at("module0",Vector2(138,398)),lab._tile_at(Vector2i(2,1)))
 check(lab.robot.tiles[Vector2i(2,1)].kind=="straight","spare module installs at actual track slot")
 await stroke(lab._tile_at(Vector2i(0,0)),lab._tile_at(Vector2i(1,0)))
 check(lab.robot.tiles[Vector2i(1,0)].kind=="corner","dragging whole module swaps real components")
 await stroke(lab._tile_at(Vector2i(1,0)),lab._tile_at(Vector2i(0,0)))
 await lever(lab,-42);await wait_robot(lab,"complete")
 if not lab.robot.complete:print("ROBOT_GESTURE_DIAG: "+str({"phase":lab.robot.phase,"running":lab.robot.running,"fault":lab.robot.fault,"cell":lab.robot.cell,"position":lab.robot.position,"tiles":lab.robot.tiles}))
 check(lab.robot.complete and lab.robot.cargo=="destination","empty robot returns through repaired shared route")
 await capture("robot_complete")
 await lever(lab,35)
 await stroke(Vector2(494,398),lab._tile_at(Vector2i(2,1)))
 await turn_to(lab,Vector2i(0,0),0);await turn_to(lab,Vector2i(4,0),1)
 check(lab.robot.tiles[Vector2i(0,0)].rotation==0 and lab.robot.tiles[Vector2i(4,0)].rotation==1,"rotation handles change modules through quarter-turn gestures")
 await stroke(lab.outlet_grip(),lab.GUIDE+Vector2(0,-32))
 check(lab.robot.outlet==3,"physical return guide selects upper exit")
 await lever(lab,-42);await wait_robot(lab,"complete")
 check(lab.robot.complete and lab.robot.tiles[Vector2i(2,1)].kind=="oneway","upper loop works through gestures without removing one-way module")
 await capture("robot_loop_complete")
 await undo_crank(lab)
 check(not lab.robot.complete and lab.robot.position==Vector2(lab.Robot.BASE),"undo invalidates old traversal proof and safely restores cargo")
 await click(Vector2(876,27))
func check_signal_objects()->void:
 world.set_foot(world.signal_sync_approach());await process_frame
 var desk:Dictionary=world.signal_sync_desk()
 await click(world.world_to_screen(world.Space.rect(desk.bounds).get_center()))
 var lab:Control=world.signal_sync
 check(lab.visible and no_action_strip(lab),"two-screen scene also removes action/numbered-port buttons")
 await capture("signal_initial")
 await stroke(lab._port_position("right"),Vector2(455,104),touch)
 if touch:check(lab.model.wires.right=="cached","cancelled unplug gesture keeps physical cable")
 else:
  check(not lab.model.wires.has("right"),"pulling input plug into empty space disconnects cable")
  await undo_crank(lab)
 await stroke(lab._port_position("split_b"),lab._port_position("right"))
 check(lab.model.wires.right=="split_b","drag cable plug to real socket reconnects right screen")
 await stroke(Vector2(290,397),Vector2(118,161));await create_timer(1.3).timeout
 check(lab.model.outcome=="one_change" and not lab.model.complete,"first physical edit requires another distinct comparison")
 await stroke(Vector2(108,397),Vector2(118,161));await create_timer(1.3).timeout
 check(lab.model.complete and lab.model.displayed.left==lab.model.displayed.right,"two distinct dragged pattern cards prove live synchronization")
 await capture("signal_complete")
 var original_socket:Vector2=lab._port_position("left")
 await point(Vector2(746,169),"down");await point(Vector2(740,235),"move")
 check(lab._port_position("left")!=original_socket and lab.model.complete,"receiver preview moves its actual socket and preserves evidence")
 await capture("signal_receiver_drag")
 await point(Vector2(1100,235),"up")
 check(not lab.swapped and lab._port_position("left")==original_socket and lab.model.complete,"cancelled receiver drag snaps back without changing identity")
 await stroke(Vector2(746,169),Vector2(746,310))
 check(lab.swapped and lab.model.complete,"moving physical monitors preserves socket identity and evidence")
 await stroke(lab._port_position("right"),Vector2(453,106))
 check(not lab.model.wires.has("right") and not lab.model.complete,"unplug uses moved visible screen position")
 await click(Vector2(876,27))
func check_mechanical_objects()->void:
 var point_value:Array=world.data.workshopReference.approach
 world.set_foot(Vector2(point_value[0],point_value[1]));await process_frame
 var desk:Dictionary=world.workshop_bench()
 await click(world.world_to_screen(world.Space.rect(desk.bounds).get_center()))
 var lab:Control=world.workbench
 check(lab.visible and no_action_strip(lab),"mechanical experiment follows same object-first scene contract")
 await stroke(Vector2(238,387),lab.AXLE)
 await stroke(Vector2(760,331),Vector2(505,205))
 await stroke(lab.TENSION,lab.TENSION+Vector2(0,-28))
 check(lab.model.gear==1 and lab.model.belt==2 and lab.model.tension==1,"gears belt and tension assembled through physical gestures")
 await lever(lab,-42);await create_timer(3.4).timeout
 check(lab.model.outcome=="passed","physical control lever completes mechanical feed trial")
 await capture("mechanical_complete")
 await click(Vector2(876,27));check(not lab.visible,"pointer-only exit works for all workbench types")
