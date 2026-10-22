extends SceneTree
const Bridge=preload("res://scripts/ui/world_viewport_container.gd")
const Item=preload("res://scripts/ui/inventory_item.gd")
class Surface extends Control:
	var drops: Array=[]
	func _can_drop_data(_at: Vector2,data: Variant) -> bool: return data is Dictionary and data.get("kind")=="inventory_item"
	func _drop_data(at: Vector2,_data: Variant) -> void:drops.append(at)
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,why: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(why)
func frames(n:=3) -> void:
	for i in n:await process_frame
func mouse(point:Vector2,pressed:bool) -> void:
	var e:=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;Input.parse_input_event(e);await process_frame
func run() -> void:
	var state=root.get_node("State");state.developer_mode=true
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		root.size=dimensions
		var host:=Control.new();root.add_child(host);host.position=Vector2(30,170);host.scale=Vector2(.75,.75)
		var container:=Bridge.new();container.position=Vector2(9,12);container.size=Vector2(400,240);container.stretch=true;container.stretch_shrink=2;host.add_child(container)
		var viewport:=SubViewport.new();viewport.size=Vector2i(200,120);container.add_child(viewport)
		viewport.canvas_transform=Transform2D(.07,Vector2(2,3)).scaled(Vector2(.8,.9))
		var surface:=Surface.new();surface.position=Vector2(7,11);surface.scale=Vector2(.7,.8);surface.size=Vector2(400,250);viewport.add_child(surface);container.world_surface=surface
		await frames()
		for local in [Vector2(.1,.1),Vector2(200,120),Vector2(399.9,239.9)]:
			var pixel:Vector2=local*Vector2(viewport.size)/container.size
			var actual:=container.source_position(local)
			check((surface.get_global_transform_with_canvas()*actual).distance_to(pixel)<.001,"Canvas/local transforms invert exactly at center and edges")
		check(not container.source_position(Vector2(-.01,0)).is_finite(),"Left exterior rejected")
		check(not container.source_position(container.size).is_finite(),"Exclusive bottom-right exterior rejected")
		# Native cross-viewport mouse drop, not a direct _drop_data call.
		var item:=Item.new();item.item_id="headphone";item.text="Item";item.position=Vector2(30,40);item.size=Vector2(60,50);root.add_child(item);await frames()
		var start:=item.get_global_rect().get_center();var end:=container.get_global_transform_with_canvas()*Vector2(200,120)
		await mouse(start,true)
		for i in range(1,10):
			var move:=InputEventMouseMotion.new();move.position=start.lerp(end,i/9.0);move.global_position=move.position;move.relative=(end-start)/9.0;move.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(move);await process_frame
		check(root.gui_is_dragging(),"Cross viewport native drag starts")
		await mouse(end,false);await frames()
		check(surface.drops.size()==1,"Cross viewport dispatches once")
		if not surface.drops.is_empty():check(surface.drops[0].distance_to(container.source_position(Vector2(200,120)))<.001,"Actual dispatch uses transformed local coordinates")
		item.queue_free();host.queue_free();await frames()
	print("INVENTORY_VIEWPORT_TRANSFORM: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
