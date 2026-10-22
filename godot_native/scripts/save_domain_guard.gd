extends RefCounted
## Nonmutating validation of known persisted source domains. This is deliberately
## not browser normalization: native replay/provenance fields must stay intact.
## sets are exported from actual SaveStore.ts by export-save-domains.mjs.
const PATH := "res://data/native/save-domains.json"
const SAFE_INTEGER := 9007199254740991.0
const ENUMS := {
 "runtimeMode":"VALID_RUNTIME_MODES", "networkMode":"VALID_NETWORK_MODES", "themeMode":"VALID_THEME_MODES",
 "actOne.phase":"VALID_ACT_ONE_PHASES",
 "canteenHunt.phase":"VALID_CANTEEN_HUNT_PHASES", "canteenHunt.mode":"VALID_CANTEEN_MODES",
 "theaterHunt.phase":"VALID_THEATER_HUNT_PHASES", "theaterHunt.mode":"VALID_THEATER_MODES", "theaterHunt.cc98TicketCommissionPhase":"VALID_THEATER_TICKET_COMMISSION_PHASES",
 "qizhenLake.phase":"VALID_QIZHEN_PHASES", "qizhenLake.mode":"VALID_QIZHEN_MODES", "qizhenLake.zone":"VALID_QIZHEN_ZONES", "qizhenLake.vehicle":"VALID_QIZHEN_VEHICLES", "qizhenLake.safeSpawnId":"VALID_QIZHEN_SAFE_SPAWNS", "qizhenLake.journal.status":"VALID_QIZHEN_JOURNAL_STATUSES",
 "chapterThreeInterlude.phase":"VALID_CHAPTER_THREE_INTERLUDE_PHASES",
 "clockCalibration.phase":"VALID_CLOCK_CALIBRATION_PHASES", "clockCalibration.step":"VALID_CLOCK_CALIBRATION_STEPS",
 "chapter4.phase":"VALID_CHAPTER_FOUR_PHASES", "chapter4.mode":"VALID_CHAPTER_FOUR_MODES", "chapter4.floor":"VALID_CHAPTER_FOUR_FLOORS", "chapter4.timeState":"VALID_CHAPTER_FOUR_TIME_STATES",
 "ui.zjudingPage":"VALID_ZJUDING_PAGES", "ui.libraryFinalsPhase":"VALID_LIBRARY_FINALS_PHASES", "ui.libraryFinalsPuzzle.lostFoundStage":"VALID_LOST_FOUND_STAGES"
}
const NULLABLE_ENUMS := {
 "digits.d1":"VALID_DIGIT_VALUES", "digits.d2":"VALID_DIGIT_VALUES", "digits.d3":"VALID_DIGIT_VALUES", "digits.d4":"VALID_DIGIT_VALUES",
 "canteenHunt.orderedMenuOption":"VALID_CANTEEN_MENU_OPTIONS", "qizhenLake.boardingLastSide":"VALID_QIZHEN_PADDLE_SIDES", "qizhenLake.decoyPlacedAt":"VALID_QIZHEN_DECOY_TARGETS", "qizhenLake.journal.summaryChoice":"VALID_QIZHEN_SUMMARY_CHOICES",
 "chapterThreeInterlude.networkRecordId":"VALID_CHAPTER_THREE_INTERLUDE_NETWORK_RECORDS",
 "chapter4.zhuQuestionAnswers.purpose":"VALID_CHAPTER_FOUR_ZHU_PURPOSE_ANSWERS", "chapter4.zhuQuestionAnswers.person":"VALID_CHAPTER_FOUR_ZHU_PERSON_ANSWERS"
}
const ARRAY_ENUMS := {
 "actOne.visitedAreaIds":"VALID_ACT_ONE_AREA_IDS",
 "canteenHunt.carriedTrayIds":"VALID_CANTEEN_TRAY_IDS", "canteenHunt.identifiedTrayIds":"VALID_CANTEEN_TRAY_IDS", "canteenHunt.returnedTrayIds":"VALID_CANTEEN_TRAY_IDS", "canteenHunt.drinkMixSequence":"VALID_CANTEEN_DRINK_IDS", "canteenHunt.identifiedExitIds":"VALID_CANTEEN_EXIT_IDS",
 "theaterHunt.collectedProgramIds":"VALID_THEATER_PROGRAM_IDS", "theaterHunt.programOrder":"VALID_THEATER_PROGRAM_IDS",
 "qizhenLake.mapClueIds":"VALID_QIZHEN_MAP_CLUES", "qizhenLake.observedFishingSpotIds":"VALID_QIZHEN_FISHING_SPOTS", "qizhenLake.journal.publishedSpotIds":"VALID_QIZHEN_PHOTO_SPOTS",
 "chapterThreeInterlude.photoFrameIds":"VALID_CHAPTER_THREE_INTERLUDE_PHOTOS", "chapterThreeInterlude.voiceClipOrder":"VALID_CHAPTER_THREE_INTERLUDE_VOICES", "chapterThreeInterlude.evidenceIds":"VALID_CHAPTER_THREE_INTERLUDE_EVIDENCE", "chapterThreeInterlude.timelineOrder":"VALID_CHAPTER_THREE_INTERLUDE_EVIDENCE", "chapterThreeInterlude.rejectedDecoyIds":"VALID_CHAPTER_THREE_INTERLUDE_DECOYS",
 "clockCalibration.archiveClueIds":"VALID_CLOCK_ARCHIVE_CLUE_IDS", "clockCalibration.coarseLockIds":"VALID_CLOCK_COARSE_LOCK_IDS", "clockCalibration.driftCorrectedChannelIds":"VALID_CLOCK_DRIFT_CHANNEL_IDS",
 "chapter4.factIds":"VALID_CHAPTER_FOUR_FACT_IDS", "chapter4.solvedPuzzleIds":"LEGACY_CHAPTER_FOUR_PUZZLE_IDS",
 "ui.libraryFinalsPuzzle.libraryVisitedPoints":"VALID_LIBRARY_LOCATION_IDS", "ui.libraryFinalsPuzzle.cc98UploadedEvidenceIds":"VALID_LIBRARY_EVIDENCE_IDS", "ui.libraryFinalsPuzzle.appliedBdReplyIds":"VALID_BD_REPLY_IDS", "ui.libraryFinalsPuzzle.bdSelectedPostIds":"VALID_BD_POST_IDS", "ui.libraryFinalsPuzzle.recoverySubmittedEvidenceIds":"VALID_LIBRARY_RECOVERY_EVIDENCE_IDS", "ui.seenChapterIntros":"VALID_CHAPTER_IDS"
}
## Source SaveStore rangedIntegerOr domains. Do not invent ceilings for source
## counters whose normalizer only requires nonnegative integers.
const INTEGER_RANGES := {
 "phoneBattery.percent":[1,100], "actOne.pushTriangleTapCount":[0,3], "actOne.cc98Login.revealedHintCount":[0,3],
 "canteenHunt.blockHits":[0,3], "canteenHunt.chaseBestLives":[0,3], "theaterHunt.spotlightRound":[0,3], "qizhenLake.reflectionRound":[0,3],
 "clockCalibration.displayedSeconds":[0,86399], "clockCalibration.targetSeconds":[0,86399], "clockCalibration.phaseLockHits":[0,3],
 "chapterThreeInterlude.windowStartSeconds":[0,86399], "chapterThreeInterlude.windowEndSeconds":[0,86399],
 "chapter4.lightGrid.mask":[0,31], "chapter4.chaseStairwellLanding":[0,2],
 "ui.libraryFinalsPuzzle.auditArrivalMinutes":[0,12], "ui.libraryFinalsPuzzle.auditPublicNoticeFloor":[0,63], "ui.libraryFinalsPuzzle.auditProofCount":[0,5], "ui.libraryFinalsPuzzle.bdCount":[0,3]
}
const NONNEGATIVE_INTEGERS := [
 "phoneBattery.rechargeCount", "flags.tiyiCrashCount", "flags.slashTapCount", "actOne.cc98Login.failureCount",
 "canteenHunt.drinkMixAttemptCount", "canteenHunt.orderAttemptCount", "canteenHunt.pickupAttemptCount", "canteenHunt.chaseAttemptCount", "canteenHunt.chaseBestDistance", "canteenHunt.chaseCollisions",
 "theaterHunt.ticketCodeAttempts", "theaterHunt.programWrongAttempts", "theaterHunt.spotlightMistakes",
 "qizhenLake.weatherControlAttempts", "qizhenLake.weatherControlBestMoves", "qizhenLake.boardingStrokeCount", "qizhenLake.capsizeCount", "qizhenLake.directPaperCastFailures", "qizhenLake.chaseAttempts", "qizhenLake.dockCollisionCount", "qizhenLake.swanAlertLevel", "qizhenLake.reflectionMistakes", "qizhenLake.decoyAttempts", "qizhenLake.mistAttempts",
 "clockCalibration.driftAttempts", "clockCalibration.phaseLockAttempts", "clockCalibration.adjustCount",
 "ui.libraryFinalsPuzzle.auditAttemptCount", "ui.libraryFinalsPuzzle.bdPasswordAttemptCount"
]
## Inline discriminants from core/types.ts and SaveStore normalization. No
## relationship/progression repairs happen here; controller proof checks own them.
const INLINE_ENUMS := {
 "theaterHunt.cc98TicketClaimedWave":[null,1,2],
 "chapter4.building":["A"], "chapter4.timeAuthority":["external_evidence","hall_clock"], "chapter4.guardMode":["absent","patrol","chase"], "chapter4.chaseStairwellStage":["pending","inside","complete"],
 "chapter4.chaseRestartCheckpoint":[null,"c4_a1_lobby","c4_a2_corridor"],
 "chapterThreeInterlude.destinationId":[null,"duan_yongping_a1"],
 "ui.libraryFinalsPuzzle.nextQuestId":[null,"chapter_three_canteen_hunt","chapter_three_book_hunt"]
}
var domains: Dictionary = {}
var room204: Dictionary = {}
var failure := ""
func _init() -> void:
 var data=JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
 if data is Dictionary and data.get("format")=="7-55-save-domains" and data.get("version")==1 and data.get("sets") is Dictionary: domains=data.sets
 var story=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-755.content.json"))
 if story is Dictionary and story.get("room204") is Dictionary: room204=story.room204
