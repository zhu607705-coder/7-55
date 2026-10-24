extends SceneTree
const Model=preload("res://scripts/games/chapter4_clock_chain.gd")
const Driver=preload("res://tests/helpers/clock_chain_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:run.call_deferred()
func run()->void:
	for id:String in Model.IDS:
		var cp:Dictionary=Model.fresh(id)
		var spec:Dictionary=Model.data().runs[id]
		for event:Dictionary in Driver.events(id):
			if cp.step==4:break
			cp=Model.transition(id,cp,event).checkpoint
		check(cp.step==4,"inference leads to the actual mechanism")
		for axis:String in Model.WHEELS:
			var result:Dictionary=Model.transition(id,cp,{"kind":"lock","axis":axis})
			check(result.accepted,"wrong-position latch is a real operable latch")
			cp=result.checkpoint
		check(cp.step==4 and cp.locks.size()==2,"locking both axes does not certify either answer")
		var trial:Dictionary=Model.transition(id,cp,{"kind":"compare_wheels"})
		check(not trial.accepted and trial.checkpoint==cp,"whole wrong time fails without marking the right subanswer")
		check(Model.valid_run(cp,id),"wrong locked configuration remains saveable")
		for axis:String in Model.WHEELS:cp=Model.transition(id,cp,{"kind":"lock","axis":axis}).checkpoint
		for event:Dictionary in Driver.events(id):
			if event.kind in ["wheel","lock","compare_wheels"]:cp=Model.transition(id,cp,event).checkpoint
		check(cp.step==5,"whole aligned pair opens the receiver circuit")
		for channel:Dictionary in Model.channels(id):cp=Model.transition(id,cp,{"kind":"trim","channel":channel.id,"correction":-channel.drift}).checkpoint
		check(cp.step==5 and not Model.balanced(id,cp.trims),"independently negating each drift fails the linked circuit")
		check(not Model.transition(id,cp,{"kind":"balance"}).accepted,"three chosen corrections are not three accepted answers")
		check(Model.valid_run(cp,id),"wrong complete draft survives saving")
		var before:Array=Model.residuals(id,{"dial":0,"movement":0,"phone":0})
		var changed:Array=Model.residuals(id,{"dial":1,"movement":0,"phone":0})
		check(changed==[before[0]+1,before[1]+1,before[2]],"first wheel shifts both connected receivers and leaves independent receiver alone")
		for event:Dictionary in Driver.events(id):
			if event.kind in ["trim","balance","sample","verify"]:cp=Model.transition(id,cp,event).checkpoint
		check(cp.step==7 and Model.valid_run(cp,id),"observed circuit relationship works for every changed drift case")
		var old:Dictionary=cp.duplicate(true)
		for channel:Dictionary in Model.channels(id):old.trims[channel.id]=-channel.drift
		var legacy:Dictionary={"version":1,"runs":{id:old}}
		check(Model.valid(legacy),"original seven-stage receipt remains readable")
		var migrated:Dictionary=Model.storage({"native":{"c4_clock_chain":legacy}})
		check(migrated.version==2 and Model.valid(migrated) and migrated.runs[id].step==7,"legacy full calibration translates to linked circuit without replaying story")
		check(legacy.version==1 and legacy.runs[id]==old,"migration is a detached copy")
		var bad:Dictionary=migrated.duplicate(true);bad.runs[id].trims.phone+=1
		check(not Model.valid(bad),"completed receipt rejects a mismatched final pulse")
	print("CLOCK_DISCOVERY ",checks," checks; ",failures," failures");quit(1 if failures else 0)
