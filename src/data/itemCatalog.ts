import type { ItemCatalogEntry, ItemId } from "../core/types";

const object = (uses: ItemCatalogEntry["uses"] = []): ItemCatalogEntry => ({ inspectKind: "object", uses });
const paper = (
  document: NonNullable<ItemCatalogEntry["document"]>,
  uses: ItemCatalogEntry["uses"]
): ItemCatalogEntry => ({ inspectKind: "paper", document, uses });

export const ITEM_CATALOG: Record<ItemId, ItemCatalogEntry> = {
  waterDrop: object([{ target: "headphone", result: "transform" }]),
  headphone: object([{ target: "waterDrop", result: "transform" }]),
  wateredHeadphone: object([{ target: "bonsai-water", result: "consume" }]),
  reverseGear: object([{ target: "slashLine", result: "transform" }]),
  slashLine: object([{ target: "reverseGear", result: "transform" }]),
  towerKey: object([{ target: "tower-lock", result: "consume" }]),
  fertilizer: object([{ target: "bonsai-fertilizer", result: "consume" }]),
  campusCard: object([
    { target: "department-card-reader", result: "retain" },
    { target: "campus-card-balance", result: "retain" }
  ]),
  pushTriangle: object([{ target: "mentorLine", result: "transform" }]),
  weatherWater: object([{ target: "mentor-avatar", result: "consume" }]),
  mentorLine: object([{ target: "pushTriangle", result: "transform" }]),
  rightArrow: object([
    { target: "campus-card-balance", result: "retain" },
    { target: "seat-022-gap", result: "consume" }
  ]),
  gamepad: object([{ target: "rpg-player", result: "consume" }]),
  occupancyNote: paper({
    heading: "022 临时离座留言",
    fields: [
      { label: "座位", value: "022 · 二楼南区" },
      { label: "离开时长", value: "三分钟" },
      { label: "留言状态", value: "仍在占用" }
    ],
    body: ["本人离开三分钟，精神仍在座位上。", "临时离座规则详见 CC98。"],
    footer: "纸张边缘留有反复折叠痕迹。"
  }, [{ target: "cc98-search", result: "consume" }]),
  callNumber755: paper({
    heading: "馆藏定位单",
    fields: [
      { label: "书名", value: "《三分钟离座法及其例外》" },
      { label: "索书号", value: "I247.55 / 755" },
      { label: "馆藏位置", value: "基础馆文学书架 · 755 段" }
    ],
    body: ["本条目为旧版规定的馆内定位线索。"],
    footer: "状态：仅馆内查阅。"
  }, [{ target: "library-shelf-755", result: "consume" }]),
  archivedLeaveRule: paper({
    heading: "旧版临时离座恢复规定",
    fields: [
      { label: "版本", value: "期末周修订版 · 已归档" },
      { label: "适用范围", value: "座位被非本人随身物持续占用" },
      { label: "目标座位", value: "022" }
    ],
    body: [
      "恢复申请须同时具备三类证明：",
      "一、本人确实到馆；",
      "二、目标座位与凭据一致；",
      "三、当前占用物不具备本人身份。"
    ],
    footer: "规则依据须先完成公开公示。"
  }, [{ target: "cc98-upload:archived_leave_rule", result: "consume" }]),
  itemRecognitionReport: paper({
    heading: "物品识别报告",
    fields: [
      { label: "对象类型", value: "双肩书包" },
      { label: "姓名", value: "未识别" },
      { label: "学号", value: "未识别" },
      { label: "识别结果", value: "未检测到可签到主体" }
    ],
    body: ["检测到大量期末周使用痕迹。", "身份结论需由馆内前台工作人员确认。"],
    footer: "报告状态：待盖章。"
  }, [{ target: "library-front-desk-staff", result: "transform" }]),
  bagNonPersonProof: paper({
    heading: "书包非本人证明",
    fields: [
      { label: "对象", value: "022 座位占用书包" },
      { label: "认证结论", value: "非本人" },
      { label: "姓名 / 学号", value: "无 / 无" },
      { label: "盖章来源", value: "基础馆物品身份盖章机" }
    ],
    body: ["该物品不具备独立占用座位的身份条件。"],
    footer: "电子章：基础馆失物身份登记。"
  }, [
    { target: "cc98-upload:bag_non_person_proof", result: "retain" },
    { target: "recovery-upload:bag_non_person_proof", result: "consume" }
  ]),
  seat022Receipt: paper({
    heading: "022 座位凭据",
    fields: [
      { label: "座位编号", value: "022" },
      { label: "区域", value: "二楼南区" },
      { label: "时间", value: "07:55" },
      { label: "凭据状态", value: "离座中 · 待公示" }
    ],
    body: ["当前占用物：书包。", "恢复处理需提交论坛公示。"],
    footer: "凭据来源：022 桌面夹缝。"
  }, [
    { target: "cc98-upload:seat_022_receipt", result: "retain" },
    { target: "recovery-upload:seat_022_receipt", result: "consume" }
  ]),
  libraryPresenceProof: paper({
    heading: "本人来过证明",
    fields: [
      { label: "到馆时长", value: "7 分钟" },
      { label: "公示编号", value: "47" },
      { label: "证明数量", value: "3" },
      { label: "记录状态", value: "补录成功" }
    ],
    body: ["访问轨迹与 022 座位凭据的时间记录一致。"],
    footer: "签发来源：浙大体艺访问记录补录。"
  }, [
    { target: "cc98-upload:library_presence_proof", result: "retain" },
    { target: "recovery-upload:library_presence_proof", result: "consume" }
  ]),
  seatReleasePass: paper({
    heading: "离座清退 PASS",
    fields: [
      { label: "适用座位", value: "022" },
      { label: "处理目标", value: "非本人占用书包" },
      { label: "有效状态", value: "单次有效" }
    ],
    body: ["已完成公开公示与三项恢复材料核验。"],
    footer: "仅对登记为非本人的占用物有效。"
  }, [{ target: "seat-022-backpack", result: "consume" }]),
  cafeteriaWages: object([{ target: "canteen-bike", result: "consume" }]),
  greaseTissue: object([
    { target: "canteen-bike-lock", result: "retain" },
    { target: "theater-poster-glass", result: "consume" }
  ]),
  sparklingWater: object([{ target: "canteen-mixer", result: "consume" }]),
  lemonTea: object([{ target: "canteen-mixer", result: "consume" }]),
  blackCoffee: object([{ target: "canteen-mixer", result: "consume" }]),
  badDrink: object([{ target: "rpg-player", result: "consume" }]),
  dailySpecialSparklingWater: object([{ target: "canteen-promo-board", result: "consume" }]),
  pickupTicket0755: paper({
    heading: "0755 取餐号",
    fields: [
      { label: "取餐号", value: "0755" },
      { label: "状态", value: "请取餐" }
    ],
    body: ["一张从点餐机吐出来的小票。"],
    footer: "它证明你认真排过队，也认真被骗进流程。"
  }, [{ target: "canteen-pickup-window-3", result: "consume" }]),
  canteenRealBun: object([]),
  canteenCluelessSoyMilk: object([]),
  canteenEdgeEgg: object([]),
  canteenUselessCongee: object([]),
  theaterTicketHalfA: object([{ target: "theaterTicketHalfB", result: "transform" }]),
  theaterTicketHalfB: object([{ target: "theaterTicketHalfA", result: "transform" }]),
  temporaryTheaterTicket: object([
    { target: "theater-ticket-gate", result: "retain" },
    { target: "theater-prop-scanner", result: "consume" }
  ]),
  theaterProgramOpening: object([{ target: "theater-light-console", result: "consume" }]),
  theaterProgramSpotlight: object([{ target: "theater-light-console", result: "consume" }]),
  theaterProgramFinale: object([{ target: "theater-light-console", result: "consume" }]),
  spotlightRemote: object([{ target: "theater-spotlight-console", result: "consume" }]),
  fluorescentBrush: object([{ target: "theater-backstage-vent", result: "consume" }]),
  decoyPaper: object([{ target: "fishingRod", result: "consume" }]),
  wetProgram: paper({
    heading: "湿掉的节目单",
    fields: [
      { label: "状态", value: "边角湿润" },
      { label: "来源", value: "剧院舞台" }
    ],
    body: [
      "纸条这次没有留下连续脚印。",
      "潮湿痕迹只能说明它经过了有水的地方。",
      "仍需从不同来源核对地点特征。"
    ],
    footer: "边角湿得很有方向感。"
  }, [
    { target: "cc98-search", result: "retain" },
    { target: "library-catalog-search", result: "retain" },
    { target: "qizhen-location-sources-complete", result: "consume" }
  ]),
  bridgeKeyword: object([{ target: "qizhen-map-search", result: "consume" }]),
  reflectionKeyword: object([{ target: "qizhen-map-search", result: "consume" }]),
  lakeKeyword: object([{ target: "qizhen-map-search", result: "consume" }]),
  reflectionCoordinate: paper({
    heading: "倒影坐标",
    fields: [
      { label: "暗色细节", value: "湖面左侧 / 桥影下方 / 亮点偏右" },
      { label: "浅色细节", value: "右侧路灯杆" }
    ],
    body: ["两种模式记录的是同一个位置。"],
    footer: "来源：启真湖倒影指示牌。"
  }, []),
  hairDryer: object([{ target: "qizhen-weather-clouds", result: "consume" }]),
  fishingRod: object([
    { target: "decoyPaper", result: "retain" },
    { target: "qizhen-net-frame", result: "retain" },
    { target: "swanMagnet", result: "transform" }
  ]),
  rustedLockerKey: object([{ target: "qizhen-dock-locker", result: "consume" }]),
  nylonCord: object([{ target: "brokenNetFrame", result: "transform" }]),
  brokenNetFrame: object([{ target: "nylonCord", result: "transform" }]),
  improvisedDipNet: object([{ target: "qizhen-feed-tin", result: "consume" }]),
  sealedFeedTin: object([{ target: "qizhen-feed-tin-lid", result: "consume" }]),
  fishFeedPellets: object([{ target: "qizhen-fish-school", result: "consume" }]),
  smallCarp: object([{ target: "qizhen-black-swan", result: "consume" }]),
  swanMagnet: object([{ target: "fishingRod", result: "transform" }]),
  magneticFishingRod: object([
    { target: "qizhen-clipped-paper", result: "retain" },
    { target: "qizhen-chase-finish", result: "consume" }
  ]),
  attendanceRecordPaper: paper({
    heading: "签到记录纸",
    fields: [
      { label: "状态", value: "待补全" },
      { label: "用途", value: "教学楼签到" }
    ],
    body: [
      "纸面记录停在 07:55 前后，签字栏还空着。",
      "它会暂时离开你的道具栏，但最后仍需要回到签到口。"
    ],
    footer: "边缘有多次折返留下的旧压痕。"
  }, [
    { target: "chapter4-noticeboard-paper", result: "retain" },
    { target: "chapter4-attendance-slot", result: "consume" }
  ]),
  oldClockHourHand: object([{ target: "chapter4-hall-clock-hour-hand-socket", result: "consume" }]),
  clockPositioningPlate: object([{ target: "chapter4-hall-clock-positioning-slot", result: "consume" }]),
  shortPryBar: object([{ target: "chapter4-cleaning-cart-wheel-cover", result: "consume" }]),
  universalLubricatingOil: object([
    { target: "chapter4-cleaning-cart-wheel", result: "retain" },
    { target: "chapter4-hall-clock-gear", result: "consume" }
  ]),
  finalMinute: paper({
    heading: "最后一分钟",
    fields: [
      { label: "来源", value: "202 阶梯教室投影" },
      { label: "状态", value: "待归位" }
    ],
    body: [
      "它是被偷走的最后一分钟，需要回到旧钟分针端点。",
      "归位后，手机与世界时间会重新对齐。"
    ],
    footer: "纸面的光影像一截被掰下来的时间。"
  }, [{ target: "chapter4-hall-clock-minute-endpoint", result: "consume" }])
};

export function isPaperItem(itemId: ItemId): boolean {
  return ITEM_CATALOG[itemId].inspectKind === "paper";
}
