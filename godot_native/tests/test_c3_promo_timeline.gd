extends SceneTree
const Timeline=preload("res://scripts/presentation/c3_promo_timeline.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1; push_error(label)
func run() -> void:
	for reduced in [false,true]:
		var b: Dictionary=Timeline.timing(reduced)
		check(b.completeAt==(1040 if reduced else 3999),"source complete timeline")
		check(b.insertAt==(200 if reduced else 772),"source cup blink repetitions")
		check(b.revealAt==(310 if reduced else 1299),"source insert movie delay")
		check(b.turnAt==(550 if reduced else 2238),"source queue gaze start")
		check(b.returnAt==(890 if reduced else 3343),"source three-row stagger completion")
		var snap: Dictionary=Timeline.snapshot(0,reduced)
		check(snap.emptyVisible and not snap.activeVisible and snap.queueOffsets==[0.0,0.0,0.0],"initial source props")
		snap=Timeline.snapshot(b.insertAt,reduced)
		check(snap.insertVisible and snap.insertFrame==0,"source insert begins frame0")
		snap=Timeline.snapshot(b.revealAt,reduced)
		check(snap.activeVisible and snap.bubblesVisible and not snap.emptyVisible and not snap.insertVisible,"board reveal owns props")
		check(Timeline.snapshot(b.revealAt+167,reduced).bubblesFrame==1,"bubble stays6fps under reduced motion")
		check(Timeline.snapshot(b.turnAt,reduced).turnVisible,"front student turns")
		snap=Timeline.snapshot(b.waveAt,reduced)
		check(not snap.turnVisible and snap.queueCollidable==[false,false,false],"wave temporarily releases authored collision bodies")
		snap=Timeline.snapshot(b.waveAt+b.move/2.0,reduced)
		check(is_equal_approx(snap.queueOffsets[0],18),"source half sine shift18px")
		check(snap.queueOffsets[1]<snap.queueOffsets[0],"queue rows move as a wave")
		snap=Timeline.snapshot(b.returnAt,reduced)
		check(snap.queueOffsets==[36.0,36.0,36.0] and snap.queueCollidable==[true,true,true],"final source shift and collision restoration")
		check(not Timeline.snapshot(b.completeAt-1,reduced).complete and Timeline.snapshot(b.completeAt,reduced).complete,"honest callback boundary")
		var initial:=Vector2(900,400); var player:=Vector2(1232,285)
		check(Timeline.camera(0,reduced,initial,1,player).point==initial,"camera starts without jump")
		check(Timeline.camera(b.focus,reduced,initial,1,player).point==Vector2(1232,158),"authored promo focus")
		check(Timeline.camera(b.turnAt,reduced,initial,1,player).point==Vector2(1011,210),"authored queue focus")
		check(Timeline.camera(b.completeAt,reduced,initial,1,player).point==player and Timeline.camera(b.completeAt,reduced,initial,1,player).zoom==1,"camera returns to authored follow scale")
		for ms in range(b.completeAt+1):
			snap=Timeline.snapshot(ms,reduced)
			check(snap.activeAlpha>=0 and snap.activeAlpha<=1 and snap.emptyAlpha>=.33 and snap.emptyAlpha<=1,"bounded source opacity")
			check(snap.queueOffsets.all(func(v):return v>=0 and v<=36),"bounded source displacement")
	print("C3 PROMO TIMELINE %d checks / %d failures" % [checks,failures])
	quit(1 if failures else 0)
