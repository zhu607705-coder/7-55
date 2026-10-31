extends Node2D
## Code draws light, not object artwork. This layer sits above the fixture and
## below physical components, so a beam cannot paint across their solid bodies.
var view
func _draw()->void:
 if not is_instance_valid(view):return
 var model=view.model
 for side:int in 2:
  if side!=model.condition:continue
  var source:Vector2=model.rotate_point(Vector2(-210 if side==0 else 210,0))
  var end:=lamp_end(side)
  draw_line(view.projected(source),view.projected(end),Color("d6ac55"),3)
 var camera_source:Vector2=model.rotate_point(Vector2(0,-210))
 draw_dashed_line(view.projected(camera_source),view.projected(clipped_end(camera_source)),Color("537a84"),1.5,8)
func clipped_end(source:Vector2)->Vector2:
 var end:=Vector2.ZERO
 var hit:int=view.model.path_blocker(source,end)
 if hit>=0:
  var edge:Array=view.model.slot_segment(view.model.slots[hit])
  end=Geometry2D.segment_intersects_segment(source,end,edge[0],edge[1])
 return end

func lamp_end(side:int)->Vector2:
 # Assembly's removed support disables shielding without rewriting slot state.
 if not view.model.light_blocked(side):return Vector2.ZERO
 return clipped_end(view.model.rotate_point(Vector2(-210 if side==0 else 210,0)))
