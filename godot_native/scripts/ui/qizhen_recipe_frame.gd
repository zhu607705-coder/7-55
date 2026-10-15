extends Control
## Native projection of QizhenRecipeFrame.tsx + qizhen-recipe-frame.css.
## Browser photos intentionally store a composition recipe, not bitmap bytes.
const SOURCE:=Vector2(1672,941)
const ZOOMS:=[1.0,1.5,2.2]
const SWAN:=[Vector2(.02,.78),Vector2(.10,.62),Vector2(.07,.38),Vector2(.10,.16),Vector2(.18,.06),Vector2(.27,.09),Vector2(.29,.20),Vector2(.23,.33),Vector2(.20,.50),Vector2(.26,.60),Vector2(.45,.62),Vector2(.68,.55),Vector2(.88,.60),Vector2(1,.72),Vector2(.94,.88),Vector2(.70,.96),Vector2(.38,.96),Vector2(.12,.90)]
var recipe: Dictionary={}
var thumbnail:=false
var background: Texture2D
var kayak: Texture2D
func configure(value: Dictionary, thumb: bool=false) -> void:
	recipe=value.duplicate(true); thumbnail=thumb
	background=load("res://assets/rpg/interiors/qizhen_lake_"+str(recipe.get("zone","open_water"))+".png")
	kayak=load("res://assets/rpg/qizhen/kayak_overhead_frame_a.png")
	clip_contents=true; mouse_filter=Control.MOUSE_FILTER_IGNORE; texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw); queue_redraw()
static func projection(value: Dictionary, extent: Vector2) -> Dictionary:
	var z: float=ZOOMS[clampi(int(value.get("zoomStep",0)),0,2)]
	var crop:=Vector2(float(value.get("cropCenterX",836)),float(value.get("cropCenterY",470.5)))/SOURCE
	var position:=Vector2(.5,.5) if z==1 else ((Vector2(.5,.5)-crop*z)/(1-z)).clamp(Vector2.ZERO,Vector2.ONE)
	var background_size:=Vector2(extent.x*z,extent.x*z*SOURCE.y/SOURCE.x)
	var origin: Vector2=(extent-background_size)*position
	var k: Vector2=(Vector2(float(value.get("kayakX",836)),float(value.get("kayakY",470)))/SOURCE*z+(Vector2.ONE-Vector2.ONE*z)*position)*extent
	return {"zoom":z,"origin":origin,"backgroundSize":background_size,"kayak":k,"kayakWidth":128.0/SOURCE.x*z*extent.x,"rotation":int(value.get("headingBucket",0))*PI/4}
func _draw() -> void:
	if recipe.is_empty() or background==null: return
	var p: Dictionary=projection(recipe,size)
	draw_rect(Rect2(Vector2.ZERO,size),Color("05070a"))
	draw_texture_rect(background,Rect2(p.origin,p.backgroundSize),false)
	var ripple: String=str(recipe.get("rippleClarityBucket","lost"))
	if ripple=="clear" or (ripple=="partial" and not thumbnail):
		var opacity: float=.4 if thumbnail else .55 if ripple=="clear" else .22
		var step: int=22 if thumbnail else 16
		for radius in range(step,int(size.length())+step,step):
			draw_arc(size*Vector2(.5,.64),float(radius),0,TAU,maxi(32,radius),Color(168.0/255,214.0/255,235.0/255,.5*opacity),3 if thumbnail else 2,true)
	var swan: String=str(recipe.get("swanDistanceBucket","gone"))
	if swan in ["near","mid","far"]:
		var fraction: float=({"near":.30,"mid":.19,"far":.12} if thumbnail else {"near":.34,"mid":.22,"far":.14})[swan]
		var extent:=Vector2(size.x*fraction,size.x*fraction*.6)
		var origin:=Vector2(size.x*.58,size.y*.82-extent.y)
		var points:=PackedVector2Array()
		for point: Vector2 in SWAN: points.append(origin+point*extent)
		draw_colored_polygon(points,Color(13.0/255,16.0/255,23.0/255,{"near":.92,"mid":.75,"far":.58}[swan]))
	var extent:=Vector2(float(p.kayakWidth),float(p.kayakWidth)*kayak.get_height()/kayak.get_width())
	draw_set_transform(p.kayak,p.rotation)
	draw_texture_rect(kayak,Rect2(-extent/2,extent),false)
	draw_set_transform(Vector2.ZERO)
