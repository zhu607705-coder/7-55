extends "res://samples/future_learning_center/play.gd"
func capture_review()->void:
	await process_frame;await process_frame
	world.user_control=false
	var report:Array[Dictionary]=[]
	for f:int in [2,3,4]:
		if not world.load_floor(f):push_error("Cannot load cabinet floor");continue
		world.set_hour(12)
		var current:Dictionary=world.data.duplicate(true)
		var before_path:=OS.get_environment("FLC_WALL_BEFORE").path_join("floor_%d.json"%f)
		var before:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(before_path))
		var old_space=world.FloorSpace.new();old_space.configure(before)
		for row:Dictionary in current.wallStorage.rooms:
			var units:Array=current.objects.filter(func(o:Dictionary)->bool:return o.room==row.room and o.has("wallStorage"))
			var center_x:=0.0
			for item:Dictionary in units:center_x+=world.Space.rect(item.footprint).get_center().x
			center_x/=float(units.size())
			var point:=Vector2(center_x,float(row.wallY)+125)
			var found:=false
			for offset:Vector2 in [Vector2.ZERO,Vector2(0,80),Vector2(80,0),Vector2(-80,0),Vector2(0,160),Vector2(160,80),Vector2(-160,80)]:
				var at:=point+offset
				if world.space.can_stand(at-world.Body.FOOT_CENTER_OFFSET) and old_space.can_stand(at-world.Body.FOOT_CENTER_OFFSET):
					point=at;found=true;break
			if not found:push_error("No shared review camera foot position: "+str(row.room));continue
			for mode:String in ["before","after"]:
				world.data=before if mode=="before" else current
				var next_space=world.FloorSpace.new();next_space.configure(world.data);world.space=next_space
				world.framing=world.RoomCamera.new();world.route.clear();world.overview=false
				if not world.set_foot(point):push_error("Invalid wall capture point");continue
				await capture("f%d_%s_%s"%[f,row.room,mode])
			report.append({"floor":f,"room":row.room,"before":row.before,"after":row.after,"point":[point.x,point.y],"cameraZoom":world.camera.zoom.x,"cameraPosition":[world.camera.position.x,world.camera.position.y]})
	var file:=FileAccess.open(OS.get_environment("FLC_CAPTURE_DIR").path_join("wall-captures.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"views":report,"window":[root.size.x,root.size.y],"engine":Engine.get_version_info(),"illegalFrames":world.invalid_frames},"  "));file.close()
