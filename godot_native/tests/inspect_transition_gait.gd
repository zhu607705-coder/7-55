extends SceneTree
const View=preload("res://scripts/presentation/chase_transition_3d_presenter.gd")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var v:=View.new();v.manual_clock=true;root.add_child(v);await process_frame
 for stage: String in ["start","finish"]:
  v.play(stage)
  for f: int in ([0,3,6,9,12,16,20,24,28,32,36,40,70,90] if stage=="start" else [40,50,60,70,80,90,95,100,105,110,115,120,125,132]):
   v.render_source_frame(stage,f,0)
   print(stage," ",f," hips=",v._original_bone_transform("Hips").origin," leftFoot=",v.source_world_transform("leftFootContact").origin," rightFoot=",v.source_world_transform("rightFootContact").origin)
 v.dispose();await process_frame;quit()
