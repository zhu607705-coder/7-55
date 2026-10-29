extends RefCounted
## A small independent notebook on the original north-west study table.
const BOUNDS=Rect2(1002,195,32,24)
const APPROACH=Vector2(1018,280)
const ID="library_geometry_notebook"
const Picker=preload("res://scripts/world_object_picker.gd")
static func target()->Dictionary:
	return {"id":ID,"label":"几何素描","position":[APPROACH.x,APPROACH.y],"bounds":[BOUNDS.position.x,BOUNDS.position.y,BOUNDS.size.x,BOUNDS.size.y],"radius":105.0,"action":"lib_geometry_study"}
static func draw(canvas:CanvasItem)->void:
	Picker.record(canvas,[ID],{"rect":BOUNDS.grow(3)})
	canvas.draw_rect(Rect2(BOUNDS.position+Vector2(1,2),BOUNDS.size),Color("493b29"))
	canvas.draw_rect(BOUNDS,Color("e8dfc8"))
	canvas.draw_rect(BOUNDS,Color("5b5749"),false,1)
	canvas.draw_line(BOUNDS.position+Vector2(4,1),BOUNDS.position+Vector2(4,23),Color("9b8f74"),1)
	var center=BOUNDS.get_center()+Vector2(2,0)
	canvas.draw_arc(center,7,0,TAU,24,Color("5b665d"),.8,true)
	canvas.draw_line(center+Vector2(-8,4),center+Vector2(8,-4),Color("5b665d"),.8,true)
