extends RefCounted
## Account namespaces are local folders, never an authentication authority.
static var profile := "legacy"
static func valid_key(key: String) -> bool:
	if key in ["guest","legacy"]: return true
	var expression:=RegEx.new();expression.compile("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$")
	return expression.search(key)!=null
static func folder() -> String:
	return "user://" if profile=="legacy" else "user://profiles/"+profile+"/"
static func file(name: String) -> String:
	return folder()+name
static func journal_folder() -> String:
	return file("qizhen_journal/")
static func valid_photo_path(path: String) -> bool:
	if path.contains("..") or path.length()>256: return false
	var expression:=RegEx.new()
	expression.compile("^user://(?:profiles/(?:guest|[a-f0-9-]{36})/)?qizhen_journal/[^/]+\\.png$")
	return expression.search(path)!=null
static func owns_photo(path: String) -> bool:
	return valid_photo_path(path) and path.begins_with(journal_folder())
