extends Control
## Source-faithful PhoneShell overlay. Mount at (3,3) inside the 430x860 frame.
## Read-only presentation: all story/state writes are parent-owned signal handlers.
signal page_requested(id: String)
signal utility_requested(id: String)
signal inspect_requested(item: Dictionary)
signal task_requested
signal item_selected(id: String)
signal items_combined(from_id: String, to_id: String)

const CONTENT_SIZE := Vector2(424,854)
const STATUS_HEIGHT := 40.0
const INVENTORY_TOP_DEFAULT := 240.0
const INVENTORY_TOP_MIN := 108.0
const INVENTORY_BOTTOM_GAP := 16.0
const INK := Color("222322")
const RED := Color("c85454")
const SAVING_GREEN := Color("2d7a52")
const PIXEL_FONT = preload("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
const ITEM_ORDER := ["headphone","waterDrop","wateredHeadphone","reverseGear","slashLine","towerKey","fertilizer","campusCard","pushTriangle","weatherWater","mentorLine","rightArrow","gamepad","occupancyNote","callNumber755","archivedLeaveRule","itemRecognitionReport","bagNonPersonProof","seat022Receipt","libraryPresenceProof","seatReleasePass","cafeteriaWages","greaseTissue","sparklingWater","lemonTea","blackCoffee","badDrink","dailySpecialSparklingWater","pickupTicket0755","canteenRealBun","canteenCluelessSoyMilk","canteenEdgeEgg","canteenUselessCongee","theaterTicketHalfA","theaterTicketHalfB","temporaryTheaterTicket","theaterProgramOpening","theaterProgramSpotlight","theaterProgramFinale","spotlightRemote","fluorescentBrush","decoyPaper","wetProgram","bridgeKeyword","reflectionKeyword","lakeKeyword","reflectionCoordinate","hairDryer","fishingRod","rustedLockerKey","nylonCord","brokenNetFrame","improvisedDipNet","sealedFeedTin","fishFeedPellets","smallCarp","swanMagnet","magneticFishingRod","attendanceRecordPaper","oldClockHourHand","clockPositioningPlate","shortPryBar","universalLubricatingOil","finalMinute"]
const RASTER_ICONS := {
	"hairDryer":"res://assets/rpg/props/items/hair_dryer_generated_v01.png",
	"theaterTicketHalfA":"res://assets/rpg/theater/generated/icons/item_theater_ticket_half_a.png",
	"theaterTicketHalfB":"res://assets/rpg/theater/generated/icons/item_theater_ticket_half_b.png",
	"temporaryTheaterTicket":"res://assets/rpg/theater/generated/icons/item_temporary_theater_ticket.png",
	"theaterProgramOpening":"res://assets/rpg/theater/generated/icons/item_theater_program_opening.png",
	"theaterProgramSpotlight":"res://assets/rpg/theater/generated/icons/item_theater_program_spotlight.png",
	"theaterProgramFinale":"res://assets/rpg/theater/generated/icons/item_theater_program_finale.png",
	"spotlightRemote":"res://assets/rpg/theater/generated/icons/item_spotlight_remote.png",
	"fluorescentBrush":"res://assets/rpg/theater/generated/icons/item_fluorescent_brush.png",
	"decoyPaper":"res://assets/rpg/theater/generated/icons/item_decoy_paper.png",
	"wetProgram":"res://assets/rpg/theater/generated/icons/item_wet_program.png"
}
# Authored rows/palettes transcribed verbatim from src/components/PixelIcon.tsx.
const PIXEL_ICONS := {"waterDrop":{"rows":["....b....","....b....","...bwb...","..bwwlb..",".bwwllb..",".bwlllb..","bwllllsb.","bwlllssb.",".bllssb..","..bbbb..."],"palette":{"b":"#1d3f8f","w":"#cfe8ff","l":"#6aa8df","s":"#4d7ed9"}},"headphone":{"rows":["k.......k","kk.....kk","gkk...kkg","ggk...kgg","ggk...kgg",".kk...kk.",".k.....k.",".kkkkkkk.","..kkkkk..","........."],"palette":{"k":"#222322","g":"#c85454"}},"wateredHeadphone":{"rows":["k.......k","kk.....kk","gkk.b.kkg","ggk.w.kgg","ggkblbkgg",".kkblbkk.",".k.blb.k.",".kkkkkkk.","..kkkkk..","........."],"palette":{"k":"#222322","g":"#c85454","b":"#1d3f8f","l":"#6aa8df","w":"#cfe8ff"}},"reverseGear":{"rows":["..g..g...",".ggggggg.","g.ggggg.g",".gg...gg.","ggg.y.ggg",".gg...gg.","g.ggggg.g",".ggggggg.","..g..g...","........."],"palette":{"g":"#777989","y":"#f5c542"}},"slashLine":{"rows":[".......ii","......ii.",".....ii..","....ii...","...ii....","..ii.....",".ii......","ii.......","i........","........."],"palette":{"i":"#31435f"}},"towerKey":{"rows":[".gg......","gyyg.....","gy.yg....","gyyg.....",".gg.i....","....ii...",".....ii..","......iii",".......ii","........."],"palette":{"g":"#777989","y":"#f5c542","i":"#31435f"}},"fertilizer":{"rows":["...pp....","..pggp...",".bbbbbb..",".buubbb..","bbubbubb.","bbbbbbbb.","bbubbubb.","bbbbbbbb.",".bbbbbb..","........."],"palette":{"b":"#a2793f","u":"#7c5a2a","p":"#61b58c","g":"#4c8f66"}},"campusCard":{"rows":["bbbbbbbbb","bwwwwwwwb","bwpppwwwb","bwpppwwwb","bwwwwwwwb","bkkkkkkkb","bwkwkwkwb","bkkkkkkkb","bbbbbbbbb","........."],"palette":{"b":"#185ba8","w":"#f3f7f5","p":"#71b6a0","k":"#26313b"}},"pushTriangle":{"rows":[".........","..r......","..rr.....","..rrr....","..rrrr...","..rrr....","..rr.....","..r......",".........","........."],"palette":{"r":"#d84545"}},"weatherWater":{"rows":["....c....","...ccc...","...cwc...","..cwwwc..","..cwlwc..",".cwwllwc.",".cwwllwc.","..clllc..","...ccc...","........."],"palette":{"c":"#1d6ea3","w":"#d9f4ff","l":"#63b9dd"}},"mentorLine":{"rows":["....k....","....k....","....k....","....k....","....k....","....k....","....k....","....k....","....k....","........."],"palette":{"k":"#33425f"}},"rightArrow":{"rows":[".........",".....r...","......r..","kkkkkkkr.","kkkkkkkkr","kkkkkkkr.","......r..",".....r...",".........","........."],"palette":{"k":"#33425f","r":"#d84545"}},"gamepad":{"rows":[".........","..kkkkk..",".kgggggk.","kgggggggk","kgkkggygk","kggkggygg",".kgggggk.",".kk...kk.","k.......k","........."],"palette":{"k":"#1b2430","g":"#4774b8","y":"#f0d54e"}},"occupancyNote":{"rows":["kkkkkkkkk","kwwwwwwwk","kwwkkkwwk","kwwwwwwwk","kwwkkwwwk","kwwwwwffk","kwwwwfffk","kwwfffffk","kkkkkkkkk","........."],"palette":{"k":"#27313d","w":"#f1ead7","f":"#c7b58c"}},"callNumber755":{"rows":["bbbbbbbbb","bwwwwwwwb","bwkkwkkwb","bwwkwkwwb","bwkkwkkwb","bwwwwwwwb","bwywyywwb","bwwwwwwwb","bbbbbbbbb","........."],"palette":{"b":"#1f5ea8","w":"#f6f0dc","k":"#26313b","y":"#e5b64e"}},"archivedLeaveRule":{"rows":["..kkkk...",".kyyyyyk.","kyyrrryyk","kyyyyyyyk","kyykkkyyk","kyyyyyyyk","kyykkkyyk",".kyyyyyk.","..kkkk...","........."],"palette":{"k":"#463728","y":"#d8bd79","r":"#a64d3d"}},"itemRecognitionReport":{"rows":["..kkkk...",".kbbbbk..","kkkkkkkk.","kwwwwwwk.","kwggwwwk.","kwgwwwwk.","kwwkkwwk.","kwwwwwwk.","kkkkkkkk.","........."],"palette":{"k":"#25313b","b":"#4e79ae","w":"#f2eddd","g":"#5f9b66"}},"bagNonPersonProof":{"rows":["kkkkkkkk.","kwwwwwwk.","kwkkkkwk.","kwkyykwk.","kwkkkkwk.","kwwwrrwk.","kwwrrrwk.","kwwwrrwk.","kkkkkkkk.","........."],"palette":{"k":"#27313d","w":"#f4efdf","y":"#c98a43","r":"#b94747"}},"seat022Receipt":{"rows":[".kkkkkkk.","kwwwwwwwk","kwkkwkkwk","kwkwkwkwk","kwkkwkkwk","kwwwwwwwk","kwbbbbbwk","kwwwwwwwk",".kkkkkkk.","........."],"palette":{"k":"#26313b","w":"#f4eddb","b":"#3973b8"}},"libraryPresenceProof":{"rows":["...bbb...","..bwwwb..",".bwgggwb.",".bwgkgwb.",".bwgggwb.","..bwwwb..","...bwb...","...bwb...","..bbbbb..","........."],"palette":{"b":"#1f5ea8","w":"#f2f2e9","g":"#65a96e","k":"#25313b"}},"seatReleasePass":{"rows":["ggggggggg","gwwwwwwwg","gwkkwkwgg","gwkwkwkwg","gwkkwkwgg","gwwwwwwwg","gwywywywg","gwwwwwwwg","ggggggggg","........."],"palette":{"g":"#3d8d5d","w":"#f4f0dd","k":"#23313a","y":"#e8c45b"}},"cafeteriaWages":{"rows":["..yyyyy..",".ywwwwwy.","ywyyyyywy","ywykkkywy","ywykykywy","ywykkkywy","ywyyyyywy",".ywwwwwy.","..yyyyy..","........."],"palette":{"y":"#d89f32","w":"#f7df8b","k":"#744f20"}},"greaseTissue":{"rows":["..kkkk...",".kwwwwk..","kwwwwwwk.","kwwyywwk.","kwwyyywk.","kwwwyywk.",".kwwwwwk.","..kwwwk..","...kkk...","........."],"palette":{"k":"#c6bca5","w":"#f2ead8","y":"#9f7637"}},"sparklingWater":{"rows":["...bbb...","..bwwwb..","..bcbwb..",".bcccccb.",".bcwcwcb.",".bccbccb.",".bcwcwcb.",".bcccccb.","..bbbbb..","........."],"palette":{"b":"#1d4f79","c":"#4ab9e9","w":"#e9fbff"}},"lemonTea":{"rows":["...yyy...","..ywwwy..","..ywwwy..",".ywwwwwy.",".ywwywwy.",".ywywywy.",".ywwywwy.",".ywwwwwy.","..yyyyy..","........."],"palette":{"y":"#c99d2e","w":"#f4f2df"}},"blackCoffee":{"rows":["...ggg...","..gkkkg..","..gkkkg..",".gkkkkkg.",".gkbkbkg.",".gkkkkkg.",".gkkkkkg.",".gkkkkkg.","..ggggg..","........."],"palette":{"g":"#59636a","k":"#171b1e","b":"#7a4a2a"}},"badDrink":{"rows":["..wwwww..",".w.....w.",".w.....w.",".wmmmmmw.",".wmgmgmw.",".wmmmmmw.",".wmgmmmw.",".wmmmmmw.","..wwwww..","........."],"palette":{"w":"#bac5c5","m":"#736447","g":"#3e5548"}},"dailySpecialSparklingWater":{"rows":["y..bbb..y","..bwwwb...","..bcbwb...",".bcccccb..",".bcwcwcb.y",".bccbccb..",".bcwcwcb..",".bcccccb..","y.bbbbb...","........."],"palette":{"b":"#173f6b","c":"#39c6ef","w":"#f0fdff","y":"#f2cf59"}},"pickupTicket0755":{"rows":["kkkkkkkkk","kwwwwwwwk","kwbwbwbwk","kwbbbwwwk","kwbwbwbwk","kwwwwwwwk","kwyyyyywk","kwwwwwwwk","kkkkkkkkk","........."],"palette":{"k":"#26313b","w":"#f4eddb","b":"#3973b8","y":"#d8a64a"}},"canteenRealBun":{"rows":[".........","...kkk...","..kwwwk..",".kwwywwk.",".kwwwwwk.",".kwwwwwk.","..kkkkk..",".........",".........","........."],"palette":{"k":"#5d4028","w":"#ead6a8","y":"#f6e6bf"}},"canteenCluelessSoyMilk":{"rows":["..kkkk...",".kwwwwk..",".kwwwwk..",".kwywwk..",".kwywwk..",".kwwwwk..",".kwwwwk..","..kkkk...",".........","........."],"palette":{"k":"#39434a","w":"#f3eee0","y":"#d9b84b"}},"canteenEdgeEgg":{"rows":[".........","...kk....","..kwwk...",".kwwwwk..",".kwwywwk.",".kwwywwk.","..kwwwk..","...kkk...",".........","........."],"palette":{"k":"#6b5635","w":"#f6f0d7","y":"#e6a62f"}},"canteenUselessCongee":{"rows":[".........",".kkkkkkk.",".kwwwwwk.","..kwwwk..","..kwwwk..","..kwwwk..","...kkk...","...sss...",".........","........."],"palette":{"k":"#45606a","w":"#f0ead7","s":"#a7d8df"}},"theaterTicketHalfA":{"rows":["kkkkk....","kwwww....","kwrrr....","kwwww....","kwkkw....","kwwww....","kwyww....","kwwww....","kkkkk....","........."],"palette":{"k":"#442a2c","w":"#ead8ac","r":"#9b4048","y":"#d9a94a"}},"theaterTicketHalfB":{"rows":["....kkkkk","....wwwwk","....bbbwk","....wwwwk","....wkkwk","....wwwwk","....wwywk","....wwwwk","....kkkkk","........."],"palette":{"k":"#26384a","w":"#dce9ec","b":"#3979a8","y":"#d9a94a"}},"temporaryTheaterTicket":{"rows":["kkkkkkkkk","kwwwwwwwk","kwrrrbbwk","kwwwwwwwk","kwkkwkkwk","kwwwwwwwk","kwyyyyywk","kwwwwwwwk","kkkkkkkkk","........."],"palette":{"k":"#3a3030","w":"#efe1bd","r":"#9b4048","b":"#3979a8","y":"#d9a94a"}},"theaterProgramOpening":{"rows":["kkkkkkkkk","kwwwwwwwk","kwrrrrrwk","kwwwwwwwk","kwkkkkkwk","kwwwwwwwk","kwkkkwwwk","kwwwwwwwk","kkkkkkkkk","........."],"palette":{"k":"#533237","w":"#efe3c7","r":"#a94b52"}},"theaterProgramSpotlight":{"rows":["kkkkkkkkk","kwwywwwwk","kwwywwwwk","kwwywwwwk","kwyyywwwk","kwwywwwwk","kwkkkkkwk","kwwwwwwwk","kkkkkkkkk","........."],"palette":{"k":"#533237","w":"#efe3c7","y":"#e6bf5a"}},"theaterProgramFinale":{"rows":["kkkkkkkkk","kwrrwrrwk","kwrrrrrwk","kwwrrrwwk","kwwwrwwwk","kwwwwwwwk","kwkkkkkwk","kwwwwwwwk","kkkkkkkkk","........."],"palette":{"k":"#533237","w":"#efe3c7","r":"#a94b52"}},"spotlightRemote":{"rows":["..kkkkk..",".kgggggk.","kgyyyyggk","kgggggggk","kggbgbggk","kgggggggk",".kgggggk.","..kgggk..","...kkk...","........."],"palette":{"k":"#22272b","g":"#54636d","y":"#e5c95e","b":"#61c8e8"}},"fluorescentBrush":{"rows":[".ccccccc.",".cgggggc.","..cgggc..","...kkk...","....kk...","....kk...","....kk...","....kk...","....kk...","........."],"palette":{"c":"#4dcbe8","g":"#b7f0c7","k":"#72533a"}},"decoyPaper":{"rows":["..kkkk...",".kwwwwk..","kwwwwwwk.","kwwkkwwk.","kwwwwwwk.","kwwkkwwk.",".kwwwwwk.","..kwwwk..","...kkk...","........."],"palette":{"k":"#4b5054","w":"#e8e3d5"}},"wetProgram":{"rows":["kkkkkkkkk","kwwwwwwwk","kwbbwwwwk","kwbbbwwwk","kwkkkkkwk","kwwwwbbbk","kwkkkbbbk","kwwwwbbbk","kkkkkkkkk","........."],"palette":{"k":"#39414a","w":"#e8dfc8","b":"#5598b8"}},"bridgeKeyword":{"rows":[".........","..kkkkk..",".kgggggk.","kgkgggkgk","kkkkkkkkk","...kkk...","..kkkkk..",".kk...kk.",".........","........."],"palette":{"k":"#3f4b4d","g":"#86c6af"}},"reflectionKeyword":{"rows":[".........",".bbbbbbb.","bbwwwwwbb","bwwbbbwwb","bwbwwwbwb","bwwbbbwwb","bbwwwwwbb",".bbbbbbb.",".........","........."],"palette":{"b":"#3b83a5","w":"#bfeaf0"}},"lakeKeyword":{"rows":[".........","..ggggg..",".ggggggg.","ggbbbbbgg","gbbbbbbgg","ggbbbbbg.",".ggbbbg..","..gggg...",".........","........."],"palette":{"g":"#4f8b62","b":"#55a8c9"}},"reflectionCoordinate":{"rows":["....y....","...yyy...","..yykyy..",".yykkkyy.","yykkkkkyy",".yykkkyy.","..yykyy..","...yyy...","....y....","........."],"palette":{"y":"#d6c66e","k":"#3e5f67"}},"fishingRod":{"rows":[".......kk","......kk.",".....kk..","....kk...","...kk....","..kk.....",".kk......","kk....h..",".k...hh..",".....h..."],"palette":{"k":"#755234","h":"#52636a"}},"rustedLockerKey":{"rows":["..rrrr...",".ryyyr...","ry...yr..","ry...yr..",".ryyyr...","..rrr....","...rrr...","....rrrr.","......rrr","........."],"palette":{"r":"#9a5934","y":"#d2a350"}},"nylonCord":{"rows":["..nnnn...",".nn..nn..","nn....nn.","nn.nnnnn.","nn.nn.nn.","nn....nn.",".nn..nn..","..nnnnnn.",".....nn..","......nn."],"palette":{"n":"#d8d2bd"}},"brokenNetFrame":{"rows":[".kkkkkkk.","kk.n.n.kk","k.n.n.n.k","kn.n.n..k","k.n.n....","kn.n.n..k","k.n.n.n.k","kk.n.n.kk",".kkkkkkk.","....kk..."],"palette":{"k":"#536165","n":"#9ba7a2"}},"improvisedDipNet":{"rows":[".kkkkkkk.","kkn.n.nkk","kn.n.n.nk","k.n.n.n.k","kn.n.n.nk","kkn.n.nkk",".kkkkkkk.","....kk...","....kk...","....kk..."],"palette":{"k":"#59656a","n":"#d8d2bd"}},"sealedFeedTin":{"rows":["..kkkkk..",".kwwwwwk.",".kgggggk.",".kgpppgk.",".kgggggk.",".kgpppgk.",".kgggggk.",".kwwwwwk.","..kkkkk..","........."],"palette":{"k":"#455158","w":"#c7d1d0","g":"#748b79","p":"#d0a24b"}},"fishFeedPellets":{"rows":["...kkk...","..kgggk..",".kgggggk.",".kgpgpgk.","kgpgpgpgk","kggpgpggk","kgpgpgpgk",".kgggggk.","..kkkkk..","........."],"palette":{"k":"#5a4633","g":"#b79c69","p":"#6e4f31"}},"smallCarp":{"rows":[".........",".....o...",".o..oooo.","o.oooyyoo",".oooyyyyo","..ooyykyo",".o..oooo.",".....o...",".........","........."],"palette":{"o":"#b85b35","y":"#e3a448","k":"#26333b"}},"swanMagnet":{"rows":["rr.....bb","rr.....bb","rr.....bb","rr.....bb","rr.....bb","rr.....bb",".rr...bb.","..rrrbb..","...rbb...","........."],"palette":{"r":"#c64f4d","b":"#487db5"}},"magneticFishingRod":{"rows":[".......kk","......kk.",".....kk..","....kk...","...kk....","..kk.....",".kk......","kk....rb.",".k...rrbb",".....r..b"],"palette":{"k":"#755234","r":"#c64f4d","b":"#487db5"}},"attendanceRecordPaper":{"rows":[".kkkkkkk.",".kwwwwwk.",".kwgggwk.",".kwwwwwk.",".kwgggwk.",".kwwwwwk.",".kwg..wk.",".kwwwwwk.",".kkkkkkk.","........."],"palette":{"k":"#4b5054","w":"#e7dfcf","g":"#87928c"}},"oldClockHourHand":{"rows":["....yy...","...yyyy..","..yykyyy.",".yykkkkyy","....kk...","....kk...","....kk...","....kk...","...kkkk..","........."],"palette":{"y":"#d8b45a","k":"#515860"}},"clockPositioningPlate":{"rows":["..kkkkk..",".kkyyykk.","kkykkkykk","kyk...kyk","kyk.k.kyk","kyk...kyk","kkykkkykk",".kkyyykk.","..kkkkk..","........."],"palette":{"k":"#4b5054","y":"#ccb15b"}},"shortPryBar":{"rows":[".........",".......kk","......kk.",".....kk..","..kkkk...",".kkk.....",".kk......",".kk......",".kk......","........."],"palette":{"k":"#6d737b"}},"universalLubricatingOil":{"rows":["...kkk...","..kgggk..",".kgggggk.",".kgwwwgk.",".kgwwwgk.",".kgggggk.","..kgggk..","...k.k...","...k.k...","........."],"palette":{"k":"#4d5158","g":"#7c9b5f","w":"#d8d2bd"}},"finalMinute":{"rows":[".......y.","......yy.",".....yy..","....yy...","...yy....","..yyy....",".yky.....","ykyky....",".kyk.....","..k......"],"palette":{"k":"#4b3a24","y":"#d6a94e"}},"backpack":{"rows":["..kkkk...",".k....k..","kkkkkkkk.","kbbbbbbk.","kbbbbbbk.","kbkkkkbk.","kbbyybbk.","kbbbbbbk.","kkkkkkkk.","........."],"palette":{"k":"#222322","b":"#c8863f","y":"#f5c542"}},"music":{"rows":["....kkkk.","....k..k.","....k..k.","....k..k.","....k..k.",".kk.k.kkk","kkkk..kkk","kkkk..kkk",".kk....k.","........."],"palette":{"k":"#222322"}},"willowBranchPaddle":{"rows":["........g",".......gg","......gb.",".....gb..","....gb...","...gb....","..gb.....",".bbb.....","bbbb.....",".bb......"],"palette":{"b":"#765333","g":"#9fbe61"}},"warningSignPaddle":{"rows":["...rr....","..ryyr...",".ryyyyr..","ryyyyyyr.","rrrrrrrr.","....k....","....k....","....k....","....k....","...kkk..."],"palette":{"r":"#bb3232","y":"#f4d85d","k":"#5c6469"}},"sun":{"rows":["....y....",".y..y..y.","..yyyyy..",".yywwwyy.","yyywwwyyy",".yywwwyy.","..yyyyy..",".y..y..y.","....y....","........."],"palette":{"y":"#f5c542","w":"#fff3c2"}}}

class TrackedLabel extends Label:
	var tracking := 0.0
	var tracking_color := Color("222322")
	func _draw() -> void:
		if tracking==0: return
		var face:=get_theme_font("font")
		var pixels:=get_theme_font_size("font_size")
		var x:=0.0
		var baseline:=(size.y-face.get_height(pixels))/2.0+face.get_ascent(pixels)
		for ch in text:
			draw_string(face,Vector2(x,baseline),ch,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,tracking_color)
			x+=face.get_string_size(ch,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x+tracking

class PixelShadow extends Control:
	var target: Control
	var offset:=Vector2(2,2)
	var color:=Color(0,0,0,0.36)
	func _init() -> void: mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _process(_dt: float) -> void:
		if not is_instance_valid(target): return
		visible=target.visible
		var painted:Rect2=target.get_meta("painted_rect",Rect2(Vector2.ZERO,target.size))
		position=target.position+painted.position+offset
		size=painted.size
		scale=target.scale
		pivot_offset=target.pivot_offset
		modulate=target.modulate
		queue_redraw()
	func _draw() -> void: draw_rect(Rect2(Vector2.ZERO,size),color)

class PixelIcon extends Control:
	var pixels: Dictionary = {}
	var raster: Texture2D
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	func _draw() -> void:
		if raster:
			var factor := minf(size.x/raster.get_width(),size.y/raster.get_height())
			var fitted := raster.get_size()*factor
			draw_texture_rect(raster,Rect2((size-fitted)/2.0,fitted),false)
			return
		var rows: Array = pixels.get("rows",[])
		if rows.is_empty(): return
		var palette: Dictionary = pixels.get("palette",{})
		var factor := minf(size.x/str(rows[0]).length(),size.y/rows.size())
		var origin := (size-Vector2(str(rows[0]).length(),rows.size())*factor)/2.0
		for y in rows.size():
			for x in str(rows[y]).length():
				var color: String = palette.get(str(rows[y])[x],"")
				if color.is_empty(): continue
				# SVG crispEdges snaps both cell boundaries, preserving source pixel rhythm.
				var a := (origin+Vector2(x,y)*factor).round()
				var b := (origin+Vector2(x+1,y+1)*factor).round()
				draw_rect(Rect2(a,b-a),Color(color))

class InventorySlot extends "res://scripts/ui/inventory_item.gd":
	signal combine_requested(from_id: String, to_id: String)
	var artwork: Control
	func _make_drag_preview() -> Control:
		var ghost := Control.new()
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var copy := PixelIcon.new()
		copy.pixels = artwork.pixels
		copy.raster = artwork.raster
		copy.size = Vector2(34,34)*1.15
		copy.position = -copy.size/2.0
		ghost.add_child(copy)
		return ghost
	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.get("kind")=="inventory_item" and data.get("item") is String and str(data.item)!=item_id
	func _drop_data(at_position: Vector2, data: Variant) -> void:
		if _can_drop_data(at_position,data): combine_requested.emit(str(data.item),item_id)

class StatusIcons extends Control:
	var network := "campus_wifi"
	var percent := 100.0
	var battery_x := 0.0
	var network_x := 0.0
	var critical_phase := false
	func _init() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var ink := Color("222322")
		if network == "campus_wifi":
			# Source CSS arcs: 18x16 outer, 11x10 inner, 5x4 squared dot.
			draw_arc(Vector2(network_x+9,15),7.5,-2.36,-0.78,12,ink,3.0,false)
			draw_arc(Vector2(network_x+9,16),4.0,-2.36,-0.78,8,ink,3.0,false)
			draw_rect(Rect2(network_x+6.5,17,5,4),ink)
		elif network == "cellular":
			for i in 4: draw_rect(Rect2(network_x+i*5,21-[5,8,11,14][i],3,[5,8,11,14][i]),ink)
		# Not text or a glyph: exact 22x12 native outlined battery with 2x5 terminal.
		draw_rect(Rect2(battery_x,9,22,12),ink)
		draw_rect(Rect2(battery_x+2,11,18,8),Color("fff6df"))
		draw_rect(Rect2(battery_x+22,13,2,5),ink)
		var tone := Color("c85454") if percent<=20 else Color("2d7a52")
		if critical_phase and percent<=5: tone.a=0.35
		draw_rect(Rect2(battery_x+3,12,maxf(1.0,16.0*percent/100.0),6),tone)

class PixelGrid extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shader := Shader.new()
		shader.code = "shader_type canvas_item; render_mode blend_mul; void fragment(){ COLOR.rgb = mix(vec3(1.0),COLOR.rgb,COLOR.a); COLOR.a = 1.0; }"
		var surface := ShaderMaterial.new()
		surface.shader = shader
		material = surface
	func _draw() -> void:
		for y in range(0,int(size.y),3): draw_rect(Rect2(0,y,size.x,1),Color(34/255.0,35/255.0,34/255.0,0.045))
		for x in range(0,int(size.x),3): draw_rect(Rect2(x,0,1,size.y),Color(34/255.0,35/255.0,34/255.0,0.03))

var read_state: Callable
var state: Dictionary = {}
var status_bar: Control
var time_box: Panel
var time_label: Label
var status_right: Button
var network_label: Label
var battery_number: Label
var saving_label: Label
var five_g: Label
var status_icons: StatusIcons
var task_button: Button
var task_copy: Label
var digit_hint: Label
var inventory: Control
var inventory_handle: Button
var inventory_count: Label
var inventory_arrow: Label
var inventory_body: Panel
var inventory_scroll: ScrollContainer
var inventory_slots: VBoxContainer
var inventory_tip: Label
var brightness_veil: ColorRect
var pixel_grid: PixelGrid
var acquisition: Panel
var inventory_open := false
var _inventory_anchor_signature:Array=[]
var _inventory_anchor_context:Array=[]
var inventory_top := INVENTORY_TOP_DEFAULT
var owned: Array = []
var catalog: Dictionary = {}
var inspect_kinds: Dictionary = {}
var selected_item := ""
var recent_item := ""
var time_trusted := true
var show_task_bar := true
var input_blocked := false
var _built := false
var _seen_inventory := false
var _inventory_signature := ""
var _slot_ids: Array=[]
var inventory_gestures := preload("res://scripts/ui/inventory_gesture.gd").new()
var _bar_drag_start := 0.0
var _bar_top_start := 0.0
var _bar_dragging := false
var _bar_moved := false
var _suppress_handle_click := false
var _acquisition_started := -1.0
var _acquisition_icon: PixelIcon
var _flight_particles: Array = []
var _last_critical_phase := false
var _last_objective := ""
var _task_update_started := -1.0

func setup(reader: Callable) -> void:
	read_state=reader
	_build()
	if read_state.is_valid(): refresh(read_state.call())

func _ready() -> void:
	_build()

func _style(background: Color, border: Color=Color.TRANSPARENT, border_width: int=0, shadow_color: Color=Color.TRANSPARENT, shadow_offset: Vector2=Vector2.ZERO) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color=background
	box.border_color=border
	box.set_border_width_all(border_width)
	box.shadow_color=shadow_color
	box.shadow_size=0
	box.shadow_offset=shadow_offset
	return box

func _label(parent: Control, text: String, font_size: int, color: Color=INK) -> Label:
	var label := TrackedLabel.new()
	label.text=text
	label.add_theme_font_override("font",PIXEL_FONT)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label

func _make_icon(parent: Control, id: String, extent: float) -> PixelIcon:
	var icon := PixelIcon.new()
	icon.pixels=PIXEL_ICONS.get(id,{})
	if RASTER_ICONS.has(id): icon.raster=load(RASTER_ICONS[id])
	icon.size=Vector2.ONE*extent
	parent.add_child(icon)
	return icon

func _set_button_style(button: Button, normal: StyleBoxFlat, hover: StyleBoxFlat) -> void:
	button.add_theme_stylebox_override("normal",normal)
	button.add_theme_stylebox_override("hover",hover)
	button.add_theme_stylebox_override("pressed",hover)
	button.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,Color("f0d54e"),2))
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font",PIXEL_FONT)

