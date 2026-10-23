extends SceneTree
const Flow=preload("res://scripts/games/prologue_character_flow.gd")
const Game=preload("res://scripts/games/prologue_interception.gd")
var checks=0
var failures=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("CHARACTER FLOW: "+label)
func run()->void:
 check(Flow.FIELD_OCCUPANCY>=.9 and Flow.FLOW_CELL.x*Flow.FLOW_CELL.y/(Flow.STROKE_CELL.x*Flow.STROKE_CELL.y)>=2,"smaller continuous field is at least ninety percent occupied with denser stroke glyphs")
 check(Flow.FLOW_CELL==Vector2(4,6) and Flow.STROKE_CELL==Vector2(3,4),"field glyphs shrink while stroke glyphs retain legible native pixel cells")
 check(Flow.assembly_distance(0)==90 and Flow.assembly_distance(.14)>0 and Flow.assembly_distance(.14)<90 and Flow.assembly_distance(.28)==0 and Flow.ASSEMBLY_DURATION<.5,"four-sided glyph assembly settles before the earliest real word contact")
 var fragments=["字还在往外走。","窗口却留在原处。","这一次，","让一个‘等’留下。"]
 var parts=Flow.cloud_parts(fragments)
 var authored=""
 for fragment:String in fragments:
  for character:String in fragment:
   if character.unicode_at(0)>=0x4e00 and character.unicode_at(0)<=0x9fff:authored+=character
 check("".join(parts)==authored and parts.all(func(piece):return piece.length()>=1 and piece.length()<=4),"flowing clue words preserve every authored Hanzi in order")
 var continuous=true;var seen:Array=[]
 for frame:int in 1200:
  var words=Flow.cloud_words(fragments,frame/60.0)
  continuous=continuous and not words.is_empty() and words.size()<=6
  for word:Dictionary in words:
   if not word.text in seen:seen.append(word.text)
   var ids=Flow.mask_letters(word.text)
   for index:int in word.text.length():continuous=continuous and ids[index]>=0
 check(continuous and seen.size()==parts.size(),"clue cloud continuously exposes all original parts using the same valid ASCII Hanzi masks")
 var first=Flow.cloud_words(fragments,1.0)
 var next=Flow.cloud_words(fragments,1.01)
 check(first[0].text==next[0].text and is_equal_approx(next[0].position.y-first[0].position.y,Flow.CLUE_SPEED*.01),"word cloud descends continuously rather than flashing or holding a static page")
 check(Flow.FIELD_RECT==Rect2(0,0,430,820),"character field fills the former title and stage-counter area without changing physical gameplay geometry")
 var forbidden:Array=[]
 var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/prologue-interception.content.json"))
 for entry:Dictionary in source.stages:
  for word:String in entry.targets+entry.distractors:forbidden.append(word)
 var ambient_pool:Array=Flow.ambient_fragments()
 check(ambient_pool.size()>=40 and ambient_pool.all(func(piece):return piece.length()<=4 and not piece in forbidden),"extra fragments are a varied visual vocabulary rather than duplicate physical targets")
 var ambient_complete=true;var horizontal=0;var falling=0
 var ambient_before=Flow.ambient_words(1.0,0)
 var ambient_after=Flow.ambient_words(1.001,0)
 for index:int in ambient_before.size():
  var a:Dictionary=ambient_before[index];var b:Dictionary=ambient_after[index]
  var movement:Vector2=b.position-a.position
  if absf(movement.x)>absf(movement.y):horizontal+=1
  if movement.y>0:falling+=1
  ambient_complete=ambient_complete and a.text==b.text and movement.length()<2.0 and a.scale<.4 and a.alpha<.4
  var ids=Flow.mask_letters(a.text)
  for letter:int in a.text.length():ambient_complete=ambient_complete and ids[letter]>=0
 check(ambient_complete and ambient_before.size()==Flow.AMBIENT_SLOTS and horizontal>=4 and falling>=10,"dense small masked fragments move smoothly with intersecting directions below the real targets' scale and contrast")
 var mask=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/prologue-ascii-masks.json"))
 check(mask.grid==20 and mask.fontSha256==FileAccess.get_sha256(mask.font),"ASCII silhouettes come from the exact bundled original font")
 var silhouette_ok=true;var symbols={}
 for character:String in mask.masks:
  var cells=Flow.word_cells(character)
  var count=0
  for row:String in mask.masks[character]:count+=row.count("1")
  silhouette_ok=silhouette_ok and cells.size()==count and count>25
  for cell:Dictionary in cells:
   var extent=Flow.Layout.word_size(character)
   silhouette_ok=silhouette_ok and cell.glyph.unicode_at(0)<128 and Rect2(-extent/2,extent).has_point(cell.position)
   symbols[cell.glyph]=true
 check(silhouette_ok and symbols.size()>=4,"every sampled Hanzi stroke is formed by real ASCII symbols inside its measured silhouette")
 check(Flow.word_cells("等")!=Flow.word_cells("走") and Flow.word_cells("经度").size()==Flow.word_cells("经").size()+Flow.word_cells("度").size(),"distinct Hanzi and multi-character words retain original stroke geometry")
 var contrast=load("res://scripts/ui/native_ui_theme.gd")
 check(contrast._contrast(Flow.INK,Flow.BACKGROUND)>=7 and contrast._contrast(Flow.MUTED,Flow.PANEL)>=4.5,"terminal text preserves accessible contrast on its near-black surfaces")
 var previous=-1.0;var monotonic=true
 for frame:int in 96:
  var shade=Flow.burst_opacity(frame*.01)
  monotonic=monotonic and shade>=previous and shade<=1
  previous=shade
 check(monotonic and is_equal_approx(previous,1),"white handoff is one continuous wash without alternating whole-screen flashes")
 var g=Game.new();g.size=Vector2(390,780);root.add_child(g);g.set_process(false);g.start({"resume":true})
 check(g.field_material.shader==Game.AsciiField and g.field_material.get_shader_parameter("glyph_atlas")==Game.AsciiAtlas,"dense flow uses the original bitmap ASCII atlas independently from the approved parchment font")
 g._process(0);g._process(.25)
 check(not g.success_continue.visible,"already accepted check-in has no disconnected Continue receipt button")
 g._switch("deploy");g._process(.1)
 var bodies:PackedVector4Array=g.field_material.get_shader_parameter("word_data")
 check(bodies.size()==Flow.WORD_SLOTS and Array(bodies.slice(8)).filter(func(body):return body.z>0).size()==Flow.AMBIENT_SLOTS,"renderer receives every decorative fragment in bounded slots separate from its physical bodies")
 check(g.field_material.get_shader_parameter("field_rect")==Vector4(0,0,430,820),"GPU draw coordinates cover the complete unframed game field")
 var carried_clock=g.text_flow_clock
 g._switch("intercept");g._process(.01)
 check(is_equal_approx(g.text_flow_clock,carried_clock+.01),"presentation clock survives the reading-to-interception handoff without a reset")
 g._pause();g._process(0)
 check(g.resume_button.name=="PrologueResume" and g.resume_button.text=="返回字流" and g.resume_button.position.y>g.field.position.y+g.field.size.y*.8,"explicit system pause remains recoverable")
 g._resume();g._process(0)
 var normal_reading=g.session.clue_duration()
 g.start({"resume":true,"reduced_motion":true});g._process(0)
 g._switch("deploy");g._process(0)
 bodies=g.field_material.get_shader_parameter("word_data")
 check(Array(bodies.slice(2)).all(func(body):return body.z==0),"reduced motion omits the extra clutter and animated clue layers")
 check(is_equal_approx(g.session.clue_duration(),normal_reading*2),"reduced motion keeps the full original static-clue reading interval despite faster ordinary pacing")
 var removed_text=["再试这段字流","重看完整线索","继续寻找","显示落点帮助"]
 check(g.get_children().all(func(child):return not child is Button or not child.text in removed_text),"retry and clue actions are removed from the scene rather than merely hidden")
 g._pause();g._process(0)
 var saved=g.session.clock;var field_clock=g.field_material.get_shader_parameter("flow_clock")
 for frame:int in 60:g._process(.016)
 check(g.session.clock==saved and g.field_material.get_shader_parameter("flow_clock")==field_clock,"pause freezes the exact GPU advection clock as well as the physical word simulation")
 g.queue_free();await process_frame
 print("PROLOGUE_CHARACTER_FLOW: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
