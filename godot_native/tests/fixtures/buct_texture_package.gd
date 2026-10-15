extends SceneTree
const VALIDATOR=preload("res://campuses/buct_haidian/scripts/imported_texture_validator.gd")
var errors: Array[String]=[]
var checks:=0
var rows: Array[Dictionary]=[]
func _initialize() -> void:run.call_deferred()
func check(value: bool,label: String) -> void:
 checks+=1;print("PASS " if value else "FAIL ",label)
 if not value:errors.append(label)
func run() -> void:
 var expected_sha: String=OS.get_environment("BUCT_PACKAGE_EXPECTED_SHA")
 check(not FileAccess.file_exists("res://valid.png"),"Actual PCK omits source PNG")
 check(FileAccess.file_exists("res://valid.png.import") and FileAccess.file_exists("res://.godot/imported/valid.ctex"),"Actual PCK contains import mapping and ctex")
 check(ResourceLoader.exists("res://valid.png","Texture2D"),"ResourceLoader resolves source-less imported texture in PCK")
 var imported: Texture2D=load("res://valid.png")
 check(imported!=null and imported.get_size()==Vector2(54,58),"Real compressed texture loads expected dimensions")
 for item in [["valid.png",Vector2i(54,58),expected_sha,true,"validated_import_without_source"],["with-source.png",Vector2i(54,58),expected_sha,true,"validated_source_and_import"],["corrupt-source.png",Vector2i(54,58),expected_sha,false,"available_source_sha256_mismatch"],["with-source.png",Vector2i(54,58),"0".repeat(64),false,"available_source_sha256_mismatch"],["valid.png",Vector2i(55,58),expected_sha,false,"imported_dimensions_mismatch"],["missing.png",Vector2i(54,58),expected_sha,false,"missing_resource"],["missing-data.png",Vector2i(54,58),expected_sha,false,""],["bad-data.png",Vector2i(54,58),expected_sha,false,""],["wrong-type.tres",Vector2i(54,58),expected_sha,false,"invalid_texture_resource"]]:
  var result: Dictionary=VALIDATOR.inspect("res://"+str(item[0]),item[2],item[1]);result.fixture=item[0];rows.append(result)
  check(result.ok==item[3],"Packaged validator expected outcome: "+str(item[0])+" "+str(item[1]))
  if not str(item[4]).is_empty():check(result.reason==item[4],"Specific fail-closed reason: "+str(item[4]))
 var path: String=OS.get_environment("BUCT_PACKAGE_REPORT")
 var report: Dictionary={"checks":checks,"errors":errors,"cases":rows,"source_png_absent_valid_import":true,"fixture_size_bytes":FileAccess.get_file_as_bytes(OS.get_environment("BUCT_PACKAGE_PCK")).size(),"qualification":"Actual standalone PCK mounted as main pack; raw PNG omitted for valid import case. Loader ERROR diagnostics for deliberate missing/broken resources are expected negative fixtures."}
 var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print("RONGMAO_PACKAGED_VALIDATOR ","PASS" if errors.is_empty() else "FAIL"," checks=",checks)
 quit(0 if errors.is_empty() else 1)