func _build() -> void:
	if _built: return
	_built=true
	name="PhoneChrome"
	custom_minimum_size=CONTENT_SIZE
	size=CONTENT_SIZE
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var entries: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/items.config.json"))
	if entries is Array:
		for item in entries: catalog[str(item.id)]=item
	var kinds: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/item_catalog.json"))
	if kinds is Dictionary: inspect_kinds=kinds
	status_bar=Control.new(); status_bar.name="StatusBar"; status_bar.size=Vector2(424,40); status_bar.z_index=40; status_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(status_bar)
	time_box=Panel.new(); time_box.name="Time"; time_box.mouse_filter=Control.MOUSE_FILTER_IGNORE
	time_box.add_theme_stylebox_override("panel",_style(Color(1,246/255.0,223/255.0,0.82),INK,2,Color(119/255.0,92/255.0,49/255.0,0.25),Vector2(2,2)))
	status_bar.add_child(time_box)
	time_label=_label(time_box,"07:55",14); time_label.position=Vector2(10,4); time_label.tracking=1.0; time_label.add_theme_color_override("font_color",Color.TRANSPARENT)
	status_right=Button.new(); status_right.name="ControlCenterTrigger"; status_right.tooltip_text="打开控制中心"
	_set_button_style(status_right,_style(Color(1,246/255.0,223/255.0,0.82),INK,2,Color(119/255.0,92/255.0,49/255.0,0.25),Vector2(2,2)),_style(Color(1,246/255.0,223/255.0,0.97),INK,2))
	status_right.pressed.connect(func(): page_requested.emit("control_center")); status_bar.add_child(status_right)
	network_label=_label(status_right,"",11); network_label.tracking=0.5; network_label.add_theme_color_override("font_color",Color.TRANSPARENT)
	battery_number=_label(status_right,"",11)
	saving_label=_label(status_right,"省",9,SAVING_GREEN)
	five_g=_label(status_right,"5G",9); five_g.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	five_g.add_theme_stylebox_override("normal",_style(Color.TRANSPARENT,INK,2))
	status_icons=StatusIcons.new(); status_icons.name="NativeStatusIcons"; status_right.add_child(status_icons)
	task_button=Button.new(); task_button.name="TaskTrigger"; task_button.z_index=76
	_set_button_style(task_button,_style(Color(28/255.0,34/255.0,41/255.0,0.96),Color("f2e7c9"),2,Color(0,0,0,0.36),Vector2(2,2)),_style(Color("27394a"),Color("f0d54e"),2))
	task_button.tooltip_text="点击查看当前任务和提示"; task_button.pressed.connect(func(): task_requested.emit()); add_child(task_button)
	task_copy=_label(task_button,"任务",10,Color("fff8e4")); task_copy.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	digit_hint=_label(task_button,"",9,Color("f0d54e")); digit_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	inventory=Control.new(); inventory.name="Inventory"; inventory.position=Vector2(0,240); inventory.z_index=45; inventory.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(inventory)
	inventory_body=Panel.new(); inventory_body.name="InventoryBody"; inventory_body.mouse_default_cursor_shape=Control.CURSOR_VSIZE
	var body_style:=_style(Color(38/255.0,40/255.0,48/255.0,0.92),Color("101116"),2,Color(0,0,0,0.35),Vector2(3,4)); body_style.border_width_left=0
	inventory_body.add_theme_stylebox_override("panel",body_style); inventory_body.gui_input.connect(_on_handle_input); inventory.add_child(inventory_body)
	inventory_scroll=ScrollContainer.new(); inventory_scroll.name="InventoryScroll"; inventory_scroll.position=Vector2(8,10); inventory_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; inventory_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO; inventory_body.add_child(inventory_scroll)
	var scrollbar:=inventory_scroll.get_v_scroll_bar(); scrollbar.custom_minimum_size.x=6
	scrollbar.add_theme_stylebox_override("scroll",_style(Color(16/255.0,17/255.0,22/255.0,0.65)))
	for part in ["grabber","grabber_highlight","grabber_pressed"]: scrollbar.add_theme_stylebox_override(part,_style(Color("e8e4d8"),Color("101116"),1))
	inventory_slots=VBoxContainer.new(); inventory_slots.name="InventorySlots"; inventory_slots.add_theme_constant_override("separation",8); inventory_slots.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN; inventory_scroll.add_child(inventory_slots)
	inventory_tip=_label(inventory_body,"",11,Color("e8e4d8")); inventory_tip.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; inventory_tip.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	inventory_handle=Button.new(); inventory_handle.name="InventoryHandle"; inventory_handle.mouse_default_cursor_shape=Control.CURSOR_VSIZE
	inventory_handle.pressed.connect(_toggle_inventory); inventory_handle.gui_input.connect(_on_handle_input); inventory.add_child(inventory_handle)
	var backpack:=_make_icon(inventory_handle,"backpack",26); backpack.name="BackpackIcon"; backpack.position=Vector2(5,10)
	inventory_arrow=_label(inventory_handle,"›",15,Color("e8e4d8")); inventory_arrow.position=Vector2(5,38); inventory_arrow.size=Vector2(26,15); inventory_arrow.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	inventory_count=_label(inventory_handle,"0",9,Color.WHITE); inventory_count.name="InventoryCount"; inventory_count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	inventory_count.add_theme_stylebox_override("normal",_style(RED,Color("101116"),2))
	brightness_veil=ColorRect.new(); brightness_veil.name="BrightnessVeil"; brightness_veil.color=Color("05060c"); brightness_veil.mouse_filter=Control.MOUSE_FILTER_IGNORE; brightness_veil.z_index=55; brightness_veil.size=CONTENT_SIZE; add_child(brightness_veil)
	pixel_grid=PixelGrid.new(); pixel_grid.name="PixelGrid"; pixel_grid.size=CONTENT_SIZE; pixel_grid.z_index=60; add_child(pixel_grid)
	acquisition=Panel.new(); acquisition.name="InventoryAcquisition"; acquisition.mouse_filter=Control.MOUSE_FILTER_IGNORE; acquisition.size=Vector2(42,42); acquisition.pivot_offset=Vector2(21,21); acquisition.z_index=4; acquisition.visible=false
	acquisition.add_theme_stylebox_override("panel",_style(Color("f7f1d7"),Color("101116"),2,Color(0,0,0,0.38),Vector2(3,3))); inventory.add_child(acquisition)
	_acquisition_icon=_make_icon(acquisition,"",28); _acquisition_icon.position=Vector2(7,7)
	for i in 3:
		var particle:=ColorRect.new(); particle.color=Color("f0d54e"); particle.size=Vector2(6,6); particle.position=[Vector2(-12,4),Vector2(-20,18),Vector2(-8,31)][i]; particle.mouse_filter=Control.MOUSE_FILTER_IGNORE; acquisition.add_child(particle); _flight_particles.append(particle)
	for target in [time_box,status_right,task_button,inventory_body,inventory_handle,acquisition]:
		var shadow:=PixelShadow.new(); shadow.target=target; shadow.z_index=target.z_index; shadow.name=str(target.name)+"Shadow"
		shadow.offset=Vector2(3,4) if target==inventory_body else (Vector2(3,3) if target in [inventory_handle,acquisition] else Vector2(2,2))
		shadow.color=Color(119/255.0,92/255.0,49/255.0,0.25) if target in [time_box,status_right] else Color(0,0,0,0.36)
		target.get_parent().add_child(shadow); target.get_parent().move_child(shadow,target.get_index())
	set_process(true)

