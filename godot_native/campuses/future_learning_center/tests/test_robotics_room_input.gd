extends "res://campuses/future_learning_center/tests/test_object_input.gd"
## Furniture must remain traversable before its attached experiment is accepted.
func run()->void:
 if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
 root.title="7:55 · 机器人装配室验收"
 RenderingServer.set_default_clear_color(Color("101820"))
 host=SubViewportContainer.new();host.size=Vector2(960,540);host.stretch=false;root.add_child(host)
 viewport=SubViewport.new();viewport.size=Vector2i(960,540);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;host.add_child(viewport)
 world=load("res://campuses/future_learning_center/scripts/floor_view.gd").new();viewport.add_child(world)
 root.size_changed.connect(fit);fit();root.grab_focus();await process_frame;await process_frame
 touch=OS.get_environment("FLC_TOUCH")=="1"
 world.load_floor(2);world.set_foot(world.motion_approach("robotics"));await process_frame
 await capture("robotics_room")
 var ref:Dictionary=world.data.roboticsReference
 var door:Dictionary=world.data.doors.filter(func(d:Dictionary)->bool:return d.room=="robotics")[0]
 var inside:=Vector2(door.inside[0],door.inside[1])
 var outside:=Vector2(door.outside[0],door.outside[1])
 for point:Array in world.data.roboticsFrontage.closedGlassSamples:
  check(not world.space.can_stand(Vector2(point[0],point[1])-world.Body.FOOT_CENTER_OFFSET),"closed glass frontage blocks feet")
 var loop:Array=ref.walkLoop
 for i:int in loop.size():
  var a:Vector2=Vector2(loop[i][0],loop[i][1])-world.Body.FOOT_CENTER_OFFSET
  var b:Vector2=Vector2(loop[(i+1)%loop.size()][0],loop[(i+1)%loop.size()][1])-world.Body.FOOT_CENTER_OFFSET
  check(world.space.segment_clear(a,b),"full feet fit along assembly island aisle %d"%i)
  check(not world.space.route(inside-world.Body.FOOT_CENTER_OFFSET,a).is_empty(),"door reaches assembly aisle %d"%i)
 var bench:Dictionary=world.motion_desk("robotics")
 var solid:Rect2=world.Space.rect(bench.footprint)
 var start:Vector2=Vector2(solid.get_center().x,solid.end.y+40)-world.Body.FOOT_CENTER_OFFSET
 var stopped:Vector2=world.space.move(start,Vector2(0,-220))
 check(world.space.can_stand(stopped) and stopped.y+world.Body.FOOT_CENTER_OFFSET.y>solid.end.y,"table stops complete feet at its visible base")
 check(world.space.move(stopped,Vector2(0,40)).distance_to(stopped)>35,"player can back away from table")
 check(world.framing.zoom>=.89 and world.framing.visible_rect().encloses(world.Body.visual_rect(world.player)),"closer room camera preserves full actor")
 world.set_foot(Vector2(solid.get_center().x,solid.position.y-22));await capture("robotics_behind_table")
 world.set_foot(inside);await process_frame
 await click(world.world_to_screen(world.Space.rect(bench.bounds).get_center()))
 var deadline:=Time.get_ticks_msec()+6000
 while not world.motion_lab.visible and Time.get_ticks_msec()<deadline:await process_frame
 check(world.motion_lab.visible and world.motion_lab.kind=="robotics","ordinary bench tap walks from doorway and opens robot trial")
 var at:Vector2=world.player
 if world.motion_lab.visible:await click(Vector2(876,27))
 check(not world.motion_lab.visible and world.player==at and world.space.can_stand(world.player),"exit restores same legal assembly position")
 # Circle the island through actual pointer/touch input; each leg is on screen.
 for index:int in [1,0,3,2]:
  await walk_to(Vector2(loop[index][0],loop[index][1]),"circle assembly aisle %d"%index)
 await capture("robotics_south_aisle")
 await walk_to(inside,"return to glass opening")
 await capture("robotics_glass_inside")
 await walk_to(outside,"cross glass opening into corridor")
 await capture("robotics_glass_outside")
 await walk_to(inside,"return through glass opening")
 await capture("robotics_glass_return")
 check(world.invalid_frames==0,"all movement frames retain legal floor contact")
 await check_robot_objects()
 world.set_foot(world.motion_approach("robotics"));await capture("robotics_room_return")
 var failures:Array=results.filter(func(r:Dictionary)->bool:return not r.passed)
 var folder:=OS.get_environment("FLC_CAPTURE_DIR")
 var file:=FileAccess.open(folder.path_join("robotics_room_input.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":assertions,"failures":failures.size(),"results":results,"touch":touch,"keyboardEvents":0,"viewport":[root.size.x,root.size.y],"engine":Engine.get_version_info()},"  "));file.close()
 print("FLC_ROBOTICS_ROOM: %d checks, %d failures, keyboard events 0"%[assertions,failures.size()]);quit(1 if failures.size() else 0)

func walk_to(target:Vector2,label:String)->void:
 # A close follow camera reveals the next part of the room as the player walks.
 # Tap successive visible floor positions instead of clicking beyond the canvas.
 var from:Vector2=world.player+world.Body.FOOT_CENTER_OFFSET
 var steps:=maxi(1,ceili(from.distance_to(target)/150.0))
 for step:int in steps:
  var goal:=from.lerp(target,float(step+1)/steps)
  await create_timer(.14).timeout
  var screen:Vector2=world.world_to_screen(goal)
  check(Rect2(0,38,960,466).has_point(screen),label+" next floor position is visible")
  await click(screen)
  var deadline:=Time.get_ticks_msec()+7000
  while not world.route.is_empty() and Time.get_ticks_msec()<deadline:await process_frame
 check((world.player+world.Body.FOOT_CENTER_OFFSET).distance_to(target)<8,label+" via ordinary pointer or finger")
