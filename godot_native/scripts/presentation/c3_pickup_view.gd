extends RefCounted
## The pickup film paints the same registered furniture and source actors. It
## holds a private presentation snapshot; the controller already owns exit_blocking.
const Timeline=preload("res://scripts/presentation/c3_pickup_timeline.gd")
const PaperArt=preload("res://scripts/presentation/c3_paper_art.gd")
const Layers=preload("res://scripts/ui/chapter3_world_layers.gd")
var furniture:Node2D
var crowd:RefCounted
var snapshot:Dictionary={}
var start_clock:=0.0
var textures:Dictionary={}
var font:Font
var background:Texture2D
var reduced:=false
var start_player:=Vector2(790,260)
var start_camera:=Vector2(790,260)
var start_zoom:=1.0
var _origin:=Vector2.ZERO
var _zoom:=1.0
func configure(scene:Node2D,layers:RefCounted,state:Dictionary,player:Vector2,camera:Vector2,zoom:float)->void:
	furniture=scene;start_player=player;start_camera=camera;start_zoom=zoom
	snapshot=state.duplicate(true)
	if not snapshot.is_empty():
		# Render-only copy restores the actors removed by the accepted phase change.
		# Never change State.d, collision bodies, inventory, sessions or the model.
		snapshot.canteenHunt.phase="pickup_search"
		crowd=Layers.new();crowd.sync(snapshot,true)
		start_clock=float(layers.clock_ms) if layers!=null else 0.0
		crowd.light_alpha=1;crowd.shadow_alpha=0
		reduced=bool(snapshot.native.settings.get("reduced_motion",false))
	font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	background=_texture("res://assets/rpg/interiors/canteen_interior.png")
func pose(milliseconds:float)->Dictionary:return Timeline.sample(milliseconds,reduced,start_player,start_camera,start_zoom)
func _texture(path:String)->Texture2D:
	if not textures.has(path):textures[path]=load(path)
	return textures[path]
func _transform(canvas:CanvasItem)->void:canvas.draw_set_transform(_origin,0,Vector2.ONE*_zoom)
func actor_entries(milliseconds:float)->Array:
	if crowd==null or milliseconds>=8040:return []
	crowd.clock_ms=start_clock+milliseconds
	return crowd.entries(snapshot).filter(func(e:Dictionary)->bool:return e.kind=="sprite" and not str(e.id).begins_with("promo") and not str(e.id).begins_with("queue_prompt"))
func shadow_frame(milliseconds:float)->int:
	if reduced:return 0
	var sequence:=[0,0,1,0,0,0,2]
	return sequence[mini(6,int(fmod(start_clock+milliseconds,1780)/(1000.0/7)))]
func _sheet(canvas:CanvasItem,path:String,point:Vector2,frame:int,frame_size:Vector2,columns:int,factor:float,anchor:Vector2=Vector2(.5,.5),alpha:float=1)->void:
	var tex:=_texture(path)
	canvas.draw_texture_rect_region(tex,Rect2(point-frame_size*factor*anchor,frame_size*factor),Rect2(Vector2((frame%columns)*frame_size.x,int(frame/columns)*frame_size.y),frame_size),Color(1,1,1,alpha))
func _actor(canvas:CanvasItem,e:Dictionary)->void:
	var tex:Texture2D=_texture(e.asset)
	if tex==null:return
	var frame_size:Vector2=e.get("frameSize",tex.get_size())
	_sheet(canvas,e.asset,e.point,int(e.get("frame",0)),frame_size,maxi(1,int(tex.get_width()/frame_size.x)),float(e.get("scale",1)),e.get("anchor",Vector2(.5,.5)),float(e.get("alpha",1)))
