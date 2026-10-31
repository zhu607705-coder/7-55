extends RefCounted
## Export features select the shipped content; saved state and launch arguments
## cannot bring research-only campuses back into a story-only release.
const STORY_FAMILIES := ["chapter2", "chapter3", "chapter35", "chapter4"]
const ACTIVITY_FAMILIES := ["flc_activity"]
const CAMPUS_FAMILIES := ["campus_shared", "campus_chaoyang", "campus_haidian", "campus_changping"]

static func story_only() -> bool:
	return OS.has_feature("755_story_only")

static func flc_activity_available() -> bool:
	return true

static func campuses_available() -> bool:
	return not story_only()

static func family_available(family: Variant) -> bool:
	return family is String and (family in STORY_FAMILIES or family in ACTIVITY_FAMILIES or (campuses_available() and family in CAMPUS_FAMILIES))

static func scene_available(path: String) -> bool:
	var normalized := path.simplify_path()
	return campuses_available() or normalized.begins_with("res://campuses/future_learning_center/scripts/") or normalized.begins_with("res://campuses/future_learning_center/scenes/") or not normalized.begins_with("res://campuses/")
