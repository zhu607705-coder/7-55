extends StyleBox
## A/B study only; intentionally different radii/lift from the approved product.
## One StyleBox owns face/edge/insets/contact/lift. No overlay masks corners.
const VARIANTS := ["primary", "secondary", "tertiary", "ghost", "text"]
var PALETTES := {
 "primary": [Color("454441"),Color("302f2c"),Color("191917"),Color.WHITE,.18,.22,.18,.28,.40],
 "secondary": [Color("fffefa"),Color("f3f1eb"),Color(30.0/255,30.0/255,27.0/255,.14),Color("393a37"),.95,.06,.06,.09,.14],
 "tertiary": [Color("eeede8"),Color("e2e0d9"),Color(30.0/255,30.0/255,27.0/255,.10),Color("393a37"),.85,.06,.06,.09,.12],
 "ghost": [Color("eeede8"),Color("e2e0d9"),Color.TRANSPARENT,Color("62645f"),0.0,0.0,0.0,0.0,.14],
 "text": [Color.TRANSPARENT,Color.TRANSPARENT,Color.TRANSPARENT,Color("62645f"),0.0,0.0,0.0,0.0,0.0],
}
var HOVER_PALETTES := {
 "primary": [Color("504f4b"),Color("3b3a36")],
 "secondary": [Color("fffffc"),Color("faf9f5")],
 "tertiary": [Color("f5f4ef"),Color("eae8e1")],
 "ghost": [Color("eeede8"),Color("e2e0d9")],
 "text": [Color.TRANSPARENT,Color.TRANSPARENT],
}
var direction := "A"
var radius_units := 4.0
var variant := "secondary"
var unit := 1.0
var hover_amount := 0.0
var press_amount := 0.0
var lift_amount := 0.0
var disabled_amount := 0.0
var compact := false
var shadow_press := 0.0
var color_press := 0.0
var label_line: TextLine
var label_alignment := HORIZONTAL_ALIGNMENT_CENTER
var label_inset := 0.0


# Compatibility metadata for existing layout/contrast readers. Rendering remains
# owned here; late legacy palette writes must not restore app-specific hues.
var bg_color: Color:
 get:
  if variant in ["ghost","text"]:return Color.TRANSPARENT
  return PALETTES[variant][1]
 set(_value):pass
var border_color: Color:
 get:return PALETTES[variant][2]
 set(_value):pass
var border_width_left: int:
 get:return roundi(unit)
var corner_radius_top_left: int:
 get:return roundi(radius_units*unit)
var anti_aliasing := true
var expand_margin_left := 0.0
var expand_margin_top := 0.0
var expand_margin_right := 0.0
var expand_margin_bottom := 0.0
var shadow_size := 0
var shadow_offset := Vector2.ZERO
func set_border_width_all(_value: int) -> void:pass
func set_corner_radius_all(_value: int) -> void:pass

func configure(kind: String, u: float) -> void:
 variant=kind if kind in VARIANTS else "secondary"
 unit=u
 var p: Array=PALETTES[variant]
 bg_color=p[1];border_color=p[2]
 set_border_width_all(maxi(1,roundi(unit)))
 set_corner_radius_all(roundi(radius_units*unit))
 anti_aliasing=true
 content_margin_left=18.0*unit;content_margin_right=18.0*unit
 content_margin_top=unit;content_margin_bottom=unit

func _get_draw_rect(rect: Rect2) -> Rect2:
 return rect.grow(12.0*unit)

func _points(rect: Rect2, radius: float) -> PackedVector2Array:
 var result:=PackedVector2Array()
 var r: float=clampf(radius,0.0,minf(rect.size.x,rect.size.y)/2.0)
 var centers: Array[Vector2]=[rect.position+Vector2(r,r),rect.position+Vector2(rect.size.x-r,r),rect.end-Vector2(r,r),rect.position+Vector2(r,rect.size.y-r)]
 for corner in 4:
  for segment in 9:
   var angle: float=PI+corner*PI/2.0+segment*PI/16.0
   result.append(centers[corner]+Vector2(cos(angle),sin(angle))*r)
 return result

