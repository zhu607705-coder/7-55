extends Node2D
## A real split sprite: tripod stays put while the upper shade can leave its post.
var body:Sprite2D
var cap:Node2D
var face:Sprite2D
var cutout:Node2D
var hat_id:="entrance"
var selected:=false
const PART_SCALE:=.145
const TRIM:=Rect2(110,64,827,1405)
const CUT_Y:=800.0
func configure(texture:Texture2D)->void:
	body=Sprite2D.new();body.centered=false;body.texture=texture;body.region_enabled=true
	body.region_rect=Rect2(TRIM.position.x,CUT_Y,TRIM.size.x,TRIM.end.y-CUT_Y)
	body.region_filter_clip_enabled=true;body.scale=Vector2.ONE*PART_SCALE
	body.position=Vector2(-TRIM.size.x*.5*PART_SCALE,-(TRIM.end.y-CUT_Y)*PART_SCALE);add_child(body)
	cap=Node2D.new();cap.name="MovableShade";add_child(cap)
	face=Sprite2D.new();face.centered=false;face.texture=texture;face.region_enabled=true
	face.region_rect=Rect2(TRIM.position,Vector2(TRIM.size.x,CUT_Y-TRIM.position.y));face.region_filter_clip_enabled=true
	face.scale=Vector2.ONE*PART_SCALE;face.position=Vector2(-TRIM.size.x*.5*PART_SCALE,0);cap.add_child(face)
	cutout=Cutout.new();cutout.owner_prop=self;cutout.position=Vector2(0,36);cap.add_child(cutout)
	settle();queue_redraw()
func rest_position()->Vector2:return Vector2(0,-TRIM.size.y*PART_SCALE)
func settle()->void:
	if cap!=null:cap.position=rest_position();cap.rotation=0
func _process(_delta:float)->void:
	if cutout!=null:cutout.queue_redraw()
class Cutout extends Node2D:
	var owner_prop:Node2D
	func _draw()->void:
		var color:=Color("e6c780") if owner_prop.selected else Color("c8d8cd")
		draw_circle(Vector2.ZERO,20,Color("15211f"));draw_arc(Vector2.ZERO,20,0,TAU,32,color,2)
		if owner_prop.selected:draw_arc(Vector2.ZERO,25,-PI*.9,PI*.9,28,Color("f1ca78"),3)
		draw_set_transform(Vector2.ZERO,0,Vector2.ONE*.75)
		owner_prop.draw_symbol(self,owner_prop.hat_id,Vector2.ZERO,Color("e9dfb0"),3)
		draw_set_transform(Vector2.ZERO)
static func symbol_paths(id:String)->Array:
	match id:
		"entrance":return [[Vector2(-17,16),Vector2(-17,-16),Vector2(17,-16),Vector2(17,16)]]
		"stairs":return [[Vector2(-18,16),Vector2(-18,6),Vector2(-6,6),Vector2(-6,-5),Vector2(6,-5),Vector2(6,-16),Vector2(18,-16)]]
		_:return [[Vector2(-15,-16),Vector2(-15,16)],[Vector2(0,-16),Vector2(0,16)],[Vector2(15,-16),Vector2(15,16)]]
static func draw_symbol(canvas:CanvasItem,id:String,center:Vector2,color:Color,width:=3.0,reference:=false,angle:=0.0,mirror:=1.0)->void:
	for path:Array in symbol_paths(id):
		for i in range(path.size()-1):
			var a:Vector2=center+Vector2(path[i].x*mirror,path[i].y).rotated(angle)
			var b:Vector2=center+Vector2(path[i+1].x*mirror,path[i+1].y).rotated(angle)
			if reference:canvas.draw_dashed_line(a,b,color,width,5)
			else:canvas.draw_line(a,b,color,width,true)
