extends Node2D
## Two compatible native props inserted at their former draw positions. This adapter never
## handles input or saves progress; the original dispatcher remains the only owner.
const Room=preload("res://scripts/games/chapter4_room204_model.gd")
const TableScene=preload("res://scenes/objects/room204_table.tscn")
const Table2Scene=preload("res://scenes/objects/room204_table_2.tscn")
const SCENES={"table:group_table_1":TableScene,"table:group_table_2":Table2Scene}
const KEY="table:group_table_1"
class DrawPass extends Node2D:
	var world: Control
	var before: bool
	func _draw() -> void:
		if is_instance_valid(world): world.draw_room204_object_pass(self,before)
	func register_object_surface(ids: Array,geometry: Dictionary) -> void:
		if is_instance_valid(world): world.register_object_surface(ids,geometry)
var world: Control
var before_pass: DrawPass
var source_space: Node2D
var after_pass: DrawPass
var table: Node2D
var entity: Dictionary={}
var entities: Dictionary={}
var tables: Dictionary={}
func setup(owner_world: Control) -> void:
	world=owner_world
	before_pass=DrawPass.new();before_pass.name="BeforeTable";before_pass.world=world;before_pass.before=true;add_child(before_pass)
	source_space=Node2D.new();source_space.name="SourceCoordinates";add_child(source_space)
	after_pass=DrawPass.new();after_pass.name="AfterTable";after_pass.world=world;after_pass.before=false;add_child(after_pass)
	hide()
func sync(state: Dictionary,scene_id: String) -> void:
	entities={}
	if scene_id=="duan_yongping_temporal_maze":
		for e: Dictionary in Room.entities(state):
			var id: String=e.kind+":"+e.id
			if SCENES.has(id): entities[id]=e
	for id: String in tables.keys():
		if not entities.has(id):
			var retiring: Node2D=tables[id]
			source_space.remove_child(retiring);retiring.queue_free();tables.erase(id)
	for id: String in SCENES:
		if not entities.has(id): continue
		if not tables.has(id):
			var object: Node2D=SCENES[id].instantiate();source_space.add_child(object);tables[id]=object
		var object: Node2D=tables[id];var e: Dictionary=entities[id]
		object.position=e.position;object.rotation=deg_to_rad(float(e.angle))
	# Preserve the first-table inspection access used by existing callers/tests.
	table=tables.get(KEY);entity=entities.get(KEY,{})
	visible=not tables.is_empty()
func owns_entity(id: String) -> bool:
	return entities.has(id) and tables.has(id) and is_instance_valid(tables[id])
func has_objects() -> bool:
	return not tables.is_empty()
func configure_view(origin: Vector2,zoom: float) -> void:
	source_space.position=origin;source_space.scale=Vector2.ONE*zoom
	before_pass.queue_redraw();after_pass.queue_redraw()
func front_of_player(player: Vector2) -> bool:
	# These two compatible source tables are adjacent in paint order at y710.
	# Other-depth chairs are intentionally outside this bounded adapter.
	for id: String in SCENES:
		if owns_entity(id): return tables[id].position.y+1>player.y
	return false
func footprint_bounds(id: String=KEY) -> Rect2:
	return tables[id].footprint_bounds() if owns_entity(id) else Rect2()
func contains_source_point(point: Vector2,id: String=KEY) -> bool:
	return owns_entity(id) and tables[id].contains_source_point(point)
func drag_preview(point: Vector2,zoom: float,reduced: bool) -> Control:
	for id: String in SCENES:
		if not contains_source_point(point,id): continue
		var object: Node2D=tables[id]
		object.begin_drag(reduced)
		var preview: Control=load("res://scripts/ui/room204_drag_preview.gd").new()
		preview.configure(object.get_node("OriginalAppearance"),object.rotation,zoom,reduced)
		return preview
	return null
func finish_drag(settle:=true) -> void:
	for object: Node2D in tables.values():object.finish_drag(settle)
