extends Node2D
## Presentation only. Accepted controller facts choose the layers and outcome.
signal presentation_finished
var hold_terminal_result:=false
# Local presentation clock. Does not change Engine.time_scale or controller input.
const PLAYBACK_RATE: float = 0.75
const Press=preload("res://scripts/presentation/drink_machine_press.gd")
const DISPENSER=preload("res://assets/native/canteen_objects/canteen_drink_dispenser.png")
const Paddle=preload("res://scripts/presentation/drink_cup_paddle.gd")
const NOZZLE_OUTLET:=Vector2(0,-178)
const CUP_HOME:=Vector2(68,0)
const REST_ANGLE:float=-0.42
const PRESSED_ANGLE:float=0.22
const CONTACT_BEGIN:float=0.16
const PRESS_END:float=0.28
const FLOW_BEGIN:float=0.30
const FLOW_END:float=0.65
const DRIP_END:float=0.76
const REBOUND_END:float=0.88
const RETURN_END:float=0.96
const PADDLE_PIVOT:=Vector2(-38.353425,-181) # Visible pad rim meets bright glass wall in the held pose.
var paddle_root:Node2D
var paddle:Sprite2D
var cup_shadow:Polygon2D
var cup_home:=CUP_HOME
var cup_start:=CUP_HOME
var cup_return:=CUP_HOME
var nozzle:Sprite2D
var drip:Polygon2D
const Source=preload("res://scripts/presentation/c3_mixer_session.gd")
var base_sequence:Array=[]
var shown_sequence:Array=[]
var pour_origin:=Vector2(-86,-152)
var item_id:=""
var outcome:=""
var playing:=false
var denied:=false
var reduced:=false
var elapsed_ms:=0.0
var duration_ms:=420.0
var glass_root:Node2D
var glass_back:Polygon2D
var liquid_parts:Array[Polygon2D]=[]
var glass_edge:Line2D
var rim:Line2D
var bottle:Node2D
var bottle_body:Polygon2D
var bottle_cap:Polygon2D
var stream:Polygon2D
var foam:Array[Polygon2D]=[]
var motes:Array[Polygon2D]=[]
var observed_accepts:=0
var component_data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/native/mixer/components.json")).components
var glass_sprite:Sprite2D
var bottle_sprite:Sprite2D
var cap_sprite:Sprite2D
var glass_mask:Polygon2D
var current_art_id:String=""
const BOTTLE_HEIGHT:float=100.0
func _ready()->void:
	_build();_pose()
func _poly(parent:Node,name_value:String,points:Array,color:Color)->Polygon2D:
	var p:=Polygon2D.new();p.name=name_value;p.polygon=PackedVector2Array(points);p.color=color;p.antialiased=false;parent.add_child(p);return p
func _line(parent:Node,name_value:String,points:Array,color:Color,width:float)->Line2D:
	var line:=Line2D.new();line.name=name_value;line.points=PackedVector2Array(points);line.default_color=color;line.width=width;line.antialiased=false;parent.add_child(line);return line
