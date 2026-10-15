extends "res://tests/test_chapter4_device_main.gd"
## Controller integration fixtures, not earned user-play evidence.
func run()->void:
 state_node=root.get_node("State");state_node.developer_mode=true
 var contract:Dictionary=state_node.content("chapter4-755.content.json").lightGrid
 for view:Vector2i in [Vector2i(1180,812),Vector2i(390,844)]:
  await prepare(view,"c4-755-blackout-0754")
  var source_before:Dictionary=state_node.d.chapter4.duplicate(true)
  state_node.act("c4_power");await frames(4)
  var panel:Control=shell.modal
  check(is_instance_valid(panel) and panel.has_method("maybe_lock"),"Accepted original power intent opens native topology")
  if not is_instance_valid(panel):continue
  check(shell.world_frame.is_visible_in_tree() and panel.is_visible_in_tree(),"Original world retained under modal")
  check(state_node.d.chapter4==source_before,"Opening does not mutate story or grid")
  var player=state_node.d.native.player.duplicate(true)
  await press_key(KEY_D);check(state_node.d.native.player==player,"World movement inhibited by panel")
  await mouse_click(panel.buttons[0]);check(int(state_node.d.chapter4.lightGrid.mask)==1 and panel.mask==1,"Physical root pointer delegates original linked toggle exactly once")
  check(shell.toast.text.is_empty(),"Toggle does not produce duplicate notification")
  await press_key(KEY_ESCAPE);check(shell.modal==null,"Escape disposes panel and restores world")
  state_node.act("c4_power");await frames(3);panel=shell.modal
  check(is_instance_valid(panel) and panel.mask==1,"Reentry reads current authoritative mask")
  await press_key(KEY_TAB);var focus=root.gui_get_focus_owner();check(panel==focus or panel.is_ancestor_of(focus),"Tab remains in panel controls")
  var phase:String=state_node.d.chapter4.phase
  # Presentation must never complete a target state without the original evidence.
  var facts:Array=state_node.d.chapter4.factIds.duplicate()
  state_node.d.chapter4.factIds.erase("a2_power_topology_recovered")
  state_node.d.chapter4.lightGrid.mask=int(contract.targetMask);state_node.changed.emit();await frames(4)
  check(state_node.d.chapter4.phase==phase and not state_node.d.chapter4.lightGrid.locked,"Source evidence gate still rejects matching mask")
  check(shell.modal==panel and panel.retry.visible and not panel.pending,"Rejected automatic lock remains readable and retryable")
  var feedback:String=panel.feedback;await frames(5);check(panel.feedback==feedback and not panel.pending,"No repeated automatic lock after rejection")
  state_node.d.chapter4.factIds=facts
  await mouse_click(panel.retry);await frames(4)
  check(state_node.d.chapter4.lightGrid.locked and state_node.d.chapter4.phase=="final_chase","Original controller accepts explicit retry with earned fixture evidence")
  check(shell.modal==null,"Accepted scene handoff retires exactly one panel")
  var after:Dictionary=state_node.d.chapter4.duplicate(true);await frames(5);check(after==state_node.d.chapter4,"Retired deferred callback cannot mutate result")
 await shell.shutdown();shell.queue_free();await frames(3)
 print("CHAPTER4_POWER_MAIN ",checks," checks; ",failures," failures");quit(1 if failures else 0)
