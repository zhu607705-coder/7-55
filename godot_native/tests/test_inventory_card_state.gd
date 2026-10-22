extends SceneTree
var failures:=0
var checks:=0
func _initialize()->void: run.call_deferred()
func check(value:bool,message:String)->void:
	checks+=1
	if not value: failures+=1;push_error(message)
func frames()->void:
	for unused in 5: await process_frame
func run()->void:
	var state:=root.get_node("State")
	state.developer_mode=true;state.d=state.initial()
	var shell:Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	for dimensions:Vector2i in [Vector2i(390,844),Vector2i(1440,900)]:
		root.size=dimensions;shell.size=Vector2(dimensions)
		state.begin_checkpoint("c2-dorm-exit");shell._refresh();await frames()
		var owned:Dictionary=state.d.items.duplicate(true)
		shell._show_inventory();await frames()
		var grid:GridContainer=shell.modal.find_child("InventoryGrid",true,false)
		check(grid!=null and grid.get_child_count()>=2,"real inventory owns at least two fixture items")
		for index in grid.get_child_count():
			var slot:Button=grid.get_child(index)
			slot.selection_requested.emit(slot.item_id);await frames()
			check(state.d.native.selected_item==slot.item_id,"selection calls existing shared intent")
			check(state.d.items==owned,"selection never earns or consumes objects")
			for other:Button in grid.get_children():
				check(other.get_node("HardwareDetail").selected==(other==slot),"exactly the selected object has the shape marker")
				check(other.get_global_rect().size.y>=44,"item retains touch target")
				check(shell.modal_panel.get_global_rect().encloses(other.get_global_rect()),"item remains inside responsive folder")
		shell._close_modal()
	await shell.shutdown();shell.queue_free();await frames()
	print("Inventory card state: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
