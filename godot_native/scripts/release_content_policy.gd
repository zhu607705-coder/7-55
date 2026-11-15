extends RefCounted
## Export features select the shipped content; saved state and launch arguments
## cannot bring research-only campuses back into a story-only release.
const STORY_FAMILIES := ["chapter2", "chapter2_campus", "chapter2_library", "chapter3", "chapter35", "chapter4"]
const LATER_CHAPTER_FAMILIES := ["chapter3", "chapter35", "chapter4"]
const LATER_CHAPTER_SCENES := ["canteen_interior", "theater_interior", "campus_qizhen_loop", "qizhen_lake", "duan_yongping_temporal_maze"]
const CHAPTER_LIMIT_NOTICE := "线上试玩开放到第二章。第三章和第四章暂未开放。"
const FULL_CHAPTER_LIMIT := 4
static var chapter_limit := FULL_CHAPTER_LIMIT
const PHONE_FAMILIES := ["phone_bonsai", "phone_tiyi", "phone_zjuding"]
const ACTIVITY_FAMILIES := ["flc_activity"]
const CAMPUS_FAMILIES := ["campus_shared", "campus_chaoyang", "campus_haidian", "campus_changping"]

static func story_only() -> bool:
	return OS.has_feature("755_story_only")

static func flc_activity_available() -> bool:
	return true

static func campuses_available() -> bool:
	return not story_only()

static func chapter_available(chapter: int) -> bool:
	return chapter <= chapter_limit

static func route_available(page: String, scene: String) -> bool:
	if chapter_available(3): return true
	return scene not in LATER_CHAPTER_SCENES and not page.begins_with("c3_") and not page.begins_with("c35_") and not page.begins_with("c4_")

static func permits_snapshot(snapshot: Dictionary) -> bool:
	if chapter_available(3): return true
	var native: Dictionary = snapshot.native if snapshot.get("native") is Dictionary else {}
	if int(native.get("chapter", 1)) > chapter_limit: return false
	if not route_available(str(native.get("page", "")), str(native.get("scene", ""))): return false
	if not route_available(str(snapshot.get("currentScene", "")), str(snapshot.get("rpgScene", ""))): return false
	var initial_phases := {"canteenHunt": "tracking", "theaterHunt": "entry_ticket", "qizhenLake": "inactive"}
	for key: String in initial_phases:
		var story: Variant = snapshot.get(key)
		if story is Dictionary and (bool(story.get("active", false)) or str(story.get("phase", "")) not in ["", "idle", "inactive", initial_phases[key]]): return false
	var later: Variant = snapshot.get("chapter4")
	return not later is Dictionary or not (bool(later.get("prologueSeen", false)) or bool(later.get("completed", false)))

static func family_available(family: Variant, limit: int = -1) -> bool:
	if (chapter_limit if limit < 0 else limit) < 3 and family in LATER_CHAPTER_FAMILIES: return false
	return family is String and (family in STORY_FAMILIES or family in PHONE_FAMILIES or family in ACTIVITY_FAMILIES or (campuses_available() and family in CAMPUS_FAMILIES))

static func scene_available(path: String) -> bool:
	var normalized := path.simplify_path()
	return campuses_available() or normalized.begins_with("res://campuses/future_learning_center/scripts/") or normalized.begins_with("res://campuses/future_learning_center/scenes/") or not normalized.begins_with("res://campuses/")
