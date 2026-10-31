extends SceneTree
## Isolated graphical QA harness, not ordinary entry or a second game controller.
## Manual mode uses real host inputs. --sweep creates labelled geometry fixtures.
var host:Control
var label:="collab_b"
var sequence:=0
const ROOMS:=[{"key":"collab_b","floor":4},{"key":"seminar_3","floor":4}]
class CaptureKeys extends Node:
 var capture_tree:SceneTree
 func _input(event:InputEvent)->void:
  if not event is InputEventKey or not event.pressed or event.echo:return
  match event.keycode:
   KEY_F1:capture_tree.select_room(capture_tree.ROOMS[0])
   KEY_F2:capture_tree.select_room(capture_tree.ROOMS[1])
   KEY_F5:capture_tree.resize_to(Vector2i(1280,720))
   KEY_F6:capture_tree.resize_to(Vector2i(844,390))
   KEY_F7:capture_tree.resize_to(Vector2i(390,844))
   KEY_F12:capture_tree.capture()
func _initialize()->void:boot.call_deferred()
func frames(count:=3)->void:
 for i:int in count:await process_frame
func boot()->void:
 var output:=OS.get_environment("FLC_CAPTURE_DIR")
 if not output.is_empty() and DirAccess.dir_exists_absolute(output):
  for file:String in DirAccess.get_files_at(output):
   if file.ends_with(".png"):sequence+=1
 root.size=Vector2i(1280,720)
 host=load("res://scripts/games/future_learning_center/view.gd").new();root.add_child(host)
 host.configure_activity_layout(Vector2(root.size),false);host.floor_view.persistence_enabled=false
 var keys:=CaptureKeys.new();keys.capture_tree=self;root.add_child(keys)
 await frames()
 if "--sweep" in OS.get_cmdline_user_args():
  for viewport_size:Vector2i in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844)]:
   resize_to(viewport_size);await frames()
   for room:Dictionary in ROOMS:
    if not select_room(room):return
    await frames()
    var view=host.floor_view.active_puzzle;view.set_process(false)
    view.model.place(0,-1);view.model.place(1,-1)
    while view.model.quarter_turn!=0:view.model.rotate_fixture()
    view._sync_visuals(0);label=room.key+"_rest";await capture()
    for turn:int in 4:
     if room.key=="collab_b":view.model.place(0,(3+turn)%4)
     else:view.model.set_bracket(0,true)
     view.model.start("feed")
     for step:int in 30:view.model.step(.1)
     view._sync_visuals(.2);view._sync_visuals(.2);view.queue_redraw();await frames()
     label=room.key+"_contact_q%d"%turn;await capture()
     view.model.rotate_fixture()
    view.set_process(true)
  quit();return
 if not select_room(ROOMS[0]):return
 print("OPTICAL_CAPTURE_READY F1 collab / F2 assembly / F5 desktop / F6 landscape / F7 portrait / F12 capture")
func resize_to(value:Vector2i)->void:
 root.size=value;host.configure_activity_layout(Vector2(value),value.x<900)
func select_room(room:Dictionary)->bool:
 if is_instance_valid(host.floor_view.active_puzzle) and host.floor_view.active_puzzle.visible:host.floor_view.active_puzzle.close()
 var floor_view=host.floor_view
 if not floor_view.load_floor(room.floor):push_error("Capture floor failed");quit(1);return false
 var item:Dictionary=floor_view.puzzle_anchor(room.key)
 if item.is_empty():push_error("Capture anchor missing");quit(1);return false
 var box:Rect2=floor_view.Space.rect(item.footprint)
 var placed:=false
 # A geometry fixture, not a full-floor pathfinding/ordinary-entry acceptance.
 for offset:Vector2 in [Vector2(0,65),Vector2(-65,0),Vector2(65,0),Vector2(0,-65)]:
  var point:=box.get_center()+offset+Vector2(signf(offset.x)*box.size.x/2,signf(offset.y)*box.size.y/2)
  if floor_view.set_foot(point):placed=true;break
 if not placed or not floor_view.open_puzzle(room.key):push_error("Capture apparatus failed to open");quit(1);return false
 var expected:String="collab" if room.key=="collab_b" else "assembly"
 var active=floor_view.active_puzzle
 if not active.get_script().resource_path.ends_with(expected+"_view.gd") or not active.model.get_script().resource_path.ends_with(expected+"_model.gd"):
  push_error("Capture view/model identity mismatch");quit(1);return false
 label=room.key
 print("OPTICAL_OPEN ",room.key," visible=",active.visible," view=",active.get_script().resource_path," model=",active.model.get_script().resource_path)
 return true

func capture()->void:
 if not is_instance_valid(host.floor_view.active_puzzle) or not host.floor_view.active_puzzle.visible:
  push_error("OPTICAL_CAPTURE_REFUSED: no open apparatus");return
 await RenderingServer.frame_post_draw
 var folder:=OS.get_environment("FLC_CAPTURE_DIR")
 if folder.is_empty():folder="/workspace/shared/flc-optical-graphical-20261031"
 DirAccess.make_dir_recursive_absolute(folder)
 var filename:="%02d_%s_%dx%d.png"%[sequence,label,root.size.x,root.size.y]
 var image:=root.get_texture().get_image()
 if image==null or image.is_empty():push_error("OPTICAL_CAPTURE_EMPTY");return
 var result:=image.save_png(folder.path_join(filename));sequence+=1
 print("OPTICAL_CAPTURE "+folder.path_join(filename)+" result="+str(result))
