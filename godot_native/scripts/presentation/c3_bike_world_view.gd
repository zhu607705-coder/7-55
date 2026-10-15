extends RefCounted
## Source bicycle (BootScene.ensureCanteenTextures), rendered at 92 × 62.
## Drawing and alpha picking share one texture. This view owns no story state.
const Picker=preload("res://scripts/world_object_picker.gd")
const SIZE:=Vector2(92,62)
const DRAW: Array=[{"method":"strokeCircle","args":[20,42,17],"style":{"width":5,"color":1515817,"alpha":1}},{"method":"strokeCircle","args":[20,42,13],"style":{"width":2,"color":12371911,"alpha":0.9}},{"method":"lineBetween","args":[7,42,33,42],"style":{"width":2,"color":12371911,"alpha":0.9}},{"method":"lineBetween","args":[20,29,20,55],"style":{"width":2,"color":12371911,"alpha":0.9}},{"method":"strokeCircle","args":[70,42,17],"style":{"width":5,"color":1515817,"alpha":1}},{"method":"strokeCircle","args":[70,42,13],"style":{"width":2,"color":12371911,"alpha":0.9}},{"method":"lineBetween","args":[57,42,83,42],"style":{"width":2,"color":12371911,"alpha":0.9}},{"method":"lineBetween","args":[70,29,70,55],"style":{"width":2,"color":12371911,"alpha":0.9}},{"method":"lineBetween","args":[20,42,39,20],"style":{"width":6,"color":4094382,"alpha":1}},{"method":"lineBetween","args":[39,20,52,42],"style":{"width":6,"color":4094382,"alpha":1}},{"method":"lineBetween","args":[52,42,20,42],"style":{"width":6,"color":4094382,"alpha":1}},{"method":"lineBetween","args":[39,20,70,42],"style":{"width":6,"color":4094382,"alpha":1}},{"method":"lineBetween","args":[38,19,34,10],"style":{"width":6,"color":4094382,"alpha":1}},{"method":"fillRoundedRect","args":[29,7,18,6,2],"style":{"color":2503740,"alpha":1}},{"method":"fillRoundedRect","args":[55,20,14,13,2],"style":{"color":2503740,"alpha":1}},{"method":"fillRect","args":[59,23,6,6],"style":{"color":7591922,"alpha":1}}]

var image: Image
var texture: ImageTexture
var font: Font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
var worlds: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json")).worlds
func active(s: Dictionary) -> bool:
	return str(s.native.scene)=="campus_bootstrap" and bool(s.canteenHunt.active) and str(s.canteenHunt.phase)=="chase_ready"
func point() -> Vector2:
	var p: Dictionary=worlds.campus_bootstrap.manifest.canteen.bike
	return Vector2(p.x,p.y)
func body_texture() -> Texture2D:
	if texture==null:
		image=Image.new()
		if image.load_svg_from_string(svg())!=OK: return null
		texture=ImageTexture.create_from_image(image)
	return texture
func svg() -> String:
	var markup: String='<svg xmlns="http://www.w3.org/2000/svg" width="92" height="62" viewBox="0 0 92 62">'
	for primitive: Dictionary in DRAW:
		var a: Array=primitive.args;var style: Dictionary=primitive.style
		var color: String="#%06x"%int(style.color)
		match primitive.method:
			"strokeCircle": markup+='<circle cx="%s" cy="%s" r="%s" fill="none" stroke="%s" stroke-width="%s" stroke-opacity="%s"/>'%[a[0],a[1],a[2],color,style.width,style.alpha]
			"lineBetween": markup+='<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" stroke-opacity="%s"/>'%[a[0],a[1],a[2],a[3],color,style.width,style.alpha]
			"fillRoundedRect","fillRect": markup+='<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s" fill-opacity="%s"/>'%[a[0],a[1],a[2],a[3],a[4] if a.size()>4 else 0,color,style.alpha]
	return markup+"</svg>"
func geometry() -> Dictionary:
	return {"rect":Rect2(point()-SIZE/2,SIZE),"texture":body_texture()}
func draw(canvas: CanvasItem,context: Dictionary,s: Dictionary,front: bool) -> void:
	if not active(s): return
	var p: Vector2=point();var z: float=context.zoom;var origin: Vector2=context.origin
	# BootScene places the bicycle at y+6 and actor at y+30.
	if (p.y+6>context.player.y+30)!=front:return
	var tex: Texture2D=body_texture()
	if tex==null:return
	var dark: bool=s.native.mode=="dark"
	var code: Vector2=p+Vector2(18,-5)
	if dark:
		canvas.draw_circle(origin+code*z,22*z,Color("4bc9ff",.16))
		canvas.draw_arc(origin+code*z,22*z,0,TAU,40,Color("88e7ff",.95),4*z)
	canvas.draw_texture_rect(tex,Rect2(origin+(p-SIZE/2)*z,SIZE*z),false)
	Picker.record(canvas,["bike"],geometry())
	if not dark and not s.canteenHunt.bikeLockCleaned:
		canvas.draw_set_transform(origin+code*z,-.18,Vector2.ONE*z)
		canvas.draw_rect(Rect2(-6.5,-5.5,13,11),Color("ffffff",.7))
		canvas.draw_rect(Rect2(-6.5,-5.5,13,11),Color("ffedba",.9),false,2)
		canvas.draw_set_transform(Vector2.ZERO)
func draw_hint(canvas: CanvasItem,context: Dictionary,s: Dictionary) -> void:
	if not active(s) or context.player.distance_to(point())>170:return
	var outer_scale: float=canvas.hud_display_scale() if canvas.has_method("hud_display_scale") else 1.0
	var font_size: int=maxi(12,ceili(14/maxf(.1,outer_scale)))
	var text: String="扫码骑车：2.00 元 / 次\n我的零钱：%.2f 元"%(float(s.wallet.cashCents)/100.0)
	var text_size: Vector2=font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_CENTER,-1,font_size)
	var extent: Vector2=text_size+Vector2(16,12)
	var anchor: Vector2=context.origin+(point()+Vector2(0,-58))*float(context.zoom)
	var position:=Vector2(clampf(anchor.x-extent.x/2,8,maxf(8,canvas.size.x-extent.x-8)),anchor.y-extent.y)
	if position.y<48:
		var body_center: Vector2=context.origin+point()*float(context.zoom)
		var left: float=body_center.x-SIZE.x*float(context.zoom)/2-12-extent.x
		position=Vector2(left,body_center.y-extent.y/2) if left>=8 else Vector2(clampf(body_center.x-extent.x/2,8,maxf(8,canvas.size.x-extent.x-8)),body_center.y+SIZE.y*float(context.zoom)/2+10)
		position.y=clampf(position.y,48,maxf(48,canvas.size.y-extent.y-8))
	canvas.draw_rect(Rect2(position,extent),Color("241a12",.94))
	Picker.record(canvas,[],{"rect":Rect2((position-context.origin)/float(context.zoom),extent/float(context.zoom))})
	canvas.draw_multiline_string(font,position+Vector2(8,6+font.get_ascent(font_size)),text,HORIZONTAL_ALIGNMENT_CENTER,text_size.x,font_size,-1,Color("fff7df"))
