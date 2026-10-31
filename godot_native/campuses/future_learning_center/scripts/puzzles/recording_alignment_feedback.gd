extends Node2D
## Comparison guides behind the metal aperture frames, not painted on the objects.
var model
func _draw()->void:
 if model==null:return
 for j:int in [0,3]:
  var a:=Vector2(model.event_x(0,j),189.44);var b:=Vector2(model.event_x(1,j),237.56)
  if a.x>104.57 and a.x<855.43 and b.x>104.57 and b.x<855.43:draw_line(a,b,Color("6f8580"),2)
