extends SceneTree
## Actual GPU base-material check, before lighting and wall group opacity.
func _initialize()->void:run.call_deferred()
func run()->void:
	if DisplayServer.get_name()=="headless" or not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	var output:=OS.get_environment("NORTH_PROP_CAPTURE_DIR")
	if output.is_empty():quit(2);return
	var state:Node=root.get_node("State");state.developer_mode=true;state.begin_checkpoint("c4-755-classrooms-1850")
	var world:Control=load("res://scripts/world.gd").new();root.add_child(world);world.set_process(false)
	await process_frame;await process_frame
	var family:RefCounted=world.north_objects
	if not family.active:quit(2);return
	var palette:Array=[]
	for hex:String in family.data.palette.colors:palette.append(Color(hex).to_html(false))
	var reports:Array=[];var passed:=true
	for asset:Dictionary in family.asset_registrations():
		var original:Sprite2D
		for registration:Dictionary in world.north_props.registrations:
			if registration.get("assetId",registration.id)==asset.id:
				original=world.north_props.objects[registration.id].get_node("Appearance");break
		var viewport:=SubViewport.new();viewport.size=Vector2i(160,160);viewport.transparent_bg=true;viewport.disable_3d=true
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
		var sprite:=original.duplicate() as Sprite2D;sprite.position=Vector2(5,5);sprite.modulate=Color.WHITE
		sprite.scale=Vector2.ONE*minf(150.0/sprite.region_rect.size.x,150.0/sprite.region_rect.size.y);viewport.add_child(sprite)
		for i in 4:await process_frame
		await RenderingServer.frame_post_draw
		var pixels:Image=viewport.get_texture().get_image();var colors:Dictionary={};var soft_alpha:=0;var off_palette:=0;var opaque:=0
		for y in pixels.get_height():
			for x in pixels.get_width():
				var c:Color=pixels.get_pixel(x,y)
				if c.a>0 and c.a<1:soft_alpha+=1
				if c.a==1:
					opaque+=1;colors[c.to_html(false)]=true
					if c.to_html(false) not in palette:off_palette+=1
		var ok:=soft_alpha==0 and off_palette==0 and opaque>100
		reports.append({"assetId":asset.id,"baseColors":colors.size(),"opaquePixels":opaque,"nonBinaryAlphaPixels":soft_alpha,"offPalettePixels":off_palette,"passed":ok})
		passed=passed and ok;viewport.queue_free();await process_frame
	var evidence:={"source":"actual GPU SubViewport, untinted object material; not metadata-only","passed":passed,"assets":reports}
	var file:=FileAccess.open(output.path_join("palette_alpha_gpu.json"),FileAccess.WRITE);file.store_string(JSON.stringify(evidence,"  "));file.close()
	print("NORTH_PALETTE_ALPHA_GPU: ",JSON.stringify(evidence));world.queue_free();await process_frame;quit(0 if passed else 1)
