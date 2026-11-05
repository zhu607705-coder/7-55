extends SceneTree
## Deterministic import only: preserve generated originals; binary alpha and uniform scale.

# On the stack master these four cuts pass through uninterrupted book blocks.
# Remove equal lengths of shelving stock, preserving the posts, rails and foot cap.
func fit_stack_bays(master:Image, size:Vector2i)->Image:
	var scaled_height:=roundi(float(master.get_height())*size.x/master.get_width())
	master.resize(size.x,scaled_height,Image.INTERPOLATE_NEAREST)
	var trim:=scaled_height-size.y
	var stack:=Image.create_empty(size.x,size.y,false,Image.FORMAT_RGBA8)
	var source_y:=0
	var dest_y:=0
	for bay:int in 4:
		var cut:=roundi(trim*(bay+1)/4.0)-roundi(trim*bay/4.0)
		var center:=roundi(scaled_height*[.12,.30,.48,.665][bay])
		var length:=center-floori(cut/2.0)-source_y
		stack.blit_rect(master,Rect2i(0,source_y,size.x,length),Vector2i(0,dest_y))
		source_y+=length+cut
		dest_y+=length
	stack.blit_rect(master,Rect2i(0,source_y,size.x,scaled_height-source_y),Vector2i(0,dest_y))
	return stack

