extends RefCounted
## Local retrieval state only. Historical windows never grant eligibility.
const Owners = preload("res://kit/pointer_owners.gd")
const TARGET_BOOK := 4 # ring above two bars; every half alone matches decoys.
const KEYBOARD_OWNER := -2
const PULL_PIXELS := 72.0
var input := Owners.new()
var pull := 0.0
var selected_book := -1
var completed := false
var completion_count := 0
var rejected_count := 0
var suspended := false

func start(id: int, target: String) -> bool:
	if suspended or completed: return false
	if target not in ["history0","history1","book:0","book:1","book:2","book:3","book:4","book:5"]: return false
	if target.begins_with("book:"):
		var book := int(target.substr(5))
		if book<0 or book>5 or selected_book!=-1: return false
		if not _claim(id,target): return false
		selected_book=book; pull=0
		return true
	return _claim(id,target)

func _claim(id: int, target: String) -> bool:
	# Keep this sample's keyboard identity out of the shared pointer-only kit.
	if id==KEYBOARD_OWNER:
		if input.owners.has(id) or input.has_owner(target): return false
		input.owners[id]=target
		return true
	return input.start(id,target)

func drag(id: int, delta: Vector2) -> void:
	if suspended or completed or not input.owners.has(id) or not delta.is_finite(): return
	var target: String=input.owners[id]
	# The view moves history rectangles. Dragging them changes no puzzle facts.
	if target.begins_with("book:"):
		pull=clampf(pull+delta.y/PULL_PIXELS,0.0,1.0)

func release(id: int, visible: bool=true) -> bool:
	if not input.owners.has(id): return false
	var target: String=input.owners[id]; input.release(id)
	var accepted := false
	if target.begins_with("book:"):
		accepted=not suspended and not completed and visible and selected_book==TARGET_BOOK and pull>=0.75
		if accepted: completed=true; completion_count+=1; input.clear()
		elif pull>0.12: rejected_count+=1
		selected_book=-1; pull=0
	return accepted

func cancel(id: int) -> void:
	if not input.owners.has(id): return
	var target: String=input.owners[id]; input.release(id)
	if target.begins_with("book:"):
		selected_book=-1; pull=0

func suspend() -> void:
	input.clear(); selected_book=-1; pull=0; suspended=true

func resume() -> void:
	input.clear(); selected_book=-1; pull=0; suspended=false

func reset() -> void:
	resume(); completed=false; completion_count=0; rejected_count=0
