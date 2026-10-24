extends Node2D
## Presentation-only props in the chest artwork's native source coordinates.
## Controller snapshots describe occupancy; this renderer never changes it.
const KIT_PATH: String="res://assets/native/theater_chest_20261023/puzzle_kit.png"
const WOOD_PATH: String="res://assets/native/theater_chest_20261023/prop_chest_overhead_body_v2.png"
const ATLAS: Dictionary={
	"fan":Rect2(108,65,351,338),
	"butterfly":Rect2(605,65,351,338),
	"lamp":Rect2(1110,65,351,338),
	"rotor":Rect2(33,452,506,502),
	"crank":Rect2(599,566,453,292),
	"note":Rect2(1113,554,378,367),
}
const ROTOR_CENTER:=Vector2(620,700)
const ROTOR_RECT:=Rect2(455,535,330,330)
const DRAWER_RECT:=Rect2(855,766,300,110)
const PARTS: Dictionary={
	"fan":Rect2(324,436,92,88),
	"butterfly":Rect2(372,467,92,88),
	"lamp":Rect2(351,508,92,88),
	"crank":Rect2(900,425.5,200,129),
	"note":Rect2(310,445,230,180),
	"slot0":Rect2(574,562,92,88),
	"slot1":Rect2(655.406388,703,92,88),
	"slot2":Rect2(492.593612,703,92,88),
	"axle":Rect2(588,668,64,64),
	"drawer":Rect2(941,841,128,34),
	"brush":Rect2(881,793,122,42),
	"vent_clue":Rect2(1021,779,115,68),
}
const BRASS:=Color("c79b62")
const INK:=Color("44332d")
var snapshot: Dictionary={}
var selected: String=""
var _clue_driven:=false
var _drawer_driven:=false
var hovered: String="":
	set(value):hovered=value;queue_redraw()
var turn_angle: float=0.0:
	set(value):turn_angle=value;queue_redraw()
var clue_flip: float=0.0:
	set(value):clue_flip=clampf(value,0.0,1.0);_clue_driven=true;queue_redraw()
var drawer_amount: float=0.0:
	set(value):drawer_amount=clampf(value,0.0,1.0);_drawer_driven=true;queue_redraw()
var pickup_amount: float=0.0:
	set(value):pickup_amount=clampf(value,0,1);queue_redraw()
var placement_piece: String="":
	set(value):placement_piece=value;queue_redraw()
var placement_from:=Vector2.ZERO:
	set(value):placement_from=value;queue_redraw()
var placement_to:=Vector2.ZERO:
	set(value):placement_to=value;queue_redraw()
var placement_amount: float=0.0:
	set(value):placement_amount=clampf(value,0.0,1.0);queue_redraw()
var held_piece: String=""
var held_offset:=Vector2.ZERO:
	set(value):held_offset=value;_sync_volume();queue_redraw()
var held_lift:=0.0:
	set(value):held_lift=value;_sync_volume();queue_redraw()
var kit: Texture2D
var wood: Texture2D
var volume_view: SubViewport
var volume: Node3D

static func part_rect(id: String) -> Rect2:
	return PARTS.get(id,Rect2())

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	kit=_texture(KIT_PATH);wood=_texture(WOOD_PATH)
	volume_view=SubViewport.new();volume_view.name="PhysicalContentsViewport"
	volume_view.size=Vector2i(1448,1086);volume_view.transparent_bg=true;volume_view.own_world_3d=true
	volume_view.gui_disable_input=true;volume_view.render_target_update_mode=SubViewport.UPDATE_ONCE
	add_child(volume_view)
	volume=load("res://scripts/objects/theater_chest_contents_3d.gd").new()
	volume_view.add_child(volume)
	queue_redraw()

func _texture(path: String) -> Texture2D:
	if FileAccess.file_exists(path+".import"):return load(path)
	var pixels:=Image.load_from_file(path)
	return null if pixels.is_empty() else ImageTexture.create_from_image(pixels)

func set_state(value: Dictionary, selected_piece: String="") -> void:
	snapshot=value.duplicate(true);selected=selected_piece;_sync_volume();queue_redraw()

func _sync_volume() -> void:
	if is_instance_valid(volume):
		volume.update_state(snapshot,selected,hovered,turn_angle,clue_flip,drawer_amount,placement_piece,placement_from,placement_to,placement_amount,pickup_amount,held_piece,held_offset,held_lift)
		volume_view.render_target_update_mode=SubViewport.UPDATE_ONCE

