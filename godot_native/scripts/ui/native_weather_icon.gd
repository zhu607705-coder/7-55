extends Control
## Weather glyphs on the same small square grid as the phone's pixel artwork.
const SKY := Color("bddbe2")
const EDGE := Color("3d7284")
const BLUE := Color("4f899a")
const CLOUD := [
	"......####......",
	".....#++++#.....",
	"....#++++++#....",
	"..##++++++++#...",
	".#+++++++++++##.",
	"#++++++++++++++#",
	"#++++++++++++++#",
	".##############.",
]
const SUN := [
	".......##.......",
	".......##.......",
	"..#..........#..",
	"...#........#...",
	"......####......",
	".....#++++#.....",
	"....#++++++#....",
	"##..#++++++#..##",
	"##..#++++++#..##",
	"....#++++++#....",
	".....#++++#.....",
	"......####......",
	"...#........#...",
	"..#..........#..",
	".......##.......",
	".......##.......",
]
const DROP := ["....##....","....##....","...####...","..######..",".########.",".########.",".########.","..######..","...####..."]
const ADVICE := ["......####......","....##++++##....","..##++++++++##..",".#++++++++++++#.","..##++++++++##..","....##++++##....","..##..####..##..","....##....##....","......####......"]
var kind: String="rain"

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _pixels(rows: Array, origin: Vector2, outline: Color, fill: Color=SKY) -> void:
	for y: int in range(rows.size()):
		var row: String=rows[y]
		for x: int in range(row.length()):
			if row[x]==".": continue
			draw_rect(Rect2(origin+Vector2(x,y),Vector2.ONE),outline if row[x]=="#" else fill)

func _draw() -> void:
	var unit := minf(size.x,size.y)/16.0
	if unit<=0: return
	draw_set_transform((size-Vector2.ONE*16*unit)/2,0,Vector2.ONE*unit)
	match kind:
		"sun":
			_pixels(SUN,Vector2.ZERO,Color("b58038"),Color("f3ca72"))
		"cloud","rain":
			_pixels(CLOUD,Vector2(0,4 if kind=="cloud" else 1),EDGE)
			if kind=="rain":
				for x: int in [5,9,13]:
					draw_rect(Rect2(x,10,1,1),BLUE)
					draw_rect(Rect2(x-1,11,1,2),BLUE)
		"drop":
			_pixels(DROP,Vector2(3,3),BLUE)
		"wind":
			for segment: Rect2 in [Rect2(2,6,9,1),Rect2(10,4,2,2),Rect2(1,9,14,1),Rect2(14,7,1,2),Rect2(4,12,8,1),Rect2(11,13,2,1)]:
				draw_rect(segment,BLUE)
		"advice":
			_pixels(ADVICE,Vector2(0,3),BLUE)
	draw_set_transform(Vector2.ZERO)