func refresh(next_state: Dictionary) -> void:
	_build()
	state=next_state
	var ui: Dictionary=state.get("ui",{})
	var page:=str(state.get("native",{}).get("page",state.get("currentScene","phone_home")))
	var bare:=page in ["alarm","desktop","ending"]
	status_bar.visible=not bare
	task_button.visible=not bare and show_task_bar and _task_visible()
	_refresh_status()
	_refresh_task()
	brightness_veil.color=Color(5/255.0,6/255.0,12/255.0,clampf((70.0-float(ui.get("brightness",70)))/70.0,0,1)*0.3)
	var next_owned: Array=[]
	for id in ITEM_ORDER:
		if state.get("items",{}).get(id,false): next_owned.append(id)
	var new_item:=""
	if _seen_inventory:
		for id in next_owned:
			if not owned.has(id): new_item=id; break
	_seen_inventory=true
	owned=next_owned
	inventory_open=bool(ui.get("inventoryOpen",false))
	selected_item=str(ui.get("selectedItem","") if ui.get("selectedItem")!=null else "")
	inventory.visible=not bare and not owned.is_empty() and not (state.get("flags",{}).get("checkinDone",false) and not state.get("actOne",{}).get("inventoryRecovered",false))
	var signature:=str(owned)+"|"+str(inventory_open)+"|"+selected_item
	if signature!=_inventory_signature:
		_inventory_signature=signature
		_refresh_inventory()
	if not new_item.is_empty() and inventory.visible: _start_acquisition(new_item)
	set_input_blocked(input_blocked)