func get_part_polygon(id: String) -> PackedVector2Array:
	if is_instance_valid(volume) and volume.has_method("projected_polygon"):
		if id=="axle" and bool(snapshot.get("crank_installed",false)):
			# The visible handle is the target once fitted, including its axle.
			var handle: PackedVector2Array=volume.projected_polygon("crank")
			var axle:=part_rect("axle")
			handle.append_array(PackedVector2Array([axle.position,Vector2(axle.end.x,axle.position.y),axle.end,Vector2(axle.position.x,axle.end.y)]))
			return Geometry2D.convex_hull(handle)
		var points: PackedVector2Array=volume.projected_polygon(id)
		if not points.is_empty():return points
	var rect:=part_rect(id)
	return PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])

func part_anchor(id: String) -> Vector2:
	_sync_volume()
	if is_instance_valid(volume):return volume.projected_anchor(id)
	return part_rect(id).get_center()

func preview_held(piece: String, offset: Vector2, lift: float) -> void:
	held_piece=piece;held_offset=offset;held_lift=lift
	_sync_volume();queue_redraw()

func _draw() -> void:
	if kit==null:return
	if is_instance_valid(volume):
		volume.update_state(snapshot,selected,hovered,turn_angle,clue_flip,drawer_amount,placement_piece,placement_from,placement_to,placement_amount,pickup_amount,held_piece,held_offset,held_lift)
		volume_view.render_target_update_mode=SubViewport.UPDATE_ONCE
		_draw_drawer()
		draw_texture(volume_view.get_texture(),Vector2.ZERO)
		_draw_note()
		return
	_draw_drawer()
	_draw_rotor()
	var remaining: Array=snapshot.get("remaining",["fan","butterfly","lamp","crank"])
	for id: String in ["fan","butterfly","lamp","crank"]:
		if id in remaining and id!=placement_piece:
			_blit(id,part_rect(id));_highlight(id,part_rect(id))
	_draw_note()
	if not placement_piece.is_empty() and ATLAS.has(placement_piece):
		var start_size: Vector2=part_rect(placement_piece).size
		var end_size:=Vector2(130,84) if placement_piece=="crank" else Vector2(62,60)
		var dimensions:=start_size.lerp(end_size,placement_amount)
		var center:=placement_from.lerp(placement_to,placement_amount)
		_blit(placement_piece,Rect2(center-dimensions*.5,dimensions))

func _draw_rotor() -> void:
	var settled_angle:=float(snapshot.get("turns",0))*TAU/3.0
	var total_angle:=settled_angle+turn_angle
	draw_set_transform(ROTOR_CENTER,total_angle)
	_blit("rotor",Rect2(ROTOR_RECT.position-ROTOR_CENTER,ROTOR_RECT.size))
	var slots: Array=snapshot.get("slots",["","",""])
	for index: int in range(3):
		var id:=str(slots[index]) if index<slots.size() else ""
		var target: Rect2=part_rect("slot"+str(index))
		# The controller has already permuted canonical slot occupancy after a
		# settled turn. Rotate only the in-flight position, while retaining the
		# platter's cumulative orientation on each mounted tile.
		var center:=ROTOR_CENTER+(target.get_center()-ROTOR_CENTER).rotated(turn_angle)
		draw_set_transform(center,total_angle)
		var local:=Rect2(-target.size*.5,target.size)
		if ATLAS.has(id) and id!=placement_piece:_blit(id,local)
		_highlight("slot"+str(index),local)
		if id==selected:_outline(local,Color(BRASS,.8))
	if bool(snapshot.get("crank_installed",false)) and placement_piece!="crank":
		# The pin stays on the axle; the handle sits between the upper and
		# right sockets instead of hiding either fitted tile.
		draw_set_transform(ROTOR_CENTER,total_angle-PI*.25)
		var ratio:=130.0/453.0
		_blit("crank",Rect2(-Vector2(26,84)*ratio,Vector2(453,292)*ratio))
	draw_set_transform(ROTOR_CENTER,total_angle)
	_highlight("axle",Rect2(-Vector2(32,32),Vector2(64,64)))
	draw_set_transform(Vector2.ZERO)

func _draw_note() -> void:
	if snapshot.get("cleared",[]).size()<3:return
	var target:=part_rect("note")
	var flip:=clue_flip if _clue_driven else (1.0 if bool(snapshot.get("clue_open",false)) else 0.0)
	var face:=absf(cos(PI*flip))
	_projected_blit("note",target,face,target.get_center().x)
	if bool(snapshot.get("clue_open",false)) and flip>=.98:
		# A physical assembly sketch: matching edge notches, then a cam turn.
		# It does not repeat the earlier program-order puzzle's symbol sequence.
		var paper:=Rect2(343,478,164,112)
		draw_rect(paper,Color("c9b890"))
		draw_rect(Rect2(357,491,52,40),INK,false,2)
		draw_rect(Rect2(357,549,52,30),INK,false,2)
		for x: float in [369,389]:
			draw_rect(Rect2(x,520,7,12),INK)
			draw_rect(Rect2(x,549,7,12),INK,false,2)
		draw_line(Vector2(383,534),Vector2(383,544),INK,2)
		draw_polyline(PackedVector2Array([Vector2(378,540),Vector2(383,545),Vector2(388,540)]),INK,2)
		draw_arc(Vector2(458,525),24,-PI*.8,PI*.6,24,INK,2)
		draw_polyline(PackedVector2Array([Vector2(445,545),Vector2(451,551),Vector2(453,542)]),INK,2)
		draw_line(Vector2(458,525),Vector2(480,542),INK,3)
		draw_line(Vector2(449,566),Vector2(489,566),INK,3)
		draw_polyline(PackedVector2Array([Vector2(457,559),Vector2(449,566),Vector2(457,573)]),INK,2)
	_highlight("note",target)

