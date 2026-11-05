extends SceneTree
## Interactive native review only. Fixture starts the real activity directly;
## it does not claim the puzzle was played or write the production profile.
var shell:Control
var game:Control
var output:="user://focus-live.json"
var platform:Node
var last:=""
var started:=0
class ReviewKeys extends Node:
 var game:Control
 var shell:Control
 func _input(event:InputEvent):
  if not event is InputEventKey or not event.pressed or event.echo:return
  if event.keycode not in [KEY_F5,KEY_F6,KEY_F7,KEY_F8,KEY_F9]:return
  # Explicit fixture scene selection only. No State/controller action or save.
  if event.keycode==KEY_F5:
   game.hide();game.set_process(false);shell.active_game=null;shell._layout();get_viewport().set_input_as_handled();return
  shell.active_game=game;game.show();game.set_process(true);shell._layout()
  game.start({});game._switch("success" if event.keycode==KEY_F6 else "blackout" if event.keycode==KEY_F7 else "lock" if event.keycode==KEY_F8 else "deploy")
  game._sync_pause_surface();game.grab_focus();get_viewport().set_input_as_handled()
func _initialize():run.call_deferred()
func frames(n=4):
 for i in n:await process_frame
func run():
 if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
 root.size=Vector2i(390,844)
 var phase:="deploy"
 var wait_for_review:=false
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--phase="):phase=arg.trim_prefix("--phase=")
  if arg.begins_with("--report="):output=arg.trim_prefix("--report=")
  if arg=="--desktop":root.size=Vector2i(1440,900)
  if arg=="--wait-for-review":wait_for_review=true
 var state=root.get_node("State");state.developer_mode=true;state.d=state.initial();state.d.native.settings.effects=false;state.d.native.settings.music=false
 shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
 await shell._open_game_now({"script":"res://scripts/games/prologue_interception.gd","type":"interception","viewport":[430,820]})
 game=shell.active_game;game._switch(phase);game.grab_focus();started=Time.get_ticks_msec()
 if wait_for_review:game._pause()
 var hotkeys:=ReviewKeys.new();hotkeys.game=game;hotkeys.shell=shell;root.add_child(hotkeys)
 platform=load("res://scripts/platform/web_platform.gd").new();shell.add_child(platform);platform.setup(shell,state);shell.web_platform=platform
 # Native GUI drives the production platform boundary; no browser/WebGL claim.
 root.focus_exited.connect(func():platform._apply_focus(false))
 root.focus_entered.connect(func():platform._apply_focus(true))
 process_frame.connect(observe)
 print("PAUSE REVIEW READY report=",output," phase=",phase," real focus/click/Enter/Space/Escape; F5=phone F6=receipt F7=blackout F8=lock F9=moving text; fixture only, no earned progress")
func observe():
 if not is_instance_valid(game):return
 var value={"surface":"activity" if is_instance_valid(shell.active_game) else "phone","platformSuspended":platform._suspended,"overlayVisible":game.pause_overlay.is_open(),"footerHintPresent":game.pause_overlay.panel.find_child("PauseKeyboardHint",true,false)!=null,"elapsed":game.elapsed,"wordClock":game.session.clock,"phase":game.phase,"paused":game.paused,"pauseReason":game.pause_reason,"blocked":game.platform_suspended,"focused":root.has_focus(),"buttonVisible":game.resume_button.is_visible_in_tree(),"buttonDisabled":game.resume_button.disabled,"buttonRect":str(game.resume_button.get_global_rect()),"savedState":root.get_node("State").d.flags.duplicate(true)}
 var text=JSON.stringify(value)
 if not output.is_empty() and text!=last:
  var f=FileAccess.open(output,FileAccess.WRITE);f.store_string(text);f.close();last=text
