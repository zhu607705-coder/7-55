extends SceneTree
const Typography=preload("res://scripts/ui/native_typography.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func run()->void:
	# Actual runtime resource identity, not a source-path or fallback-font claim.
	for row:Array in [
		["games/c3_weather.gd","FONT"],
		["games/identity_stamp.gd","font"],
		["presentation/c3_bike_world_view.gd","font"],
		["presentation/c3_reversal_view.gd","font"],
		["presentation/chapter4_lamp_closure.gd","SummaryFont"],
		["media/c3_charging_view.gd","PIXEL_FONT"]]:
		var view=load("res://scripts/"+row[0]).new()
		check(view.get(row[1])==Typography.body_font(),"runtime family matches common UI: "+row[0])
		if view is Node:view.free()
	# A physical Label3D is authored scenery; only the surrounding UI changes.
	var stair:String=FileAccess.get_file_as_string("res://scripts/presentation/chapter4_endless_stair_view.gd")
	check(stair.contains('if font: label.font = font'),"authored 3D wall lettering retains its geometry face")
	for control:String in ["instruction","start_button","back","subtitle","corner_label"]:
		check(stair.contains(control+'.add_theme_font_override("font",preload("res://scripts/ui/native_typography.gd").body_font())'),"stair UI uses common family: "+control)
	print("Runtime type family: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