func _build()->void:
	if glass_root!=null:return
	cup_shadow=_poly(self,"CupContactShadow",[Vector2(-49,2),Vector2(-36,-2),Vector2(36,-2),Vector2(49,2),Vector2(36,6),Vector2(-36,6)],Color(0,0,0,.22))
	paddle_root=Node2D.new();paddle_root.name="FixedHinge";paddle_root.position=PADDLE_PIVOT;add_child(paddle_root)
	paddle=Paddle.sprite();paddle_root.add_child(paddle)
	glass_root=Node2D.new();glass_root.name="GlassBody";add_child(glass_root)
	glass_back=_poly(glass_root,"GlassBack",[Vector2(-49,-148),Vector2(-42,0),Vector2(42,0),Vector2(49,-148)],Color("badbe4",.16))
	glass_mask=_poly(glass_root,"GlassInteriorMask",[Vector2(-43,-141),Vector2(43,-141),Vector2(37,-6),Vector2(-37,-6)],Color.WHITE)
	glass_mask.clip_children=CanvasItem.CLIP_CHILDREN_ONLY
	for i in range(3):liquid_parts.append(_poly(glass_mask,"IngredientLayer"+str(i),[],Color.WHITE))
	glass_edge=_line(glass_root,"GlassEdge",[Vector2(-50,-150),Vector2(-42,0),Vector2(42,0),Vector2(50,-150)],Color("b7e1e7"),4)
	rim=_line(glass_root,"GlassRim",[Vector2(-50,-150),Vector2(50,-150)],Color("e8f4e6"),3)
	_line(glass_root,"GlassHighlight",[Vector2(-38,-137),Vector2(-33,-17)],Color("e4f2e8",.5),3)
	stream=_poly(self,"PourStream",[],Color.WHITE)
	bottle=Node2D.new();bottle.name="PouringBottle";add_child(bottle)
	bottle_body=_poly(bottle,"BottleBody",[Vector2(-6,0),Vector2(-6,-15),Vector2(-15,-25),Vector2(-15,-69),Vector2(-11,-75),Vector2(11,-75),Vector2(15,-69),Vector2(15,-25),Vector2(6,-15),Vector2(6,0)],Color.WHITE)
	_poly(bottle,"BottleShine",[Vector2(-10,-64),Vector2(-6,-64),Vector2(-6,-28),Vector2(-10,-31)],Color("f8f4dc",.48))
	bottle_cap=_poly(bottle,"BottleCap",[Vector2(-9,-4),Vector2(9,-4),Vector2(9,2),Vector2(-9,2)],Color("d6c88a"))
	for i in range(5):foam.append(_poly(glass_root,"Foam"+str(i),[Vector2(-9,-4),Vector2(-9,-10),Vector2(-4,-10),Vector2(-4,-14),Vector2(4,-14),Vector2(4,-10),Vector2(9,-10),Vector2(9,-4)],Color("d8ded1")))
	for i in range(10):motes.append(_poly(self,"Bubble"+str(i),[Vector2(-2,-2),Vector2(2,-2),Vector2(2,2),Vector2(-2,2)],Color("e7f5db")))
	_install_rgba_art()
	nozzle=_sprite(self,"FixedMachineNozzle")
	nozzle.texture=DISPENSER;nozzle.region_rect=Rect2(586,790,84,100)
	nozzle.scale=Vector2.ONE*.38;nozzle.position=NOZZLE_OUTLET-Vector2(84*.38/2,100*.38)
	drip=_poly(self,"OutletLastDrop",[Vector2(0,-3),Vector2(2,0),Vector2(0,3),Vector2(-2,0)],Color.WHITE)
func _sprite(parent:Node,part:String)->Sprite2D:
	var node:=Sprite2D.new();node.name=part;node.centered=false;node.region_enabled=true;node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;parent.add_child(node);return node
func _region_data(id:String)->Rect2:
	var values:Array=component_data[id].region;return Rect2(values[0],values[1],values[2],values[3])
func _install_rgba_art()->void:
	glass_back.modulate.a=0;glass_edge.hide();rim.hide();glass_root.get_node("GlassHighlight").hide()
	glass_sprite=_sprite(glass_root,"OriginalGlassRGBA")
	glass_sprite.texture=load(component_data.glass.path);glass_sprite.region_rect=_region_data("glass")
	var factor:float=150.0/glass_sprite.region_rect.size.y
	glass_sprite.scale=Vector2.ONE*factor;glass_sprite.position=Vector2(-glass_sprite.region_rect.size.x*factor/2,-150)
	for node in bottle.get_children():
		if node is CanvasItem:node.modulate.a=0
	bottle_sprite=_sprite(bottle,"OriginalBottleBodyRGBA");cap_sprite=_sprite(bottle,"OriginalCapRGBA")
func _sync_bottle_art()->void:
	if not component_data.has(item_id) or bottle_sprite==null:return
	if current_art_id!=item_id:
		current_art_id=item_id
		var data:Dictionary=component_data[item_id];var rect:Rect2=_region_data(item_id);var cap:float=float(data.cap_pixels)
		var factor:float=BOTTLE_HEIGHT/rect.size.y;var half_width:float=rect.size.x*factor/2
		bottle_sprite.texture=load(data.path);bottle_sprite.region_rect=Rect2(rect.position+Vector2(0,cap),rect.size-Vector2(0,cap));bottle_sprite.position=Vector2(half_width,0);bottle_sprite.rotation=PI;bottle_sprite.scale=Vector2.ONE*factor
		cap_sprite.texture=bottle_sprite.texture;cap_sprite.region_rect=Rect2(rect.position,Vector2(rect.size.x,cap));cap_sprite.position=Vector2(half_width,cap*factor);cap_sprite.rotation=PI;cap_sprite.scale=Vector2.ONE*factor
	var t:float=clampf(elapsed_ms/maxf(1.0,duration_ms),0.0,1.0)
	var part:Dictionary=component_data[item_id];var rect:Rect2=_region_data(item_id)
	var factor:float=BOTTLE_HEIGHT/rect.size.y;var cap_height:float=float(part.cap_pixels)*factor
	var opening:float=0.0 if denied else smoothstep(0.0,0.18,t)
	cap_sprite.position=Vector2(rect.size.x*factor/2,cap_height+10.0*opening)
	cap_sprite.modulate.a=1.0-opening
	cap_sprite.visible=denied or (not reduced and t<0.18)

func set_sequence(sequence:Array)->void:
	base_sequence=sequence.duplicate()
	if not playing:shown_sequence=base_sequence.duplicate()
	_pose()
