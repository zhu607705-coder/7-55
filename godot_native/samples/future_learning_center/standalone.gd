extends Node
## The same floor and workbench controllers, in a separate no-autoload project.
var host:SubViewportContainer
var world:Node2D
func _ready()->void:
	host=SubViewportContainer.new();host.size=Vector2(960,540);host.stretch=false;add_child(host)
	var viewport:=SubViewport.new();viewport.size=Vector2i(960,540);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;host.add_child(viewport)
	world=preload("res://campuses/future_learning_center/scripts/floor_view.gd").new();viewport.add_child(world)
	get_tree().root.size_changed.connect(fit);fit()
	world.load_floor(2)
	var point:Array=world.data.workshopReference.capture
	if not world.set_foot(Vector2(point[0],point[1])):push_error("Workshop review spawn is blocked")
func fit()->void:
	var ratio:float=minf(get_viewport().size.x/960.0,get_viewport().size.y/540.0)
	host.scale=Vector2.ONE*ratio;host.position=(Vector2(get_viewport().size)-Vector2(960,540)*ratio)/2
