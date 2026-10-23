extends SceneTree
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;print("FAIL: ",label)
func run()->void:
	check(not Ui.enable_scale_aware_text(null),"missing UI scope is a no-op")
	var outer:=Control.new();root.add_child(outer)
	var inner:=Control.new();inner.scale=Vector2.ONE*(424.0/378.0);outer.add_child(inner)
	var font:Font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	var label:=Label.new();label.text="入馆记录已记下，继续寻找纸条。";label.position=Vector2(17,23);label.add_theme_font_override("font",font);label.add_theme_font_size_override("font_size",13);inner.add_child(label)
	var button:=Button.new();button.text="签到成功";button.position=Vector2(30,90);button.size=Vector2(180,44);inner.add_child(button)
	var state_before:=JSON.stringify(root.get_node("State").d)
	var density_before:float=root.content_scale_factor
	var font_before:bool=font.get("multichannel_signed_distance_field")
	var supported:=ClassDB.class_has_integer_constant(&"CanvasItem",&"OVERSAMPLING_WITH_SCALE_ENABLED")
	for scale_value in [.774418604651163,.983720930232558,.851162790697674]:
		outer.scale=Vector2.ONE*scale_value
		if supported:outer.set(&"oversampling_with_scale",ClassDB.class_get_integer_constant(&"CanvasItem",&"OVERSAMPLING_WITH_SCALE_DISABLED"))
		await process_frame
		var transform:=label.get_global_transform_with_canvas();var rect:=button.get_global_rect();var minimum:=label.get_combined_minimum_size()
		check(Ui.enable_scale_aware_text(outer)==supported,"only a supported native capability changes the font sampling scope")
		await process_frame
		check(label.get_global_transform_with_canvas()==transform and button.get_global_rect()==rect,"font sampling leaves rendered anchors and hit geometry unchanged")
		check(label.get_combined_minimum_size().is_equal_approx(minimum),"source logical text measurements stay unchanged")
		check(not Ui.enable_scale_aware_text(outer),"already enabled scope is idempotent without another write")
	check(root.content_scale_factor==density_before,"font helper never changes canvas DPI policy")
	check(font.get("multichannel_signed_distance_field")==font_before and label.get_theme_font("font")==font,"font family and original rendering resource remain unchanged")
	check(JSON.stringify(root.get_node("State").d)==state_before,"font presentation cannot mutate story/save facts")
	outer.free()
	print("SCALE_AWARE_TEXT: ",checks," checks; ",failures," failures; native_capability=",supported)
	quit(1 if failures else 0)
