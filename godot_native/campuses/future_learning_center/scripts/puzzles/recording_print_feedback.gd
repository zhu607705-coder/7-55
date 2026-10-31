extends Node2D
## Dynamic ink feedback on generated paper, clipped by its physical guide opening.
## This is not physical object artwork and never changes record identity or state.
const Sync=preload("res://campuses/future_learning_center/scripts/puzzles/sync_model.gd")
var model
var font:Font
var row:=0
var annotations_visible:=false
var aperture_origin:=Vector2.ZERO
func _draw()->void:
 if model==null or font==null:return
 var ink:=Color("253e46")
 for j:int in 4:
  var at:=Vector2(model.event_x(row,j),158+row*108)-aperture_origin
  var kind:String=Sync.CAMERA[j].kind
  if kind=="flash":
   for angle:float in [0,PI/2,PI/4,-PI/4]:draw_line(at-Vector2(cos(angle),sin(angle))*12,at+Vector2(cos(angle),sin(angle))*12,ink,2)
  elif kind=="feed":
   draw_rect(Rect2(at-Vector2(14,10),Vector2(24,20)),ink);draw_line(at+Vector2(15,-15),at+Vector2(15,15),ink,3)
  else:
   draw_rect(Rect2(at-Vector2(16,10),Vector2(22,20)),ink);draw_line(at+Vector2(8,-19),at+Vector2(8,19),ink,5)
  if annotations_visible:draw_string(font,at+Vector2(-6,25),str(int(Sync.CAMERA[j].time+(model.bias() if row==1 else 0))),HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
