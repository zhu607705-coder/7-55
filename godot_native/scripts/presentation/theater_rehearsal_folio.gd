extends PanelContainer
## A stitched paper folio. Decoration never receives input or owns puzzle facts.
var divided := true
var turn_amount:=0.0
var turn_direction:=1

func _ready()->void:
	resized.connect(queue_redraw)

func turn_page(direction:int,reduced:bool)->void:
	turn_direction=direction;turn_amount=0.0 if reduced else 1.0;queue_redraw()

func _process(delta:float)->void:
	if turn_amount<=0:return
	turn_amount=maxf(0,turn_amount-delta/.24);queue_redraw()

func _draw()->void:
	draw_rect(Rect2(Vector2(0,3),size),Color("202B3540"))
	draw_rect(Rect2(Vector2.ZERO,size),Color("344247"))
	for edge:int in range(3):
		draw_rect(Rect2(Vector2(13+edge,5+edge),size-Vector2(19+edge*2,12+edge*2)),Color("C5B792"))
	draw_rect(Rect2(Vector2(18,8),size-Vector2(27,19)),Color("F4EAD5"))
	draw_rect(Rect2(Vector2(30,20),size-Vector2(53,43)),Color("C9BA98"),false,1)
	for y:int in range(42,int(size.y)-26,45):
		draw_line(Vector2(7,y),Vector2(23,y+4),Color("E5D7B4"),2)
		draw_line(Vector2(7,y+9),Vector2(23,y+4),Color("9D875E"),1)
	if divided:
		var x:float=size.x*.48
		draw_line(Vector2(x,76),Vector2(x,size.y-70),Color("C9BA98"),1)
		draw_line(Vector2(x+3,78),Vector2(x+3,size.y-72),Color("E5D7B4"),2)
	if turn_amount>0:
		var corner:=Vector2(size.x-9,size.y-11) if turn_direction>0 else Vector2(19,size.y-11)
		var fold:=Vector2(-26*turn_amount*turn_direction,-34*turn_amount)
		draw_colored_polygon(PackedVector2Array([corner,corner+Vector2(fold.x,0),corner+Vector2(0,fold.y)]),Color("C5B792"))
		draw_line(corner+Vector2(fold.x,0),corner+Vector2(0,fold.y),Color("9D875E"),1)