func _task_visible() -> bool:
	var ui: Dictionary=state.get("ui",{})
	var phase:=str(state.get("actOne",{}).get("phase","prologue"))
	var chapter4: Dictionary=state.get("chapterThreeInterlude",{})
	var later:=bool(chapter4.get("completed",false) and chapter4.get("replayUnlocked",false))
	later=later or ui.get("libraryFinalsPuzzle",{}).get("nextQuestId","")=="chapter_three_canteen_hunt" or ui.get("libraryFinalsPhase","")=="friend_contacted"
	for key in ["canteenHunt","theaterHunt","qizhenLake"]: later=later or bool(state.get(key,{}).get("active",false))
	return later or not phase in ["friend_message_required","system_required"]

func _text_width(text: String, font_size: int) -> float:
	return ceilf(PIXEL_FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)

func _refresh_status() -> void:
	var c4: Dictionary=state.get("chapter4",{})
	var active: bool=bool(state.get("chapterThreeInterlude",{}).get("completed",false)) and (c4.get("prologueSeen",false) or c4.get("completed",false) or state.get("rpgScene","")=="duan_yongping_temporal_maze")
	var seconds:=int(c4.get("phoneStatusTimeSeconds",28523)) if active else 28500
	seconds=posmod(seconds,86400)
	var clock:="%02d:%02d" % [seconds/3600,(seconds%3600)/60]
	if active: clock += ":%02d" % [seconds%60]
	time_trusted=not active or bool(c4.get("phoneStatusTimeTrusted",false))
	time_label.text=clock+(" 不可信" if not time_trusted else "")
	time_label.tooltip_text="" if time_trusted else "状态时间已冻结，等待旧钟成为时间来源"
	time_label.size=Vector2(_text_width(time_label.text,14)+time_label.text.length(),20)
	time_box.position=Vector2(18,9); time_box.size=Vector2(time_label.size.x+20,28)
	var network:=str(state.get("networkMode","campus_wifi"))
	var percent:=clampf(float(state.get("phoneBattery",{}).get("percent",100)),0,100)
	var saving:=bool(state.get("phoneBattery",{}).get("lowPowerMode",false))
	network_label.text={"campus_wifi":"ZJUWLAN","cellular":"流量"}.get(network,"无服务")
	network_label.position=Vector2(10,5); network_label.size=Vector2(_text_width(network_label.text,11)+network_label.text.length()*0.5,20)
	var x:=10+network_label.size.x+7
	status_icons.network=network; status_icons.network_x=x
	five_g.visible=network=="cellular"
	if network=="campus_wifi": x+=18+7
	elif network=="cellular":
		x+=18+7; five_g.position=Vector2(x,7); five_g.size=Vector2(_text_width("5G",9)+8,17); x+=five_g.size.x+7
	battery_number.text="%d%%" % int(percent); battery_number.position=Vector2(x,5); battery_number.size=Vector2(_text_width(battery_number.text,11),20)
	battery_number.add_theme_color_override("font_color",RED if percent<=20 else INK); x+=battery_number.size.x
	saving_label.visible=saving
	if saving:
		saving_label.position=Vector2(x+2,5); saving_label.size=Vector2(9,20); x+=11
	x+=7; status_icons.battery_x=x; status_icons.percent=percent
	status_right.size=Vector2(x+22+10,30); status_right.position=Vector2(424-14-status_right.size.x,8)
	status_icons.size=status_right.size; status_icons.queue_redraw()
	status_right.tooltip_text="打开控制中心，当前电量 %d%%%s" % [int(percent),"，低电量模式已开启" if saving else ""]

