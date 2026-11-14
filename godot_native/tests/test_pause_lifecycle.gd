extends SceneTree
## Real production owners and native root input. Browser events below enter
## their exact host callback; OS/CUA focus verification is a separate fixture.
const Overlay=preload("res://scripts/ui/native_pause_overlay.gd")
var shell:Control
var state:Node
var game:Control
var platform:Node
var checks:=0
var failures:=0
var observations:Array=[]
func _initialize():run.call_deferred()
func check(ok:bool,label:String):
 checks+=1;observations.append({"check":label,"passed":ok})
 if not ok:failures+=1;push_error("PAUSE LIFECYCLE: "+label)
func frames(n=3):
 for i in n:await process_frame
func key(code:Key,pressed:bool,echo:bool=false):
 var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed;e.echo=echo;root.push_input(e,true)
func click(button:Button):
 var point=button.get_global_transform_with_canvas()*(button.size/2)
 for down in [true,false]:
  var m=InputEventMouseMotion.new();m.position=point;m.global_position=point;root.push_input(m,true)
  var e=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e,true)
 await frames()
func touch(button:Button):
 var point=button.get_global_transform_with_canvas()*(button.size/2)
 Input.call("set_emulate_mouse_from_touch",true)
 for down in [true,false]:
  var e=InputEventScreenTouch.new();e.index=3;e.position=point;e.pressed=down;Input.parse_input_event(e)
  await frames()
 Input.call("set_emulate_mouse_from_touch",false)
func visible_surfaces()->int:
 var count=0
 for view:Node in get_nodes_in_group(Overlay.GROUP):
  if view.is_open():count+=1
 return count
