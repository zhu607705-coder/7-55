extends SceneTree
## Isolated A/B design study. Does not alter any production script or registration.
const StudyMaterial=preload("res://design_studies/button_directions/study_material.gd")
var validate_only:=OS.get_environment("UI_CAPTURE_VALIDATE")=="1"
var output:=OS.get_environment("UI_CAPTURE_DIR")
var checks:=0
var failures:=0
var records:Array=[]
func _initialize()->void:run.call_deferred()
func frames(n:int=5)->void:
 for unused in n:await process_frame
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("BUTTON_STUDY: "+message)
func row(parent:Control,vertical:bool=false)->BoxContainer:
 var box:BoxContainer=VBoxContainer.new() if vertical else HBoxContainer.new()
 box.add_theme_constant_override("separation",4 if vertical else 10)
 parent.add_child(box);return box
func skin(button:Button,direction:String,kind:String="secondary",left:bool=false)->void:
 var adapter:Node=button.get_node("TactileMaterialState")
 var old:StyleBox=adapter.material
 var fresh=StudyMaterial.new();fresh.study_direction(direction);fresh.configure(kind,adapter.unit)
 for side:int in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:fresh.set_content_margin(side,old.get_content_margin(side))
 if direction=="B2" and left:
  fresh.content_margin_left=8;fresh.content_margin_right=8
 adapter.variant=kind;adapter.material=fresh;adapter._apply()
 button.set_meta("study_direction",direction)
 button.custom_minimum_size.y=44
 button.alignment=HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_CENTER
 var focus:=StyleBoxFlat.new();focus.bg_color=Color.TRANSPARENT
 focus.border_color=Color("77766c");focus.set_border_width_all(1);focus.set_corner_radius_all(4 if direction=="A" else 1)
 focus.expand_margin_left=2;focus.expand_margin_top=2;focus.expand_margin_right=2;focus.expand_margin_bottom=2
 button.add_theme_stylebox_override("focus",focus)
func buttons(node:Node)->Array[Button]:
 var found:Array[Button]=[]
 for child in node.get_children():
  if child is Button and child.is_visible_in_tree():found.append(child)
  found.append_array(buttons(child))
 return found
func save_frame(id:String,node:Node)->void:
 await frames()
 var visible:=buttons(node)
 var targets:Array=[]
 for button:Button in visible:
  check(button.focus_mode!=Control.FOCUS_NONE,"keyboard focus retained: "+button.text)
  check(button.get_signal_connection_list("pressed").size()>0,"original callback retained: "+button.text)
  check(button.size.y>=43.9,"44px touch height: "+button.text)
  check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(button.get_global_rect()),"button contained: "+button.text)
  targets.append({"text":button.text,"rect":str(button.get_global_rect()),"focus_mode":button.focus_mode})
 if not validate_only:
  await RenderingServer.frame_post_draw
  var error:=root.get_texture().get_image().save_png(output.path_join(id+".png"))
  check(error==OK,"real PNG written: "+id)
 records.append({"id":id,"targets":targets,"validation_only":validate_only})
func entry_study(direction:String)->void:
 var entry:Control=load("res://scenes/entry.tscn").instantiate();root.add_child(entry);await frames()
 # Stop only the preview instance's automatic original sizing, not product logic.
 for connection:Dictionary in entry.card.get_signal_connection_list("minimum_size_changed"):
  entry.card.disconnect("minimum_size_changed",connection.callable)
 if entry.resized.is_connected(entry._layout):entry.resized.disconnect(entry._layout)
 entry.content.add_theme_constant_override("separation",10)
 var group:=row(entry.content,true)
 entry.content.move_child(group,entry.campus_button.get_index())
 for button:Button in [entry.campus_button,entry.haidian_button,entry.changping_button]:
  button.reparent(group);skin(button,direction,"secondary",true)
 skin(entry.story_button,direction,"primary")
 skin(entry.preview_button,direction,"ghost",true)
 if direction=="B2":
  group.add_theme_constant_override("separation",0)
  entry.story_button.custom_minimum_size=Vector2(242,48)
  entry.story_button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
  entry.content.add_theme_constant_override("separation",12)
 var panel:StyleBox=entry.card.get_theme_stylebox("panel")
 panel.content_margin_top=22;panel.content_margin_bottom=22
 await frames()
 entry.card.size=Vector2(358,entry.card.get_combined_minimum_size().y)
 entry.card.position=(Vector2(root.size)-entry.card.size)/2
 entry.story_button.grab_focus();await frames()
 var event:=InputEventKey.new();event.keycode=KEY_TAB;event.pressed=true;root.push_input(event)
 event=InputEventKey.new();event.keycode=KEY_TAB;event.pressed=false;root.push_input(event)
 await frames()
 check(root.gui_get_focus_owner()!=entry.story_button,"Tab reaches next existing entry action")
 entry.story_button.grab_focus()
 if direction=="B2":entry.story_button.release_focus()
 await save_frame(direction+"-entry",entry)
 if direction=="B2":await state_evidence(entry.campus_button,entry)
 entry.queue_free();await frames()