func _refresh_task() -> void:
	var digits: Dictionary=state.get("digits",{})
	var known: Array=[]
	var any_digit:=false
	for key in ["d1","d2","d3","d4"]:
		var digit: Variant=digits.get(key)
		var acquired:=digit!=null and str(digit)!=""
		known.append(str(digit) if acquired else "?")
		any_digit=any_digit or acquired
	var show_digits: bool=state.get("actOne",{}).get("phase","prologue")=="prologue" and (state.get("flags",{}).get("codeScattered",false) or any_digit)
	var width:=136.0 if show_digits else 76.0
	task_button.position=Vector2((424-width)/2,5); task_button.size=Vector2(width,30)
	task_copy.position=Vector2(2,3 if show_digits else 2); task_copy.size=Vector2(width-4,12 if show_digits else 26)
	digit_hint.visible=show_digits; digit_hint.text="签到码 "+" ".join(known); digit_hint.position=Vector2(2,15); digit_hint.size=Vector2(width-4,11)
	var objective:=str(state.get("native",{}).get("objective",state.get("objective","")))
	if not objective.is_empty() and not _last_objective.is_empty() and objective!=_last_objective: _task_update_started=Time.get_ticks_msec()/1000.0
	_last_objective=objective

func _refresh_inventory() -> void:
	inventory_body.visible=inventory_open
	inventory_count.visible=not inventory_open
	inventory_arrow.text="‹" if inventory_open else "›"
	inventory_handle.tooltip_text="收起物品栏" if inventory_open else "展开物品栏"
	inventory_handle.position=Vector2(74 if inventory_open else 0,0); inventory_handle.size=Vector2(40 if inventory_open else 38,63)
	for part in ["normal","hover","pressed"]:
		var bg:=Color(38/255.0,40/255.0,48/255.0,0.92) if part=="normal" else Color(56/255.0,59/255.0,70/255.0,0.95)
		var box:=_style(bg,Color("101116"),2,Color(0,0,0,0.35),Vector2(3,3)); box.border_width_left=2 if inventory_open else 0
		inventory_handle.add_theme_stylebox_override(part,box)
	inventory_count.text=str(owned.size()); inventory_count.size=Vector2(_text_width(inventory_count.text,9)+12,15); inventory_count.position=Vector2(inventory_handle.size.x-inventory_count.size.x+8,-8)
	var scroll_before:=inventory_scroll.scroll_vertical
	if _slot_ids!=owned:
		_slot_ids=owned.duplicate()
		for child in inventory_slots.get_children(): inventory_slots.remove_child(child); child.queue_free()
		for id in owned:
			var item: Dictionary=catalog.get(id,{"id":id,"name":id,"desc":""})
			var slot:=InventorySlot.new(); slot.name="Item_"+id; slot.item_id=id; slot.tooltip_text=str(item.name)+"："+str(item.get("desc",""))
			slot.custom_minimum_size=Vector2(52,52); slot.size=Vector2(52,52); slot.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
			_set_button_style(slot,_style(Color("f5c542") if selected_item==id else Color("cfd3d9"),Color("101116"),2),_style(Color("e2e6ec"),Color("101116"),2))
			inventory_slots.add_child(slot)
			# Source inset highlights and shadows, inside the 2px ink outline.
			for edge in [[Rect2(2,2,48,3),Color(1,1,1,0.35)],[Rect2(2,2,3,48),Color(1,1,1,0.35)],[Rect2(2,47,48,3),Color(0,0,0,0.18)],[Rect2(47,2,3,48),Color(0,0,0,0.18)]]:
				var shade:=ColorRect.new(); shade.position=edge[0].position; shade.size=edge[0].size; shade.color=edge[1]; shade.mouse_filter=Control.MOUSE_FILTER_IGNORE; slot.add_child(shade)
			slot.artwork=_make_icon(slot,id,34); slot.artwork.position=Vector2(9,9)
			slot.gestures=inventory_gestures
			slot.selection_requested.connect(_select_inventory_item); slot.inspection_requested.connect(_inspect_inventory_item)
			slot.drag_finished.connect(func(landed: bool): if not landed: get_node("/root/State").feedback.emit("没有落在可使用的物品上，道具仍在物品栏。"))
			slot.combine_requested.connect(func(from_id: String,to_id: String): items_combined.emit(from_id,to_id))
	for slot in inventory_slots.get_children():
		_set_button_style(slot,_style(Color("f5c542") if selected_item==slot.item_id else Color("cfd3d9"),Color("101116"),2),_style(Color("e2e6ec"),Color("101116"),2))
	var slots_height:=minf(260,owned.size()*60-8+4)
	inventory_scroll.size=Vector2(62,slots_height)
	var tip:=str(catalog.get(selected_item,{}).get("name",""))
	inventory_tip.text=tip; inventory_tip.position=Vector2(6,18+slots_height); inventory_tip.size=Vector2(60,15 if not tip.is_empty() else 0)
	var height:=27+slots_height+(15 if not tip.is_empty() else 0)
	inventory_body.size=Vector2(74,minf(height,328))
	inventory.size=Vector2(114,maxf(63,inventory_body.size.y)) if inventory_open else Vector2(38,63)
	inventory_scroll.set_deferred("scroll_vertical",scroll_before)
	set_inventory_top(inventory_top)

