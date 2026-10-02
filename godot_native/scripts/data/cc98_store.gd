extends RefCounted
## Player-edited fictional posts are a separate document, never part of story saves.
const POST_FIELDS = ["author","rank","board","title","replies","views","time","body"]
const AVATARS = ["warrior","blonde","anonymous","printer","coin","wind","cyclist","socket","auditor"]
const QUEST_IDS = ["act-two-gamepad-market","seat-022-backpack","qizhen-wet-paper-witness","chapter4-study-index","theater-755-ticket-commission"]
static var posts_path: String = "user://cc98-posts.json"
static var quest_path: String = "user://cc98-quest-post-overrides.json"

static func source(name: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/source/"+name+".json"))

static func defaults() -> Array:
	var out: Array = []
	for post in source("cc98.posts"):
		if post is Dictionary and str(post.get("id","")) not in QUEST_IDS: out.append(post.duplicate(true))
	return out

static func _read(path: String, fallback: Variant) -> Variant:
	if not FileAccess.file_exists(path): return fallback
	var file = FileAccess.open(path,FileAccess.READ)
	if not file or file.get_length() > 8*1024*1024: return fallback
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed != null else fallback

static func _editable(value: Variant) -> Dictionary:
	var clean: Dictionary = {}
	if not value is Dictionary: return clean
	for key in POST_FIELDS:
		if value.get(key) is String and str(value[key]).length() <= 200000: clean[key] = value[key]
	return clean

static func load_posts() -> Array:
	var baseline = defaults()
	var saved = _read(posts_path,[])
	if not saved is Array or saved.is_empty(): return baseline
	var by_id: Dictionary = {}
	for post in saved:
		if post is Dictionary and post.get("id") is String and str(post.id) not in QUEST_IDS:
			by_id[post.id] = post
	var known: Array = []
	for post in baseline:
		known.append(post.id)
		if by_id.has(post.id):
			var authored_replies=post.get("threadReplies")
			post.merge(_editable(by_id[post.id]),true)
			post.merge(_auxiliary(by_id[post.id]),true)
			if authored_replies is Array: post.threadReplies=authored_replies
	# Authored replies always come from current source. Valid extra fictional posts survive.
	for id in by_id:
		if id in known: continue
		var record: Dictionary = _editable(by_id[id])
		if record.size() != POST_FIELDS.size(): continue
		record.id = id
		record.avatar = by_id[id].get("avatar","anonymous") if by_id[id].get("avatar") in AVATARS else "anonymous"
		record.merge(_auxiliary(by_id[id]),true)
		baseline.append(record)
	return baseline

static func load_quest_overrides() -> Dictionary:
	var parsed = _read(quest_path,{})
	var clean: Dictionary = {}
	if parsed is Dictionary:
		for id in QUEST_IDS:
			if parsed.has(id): clean[id] = _editable(parsed[id])
	return clean

static func _atomic_write(path: String, data: Variant) -> Error:
	var file = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if not file: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data,"\t"))
	file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))

static func save_edits(changes: Dictionary) -> Error:
	var posts = load_posts()
	var overrides = load_quest_overrides()
	for id in changes:
		if not id is String or not changes[id] is Dictionary: return ERR_INVALID_DATA
		var clean = _editable(changes[id])
		if clean.size() != changes[id].size(): return ERR_INVALID_DATA
		if id in QUEST_IDS:
			var previous: Dictionary = overrides.get(id,{})
			previous.merge(clean,true)
			overrides[id] = previous
		else:
			var found = false
			for post in posts:
				if post.id == id: post.merge(clean,true); found = true; break
			if not found: return ERR_INVALID_DATA
	return _write_documents(posts,overrides)

static func restore_defaults() -> Error:
	return _write_documents(defaults(),{})

