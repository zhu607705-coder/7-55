extends RefCounted
## Godot's JSON reader accepts several forms that browser JSON.parse rejects.
## Validate the JSON grammar first, then let Godot decode its values.
var text := ""
var cursor := 0
var nodes := 0

func accepts(input: String) -> bool:
	text = input
	cursor = 0
	nodes = 0
	_space()
	if not _value(0): return false
	_space()
	return cursor == text.length()

func _space() -> void:
	while cursor < text.length() and text.unicode_at(cursor) in [9,10,13,32]: cursor += 1

func _take(token: String) -> bool:
	if text.substr(cursor,token.length()) != token: return false
	cursor += token.length()
	return true

func _value(depth: int) -> bool:
	nodes += 1
	if depth > 24 or nodes > 200000 or cursor >= text.length(): return false
	var token := text.substr(cursor,1)
	if token == "\"": return _string()
	if token == "t": return _take("true")
	if token == "f": return _take("false")
	if token == "n": return _take("null")
	if token == "{":
		cursor += 1
		_space()
		if _take("}"): return true
		while true:
			if not _string(): return false
			_space()
			if not _take(":"): return false
			_space()
			if not _value(depth+1): return false
			_space()
			if _take("}"): return true
			if not _take(","): return false
			_space()
	if token == "[":
		cursor += 1
		_space()
		if _take("]"): return true
		while true:
			if not _value(depth+1): return false
			_space()
			if _take("]"): return true
			if not _take(","): return false
			_space()
	return _number()

func _string() -> bool:
	if not _take("\""): return false
	while cursor < text.length():
		var code := text.unicode_at(cursor)
		cursor += 1
		if code == 34: return true
		if code < 32: return false
		if code != 92: continue
		if cursor >= text.length(): return false
		var escape := text.substr(cursor,1)
		cursor += 1
		if escape in ["\"","\\","/","b","f","n","r","t"]: continue
		if escape != "u" or cursor+4 > text.length(): return false
		var digits := text.substr(cursor,4)
		if digits == "0000": return false # Godot replaces NUL; reject rather than corrupt it.
		for digit in digits:
			if digit not in "0123456789abcdefABCDEF": return false
		cursor += 4
	return false

func _digit() -> bool:
	if cursor >= text.length(): return false
	var code := text.unicode_at(cursor)
	return code >= 48 and code <= 57

func _number() -> bool:
	_take("-")
	if cursor >= text.length(): return false
	if _take("0"):
		if _digit(): return false
	else:
		if not _digit(): return false
		while _digit(): cursor += 1
	if _take("."):
		if not _digit(): return false
		while _digit(): cursor += 1
	if _take("e") or _take("E"):
		if not _take("+"): _take("-")
		if not _digit(): return false
		while _digit(): cursor += 1
	return true
