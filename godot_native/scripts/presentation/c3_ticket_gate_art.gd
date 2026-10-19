extends RefCounted
## Source-registered material fragments; animation remains the gate-view contract.
const MATERIAL="res://assets/rpg/theater/generated/objects/theater_ticket_wings_material_v1.png"
const GLASS_TINT:=Color(.68,.73,.70,.30)
const LEFT_BODY:=Rect2(775,658,18,61)
const RIGHT_BODY:=Rect2(878,658,18,61)
var texture:Texture2D
func draw(canvas:CanvasItem,pose:Dictionary)->void:
	if texture==null:texture=load(MATERIAL)
	if texture==null:return
	var t:float=clampf(float(pose.open_ratio),0,1)
	var tex_size:Vector2=texture.get_size()
	# Wings slide into fixed slots: retain the leading seam, crop the entering
	# portion. Do not scale the entire pillar/plate image to fake an opening.
	for side:int in [-1,1]:
		var outer:float=786.0 if side<0 else 883.0
		var inner:float=float(pose.left_inner if side<0 else pose.right_inner)
		var top:float=lerpf(664,672,t);var bottom:float=lerpf(706,714,t)
		var q:=PackedVector2Array([Vector2(outer,top),Vector2(inner,672),Vector2(inner,714),Vector2(outer,bottom)])
		var a:=Vector2(604,349) if side<0 else Vector2(1063,349)
		var b:=Vector2(831,393) if side<0 else Vector2(840,393)
		var c:=Vector2(831,597) if side<0 else Vector2(840,597)
		var d:=Vector2(604,558) if side<0 else Vector2(1063,558)
		var uv:=PackedVector2Array([a.lerp(b,t)/tex_size,b/tex_size,c/tex_size,d.lerp(c,t)/tex_size])
		# Smoked acrylic leaves the original red carpet and wood visible.
		# The concept's broad pale reflection is attenuated, never emissive.
		canvas.draw_polygon(q,PackedColorArray([GLASS_TINT]),uv,texture)
		canvas.draw_line(Vector2(inner,673),Vector2(inner,714),Color("405653",.55),1.0)
	# Opaque bodies use the generated bronze caps, inset slots and grounded feet.
	# The local registration follows the existing fixture edges, not its canvas.
	canvas.draw_texture_rect_region(texture,LEFT_BODY,Rect2(527,324,84,294),Color(.88,.86,.81,1))
	canvas.draw_texture_rect_region(texture,RIGHT_BODY,Rect2(1062,324,84,294),Color(.88,.86,.81,1))