static func quest_posts(s: Dictionary) -> Array:
	var out: Array = []
	if s.actOne.phase in ["movement_required","reservation_briefing_required","reservation_required","movement_ready"]:
		out.append(source("act-one-bootstrap.content").cc98ExchangePost.duplicate(true))
	var puzzle: Dictionary = s.ui.libraryFinalsPuzzle
	if puzzle.investigationOpened:
		var post: Dictionary = source("library-finals.content").cc98.post.duplicate(true)
		post.rank = "01" if int(puzzle.bdCount)>=3 else "04"
		post.replies = str(int(post.replies)+source("library-finals.content").cc98.bdPassword.posts.size()) if puzzle.preBdBriefingSeen or int(puzzle.bdCount)>=3 else str(post.replies)
		out.append(post)
	if s.theaterHunt.cc98TicketCommissionPhase != "locked":
		var post: Dictionary = source("chapter3-theater.content").cc98TicketCommission.duplicate(true)
		post.avatar = "warrior"
		out.append(post)
	if s.qizhenLake.active and s.qizhenLake.phase == "location_search" and s.qizhenLake.bridgeClueFound:
		var content: Dictionary = source("chapter3-qizhen-lake.content").locationSearch.cc98
		out.append({"id":"qizhen-wet-paper-witness","author":"匿名用户","avatar":"anonymous","rank":"12","board":"校园生活","title":content.title,"replies":"3","views":"755","time":"刚刚","body":"如题。"})
	var overrides = load_quest_overrides()
	for post in out:
		var rank = post.get("rank","")
		var replies = post.get("replies","")
		post.merge(overrides.get(post.id,{}),true)
		if post.id == "seat-022-backpack": post.rank = rank; post.replies = replies
	return out

static func all_posts(s: Dictionary) -> Array:
	return quest_posts(s)+load_posts()

static func validate_bundle(stores: Variant) -> bool:
	if not stores is Dictionary or stores.is_empty(): return false
	for key in stores:
		if key not in ["posts","questPostOverrides"]: return false
	if stores.has("posts"):
		if not stores.posts is Array or stores.posts.size()>10000: return false
		for post in stores.posts:
			if not post is Dictionary or not post.get("id") is String or str(post.id).is_empty(): return false
			if _editable(post).size()!=POST_FIELDS.size(): return false
			if post.get("avatar") not in AVATARS: return false
	if stores.has("questPostOverrides"):
		if not stores.questPostOverrides is Dictionary: return false
		for id in stores.questPostOverrides:
			if id not in QUEST_IDS or not stores.questPostOverrides[id] is Dictionary: return false
			if _editable(stores.questPostOverrides[id]).size()!=stores.questPostOverrides[id].size(): return false
	return true

static func import_bundle(stores: Dictionary) -> Error:
	if not validate_bundle(stores): return ERR_INVALID_DATA
	var clean: Variant=null
	if stores.has("posts"):
		clean=[]
		for post in stores.posts:
			if post.id in QUEST_IDS: continue
			var record=_editable(post); record.id=post.id; record.avatar=post.avatar
			record.merge(_auxiliary(post),true)
			clean.append(record)
	return _write_documents(clean,stores.get("questPostOverrides"))

static func _write_documents(posts: Variant, overrides: Variant) -> Error:
	# Snapshot exact prior bytes before promoting either independently stored document.
	var had_posts=FileAccess.file_exists(posts_path)
	var prior=PackedByteArray()
	if posts!=null and had_posts:
		var old=FileAccess.open(posts_path,FileAccess.READ)
		if not old: return FileAccess.get_open_error()
		prior=old.get_buffer(old.get_length()); old.close()
	if posts!=null:
		var first=_atomic_write(posts_path,posts)
		if first!=OK: return first
	if overrides==null: return OK
	var second=_atomic_write(quest_path,overrides)
	if second==OK or posts==null: return second
	# A failed second promotion leaves the original first document byte-for-byte intact.
	var rollback=OK
	if had_posts:
		var file=FileAccess.open(posts_path+".rollback",FileAccess.WRITE)
		if not file: return FileAccess.get_open_error()
		file.store_buffer(prior); file.close()
		rollback=DirAccess.rename_absolute(ProjectSettings.globalize_path(posts_path+".rollback"),ProjectSettings.globalize_path(posts_path))
	else: rollback=DirAccess.remove_absolute(ProjectSettings.globalize_path(posts_path))
	return second if rollback==OK else rollback

static func _auxiliary(post: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for section in ["threadOperation","threadMetrics"]:
		if not post.get(section) is Dictionary: continue
		var fields=["user","action","reason"] if section=="threadOperation" else ["favorites","likes","dislikes"]
		var clean: Dictionary={}
		for key in fields:
			if post[section].get(key) is String: clean[key]=post[section][key]
		if clean.size()==fields.size(): result[section]=clean
	if post.get("threadReplies") is Array:
		var replies: Array=[]
		for reply in post.threadReplies:
			if not reply is Dictionary: continue
			var clean: Dictionary={}
			for key in ["personaId","time","floor","role","text","image","caption","likes","dislikes"]:
				if reply.get(key) is String and str(reply[key]).length()<=200000: clean[key]=reply[key]
			if clean.has("text") and clean.has("personaId"): replies.append(clean)
		result.threadReplies=replies
	return result
