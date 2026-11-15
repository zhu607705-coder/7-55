extends SceneTree
const Policy = preload("res://scripts/release_content_policy.gd")
const Content = preload("res://scripts/platform/web_content.gd")
const Storage = preload("res://scripts/platform/profile_storage.gd")
const Posts = preload("res://scripts/data/cc98_store.gd")
var state: Node
var failures := 0
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(why)
func write(path: String, text: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	check(file != null,"fixture opens only the isolated test file")
	if file: file.store_string(text); file.close()
func data(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
func digest(path: String) -> String:
	return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
func public_edition() -> void:
	var content := Content.new(); root.add_child(content)
	var manifest := {"schema":"755-web-content-v1","core":{"file":"index.pck","bytes":1,"sha256":"a".repeat(64)},"packs":[],"backgroundOrder":[],"publicChapterLimit":2}
	check(content._configure_manifest(JSON.parse_string(JSON.stringify(manifest)), null),"serialized Pages policy activates normally")
	check(not Policy.chapter_available(3),"later chapters are actually unavailable")
func seed_later() -> void:
	state.d = state.initial()
	state.d.native.chapter = 3
	state.d.native.scene = "qizhen_lake"; state.d.native.page = "c3_journal_camera"
	state.d.rpgScene = "qizhen_lake"; state.d.runtimeMode = "rpg"
	state.d.qizhenLake.active = true; state.d.qizhenLake.phase = "lake_exploration"
	check(state.validate_snapshot(state.d),"later fixture is a valid original-engine snapshot")
func backup_case(locked: bool, profile: String) -> void:
	Policy.chapter_limit = 4
	check(state.activate_profile(profile,false).ok,"isolated profile opens")
	if locked: seed_later()
	check(state.save_game(),"original campaign writes primary")
	state.d.phoneBattery.percent = 82
	check(state.save_game(),"original campaign writes previous snapshot")
	var original_primary := data(state.SAVE_PATH)
	var original_backup := data(state.BACKUP_PATH)
	public_edition()
	if locked:
		check(not state.load_game() and not state.chapter_locked_save_path.is_empty(),"public edition protects later story before restart")
		check(state.restart_chapter_limited_save(),"explicit restart succeeds after archiving")
		var archived: Array[String] = []
		for path in state.chapter_backup_files():
			if path.contains(".before-online-chapter-limit-"): archived.append(data(path))
		check(original_primary in archived and original_backup in archived,"both original story files remain byte-identical in archives")
	state.d.phoneBattery.percent = 75; check(state.save_game(),"new campaign first progress saves")
	var prior_primary := data(state.SAVE_PATH)
	state.d.phoneBattery.percent = 74; check(state.save_game(),"new campaign next progress saves")
	var previous_tracks_new: bool = data(state.BACKUP_PATH) == prior_primary
	var backup_chapter: int = int(JSON.parse_string(data(state.BACKUP_PATH)).state.native.chapter)
	write(state.SAVE_PATH,"{invalid-json")
	state.d = state.initial()
	var recovered: bool = state.load_game()
	print("CHAPTER_SAVE_BACKUP ",JSON.stringify({"locked_old_backup":locked,"previous_tracks_new_campaign":previous_tracks_new,"backup_chapter":backup_chapter,"recovered":recovered,"recovered_battery":state.d.phoneBattery.percent,"chapter_locked_path":state.chapter_locked_save_path,"user_dir":OS.get_user_data_dir()}))
	check(previous_tracks_new,"after restart, normal backup must track the new campaign")
	check(recovered and state.d.phoneBattery.percent == 75,"corrupt primary must recover the new campaign's last good snapshot")
func reset_legacy() -> void:
	Policy.chapter_limit = 4
	for path: String in ["user://save.json", "user://save.previous.json", "user://cc98-posts.json", "user://cc98-quest-post-overrides.json", "user://profiles/guest/save.json", "user://profiles/guest/save.previous.json", "user://profiles/guest/cc98-posts.json", "user://profiles/guest/cc98-quest-post-overrides.json"]:
		if FileAccess.file_exists(path): check(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK, "remove only the previous isolated fixture")
	Storage.profile = "legacy"
	state.SAVE_PATH = "user://save.json"; state.BACKUP_PATH = "user://save.previous.json"
	Posts.posts_path = "user://cc98-posts.json"; Posts.quest_path = "user://cc98-quest-post-overrides.json"
	state.d = state.initial(); state.developer_mode = false; state.persistence_ready = true
	state.chapter_locked_save_path = ""; state._invalidate_save_receipt()

func guest_case(locked: bool) -> void:
	reset_legacy()
	if locked: seed_later()
	else: state.d = state.initial()
	check(state.save_game(),"legacy story writes normally in full edition")
	var post := {"id":"pr256-guest-edited-note","avatar":"anonymous"}
	for field in Posts.POST_FIELDS: post[field] = "隔离验证：游客保留的个人编辑"
	var overrides := {"act-two-gamepad-market":{"title":"隔离验证：游客改过的剧情帖标题"}}
	check(Posts.import_bundle({"posts":[post],"questPostOverrides":overrides}) == OK,"valid edited documents are saved separately")
	var originals := {"story":digest("user://save.json"),"posts":digest("user://cc98-posts.json"),"quest":digest("user://cc98-quest-post-overrides.json")}
	public_edition()
	var activated: Dictionary = state.activate_profile("guest")
	check(activated.get("ok",false),"guest activation reports success")
	if locked:
		check(activated.get("chapterLocked",false),"legacy later chapter is protected")
		check(state.restart_chapter_limited_save(),"guest can explicitly restart the available chapters")
	else: check(activated.get("hasSave",false),"playable legacy guest story migrates")
	var posts_kept: bool = Posts.load_posts().any(func(row): return row.id == post.id and row.body == post.body)
	var quest_kept: bool = Posts.load_quest_overrides() == overrides
	var source_intact: bool = digest("user://save.json") == originals.story and digest("user://cc98-posts.json") == originals.posts and digest("user://cc98-quest-post-overrides.json") == originals.quest
	var reactivated: Dictionary = state.activate_profile("guest")
	var still_visible: bool = Posts.load_posts().any(func(row): return row.id == post.id)
	print("CHAPTER_SAVE_GUEST ",JSON.stringify({"locked_legacy":locked,"activation":activated,"posts_preserved":posts_kept,"quest_overrides_preserved":quest_kept,"legacy_source_bytes_intact":source_intact,"reentry":reactivated,"visible_after_reentry":still_visible,"active_posts_path":Posts.posts_path,"active_posts_exists":FileAccess.file_exists(Posts.posts_path),"active_quest_exists":FileAccess.file_exists(Posts.quest_path),"user_dir":OS.get_user_data_dir()}))
	check(source_intact,"legacy source documents and story are never overwritten")
	check(posts_kept and quest_kept,"personal CC98 documents must migrate independently of story availability")
	check(reactivated.get("hasSave",false) and still_visible,"guest edits must remain visible after re-entry")
func protected_backup_cases() -> void:
	Policy.chapter_limit = 4
	check(state.activate_profile("33333333-3333-4333-8333-333333333333", false).ok, "archive protection profile opens")
	seed_later(); check(state.save_game(), "later primary saved")
	state.d.phoneBattery.percent = 80; check(state.save_game(), "later backup saved")
	public_edition()
	var primary := data(state.SAVE_PATH); var previous := data(state.BACKUP_PATH)
	var archive: String = state._chapter_locked_archive_path(state.BACKUP_PATH, previous.to_utf8_buffer())
	write(archive, "conflicting archive bytes")
	check(not state.load_game(), "later checkpoint stays locked")
	check(not state.restart_chapter_limited_save(), "archive collision blocks restart")
	check(data(state.SAVE_PATH) == primary and data(state.BACKUP_PATH) == previous, "failed archive preserves both old slots")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(archive)) == OK, "remove only the injected collision")
	check(state.restart_chapter_limited_save(), "retry archives original bytes before restarting")
	write(archive, "damaged archive bytes")
	state.d.phoneBattery.percent = 70; check(state.save_game(), "new primary can progress")
	check(data(state.BACKUP_PATH) == previous, "damaged archive never authorizes overwriting the old backup")
	write(archive, previous)
	state.d.phoneBattery.percent = 69; check(state.save_game(), "verified archive permits subsequent backup rotation")
	check(int(JSON.parse_string(data(state.BACKUP_PATH)).state.phoneBattery.percent) == 70, "new backup resumes at the actual previous primary")

