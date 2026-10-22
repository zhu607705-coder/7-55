extends RefCounted
const PixelEdges=preload("res://scripts/ui/pixel_edges.gd")
## Deterministic, presentation-only stationery and campus-sign materials.
## Draw from a CanvasItem's _draw(). Content and hit areas remain caller-owned.
## No textures, text, animation, nodes, inputs, or gameplay state are created.
const PAPER := Color("f3eddf")
const PAPER_EDGE := Color("c8bda8")
const NAVY := Color("263c49")
const INK := Color("293942")
const WOOD := Color("97735a")
const CORAL := Color("ba6656")
const RULE := Color("d8cfc0")
const SHADOW := Color("b9ad97")
const KINDS := ["paper", "placard"]

static func palette(overrides: Dictionary = {}) -> Dictionary:
	var colors := {"paper":PAPER,"edge":PAPER_EDGE,"navy":NAVY,"ink":INK,"wood":WOOD,"accent":CORAL,"rule":RULE,"shadow":SHADOW}
	for key: String in colors:
		if overrides.get(key) is Color: colors[key] = overrides[key]
	return colors

static func minimum_size(kind: String = "paper", header_height: float = 0.0) -> Vector2:
	var padding := 12.0 if kind == "placard" else 16.0
	return Vector2(padding*2+32,padding*2+20+maxf(0,header_height))

static func geometry(rect: Rect2, kind: String = "paper", header_height: float = 0.0) -> Dictionary:
	# Small surfaces keep a valid body and drop optional details. Never expand
	# the supplied bounds to satisfy a decorative motif or minimum size.
	var bounds := Rect2(rect.position,Vector2(maxf(0,rect.size.x),maxf(0,rect.size.y)))
	var normal_inset := 12.0 if kind == "placard" else 16.0
	var inset := minf(normal_inset,minf(bounds.size.x,bounds.size.y)/4.0)
	var inner := Rect2(bounds.position+Vector2.ONE*inset,(bounds.size-Vector2.ONE*inset*2).max(Vector2.ZERO))
	var header := Rect2(inner.position,Vector2(inner.size.x,0))
	var body := inner
	if kind != "placard" and header_height>0 and inner.size.y>=36:
		header.size.y = minf(header_height,inner.size.y-20)
		body.position.y += header.size.y
		body.size.y -= header.size.y
	var heading := header
	var index := Rect2(header.end,Vector2.ZERO)
	if header.size.x>=120 and header.size.y>=24:
		index = Rect2(Vector2(header.end.x-32,header.position.y),Vector2(32,header.size.y-10))
		heading.size.x -= 44
	return {"bounds":bounds,"inner":inner,"body":body,"header":header,"heading":heading,"index":index,"inset":inset,"details":bounds.size.x>=64 and bounds.size.y>=44}

static func _mark(commands: Array, rect: Rect2, color: Color, decoration: bool = true) -> void:
	if rect.size.x>0 and rect.size.y>0: commands.append({"rect":rect,"color":color,"decoration":decoration})

static func commands(rect: Rect2, kind: String = "paper", overrides: Dictionary = {}, header_height: float = 0.0) -> Array:
	# Filled strips avoid the half-pixel outward extent of stroked outlines.
	var geo := geometry(rect,kind,header_height)
	var bounds: Rect2 = geo.bounds
	var c := palette(overrides)
	var marks: Array = []
	if bounds.size.x<=0 or bounds.size.y<=0: return marks
	var is_placard := kind == "placard"
	for piece:Rect2 in PixelEdges.silhouette(bounds): _mark(marks,piece,c.navy if is_placard else c.paper,false)
	if not geo.details: return marks
	var x := bounds.position.x
	var y := bounds.position.y
	var w := bounds.size.x
	var h := bounds.size.y
	var edge: Color = c.wood if is_placard else c.edge
	_mark(marks,Rect2(x+6,y,w-12,1),edge)
	_mark(marks,Rect2(x,y+6,1,h-12),edge)
	_mark(marks,Rect2(x+w-1,y+6,1,h-12),edge)
	_mark(marks,Rect2(x+6,y+h-2,w-12,2),c.wood if is_placard else c.shadow)
	if is_placard:
		# Two tiny fixed mounting marks, not free-floating check/badge motifs.
		_mark(marks,Rect2(x+5,y+5,2,2),c.edge)
		_mark(marks,Rect2(x+w-7,y+5,2,2),c.edge)
		_mark(marks,Rect2(x+5,y+h-7,2,2),c.edge)
		_mark(marks,Rect2(x+w-7,y+h-7,2,2),c.edge)
	else:
		# Registration corners live entirely in the margin, never under prose.
		for corner_x: float in [x+5,x+w-11]:
			_mark(marks,Rect2(corner_x,y+6,6,1),c.rule)
			_mark(marks,Rect2(corner_x,y+h-7,6,1),c.rule)
		var header: Rect2 = geo.header
		if header.size.y>0:
			# The caller owns text in this reserved header. The rule has a short
			# coral registration segment; no status or puzzle meaning is implied.
			_mark(marks,Rect2(header.position.x,header.end.y-5,header.size.x,1),c.rule)
			_mark(marks,Rect2(header.position.x,header.end.y-5,minf(24,header.size.x),1),c.accent)
			var index: Rect2 = geo.index
			if index.size.x>0:
				_mark(marks,Rect2(index.position.x-6,index.position.y,1,index.size.y),c.rule)
	return marks

static func draw(canvas: CanvasItem, rect: Rect2, kind: String = "paper", overrides: Dictionary = {}, header_height: float = 0.0) -> void:
	for command: Dictionary in commands(rect,kind,overrides,header_height):
		canvas.draw_rect(command.rect,command.color)

static func panel_style(kind: String = "paper", overrides: Dictionary = {}, padding: Vector2 = Vector2(16,16)) -> StyleBoxFlat:
	# Container companion: exact explicit padding and no outward shadow.
	# Decorative draw() can be used behind the container with matching bounds.
	var c := palette(overrides)
	var style := StyleBoxFlat.new()
	style.bg_color = c.navy if kind == "placard" else c.paper
	style.border_color = c.wood if kind == "placard" else c.edge
	style.set_border_width_all(1)
	style.border_width_bottom = 2
	PixelEdges.configure(style,true)
	style.content_margin_left = maxf(0,padding.x)
	style.content_margin_right = maxf(0,padding.x)
	style.content_margin_top = maxf(0,padding.y)
	style.content_margin_bottom = maxf(0,padding.y)
	return style
