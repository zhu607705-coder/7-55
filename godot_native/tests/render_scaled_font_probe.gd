extends SceneTree
## GPU-only A/B probe: same custom font, DPI and nested phone transforms.
const DisplayPolicy=preload("res://scripts/platform/web_display.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
var font:Font
var display_font:Font
func _initialize()->void:run.call_deferred()
func mode(item:CanvasItem,enabled:bool)->void:
	var name:="OVERSAMPLING_WITH_SCALE_ENABLED" if enabled else "OVERSAMPLING_WITH_SCALE_DISABLED"
	if ClassDB.class_has_integer_constant("CanvasItem",name):item.set("oversampling_with_scale",ClassDB.class_get_integer_constant("CanvasItem",name))
func sample(parent:Control,position:Vector2,fit:float,enabled:bool)->Control:
	var outer:=Control.new();outer.position=position;outer.scale=Vector2.ONE*fit;parent.add_child(outer);mode(outer,enabled)
	var inner:=Control.new();inner.scale=Vector2.ONE*(424.0/378.0);outer.add_child(inner)
	var background:=ColorRect.new();background.size=Vector2(378,220);background.color=Color("fff6df");inner.add_child(background)
	for row:Array in [["按实际比例重新采样" if enabled else "当前：仅按视口采样",18,"body"],["签到成功 · 开始游戏 · 7:55",24,"display"],["入馆记录已记下，继续寻找纸条。",13,"body"],["0O 1Il 3B 5S 6G 8B / rn m w",18,"body"],["Morning Note / Campus / CC98",14,"body"],["签到 07:55 / ZJUWLAN / Wi-Fi",13,"body"]]:
		var label:=Label.new();label.position=Vector2(10,10+inner.get_child_count()*28);label.size=Vector2(358,28);label.text=row[0];label.add_theme_font_override("font",display_font if row[2]=="display" else font);label.add_theme_font_size_override("font_size",int(row[1]));label.add_theme_color_override("font_color",Color("222322"));label.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;inner.add_child(label)
		# Keep sampling inherited from the A/B scope. Calling apply_body here
		# would enable per-label oversampling and erase the intended comparison.
	return outer
func face_metrics(face:Font)->Dictionary:
	var base:FontFile=face.base_font if face is FontVariation else face
	return {"family":base.get_font_name(),"weight":base.get_font_weight(),"fontMSDF":base.multichannel_signed_distance_field,"fontOversampling":base.oversampling,"antialiasing":base.antialiasing,"hinting":base.hinting,"subpixelPositioning":base.subpixel_positioning}
func run()->void:
	if DisplayServer.get_name()=="headless":print("GPU_RENDERER_REQUIRED");quit(2);return
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS,true)
	font=Typography.body_font();display_font=Typography.display_font()
	var out:=OS.get_environment("FONT_PROBE_OUTPUT")
	var rows:Array=[]
	for spec:Array in [[1280,720,1],[1440,900,2],[390,844,3]]:
		var density:float=float(spec[2]);var css:=Vector2(float(spec[0]),float(spec[1]))
		# A native macOS Window is clamped to the attached display height. Use a
		# real offscreen GPU viewport to retain the requested HiDPI backing size.
		var viewport:=SubViewport.new();viewport.size=Vector2i(css*density);viewport.size_2d_override=Vector2i(css);viewport.size_2d_override_stretch=true;viewport.disable_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
		var host:=Control.new();viewport.add_child(host);host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var bg:=ColorRect.new();bg.size=css;bg.color=Color("0c1b24");host.add_child(bg)
		var fit:=minf((css.y-54)/860.0,(css.x-24)/430.0)
		var x:float=(css.x-424*fit)/2
		var a:=sample(host,Vector2(x,24),fit,false);var b:=sample(host,Vector2(x,52+246*fit),fit,true)
		await process_frame;await RenderingServer.frame_post_draw
		var name:="font-ab-"+str(spec[0])+"-dpr"+str(spec[2])+".png"
		var image:=viewport.get_texture().get_image();image.save_png(out.path_join(name))
		rows.append({"file":name,"css":css,"density":density,"visibleRect":viewport.get_visible_rect(),"physicalImage":image.get_size(),"viewportOversampling":viewport.get_oversampling(),"phoneFitScale":fit,"innerScale":424.0/378.0,"fonts":{"body":face_metrics(font),"display":face_metrics(display_font)},"aMode":a.get("oversampling_with_scale"),"bMode":b.get("oversampling_with_scale")})
		viewport.free()
	var report:=FileAccess.open(out.path_join("report.json"),FileAccess.WRITE);report.store_string(JSON.stringify(rows,"\t"));report.close()
	print("FONT_SCALE_GPU_PROBE: ",JSON.stringify(rows));quit()
