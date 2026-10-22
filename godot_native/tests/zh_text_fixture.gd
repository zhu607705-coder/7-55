extends RefCounted
## Test-only projection. Keep source roles, order, gameplay and voiced clocks.
## Explicitly revised unvoiced lines receive the approved minimum reading time.

static func reading_ms(text: String) -> int:
	var visible: int = 0
	for character: String in text:
		if not character.strip_edges().is_empty(): visible += 1
	return clampi(1600 + 120 * visible, 2400, 6500)

static func revisions() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/zh_text_revisions.json")).revisions

static func same_path(first: Array, second: Array) -> bool:
	if first.size() != second.size(): return false
	for index in range(first.size()):
		if (first[index] is float or first[index] is int) and (second[index] is float or second[index] is int):
			if int(first[index]) != int(second[index]): return false
		elif first[index] != second[index]: return false
	return true

static func text_at(entries: Array, source_file: String, path: Array, original: String) -> String:
	for entry: Dictionary in entries:
		if entry.sourceFile == source_file and same_path(entry.path, path):
			assert(entry.oldText == original, "Display fixture does not match the immutable original text")
			return str(entry.newText)
	return original

static func library(original: Dictionary) -> Dictionary:
	var result: Dictionary = original.duplicate(true)
	var entries: Array = revisions()
	for id: String in result.sequences:
		for index in range(result.sequences[id].size()):
			result.sequences[id][index].text = text_at(entries, "library-finals.content.json", ["storyDialogues",id,index,"text"], result.sequences[id][index].text)
			result.sequences[id][index].durationMs = float(maxi(int(original.sequences[id][index].durationMs), reading_ms(result.sequences[id][index].text)))
	return result

static func chapter3(original: Dictionary) -> Dictionary:
	var result: Dictionary = original.duplicate(true)
	var entries: Array = revisions()
	# Each source queue's actual array owner, rather than a global string replace.
	var arrays: Dictionary = {
		"canteen_tray_intro":["chapter3-canteen.content.json",["tray","introDialogue"],0],
		"canteen_queue":["chapter3-canteen.content.json",["drinks","queueDialogue"],0],
		"canteen_bad_drink":["chapter3-canteen.content.json",["drinks","badDrinkConsumed"],0],
		"canteen_queue_shift":["chapter3-canteen.content.json",["drinks","queueShiftDialogue"],0],
		"canteen_order_correct":["chapter3-canteen.content.json",["menu","correct"],0],
		"canteen_order_wrong":["chapter3-canteen.content.json",["menu","wrongGeneric"],0],
		"canteen_escape":["chapter3-canteen.content.json",["blocking","escapeDialogue"],0],
		"theater_entry":["chapter3-theater.content.json",["entryDialogue"],0],
		"theater_combined":["chapter3-theater.content.json",["ticket","combinedDialogue"],0],
		"theater_admission":["chapter3-theater.content.json",["ticket","admissionDialogue"],0],
		"theater_wrong_order":["chapter3-theater.content.json",["program","wrongDialogue"],0],
		"theater_reversal_before":["chapter3-theater.content.json",["spotlight","endingDialogue"],0],
		"theater_reversal_after":["chapter3-theater.content.json",["spotlight","endingDialogue"],2]
	}
	for id: String in arrays:
		for index in range(result.groups[id].lines.size()):
			var address: Array = arrays[id][1].duplicate()
			address.append(index + int(arrays[id][2]))
			result.groups[id].lines[index].text = text_at(entries, arrays[id][0], address, result.groups[id].lines[index].text)
	var mixed: Dictionary = {
		"canteen_tray_complete":["chapter3-canteen.content.json",[["tray","correctReturn"]]],
		"canteen_tray_done":["chapter3-canteen.content.json",[["tray","afterCompletion"]]],
		"canteen_tray_return":["chapter3-canteen.content.json",[["tray","correctReturn"]]],
		"canteen_pickup_clue":["chapter3-canteen.content.json",[["pickup","darkClueRead"]]],
		"theater_printed":["chapter3-theater.content.json",[["ticket","ticketPrinted"]]],
		"theater_prop_ghost":["chapter3-theater.content.json",[["prop","ghost"],["prop","managerHint"]]],
		"theater_console":["chapter3-theater.content.json",[["program","consolePrompt"],["program","consoleState"]]],
		"qizhen_approach":["chapter3-qizhen-lake.content.json",[["locationSearch","approachTransition","visualBeats",0],["locationSearch","dialogue",0],["locationSearch","approachTransition","visualBeats",1],["locationSearch","dialogue",1],["locationSearch","approachTransition","visualBeats",2],["locationSearch","dialogue",2],["locationSearch","dialogue",3]]]
	}
	for index in range(1, result.groups.canteen_tray_complete.lines.size()):
		mixed.canteen_tray_complete[1].append(["tray","completionDialogue",index - 1])
	for id: String in mixed:
		assert(mixed[id][1].size() == result.groups[id].lines.size(), "Display projection keeps the original source queue length")
		for index in range(result.groups[id].lines.size()):
			result.groups[id].lines[index].text = text_at(entries, mixed[id][0], mixed[id][1][index], result.groups[id].lines[index].text)
	return result

static func opening(original: Dictionary) -> Dictionary:
	var result: Dictionary = original.duplicate(true)
	for revision: Dictionary in revisions():
		if revision.sourceFile != "library-finals.content.json" or revision.path.size() != 4 or revision.path[0] != "library" or revision.path[1] != "dialogue022" or revision.path[3] != "text" or revision.oldText == revision.newText:
			continue
		for mode: String in ["normal", "reduced"]:
			for beat: Dictionary in result[mode]:
				if beat.lineIndex != null and int(beat.lineIndex) == int(revision.path[2]):
					beat.durationMs = float(maxi(int(beat.durationMs), reading_ms(revision.newText)))
	return result