func _fill(canvas: RID,rect: Rect2,radius: float,top: Color,bottom: Color) -> void:
 if rect.size.x<=0.0 or rect.size.y<=0.0:return
 var edge_points:=_points(rect,radius)
 var points:=PackedVector2Array([rect.get_center()]);points.append_array(edge_points)
 var colors:=PackedColorArray()
 for point: Vector2 in points:
  colors.append(top.lerp(bottom,clampf((point.y-rect.position.y)/rect.size.y,0.0,1.0)))
 # Convex fan avoids ear-clipping failures on tiny native dialog keys whose
 # clamped corner centers coincide. Degenerate arc triangles have zero area.
 var indices:=PackedInt32Array()
 for i in edge_points.size():indices.append_array(PackedInt32Array([0,i+1,(i+1)%edge_points.size()+1]))
 RenderingServer.canvas_item_add_triangle_array(canvas,indices,points,colors)
 if not anti_aliasing:return
 # Fractional coverage fringe, not a blur/glow. It scales with the type and
 # smooths the actual outer contour rather than only the inset polylines.
 var outer:=_points(rect.grow(.5*unit),radius+.5*unit)
 var fringe:=PackedVector2Array();var fringe_colors:=PackedColorArray();var fringe_indices:=PackedInt32Array()
 for i in edge_points.size():
  fringe.append(edge_points[i]);fringe.append(outer[i])
  var color: Color=top.lerp(bottom,clampf((edge_points[i].y-rect.position.y)/rect.size.y,0.0,1.0))
  fringe_colors.append(color);fringe_colors.append(Color(color,0))
  var a: int=i*2;var b: int=((i+1)%edge_points.size())*2
  fringe_indices.append_array(PackedInt32Array([a,a+1,b,b,a+1,b+1]))
 RenderingServer.canvas_item_add_triangle_array(canvas,fringe_indices,fringe,fringe_colors)

func _shadow(canvas: RID,rect: Rect2,radius: float,offset: float,blur: float,spread: float,alpha: float) -> void:
 # Fixed 12-band Gaussian approximation, scaled in logical units. The renderer
 # caches draw commands between state changes; no image allocation per frame.
 for band in range(12,0,-1):
  var t: float=float(band)/12.0
  var growth: float=spread+blur*.5*t
  var area:=rect.grow(growth);area.position.y+=offset
  var a: float=alpha*(exp(-2.0*t*t)-exp(-2.0*pow(t+1.0/12.0,2.0)))
  _fill(canvas,area,maxf(0,radius+growth),Color(0,0,0,a),Color(0,0,0,a))

func _draw(canvas: RID,rect: Rect2) -> void:
 var p: Array=PALETTES[variant]
 var opacity: float=1.0 # Disabled values remain readable; native input owns gating.
 var face:=rect;face.position.y+=press_amount*unit
 var r: float=radius_units*unit
 if direction in ["B","B2"] and variant=="secondary":
  var wash:=Color("ddd8ca");wash.a=maxf(hover_amount*.45,press_amount*.7)
  _fill(canvas,face,0,wash,wash)
  if direction=="B":RenderingServer.canvas_item_add_line(canvas,Vector2(face.position.x,face.end.y-unit),Vector2(face.end.x,face.end.y-unit),Color(0.25,0.24,0.21,.22),unit,true)
  return
 if variant=="text":
  _label_detail(canvas,face,opacity)
  return
 var visible_face: float=1.0 if variant!="ghost" else maxf(hover_amount*.65,press_amount)
 if visible_face<=.001:return
 if variant!="ghost":
  _shadow(canvas,face,r,lerpf(1.0,1.0,shadow_press)*unit,lerpf(2.0,1.0,shadow_press)*unit,0,float(p[6])*opacity)
  _shadow(canvas,face,r,lerpf(lerpf(1.5,2.0,lift_amount),1.0,shadow_press)*unit,lerpf(lerpf(3.0,4.0,lift_amount),1.0,shadow_press)*unit,lerpf(-1.0,0.0,shadow_press)*unit,float(p[7])*(1.0-shadow_press)*opacity)
  if variant!="primary":
   var below:=face;below.position.y+=unit
   _fill(canvas,below,r,Color(1,1,1,.9*press_amount*opacity),Color(1,1,1,.9*press_amount*opacity))
 var edge: Color=p[2];edge.a*=visible_face*opacity
 _fill(canvas,face,r,edge,edge)
 var inner:=face.grow(-unit)
 var top: Color=p[0];var bottom: Color=p[1]
 top=top.lerp(HOVER_PALETTES[variant][0],hover_amount);bottom=bottom.lerp(HOVER_PALETTES[variant][1],hover_amount)
 var first: Color=top.lerp(bottom,color_press)
 var last: Color=bottom.lerp(top,color_press)
 first.a*=visible_face*opacity;last.a*=visible_face*opacity
 _fill(canvas,inner,maxf(0,r-unit),first,last)
 # Insets share the inner radius. Highlight, bottom and three falloff slots
 # are always drawn, including zero-alpha rest/pressed padding.
 var inner_points:=_points(inner.grow(-.5*unit),maxf(0,r-1.5*unit))
 var top_points:=PackedVector2Array();var bottom_points:=PackedVector2Array()
 for i in range(0,18):top_points.append(inner_points[i])
 for i in range(18,36):bottom_points.append(inner_points[i])
 var highlight:=Color(1,1,1,float(p[4])*(1.0-shadow_press)*visible_face*opacity)
 RenderingServer.canvas_item_add_polyline(canvas,top_points,PackedColorArray([highlight]),unit,true)
 var shade:=Color(0,0,0,lerpf(float(p[5]),0.0,shadow_press)*visible_face*opacity)
 RenderingServer.canvas_item_add_polyline(canvas,bottom_points,PackedColorArray([shade]),unit,true)
 for line in 3:
  var inset: float=(float(line)+.5)*unit
  var top_line:=PackedVector2Array()
  var cut:=_points(inner.grow(-inset),maxf(0,r-unit-inset))
  for i in range(0,18):top_line.append(cut[i])
  RenderingServer.canvas_item_add_polyline(canvas,top_line,PackedColorArray([Color(0,0,0,float(p[8])*shadow_press*opacity/(float(line)+2.0))]),unit,true)
 _label_detail(canvas,face,opacity)

