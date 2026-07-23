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
    { target: "seat-022-gap", result: "retain" }
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
    body: ["检测到大量期末周使用痕迹。", "身份结论需由馆内物品登记机确认。"],
    footer: "报告状态：待盖章。"
  }, [{ target: "lost-found-machine", result: "transform" }]),
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
  greaseTissue: object([{ target: "canteen-bike-lock", result: "retain" }]),
  pickupTicket0755: paper({
    heading: "0755 取餐号",
    fields: [
      { label: "取餐号", value: "0755" },
      { label: "状态", value: "请取餐" }
    ],
    body: ["取纸不取餐，找纸不找饭。"],
    footer: "一张从点餐机吐出来的小票。"
  }, [{ target: "canteen-pickup-window-3", result: "consume" }])
};

export function isPaperItem(itemId: ItemId): boolean {
  return ITEM_CATALOG[itemId].inspectKind === "paper";
}
