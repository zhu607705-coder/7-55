extends SceneTree
const Model=preload("res://scripts/games/c3_spotlight_model.gd")
const Lens=preload("res://scripts/presentation/theater_lens.gd")
var checks:=0
var failures:=0
func check(value:bool,message:String)->void:
	checks+=1
	if not value:failures+=1;push_error(message)
func numbers(value:Array)->Array:return value.map(func(v):return int(v))
func _initialize()->void:
	var rules:=Model.new()
	var fixture:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/spotlight_balance_samples.json"))
	for route:Dictionary in fixture.cases:
		var proof:Dictionary=route.proof;var s:Dictionary=rules.create(int(proof.round),int(proof.attempt));var cursor:=0
		for input:Dictionary in proof.inputs:
			s=rules.step(s,input)
			if cursor<route.samples.size() and s.tick==route.samples[cursor].tick:
				var expected:Dictionary=route.samples[cursor];cursor+=1
				check(s.head.distance_to(Vector2(expected.head.x,expected.head.y))<.005,"source/native head parity tick "+str(s.tick))
				check(s.lives==expected.lives and s.focus==numbers(expected.focus) and s.collected==numbers(expected.collected) and s.status==expected.status and s.lastEvent==expected.event,"source/native exposure, damage, collection and result parity")
				check(s.primed==expected.primed and s.pairTicks==expected.pairTicks and s.pairFailures==expected.pairFailures,"source/native pair transaction parity")
				var echo:Dictionary=rules.echo(s)
				check(echo.is_empty() if expected.echo==null else (not echo.is_empty() and echo.position.distance_to(Vector2(expected.echo.x,expected.echo.y))<.005),"source/native 60-tick cooperation parity")
		check(s.status=="won" and rules.validate(proof,int(proof.round),int(proof.attempt))==s,"source trace wins and exactly replays natively")
		check(rules.validate(proof,int(proof.round),int(proof.attempt)+1).is_empty(),"stale attempts stay rejected")
	for act in 3:
		var s:Dictionary=rules.create(act)
		for tick in range(0,1601,5):
			s.tick=tick
			for id in int(Model.ACTS[act].count):
				var p:Vector2=rules.food(s,id);var shown:Vector2=Lens.display_point(p)
				check(Rect2(71,145,819,252).has_point(p),"all marks stay within playable bounds")
				check(Rect2(0,0,960,540).has_point(shown) and Lens.sample_point(shown).distance_to(p)<.1,"all moving/fixed marks remain visible and exactly mapped")
				if act==2:check(p==Model.FOOD[id],"cooperative anchors never move under the delayed actor")
	# A safe ray can be blocked from one side and lit from another at the same tick.
	var s:Dictionary=rules.create(1);var blocked:=Vector2(722.052298,315.647963);var clear:=Vector2(823.164363,369.693488)
	for origin:Vector2 in [blocked,clear]:
		check(origin.distance_to(rules.food(s,3))<rules.light_radius(s),"LOS witness is within actual illumination reach")
		for hazard:Dictionary in rules.hazards(s):check(origin.distance_to(hazard.position)>hazard.radius+10,"LOS witness is not standing in damage radius")
	check(rules.food_blocked(s,3,blocked) and not rules.food_blocked(s,3,clear),"changing safe vantage really changes optical occlusion")
	s.head=clear
	for i in 20:
		var future:Dictionary=s.duplicate(true);future.tick+=1
		var axis:Vector2=rules.pointer_axis(s,rules.food(future,3)+Vector2(65,0));s=rules.step(s,{"x":axis.x,"y":axis.y,"dash":false})
	check(s.primed==3 and s.collected.is_empty() and s.lives==3,"safe clear-side tracking primes a pair without granting it")
	check(rules.active_food(s)==[4] and s.pairTicks==110,"only the partner opens for the measured deadline")
	# Deadline is exclusive: remaining=1 expires before this next tick can commit.
	s.collected=[0,2];s.pairTicks=1;s.focus[4]=19
	var future:Dictionary=s.duplicate(true);future.tick+=1;s.head=rules.food(future,4)
	s=rules.step(s,{"x":0,"y":0,"dash":false})
	check(s.collected==[0,2] and s.primed==-1 and s.pairFailures==1,"expiration cancels only the current temporary group before completion")
	check(not rules.active_food(s).has(1),"central final mark stays locked until both outer pairs are permanent")
	# A same-tick hurt overrides a would-be second endpoint completion.
	s=rules.create(1);s.collected=[4,3];s.primed=0;s.pairTicks=40;s.focus[2]=19
	future=s.duplicate(true);future.tick+=1;s.head=rules.food(future,2);s.history=[]
	for i in 61:s.history.append(s.head)
	s=rules.step(s,{"x":0,"y":0,"dash":false})
	check(s.lastEvent=="hurt" and s.collected==[4,3] and s.primed==-1 and s.focus==[0,0,0,0,0,0],"hurt wins before new pair submission and preserves earlier group")
	check(s.history.size()==62,"hurt retains the history instead of erasing the cooperative timeline")
	# Third act: exact delay, harmless echo, simultaneous light and fixed anchors.
	s=rules.create(2)
	for i in 59:s=rules.step(s,{"x":0,"y":0,"dash":false})
	check(rules.echo(s).is_empty(),"no premature echo before 60 ticks")
	s=rules.step(s,{"x":0,"y":0,"dash":false})
	check(rules.echo(s).position==Vector2(156,280),"60th tick reveals the original position")
	for hazard:Dictionary in rules.hazards(s):check(hazard.kind!="shadow","third-act echo cannot damage its owner")
	s=rules.create(2);s.head=Model.FOOD[2];s.history=[];s.focus[0]=15;s.focus[2]=15
	for i in 61:s.history.append(Model.FOOD[0])
	s=rules.step(s,{"x":0,"y":0,"dash":false})
	check(s.collected==[0,2],"actor and delayed light finish distinct endpoints of one pair together")
	s=rules.create(2);s.head=Model.FOOD[2];s.history=[];s.focus[0]=15;s.focus[2]=15
	for i in 61:s.history.append(Model.FOOD[2])
	s=rules.step(s,{"x":0,"y":0,"dash":false})
	check(s.collected.is_empty() and s.focus[0]==0 and s.focus[2]==0,"both actors at one end cannot fake simultaneous cooperation")
	check(rules.create(2).history.size()==1 and rules.echo(rules.create(2)).is_empty(),"retry clears historical light and all temporary exposure")
	# The same optical geometry can finish while protected, but hurt wins at tick 18.
	s=rules.create(2);s.tick=17;s.head=Vector2(581.187304,340.863655);s.collected=[0,2,4,3];s.focus[5]=15;s.focus[1]=15;s.history=[]
	for i in 61:s.history.append(Model.FOOD[5])
	var axis:Vector2=rules.pointer_axis(s,s.head);var input:Dictionary={"x":axis.x,"y":axis.y,"dash":false}
	var protected:Dictionary=s.duplicate(true);protected.invulnerable=2
	protected=rules.step(protected,input)
	check(protected.collected.size()==6,"same-tick optical witness would otherwise complete the final cooperative pair")
	s=rules.step(s,input)
	check(s.lastEvent=="hurt" and s.collected==[0,2,4,3] and s.focus==[0,0,0,0,0,0],"third-act damage cancels joint completion before submission")
	check(s.history.size()==62 and not rules.echo(s).is_empty(),"third-act injury retains the exact cooperative history")
	print("THEATER_BALANCE: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
