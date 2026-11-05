extends SceneTree
const Grade=preload("res://scripts/ui/phone_display_grade.gd")
const Policy=preload("res://scripts/ui/phone_brightness_policy.gd")
var checks:=0
var failures:=0
func check(ok: bool, reason: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("DISPLAY_GRADE: "+reason)
func _initialize() -> void:
	var previous:=-1.0
	for step in range(10001):
		var value:=float(step)/10000.0
		var result:=Grade.calibrated_color(Color(value,value,value,0.6))
		check(result.r>=value-0.000001 and result.r<=1.0,"bounded nonnegative lift")
		check(result.r>previous,"strictly monotonic transfer curve")
		check(is_equal_approx(result.a,0.6),"alpha is unchanged")
		previous=result.r
	for r in range(0,256,7):
		for g in range(0,256,7):
			for b in range(0,256,7):
				var source:=Color(float(r)/255,float(g)/255,float(b)/255)
				var result:=Grade.calibrated_color(source)
				check(minf(result.r,minf(result.g,result.b))>=-0.000001 and maxf(result.r,maxf(result.g,result.b))<=1.000001,"RGB cube remains in gamut")
				check(absf((source.r-source.g)*(result.r-result.b)-(source.r-source.b)*(result.r-result.g))<0.000001,"channel differences retain hue")
				var high:=maxf(source.r,maxf(source.g,source.b));var low:=minf(source.r,minf(source.g,source.b))
				var new_high:=maxf(result.r,maxf(result.g,result.b));var new_low:=minf(result.r,minf(result.g,result.b))
				var saturation:=(high-low)/maxf(1-absf(high+low-1),.000001)
				var new_saturation:=(new_high-new_low)/maxf(1-absf(new_high+new_low-1),.000001)
				check(absf(saturation-new_saturation)<.0001,"HSL saturation remains authored")
	check(Grade.calibrated_color(Color.BLACK)==Color.BLACK,"black stays black")
	check(Grade.calibrated_color(Color.WHITE)==Color.WHITE,"white stays white")
	for ink: Color in [Color("222322"),Color("101116"),Color("1b2430")]:
		var result:=Grade.calibrated_color(ink)
		check(maxf(absf(result.r-ink.r),maxf(absf(result.g-ink.g),absf(result.b-ink.b)))*255<3,"near-black text remains dark")
	check(Grade.calibrated_color(Color(.5,.5,.5)).r>.64,"midtones visibly brighten at full output")
	var cream:=Color("fff0cc");var lit_cream:=Grade.calibrated_color(cream)
	check(lit_cream.g>cream.g+.01 and lit_cream.b>cream.b+.03,"warm paper lifts even when red is already maximum")
	for source: Color in [cream,Color("222322"),Color("c85454"),Color("61b58c"),Color("6aa8df"),Color("f2f2f7"),Color(.5,.5,.5)]:
		var last:=Color.BLACK
		for step in range(1001):
			var value:=float(step)/1000
			var graded:=Grade.calibrated_color(Color(source.r*value,source.g*value,source.b*value))
			check(graded.r>=last.r-.000001 and graded.g>=last.g-.000001 and graded.b>=last.b-.000001,"manual dimmer remains monotonic for every RGB channel")
			last=graded
	for r in range(0,256,17):
		for g in range(0,256,17):
			for b in range(0,256,17):
				var source:=Color(float(r)/255,float(g)/255,float(b)/255,.73)
				check(Grade.calibrated_color(source,Policy.grade_strength(65))==source,"neutral65 is exact original RGBA, not a dim-then-lift approximation")
				var last:=Color.BLACK
				for value in range(101):
					var factor:=1-Policy.veil_alpha(value)
					var composed:=Grade.calibrated_color(Color(source.r*factor,source.g*factor,source.b*factor,source.a),Policy.grade_strength(value))
					check(composed.r>=last.r-.000001 and composed.g>=last.g-.000001 and composed.b>=last.b-.000001,"full0–100 composite is channel-monotonic")
					check(minf(composed.r,minf(composed.g,composed.b))>=-.000001 and maxf(composed.r,maxf(composed.g,composed.b))<=1.000001,"entire manual range remains in gamut")
					check(is_equal_approx(composed.a,source.a),"entire range preserves alpha")
					last=composed
	print("PHONE_DISPLAY_GRADE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
