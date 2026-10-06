extends SceneTree
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func run()->void:
	var owner:=root.get_node("State");var chapter:RefCounted
	for module in owner.modules:
		if str(module.get_script().resource_path)=="res://scripts/chapters/chapter4.gd":chapter=module
	for reduced in [true,false]:
		owner.begin_checkpoint("c4-755-closure");owner.developer_mode=false;owner.d.native.settings.reduced_motion=reduced
		check(owner.validate_snapshot(owner.d),"Original closure fixture is valid before completion")
		var issued:Dictionary=chapter.dispatch(owner.d,"c4_lamp_start")
		var choices:Dictionary={"purpose":"seek_truth","person":"clear_minded"}
		chapter.dispatch(owner.d,"c4_lamp_answers",{"session":issued.game.session,"answers":choices})
		var duration:=3600.0 if reduced else 5800.0
		var proof:Dictionary={"session":issued.game.session,"consumer":"ChapterFourStarLampClosure","answers":choices,"playbackMs":duration,"acknowledged":true,"playbackMode":"client_untrusted"}
		if not reduced:
			owner.d.native.settings.reduced_motion=true
			var forged:Dictionary=proof.duplicate(true);forged.playbackMs=3600;forged.playbackMode="reduced_motion"
			chapter.dispatch(owner.d,"c4_closure_done",forged)
			check(not owner.d.chapter4.completed,"Client mode/changed settings cannot shorten already-issued normal session")
		chapter.dispatch(owner.d,"c4_closure_done",proof)
		check(owner.d.chapter4.completed,"Authored duration completes validated session")
		check(owner.d.native.c4_closure_proof.get("playbackMode")==("reduced_motion" if reduced else "normal"),"Controller overwrites client marker from validated issued session")
		check(owner.validate_snapshot(owner.d),"Completed normal/reduced state passes actual save validation")
		var written:bool=owner.save_game();check(written,"Actual ordinary save writes completed mode "+str(reduced))
		if written:
			owner.d=owner.initial();check(owner.load_game(),"Ordinary reader reloads completed mode "+str(reduced))
			check(owner.d.chapter4.completed and owner.d.chapter4.zhuQuestionAnswers==choices and float(owner.d.native.c4_closure_proof.playbackMs)==duration,"Loaded state is the new completed save, not an older backup")
		var completed:Dictionary=owner.d.duplicate(true)
		if not reduced:
			var legacy:Dictionary=completed.duplicate(true);legacy.native.c4_closure_proof.erase("playbackMode")
			check(owner.validate_snapshot(legacy),"Legacy ordinary5800 proof remains compatible")
			legacy.native.c4_closure_proof.playbackMs=3600
			check(not owner.validate_snapshot(legacy),"Legacy proof still requires5800")
		for mode in ["normal","reduced_motion","client_untrusted",1,null]:
			var changed:Dictionary=completed.duplicate(true);changed.native.c4_closure_proof.playbackMode=mode;changed.native.c4_closure_proof.playbackMs=3599
			check(not owner.validate_snapshot(changed),"Short/unknown mode proof rejected "+str(mode))
	print("CHAPTER4_CLOSURE_SAVE_MODE ",checks," checks; ",failures," failures");quit(1 if failures else 0)