func _path_value(value: Dictionary,path: String) -> Variant:
 var current: Variant=value
 for key in path.split("."):
  if not current is Dictionary or not current.has(key): return {"missing_domain_field":path}
  current=current[key]
 return current
func _fail(path: String) -> bool:
 failure=path
 return false
func _allowed(value: Variant,allowed: Array) -> bool:
 for candidate in allowed:
  if candidate==null and value==null: return true
  if candidate is String and value is String and candidate==value: return true
  if (candidate is int or candidate is float) and (value is int or value is float) and float(candidate)==float(value): return true
 return false
func _enum(value: Variant,set_name: String,nullable: bool=false) -> bool:
 return (nullable and value==null) or (value is String and domains.get(set_name,[]).has(value))
func _number(value: Variant,minimum: float,maximum: float=INF,integer: bool=true,nullable: bool=false) -> bool:
 if nullable and value==null: return true
 return (value is int or value is float) and is_finite(float(value)) and float(value)>=minimum and float(value)<=maximum and (not integer or float(value)==floorf(float(value)))
func validate(value: Variant) -> bool:
 failure=""
 if not value is Dictionary or domains.is_empty(): return _fail("source_domains_unavailable_or_invalid_snapshot")
 for path in ENUMS:
  if not _enum(_path_value(value,path),ENUMS[path]): return _fail(path)
 for path in NULLABLE_ENUMS:
  if not _enum(_path_value(value,path),NULLABLE_ENUMS[path],true): return _fail(path)
 for path in ARRAY_ENUMS:
  var entries: Variant=_path_value(value,path)
  if not entries is Array: return _fail(path)
  for entry in entries:
   if not _enum(entry,ARRAY_ENUMS[path]): return _fail(path)
 for path in INLINE_ENUMS:
  if not _allowed(_path_value(value,path),INLINE_ENUMS[path]): return _fail(path)
 for path in INTEGER_RANGES:
  if not _number(_path_value(value,path),INTEGER_RANGES[path][0],INTEGER_RANGES[path][1]): return _fail(path)
 for path in NONNEGATIVE_INTEGERS:
  if not _number(_path_value(value,path),0): return _fail(path)
 for path in ["wallet.campusCardCents","wallet.cashCents","chapter4.chaseAttempt","qizhenLake.journal.threadSeed"]:
  if not _number(_path_value(value,path),0,SAFE_INTEGER): return _fail(path)
 if not _number(_path_value(value,"actOne.cc98Login.lockUntilMs"),0,SAFE_INTEGER,true,true): return _fail("actOne.cc98Login.lockUntilMs")
 if not _number(_path_value(value,"clockCalibration.selectedTargetSeconds"),0,86399,true,true): return _fail("clockCalibration.selectedTargetSeconds")
 if not _number(_path_value(value,"ui.brightness"),0,100,false): return _fail("ui.brightness")
 for path in ["qizhenLake.chaseDistance","qizhenLake.chaseBestDistance"]:
  if not _number(_path_value(value,path),0,1000,false): return _fail(path)
 var rotations: Variant=_path_value(value,"qizhenLake.signRotations")
 if not rotations is Array or rotations.size()!=3: return _fail("qizhenLake.signRotations")
 for rotation in rotations:
  if not _number(rotation,0,3): return _fail("qizhenLake.signRotations")
 var placements: Variant=_path_value(value,"chapter4.room204Placements")
 if not placements is Array or room204.is_empty(): return _fail("chapter4.room204Placements")
 var pieces: Array=[]
 var slots: Array=[]
 for placement in placements:
  # Source ChapterFourRoom204Model normalizes unique known piece/slot pairs
  # with its one allowed orientation; arbitrary correct permutations stay valid.
  if not placement is Dictionary or placement.get("pieceId") not in room204.pieceIds or placement.get("slotId") not in room204.slotIds or placement.get("orientation")!="up": return _fail("chapter4.room204Placements")
  if placement.pieceId in pieces or placement.slotId in slots: return _fail("chapter4.room204Placements")
  pieces.append(placement.pieceId); slots.append(placement.slotId)
 return true
