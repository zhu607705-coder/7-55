extends RefCounted
## Public building identity only. Coordinates use the north-up source plate.
## This presentation cannot change routes, reservations, inventory, or story facts.
const PLATE = "res://assets/rpg/campus/zijingang_campus_plate.png"
const LIBRARY_NAME = "基础图书馆"
const LIBRARY_CENTER = Vector2(3718,1568)
const LIBRARY_GATE = Vector2(3706,1696)
const LIBRARY_LABEL = Vector2(3718,1660)
const REVEAL_RADIUS = 225.0
const MAP_REGION = Rect2(2240,360,1850,1500)
const TOWER_REGION = Rect2(3560,1430,330,280)

static func label_layout(context: Dictionary, font: Font, display_scale: float, visible_rect: Rect2) -> Dictionary:
	if str(context.get("scene_id","")) != "campus_bootstrap": return {}
	# During viewport handoff, the HUD can temporarily leave no scene area.
	if visible_rect.size.x <= 0 or visible_rect.size.y <= 0: return {}
	if Vector2(context.player).distance_to(LIBRARY_CENTER) > REVEAL_RADIUS: return {}
	var z: float = context.zoom
	var scale: float = maxf(display_scale,.1)
	# Screen readability is independent of world zoom and desktop split scaling.
	var font_size: int = ceili(16.0/scale)
	var pad: float = 7.0/scale
	var text_size: Vector2 = font.get_string_size(LIBRARY_NAME,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
	var point: Vector2 = context.origin + LIBRARY_LABEL*z
	var rect := Rect2(point-Vector2(text_size.x/2+pad,text_size.y+pad*2),text_size+Vector2(pad*2,pad*2))
	# A nearby player cannot reveal a clamped label on a distant, panned view.
	if not visible_rect.encloses(rect): return {}
	return {"rect":rect,"font_size":font_size,"baseline":rect.position+Vector2(pad,pad+font.get_ascent(font_size)),"physical_font_size":font_size*scale}

static func draw_label(canvas: CanvasItem, context: Dictionary, font: Font, display_scale: float, visible_rect: Rect2) -> void:
	var layout := label_layout(context,font,display_scale,visible_rect)
	if layout.is_empty(): return
	canvas.draw_rect(layout.rect,Color("13202bea"))
	canvas.draw_rect(layout.rect,Color("b4b49b"),false,1.0/maxf(display_scale,.1))
	canvas.draw_string(font,layout.baseline,LIBRARY_NAME,HORIZONTAL_ALIGNMENT_LEFT,-1,layout.font_size,Color("fff5dd"))

static func plate_crop(parent: Control, region: Rect2, rect: Rect2, node_name: String) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(PLATE)
	atlas.region = region
	var image := TextureRect.new()
	image.name = node_name; image.position = rect.position; image.size = rect.size
	image.texture = atlas; image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image

static func build_location(b, back: Callable) -> Control:
	var root: Control = b._base(Color("f6f7fa"),b.APP_HEIGHT)
	root.name = "LibraryBuildingLocation"
	root.set_meta("handles_all_actions",true)
	b._header(root,"馆舍位置",Color.WHITE,Color("243245"),back,"back","返回座位预约")
	var scroll := ScrollContainer.new()
	scroll.name = "LibraryLocationScroll"; scroll.position = Vector2(0,54); scroll.size = Vector2(378,b.APP_HEIGHT-54)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; root.add_child(scroll)
	var inner := Control.new(); inner.custom_minimum_size = Vector2(370,686); scroll.add_child(inner)
	b._label(inner,"基础馆 · 基础图书馆",Rect2(16,12,344,30),20,Color("164f93")).name = "LibraryLocationIdentity"
	b._label(inner,"校区东侧，圆环顶塔楼。入口在南侧。",Rect2(16,50,344,44),16,Color("405567"))
	b._panel(inner,Rect2(14,104,350,284),Color("d7e5dc"),Color("7d8a80"),0,1)
	plate_crop(inner,MAP_REGION,Rect2(14,104,350,284),"LibraryCampusMap")
	b._panel(inner,Rect2(307,111,48,28),Color("fff5dd"),Color("405567"),0,1)
	b._label(inner,"北 ↑",Rect2(309,112,44,26),16,Color("243245"),HORIZONTAL_ALIGNMENT_CENTER)
	# Public landmark labels on the same source crop; no player marker or path.
	b._panel(inner,Rect2(53,143,96,27),Color("13202bea"))
	b._label(inner,"紫云碧峰",Rect2(55,143,92,27),16,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
	b._panel(inner,Rect2(239,354,120,28),Color("13202bea"))
	b._label(inner,LIBRARY_NAME,Rect2(242,354,114,28),16,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
	b._label(inner,"馆舍外观",Rect2(16,401,344,28),16,Color("164f93"))
	b._panel(inner,Rect2(14,439,350,185),Color("e3eee3"),Color("7d8a80"),0,1)
	plate_crop(inner,TOWER_REGION,Rect2(16,441,213,181),"LibraryTowerReference")
	b._label(inner,"圆环形楼顶\n玻璃门厅\n南侧前庭",Rect2(237,472,115,122),16,Color("243245"))
	b._label(inner,"预约中的“基础馆”就是这座建筑。",Rect2(16,638,344,38),16,Color("405567"))
	return root
