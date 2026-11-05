extends "res://tests/test_compact_device_navigation.gd"
## Caption visibility and native activation for the shared C4 device header.
func run() -> void:
 if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
 state=root.get_node("State");seed_case("c4_duty")
 main=load("res://scenes/main.tscn").instantiate();root.add_child(main)
 for i in 5:await process_frame
 for width:int in [390,1440]:
  await prepare("c4_duty",width);await interact("c4_device_duty_board")
  for i in 5:await process_frame
  var button:Button=main.modal.close_button
  var font:Font=button.get_theme_font("font");var style:StyleBox=button.get_theme_stylebox("normal")
  var caption:float=font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x
  check(button.text=="关闭" and button.autowrap_mode==TextServer.AUTOWRAP_OFF,"close has a readable single-line caption")
  check(button.size.x-style.get_margin(SIDE_LEFT)-style.get_margin(SIDE_RIGHT)>=caption,"caption fits after the actual style padding")
  check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(main.modal.frame.get_global_rect()),"same device frame fits viewport")
  var scene=state.d.native.scene;var position=main.world.player;var facts=state.d.chapter4.factIds.duplicate()
  await click(button,"C4 header close")
  check(not is_instance_valid(main.modal) and main.world.is_visible_in_tree(),"native close returns to world")
  check(state.d.native.scene==scene and main.world.player==position and state.d.chapter4.factIds==facts,"closing preserves position and grants no puzzle fact")
 await main.shutdown();main.queue_free();await process_frame
 print("STORY_DEVICE_CLOSE: ",checks," checks; ",failures," failures");quit(1 if failures else 0)
