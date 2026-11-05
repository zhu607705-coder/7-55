extends SceneTree
## Presentation contract only; physical capture and ordinary input are tested
## by test_narrator_intentional_play.gd and test_narrator_motion_challenge.gd.
const Game=preload("res://scripts/games/prologue_interception.gd")
var checks=[]
var failures=[]
func _initialize():call_deferred("run")
func check(ok,label):
 checks.append({"name":label,"passed":ok})
 if not ok:failures.append(label)
func run():
 var content=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/prologue-interception.content.json"))
 var g=Game.new();g.content=content;g.session.setup(content)
 var line=str(content.get("retainedLine",""))
 var words=""
 var earned=[]
 for stage_index in content.stages.size():
  for word in content.stages[stage_index].targets:
   words+=word;earned.append({"stage":stage_index,"word":word})
 check(line=="等一下，旁白，帮我补个签到！","retained line is the player's request that leads into the original bargain")
 check(line.replace("，","").replace("！","")==words,"line contains exactly the six target words in authored order")
 check(content.stages.map(func(s):return s.targets.size())==[1,2,3],"one/two/three target progression is unchanged")
 check(not content.stages[0].ordered and not content.stages[1].ordered and content.stages[2].ordered,"second round remains unordered; third round remains ordered")
 check(g._retained_sentence().is_empty(),"no final line is shown before earned completion")
 g.session.completed_stages=3
 check(g._retained_sentence().is_empty(),"completion count alone cannot supply missing captured words")
 g.session.captures=earned.duplicate(true)
 var before=JSON.stringify(g.session.captures)
 check(g._retained_sentence()==line,"six captured words yield the natural sentence")
 check(JSON.stringify(g.session.captures)==before and g.session.completed_stages==3,"formatting never mutates captures or progression")
 var swap=g.session.captures[1];g.session.captures[1]=g.session.captures[2];g.session.captures[2]=swap
 check(g._retained_sentence()==line,"reversed capture order in second round still reads correctly")
 g.session.captures.pop_back()
 check(g._retained_sentence().is_empty(),"missing final target hides the assembled line")
 g.session.captures.append({"stage":1,"word":"签到"})
 check(g._retained_sentence().is_empty(),"a same-text record from a different round cannot fill the gap")
 g.session.captures=earned.duplicate(true);g.session.completed_stages=2
 check(g._retained_sentence().is_empty(),"complete words without completed rounds cannot show the final line")
 g.session.setup({"stages":[]})
 check(g._retained_sentence().is_empty(),"empty stage data cannot show an unearned line")
 var masks=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/prologue-ascii-masks.json")).masks
 var missing=[]
 for s in content.stages:
  for text in s.targets+s.distractors+s.fragments:
   for i in text.length():
    var c=text.substr(i,1)
    if c.unicode_at(0)>=0x4e00 and c.unicode_at(0)<=0x9fff and not masks.has(c):missing.append(c)
 check(missing.is_empty(),"every changed clue and target has an ASCII glyph mask")
 g.free()
 var report={"passed":failures.is_empty(),"checks":checks,"failures":failures}
 print(JSON.stringify(report,"  "))
 quit(0 if failures.is_empty() else 1)
