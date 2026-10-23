extends SceneTree
const V=preload("res://scripts/presentation/chase_transition_3d_presenter.gd")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var v:=V.new();v.manual_clock=true;root.add_child(v);await process_frame
 print("SADDLE=",v.rider_saddle.name," parent=",v.rider_bicycle.name)
 for f: int in [0,20,33,40,70,76,76]:
  v.render_source_frame("start",f,.5)
  print(f," bike=",v.rider_bicycle.global_transform," root=",v.source_root.global_transform," pedal=",v.source_world_transform("rightPedalContact").origin," hand=",v.action_pose.hand_constraints," seat=",v.saddle_world_top())
 v.dispose();v.queue_free();await process_frame;quit()
