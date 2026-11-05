extends "res://tools/normalize_library_animation.gd"
## Same alpha/palette process as the walk family; originals remain untouched.
func family(id:String,base:String,output:String,cell:Vector2i,target:float,anchor:Vector2i)->void:
	var source:=Image.load_from_file(base.path_join("originals/"+id+".png"))
	var frames:Array[Image]=cells(source,Vector2i(4,4))
	var measures:Array[int]=[]
	for frame:Image in frames:measures.append(frame.get_used_rect().size.x if id=="paper" else frame.get_used_rect().size.y)
	measures.sort()
	var factor:float=target/measures[8]
	var sheet:=Image.create_empty(cell.x*4,cell.y*4,false,Image.FORMAT_RGBA8)
	var rows:Array=[];var hashes:Dictionary={}
	for index:int in frames.size():
		var frame:Image=frames[index];var bounds:=frame.get_used_rect()
		var reference:=bounds
		if id!="paper":reference=frame.get_region(Rect2i(bounds.position,Vector2i(bounds.size.x,roundi(bounds.size.y*.25)))).get_used_rect()
		var center:float=bounds.get_center().x if id=="paper" else bounds.position.x+reference.get_center().x
		var crop:=frame.get_region(bounds)
		crop.resize(maxi(1,roundi(bounds.size.x*factor)),maxi(1,roundi(bounds.size.y*factor)),Image.INTERPOLATE_NEAREST)
		var at:=Vector2i(roundi(anchor.x-(center-bounds.position.x)*factor),anchor.y-crop.get_height())
		if id=="paper":at.y=anchor.y-crop.get_height()/2
		if at.x<2 or at.y<2 or at.x+crop.get_width()>cell.x-2 or at.y+crop.get_height()>cell.y:
			push_error("Clipped interaction frame "+id+str(index));failed=true;return
		quantize(crop)
		var normalized:=Image.create_empty(cell.x,cell.y,false,Image.FORMAT_RGBA8)
		normalized.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),at)
		normalized.save_png(output.path_join("%s_%02d.png"%[id,index]))
		sheet.blit_rect(normalized,Rect2i(Vector2i.ZERO,cell),Vector2i(index%4,index/4)*cell)
		hashes[normalized.get_data().hex_encode().sha256_text()]=true
		rows.append({"frame":index,"sourceBounds":var_to_str(bounds),"ink":var_to_str(normalized.get_used_rect())})
	if hashes.size()<12:push_error("Insufficient distinct frames "+id);failed=true;return
	sheet.save_png(output.path_join(id+"_sheet.png"));sheet.save_png(base.path_join("preview_"+id+".png"))
	report[id]={"cell":[cell.x,cell.y],"anchor":[anchor.x,anchor.y],"sharedScale":factor,"uniqueFrames":hashes.size(),"frames":rows}

func run()->void:
	var project:String=OS.get_cmdline_user_args()[0]
	var base:=project.path_join("art_source/library_interactions_20261105")
	var output:=project.path_join("assets/native/library_interactions_20261105")
	DirAccess.make_dir_recursive_absolute(output)
	var art:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(project.path_join("docs/art/art_direction_v1.json")))
	for hex:String in art.palette.colors:palette.append(Color(hex))
	report={"schema":"library-interaction-import-v1"}
	family("backpack",base,output,Vector2i(256,256),220,Vector2i(128,248))
	family("staff",base,output,Vector2i(96,128),116,Vector2i(48,128))
	family("paper",base,output,Vector2i(192,144),150,Vector2i(96,72))
	if failed:quit(2);return
	FileAccess.open(base.path_join("normalization.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LIBRARY_INTERACTION_IMPORT ",JSON.stringify(report.keys()));quit()