func _toggle_inventory() -> void:
	if _suppress_handle_click:
		_suppress_handle_click=false
		return
	inventory_gestures.reset()
	inventory_open=not inventory_open
	if not inventory_open:
		selected_item=""; item_selected.emit("")
	_refresh_inventory()
	utility_requested.emit("inventory_toggle")

func _activate_item(id: String) -> void:
	# Kept as a semantic tap entry point for existing callers/tests.
	if inventory_gestures.tap(id,Vector2.ZERO,Time.get_ticks_msec()): _inspect_inventory_item(id)
	else: _select_inventory_item(id)

func _select_inventory_item(id: String) -> void:
	selected_item=id
	item_selected.emit(id)
	_refresh_inventory()

func _inspect_inventory_item(id: String) -> void:
	inventory_gestures.reset()
	inspect_requested.emit(catalog.get(id,{"id":id,"name":id}))

func _on_handle_input(event: InputEvent) -> void:
	if _reading_inventory_anchor() and not inventory_open: return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			_bar_dragging=true; _bar_moved=false; _bar_drag_start=get_global_mouse_position().y; _bar_top_start=inventory_top
		else:
			_suppress_handle_click=_bar_moved; _bar_dragging=false
	elif event is InputEventScreenTouch:
		if event.pressed:
			_bar_dragging=true; _bar_moved=false; _bar_drag_start=event.position.y; _bar_top_start=inventory_top
		else: _suppress_handle_click=_bar_moved; _bar_dragging=false

