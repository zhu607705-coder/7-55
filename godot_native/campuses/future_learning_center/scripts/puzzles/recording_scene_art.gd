extends RefCounted
## Original webpage PNGs only. Crops retain source bytes and uniform scale.
const Shared=preload("res://campuses/future_learning_center/scripts/puzzles/optical_scene_art.gd")
const REQUIRED=["drive_base","drive_handle","handwheel","sliding_baffle","endstop","dropgate","paper_guide","paper_strip","paper_roll"]
const PARTS:Dictionary={
 "drive_base":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/recording_scene/drive_base.png"),"region":Rect2(217,91,359,1799),"box":Vector2(41.0696,205.8056),"pivot":Vector2(395,975)},
 "drive_handle":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/recording_scene/drive_handle.png"),"region":Rect2(408,374,439,520),"box":Vector2(24,24),"pivot":Vector2(626,835)},
 "handwheel":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/recording_scene/handwheel.png"),"region":Rect2(91,89,1090,1072),"box":Vector2(66,66),"pivot":Vector2(625,639)},
 "sliding_baffle":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/recording_scene/sliding_baffle.png"),"region":Rect2(375,96,221,1427),"box":Vector2(22,120),"pivot":Vector2(485.5,809.5)},
 "endstop":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/recording_scene/endstop.png"),"region":Rect2(441,113,175,1271),"box":Vector2(12,65),"pivot":Vector2(441,748.5)},
 "dropgate":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/recording_scene/dropgate.png"),"region":Rect2(369,179,308,1144),"box":Vector2(14,50),"pivot":Vector2(523,751)},
 "paper_guide":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/recording_scene/paper_guide.png"),"region":Rect2(61,218,2084,270),"box":Vector2(800,104),"pivot":Vector2(1103,353)},
 "paper_strip":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/recording_scene/paper_strip.png"),"region":Rect2(90,241,1990,236),"box":Vector2(786,59.885),"pivot":Vector2(1085,359)},
 "paper_roll":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/recording_scene/paper_roll.png"),"region":Rect2(165,144,910,961),"box":Vector2(70,70),"pivot":Vector2(670,607)}
}
static func complete()->bool:
 for key:String in REQUIRED:
  if not PARTS.has(key):return false
 return true
static func parts()->Dictionary:
 var result:=Shared.parts()
 for key:String in PARTS:result[key]=PARTS[key].duplicate()
 return result
