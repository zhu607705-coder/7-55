extends Node2D
## Presentation only. Accepted controller facts choose the layers and outcome.
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
	_poly(self,"CupContactShadow",[Vector2(-49,2),Vector2(-36,-2),Vector2(36,-2),Vector2(49,2),Vector2(36,6),Vector2(-36,6)],Color(0,0,0,.22))
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
	base_sequence=sequence.duplicate();shown_sequence=base_sequence.duplicate();playing=false;outcome="";denied=false;elapsed_ms=0;_pose()
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
	duration_ms=(220.0 if reduced else 600.0) if not outcome.is_empty() else (140.0 if reduced else 420.0)
	elapsed_ms=0;playing=true;observed_accepts+=1;_pose();return true
func reject(ingredient:String,reduced_value:bool)->void:
	item_id=ingredient;reduced=reduced_value;denied=true;outcome="";shown_sequence=base_sequence.duplicate();duration_ms=100 if reduced else 260;elapsed_ms=0;playing=true;_pose()
func _process(delta:float)->void:
	if not playing:return
	elapsed_ms=minf(duration_ms,elapsed_ms+maxf(delta,0)*1000)
	if elapsed_ms>=duration_ms:playing=false;denied=false;outcome="";shown_sequence=base_sequence.duplicate()
	_pose()
func sample_pose(ms:float)->void:
	elapsed_ms=clampf(ms,0,duration_ms);_pose()
func _color(id:String)->Color:
	var value:int=Source.COLORS.get(id,0x758b83);return Color((value>>16&255)/255.0,(value>>8&255)/255.0,(value&255)/255.0,.92)
func _pose()->void:
	if glass_root==null:return
	var t:=clampf(elapsed_ms/maxf(1,duration_ms),0,1)
	var poured:=smoothstep(.25,.68,t) if playing and not denied else 1.0
	var reaction:=sin(clampf((t-.33)/.67,0,1)*PI) if playing and not outcome.is_empty() else 0.0
	var lift:float=0.0
	glass_root.position=Vector2.ZERO;glass_root.scale=Vector2.ONE
	for i in range(liquid_parts.size()):
		var layer:Polygon2D=liquid_parts[i];layer.visible=i<shown_sequence.size()
		if not layer.visible:continue
		var amount:float=poured if playing and not denied and i==shown_sequence.size()-1 else 1.0
		var height:=40.0*amount;var bottom:float=-7-i*43.0
		var wave:float=0 if reduced or not playing or denied else sin(t*TAU*2+i)*4*(1-t)
		layer.polygon=PackedVector2Array([Vector2(-40,bottom),Vector2(-40,bottom-height+wave),Vector2(-14,bottom-height-wave*.55),Vector2(14,bottom-height+wave*.55),Vector2(40,bottom-height-wave),Vector2(40,bottom)])
		layer.color=_color(str(shown_sequence[i]))
	bottle.visible=playing and (denied or t<.96)
	if bottle.visible:
		var entry:=smoothstep(0,.25,t);var leave:=smoothstep(.68,.96,t)
		bottle.position=pour_origin.lerp(Vector2(-9,-164),entry).lerp(pour_origin,leave) if not reduced else Vector2(-9,-164)
		bottle.rotation=lerp_angle(PI,-PI/2,entry*(1-leave)) if not reduced else -PI/2
		if denied:bottle.rotation=PI+.18*sin(t*PI)*(0 if reduced else 1);bottle.position=pour_origin
		bottle.modulate.a=(1-smoothstep(.78,.96,t)) if not denied else .42
		bottle_body.color=_color(item_id);bottle_cap.visible=denied;_sync_bottle_art()
	stream.visible=playing and not denied and t>.25 and t<.68
	if stream.visible:
		var end_y:float=-7-(shown_sequence.size()-1)*43-40*poured
		stream.polygon=PackedVector2Array([Vector2(-12,-164),Vector2(-6,-164),Vector2(3,end_y),Vector2(-3,end_y)])
		stream.color=_color(item_id)
	for i in range(foam.size()):
		var part:=foam[i];part.visible=playing and outcome=="bad" and t>.34 and t<.95
		part.position=Vector2(-36+i*18,-145+reaction*4)
		part.scale=Vector2(1,1+reaction*(.15 if reduced else 1.4));part.modulate.a=1-smoothstep(.74,.95,t)
	for i in range(motes.size()):
		var part:=motes[i];part.visible=playing and not denied and t>.2 and t<.9
		var rise:float=(i+1)/4.0 if reduced else fmod(t*1.4+i*.17,1.0)
		var spread:float=22 if outcome=="bad" else 1
		part.position=Vector2(-34+(i%5)*17+sin(i*2.3)*reaction*spread,-12-rise*128+lift)
		if outcome=="bad":part.position.y=-145+pow(reaction,2)*i*3;part.color=Color("a1b896")
		else:part.color=Color("e3f8e5")
		part.scale=Vector2.ONE*(1+reaction if outcome=="success" else 1)
		part.modulate.a=(.65 if reduced else .8)*(1-smoothstep(.7,.9,t));part.visible=part.visible and (not reduced or i<3)
