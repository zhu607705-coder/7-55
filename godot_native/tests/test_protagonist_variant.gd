extends SceneTree

const Protagonist := preload("res://scripts/protagonist_profile.gd")
const WalkArt := preload("res://scripts/player_walk_art.gd")
const LibraryArt := preload("res://scripts/objects/library_animation_assets.gd")
const Chapter := preload("res://scripts/chapters/chapter1_2.gd")
const Director := preload("res://scripts/media/audio_director.gd")
const PhonePages := preload("res://scripts/ui/phone_pages.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("Protagonist tests require the isolated native save sandbox.")
		quit(2)
		return
	var state := root.get_node("State")
	var legacy: Dictionary = state.initial()
	check(not legacy.native.has(Protagonist.SAVE_KEY) and state.validate_snapshot(legacy), "legacy snapshot remains valid")
	check(Protagonist.variant(legacy) == Protagonist.MALE, "legacy snapshot selects the original art")
	check(not state.choose_opening_protagonist("unknown"), "unknown variant refused")
	check(state.choose_opening_protagonist(Protagonist.FEMALE), "female opening selection written")
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(state.SAVE_PATH))
	check(Protagonist.variant(envelope.state) == Protagonist.FEMALE, "female variant stored in durable snapshot")
	var invalid := envelope.state.duplicate(true) as Dictionary
	invalid.native[Protagonist.SAVE_KEY] = true
	check(not state.validate_snapshot(invalid), "malformed variant rejected")
	state.act("c1_start_alarm")
	check(not state.choose_opening_protagonist(Protagonist.MALE), "started story retains its selected protagonist")
	check(state.load_game() and Protagonist.variant(state.d) == Protagonist.FEMALE, "local save reload retains female protagonist")
	var portable: Dictionary = state.capture_cloud_bundle()
	check(portable.get("ok", false), "portable save accepts protagonist field")
	if portable.get("ok", false):
		var decoded: Dictionary = state.prepare_cloud_bundle(portable.bundle, portable.images)
		check(decoded.get("ok", false) and Protagonist.variant(decoded.get("state", {})) == Protagonist.FEMALE, "portable save round trip retains protagonist")

	var female := WalkArt.shared(Protagonist.FEMALE)
	var male := WalkArt.shared()
	check(female.ensure_loaded() and male.ensure_loaded() and female != male, "both animation caches load independently")
	for direction in ["up", "down", "side", "left"]:
		var female_pose: Dictionary = female.actor(direction,true,440,true)
		var original_pose: Dictionary = male.actor(direction,true,440,true)
		check(not female_pose.is_empty() and female_pose.texture != original_pose.texture, "female walk art for " + direction)
		if not female_pose.is_empty(): check(female_pose.motion_frame == 4 and female_pose.frame_count == 8, "walk clock preserved for " + direction)
	var library := LibraryArt.new()
	var female_seated: Texture2D = library.seated_for(Protagonist.FEMALE)
	var male_seated: Texture2D = library.seated_for(Protagonist.MALE)
	check(female_seated != null and male_seated != null and female_seated != male_seated, "variant-specific library sitting pose")
	var snapshot: Dictionary = state.d.duplicate(true)
	snapshot.actOne.phase = "movement_required"
	snapshot.actOne.inventoryRecovered = true
	var chapter := Chapter.new()
	var inspect := chapter.dispatch(snapshot, "c2_inspect_character")
	check(str(inspect.get("message","")).contains("她听不见"), "inspect text refers to female player")
	var verified := chapter.dispatch(snapshot, "c2_identify", {"name":"林星宇","student_id":"3250100755"})
	check(snapshot.actOne.identityVerified and str(verified.get("message","")).contains("她现在"), "same identity puzzle with matching pronoun")
	snapshot.items.campusCard = true
	var phone := PhonePages.new()
	var card: Control = phone.build("campus_card", {}, snapshot)
	var portrait := card.find_child("CampusCardPortrait", true, false) as TextureRect
	check(portrait != null and portrait.texture != null and portrait.texture.resource_path == Protagonist.FEMALE_ROOT + "portrait.png", "campus card displays the selected portrait")
	card.free()
	var director := Director.new()
	root.add_child(director)
	director.setup(func() -> Dictionary: return snapshot)
	director.cue("act2_character_cannot_hear")
	await process_frame
	await process_frame
	await process_frame
	check(str(director.last_subtitle.get("text","")).contains("她听不见"), "subtitle uses the same protagonist wording")
	check(Protagonist.subtitle(Protagonist.FEMALE, "narrator", "跟着他走") == "跟着他走", "male NPC and narrator wording preserved")
	await director.shutdown()
	director.queue_free()
	print("PROTAGONIST_VARIANT checks=", checks, " errors=", failures)
	quit(0 if failures == 0 else 1)
