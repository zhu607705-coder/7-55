extends SceneTree
const FONT_PATH="res://campuses/future_learning_center/assets/fonts/flc_coverage_regular.otf"
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func scan(directory:String,font:FontFile)->void:
 for name in DirAccess.get_files_at(directory):
  if not (name.ends_with(".gd") or name.ends_with(".json")):continue
  var text:=FileAccess.get_file_as_string(directory.path_join(name))
  if name.ends_with(".json"):text=JSON.stringify(JSON.parse_string(text))
  for index in text.length():
   var cp:=text.unicode_at(index)
   if (cp>=0x3400 and cp<=0x9fff) or (cp>=0x20000 and cp<=0x3134f):check(font.has_char(cp),"FLC missing glyph "+String.chr(cp)+" in "+name)
 for name in DirAccess.get_directories_at(directory):scan(directory.path_join(name),font)
func _initialize()->void:
 var font:=FontFile.new();font.data=FileAccess.get_file_as_bytes(FONT_PATH);font.allow_system_fallback=false
 check(font.data.size()>0,"FLC coverage asset exists")
 check(FileAccess.get_sha256("res://ui_assets/fonts/SelectedCoverage-Regular.otf")=="b6ad88f4e3cefd19983153f1215f770fc3751028e4a98fb47107dde11741784a","historical Morning Note source unchanged")
 scan("res://campuses/future_learning_center/scripts",font)
 scan("res://campuses/future_learning_center/data",font)
 check(checks>1000,"authored FLC corpus must be present; no empty scan pass")
 print("FLC_FONT_COVERAGE ",checks," checks ",failures," failures");quit(1 if failures else 0)