func _room(canvas:CanvasItem,milliseconds:float)->void:
	var entries:=actor_entries(milliseconds)
	if milliseconds<2630:
		entries.append({"id":"pickup_shadow","sort_y":214.01,"kind":"sprite","asset":"res://assets/rpg/npcs/canteen/shadow_auntie_3frame.png","point":Vector2(790,214),"frameSize":Vector2(96,128),"frame":shadow_frame(milliseconds),"scale":.65,"anchor":Vector2(.5,1),"alpha":.68})
	if not is_instance_valid(furniture):
		if background!=null:canvas.draw_texture_rect(background,Rect2(Vector2.ZERO,Timeline.ROOM),false)
		for e:Dictionary in entries:_actor(canvas,e)
		return
	canvas.draw_texture_rect_region(furniture.textures.empty_floor,Rect2(11,1,1659,940),Rect2(11,1,1659,940))
	for opening:Dictionary in furniture.layout.get("floor_openings",[]):
		var src:Array=opening.source;var dst:Array=opening.destination
		canvas.draw_texture_rect_region(furniture.textures.empty_floor,Rect2(dst[0],dst[1],dst[2],dst[3]),Rect2(src[0],src[1],src[2],src[3]))
	var actor_planes:Array=[]
	for e:Dictionary in entries:
		var tex:Texture2D=_texture(e.asset)
		var dimensions:Vector2=e.get("frameSize",tex.get_size())*float(e.get("scale",1))
		actor_planes.append({"depth":float(e.get("sort_y",e.point.y)),"rect":Rect2(e.point-dimensions*e.get("anchor",Vector2(.5,.5)),dimensions)})
	actor_planes=furniture.with_supported_planes(actor_planes)
	var ordered:Array=[]
	for prop:Node2D in furniture.objects.values():
		if prop.definition.get("decorative_cart",false):continue
		for part:Dictionary in prop.depth_slices(actor_planes):
			ordered.append({"kind":"furniture","depth":float(part.depth),"entry":{"object":prop,"part":part}})
	for e:Dictionary in entries:ordered.append({"kind":"actor","depth":float(e.get("sort_y",e.point.y)),"entry":e})
	for feature:Array in [["pickup_slots",244.0],["drink_screens",230.0],["mixer",818.0]]:
		ordered.append({"kind":"feature","depth":feature[1],"role":feature[0]})
	ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.depth<b.depth)
	for item:Dictionary in ordered:
		if item.kind=="actor":_actor(canvas,item.entry)
		elif item.kind=="feature":furniture.draw_feature(canvas,item.role,true)
		else:
			var prop:Node2D=item.entry.object;var part:Dictionary=item.entry.part
			if prop.definition.has("door"):
				canvas.draw_rect(Rect2(prop.position+prop.top_left,prop.dimensions),Color("172020"));continue
			canvas.draw_texture_rect_region(prop.texture,Rect2(prop.position+part.position,part.region.size*prop.scale_value),part.region)
		_transform(canvas)
