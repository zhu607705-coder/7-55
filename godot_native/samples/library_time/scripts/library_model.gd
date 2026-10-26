extends RefCounted
## Local inference state only. The two historical snapshots never receive this object.
const Owners = preload("res://kit/pointer_owners.gd")
const TARGET_BOOK := 4 # ring above two bars; every half alone matches decoys.
const OBSERVE_SECONDS := 0.60
const PULL_PIXELS := 72.0
var input := Owners.new()
var moved := [false,false]
var travel := [Vector2.ZERO,Vector2.ZERO]
var observed := [false,false]
var dwell := [0.0,0.0]
var pull := 0.0
var selected_book := -1
var completed := false
var completion_count := 0
var rejected_count := 0
var suspended := false

func start(id: int, target: String) -> bool:
	if suspended or completed: return false
	if target not in ["history0","history1"] and not target.begins_with("book:"): return false
	if target.begins_with("book:"):
		var book := int(target.substr(5))
		if book<0 or book>5 or selected_book!=-1: return false
		if not input.start(id,target): return false
		selected_book=book; pull=0
		return true
	return input.start(id,target)

func drag(id: int, delta: Vector2) -> void:
	if suspended or completed or not input.owners.has(id) or not delta.is_finite(): return
	var target: String=input.owners[id]
	if target.begins_with("history"):
		var index := int(target.right(1))
		travel[index]+=delta
		if travel[index].length()>=6.0: moved[index]=true
	else:
		pull=clampf(pull+delta.y/PULL_PIXELS,0.0,1.0)

func release(id: int, visible: bool=true) -> bool:
	if not input.owners.has(id): return false
	var target: String=input.owners[id]; input.release(id)
	var accepted := false
	if target.begins_with("book:"):
		accepted=not suspended and not completed and visible and selected_book==TARGET_BOOK and pull>=0.75 and observed[0] and observed[1]
		if accepted: completed=true; completion_count+=1; input.clear()
		elif pull>0.12: rejected_count+=1
		selected_book=-1; pull=0
	return accepted

func observe(delta: float, visible: Array) -> void:
	if suspended or completed: return
	if not is_finite(delta) or delta<=0 or delta>0.25:
		dwell=[0.0,0.0]; return
	for index: int in range(2):
		if moved[index] and visible[index]:
			dwell[index]+=delta
			if dwell[index]>=OBSERVE_SECONDS: observed[index]=true
		else: dwell[index]=0.0

func suspend() -> void:
	input.clear(); selected_book=-1; pull=0; dwell=[0.0,0.0]; suspended=true

func resume() -> void:
	input.clear(); selected_book=-1; pull=0; dwell=[0.0,0.0]; suspended=false

func reset() -> void:
	resume(); moved=[false,false]; travel=[Vector2.ZERO,Vector2.ZERO]; observed=[false,false]; completed=false; completion_count=0; rejected_count=0