func _input(event: InputEvent) -> void:
	if not _bar_dragging or input_blocked: return
	var pointer_y:=0.0
	if event is InputEventMouseMotion: pointer_y=event.global_position.y
	elif event is InputEventScreenDrag: pointer_y=event.position.y
	elif event is InputEventMouseButton and not event.pressed:
		_suppress_handle_click=_bar_moved; _bar_dragging=false; return
	elif event is InputEventScreenTouch and not event.pressed:
		_suppress_handle_click=_bar_moved; _bar_dragging=false; return
	else: return
	var global_scale:=maxf(0.001,get_global_transform().get_scale().y)
	var delta_y:=(pointer_y-_bar_drag_start)/global_scale
	if absf(delta_y)>3: _bar_moved=true
	if _bar_moved: set_inventory_top(_bar_top_start+delta_y)

func set_inventory_top(top: float) -> void:
	var height:=inventory.size.y if is_instance_valid(inventory) else 63.0
	inventory_top=clampf(top,INVENTORY_TOP_MIN,maxf(INVENTORY_TOP_MIN,860-height-INVENTORY_BOTTOM_GAP))
	if is_instance_valid(inventory): inventory.position=Vector2(0,inventory_top)
	_inventory_anchor_signature=[]
	_layout_inventory_anchor()