func _draw_drawer() -> void:
	var progress:=drawer_amount if _drawer_driven else (1.0 if bool(snapshot.get("drawer_open",false)) else 0.0)
	draw_rect(DRAWER_RECT,Color("171514"))
	# The clue is drawn on a cropped region of the same aged paper, under
	# the actual 3D floor hatch and its solid inner lip.
	var paper:=part_rect("vent_clue")
	var paper_source:=Rect2(1113,680,378,190)
	draw_texture_rect_region(kit,_contain(paper_source,paper),paper_source,Color("ddcba8"))
	var pencil:=Color("554639")
	var duct:=Rect2(1036,794,84,28)
	draw_rect(duct,pencil,false,1.6)
	for index: int in range(6):
		var x: float=1043+index*13
		draw_line(Vector2(x,797),Vector2(x,819),pencil,1)
	draw_polyline(PackedVector2Array([Vector2(1029,815),Vector2(1029,835),Vector2(1123,835),Vector2(1123,824)]),pencil,1.5)
	draw_polyline(PackedVector2Array([Vector2(1119,829),Vector2(1123,824),Vector2(1127,829)]),pencil,1.5)
	if is_instance_valid(volume):return
	var visible_height:=DRAWER_RECT.size.y*(1.0-progress)
	if visible_height>0.1 and wood!=null:
		# The board slides under the front lip. Source cropping keeps its wood
		# grain unscaled and confines the moving surface to its own recess.
		var moving:=Rect2(DRAWER_RECT.position+Vector2(0,DRAWER_RECT.size.y*progress),Vector2(DRAWER_RECT.size.x,visible_height))
		draw_texture_rect_region(wood,moving,Rect2(DRAWER_RECT.position,moving.size))
		draw_line(moving.position,moving.position+Vector2(moving.size.x,0),Color("33251e"),2)
	draw_rect(DRAWER_RECT,Color("33251e"),false,2)
	var handle:=part_rect("drawer")
	# The fixed pull rail stays reachable when the panel has slid underneath.
	draw_rect(Rect2(handle.position+Vector2(6,11),Vector2(handle.size.x-12,14)),Color("35291c"))
	draw_rect(Rect2(handle.position+Vector2(10,9),Vector2(handle.size.x-20,10)),BRASS)
	for x: float in [handle.position.x+12,handle.end.x-12]:
		draw_circle(Vector2(x,handle.position.y+14),6,Color("70503b"))
		draw_circle(Vector2(x-1,handle.position.y+13),3,BRASS)
	_highlight("drawer",handle)

func _contain(source: Rect2, target: Rect2) -> Rect2:
	var dimensions:=source.size*minf(target.size.x/source.size.x,target.size.y/source.size.y)
	return Rect2(target.get_center()-dimensions*.5,dimensions)

func _blit(id: String, target: Rect2) -> void:
	var source: Rect2=ATLAS[id]
	draw_texture_rect_region(kit,_contain(source,target),source)

func _projected_blit(id: String, target: Rect2, cosine: float, pivot_x: float) -> void:
	if cosine<.004:return
	var source: Rect2=ATLAS[id]
	var destination:=_contain(source,target)
	var source_points:=PackedVector2Array([source.position,Vector2(source.end.x,source.position.y),source.end,Vector2(source.position.x,source.end.y)])
	var points:=PackedVector2Array([destination.position,Vector2(destination.end.x,destination.position.y),destination.end,Vector2(destination.position.x,destination.end.y)])
	var uv:=PackedVector2Array()
	for index: int in range(4):
		points[index].x=pivot_x+(points[index].x-pivot_x)*cosine
		uv.append(source_points[index]/kit.get_size())
	draw_polygon(points,PackedColorArray([Color.WHITE]),uv,kit)

func _highlight(id: String, target: Rect2) -> void:
	if id==selected:_outline(target,Color(BRASS,.85))
	elif id==hovered:_outline(target,Color(BRASS,.45))

func _outline(target: Rect2, color: Color) -> void:
	draw_rect(target.grow(3),Color(color,.13),false,6)
	draw_rect(target.grow(1),color,false,2)
