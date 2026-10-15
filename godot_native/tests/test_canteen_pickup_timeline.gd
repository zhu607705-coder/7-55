extends SceneTree
const Timeline=preload("res://scripts/presentation/c3_pickup_timeline.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:
	for reduced:bool in [false,true]:
		for beat:Array in [[0,"ticket"],[850,"quiet"],[1500,"camera_push"],[2630,"auntie_push"],[4030,"package_wait"],[4930,"package_shake"],[5980,"burst"],[6500,"camera_impact"],[6980,"paper_flight"],[8040,"pull_back"],[8930,"cart_reveal"],[9580,"dialogue"],[11380,"defense"]]:
			check(Timeline.sample(beat[0],reduced).stage==beat[1],"authored stage "+str(beat))
		check(Timeline.sample(0,reduced).ticket_position==Vector2(790,210),"ticket starts at player hand")
		check(Timeline.sample(650,reduced).ticket_position==Vector2(790,240),"650ms ticket enters third window")
		check(Timeline.sample(849,reduced).ticket_visible and not Timeline.sample(850,reduced).ticket_visible,"ticket removal at850ms")
		for frame in range(5):
			check(Timeline.sample(2630+frame*1000/3.6+.01,reduced).auntie_frame==frame,"original auntie3.6fps frame"+str(frame))
		for i in range(6):
			check(Timeline.sample(4930+i*1000/5.7+.01,reduced).package_frame==[0,1,0,2,3,4][i],"original package5.7fps repeated frame"+str(i))
		for i in range(8):
			check(Timeline.sample(5980+i*1000/15.4+.01,reduced).burst_frame==i,"original4x2 burst15.4fps frame"+str(i))
		check(Timeline.sample(4030,reduced).package_visible and Timeline.sample(4030,reduced).auntie_alpha==1,"package hold overlaps260ms auntie fade")
		check(not Timeline.sample(4290,reduced).auntie_visible,"auntie retires at4290ms")
		check(Timeline.sample(6500,reduced).closeup_visible and not Timeline.sample(6980,reduced).closeup_visible,"480ms camera slap")
		check(Timeline.sample(6980,reduced).paper_position==Vector2(790,242),"paper starts at source window")
		check(Timeline.sample(7680,reduced).paper_position==Vector2(836,470),"700ms flight lands center")
		check(Timeline.sample(7770,reduced).paper_position==Vector2(836,458),"first source bounce apex")
		check(Timeline.sample(7860,reduced).paper_position==Vector2(836,470),"first source bounce landing")
		check(Timeline.sample(7815,reduced).paper_position==Vector2(836,461),"Phaser yoyo reverses Quad.easeOut into return ease-in")
		check(Timeline.sample(6980,reduced).camera==Vector2(790,242),"source startFollow immediately centers on paper")
		check(Timeline.sample(7950,reduced).paper_position==Vector2(836,458),"second source bounce apex")
		check(Timeline.sample(8039,reduced).crowd_visible and not Timeline.sample(8040,reduced).crowd_visible,"crowd retained until source pullback")
		check(Timeline.sample(8890,reduced).camera.is_equal_approx(Vector2(836,470.5)) and is_equal_approx(Timeline.sample(8890,reduced).zoom,Timeline.FULL_ZOOM),"850ms source camera pullback")
		check(Timeline.sample(8439,reduced).cart_alpha==0 and Timeline.sample(8538,reduced).cart_alpha==1,"90ms early cart preview")
		check(Timeline.sample(9330,reduced).cart_alpha==1,"cart settles after source two flash cycles")
		check(Timeline.sample(9580,reduced).subtitle=="玩家：那是鸡吗？" and Timeline.sample(10360,reduced).subtitle=="","first subtitle exact780ms")
		check(Timeline.sample(10480,reduced).subtitle=="系统：现在不是了。" and Timeline.sample(11260,reduced).subtitle=="","second subtitle exact780ms")
		check(not Timeline.sample(11379,reduced).done and Timeline.sample(11380,reduced).done,"normal and reduced preserve11380ms story duration")
		for t:float in [5990,6510]:check(Timeline.sample(t,reduced).shake==Vector2.ZERO if reduced else Timeline.sample(t,reduced).shake.length()>0,"reduced only suppresses camera shake "+str(t))
	print("CANTEEN_PICKUP_TIMELINE ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
