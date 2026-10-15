extends SceneTree
const Gesture=preload("res://scripts/ui/inventory_gesture.gd")
const Surface=preload("res://scripts/ui/world_viewport_container.gd")
class DropSurface extends Control:
	var allowed:=true
	var drops:Array=[]
	func _can_drop_data(_point:Vector2,_data:Variant)->bool:return allowed
	func _drop_data(point:Vector2,_data:Variant)->void:drops.append(point)
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func run()->void:
	var source:=Control.new();root.add_child(source)
	var frame:=Control.new();frame.position=Vector2(31,47);root.add_child(frame)
	var container:SubViewportContainer=Surface.new();container.position=Vector2(10,14);frame.add_child(container)
	var viewport:=SubViewport.new();container.add_child(viewport)
	var world:=DropSurface.new();viewport.add_child(world);container.world_surface=world
	container.stretch=true
	for dimensions:Vector2 in [Vector2(372,616),Vector2(960,540),Vector2(824,314)]:
		for scale_value:float in [.5,1.0,1.3]:
			frame.scale=Vector2.ONE*scale_value;container.size=dimensions
			world.position=Vector2(3,7);world.scale=Vector2(.9,1.1)
			for zoom:float in [.45,.85,1.6]:
				var camera:=Vector2(280,750)
				var target:=Vector2(282,755)
				var local:Vector2=(target-camera)*zoom+dimensions/2
				var pixel:Vector2=world.get_global_transform_with_canvas()*local
				var point:Vector2=container.get_global_transform_with_canvas()*(pixel*container.size/Vector2(viewport.size))
				var data:Dictionary={"kind":"inventory_item","item":"greaseTissue"}
				source.force_drag(data,null)
				Gesture.capture_release(root,point,"wrongItem")
				check(not data.has("_inventory_release"),"a different inventory source cannot tag the active drag")
				Gesture.capture_release(root,point,"greaseTissue")
				var resolved:Vector2=container.release_source_position(Vector2(999,999),data)
				check(resolved.is_equal_approx(local),"event point ignores stale polled fallback across portrait/desktop/container scales")
				check(((resolved-dimensions/2)/zoom+camera).is_equal_approx(target),"camera zoom and pan inverse retain the exact original target")
				check(Gesture.release_position(data,viewport)==null,"release cannot leak into a different source viewport")
				check(container._can_drop_data(Vector2(-999,-999),data),"bridge preflight accepts valid release despite outside polled fallback")
				world.drops.clear();container._drop_data(Vector2(-999,-999),data)
				check(world.drops.size()==1 and Vector2(world.drops[0]).is_equal_approx(local),"bridge dispatch uses release point exactly once")
				world.allowed=false
				check(not container._can_drop_data(Vector2(-999,-999),data),"release snapshot cannot bypass the original world input gate")
				world.allowed=true
				data._inventory_release.point=Vector2(-999,-999)
				check(not container.release_source_position(Vector2.ZERO,data).is_finite(),"outside-surface release remains rejected")
				check(not container._can_drop_data(dimensions/2,data),"bridge preflight rejects outside release despite valid polled fallback")
				world.drops.clear();container._drop_data(dimensions/2,data)
				check(world.drops.is_empty(),"outside release never reaches the original world action")
				data._inventory_release.frame=-1
				check(container.release_source_position(Vector2(9,8),data)==Vector2(9,8),"a stale release never overrides another dispatch")
				root.gui_cancel_drag()
				var next:Dictionary={"kind":"inventory_item","item":"greaseTissue"}
				source.force_drag(next,null)
				check(not next.has("_inventory_release"),"replacement native drag inherits no released point")
				root.gui_cancel_drag()
	frame.free();source.free();await process_frame
	print("INVENTORY_RELEASE_COORDINATES ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