func _reading_inventory_anchor() -> bool:
	var page: String=str(state.get("native",{}).get("page",""))
	if page in ["c4_notes","c4_device"]: return true
	if page=="c3_lake":return true
	if bool(state.get("chapterThreeInterlude",{}).get("completed",false)):return false
	# Home's Photos app aliases the recovered frames only after the lake ending.
	# Match that page's existing admission rule without changing its story state.
	if page=="photos":return str(state.get("qizhenLake",{}).get("phase",""))=="complete"
	return page in ["c35_recovery","c35_journal","c35_photos","c35_voice","c35_official","c35_messages","c35_network"]

func _layout_inventory_anchor() -> void:
	if not _built or not is_instance_valid(inventory_handle): return
	var context:Array=[_reading_inventory_anchor(),str(state.get("native",{}).get("page","")),get_global_transform(),time_box.get_rect(),task_button.get_rect(),inventory_open]
	if not _inventory_anchor_context.is_empty() and context!=_inventory_anchor_context and (context[0] or _inventory_anchor_context[0]):
		# A pointer owned by the outgoing page/anchor cannot drop into its replacement.
		# Deliberate vertical movement of an open drawer is not a context change.
		inventory_gestures.reset();_bar_dragging=false;_bar_moved=false;_suppress_handle_click=false
		for slot in inventory_slots.get_children():slot.cancel_gesture()
	_inventory_anchor_context=context
	var signature:Array=[inventory_open,_reading_inventory_anchor(),get_global_transform(),inventory_top,time_box.get_rect(),task_button.get_rect(),inventory_count.size]
	if signature==_inventory_anchor_signature:return
	_inventory_anchor_signature=signature
	var icon:Control=inventory_handle.get_node("BackpackIcon")
	inventory_handle.remove_meta("painted_rect")
	# The expanded drawer keeps its authored drag/inspection/combine geometry.
	inventory.position=Vector2(0,inventory_top)
	inventory_handle.position=Vector2(74 if inventory_open else 0,0)
	inventory_handle.size=Vector2(40 if inventory_open else 38,63)
	_set_inventory_painted_rect(Rect2(Vector2.ZERO,inventory_handle.size))
	if not inventory_open:inventory.size=Vector2(38,63)
	inventory_arrow.visible=true;inventory_handle.mouse_default_cursor_shape=Control.CURSOR_VSIZE
	icon.position=Vector2(5,10)
	inventory_count.position=Vector2(inventory_handle.size.x-inventory_count.size.x+8,-8)
	if inventory_open or not _reading_inventory_anchor():return
	var factor:float=maxf(.001,get_global_transform().get_scale().x)
	var edge:float=44.0/factor
	var gap_left:float=time_box.position.x+time_box.size.x+8
	var gap_right:float=task_button.position.x-8
	var header_face:bool=false
	if get_global_position().x>=52:
		inventory.position.x=-(edge+8/factor)
		inventory_handle.size=Vector2(edge,maxf(edge,63))
	elif gap_right-gap_left>=edge:
		# The existing empty header gap provides a44px control without reducing
		# the authored app canvas, wrapping clue text or covering its scroll area.
		inventory.position=Vector2((gap_left+gap_right-edge)/2,40-edge)
		inventory_handle.size=Vector2(edge,edge)
		inventory_arrow.visible=false;header_face=true
	elif get_global_position().y>=52:
		inventory.position=Vector2((CONTENT_SIZE.x-edge)/2,-edge-8/factor)
		inventory_handle.size=Vector2(edge,edge);inventory_arrow.visible=false
	else:
		return
	inventory.size=inventory_handle.size
	inventory_handle.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	icon.position=Vector2((inventory_handle.size.x-26)/2,8 if inventory_arrow.visible else (inventory_handle.size.y-26)/2)
	inventory_count.position=Vector2(maxf(1,inventory_handle.size.x-inventory_count.size.x-2),1)
	if header_face:
		var painted:Rect2=Rect2((edge-38)/2,5-inventory.position.y,38,30)
		_set_inventory_painted_rect(painted)
		icon.position=painted.position+Vector2(6,2)
		inventory_count.position=painted.position+Vector2(maxf(1,painted.size.x-inventory_count.size.x-2),1)
	else:
		_set_inventory_painted_rect(Rect2(Vector2.ZERO,inventory_handle.size))

func _set_inventory_painted_rect(rect:Rect2) -> void:
	# The hit area can be larger than its face. Shadows/focus follow the face,
	# so transparent hit padding never looks like a floating block above the phone.
	inventory_handle.set_meta("painted_rect",rect)
	for role:String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		var original:StyleBox=inventory_handle.get_theme_stylebox(role)
		if not original is StyleBoxFlat:continue
		var box:StyleBoxFlat=original.duplicate()
		box.expand_margin_left=-rect.position.x
		box.expand_margin_top=-rect.position.y
		box.expand_margin_right=-(inventory_handle.size.x-rect.end.x)
		box.expand_margin_bottom=-(inventory_handle.size.y-rect.end.y)
		inventory_handle.add_theme_stylebox_override(role,box)

func set_input_blocked(blocked: bool) -> void:
	input_blocked=blocked
	if not _built: return
	status_right.disabled=blocked; task_button.disabled=blocked; inventory_handle.disabled=blocked
	for child in inventory_slots.get_children(): child.disabled=blocked
	if blocked:
		_bar_dragging=false; inventory_gestures.reset()
		for child in inventory_slots.get_children(): child.cancel_gesture()

func _start_acquisition(id: String) -> void:
	recent_item=id; _acquisition_started=Time.get_ticks_msec()/1000.0
	_acquisition_icon.pixels=PIXEL_ICONS.get(id,{}); _acquisition_icon.raster=load(RASTER_ICONS[id]) if RASTER_ICONS.has(id) else null; _acquisition_icon.queue_redraw()
	acquisition.visible=true

func _process(_delta: float) -> void:
	if not _built: return
	_layout_inventory_anchor()
	var now:=Time.get_ticks_msec()/1000.0
	var critical_phase:=fmod(now,0.8)>=0.4
	if critical_phase!=_last_critical_phase:
		_last_critical_phase=critical_phase; status_icons.critical_phase=critical_phase; status_icons.queue_redraw()
	if _acquisition_started>=0:
		var elapsed:=now-_acquisition_started
		var p:=floorf(clampf(elapsed/0.98,0,1)*12)/12.0
		acquisition.position=Vector2(208,2)+Vector2(lerpf(30,-190,minf(p/0.7,1)),lerpf(-18,0,minf(p/0.7,1)))
		var scale_value:=lerpf(1.45,0.82,p/0.7) if p<=0.7 else lerpf(0.82,0,clampf((p-0.7)/0.3,0,1))
		acquisition.scale=Vector2.ONE*scale_value
		acquisition.modulate.a=minf(1,p/0.12) if p<0.12 else (1.0 if p<0.7 else maxf(0,1-(p-0.7)/0.12))
		for i in _flight_particles.size():
			var t:=clampf((elapsed-i*0.08)/0.7,0,1)
			_flight_particles[i].modulate.a=sin(t*PI)
		if elapsed>=1.15:
			_acquisition_started=-1; recent_item=""; acquisition.visible=false
	if _task_update_started>=0 and now-_task_update_started>1.05: _task_update_started=-1
