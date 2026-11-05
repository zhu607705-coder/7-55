extends SceneTree
## Production native rendering. Direct phase setup is a presentation fixture,
## not a playthrough or substitute for the separate real-window-focus test.
var shell:Control
var output:=""
var rows:Array=[]
func _initialize():run.call_deferred()
func frames(n=5):
 for i in n:await process_frame
func click_button(button:Button):
 var point=button.get_global_transform_with_canvas()*(button.size/2)
 for down in [true,false]:
  var m=InputEventMouseMotion.new();m.position=point;m.global_position=point;root.push_input(m,true)
  var e=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e,true)
 await frames()
func capture(name:String,view:CanvasLayer):
 await frames(6);await RenderingServer.frame_post_draw
 var file=output.path_join(name+".png")
 var result=root.get_texture().get_image().save_png(file)
 rows.append({"file":file,"result":result,"viewport":str(root.size),"panel":str(view.panel.get_global_rect()),"button":str(view.resume_button.get_global_rect()),"overlayVisible":view.is_open(),"footerHintPresent":view.panel.find_child("PauseKeyboardHint",true,false)!=null,"titleFont":view.title.get_theme_font_size("font_size"),"sharedScale":view.panel.scale.x})
func run():
 if not preload("res://tests/native_test_isolation.gd").is_isolated_save() or DisplayServer.get_name()=="headless":quit(2);return
 output=OS.get_environment("PAUSE_CAPTURE_DIR")
 if output.is_empty():quit(2);return
 DirAccess.make_dir_recursive_absolute(output)
 create_timer(120).timeout.connect(func():push_error("Pause capture deadline");quit(2))
 var state=root.get_node("State");state.developer_mode=true;state.d=state.initial();state.d.native.settings.music=false;state.d.native.settings.effects=false
 shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
 shell.set_process(false);shell.world.set_process(false);shell.battery_prank.set_process(false)
 var baseline:Dictionary=state.d.duplicate(true)
 for extent:Vector2i in [Vector2i(390,844),Vector2i(1440,900),Vector2i(320,568),Vector2i(844,390)]:
  root.size=extent;shell.size=Vector2(extent);shell._layout();await frames()
  await shell._open_game_now({"script":"res://scripts/games/prologue_interception.gd","type":"interception","viewport":[430,820]})
  var game=shell.active_game;game.set_process(false)
  for phase:String in ["success","blackout","deploy"]:
   game.start({});game._switch(phase);game.elapsed=2.2 if phase=="success" else .3;game._process(0);game._on_window_focus_out()
   await capture("%dx%d-%s-focus"%[extent.x,extent.y,phase],game.pause_overlay)
   game._on_window_focus_in();game._resume()
  shell.active_game=null;game.queue_free();await frames()
  # The cropped C1 shell is not a Chapter 3 arrival fixture. Render this
  # resource-light production activity standalone, without an unrelated
  # alarm page behind it. Start through its real native button and boundary.
  shell.hide()
  var weather=load("res://scripts/games/c3_weather.gd").new();root.add_child(weather);weather.set_process(false)
  var factor:float=minf((extent.x-20)/960.0,(extent.y-20)/540.0)
  weather.scale=Vector2.ONE*factor;weather.position=(Vector2(extent)-Vector2(960,540)*factor)/2
  weather._apply_presentation_layout(true);await frames();await click_button(weather.start_button)
  if not weather.started:push_error("Weather native start did not activate");quit(2);return
  weather._process(.05);weather._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
  await capture("%dx%d-weather-pause"%[extent.x,extent.y],weather.shared_pause_overlay)
  weather.queue_free();await frames();shell.show()
 var unchanged:bool=state.d==baseline
 var f=FileAccess.open(output.path_join("CAPTURE_REPORT.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"kind":"Actual production native rendering from explicit phase fixtures, not browser gameplay","stateUnchanged":unchanged,"captures":rows},"\t"));f.close()
 await shell.shutdown();shell.queue_free();await frames()
 print("PAUSE_CAPTURE: ",rows.size()," captures; unchanged state=",unchanged)
 quit(0 if unchanged else 1)
