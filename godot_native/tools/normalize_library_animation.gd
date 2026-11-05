extends SceneTree
## Deterministic asset import: preserve generated masters, alpha and foot anchors.
var failed:=false
var palette:Array[Color]=[]
var color_cache:Dictionary={}
var report:Dictionary={"schema":"library-animation-import-v1","actors":{},"book":{}}

func _initialize()->void:run.call_deferred()

func clean_cell(source:Image)->Image:
	source.convert(Image.FORMAT_RGBA8)
	var data:PackedByteArray=source.get_data()
	for n:int in range(3,data.size(),4):data[n]=255 if data[n]>=192 else 0
	var image:=Image.create_from_data(source.get_width(),source.get_height(),false,Image.FORMAT_RGBA8,data)
	var seen:=PackedByteArray();seen.resize(image.get_width()*image.get_height())
	var biggest:=PackedInt32Array()
	for start:int in seen.size():
		if seen[start]!=0:continue
		seen[start]=1
		if data[start*4+3]==0:continue
		var queue:=PackedInt32Array([start]);var component:=PackedInt32Array()
		while not queue.is_empty():
			var at:int=queue[-1];queue.resize(queue.size()-1);component.append(at)
			var x:int=at%image.get_width();var y:int=at/image.get_width()
			for dy:int in [-1,0,1]:
				for dx:int in [-1,0,1]:
					var nx:int=x+dx;var ny:int=y+dy
					if nx<0 or ny<0 or nx>=image.get_width() or ny>=image.get_height():continue
					var next:int=ny*image.get_width()+nx
					if seen[next]!=0:continue
					seen[next]=1
					if data[next*4+3]!=0:queue.append(next)
		if component.size()>biggest.size():biggest=component
	var result:=Image.create_empty(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8)
	for at:int in biggest:result.set_pixel(at%image.get_width(),at/image.get_width(),image.get_pixel(at%image.get_width(),at/image.get_width()))
	return result

func quantize(image:Image,cloth:bool=false)->void:
	for y:int in image.get_height():
		for x:int in image.get_width():
			var c:Color=image.get_pixel(x,y)
			if c.a<.5:continue
			if cloth and maxf(c.r,maxf(c.g,c.b))<.5 and c.r<c.g*1.2:
				image.set_pixel(x,y,palette[0] if maxf(c.r,maxf(c.g,c.b))<.18 else palette[20]);continue
			var key:int=c.to_rgba32()
			if not color_cache.has(key):
				var nearest:Color=palette[0];var distance:=INF
				var ramp:Array[Color]=palette
				var high:float=maxf(c.r,maxf(c.g,c.b))
				var low:float=minf(c.r,minf(c.g,c.b))
				if high<.5 and high-low<.075:ramp=palette.slice(0,3)
				for entry:Color in ramp:
					var d:float=pow(c.r-entry.r,2)+pow(c.g-entry.g,2)+pow(c.b-entry.b,2)
					if d<distance:distance=d;nearest=entry
				color_cache[key]=nearest
			image.set_pixel(x,y,color_cache[key])

func cells(image:Image,grid:Vector2i)->Array[Image]:
	var out:Array[Image]=[]
	for row:int in grid.y:
		for column:int in grid.x:
			var begin:=Vector2i(roundi(float(column)*image.get_width()/grid.x),roundi(float(row)*image.get_height()/grid.y))
			var end:=Vector2i(roundi(float(column+1)*image.get_width()/grid.x),roundi(float(row+1)*image.get_height()/grid.y))
			out.append(clean_cell(image.get_region(Rect2i(begin,end-begin))))
	return out

func actor(id:String,base:String,output:String)->void:
	var source:Image=Image.load_from_file(base.path_join("originals/walk_"+id+".png"))
	var frames:Array[Image]=cells(source,Vector2i(5,4))
	var heights:Array[int]=[]
	for frame:Image in frames:heights.append(frame.get_used_rect().size.y)
	heights.sort();var factor:float=134.0/heights[heights.size()/2]
	var hashes:Dictionary={};var rows:Array=[]
	var sheet:=Image.create_empty(96*5,128*4,false,Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(base.path_join("masters"))
	for index:int in frames.size():
		var frame:Image=frames[index];var bounds:Rect2i=frame.get_used_rect()
		if bounds.size.y<80 or bounds.size.x<10:push_error("Invalid generated actor cell");failed=true;return
		var head:Rect2i=frame.get_region(Rect2i(bounds.position,Vector2i(bounds.size.x,roundi(bounds.size.y*.32)))).get_used_rect()
		var center:float=bounds.position.x+head.get_center().x
		var crop:Image=frame.get_region(bounds)
		crop.resize(roundi(bounds.size.x*factor),roundi(bounds.size.y*factor),Image.INTERPOLATE_NEAREST)
		var at:=Vector2i(roundi(60-(center-bounds.position.x)*factor),160-crop.get_height())
		if at.x<0 or at.x+crop.get_width()>120 or at.y<0:push_error("Clipped actor frame "+id+str(index));failed=true;return
		var master:=Image.create_empty(120,160,false,Image.FORMAT_RGBA8)
		master.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),at);quantize(master)
		master.save_png(base.path_join("masters/player_%s_%02d.png"%[id,index]))
		var runtime:Image=master.duplicate();runtime.resize(96,128,Image.INTERPOLATE_NEAREST)
		var name:="player_%s_%02d.png"%[id,index] if index<16 else "player_%s_idle_%02d.png"%[id,index-16]
		runtime.save_png(output.path_join(name))
		if index==16:runtime.save_png(output.path_join("player_"+id+"_idle.png"))
		if index<16:hashes[runtime.get_data().hex_encode().sha256_text()]=true
		sheet.blit_rect(runtime,Rect2i(Vector2i.ZERO,runtime.get_size()),Vector2i(index%5*96,index/5*128))
		rows.append({"frame":index,"source":var_to_str(bounds),"headCenterX":center,"baseline":160,"masterInk":var_to_str(master.get_used_rect())})
	sheet.save_png(base.path_join("preview_"+id+".png"))
	report.actors[id]={"sourceSize":var_to_str(source.get_size()),"masterSize":[120,160],"runtimeSize":[96,128],"sharedScale":factor,"uniqueWalkFrames":hashes.size(),"frames":rows}