func reset(sequence:Array=[])->void:
	base_sequence=sequence.duplicate();shown_sequence=base_sequence.duplicate();playing=false;outcome="";denied=false;elapsed_ms=0;cup_home=CUP_HOME;cup_start=CUP_HOME;cup_return=CUP_HOME;_pose()
func accept(action:String,before:Dictionary,next:Dictionary,result:Dictionary={})->bool:
	if not action.begins_with("c3_mix:"):return false
	var ingredient:=action.trim_prefix("c3_mix:")
	if not Source.COLORS.has(ingredient):return false
	var previous:Dictionary=before.get("canteenHunt",{});var current:Dictionary=next.get("canteenHunt",{})
	var consumed:bool=bool(before.get("items",{}).get(ingredient,false)) and not bool(next.get("items",{}).get(ingredient,false))
	var attempt_delta:int=int(current.get("drinkMixAttemptCount",0))-int(previous.get("drinkMixAttemptCount",0))
	var grew:bool=current.get("drinkMixSequence",[]).size()==previous.get("drinkMixSequence",[]).size()+1
	if not consumed or (not grew and attempt_delta!=1):return false
	reduced=bool(next.get("native",{}).get("settings",{}).get("reduced_motion",false));item_id=ingredient;denied=false;outcome=""
	base_sequence=current.get("drinkMixSequence",[]).duplicate();shown_sequence=previous.get("drinkMixSequence",[]).duplicate();shown_sequence.append(ingredient)
	if attempt_delta==1:
		var drinks:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter3-canteen.content.json")).drinks
		if str(result.get("message",""))==str(drinks.correctMix):outcome="success"
		elif str(result.get("message",""))==str(drinks.wrongMix):outcome="bad"
		elif not bool(before.items.get("dailySpecialSparklingWater",false)) and bool(next.items.get("dailySpecialSparklingWater",false)):outcome="success"
		elif not bool(before.items.get("badDrink",false)) and bool(next.items.get("badDrink",false)):outcome="bad"
		else:outcome="complete" # The renderer never guesses the recipe.
	duration_ms=(220.0 if reduced else 1350.0) if not outcome.is_empty() else (140.0 if reduced else 1050.0)
	cup_start=glass_root.position;cup_return=cup_start if reduced else CUP_HOME
	elapsed_ms=0;playing=true;observed_accepts+=1;_pose();return true
func reject(ingredient:String,reduced_value:bool)->void:
	item_id=ingredient;reduced=reduced_value;denied=true;outcome="";shown_sequence=base_sequence.duplicate();duration_ms=100 if reduced else 260;elapsed_ms=0;playing=true;_pose()
func _process(delta:float)->void:
	if not playing:return
	elapsed_ms=minf(duration_ms,elapsed_ms+maxf(delta,0)*1000*PLAYBACK_RATE)
	if elapsed_ms>=duration_ms:
		cup_home=cup_return;playing=false;denied=false
		if not hold_terminal_result or outcome.is_empty():
			outcome="";shown_sequence=base_sequence.duplicate()
		_pose()
		presentation_finished.emit()
		return
	_pose()
func sample_pose(ms:float)->void:
	elapsed_ms=clampf(ms,0,duration_ms);_pose()
func _color(id:String)->Color:
	var value:int=Source.COLORS.get(id,0x758b83);return Color((value>>16&255)/255.0,(value>>8&255)/255.0,(value&255)/255.0,.92)