func run():
 if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
 create_timer(180).timeout.connect(func():push_error("pause lifecycle watchdog");quit(2))
 state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
 state.d.native.settings.music=false;state.d.native.settings.effects=false
 shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(6)
 shell.set_process(false);shell.world.set_process(false);shell.battery_prank.set_process(false)
 await shell._open_game_now({"script":"res://scripts/games/prologue_interception.gd","type":"interception","viewport":[430,820]})
 game=shell.active_game;game.set_process(false)
 var baseline:Dictionary=state.d.duplicate(true)
 for extent:Vector2i in [Vector2i(390,844),Vector2i(1440,900),Vector2i(320,568),Vector2i(844,390),Vector2i(1270,1810)]:
  root.size=extent;shell.size=Vector2(extent);shell._layout();await frames()
  for phase:String in ["deploy","intercept","lock"]:
   game.start({});game._switch(phase);
   if phase=="intercept":game.session.begin_search()
   game._process(.1);game._pause()
   check(game.pause_overlay.is_open() and game.resume_button.is_visible_in_tree(),"synchronous pause control "+phase+str(extent))
   check(visible_surfaces()==1,"one pause surface "+phase)
   var rect:Rect2=game.resume_button.get_global_rect()
   check(Rect2(Vector2.ZERO,Vector2(extent)).encloses(rect) and rect.size.y>=44-.01,"continue fits viewport and touch height")
   check(game.resume_button.text=="继续" and game.pause_overlay.title.get_theme_font_size("font_size")==16,"shared continue and regular title size")
   var elapsed:float=game.elapsed;var clock:float=game.session.clock;var held:float=game.hold_ms;var captures:Array=game.session.captures.duplicate(true)
   game._process(.25);game._process(.25)
   check(game.elapsed==elapsed and game.session.clock==clock and game.hold_ms==held and game.session.captures==captures,"paused timers and earned words preserved")
   await click(game.resume_button)
   check(not game.paused and game.phase==phase and game.elapsed==elapsed,"first real pointer click continues same phase")
   check(visible_surfaces()==0,"resume hides sole overlay immediately")
 for code:Key in [KEY_ENTER,KEY_SPACE,KEY_ESCAPE]:
  for phase:String in ["deploy","lock","intercept"]:
   game.start({});game._switch(phase);
   if phase=="intercept":game.session.begin_search()
   game._process(.1);game._pause();key(code,true)
   check(not game.paused and game.phase==phase and not game.holding,"keyboard resume does not skip/start hold")
   key(code,true,true);key(code,false);check(not game.holding,"resume repeats and key-up are consumed")
 game.start({});game._switch("lock");game._process(.1);game._pause();await touch(game.resume_button)
 check(not game.paused and game.phase=="lock" and not game.holding,"real synthetic touch resumes without lock click-through")
 game._pause();game.hide();check(visible_surfaces()==0,"hidden owner removes root pause synchronously")
 game.show();check(visible_surfaces()==1,"same paused owner reveals one surface on return")
 # Nested owner arbitration is a presentation rule, not a second pause state.
 var child:=Control.new();game.add_child(child)
 var child_overlay=Overlay.mount(child,func():child_overlay_noop())
 child_overlay.present(true);check(visible_surfaces()==1 and child_overlay.is_open() and not game.pause_overlay.is_open(),"nested pause never stacks")
 var action_calls=[0,0,0]
 child_overlay.set_actions([{"text":"重试","callback":func():action_calls[0]+=1},{"text":"返回","callback":func():action_calls[1]+=1},{"text":"撤回","callback":func():action_calls[2]+=1,"disabled":true}])
 await click(child_overlay.action_buttons[0]);check(action_calls==[1,0,0],"shared secondary real pointer keeps original action")
 child_overlay.resume_button.grab_focus();key(KEY_TAB,true);key(KEY_TAB,false);key(KEY_ENTER,true);key(KEY_ENTER,false)
 check(action_calls==[2,0,0],"Tab and Enter activate focused secondary, not Continue")
 await click(child_overlay.action_buttons[2]);check(action_calls==[2,0,0],"disabled original action remains blocked")
 Overlay.set_environment_blocked(self,true);await click(child_overlay.action_buttons[1]);check(action_calls==[2,0,0],"loading/hidden guard also blocks secondary actions")
 Overlay.set_environment_blocked(self,false)
 child.hide();check(visible_surfaces()==1 and game.pause_overlay.is_open(),"hiding nested owner returns parent pause")
 child.queue_free();await frames();game._resume()
 platform=load("res://scripts/platform/web_platform.gd").new();shell.add_child(platform);platform.setup(shell,state)
 for prior_manual:bool in [false,true]:
  game.start({});game._switch("lock");game._process(.2)
  if prior_manual:game._pause()
  platform._on_browser_visibility([false,false]);check(game.paused and paused and game.resume_button.disabled,"blur freezes tree and disables resume")
  check(game.pause_reason==("manual" if prior_manual else "focus"),"manual vs automatic pause reason retained")
  for i in 3:platform._on_browser_visibility([true,false]);platform._on_browser_visibility([false,false])
  check(paused and game.resume_button.disabled,"hidden/blur duplicates cannot thaw scene")
  platform.set_content_loading(true);platform._on_browser_visibility([false,true]);await click(game.resume_button)
  check(game.paused and paused and game.resume_button.disabled,"foreground continue cannot bypass loading")
  platform.set_content_loading(false)
  check(not paused and game.paused and not game.resume_button.disabled,"visibility return leaves activity awaiting explicit resume")
  await click(game.resume_button);check(not game.paused and game.phase=="lock","explicit continue after overlaps succeeds")
 game.start({});game._switch("lock");game.holding=true;game.hold_ms=600;game.left_held=true
 platform._on_browser_visibility([true,false]);check(game.hold_ms==0 and not game.holding and not game.left_held,"focus cancels partial hold and pressed input")
 platform._on_browser_visibility([false,true]);await click(game.resume_button)
 check(state.d==baseline,"all pauses keep story and save fields unchanged")
 var controls:Array=platform.read_snapshot().visibleControls
 game._pause();controls=platform.read_snapshot().visibleControls
 check(controls.any(func(c):return c.name=="PrologueResume" and c.text=="继续"),"web observation includes actual root continue button")
 game._resume();var gone=game;game=null;shell.active_game=null;gone.queue_free();await frames()
 for i in 3:
  platform._on_browser_visibility([false,false]);check(paused and visible_surfaces()==0,"phone lifecycle freezes without pause UI")
  platform._on_browser_visibility([false,true]);check(not paused and visible_surfaces()==0,"phone returns automatically without Continue")
 paused=true;platform._on_browser_visibility([true,false]);platform._on_browser_visibility([false,true])
 check(paused,"platform never releases a pre-existing tree pause");paused=false
 for hidden_first:bool in [true,false]:
  if hidden_first:platform._on_browser_visibility([true,false])
  shell.web_platform=platform;shell._on_content_blocking(true)
  if not hidden_first:platform._on_browser_visibility([true,false])
  shell._on_content_blocking(false);check(paused,"loading completion while hidden cannot resume tree")
  platform._on_browser_visibility([false,true])
  check(not paused and visible_surfaces()==0,"static overlap automatically ends after both guards clear")
 platform._on_browser_visibility([true,false])
 await shell._open_game_now({"script":"res://scripts/games/prologue_interception.gd","type":"interception","viewport":[430,820]})
 game=shell.active_game;game.set_process(false);platform._on_browser_visibility([true,false])
 check(not game.paused and game.platform_suspended and visible_surfaces()==0,"new receipt stays lifecycle-only without global latch")
 platform._on_browser_visibility([false,true])
 check(not paused and not game.paused and not game.platform_suspended,"new receipt automatically returns after background creation")
 for phase:String in ["success","signal_loss","error","red","blackout","caught","burst","whiteout"]:
  game.start({});game._switch(phase);game._process(.1)
  var before:float=game.elapsed
  game._pause();check(not game.paused and visible_surfaces()==0,"static phase has no manual pause: "+phase)
  game._on_window_focus_out();game._process(3600)
  check(game.elapsed==before and not game.paused and visible_surfaces()==0,"native static lifecycle freezes without overlay: "+phase)
  game._on_window_focus_in();game._process(3600)
  check(game.elapsed==before and not game.platform_suspended,"first resumed frame drops background delta: "+phase)
  game._process(.01);check(game.elapsed>before,"static clock resumes automatically: "+phase)
  platform._on_browser_visibility([true,false]);before=game.elapsed;game._process(1000)
  check(game.elapsed==before and visible_surfaces()==0,"browser static background freezes without UI: "+phase)
  platform.set_content_loading(true);platform._on_browser_visibility([false,true]);game._process(1000)
  check(game.elapsed==before and game.platform_suspended and paused,"static return cannot bypass content loading: "+phase)
  platform.set_content_loading(false);game._process(1000);game._process(.01)
  check(not paused and not game.paused and game.elapsed>before,"static overlap auto resumes only after loading: "+phase)
 game.start({});game._switch("intercept");game.session.begin_search()
 game.session._fail("meaning",{"text":"错误"});game._process(.1)
 game._pause();check(not game.paused and visible_surfaces()==0,"failed-word hint is a static retry state, not player pause")
 game._on_window_focus_out();game._process(3600);game._on_window_focus_in();game._process(3600)
 check(game.session.phase=="hint" and not game.paused and visible_surfaces()==0,"focus return never automatically retries the failed round")
 game._process(.4);game._layout_controls();await click(game.retry_button)
 check(game.session.phase=="clue" and game.supports_player_pause(),"authored retry returns to live-play pause policy")
 game.start({});game._switch("deploy");game._pause()
 check(game.pause_overlay.panel.find_child("PauseKeyboardHint",true,false)==null,"removed keyboard explanation has no node or reserved row")
 check(game.pause_overlay.panel.size.y<200,"empty footer removed from primary-only panel")
 game._resume()
 check(state.d==baseline,"phone/content pauses do not overwrite progress")
 await shell.shutdown();shell.queue_free();await frames(5)
 check(visible_surfaces()==0 and get_nodes_in_group(Overlay.GROUP).is_empty(),"scene disposal leaves no root overlays")
 var output:=OS.get_environment("PAUSE_REPORT")
 if not output.is_empty():
  var f=FileAccess.open(output,FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"kind":"native synthetic input plus exact browser callback; CUA/WebGL reported separately","observations":observations},"\t"));f.close()
 print("PAUSE_LIFECYCLE: ",checks," checks; ",failures," failures");quit(1 if failures else 0)
func child_overlay_noop():pass
