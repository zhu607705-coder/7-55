extends RefCounted
## Close view of the actual pull-out drawer in the central exhibit case.
## Three paper channels, timber rails, and brass handle have separate motion.
const TEXTURE=preload("res://assets/native/north_objects_20261025/room301_index_drawer_v1.png")
const FILM_TEXTURE=preload("res://assets/rpg/interiors/finale/chapter4-755/props/chapter4_a3_archive_film_v01.png")
const SOURCE:=Rect2(12,108,1230,998)
const FRONT:=Rect2(12,848,1230,258)
const SIZE:=Vector2(96,998.0*96.0/1230.0)

static func render(canvas:CanvasItem,where:Rect2,pull:float,film_alpha:float,film_offset:=Vector2.ZERO,tint:=Color.WHITE)->void:
	var factor:float=where.size.x/SOURCE.size.x
	var scale_value:float=where.size.x/SIZE.x
	var back:=Rect2(SOURCE.position,Vector2(SOURCE.size.x,FRONT.position.y-SOURCE.position.y))
	canvas.draw_texture_rect_region(TEXTURE,Rect2(where.position,back.size*factor),back,tint,false,true)
	var seam:Vector2=where.position+Vector2(0,back.size.y)*factor
	if pull>0:
		canvas.draw_rect(Rect2(seam,Vector2(where.size.x,pull*scale_value+2)),Color("28180c"))
		for edge:float in [0.0,FRONT.size.x-30]:
			canvas.draw_texture_rect_region(TEXTURE,Rect2(seam+Vector2(edge*factor,0),Vector2(30*factor,pull*scale_value+2)),Rect2(FRONT.position+Vector2(edge,0),Vector2(30,30)),tint,false,true)
	canvas.draw_texture_rect_region(TEXTURE,Rect2(seam+Vector2(0,pull*scale_value),FRONT.size*factor),FRONT,tint,false,true)
	if film_alpha>0:
		# Retain the authored amber film, at a normal uniform crop scale.
		var at:Vector2=where.position+(Vector2(76,43)+film_offset)*scale_value
		canvas.draw_texture_rect_region(FILM_TEXTURE,Rect2(at,Vector2(18,17)*scale_value*.5),Rect2(53,30,18,17),Color(tint,film_alpha),false,true)
