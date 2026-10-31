extends RefCounted
## The sheet, physical stencil and lock share the same puzzle data.
## Each shape appears twice; only the shapes engraved above the wheels count.
const GRID := [[2, 4, 9, 6], [8, 5, 7, 2], [9, 0, 4, 3], [1, 6, 3, 8]]
const WINDOWS := {
	"triangle": [Vector2i(0, 0), Vector2i(2, 2)],
	"circle": [Vector2i(1, 0), Vector2i(1, 2)],
	"diamond": [Vector2i(3, 1), Vector2i(2, 3)],
	"square": [Vector2i(3, 0), Vector2i(0, 3)],
	"star": [Vector2i(1, 1), Vector2i(3, 2)],
}
const LOCK_SHAPES := ["triangle", "circle", "diamond"]

var clue_open := false
var stencil_placed := false
var digits: Array[int] = [0, 0, 0]
var unlocked := false
var failed_attempts := 0
var hint_index := 0

func answer() -> Array[int]:
	var result: Array[int] = []
	for shape: String in LOCK_SHAPES:
		var first: Vector2i = WINDOWS[shape][0]
		var second: Vector2i = WINDOWS[shape][1]
		result.append(int(GRID[first.y][first.x]) + int(GRID[second.y][second.x]))
	return result

static func window_shape(cell: Vector2i) -> String:
	for shape: String in WINDOWS:
		if cell in WINDOWS[shape]: return shape
	return ""

func turn(index: int, steps: int) -> bool:
	if unlocked or index < 0 or index >= digits.size() or steps == 0: return false
	digits[index] = posmod(digits[index] + steps, 10)
	return true

func try_handle() -> bool:
	if unlocked: return true
	if digits == answer():
		unlocked = true
		return true
	failed_attempts += 1
	return false

func next_hint() -> int:
	hint_index = mini(hint_index + 1, 3)
	return hint_index