func draw(canvas:CanvasItem,viewport:Rect2,p:Dictionary)->void:
	var fit:=minf(viewport.size.x/960,viewport.size.y/540)
	# Native exploration already measures zoom in viewport pixels, including
	# portrait. Preserve that entrance scale; fit only the source full-room end.
	_zoom=float(p.zoom)
	if float(p.elapsed)>=8040:
		var pull:=sin(clampf((float(p.elapsed)-8040)/850,0,1)*PI/2)
		_zoom=lerpf(1.42,Timeline.FULL_ZOOM*fit,pull)
	_origin=viewport.get_center()-Vector2(p.camera)*_zoom+Vector2(p.shake)
	_transform(canvas);_room(canvas,float(p.elapsed))
	if p.glow_alpha>0:canvas.draw_circle(Timeline.WINDOW+Vector2(0,10),46,Color(.54,.90,1,.14*float(p.glow_alpha)))
	if p.ticket_visible:
		var z:float=_zoom*float(p.ticket_scale)
		canvas.draw_set_transform(_origin+Vector2(p.ticket_position)*_zoom,0,Vector2.ONE*z)
		canvas.draw_rect(Rect2(-22,-10.5,48,27),Color(.03,.07,.10,.42*float(p.ticket_alpha)))
		canvas.draw_rect(Rect2(-24,-13.5,48,27),Color("e9e6d8",p.ticket_alpha))
		canvas.draw_rect(Rect2(-24,-13.5,48,27),Color("36789b",p.ticket_alpha),false,2)
		if font:canvas.draw_string(font,Vector2(-22,5),"0755",HORIZONTAL_ALIGNMENT_CENTER,44,13,Color("234d67",p.ticket_alpha))
		_transform(canvas)
	if p.auntie_visible:_sheet(canvas,"res://assets/rpg/canteen/pickup-cutscene/shadow_auntie_push_5frame.png",Timeline.WINDOW+Vector2(0,30),p.auntie_frame,Vector2(96,128),5,.68,Vector2(.5,1),p.auntie_alpha)
	if p.package_visible:
		_sheet(canvas,"res://assets/rpg/canteen/pickup-cutscene/paper_chicken_shake_5frame.png",Timeline.WINDOW+Vector2(0,8),p.package_frame,Vector2(64,80),5,.62,Vector2(.5,1))
		_sheet(canvas,"res://assets/rpg/canteen/promo/canteen_promo_fx_3x2.png",Timeline.WINDOW+Vector2(17,-26),p.bubble_frame,Vector2(48,48),3,.38)
	if p.burst_visible:_sheet(canvas,"res://assets/rpg/canteen/pickup-cutscene/paper_chicken_burst_8frame.png",Timeline.WINDOW+Vector2(0,8),p.burst_frame,Vector2(96,96),4,1.18)
	_particles(canvas,float(p.elapsed))
	if p.cart_alpha>0:_sheet(canvas,"res://assets/rpg/player/player_push_cart_sheet.png",Vector2(908,628),8,Vector2(314,314),4,.3,Vector2(.5,.74),p.cart_alpha)
	if p.paper_visible:
		PaperArt.draw(canvas,_origin+Vector2(p.paper_position)*_zoom,float(p.paper_scale)*_zoom,float(p.paper_angle))
		_transform(canvas)
	canvas.draw_set_transform(Vector2.ZERO)
	if p.closeup_visible:_closeup(canvas,viewport,p,fit)
func _particles(canvas:CanvasItem,t:float)->void:
	if t<5980 or t>=6740:return
	var colors:=[Color("ffce55"),Color("7bdbff"),Color.WHITE,Color("d98b44")]
	for i in range(22):
		# Stable local variation never consumes the defense model's seeded RNG.
		var duration:=160.0 if reduced else 480.0+float((i*73)%281)
		var q:=clampf((t-5980)/duration,0,1)
		if q>=1:continue
		var ease:=1-(1-q)*(1-q);var angle:=deg_to_rad(360.0*i/22+float((i*7)%19)-9)
		var distance:=46.0+float((i*37)%73)
		var point:=Timeline.WINDOW+Vector2(0,8)+Vector2(cos(angle)*distance,sin(angle)*distance-(i%4)*7)*ease
		var color:Color=colors[i%4];color.a=(.95 if i%3==0 else .9)*(1-ease)
		if i%3==0:canvas.draw_rect(Rect2(point-Vector2(3.5,2)*lerpf(1,1.4,ease),Vector2(7,4)*lerpf(1,1.4,ease)),color)
		else:canvas.draw_circle(point,(6 if i%4==0 else 3)*lerpf(1,.45,ease),color)
func _closeup(canvas:CanvasItem,viewport:Rect2,p:Dictionary,fit:float)->void:
	var factor:=maxf(fit,.65)*float(p.closeup_scale)
	var angle:=deg_to_rad(float(p.closeup_angle));var center:=viewport.get_center()
	canvas.draw_set_transform(center,angle,Vector2.ONE*factor)
	canvas.draw_rect(Rect2(-165,-85,330,170),Color("f5efd9",.98))
	canvas.draw_rect(Rect2(-165,-85,330,170),Color("58717e"),false,5)
	PaperArt.draw(canvas,center+Vector2(0,-4).rotated(angle)*factor,4.9*factor,float(p.closeup_angle)-7,-1,.23)
	canvas.draw_set_transform(center,angle,Vector2.ONE*factor)
	if font:canvas.draw_string(font,Vector2(-152,13),"本人马上回来。",HORIZONTAL_ALIGNMENT_CENTER,304,26,Color("172128"))
	canvas.draw_set_transform(Vector2.ZERO)