func pause_study(direction:String)->void:
 var state:=root.get_node("State");state.developer_mode=true;state.begin_checkpoint("c2-dorm-exit")
 var shell:Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
 shell.size=Vector2(root.size);shell.mobile_world=true;shell._layout();await frames()
 shell._show_settings();await frames()
 var content:VBoxContainer=shell.modal_panel.get_meta("dialog_content")
 var original:Array[Button]=buttons(content)
 var lookup:Dictionary={}
 for button:Button in original:lookup[button.text]=button
 var storage:=row(content);content.move_child(storage,lookup["导出存档"].get_index())
 for caption:String in ["导出存档","导入存档"]:
  var button:Button=lookup[caption];button.reparent(storage);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;skin(button,direction,"secondary",true)
 var display:=row(content);content.move_child(display,lookup["全屏 / 窗口"].get_index())
 for caption:String in ["全屏 / 窗口","保存画面截图"]:
  var button:Button=lookup[caption];button.reparent(display);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;skin(button,direction,"secondary",true)
 for button:Button in original:
  if button.get_parent()==storage or button.get_parent()==display:continue
  skin(button,direction,"primary" if button==shell.save_progress_button else "ghost",button!=shell.save_progress_button)
 skin(shell.modal.find_child("NativeModalClose",true,false),direction,"ghost")
 content.add_theme_constant_override("separation",10)
 if direction=="B2":
  content.add_theme_constant_override("separation",6)
  shell.save_progress_button.custom_minimum_size=Vector2(220,48)
  shell.save_progress_button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
  var spacer:=Control.new();spacer.custom_minimum_size.y=12;content.add_child(spacer);content.move_child(spacer,display.get_index())
 shell.modal_panel.set_meta("fixed_action_layout",false)
 await frames();shell._layout_modal();await frames()
 await save_frame(direction+"-pause",shell.modal)
 var close:Button=shell.modal.find_child("NativeModalClose",true,false)
 var point:=close.get_global_rect().get_center()
 for down:bool in [true,false]:
  var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.position=point;click.pressed=down;root.push_input(click)
 await frames();check(not is_instance_valid(shell.modal),"real original close callback works")
 await shell.shutdown();shell.queue_free();await frames()
func state_evidence(button:Button,node:Node)->void:
 var point:=button.get_global_rect().get_center()
 var motion:=InputEventMouseMotion.new();motion.position=point;root.push_input(motion)
 await create_timer(.2).timeout
 check(button.is_hovered(),"B2 pointer hover is real")
 await save_frame("B2-hover",node)
 var down:=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.position=point;down.pressed=true;root.push_input(down)
 await create_timer(.2).timeout
 check(button.is_pressed(),"B2 pointer press is real")
 await save_frame("B2-pressed",node)
 # Release outside, preserving actual callback without launching the campus.
 motion=InputEventMouseMotion.new();motion.position=Vector2(2,2);root.push_input(motion)
 var up:=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.position=Vector2(2,2);up.pressed=false;root.push_input(up)
 await create_timer(.2).timeout
 button.grab_focus();await frames()
 check(button.has_focus(),"B2 keyboard focus is real")
 await save_frame("B2-focus",node)
func run()->void:
 if DisplayServer.get_name()=="headless" and not validate_only:push_error("Real GL required");quit(2);return
 if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
 if output.is_empty():quit(2);return
 DirAccess.make_dir_recursive_absolute(output)
 root.size=Vector2i(390,844)
 if not validate_only:DisplayServer.window_set_size(root.size)
 create_timer(120).timeout.connect(func():quit(2))
 root.get_node("State").developer_mode=true
 for direction:String in ["B","B2"]:
  await entry_study(direction);await pause_study(direction)
 var file:=FileAccess.open(output.path_join("study.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures,"frames":records,"proposal_not_production":true},"\t"));file.close()
 print("BUTTON_STUDY: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
