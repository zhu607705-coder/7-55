extends SceneTree
## Actual GPU seam comparison. Reference uploads are small same-source crops only.
const Tiled=preload("res://scripts/presentation/source_tiled_texture.gd")
var checks:=0
var failures:=0
class Surface:
	extends Control
	var plate:RefCounted
	var reference:Texture2D
	var source:Rect2
	var reference_origin:=Vector2.ZERO
	var destination:Rect2
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),Color("a010a0"))
		if plate!=null:plate.draw_region(self,destination,source)
		else:draw_texture_rect_region(reference,destination,Rect2(source.position-reference_origin,source.size),Color.WHITE,false,false)
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;print("FAIL: ",label)
func viewport(surface:Surface)->SubViewport:
	var view:=SubViewport.new();view.size=Vector2i(640,360);view.disable_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(view);surface.size=Vector2(640,360);view.add_child(surface);return view
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated rendering profile")
	if failures:quit(1);return
	check(DisplayServer.get_name()!="headless","GPU renderer is active rather than dummy headless output")
	if failures:quit(1);return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS,true)
	var plate:=Tiled.new();plate.configure(Tiled.SOURCE)
	check(plate.ensure_loaded(),"production adapter loads all seven imported small textures")
	if not plate.ready:quit(1);return
	var original:=Image.load_from_file(ProjectSettings.globalize_path("res://../"+str(plate.manifest.sourceFile)))
	var actual:=Surface.new();actual.plate=plate
	var reference:=Surface.new()
	var av:=viewport(actual);var rv:=viewport(reference)
	var capture_image:Image
	var tie_probe:=OS.get_environment("TILED_RENDER_TIE_PROBE")=="1"
	var capture:=OS.get_environment("TILED_RENDER_CAPTURE")
	var maximum_error:=0.0
	for seam in [2046,4092,6138,8184,10230,12276]:
		for config:Array in [[CanvasItem.TEXTURE_FILTER_NEAREST,1.0],[CanvasItem.TEXTURE_FILTER_LINEAR,.63],[CanvasItem.TEXTURE_FILTER_LINEAR,1.1]]:
			var scale_value:float=float(config[1]);var filter_value:int=int(config[0])
			# Do not compare two nearest-sampler UV representations exactly at a
			# texel boundary: either neighboring texel is valid after GPU rounding.
			# A 1/8px source offset leaves the sample safely inside the same texel.
			var source:=Rect2(float(seam)-250.125,200.5,500.5,280)
			if tie_probe:source.position.x=float(seam)-250.25
			var region:=Rect2i(int(floor(source.position.x))-2,198,506,285)
			actual.source=source;reference.source=source
			actual.destination=Rect2(Vector2(13.25,17.5),source.size*scale_value);reference.destination=actual.destination
			actual.texture_filter=filter_value;reference.texture_filter=filter_value
			reference.reference_origin=region.position
			reference.reference=ImageTexture.create_from_image(original.get_region(region))
			actual.queue_redraw();reference.queue_redraw()
			await process_frame;await RenderingServer.frame_post_draw
			var a:=av.get_texture().get_image();var b:=rv.get_texture().get_image()
			check(a!=null and b!=null and a.get_size()==Vector2i(640,360),"GPU output exists seam="+str(seam)+" filter="+str(filter_value)+" scale="+str(scale_value))
			if a==null or b==null:continue
			var compared:=0;var wrong:=0;var bounds:=actual.destination.grow(-3)
			for y in range(int(bounds.position.y),int(bounds.end.y),5):
				for x in range(int(bounds.position.x),int(bounds.end.x),5):
					var ca:=a.get_pixel(x,y);var cb:=b.get_pixel(x,y)
					var error:=maxf(absf(ca.r-cb.r),maxf(absf(ca.g-cb.g),absf(ca.b-cb.b)))
					maximum_error=maxf(maximum_error,error);compared+=1
					if error>2.1/255.0:wrong+=1
			# Dense samples on both sides of the seam detect filtering/coverage cracks.
			var seam_x:=actual.destination.position.x+(float(seam)-source.position.x)*scale_value
			for y in range(int(bounds.position.y),int(bounds.end.y)):
				for x in range(int(floor(seam_x))-2,int(ceil(seam_x))+3):
					var ca:=a.get_pixel(x,y);var cb:=b.get_pixel(x,y)
					if maxf(absf(ca.r-cb.r),maxf(absf(ca.g-cb.g),absf(ca.b-cb.b)))>2.1/255.0:wrong+=1
			check(compared>500 and wrong==0,"tiles match native same-source crop including seam texels seam="+str(seam)+" filter="+str(filter_value)+" scale="+str(scale_value)+" mismatches="+str(wrong))
			if tie_probe and seam==12276 and filter_value==CanvasItem.TEXTURE_FILTER_NEAREST and not capture.is_empty():
				var diff:=Image.create(640,360,false,Image.FORMAT_RGBA8);diff.fill(Color.BLACK)
				var columns:Dictionary={};var rows:Dictionary={};var min_x:=640;var max_x:=0;var count:=0
				for y in range(int(bounds.position.y),int(bounds.end.y)):
					for x in range(int(bounds.position.x),int(bounds.end.x)):
						var ca:=a.get_pixel(x,y);var cb:=b.get_pixel(x,y)
						var error:=maxf(absf(ca.r-cb.r),maxf(absf(ca.g-cb.g),absf(ca.b-cb.b)))
						if error>2.1/255.0:
							diff.set_pixel(x,y,Color(1,1,1));columns[str(x)]=int(columns.get(str(x),0))+1;rows[str(y)]=int(rows.get(str(y),0))+1;count+=1;min_x=mini(min_x,x);max_x=maxi(max_x,x)
				var composite:=Image.create(1920,360,false,Image.FORMAT_RGBA8)
				composite.blit_rect(a,Rect2i(0,0,640,360),Vector2i.ZERO);composite.blit_rect(b,Rect2i(0,0,640,360),Vector2i(640,0));composite.blit_rect(diff,Rect2i(0,0,640,360),Vector2i(1280,0));composite.save_png(capture.trim_suffix(".png")+"-tie.png")
				var output:=FileAccess.open(capture.trim_suffix(".png")+"-tie.json",FileAccess.WRITE)
				output.store_string(JSON.stringify({"seamWorld":seam,"seamScreenX":seam_x,"sourceRect":[source.position.x,source.position.y,source.size.x,source.size.y],"destinationRect":[actual.destination.position.x,actual.destination.position.y,actual.destination.size.x,actual.destination.size.y],"mismatchedPixels":count,"minScreenX":min_x,"maxScreenX":max_x,"mismatchesByColumn":columns,"mismatchesByRow":rows,"layout":"actual-left/reference-middle/threshold-diff-right"},"\t"));output.close()
			if seam==12276 and filter_value==CanvasItem.TEXTURE_FILTER_LINEAR and scale_value>1:
				capture_image=Image.create(1280,360,false,Image.FORMAT_RGBA8)
				capture_image.blit_rect(a,Rect2i(0,0,640,360),Vector2i.ZERO);capture_image.blit_rect(b,Rect2i(0,0,640,360),Vector2i(640,0))
	if not capture.is_empty() and capture_image!=null:check(capture_image.save_png(capture)==OK,"write temporary actual-left/reference-right seam review PNG")
	av.free();rv.free()
	print("SOURCE_TILED_RENDER: ",checks," checks; ",failures," failures; max_sample_error=",maximum_error)
	quit(1 if failures else 0)
