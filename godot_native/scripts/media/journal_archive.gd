extends RefCounted
## Portable native save attachments. Paths never come from archive entries;
## every imported PNG is verified and installed under its own SHA-256 name.
const MAX_IMAGE_BYTES:=12*1024*1024
const MAX_TOTAL_BYTES:=32*1024*1024
static func photos(state: Dictionary) -> Array:
	var result: Array=[]
	var journal: Dictionary=state.get("qizhenLake",{}).get("journal",{})
	if journal.get("mainPhoto") is Dictionary: result.append(journal.mainPhoto)
	for photo: Variant in journal.get("optionalPhotos",{}).values():
		if photo is Dictionary: result.append(photo)
	if journal.get("pendingDraft") is Dictionary and journal.pendingDraft.get("photo") is Dictionary: result.append(journal.pendingDraft.photo)
	return result
static func digest(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(bytes); return hash.finish().hex_encode()
static func pack(state: Dictionary) -> Dictionary:
	var images: Dictionary={}
	var total:=0
	for photo: Dictionary in photos(state):
		if not photo.has("nativeImagePath"): continue
		var sha: String=str(photo.get("nativeImageSha256",""))
		if images.has(sha): continue
		var path: String=photo.nativeImagePath
		if not path.begins_with("user://qizhen_journal/") or path.contains("..") or not FileAccess.file_exists(path): return {"ok":false,"error":ERR_FILE_NOT_FOUND}
		var bytes:=FileAccess.get_file_as_bytes(path); total+=bytes.size()
		if bytes.size()>MAX_IMAGE_BYTES or total>MAX_TOTAL_BYTES or digest(bytes)!=sha: return {"ok":false,"error":ERR_INVALID_DATA}
		images[sha]={"mime":"image/png","data":Marshalls.raw_to_base64(bytes)}
	return {"ok":true,"images":images}
static func prepare(state: Dictionary, archive: Variant) -> Dictionary:
	if not archive is Dictionary or archive.size()>4: return {"ok":false}
	var required: Dictionary={}
	for photo: Dictionary in photos(state):
		if photo.has("nativeImagePath"): required[str(photo.nativeImageSha256)]=true
	if archive.size()!=required.size(): return {"ok":false}
	var images: Dictionary={}; var total:=0
	for sha: Variant in archive:
		if not sha is String or sha.length()!=64 or not required.has(sha): return {"ok":false}
		var entry: Variant=archive[sha]
		if not entry is Dictionary or entry.get("mime")!="image/png" or not entry.get("data") is String: return {"ok":false}
		if entry.data.length()>MAX_IMAGE_BYTES*4/3+4: return {"ok":false}
		var encoded: String=entry.data
		if encoded.length()%4!=0: return {"ok":false}
		for index in range(encoded.length()):
			var character: String=encoded.substr(index,1)
			if "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".find(character)<0 and not (character=="=" and index>=encoded.length()-2): return {"ok":false}
		var bytes:=Marshalls.base64_to_raw(encoded); total+=bytes.size()
		if bytes.is_empty() or bytes.size()>MAX_IMAGE_BYTES or total>MAX_TOTAL_BYTES or Marshalls.raw_to_base64(bytes)!=entry.data or digest(bytes)!=sha: return {"ok":false}
		# Check PNG dimensions before decoding to avoid decompression bombs.
		if bytes.size()<24 or bytes.slice(0,8)!=PackedByteArray([137,80,78,71,13,10,26,10]): return {"ok":false}
		var width: int=(int(bytes[16])<<24)|(int(bytes[17])<<16)|(int(bytes[18])<<8)|int(bytes[19])
		var height: int=(int(bytes[20])<<24)|(int(bytes[21])<<16)|(int(bytes[22])<<8)|int(bytes[23])
		if width<320 or width>3840 or height<180 or height>2160: return {"ok":false}
		var image:=Image.new()
		if image.load_png_from_buffer(bytes)!=OK or image.get_width()!=width or image.get_height()!=height: return {"ok":false}
		images[sha]=bytes
	return {"ok":true,"images":images}
static func install(state: Dictionary, images: Dictionary) -> Dictionary:
	var created: Array=[]
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://qizhen_journal"))!=OK: return {"ok":false,"created":created}
	for sha: String in images:
		var path: String="user://qizhen_journal/imported-"+sha+".png"
		if FileAccess.file_exists(path):
			if FileAccess.get_sha256(path)!=sha: rollback(created); return {"ok":false,"created":[]}
		else:
			var file:=FileAccess.open(path,FileAccess.WRITE)
			if file==null: rollback(created); return {"ok":false,"created":[]}
			created.append(path); file.store_buffer(images[sha]); file.flush(); var error:=file.get_error(); file.close()
			if error!=OK or FileAccess.get_sha256(path)!=sha: rollback(created); return {"ok":false,"created":[]}
	for photo: Dictionary in photos(state):
		if photo.has("nativeImagePath"): photo.nativeImagePath="user://qizhen_journal/imported-"+str(photo.nativeImageSha256)+".png"
	return {"ok":true,"created":created}
static func rollback(created: Array) -> void:
	for path: String in created:
		if path.begins_with("user://qizhen_journal/imported-"): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
