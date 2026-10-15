extends SceneTree
func _initialize() -> void:
 var files: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("BUCT_PACKAGE_FILES")))
 var packer:=PCKPacker.new()
 if packer.pck_start(OS.get_environment("BUCT_PACKAGE_PCK"))!=OK:quit(1);return
 for relative in files:
  var result: int=packer.add_file("res://"+relative,str(files[relative]))
  if result!=OK:printerr("Pack add failed ",relative," ",result);quit(1);return
 var result: int=packer.flush()
 print("TINY_TEXTURE_PACKAGE_BUILT result=",result," files=",files.size())
 quit(0 if result==OK else 1)
