extends SceneTree
## Export the actual procedural stage as an editable Godot scene, with the
## named lamp hierarchy and mesh subresources. No screenshot/model substitution.
func _initialize()->void:run.call_deferred()
func assign_owner(node:Node,owner:Node)->void:
	for child:Node in node.get_children():child.owner=owner;assign_owner(child,owner)
func run()->void:
	var view:TextureRect=preload("res://scripts/presentation/theater_stage_view.gd").new();root.add_child(view);await process_frame
	var model:Node3D=view.stage
	var copy:Node3D=model.duplicate(0)
	copy.name="FunhouseTheaterModel"
	copy.set_script(null)
	assign_owner(copy,copy)
	var scene:=PackedScene.new();var result:int=scene.pack(copy)
	if result==OK:result=ResourceSaver.save(scene,"res://scenes/theater/funhouse_stage_editable.scn",ResourceSaver.FLAG_COMPRESS)
	print("Editable theater model export: ",result)
	copy.free();view.queue_free();await process_frame;quit(result)
