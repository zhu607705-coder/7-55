extends SceneTree
const View=preload("res://scripts/objects/room302_studio_view.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func run()->void:
	for extent:Vector2 in [Vector2(390,844),Vector2(844,390),Vector2(1440,900)]:
		var view:=View.new();view.size=extent;root.add_child(view)
		await process_frame
		var area:=Rect2(16,126,extent.x-32,extent.y-186)
		var previous_fit:float=-1
		for touch:bool in [false,true]:
			view.touch_mode=touch;view.layout_scene(area)
			check((view.design_size.x==360)==(area.size.y>area.size.x),"layout follows available aspect, not input")
			check(view.touch_mode==touch,"layout never changes input authority")
			if previous_fit>=0:check(is_equal_approx(previous_fit,view.fit),"switching hardware leaves composition stable")
			previous_fit=view.fit
			check(area.encloses(Rect2(view.origin,view.design_size*view.fit)),"whole authored stage remains inside safe area")
			var caption:=view.scanner_caption_rect()
			check(area.encloses(caption),"scanner caption never crosses screen edge")
			check(caption.size.x>=Typography.body_font().get_string_size(View.SCANNER_CAPTION,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x,"full scanner caption fits")
			if extent.x==390:check(view.fit>.8,"portrait uses existing portrait art composition, not shrunk 880px stage")
		view.free()
	print("Room302 responsive: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