func _initialize()->void:
	var args:=OS.get_cmdline_user_args()
	if args.is_empty():quit(2);return
	var base:String=args[0]
	var source_dir:=base.path_join("art_source/library_object_depth_20261104")
	var output:=base.path_join("assets/native/library_object_depth_20261104")
	DirAccess.make_dir_recursive_absolute(output)
	var sources:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source_dir.path_join("sources.json")))
	var report:Dictionary={"engine":Engine.get_version_info().string,"assets":{}}
	var direction:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("docs/art/art_direction_v1.json")))
	var palette:Array=[]
	for hex:String in direction.palette.colors:palette.append(Color(hex))
	var color_cache:Dictionary={}
	for id:String in sources:
		var source_path:String=sources[id]
		var path:String=source_path if source_path.is_absolute_path() else source_dir.path_join(source_path)
		var image:=Image.load_from_file(path)
		if image==null or image.is_empty():push_error("Missing generated source "+id);quit(1);return
		image.convert(Image.FORMAT_RGBA8)
		var original_size:=image.get_size()
		var is_base:=id.begins_with("clean_plate")
		var face_pixels:=0
		if is_base:
			# Crop to the source aspect, then scale uniformly. Never stretch the map.
			var ratio:=minf(float(image.get_width())/1500,float(image.get_height())/900)
			var extent:=Vector2i(roundi(1500*ratio),roundi(900*ratio))
			image=image.get_region(Rect2i((image.get_size()-extent)/2,extent))
			image.resize(1500,900,Image.INTERPOLATE_NEAREST)
		else:
			# Remove semitransparent generated halos; do not key out a background color.
			var bytes:=image.get_data()
			for index:int in range(3,bytes.size(),4):bytes[index]=255 if bytes[index]>=128 else 0
			image=Image.create_from_data(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8,bytes)
			var ink:=image.get_used_rect()
			image=image.get_region(ink)
			# Keep five native pixels per original-world pixel; every resize is uniform.
			if id in ["shelf_divider","shelf_row"]:
				var size:=Vector2i(200,1370) if id=="shelf_divider" else Vector2i(225,1155)
				# In the master the vertical south elevation starts below the rail at y=1429.
				face_pixels=roundi((ink.end.y-1429)*float(size.x)/ink.size.x)
				image=fit_stack_bays(image,size)
			else:
				if id=="water_dispenser":
					# A short lower service panel and bottle suit a chest-high floor model.
					var compact:=Image.create_empty(ink.size.x,ink.size.y-350,false,Image.FORMAT_RGBA8)
					var first:=310-ink.position.y
					var second:=1250-ink.position.y
					compact.blit_rect(image,Rect2i(0,0,ink.size.x,first),Vector2i.ZERO)
					compact.blit_rect(image,Rect2i(0,first+110,ink.size.x,second-first-110),Vector2i(0,first))
					compact.blit_rect(image,Rect2i(0,second+240,ink.size.x,ink.size.y-second-240),Vector2i(0,second-110))
					image=compact
				var scale_value:=minf(1.0,700.0/maxi(image.get_width(),image.get_height()))
				image.resize(maxi(1,roundi(image.get_width()*scale_value)),maxi(1,roundi(image.get_height()*scale_value)),Image.INTERPOLATE_NEAREST)
			if id=="glass_panel":
				for y:int in image.get_height():
					for x:int in image.get_width():
						var color:=image.get_pixel(x,y)
						if color.a>0 and color.b>color.r*1.1 and color.g>color.r*1.1 and color.v>.4:
							color.a=170.0/255;image.set_pixel(x,y,color)
		# One shared project palette; cached color buckets keep the transform reproducible.
		var pixels:=image.get_data()
		for index:int in range(0,pixels.size(),4):
			if pixels[index+3]==0:continue
			if is_base:
				# Nearby generated fabric values straddle palette ramps. Keep quiet carpet
				# clusters instead of turning that subpixel variation into scattered dots.
				var at:=Vector2((index/4)%image.get_width(),(index/4)/image.get_width())
				var carpet:bool=Rect2(944,87,510,475).has_point(at) or Rect2(156,435,333,222).has_point(at) or Rect2(590,435,340,222).has_point(at)
				if carpet and pixels[index+2]>pixels[index]*1.2 and pixels[index+1]>pixels[index]*1.2 and pixels[index+1]<105:
					var fabric:=Color("243F5A")
					pixels[index]=fabric.r8;pixels[index+1]=fabric.g8;pixels[index+2]=fabric.b8
					continue
			var key:int=(int(pixels[index])>>3)*1024+(int(pixels[index+1])>>3)*32+(int(pixels[index+2])>>3)
			if not color_cache.has(key):
				var sample:=Vector3((key/1024)*8+4,((key/32)%32)*8+4,(key%32)*8+4)/255.0
				var best:=0;var distance:=INF
				for p:int in palette.size():
					var color:Color=palette[p];var delta:=sample-Vector3(color.r,color.g,color.b)
					var cost:float=delta.x*delta.x*.30+delta.y*delta.y*.59+delta.z*delta.z*.11
					if cost<distance:distance=cost;best=p
				color_cache[key]=best
			var chosen:Color=palette[color_cache[key]]
			pixels[index]=chosen.r8;pixels[index+1]=chosen.g8;pixels[index+2]=chosen.b8
		image=Image.create_from_data(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8,pixels)
		if is_base:apply_floor_joints(image)
		var destination:=output.path_join(id+".png")
		if image.save_png(destination)!=OK:quit(1);return
		report.assets[id]={"source":path,"sourceSha256":FileAccess.get_sha256(path),"outputSha256":FileAccess.get_sha256(destination),"masterSize":[original_size.x,original_size.y],"size":[image.get_width(),image.get_height()],"binaryAlpha":not is_base and id!="glass_panel","uniformScale":true,"palette":direction.palette.name}
		if face_pixels>0:report.assets[id].southFacePixels=face_pixels
	var file:=FileAccess.open(source_dir.path_join("normalization.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close()
	print("LIBRARY_NORMALIZE ",report.assets.size()," assets")
	quit()

# Project a square floor tile to 40 x 22 world pixels. Only replace the connected
# sandstone floor; window frames, carpet, threshold and wall courses stay registered.
func apply_floor_joints(plate:Image)->void:
	var stone:=plate.get_pixel(520,350)
	var light_tile:=plate.get_pixel(530,403)
	var width:=plate.get_width()
	var height:=plate.get_height()
	var seen:=PackedByteArray()
	seen.resize(width*height)
	var todo:=PackedInt32Array([350*width+520])
	while not todo.is_empty():
		var at:=todo[-1]
		todo.resize(todo.size()-1)
		if seen[at]:continue
		seen[at]=1
		var x:=at%width
		var y:=floori(at/float(width))
		var tone:=plate.get_pixel(x,y)
		if tone!=stone and tone!=light_tile:continue
		var gx:=(x-4)%40
		var gy:=(y-3)%22
		plate.set_pixel(x,y,Color("c79b62") if gx==0 or gy==0 else stone)
		if x>0:todo.append(at-1)
		if x+1<width:todo.append(at+1)
		if y>0:todo.append(at-width)
		if y+1<height:todo.append(at+width)
