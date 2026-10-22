extends Node2D
## One independently addressable native object. Coordinates are local to this
## object; its owning scene supplies position/rotation/visibility separately.
const Motion=preload("res://scripts/presentation/c3_theater_clue_motion.gd")
@export_enum("oil","tissue","ticket","powder") var part:="oil"
var elapsed_ms:=-1.0
var ticket_texture:Texture2D
const TISSUE_ROWS:=["..kkkk...",".kwwwwk..","kwwwwwwk.","kwwyywwk.","kwwyyywk.","kwwwyywk.",".kwwwwwk.","..kwwwk..","...kkk..."]
const TISSUE_COLORS:={"k":Color("c6bca5"),"w":Color("f2ead8"),"y":Color("9f7637")}

func present(ms:float)->void:
	elapsed_ms=ms;queue_redraw()

static func oil_density(point:Vector2)->float:
	# Three overlapping thumb/cloth-shaped smears leave variable oil thickness.
	# Brass frames and the warm glass remain legible through the thicker brown
	# film; cleared cells have no residual fill and read as a clean contact trail.
	var density:=0.0
	for smear:Vector4 in [Vector4(43,13,76,19),Vector4(116,32,80,20),Vector4(191,49,70,20)]:
		var p:Vector2=(point-Vector2(smear.x,smear.y))/Vector2(smear.z,smear.w)
		density=maxf(density,maxf(0,1-p.length_squared()))
	return clampf(.17+.49*density+float((int(point.x/4)+int(point.y/4)*3)%5)*.011,0,.72)

func _draw()->void:
	match part:
		"oil":_draw_oil()
		"tissue":_draw_tissue()
		"ticket":_draw_ticket()
		"powder":
			for grain:Dictionary in Motion.grains(elapsed_ms):draw_rect(Rect2(grain.point-Motion.VENT_LIP,Vector2.ONE*float(grain.size)),Color("a6b979",float(grain.alpha)*.66))

func _draw_oil()->void:
	for y in range(0,62,4):
		for x in range(0,230,4):
			var local:=Vector2(x,y)
			if elapsed_ms>=0 and Motion.cleared(Motion.GLASS.position+local+Vector2(2,2),elapsed_ms):continue
			draw_rect(Rect2(local,Vector2(4,4)),Color("594027",oil_density(local+Vector2(2,2))))
	for i in 18:
		var source:=Vector2(207+i*7,719+i*2)
		if elapsed_ms<0 or not Motion.cleared(source,elapsed_ms):draw_rect(Rect2(source-Motion.GLASS.position,Vector2(12,2)),Color("d8b57b",.23))

func _draw_tissue()->void:
	# Original greaseTissue inventory pixels. This native node owns its contact
	# pivot and rotation; it is not a full-scene texture or replacement hand.
	for y in TISSUE_ROWS.size():
		for x in TISSUE_ROWS[y].length():
			var key:String=TISSUE_ROWS[y][x]
			if key!=".":draw_rect(Rect2(Vector2(x*3-13,y*3-13),Vector2(3,3)),TISSUE_COLORS[key])

func _draw_ticket()->void:
	if ticket_texture==null:ticket_texture=load("res://assets/rpg/theater/generated/icons/item_theater_ticket_half_a.png")
	for y in range(0,64,4):
		for x in range(0,64,4):
			var local:=Vector2(x-32,y-32)*.76
			if Motion.cleared(Motion.TICKET+local+Vector2(1.5,1.5),elapsed_ms):draw_texture_rect_region(ticket_texture,Rect2(local,Vector2.ONE*3.04),Rect2(x,y,4,4))
