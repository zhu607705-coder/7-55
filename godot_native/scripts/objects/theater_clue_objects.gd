extends Node2D
## Native object scene. The controller has already accepted the action; every
## child here owns visual geometry only, with no event, save or reward callback.
const Motion=preload("res://scripts/presentation/c3_theater_clue_motion.gd")
@onready var clip:Control=$VisibleSurface
@onready var objects:Node2D=$VisibleSurface/Objects
@onready var oil:Node2D=$VisibleSurface/Objects/OilMask
@onready var tissue:Node2D=$VisibleSurface/Objects/Tissue
@onready var ticket:Node2D=$VisibleSurface/Objects/TicketHalf
@onready var corner:Polygon2D=$VisibleSurface/Objects/TicketHalf/LiftedCorner
@onready var brush:Sprite2D=$VisibleSurface/Objects/VentBrush
@onready var powder:Node2D=$VisibleSurface/Objects/Powder
@onready var paper:Node2D=$VisibleSurface/Objects/Paper
@onready var left:Polygon2D=$VisibleSurface/Objects/Paper/UnmarkedLeft
@onready var right:Polygon2D=$VisibleSurface/Objects/Paper/UnmarkedRight
@onready var marked_left:Polygon2D=$VisibleSurface/Objects/Paper/MarkedLeft
@onready var marked_right:Polygon2D=$VisibleSurface/Objects/Paper/MarkedRight

func configure(context:Dictionary,snapshot:Dictionary)->void:
	visible=bool(snapshot.get("visible",false))
	if not visible:return
	var safe:Rect2=context.safe_rect
	clip.position=safe.position;clip.size=safe.size
	objects.position=Vector2(context.origin)-safe.position;objects.scale=Vector2.ONE*float(context.zoom)
	var poster_visible:bool=snapshot.poster_visible
	var poster_ms:float=snapshot.poster_ms
	oil.visible=poster_visible;oil.position=Motion.GLASS.position;oil.present(poster_ms)
	tissue.visible=poster_visible and poster_ms>=0
	ticket.visible=tissue.visible
	if tissue.visible:
		var pose:Dictionary=Motion.poster(poster_ms)
		tissue.position=pose.cloth;tissue.rotation_degrees=float(pose.cloth_angle);tissue.modulate.a=float(pose.cloth_alpha);tissue.present(poster_ms)
		ticket.position=Motion.TICKET+Vector2(pose.ticket_offset);ticket.modulate.a=float(pose.ticket_alpha);ticket.present(poster_ms)
		corner.visible=float(pose.lift)>0
		corner.position=Vector2(10,-21)
		corner.polygon=PackedVector2Array([Vector2.ZERO,Vector2(7,2),Vector2(4,-7)*float(pose.lift)])
	var paper_visible:bool=snapshot.paper_visible
	brush.visible=paper_visible;powder.visible=paper_visible;paper.visible=paper_visible
	if not paper_visible:return
	var ms:float=snapshot.dust_ms
	var pose:Dictionary=Motion.dust(ms)
	brush.position=pose.brush_contact;brush.rotation_degrees=float(pose.brush_angle);brush.scale=Vector2.ONE*.62;brush.modulate=Color(.90,.88,.76,float(pose.brush_alpha))
	powder.position=Motion.VENT_LIP;powder.present(ms)
	var y:float=7*(1-cos(fmod(float(snapshot.clock_ms)/760.0,2)*PI))/2
	paper.position=Vector2(pose.paper)+Vector2(0,y)
	paper.rotation_degrees=lerpf(-4,4,y/7)
	paper.modulate.a=float(pose.paper_alpha)
	# Only the outer paper strip yields to the wind; the body keeps the source
	# idle trajectory and never folds like a book or jumps sideways.
	var flutter:float=pose.flutter
	var left_points:=PackedVector2Array([Vector2(-32,-32),Vector2(14,-32),Vector2(14,32),Vector2(-32,32)])
	var right_points:=PackedVector2Array([Vector2(14,-32),Vector2(32+flutter*.25,-32+flutter),Vector2(32-flutter*.25,32-flutter*.6),Vector2(14,32)])
	left.polygon=left_points;marked_left.polygon=left_points
	right.polygon=right_points;marked_right.polygon=right_points
	left.color=Color.WHITE;marked_left.color=Color.WHITE
	var shade:float=1-absf(flutter)*.015
	right.color=Color(shade,shade,shade);marked_right.color=right.color
	# Each scene instance owns its two local materials. The mark spreads from
	# the powder-contact edge; it is not a whole-sheet fluorescent crossfade.
	left.material.set_shader_parameter("reveal",float(pose.edge))
	marked_left.material.set_shader_parameter("reveal",float(pose.edge))

func retire()->void:
	hide()
