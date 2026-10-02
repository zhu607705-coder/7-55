extends RefCounted
## Shared native chapter-3 helpers. All progression lives in the original source dictionaries.
var cache: Dictionary = {}

func content(file: String) -> Dictionary:
	if not cache.has(file):
		var path: String = "res://data/source/" + file + ".json"
		cache[file] = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	return cache[file]

func source_value(file: String, path: String) -> Variant:
	var current: Variant = content(file)
	for part: String in path.split("."):
		if not current is Dictionary or not current.has(part): return ""
		current = current[part]
	return current

func prose(file: String, path: String) -> String:
	return words(source_value(file,path))

func source_lines(file: String, path: String) -> Array:
	var value: Variant=source_value(file,path)
	return value.duplicate(true) if value is Array else [str(value)]

func words(value: Variant) -> String:
	if value is Array:
		var lines: PackedStringArray = []
		for entry: Variant in value: lines.append(words(entry))
		return "\n".join(lines)
	return str(value)

func response(message: String = "") -> Dictionary:
	return {"handled": true, "message": message}

func locked(message: String = "这里暂时没有要处理的事。") -> Dictionary:
	return response(message)

func command(id: String, label: String) -> Dictionary:
	return {"id": id, "label": label}

func field(id: String, label: String, options: Array = []) -> Dictionary:
	var result: Dictionary = {"id": id, "label": label, "input": "text"}
	if not options.is_empty():
		result.input = "choice"
		result.options = options
	return result

func option(id: String, label: String) -> Dictionary:
	return {"id": id, "label": label}

func parse_order(value: Variant) -> Array:
	if value is Array: return value.duplicate()
	var list: Array = []
	for part: String in str(value).replace("，", ",").replace("→", ",").replace(" ", ",").split(",", false):
		list.append(part.strip_edges())
	return list

func own(s: Dictionary, item: String) -> bool:
	return bool(s.get("items", {}).get(item, false))

func consume(s: Dictionary, item: String) -> void:
	s.items[item] = false
	if s.get("ui", {}).get("selectedItem") == item: s.ui.selectedItem = null
	if s.get("native", {}).get("selected_item") == item: s.native.selected_item = ""

func unique(list: Array, value: Variant) -> void:
	if not list.has(value): list.append(value)

func enter(s: Dictionary, scene: String, page: String, checkpoint: String = "") -> Dictionary:
	s.native.scene = scene
	s.native.page = page
	s.rpgScene = scene
	s.runtimeMode = "rpg"
	if not checkpoint.is_empty(): s.rpgCheckpoint = checkpoint
	return {"handled": true, "message": "", "scene": scene, "page": page}

func mode(s: Dictionary, key: String) -> String:
	return str(s.native.get("mode", s[key].get("mode", "light")))

func target(id: String, label: String, position: Array, action: String, radius: float = 90.0, item: String = "", required_mode: String = "") -> Dictionary:
	var result: Dictionary = {"id":id,"label":label,"position":position,"action":action,"radius":radius}
	if not item.is_empty(): result.item = item
	if not required_mode.is_empty(): result.mode = required_mode
	return result

func near(s: Dictionary, scene: String, point: Array, radius: float = 120.0) -> bool:
	if s.native.get("scene", "") != scene: return false
	var player: Variant = s.native.get("player", {})
	if player is Dictionary and player.has(scene): player = player[scene]
	if player is Array and player.size() >= 2: return Vector2(float(player[0]),float(player[1])).distance_to(Vector2(float(point[0]),float(point[1]))) <= radius
	if player is Dictionary and player.has("x") and player.has("y"):
		return Vector2(float(player.x),float(player.y)).distance_to(Vector2(float(point[0]),float(point[1]))) <= radius
	return false

func world(scene: String) -> Dictionary:
	if not cache.has("worlds"):
		cache.worlds = JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json"))
	return cache.worlds.worlds.get(scene,{})

func source_targets(scene: String) -> Array:
	return world(scene).get("interactionTargets",[])

func from_source(source: Dictionary, action: String, item: String = "") -> Dictionary:
	var position: Array = [source.x, source.y]
	var radius: float = float(source.get("proximity",80))
	# Keep full visible surfaces. Shared renderer can use exact bounds; conservative
	# circle includes reachable stand until it supports rectangle-edge distance.
	var result: Dictionary = target(str(source.id),str(source.label),position,action,radius,item)
	if source.get("stand") is Dictionary:
		var dx: float = maxf(0,absf(float(source.stand.x)-float(source.x))-float(source.get("width",0))/2)
		var dy: float = maxf(0,absf(float(source.stand.y)-float(source.y))-float(source.get("height",0))/2)
		result.radius = maxf(radius,Vector2(dx,dy).length()+4)
	if source.has("width") and source.has("height"):
		result.bounds = [float(source.x)-float(source.width)/2,float(source.y)-float(source.height)/2,float(source.width),float(source.height)]
	for key: String in ["width","height","dropWidth","dropHeight","stand"]:
		if source.has(key): result[key] = source[key]
	return result

func near_source(s: Dictionary, scene: String, source: Dictionary) -> bool:
	if s.native.get("scene", "") != scene: return false
	var player: Variant = s.native.get("player", {})
	if player is Dictionary and player.has(scene): player = player[scene]
	var p: Vector2 = Vector2.ZERO
	if player is Array and player.size() >= 2: p = Vector2(player[0],player[1])
	elif player is Dictionary and player.has("x") and player.has("y"): p=Vector2(player.x,player.y)
	else: return false
	var dx: float = maxf(0,absf(p.x-float(source.x))-float(source.get("width",0))/2)
	var dy: float = maxf(0,absf(p.y-float(source.y))-float(source.get("height",0))/2)
	var proximity: float = float(source.get("proximity",80))
	if source.get("stand") is Dictionary:
		if p.distance_to(Vector2(float(source.stand.x),float(source.stand.y))) <= proximity: return true
	return Vector2(dx,dy).length() <= proximity