func _pose()->void:
	if glass_root==null:return
	var t:=clampf(elapsed_ms/maxf(1,duration_ms),0,1)
	var poured:=smoothstep(FLOW_BEGIN,FLOW_END,t) if playing and not denied else 1.0
	var reaction:=sin(clampf((t-.33)/.67,0,1)*PI) if playing and not outcome.is_empty() else 0.0
	var lift:float=0.0
	_pose_contact(t)
	glass_root.scale=Vector2.ONE
	cup_shadow.position=glass_root.position
	for i in range(liquid_parts.size()):
		var layer:Polygon2D=liquid_parts[i];layer.visible=i<shown_sequence.size()
		if not layer.visible:continue
		var amount:float=poured if playing and not denied and i==shown_sequence.size()-1 else 1.0
		var height:=40.0*amount;var bottom:float=-7-i*43.0
		var wave:float=0 if reduced or not playing or denied else sin(t*TAU*2+i)*4*(1-t)
		layer.polygon=PackedVector2Array([Vector2(-40,bottom),Vector2(-40,bottom-height+wave),Vector2(-14,bottom-height-wave*.55),Vector2(14,bottom-height+wave*.55),Vector2(40,bottom-height-wave),Vector2(40,bottom)])
		layer.color=_color(str(shown_sequence[i]))
	# The nozzle and hinge stay fixed. Only a contacting cup opens the valve.
	bottle.hide()
	stream.visible=playing and not denied and not reduced and t>=FLOW_BEGIN and t<FLOW_END and cup_contact_error()<0.05
	if stream.visible:
		var end_y:float=-7-(shown_sequence.size()-1)*43-40*poured
		stream.polygon=PackedVector2Array([NOZZLE_OUTLET+Vector2(-3,0),NOZZLE_OUTLET+Vector2(3,0),Vector2(3,end_y),Vector2(-3,end_y)])
		stream.color=_color(item_id)
	drip.visible=playing and not denied and not reduced and t>=FLOW_END and t<DRIP_END
	if drip.visible:
		var surface_y:float=-7-(shown_sequence.size()-1)*43-40
		drip.position=NOZZLE_OUTLET.lerp(Vector2(0,surface_y),clampf((t-FLOW_END)/(DRIP_END-FLOW_END),0,1))
		drip.color=_color(item_id)
	for i in range(foam.size()):
		var part:=foam[i];part.visible=playing and outcome=="bad" and t>.34 and t<.95
		part.position=Vector2(-36+i*18,-145+reaction*4)
		part.scale=Vector2(1,1+reaction*(.15 if reduced else 1.4));part.modulate.a=1-smoothstep(.74,.95,t)
	for i in range(motes.size()):
		var part:=motes[i];part.visible=playing and not denied and t>.2 and t<.9
		var rise:float=(i+1)/4.0 if reduced else fmod(t*1.4+i*.17,1.0)
		var spread:float=22 if outcome=="bad" else 1
		part.position=glass_root.position+Vector2(-34+(i%5)*17+sin(i*2.3)*reaction*spread,-12-rise*128+lift)
		if outcome=="bad":part.position.y=-145+pow(reaction,2)*i*3;part.color=Color("a1b896")
		else:part.color=Color("e3f8e5")
		part.scale=Vector2.ONE*(1+reaction if outcome=="success" else 1)
		part.modulate.a=(.65 if reduced else .8)*(1-smoothstep(.7,.9,t));part.visible=part.visible and (not reduced or i<3)

# Contact is the right edge of the generated paddle against the original glass's
# left wall. During push, cup x is solved from that shared point, not eyeballed.
static func cup_wall_x(y:float)->float:
	return -37.8+clampf(y,-150.0,0.0)*7.0/150.0
func paddle_contact()->Vector2:
	return PADDLE_PIVOT+Paddle.CONTACT_LOCAL.rotated(paddle_root.rotation)
func cup_contact_error()->float:
	var c:=paddle_contact()
	return absf(c.x-(glass_root.position.x+cup_wall_x(c.y-glass_root.position.y)))
func _contact_cup(angle:float)->Vector2:
	var c:=PADDLE_PIVOT+Paddle.CONTACT_LOCAL.rotated(angle)
	return Vector2(c.x-cup_wall_x(c.y),0)
func _pose_contact(t:float)->void:
	paddle_root.rotation=REST_ANGLE
	glass_root.position=cup_home
	if not playing or denied or reduced:return
	var first:=_contact_cup(REST_ANGLE)
	var held:=_contact_cup(PRESSED_ANGLE)
	if t<CONTACT_BEGIN:
		glass_root.position=cup_start.lerp(first,smoothstep(0,CONTACT_BEGIN,t))
	elif t<PRESS_END:
		paddle_root.rotation=lerpf(REST_ANGLE,PRESSED_ANGLE,smoothstep(CONTACT_BEGIN,PRESS_END,t))
		glass_root.position=_contact_cup(paddle_root.rotation)
	elif t<FLOW_END:
		paddle_root.rotation=PRESSED_ANGLE;glass_root.position=held
	else:
		paddle_root.rotation=lerpf(PRESSED_ANGLE,REST_ANGLE,smoothstep(DRIP_END,REBOUND_END,t))
		# Move only 12 px while the final drop falls, keeping the mouth beneath it.
		if t<DRIP_END:glass_root.position=held.lerp(Vector2(12,0),smoothstep(FLOW_END,DRIP_END,t))
		elif t<REBOUND_END:
			var clearance:float=lerpf(12.0,3.0,smoothstep(DRIP_END,REBOUND_END,t))
			glass_root.position=_contact_cup(paddle_root.rotation)+Vector2(clearance,0)
		else:glass_root.position=_contact_cup(REST_ANGLE).lerp(cup_return-Vector2(3,0),smoothstep(REBOUND_END,RETURN_END,t))+Vector2(3,0)
func stage_next_cup()->void:
	# An accepted queued ingredient need not send the glass all the way out.
	if playing and not reduced and elapsed_ms<duration_ms*FLOW_END:cup_return=_contact_cup(REST_ANGLE)+Vector2(3,0)
func press_frame()->int:
	# Top controls select a flavor only; the cup-actuated lever opens the valve.
	return 0
