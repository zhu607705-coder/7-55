extends "res://tests/test_native_surface_modes.gd"
func run()->void:
 state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
 shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
 for dimensions:Vector2i in [Vector2i(390,844),Vector2i(667,375),Vector2i(1280,720),Vector2i(1440,900)]:
  root.size=dimensions;shell.size=Vector2(dimensions)
  state.begin_checkpoint("c2-dorm-exit");shell._refresh();shell.mobile_world=true;shell._layout();await frames()
  var launcher:Button=shell.mobile_back
  check(launcher.text.is_empty(),"phone launcher is a silhouette, not a generic text rectangle")
  check(launcher.tooltip_text.contains("手机") and launcher.tooltip_text.contains("P"),"existing action and shortcut remain discoverable")
  check(launcher.size==Vector2(44,44),"small 20x30 drawing retains exact 44px touch target")
  check(launcher.get_global_rect().end.is_equal_approx(shell.world_view.get_global_rect().end-Vector2(8,8)),"map phone icon uses the actual playfield's bottom-right corner")
  check(launcher.get_theme_stylebox("normal") is StyleBoxFlat and launcher.get_theme_stylebox("normal").bg_color==Color("F4EAD5"),"phone uses the same opaque paper icon plate as tools and items")
  await click(launcher)
  check(shell.phone.visible and not shell.world_frame.visible,"actual pointer opens existing phone directly")
  var back:Button=shell.phone_world_return
  check(back.text.is_empty() and back.get("glyph")=="map" and back.size==Vector2(44,44),"phone offers a map glyph with a physical44px hit target")
  check(back.get_global_rect().end.is_equal_approx(Vector2(dimensions)-Vector2(12,12)),"phone return map icon uses the same bottom-right corner")
  await click(back)
  check(shell.world_frame.visible,"existing return restores world")
 # First event on a fresh retained-world shell must work without a prior hover.
 # Keep raw MouseButton pairs: adding motion here would mask the init regression.
 for dimensions:Vector2i in [Vector2i(1440,900),Vector2i(1280,720),Vector2i(390,844),Vector2i(430,860)]:
  for route:String in ["mouse","touch","keyboard"]:
   await create_shell(dimensions,"library_interior")
   var launcher:Button=shell.mobile_back
   var actor:Vector2=shell.world.player
   var counts:Array=[0]
   launcher.pressed.connect(func():counts[0]+=1)
   if route=="mouse":await click(launcher)
   elif route=="touch":
    var point:Vector2=launcher.get_global_rect().get_center()
    for down:bool in [true,false]:
     var event:=InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=down
     Input.parse_input_event(event);Input.flush_buffered_events();await frames(1)
    await frames()
   else:
    launcher.grab_focus();await frames(1);await key(KEY_ENTER)
   check(shell.phone.visible and not shell.world_frame.visible,"fresh first "+route+" opens phone at "+str(dimensions))
   check(counts[0]==1,"fresh "+route+" dispatches exactly once")
   check(shell.world.player==actor,"fresh "+route+" does not move world actor")
 await close_shell()
 print("Selected phone launcher: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
