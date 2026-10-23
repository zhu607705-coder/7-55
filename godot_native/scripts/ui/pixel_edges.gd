extends RefCounted
## Shared low-resolution corner profile. Paint only; content/hit rectangles stay
## unchanged. Small integer radii and no antialiasing avoid smooth web-card arcs.
const CONTROL_RADIUS:=4
const PANEL_RADIUS:=6
static func configure(style:StyleBoxFlat,panel:bool=false)->StyleBoxFlat:
	style.set_corner_radius_all(PANEL_RADIUS if panel else CONTROL_RADIUS)
	style.corner_detail=2
	style.anti_aliasing=false
	return style

static func silhouette(rect:Rect2)->Array[Rect2]:
	if rect.size.x<=0 or rect.size.y<=0:return []
	if minf(rect.size.x,rect.size.y)<16:return [rect]
	# Same six-pixel extent as the panel style, with explicit integer steps.
	return [Rect2(rect.position+Vector2(6,0),rect.size-Vector2(12,0)),Rect2(rect.position+Vector2(3,2),rect.size-Vector2(6,4)),Rect2(rect.position+Vector2(0,6),rect.size-Vector2(0,12))]