func book(base:String,output:String)->void:
	var source:Image=Image.load_from_file(base.path_join("originals/library_book.png"))
	var frames:Array[Image]=cells(source,Vector2i(4,4))
	var heights:Array[int]=[]
	for frame:Image in frames:heights.append(frame.get_used_rect().size.y)
	heights.sort();var factor:float=110.0/heights[heights.size()/2]
	var sheet:=Image.create_empty(192*4,160*4,false,Image.FORMAT_RGBA8)
	var pivots:Array[float]=[.5,.10,.10,.08,.07,.07,.07,.07,.07,.07,.16,.29,.40,.46,.5,.5]
	var rows:Array=[]
	for index:int in frames.size():
		var bounds:Rect2i=frames[index].get_used_rect();var crop:Image=frames[index].get_region(bounds)
		crop.resize(roundi(bounds.size.x*factor),roundi(bounds.size.y*factor),Image.INTERPOLATE_NEAREST)
		var at:=Vector2i(roundi(80-crop.get_width()*pivots[index]),154-crop.get_height())
		var image:=Image.create_empty(192,160,false,Image.FORMAT_RGBA8)
		if at.x<0 or at.x+crop.get_width()>192:push_error("Clipped book frame "+str(index));failed=true;return
		image.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),at);quantize(image,true)
		sheet.blit_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),Vector2i(index%4*192,index/4*160))
		rows.append({"frame":index,"source":var_to_str(bounds),"pivotFraction":pivots[index],"ink":var_to_str(image.get_used_rect())})
	sheet.save_png(output.path_join("library_book_sheet.png"));sheet.save_png(base.path_join("preview_book.png"))
	report.book={"frames":16,"cell":[192,160],"pivot":[80,154],"height":110,"sharedScale":factor,"rows":rows}

func seated_actor(base: String, output: String) -> void:
	var path := base.path_join("originals/player_seated.png")
	var generated := Image.load_from_file(path)
	if generated == null or generated.is_empty():
		failed = true
		return
	var cleaned := clean_cell(generated)
	var bounds := cleaned.get_used_rect()
	if not bounds.has_area():
		failed = true
		return
	var cropped := cleaned.get_region(bounds)
	var width := roundi(cropped.get_width() * 88.0 / cropped.get_height())
	if width > 90:
		failed = true
		return
	cropped.resize(width, 88, Image.INTERPOLATE_NEAREST)
	quantize(cropped)
	var frame := Image.create_empty(96, 128, false, Image.FORMAT_RGBA8)
	frame.blit_rect(cropped, Rect2i(0, 0, width, 88), Vector2i((96 - width) / 2, 24))
	failed = frame.save_png(output.path_join("player_seated.png")) != OK
	report["seated"] = {"size":[96,128], "bounds":var_to_str(frame.get_used_rect())}

func run()->void:
	var project:String=OS.get_cmdline_user_args()[0]
	var base:=project.path_join("art_source/library_animation_20261105")
	var output:=project.path_join("assets/native/library_animation_20261105")
	DirAccess.make_dir_recursive_absolute(output)
	var art:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(project.path_join("docs/art/art_direction_v1.json")))
	for hex:String in art.palette.colors:palette.append(Color(hex))
	if "--seated-only" in OS.get_cmdline_user_args():
		seated_actor(base, output)
		quit(2 if failed else 0)
		return
	for id:String in ["side","down","up"]:
		actor(id,base,output)
		if failed:quit(2);return
	book(base,output)
	if not failed: seated_actor(base, output)
	if failed:quit(2);return
	FileAccess.open(base.path_join("normalization.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LIBRARY_ANIMATION_IMPORT ",JSON.stringify(report.actors.keys())," book=",report.book.get("frames",0))
	quit()
