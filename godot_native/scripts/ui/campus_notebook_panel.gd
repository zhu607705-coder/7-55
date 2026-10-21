extends PanelContainer
## Optional investigation-folder silhouette. Presentation only: no inputs or state.
## All cover/page detail is inside the fixed content margins; no outside shadow.
const UiMaterial = preload("res://scripts/ui/campus_ui_material.gd")
const MODES := ["notebook", "loose_sheet"]
const LEFT := 32.0
const RIGHT := 18.0
const TOP := 18.0
const BOTTOM := 22.0
var mode: String = "notebook":
	set(value):
		mode = value if value in MODES else "notebook"
		queue_redraw()

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var spacing := StyleBoxEmpty.new()
	spacing.content_margin_left = LEFT
	spacing.content_margin_right = RIGHT
	spacing.content_margin_top = TOP
	spacing.content_margin_bottom = BOTTOM
	add_theme_stylebox_override("panel", spacing)

func _ready() -> void:
	resized.connect(queue_redraw)

func body_rect() -> Rect2:
	return geometry(size).body

static func geometry(dimensions: Vector2) -> Dictionary:
	var extent := dimensions.max(Vector2.ZERO)
	var start := Vector2(minf(LEFT, extent.x), minf(TOP, extent.y))
	var finish := Vector2(maxf(start.x, extent.x-RIGHT), maxf(start.y, extent.y-BOTTOM))
	return {"bounds": Rect2(Vector2.ZERO, extent), "body": Rect2(start, finish-start)}

static func commands(dimensions: Vector2, kind: String = "notebook") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	# Below the container minimum, omit detail rather than squeeze it over text.
	if dimensions.x < LEFT+RIGHT+8 or dimensions.y < TOP+BOTTOM+8:
		return result
	var w := dimensions.x
	var h := dimensions.y
	var notebook := kind != "loose_sheet"
	var cover := UiMaterial.NAVY if notebook else Color("b8ae9b")
	# Two overlapping rects give a 3px stepped silhouette without an outer stroke.
	result.append({"rect": Rect2(3, 0, w-6, h), "color": cover, "decoration": false})
	result.append({"rect": Rect2(0, 3, w, h-6), "color": cover, "decoration": false})
	var page_left := 19.0 if notebook else 5.0
	result.append({"rect": Rect2(page_left+3, 4, w-page_left-10, h-13), "color": UiMaterial.PAPER, "decoration": false})
	result.append({"rect": Rect2(page_left, 7, w-page_left-4, h-19), "color": UiMaterial.PAPER, "decoration": false})
	# Page stack: horizontal and vertical strips confined to bottom/right margins.
	for offset: float in [0.0, 3.0]:
		result.append({"rect": Rect2(page_left+4, h-9+offset, w-page_left-12, 1), "color": UiMaterial.PAPER_EDGE, "decoration": true})
		result.append({"rect": Rect2(w-7+offset, 10, 1, h-24), "color": UiMaterial.PAPER_EDGE, "decoration": true})
	if notebook:
		# Cloth spine, hinge and three fixed binding loops; no fake controls or text.
		result.append({"rect": Rect2(4, 7, 3, h-14), "color": Color("3c515a"), "decoration": true})
		result.append({"rect": Rect2(17, 7, 2, h-18), "color": Color("172c37"), "decoration": true})
		result.append({"rect": Rect2(20, 10, 1, h-25), "color": UiMaterial.PAPER_EDGE, "decoration": true})
		for ratio:float in [.25,.5,.75]:
			var cy:=floorf(h*ratio)
			result.append({"rect":Rect2(10,cy-3,15,2),"color":Color("c8bda8"),"decoration":true})
			result.append({"rect":Rect2(10,cy+2,15,2),"color":Color("8e816c"),"decoration":true})
			result.append({"rect":Rect2(8,cy-1,2,4),"color":Color("c8bda8"),"decoration":true})
	else:
		# A single folded top corner stays wholly above the text area.
		result.append({"rect": Rect2(w-15, 5, 8, 3), "color": UiMaterial.PAPER_EDGE, "decoration": true})
		result.append({"rect": Rect2(w-12, 8, 5, 3), "color": UiMaterial.PAPER_EDGE, "decoration": true})
	return result

func _draw() -> void:
	for mark: Dictionary in commands(size, mode):
		draw_rect(mark.rect, mark.color)
