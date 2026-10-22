extends RefCounted
## A local clipboard affordance for the already visible, authored CC98 clue.
## No controller intents, story writes, search drafts, or pending navigation.
const SOURCE_PATH = "res://data/source/library-finals.content.json"
const SOURCE_FLOOR = 12

func title_for_reply(state: Dictionary, row: Dictionary) -> String:
	if not state.get("ui",{}).get("libraryFinalsPuzzle",{}).get("investigationOpened",false): return ""
	if int(str(row.get("title","")).get_slice(" ",0))!=SOURCE_FLOOR: return ""
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SOURCE_PATH))
	for reply: Dictionary in source.cc98.storyReplies:
		if int(reply.floor)!=SOURCE_FLOOR: continue
		if int(str(row.get("title","")).get_slice(" ",0))!=int(reply.floor): return ""
		var text=str(reply.text)
		if not str(row.get("body","")).contains(text): return ""
		var start=text.find("搜‘")
		if start<0: return ""
		start+=2
		var end=text.find("’",start)
		return text.substr(start,end-start) if end>start else ""
	return ""

func copy_reply_title(state: Dictionary, row: Dictionary) -> String:
	var title=title_for_reply(state,row)
	if title.is_empty(): return "请先阅读调查帖中的题名线索。"
	if not _clipboard_supported(): return "当前设备无法复制，请手动输入题名。"
	_write_clipboard(title)
	# clipboard_set has no result. Read back to avoid claiming a failed write worked.
	if _read_clipboard()!=title: return "复制未完成，请重试或手动输入题名。"
	return "已复制题名，可在馆藏检索中粘贴。"

func _clipboard_supported() -> bool:
	return DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD)

func _write_clipboard(text: String) -> void:
	DisplayServer.clipboard_set(text)

func _read_clipboard() -> String:
	return DisplayServer.clipboard_get()
