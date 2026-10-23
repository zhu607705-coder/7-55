extends SceneTree
## Lossless derived assets, exact world/crop coordinates and the actual drawing adapter.
const Tiled=preload("res://scripts/presentation/source_tiled_texture.gd")
const TiledView=preload("res://scripts/presentation/source_tiled_view.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;print("FAIL: ",label)
func digest(bytes:PackedByteArray)->String:
	var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(bytes);return h.finish().hex_encode()
func rect_from(raw:Array)->Rect2:return Rect2(float(raw[0]),float(raw[1]),float(raw[2]),float(raw[3]))
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated native profile")
	if failures:quit(1);return
	var plate:=Tiled.new()
	check(plate.configure(Tiled.SOURCE) and plate.get_size()==Vector2(13668,1084),"unchanged original world source dimensions")
	check(Tiled.supports("src/assets/rpg/campus/zijingang_campus_loop_panorama.png") and not Tiled.supports("res://assets/rpg/campus/zijingang_campus_plate.png"),"only the original loop projection opts into tiling")
	var original:=Image.load_from_file(ProjectSettings.globalize_path("res://../"+str(plate.manifest.sourceFile)))
	check(original!=null and original.get_size()==Vector2i(13668,1084),"read original PNG directly as pixel oracle without a giant GPU texture")
	if original==null:quit(1);return
	check(digest(FileAccess.get_file_as_bytes("res://../"+str(plate.manifest.sourceFile)))==str(plate.manifest.sourceSha256),"manifest pins original PNG SHA")
	check(digest(original.get_data())==str(plate.manifest.decodedSourceSha256),"independent Godot PNG decoder agrees with generator source pixel SHA")
	var rebuilt:=Image.create(original.get_width(),original.get_height(),false,original.get_format())
	var source_x:=0
	for tile:Dictionary in plate.manifest.tiles:
		var image:=Image.load_from_file(ProjectSettings.globalize_path(str(tile.path)))
		var source:=rect_from(tile.sourceRect);var region:=rect_from(tile.textureRegion)
		check(image!=null and maxi(image.get_width(),image.get_height())<=2048,"physical tile stays inside minimum 2048 texture bound")
		check(source.position==Vector2(source_x,0) and source.size.y==1084 and region.position==Vector2.ONE,"contiguous source core and one-pixel gutter")
		check(digest(FileAccess.get_file_as_bytes(str(tile.path)))==str(tile.sha256) and digest(image.get_data())==str(tile.decodedPixelSha256),"generated PNG bytes and independent decoded pixels match manifest")
		rebuilt.blit_rect(image,Rect2i(region),Vector2i(source.position))
		# Every gutter texel, including corners, must come from its exact neighbor/clamped outer pixel.
		var gutter_ok:=true
		for x in image.get_width():
			var sx:=clampi(source_x+x-1,0,original.get_width()-1)
			gutter_ok=gutter_ok and image.get_pixel(x,0)==original.get_pixel(sx,0) and image.get_pixel(x,image.get_height()-1)==original.get_pixel(sx,1083)
		for y in image.get_height():
			var sy:=clampi(y-1,0,1083)
			gutter_ok=gutter_ok and image.get_pixel(0,y)==original.get_pixel(maxi(0,source_x-1),sy) and image.get_pixel(image.get_width()-1,y)==original.get_pixel(mini(13667,source_x+int(source.size.x)),sy)
		check(gutter_ok,"all four gutter edges preserve neighboring source texels")
		source_x+=int(source.size.x)
	check(source_x==13668 and rebuilt.get_data()==original.get_data(),"all seven generated cores reconstruct every original source pixel exactly")
	var parts:=plate.pieces(Rect2(10,20,200,600),Rect2(2000,100,100,300))
	check(parts.size()==2 and parts[0].worldSource==Rect2(2000,100,46,300) and parts[1].worldSource==Rect2(2046,100,54,300),"cross-2046 crop splits exactly 46/54 source pixels")
	check(parts[0].destination==Rect2(10,20,92,600) and parts[1].destination==Rect2(102,20,108,600),"crop destinations share an exact edge without changing source coordinates")
	parts=plate.pieces(Rect2(0,0,100,100),Rect2(12250,200,100,100))
	check(parts.size()==2 and parts[0].worldSource.size.x==26 and parts[1].worldSource.position.x==12276 and parts[1].worldSource.size.x==74,"tail boundary uses actual final partial tile")
	parts=plate.pieces(Rect2(40,60,100,100),Rect2(-10,-10,100,100))
	check(parts.size()==1 and parts[0].worldSource==Rect2(0,0,90,90) and parts[0].destination==Rect2(50,70,90,90),"negative source clips overlap without stretching the destination")
	parts=plate.pieces(Rect2(0,0,100,50),Rect2(13640,1050,100,50))
	check(parts.size()==1 and parts[0].worldSource==Rect2(13640,1050,28,34) and parts[0].destination==Rect2(0,0,28,34),"source right/bottom clips to original dimensions")
	check(plate.pieces(Rect2(),Rect2(0,0,100,100)).is_empty() and plate.pieces(Rect2(0,0,100,100),Rect2()).is_empty() and plate.pieces(Rect2(0,0,100,100),Rect2(14000,0,10,10)).is_empty(),"empty or fully outside requests draw no pieces")
	# Failed resource availability is runtime-only; restoring the exact manifest retries normally.
	var retry:=Tiled.new();retry.configure(Tiled.SOURCE)
	var real_manifest:Dictionary=retry.manifest.duplicate(true)
	retry.manifest.tiles[0].path="res://assets/nonexistent-later-content-tile.png"
	check(not retry.ensure_loaded() and not retry.ready and retry.textures.is_empty(),"temporarily missing tile never commits a partial ready set")
	retry.manifest=real_manifest
	check(retry.ensure_loaded() and retry.ready and retry.textures.size()==7 and retry.snapshot().maxTextureDimension<=2048,"same adapter retries after later resource availability")
	var detached:Dictionary=retry.snapshot();detached.sourceSize.x=-1
	check(retry.snapshot().sourceSize.x==13668,"diagnostic snapshot is detached and readonly")
	var view:=TiledView.new();view.size=Vector2(378,180);view.configure(Tiled.SOURCE,true);root.add_child(view)
	await process_frame
	check(view.flip_h and view.mouse_filter==Control.MOUSE_FILTER_IGNORE and view.plate.get_size()==Vector2(13668,1084),"narrative view preserves mirroring/source extent and owns no input")
	view.size=Vector2(720,240);await process_frame
	check(view.size==Vector2(720,240) and view.plate.ready,"narrative resize keeps the same ready small textures")
	view.free()
	check(not plate.configure("") and not plate.ready and plate.textures.is_empty() and plate.get_size()==Vector2.ZERO,"leaving the loop releases its texture ownership")
	print("SOURCE_TILED_TEXTURE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
