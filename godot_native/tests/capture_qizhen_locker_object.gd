extends SceneTree
## Actual GPU visual fixture; declared prerequisites, no claimed player-earned run.
const Locker=preload("res://scripts/presentation/qizhen_locker_object.gd")
const Lake=preload("res://scripts/chapters/c3_lake.gd")
class Painter extends Control:
	var item:RefCounted
	var s:Dictionary
	var show_object:=false
	var mode_mix:=0.0
	var plate:Texture2D=load(Locker.PLATE)
	func _draw()->void:
		draw_texture(plate,Vector2.ZERO)
		draw_rect(Rect2(Vector2.ZERO,plate.get_size()),Color(.03,.15,.26,mode_mix*.3))
		if show_object:item.draw(self,{"origin":Vector2.ZERO,"zoom":1.,"player":Vector2(430,835),"mode_mix":mode_mix},s,false)
func _initialize()->void:run.call_deferred()
func capture(vp:SubViewport,painter:Painter,path:String)->Image:
	painter.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
	var image:=vp.get_texture().get_image();image.save_png(path);return image
func changes(base:Image,pose:Image)->Dictionary:
	var outside:=0;var inside:=0
	for y:int in 941:
		for x:int in 1672:
			if base.get_pixel(x,y)==pose.get_pixel(x,y):continue
			if Locker.FACE.has_point(Vector2(x,y)):inside+=1
			else:outside+=1
	return {"insideFace":inside,"outsideFace":outside}
func run()->void:
	if DisplayServer.get_name()=="headless" or not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS,true)
	var out:=OS.get_environment("QIZHEN_LOCKER_OUTPUT")
	if out.is_empty():quit(2);return
	DirAccess.make_dir_recursive_absolute(out)
	var s:Dictionary=root.get_node("State").initial()
	s.native.merge({"chapter":3,"scene":"qizhen_lake","page":"c3_lake","mode":"light","player":{"x":430.,"y":835.}},true)
	s.qizhenLake.merge({"active":true,"phase":"tool_chain","zone":"dock","vehicle":"on_foot","lockerOpened":false},true)
	s.items.rustedLockerKey=true;s.items.nylonCord=false
	var item:RefCounted=Locker.new();item.sync(s)
	var vp:=SubViewport.new();vp.size=Vector2i(1672,941);vp.disable_3d=true;vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
	var painter:=Painter.new();painter.item=item;painter.s=s;painter.size=Vector2(1672,941);painter.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;vp.add_child(painter)
	var base:=await capture(vp,painter,out.path_join("00-original-plate.png"))
	painter.show_object=true
	var closed:=await capture(vp,painter,out.path_join("01-closed-object.png"))
	var closed_equal:bool=base.get_data()==closed.get_data()
	var controller:RefCounted=Lake.new();controller.dispatch(s,"c3_lake_target:qizhen_use_item_1");item.sync(s)
	var states:Array=[];var changed_pixels:Array=[];var all_poses_confined:=true
	for row:Array in [[.12,"02-unlatch"],[.52,"03-opening"],[1.0,"04-open"]]:
		var left:float=row[0]
		while left>0:
			var dt:=minf(.04,left);item.tick(dt,s);left-=dt
		var pose:=await capture(vp,painter,out.path_join(str(row[1])+".png"));states.append(item.snapshot())
		var diff:=changes(base,pose);changed_pixels.append(diff);all_poses_confined=all_poses_confined and diff.outsideFace==0
	var inside_changes:int=changed_pixels[-1].insideFace;var outside_changes:int=changed_pixels[-1].outsideFace
	painter.mode_mix=1.;await capture(vp,painter,out.path_join("05-open-dark.png"))
	var report={"closedObjectPixelIdenticalToOriginal":closed_equal,"openedDifferentPixelsInsideFace":inside_changes,"openedDifferentPixelsOutsideFace":outside_changes,"allSampledPosesConfinedToSourceFace":all_poses_confined,"poseChanges":changed_pixels,"snapshots":states,"scope":"Actual4.7.1 GPU object rendering at1:1 source size; fixture prerequisites then existing controller transaction. Manual fixture time samples, not browser/physical-phone or full earned-route acceptance."}
	var file:=FileAccess.open(out.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("QIZHEN_LOCKER_GPU ",JSON.stringify(report));painter.item=null;item=null;vp.free();quit(0 if closed_equal and inside_changes>0 and all_poses_confined else 1)
