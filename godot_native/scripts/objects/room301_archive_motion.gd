extends RefCounted
## Anchor 50: source drawer motion, bounded to one original modal lifetime.
const FACT := "a3_archive_film_retrieved"
const Art=preload("res://scripts/objects/room301_archive_art.gd")
const ART := "res://assets/rpg/interiors/finale/chapter4-755/props/chapter4_a3_archive_film_v01.png"
const CENTER := Vector2(290,350)
const EXTENT := Vector2(96,82)
const FILM := Rect2(53,30,18,17)
var stage := "idle"
var elapsed_ms := 1000.0
var reduced := false
var serial := 0
var context_key := ""
var state_owner: Dictionary = {}
func _key(state: Dictionary) -> String:
	var c: Dictionary=state.get("chapter4",{})
	return str([state.get("native",{}).get("scene",""),c.get("floor",""),c.get("phase",""),c.get("mode",""),c.get("timeState","")])

func valid_context(state: Dictionary) -> bool:
	var c: Dictionary=state.get("chapter4",{})
	return state.get("native",{}).get("scene","")=="duan_yongping_temporal_maze" and c.get("floor","")=="A3" and c.get("phase","")=="room204_restore"
func matches(state: Dictionary) -> bool:
	return valid_context(state) and is_same(state,state_owner) and _key(state)==context_key

func open(state: Dictionary) -> void:
	serial+=1
	state_owner=state
	context_key=_key(state)
	reduced=bool(state.get("native",{}).get("settings",{}).get("reduced_motion",false))
	stage="opening" if valid_context(state) and FACT not in state.get("chapter4",{}).get("factIds",[]) else "idle"
	elapsed_ms=0

func close(fresh: bool, state: Dictionary) -> void:
	if not matches(state): cancel(); return
	var already: bool=FACT in state.get("chapter4",{}).get("factIds",[])
	stage="handoff" if fresh and already else ("idle" if already else "closing")
	elapsed_ms=0
	if reduced: stage="idle"

func cancel() -> void:
	stage="idle"; elapsed_ms=1000

func tick(delta: float, state: Dictionary) -> void:
	if not matches(state): cancel(); return
	elapsed_ms+=clampf(delta,0,.06)*1000.0
	if (stage=="handoff" and elapsed_ms>=1000) or (stage=="closing" and elapsed_ms>=180): stage="idle"

func sample() -> Dictionary:
	var pull:=0.0
	var lift:=Vector2.ZERO
	var alpha:=0.0
	if not reduced:
		if stage=="opening": pull=5.0*smoothstep(0,220,elapsed_ms)
		elif stage=="closing": pull=5.0*(1-smoothstep(0,180,elapsed_ms))
		elif stage=="handoff":
			pull=5.0*(1-smoothstep(480,1000,elapsed_ms))
			lift=Vector2(14*smoothstep(480,760,elapsed_ms),-10*smoothstep(0,480,elapsed_ms)-10*smoothstep(480,760,elapsed_ms))
			alpha=1.0-smoothstep(480,760,elapsed_ms)
	return {"pull":pull,"film_offset":lift,"film_alpha":alpha,"stage":stage}

func draw(owner: RefCounted, canvas: CanvasItem, context: Dictionary, state: Dictionary, front: bool) -> void:
	if not valid_context(state) or (CENTER.y+EXTENT.y/2>Vector2(context.get("player",Vector2.ZERO)).y)!=front: return
	var pose:=sample()
	var origin: Vector2=CENTER-EXTENT/2
	owner._world(canvas,context)
	var film_alpha:float=pose.film_alpha if stage=="handoff" else (0.0 if FACT in state.get("chapter4",{}).get("factIds",[]) else 1.0)
	Art.render(canvas,Rect2(origin,EXTENT),pose.pull,film_alpha,pose.film_offset)
	canvas.draw_set_transform(Vector2.ZERO)
