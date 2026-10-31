extends RefCounted
## Only original webpage-generated raster parts belong in this manifest.
## Optical crops are supplied by the asset inspection pass, never placeholders.
const Shared=preload("res://campuses/future_learning_center/scripts/puzzles/schedule_scene_art.gd")
const CAMERA=preload("res://campuses/future_learning_center/assets/puzzles/schedule_generated/camera.png")
const REQUIRED=["fixture","baffle_front","baffle_edge","lamp","carriage","rail_horizontal","rail_vertical","target","quarter_control","bracket","socket"]
const OPTICAL_PARTS:Dictionary={
 "fixture":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/optical_scene/fixture.png"),"region":Rect2(85,96,1374,815),"box":Vector2(312,185),"pivot":Vector2(772,490)},
 "baffle_front":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/optical_scene/baffle_front.png"),"region":Rect2(154,180,1543,539),"box":Vector2(116,41),"pivot":Vector2(924,710)},
 "baffle_edge":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/optical_scene/baffle_edge.png"),"region":Rect2(415,82,194,1372),"box":Vector2(194,1372)*(76.56/1310.0),"pivot":Vector2(512,792)},
 "lamp":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/optical_scene/lamp.png"),"region":Rect2(184,138,924,969),"box":Vector2(36,38),"pivot":Vector2(642,549)},
 "carriage":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/optical_scene/carriage.png"),"region":Rect2(179,241,915,779),"box":Vector2(38,37),"pivot":Vector2(637,700)},
 "rail_horizontal":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/optical_scene/rail_horizontal.png"),"region":Rect2(82,272,2008,57),"box":Vector2(210,8)},
 "rail_vertical":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/optical_scene/rail_vertical.png"),"region":Rect2(326,109,81,1437),"box":Vector2(8,138.6)},
 "target":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/optical_scene/target.png"),"region":Rect2(176,188,924,862),"box":Vector2(36,34),"pivot":Vector2(638,619)},
 "quarter_control":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/optical_scene/quarter_control.png"),"region":Rect2(218,255,819,780),"box":Vector2(60,60),"pivot":Vector2(627,800)},
 "bracket":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/optical_scene/bracket.png"),"region":Rect2(187,171,678,1244),"box":Vector2(28,52),"pivot":Vector2(525,1200)},
 "socket":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/optical_scene/socket.png"),"region":Rect2(100,452,1418,93),"box":Vector2(116,8),"pivot":Vector2(809,498.5)}
}
static func parts()->Dictionary:
 var result:=Shared.PARTS.duplicate(true)
 result["camera"]={"texture":CAMERA,"region":Rect2(105,356,1052,649),"box":Vector2(57,43)}
 for key:String in OPTICAL_PARTS:
  var spec:Dictionary=OPTICAL_PARTS[key].duplicate()
  result[key]=spec
 return result
static func complete()->bool:
 for key:String in REQUIRED:
  if not OPTICAL_PARTS.has(key) or not OPTICAL_PARTS[key].get("accepted",true):return false
 return true
