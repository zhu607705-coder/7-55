extends RefCounted
## Small, node-owned presentation feedback. Never changes input rectangles/state.
static func press(button:Button,reduced:bool)->void:
 var active:Dictionary={"tween":null}
 var reset:Callable=func()->void:
  if active.tween!=null and active.tween.is_valid():active.tween.kill()
  active.tween=null;button.self_modulate=Color.WHITE
 button.button_down.connect(func()->void:
  reset.call();button.self_modulate=Color(.88,.94,.95,1))
 button.button_up.connect(func()->void:
  if active.tween!=null and active.tween.is_valid():active.tween.kill()
  if reduced:reset.call();return
  active.tween=button.create_tween()
  active.tween.tween_property(button,"self_modulate",Color.WHITE,.10))
 button.focus_exited.connect(reset)
 button.visibility_changed.connect(func()->void:
  if not button.is_visible_in_tree():reset.call())
static func enter(control:Control,reduced:bool)->void:
 if reduced:return
 control.modulate.a=.84
 control.ready.connect(func()->void:
  var tween:Tween=control.create_tween()
  tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
  tween.tween_property(control,"modulate:a",1.0,.16),CONNECT_ONE_SHOT)
