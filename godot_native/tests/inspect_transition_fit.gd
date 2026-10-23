extends SceneTree
const View=preload("res://scripts/presentation/chase_transition_3d_presenter.gd")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var v:=View.new();v.manual_clock=true;root.add_child(v);await process_frame
 for stage: String in ["start","finish"]:
  v.play(stage)
  for f: int in ([0,20,40,55,70,90] if stage=="start" else [0,20,40,70,90,120]):
   v.render_source_frame(stage,f,0)
   var h: Node3D=v.campus_human
   print("TRANSITION_FIT ",stage," frame=",f," hips=",h.joint_point("Hips")," torso=",h.joint_point("Torso")," neck=",h.joint_point("Neck")," head=",h.joint_point("Head")," head_neck=",h.joint_point("Head").distance_to(h.joint_point("Neck"))," rest=",h.rests.Head.distance_to(h.rests.Neck))
 v.dispose();await process_frame;quit()
