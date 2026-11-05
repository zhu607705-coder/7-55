extends SceneTree
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
 check(g._movement_hint()=="拖动窗口","first encounter offers only a short object-action cue")
 g.session.moved_distance=7
 check(g._movement_hint().is_empty(),"moving the window removes the cue")
 g.session.moved_distance=0;g.session.stage=1
 check(g._movement_hint().is_empty(),"later rounds do not repeat the tutorial")
 check(g._round_goal()=="一下 · 旁白","unordered targets remain legible without report labels")
 g.session.stage=2
 check(g._round_goal()=="帮我 → 补个 → 签到","ordered targets still communicate their sequence")
 g.session.hint={"reason":"order"}
 check(g._round_error()=="先接“帮我”","order mistake keeps the one recovery detail the player needs")
 g.session.hint={"reason":"meaning"}
 check(g._round_error()=="接错了","wrong catch feedback is brief")
 g.session.hint={"reason":"late"}
 check(g._round_error()=="没接住","miss feedback is brief")
 check(g._lock_feedback()=="按住","visible ring needs only a short hold cue")
 g.lock_release_count=1
 check(g._lock_feedback()=="再按住一会儿","early release gets concise recovery feedback")
 check(content.stages.all(func(s):return s.fragments.size()==1),"each round has one narrative fragment instead of four teaching lines")
 for st in range(3):
  g.session.stage=st
  check(is_equal_approx(g.session.clue_duration(),3.6),"round %d keeps its brief orientation beat with shorter copy"%(st+1))
 g.session.reading_time_scale=2
 check(is_equal_approx(g.session.clue_duration(),7.2),"reduced-motion orientation time still doubles")
 g.free()
 print(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"  "))
 quit(0 if failures.is_empty() else 1)