func guest_document_edges() -> void:
	reset_legacy(); seed_later(); check(state.save_game(), "edge fixture has a valid locked legacy story")
	var post := {"id":"pr256-edge-note","avatar":"anonymous"}
	for field in Posts.POST_FIELDS: post[field] = "legacy document edit"
	var quest := {"act-two-gamepad-market":{"title":"legacy quest edit"}}
	check(Posts.import_bundle({"posts":[post],"questPostOverrides":quest}) == OK, "edge fixture writes valid legacy documents")
	var legacy_posts := data(Posts.posts_path); var legacy_quest := data(Posts.quest_path)
	var legacy_story := data(state.SAVE_PATH)
	# Already-restarted guests from the affected release have a story file but no documents.
	check(state.activate_profile("guest", false).ok and state.save_game(), "simulate an already restarted guest")
	public_edition()
	check(state.activate_profile("guest").get("hasSave",false), "existing guest story still loads")
	check(Posts.load_posts().any(func(row): return row.id == post.id) and Posts.load_quest_overrides() == quest, "missing documents are also repaired after an earlier restart")
	check(data("user://save.json") == legacy_story, "repair never reloads or overwrites the unavailable legacy story")
	# An edited guest document wins; only its missing companion migrates.
	post.body = "newer guest edit"
	check(Posts.import_bundle({"posts":[post]}) == OK, "guest writes its own newer document")
	var guest_bytes := data(Posts.posts_path)
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(Posts.quest_path)) == OK, "remove only the generated companion fixture")
	check(state.activate_profile("guest").ok, "partial document migration can repeat")
	check(data(Posts.posts_path) == guest_bytes and Posts.load_quest_overrides() == quest, "existing guest bytes survive while missing quest edits migrate")
	# Failed migration must not authorize autosave or leave a half-written document pair.
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(Posts.posts_path)) == OK, "clear fixture posts")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(Posts.quest_path)) == OK, "clear fixture overrides")
	write("user://cc98-quest-post-overrides.json", "{broken")
	var story_bytes := data(state.SAVE_PATH)
	check(not state.activate_profile("guest").ok and not state.save_game(), "invalid legacy documents block migration and accidental autosave")
	check(not FileAccess.file_exists(Posts.posts_path) and not FileAccess.file_exists(Posts.quest_path) and data(state.SAVE_PATH) == story_bytes, "invalid document pair leaves the target untouched")
	write("user://cc98-quest-post-overrides.json", legacy_quest)
	check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(Posts.quest_path)) == OK, "inject a target promotion failure in the disposable profile")
	check(not state.activate_profile("guest").ok and not state.save_game(), "document promotion failure blocks activation and autosave")
	check(not FileAccess.file_exists(Posts.posts_path) and data(state.SAVE_PATH) == story_bytes, "second-document failure rolls back the first document")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(Posts.quest_path)) == OK, "clear injected target directory")
	check(state.activate_profile("guest").ok and state.persistence_ready, "successful retry restores normal persistence")
	check(Posts.load_posts().any(func(row): return row.id == post.id and row.body == "legacy document edit") and Posts.load_quest_overrides() == quest, "successful retry installs both original documents")
	check(data("user://cc98-posts.json") == legacy_posts and data("user://cc98-quest-post-overrides.json") == legacy_quest, "all migration retries preserve the legacy source bytes")

func run() -> void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("Refusing non-temporary user://"); quit(2); return
	state = root.get_node("State"); state.developer_mode = false
	backup_case(true, "11111111-1111-4111-8111-111111111111")
	backup_case(false, "22222222-2222-4222-8222-222222222222")
	protected_backup_cases()
	guest_case(true)
	guest_case(false)
	guest_document_edges()
	Policy.chapter_limit = 4
	print("PUBLIC_CHAPTER_SAVE_RECOVERY: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
