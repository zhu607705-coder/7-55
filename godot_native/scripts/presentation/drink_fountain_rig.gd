extends Node2D
## Three independent source-colored outlets. Paddle pixels undergo a rigid 3D
## hinge projection; there is no image-plane lever rotation or moving nozzle.
const BODY_PATH="res://assets/native/canteen_animation/drink_fountain_body.png"
const PADDLE_PATH="res://assets/native/canteen_animation/drink_fountain_paddle.png"
const BODY=preload(BODY_PATH)
const PADDLE=preload(PADDLE_PATH)
const SOURCE_ORIGIN:=Vector2(768,800)
const BODY_SCALE:float=0.4
const BODY_REGION:=Rect2(240,60,1040,900)
const BOUNDS:=Rect2(-211.2,-296,416,360)
const OUTLET_X=[-94.8,-5.2,94.0]
const OUTLET_Y:float=-162.4
const HINGE_Y:float=-159.2
const SELECTOR_REGIONS=[Rect2(482,145,90,88),Rect2(706,145,92,88),Rect2(945,145,91,88)]
const PADDLE_REGION:=Rect2(484,250,568,714)
const IMAGE_HINGE:=Vector2(768,260)
const IMAGE_CONTACT:=Vector2(768,704)
const PADDLE_SCALE:float=0.1
const LEVER_LENGTH:float=44.4
const REST_ANGLE:float=0.55
const PRESSED_ANGLE:float=-0.12
const DEPTH_AXIS:=Vector2(-0.22,0.4)
const HOME_DEPTH:float=120.0
const CUP_RADIUS:float=(346.0/557.0)*120.0/2.0
const FLOOR_BACK_Y:float=-60.0
const TRAY_SOURCE_POLYGON=[Vector2(446,660),Vector2(1135,678),Vector2(1113,788),Vector2(271,767)]
const CUP_BASE_SCALE:float=120.0/150.0
var body:Sprite2D
var selectors:Array[Sprite2D]=[]
var nozzles:Array[Node2D]=[]
var pivots:Array[Node2D]=[]
var paddles:Array[Polygon2D]=[]
var angles:Array[float]=[REST_ANGLE,REST_ANGLE,REST_ANGLE]
static func matte()->ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type canvas_item;
varying vec4 vertex_color;
void vertex(){vertex_color=COLOR;}
void fragment(){vec4 c=texture(TEXTURE,UV);if(c.a<0.70){discard;}COLOR=vec4(c.rgb,c.a)*vertex_color;}
"""
	var m:=ShaderMaterial.new();m.shader=shader;return m
func _ready()->void:
	body=Sprite2D.new();body.name="FixedThreeOutletBody";body.texture=BODY;body.centered=false;body.region_enabled=true;body.region_rect=BODY_REGION
	body.position=(BODY_REGION.position-SOURCE_ORIGIN)*BODY_SCALE;body.scale=Vector2.ONE*BODY_SCALE;body.material=matte();add_child(body)
	for i in range(3):
		var selector:=Sprite2D.new();selector.name="FlavorSelector"+str(i);selector.texture=BODY;selector.centered=false;selector.region_enabled=true;selector.region_rect=SELECTOR_REGIONS[i]
		selector.position=(SELECTOR_REGIONS[i].position-SOURCE_ORIGIN)*BODY_SCALE;selector.scale=Vector2.ONE*BODY_SCALE
		add_child(selector);selectors.append(selector)
		var nozzle:=Node2D.new();nozzle.name="FixedOutlet"+str(i);nozzle.position=Vector2(OUTLET_X[i],OUTLET_Y);add_child(nozzle);nozzles.append(nozzle)
		var pivot:=Node2D.new();pivot.name="HorizontalDepthHinge"+str(i);pivot.position=Vector2(OUTLET_X[i],HINGE_Y);add_child(pivot);pivots.append(pivot)
		var paddle:=Polygon2D.new();paddle.name="ForwardCupPaddle"+str(i);paddle.texture=PADDLE;paddle.material=matte();paddle.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		paddle.uv=PackedVector2Array([PADDLE_REGION.position,Vector2(PADDLE_REGION.end.x,PADDLE_REGION.position.y),PADDLE_REGION.end,Vector2(PADDLE_REGION.position.x,PADDLE_REGION.end.y)])
		pivot.add_child(paddle);paddles.append(paddle);set_angle(i,REST_ANGLE)
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
static func selector_center(index:int)->Vector2:
	return (SELECTOR_REGIONS[index].get_center()-SOURCE_ORIGIN)*BODY_SCALE
static func project_lever(point:Vector2,angle:float)->Vector2:
	var q:Vector2=(point-IMAGE_HINGE)*PADDLE_SCALE
	var z:float=q.y*sin(angle)
	return Vector2(q.x,q.y*cos(angle))+DEPTH_AXIS*z
static func contact_depth(angle:float)->float:
	return LEVER_LENGTH*sin(angle)+CUP_RADIUS
static func cup_scale(depth:float)->float:
	return CUP_BASE_SCALE*(0.93+0.07*clampf(depth/HOME_DEPTH,0.0,1.0))
static func cup_screen(lateral:float,depth:float)->Vector2:
	return Vector2(lateral,FLOOR_BACK_Y)+DEPTH_AXIS*depth
func set_angle(index:int,angle:float)->void:
	angles[index]=angle
	var points:=PackedVector2Array()
	for point:Vector2 in paddles[index].uv:points.append(project_lever(point,angle))
	paddles[index].polygon=points
func projected_contact(index:int)->Vector2:
	return pivots[index].position+project_lever(IMAGE_CONTACT,angles[index])
func set_color(index:int,color:Color,owned:bool=true)->void:
	# Neutral generated insert keeps the original bezel and texture. Brighten
	# only this independent gray insert before applying its source ingredient.
	selectors[index].modulate=Color(color.r*2.6,color.g*2.6,color.b*2.6,1.0 if owned else 0.28)
