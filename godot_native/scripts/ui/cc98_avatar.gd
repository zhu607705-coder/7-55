extends RefCounted
## Small forum avatars drawn on a shared pixel grid.
const NAMED_DEFAULTS := ["notebook", "route", "cup", "sprout"]
const FEATURED_AUTHORS := {"想把今天过完": "notebook", "绕一圈再回来": "route"}
const PIXELS := {
	"anonymous": [
		"...#####..", "..##+++##.", ".##+++++##", ".#++###++#", ".#+#o.o#+#",
		".#+#...#+#", "..##+++##.", "...#####..", "..##+++##.", ".##+++++##",
	],
	"warrior": [
		"...####...", "..#++++#..", ".#++o+++#.", "##oooooo##", ".#......#.",
		".#.#..#.#.", ".#......#.", "..#....#..", "...####...", "..##++##..",
	],
	"blonde": [
		"...####...", "..#oooo#..", ".#oooooo#.", ".#oo...o#.", ".#o.#.#o#.",
		".#o....o#.", ".#o#..#o#.", "..######..", "..##++##..", ".##++++##.",
	],
	"printer": [
		"...####...", "..#....#..", "..#..o.#..", ".########.", "##++++++##",
		"#++o+++++#", "##++++++##", "..######..", "..#....#..", "..######..",
	],
	"coin": [
		"...####...", "..#oooo#..", ".#oooooo#.", "#ooo##ooo#", "#oo#..#oo#",
		"#oo#..#oo#", "#ooo##ooo#", ".#oooooo#.", "..#oooo#..", "...####...",
	],
	"wind": [
		"..........", ".....###..", "....#...#.", ".####...#.", "........#.",
		"..######..", "..........", ".#####....", ".....##...", "..........",
	],
	"cyclist": [
		".....###..", ".....#o#..", "......##..", "....##....", "...##.##..",
		".###..####", "##.#####.#", "#..#..#..#", "####..####", "..........",
	],
	"socket": [
		"..######..", ".##....##.", ".#......#.", ".#.#..#.#.", ".#.#..#.#.",
		".#......#.", ".#..##..#.", ".#......#.", ".##....##.", "..######..",
	],
	"auditor": [
		"...#####..", "..##+++##.", ".##+++++##", ".#########", ".#......#.",
		".#.####.#.", ".#.#..#.#.", ".#......#.", "..#....#..", "...####...",
	],
	"notebook": [
		"..#...#...", ".########.", ".#o###o.#.", ".#......#.", ".#.##...#.",
		".#..##..#.", ".#...##.#.", ".#..##..#.", ".#......#.", ".########.",
	],
	"route": [
		"..........", "..###..##.", ".#...##oo#", ".#.....##.", "..####....",
		"......##..", ".##....#..", "#oo#...#..", ".#######..", "..........",
	],
	"cup": [
		"....#.....", "...#..#...", "....#.....", ".######...", ".#oooo###.",
		".#oooo#.#.", ".#oooo###.", ".######...", "..####....", ".######...",
	],
	"sprout": [
		".....####.", "....##oo#.", "...###o#..", ".###.###..", "#oo###....",
		".###.#....", "....#.....", "..######..", "..#++++#..", "...####...",
	],
}
# Tile, outline, light and accent.
const COLORS := {
	"anonymous": ["dce6ef", "496484", "f8fbfc", "7999bc"],
	"warrior": ["f0d6bf", "653b2b", "faeedb", "e3a744"],
	"blonde": ["cce9ed", "275672", "fff3dc", "dfac50"],
	"printer": ["cedde9", "294762", "fbf6e8", "d5765b"],
	"coin": ["f7e7c4", "825218", "fff4d0", "e9b64b"],
	"wind": ["d5e9ef", "2e687c", "f8faf3", "75b4c8"],
	"cyclist": ["efdfc6", "754831", "fff6db", "df9c4e"],
	"socket": ["d9ead6", "3b624c", "f8fbec", "89b78b"],
	"auditor": ["eadbe6", "654059", "fbf0e7", "ab7293"],
	"notebook": ["d5e6ec", "24546f", "fcf7e8", "d69b56"],
	"route": ["d9e8db", "356254", "f4f8ec", "d39351"],
	"cup": ["f2e1d1", "754c40", "fcf3e8", "c98a65"],
	"sprout": ["dde9d3", "365f49", "faf6e9", "81a75e"],
}

static var textures: Dictionary[String, Texture2D] = {}

static func attach(parent: Control, post: Dictionary, rect: Rect2) -> void:
	var motif := _motif(post)
	if not textures.has(motif):
		textures[motif] = _draw_motif(motif)
	var avatar := TextureRect.new()
	avatar.name = "Cc98PostAvatar"
	avatar.set_meta("avatar_motif", motif)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	avatar.texture = textures[motif]
	avatar.position = rect.position
	avatar.size = rect.size
	parent.add_child(avatar)

static func _motif(post: Dictionary) -> String:
	var author := str(post.get("author", "")).strip_edges()
	if author.is_empty() or author == "匿名用户": return "anonymous"
	var preset := str(post.get("avatar", "anonymous"))
	if preset != "anonymous" and PIXELS.has(preset): return preset
	if FEATURED_AUTHORS.has(author): return FEATURED_AUTHORS[author]
	return NAMED_DEFAULTS[author.hash() % NAMED_DEFAULTS.size()]

static func _draw_motif(motif: String) -> ImageTexture:
	var colors: Array = COLORS[motif]
	var background := Color(colors[0])
	var ink := Color(colors[1])
	var paper := Color(colors[2])
	var accent := Color(colors[3])
	var edge := background.lerp(ink, .26)
	var image := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	# One-pixel edge and stepped corners retain the phone's pixel-art vocabulary.
	image.fill_rect(Rect2i(2, 0, 12, 16), edge)
	image.fill_rect(Rect2i(0, 2, 16, 12), edge)
	image.fill_rect(Rect2i(2, 1, 12, 14), background)
	image.fill_rect(Rect2i(1, 2, 14, 12), background)
	var paint := {"#": ink, "+": paper, "o": accent}
	var rows: Array = PIXELS[motif]
	for y: int in range(rows.size()):
		var row: String = rows[y]
		for x: int in range(row.length()):
			var pixel := row.substr(x, 1)
			if paint.has(pixel):
				image.set_pixel(x + 3, y + 3, paint[pixel])
	return ImageTexture.create_from_image(image)