func _label_detail(canvas: RID, face: Rect2, opacity: float) -> void:
 if label_line==null or label_line.get_size().x<=0:return
 var available: float=maxf(0,face.size.x-content_margin_left-content_margin_right-label_inset)
 if label_line.get_size().x>available:return # Native wrapped/clipped label remains authoritative.
 var width: float=label_line.get_size().x
 var x: float=face.position.x+content_margin_left+label_inset
 if label_alignment==HORIZONTAL_ALIGNMENT_CENTER:x+=(face.size.x-content_margin_left-content_margin_right-label_inset-width)/2.0
 elif label_alignment==HORIZONTAL_ALIGNMENT_RIGHT:x=face.end.x-content_margin_right-width
 var baseline: float=face.position.y+(face.size.y-label_line.get_size().y)/2.0+label_line.get_line_ascent()
 if variant=="primary":
  label_line.draw(canvas,Vector2(x,baseline-label_line.get_line_ascent()-unit),Color(0,0,0,.28*opacity))
 elif variant=="text":
  var ink: Color=PALETTES[variant][3];ink.a*=opacity
  RenderingServer.canvas_item_add_line(canvas,Vector2(x,baseline+2*unit),Vector2(x+width,baseline+2*unit),ink,unit,true)
  var start:=Vector2(x+width+(8+2*hover_amount)*unit,face.get_center().y)
  RenderingServer.canvas_item_add_line(canvas,start,start+Vector2(8,0)*unit,ink,unit,true)
  RenderingServer.canvas_item_add_polyline(canvas,PackedVector2Array([start+Vector2(5,-3)*unit,start+Vector2(8,0)*unit,start+Vector2(5,3)*unit]),PackedColorArray([ink]),unit,true)

func study_direction(value: String) -> void:
 direction=value;radius_units=4.0 if value=="A" else 1.0
 for key: String in PALETTES:
  var p: Array=PALETTES[key]
  p[4]=.12 if key=="primary" else .3
  p[5]=.12 if key=="primary" else .03
  p[6]=.10 if value=="A" and key=="primary" else .035 if value=="A" else 0.0
  p[7]=.035 if value=="A" and key=="primary" else 0.0
  if key in ["secondary","tertiary"]:
   p[0]=Color("f2efe6");p[1]=Color("ece8dc");p[2]=Color(.30,.28,.23,.22)
   HOVER_PALETTES[key]=[Color("f6f3eb"),Color("f0ecdf")]
  if value in ["B","B2"]:p[1]=p[0];p[4]=0.0;p[5]=0.0
  if value=="B2" and key=="primary":
   p[0]=Color("55564f");p[1]=p[0];p[2]=Color("55564f")
   HOVER_PALETTES[key]=[Color("62635b"),Color("62635b")]
