extends RefCounted
## Presentation identity belongs to the story save. The puzzle identity is shared.
const MALE := "male"
const FEMALE := "female"
const SAVE_KEY := "protagonist_variant"
const FEMALE_ROOT := "res://assets/native/protagonist_female/"
const VARIANTS := [MALE, FEMALE]
const CHARACTER_SUBTITLES := ["act2_character_cannot_hear", "act2_character_named"]

static func variant(state: Dictionary) -> String:
	return FEMALE if state.get("native", {}).get(SAVE_KEY) == FEMALE else MALE

static func portrait_path(state: Dictionary, original: String) -> String:
	return FEMALE_ROOT + "portrait.png" if variant(state) == FEMALE else original

static func character_line(state: Dictionary, text: String) -> String:
	# Only existing lines whose third person subject is the on-screen protagonist
	# call this helper. Dialogue referring to the narrator or NPCs keeps its text.
	return text.replace("他", "她") if variant(state) == FEMALE else text

static func subtitle(active_variant: String, key: String, text: String) -> String:
	return text.replace("他", "她") if active_variant == FEMALE and key in CHARACTER_SUBTITLES else text
