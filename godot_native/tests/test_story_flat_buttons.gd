extends SceneTree
## Real story owners + native input. Standalone prototypes, dropdowns, and
## physical objects keep their prior visual ownership. No formal-save writes.
const StoryMaterial=preload("res://scripts/ui/tactile_button_material.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
var checks:=0
var failures:=0
var activations:=0
func _initialize():run.call_deferred()
func frames(n:int=5):
 for i in n:await process_frame
func check(ok:bool,note:String):
 checks+=1
 if not ok:failures+=1;push_error("STORY_FLAT: "+note)
func click(button:Button):
 var point=button.get_global_transform_with_canvas()*(button.size/2)
 var motion=InputEventMouseMotion.new();motion.position=point;root.push_input(motion,true)
 for down in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event,true)
 await frames()
func flat(button:Button,note:String):
 var style:StyleBox=button.get_theme_stylebox("normal")
 check(style is StoryMaterial and style.paper_ink and style.paper_flat,note+" uses flat hand-drawn story material")
 if not style is StoryMaterial:return
 var rect:=Rect2(0,0,180,48)
 check(style._get_draw_rect(rect)==rect,note+" never draws an elevated shadow outside its face")
 check(Ui._contrast(style.label_color(),style.bg_color)>=4.5,note+" readable active caption")
func run():
 if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
 root.size=Vector2i(960,540)
 var owner:=Control.new();owner.size=Vector2(root.size);owner.set_meta("paper_ink_scope",true);owner.theme=Ui.make_theme(load("res://scripts/ui/native_typography.gd").body_font());root.add_child(owner)
 var button:=Button.new();button.text="确认";button.position=Vector2(20,20);button.size=Vector2(160,48);owner.add_child(button);button.pressed.connect(func():activations+=1);await frames()
 flat(button,"ordinary confirmation")
 var controller:Node=button.get_node("TactileMaterialState");var before:=button.get_rect();var margin:Vector2=controller.material.get_minimum_size();var top:float=controller.material.content_margin_top;var font:Font=button.get_theme_font("font")
 button.toggle_mode=true;button.button_pressed=true;controller._process(.2)
 check(button.get_rect()==before and controller.material.content_margin_top==top and controller.material.get_minimum_size()==margin,"press keeps hit target, face, and caption at the same position")
 check(button.get_theme_font("font")==font,"press keeps authored type family")
 button.button_pressed=false;button.toggle_mode=false;controller._process(.2)
 await click(button);check(activations==1,"pointer activates once")
 button.grab_focus()
 for down in [true,false]:
  var key:=InputEventKey.new();key.keycode=KEY_ENTER;key.pressed=down;root.push_input(key,true)
 await frames();check(activations==2,"keyboard activates once")
 button.disabled=true;await frames();await click(button);check(activations==2,"disabled control cannot activate")
 check(Ui._contrast(controller.material.label_color(true),controller.material.bg_color)>=4.5,"disabled caption stays readable")
 var dropdown:=OptionButton.new();dropdown.add_item("现有选项");dropdown.position=Vector2(20,90);owner.add_child(dropdown)
 var menu:=MenuButton.new();menu.text="菜单";menu.position=Vector2(20,140);owner.add_child(menu)
 var physical:=Button.new();physical.text="残签";physical.set_meta("tactile_exempt",true);Ui.apply_button(physical);var physical_style:StyleBox=physical.get_theme_stylebox("normal");owner.add_child(physical)
 var standalone:=Button.new();standalone.text="独立研究";root.add_child(standalone);await frames()
 check(dropdown.get_theme_stylebox("normal") is StoryMaterial and not dropdown.get_theme_stylebox("normal").paper_flat,"OptionButton keeps the deferred dropdown material")
 check(menu.get_theme_stylebox("normal") is StoryMaterial and not menu.get_theme_stylebox("normal").paper_flat,"MenuButton keeps the deferred menu material")
 check(physical.get_node_or_null("TactileMaterialState")==null and physical.get_theme_stylebox("normal")==physical_style,"physical paper keeps its exact original drawing")
 check(standalone.get_theme_stylebox("normal") is StoryMaterial and not standalone.get_theme_stylebox("normal").paper_flat,"independent research scene is not globally restyled")
 owner.queue_free();standalone.queue_free();await frames()
 var state=root.get_node("State");state.developer_mode=true;state.d=state.initial();state.d.native.settings.volume=0
 var entry=load("res://scenes/entry.tscn").instantiate();root.add_child(entry);await frames()
 flat(entry.story_button,"actual entry")
 if is_instance_valid(entry.preview_button):
  await click(entry.preview_button);check(entry.previews_open,"actual preview entry still opens")
  await click(entry.preview_back);check(not entry.previews_open,"actual preview return still closes")
 entry.queue_free();await frames()
 var shell:Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames();shell.set_process(false);shell.world.set_process(false);shell.battery_prank.set_process(false)
 var snapshot:Dictionary=state.d.duplicate(true)
 await shell._open_game_now({"script":"res://scripts/games/c3_weather.gd"});await frames();var game=shell.active_game;game.set_process(false)
 flat(game.start_button,"actual weather Start");flat(game.exit_button,"actual weather Return")
 await click(game.start_button);check(game.started,"actual weather start remains native input")
 game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);await frames();check(game.paused and game.shared_pause_overlay.is_open(),"focus loss keeps shared pause ownership")
 await click(game.shared_pause_overlay.resume_button);check(not game.paused and not game.shared_pause_overlay.is_open(),"shared Continue resumes the same game")
 await click(game.exit_button);check(not is_instance_valid(shell.active_game),"return retires the actual activity")
 check(state.d==snapshot,"navigation and pause do not grant story progress")
 await shell.shutdown();shell.queue_free();await frames()
 var web=root.get_node("WebContent");web._build_overlay();web._overlay.show();await frames();flat(web._retry,"actual content Retry");flat(web._cancel_optional_button,"actual content Return");web._overlay.hide()
 var cloud=root.get_node("CloudSaves");cloud.process_mode=Node.PROCESS_MODE_ALWAYS;cloud._build_surface();cloud._show("当前存档保持不变。",[["返回",func():activations+=1]])
 await frames();var choice:Button=cloud._column.get_child(cloud._column.get_child_count()-1);flat(choice,"actual cloud choice")
 await click(choice);check(activations==3,"cloud choice keeps its original callback exactly once");cloud._resume()
 print("STORY_FLAT_BUTTONS: ",checks," checks; ",failures," failures");quit(1 if failures else 0)
