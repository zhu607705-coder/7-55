extends SceneTree
const Motion=preload("res://scripts/presentation/kayak_stroke_timeline.gd")
func _initialize()->void:
	var failures: int=0
	var checks: int=0
	for fps:int in [30,60,120]:
		for cadence:float in [.18,.2,.25,.3,.36,.5,.6,.72,.9]:
			var m=Motion.new();var next:int=0;var last:int=0;var repeats:int=0;var prev:String="";var extensions:int=0
			for frame:int in range(int((cadence*20+2)*fps)):
				var time:float=float(frame)/fps
				while next<20 and time+.000001>=next*cadence:
					var old_duration:float=m.duration;var old_started:int=m.started_strokes;var active:bool=m.active
					m.request_stroke("left" if next%2==0 else "right")
					if active and m.started_strokes==old_started and m.duration>old_duration+.00001:extensions+=1
					next+=1
				m.advance(1.0/fps)
				if m.started_strokes!=last:
					if prev==m.side:repeats+=1
					prev=m.side;last=m.started_strokes
			checks+=3
			if m.started_strokes!=20:failures+=1
			if repeats!=0:failures+=1
			if extensions!=0:failures+=1
			print("GRID ",JSON.stringify({"fps":fps,"cadence":cadence,"intents":m.accepted_intents,"started":m.started_strokes,"same_side_repeats":repeats,"extended_old_stroke":extensions}))
	print("CADENCE_MATRIX ",JSON.stringify({"checks":checks,"failures":failures,"cases":27}))
	quit(0 if failures==0 else 1)
