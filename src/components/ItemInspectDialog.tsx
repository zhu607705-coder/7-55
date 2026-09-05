import { useEffect, useId, useRef } from "react";
import { createPortal } from "react-dom";
import type { ItemId } from "../core/types";
import { ITEM_CATALOG } from "../data/itemCatalog";
import { gameStore } from "../core/GameState";
import { selectIdentityReadable } from "../core/IdentityAccess";
import actOneContent from "../data/act-one-bootstrap.content.json";
import { ITEM_META, PixelIcon } from "./PixelIcon";

type ItemInspectVariant = "phone" | "rpg";

interface ItemInspectEntry {
  category: string;
  source: string;
  useHint?: string;
}

const THEATER_PROGRAM_FLUORESCENT_ORDER: Partial<Record<ItemId, 1 | 2 | 3>> = {
  theaterProgramSpotlight: 1,
  theaterProgramOpening: 2,
  theaterProgramFinale: 3
};

export interface ItemInspectDialogProps {
  open: boolean;
  itemId: ItemId | null;
  variant?: ItemInspectVariant;
  portalRoot?: Element | null;
  onClose: () => void;
}

export const ITEM_INSPECT_META: Record<ItemId, ItemInspectEntry> = {
  waterDrop: {
    category: "环境材料",
    source: "主屏早八雨滴",
  },
  headphone: {
    category: "容器素材",
    source: "控制中心音乐模块",
  },
  wateredHeadphone: {
    category: "合成道具",
    source: "耳机 + 水滴",
  },
  reverseGear: {
    category: "机械素材",
    source: "主屏设置齿轮背面",
  },
  slashLine: {
    category: "图形素材",
    source: "朋友头像掉落的一撇",
  },
  towerKey: {
    category: "解锁工具",
    source: "斜线 + 反转齿轮",
  },
  fertilizer: {
    category: "植物材料",
    source: "塔楼机关奖励",
  },
  campusCard: {
    category: "身份凭证",
    source: "寝室右侧书桌 / 电子校园卡",
  },
  pushTriangle: {
    category: "图形素材",
    source: "主页推送头像",
  },
  weatherWater: {
    category: "功能材料",
    source: "天气页面",
  },
  mentorLine: {
    category: "图形素材",
    source: "导师头像掉落的一竖",
  },
  rightArrow: {
    category: "位移工具",
    source: "三角形 + 竖线",
  },
  gamepad: {
    category: "控制设备",
    source: "CC98 二手市场",
  },
  occupancyNote: {
    category: "调查证据",
    source: "图书馆 022 座位旁",
  },
  callNumber755: {
    category: "检索线索",
    source: "浙大钉馆藏检索结果",
  },
  archivedLeaveRule: {
    category: "公开证据",
    source: "图书馆 755 书架夹层",
  },
  itemRecognitionReport: {
    category: "机器报告",
    source: "照片识别结果",
  },
  bagNonPersonProof: {
    category: "认证证明",
    source: "物品身份盖章机",
  },
  seat022Receipt: {
    category: "座位凭据",
    source: "022 桌面夹缝",
  },
  libraryPresenceProof: {
    category: "到场证明",
    source: "浙大体艺访问记录",
  },
  seatReleasePass: {
    category: "执行凭证",
    source: "022 恢复申请签发",
  },
  cafeteriaWages: {
    category: "餐盘回收费 2.00 元",
    source: "餐盘回收",
  },
  greaseTissue: {
    category: "油渍纸巾",
    source: "食堂收餐口阿姨",
  },
  sparklingWater: {
    category: "调配原料 · 蓝色",
    source: "食堂饮料区",
  },
  lemonTea: {
    category: "调配原料 · 白色",
    source: "食堂饮料区",
  },
  blackCoffee: {
    category: "调配原料 · 黑色",
    source: "食堂饮料区",
  },
  badDrink: {
    category: "失败饮品",
    source: "食堂混合台",
    useHint: "可以自己喝掉。试饮杯位不收这一杯。"
  },
  dailySpecialSparklingWater: {
    category: "今日新品",
    source: "食堂混合台",
    useHint: "宣传板下空着一个杯位。洒出的泡沫有些黏。"
  },
  pickupTicket0755: {
    category: "0755 取餐号",
    source: "点餐机",
  },
  canteenRealBun: { category: "餐品", source: "食堂取餐窗口" },
  canteenCluelessSoyMilk: { category: "餐品", source: "食堂取餐窗口" },
  canteenEdgeEgg: { category: "餐品", source: "食堂取餐窗口" },
  canteenUselessCongee: { category: "餐品", source: "食堂取餐窗口" },
  theaterTicketHalfA: {
    category: "半张剧院票根 A",
    source: "剧院海报栏",
  },
  theaterTicketHalfB: {
    category: "半张剧院票根 B",
    source: "剧院取票机",
  },
  temporaryTheaterTicket: {
    category: "临时观演票",
    source: "两张半票根",
  },
  theaterProgramOpening: {
    category: "节目单残页",
    source: "剧院座席",
  },
  theaterProgramSpotlight: {
    category: "节目单残页",
    source: "剧院座席",
  },
  theaterProgramFinale: {
    category: "节目单残页",
    source: "剧院座席",
  },
  spotlightRemote: {
    category: "追光灯遥控器",
    source: "剧院灯控台",
  },
  fluorescentBrush: {
    category: "荧光粉刷",
    source: "后台道具箱",
  },
  decoyPaper: {
    category: "假纸条",
    source: "剧院追光灯下",
    useHint: "纸角能穿过鱼钩，泡过水后仍能保持形状。"
  },
  wetProgram: {
    category: "湿掉的节目单",
    source: "剧院舞台",
  },
  bridgeKeyword: {
    category: "地点关键词",
    source: "CC98 目击回复",
  },
  reflectionKeyword: {
    category: "地点关键词",
    source: "图书馆馆藏状态",
  },
  lakeKeyword: {
    category: "地点关键词",
    source: "微信朋友消息",
  },
  reflectionCoordinate: {
    category: "场景坐标",
    source: "启真湖指示牌",
  },
  hairDryer: {
    category: "寝室电器",
    source: "个人书桌",
    useHint: "天气页面的云带会随风偏移。风向可以试着控制。"
  },
  fishingRod: {
    category: "湖面工具",
    source: "启真湖浮排边",
    useHint: "竿梢和鱼钩都在，钓线末端还能系东西。"
  },
  rustedLockerKey: {
    category: "解锁工具",
    source: "启真湖开放水域钓点",
    useHint: "钥匙齿口较粗，适合码头那种旧锁。"
  },
  nylonCord: {
    category: "修复材料",
    source: "启真湖码头储物柜",
    useHint: "耐水，能穿过金属框边缘的小孔。"
  },
  brokenNetFrame: {
    category: "修复材料",
    source: "启真湖开放水域钓点",
    useHint: "框架没散，边缘还留着穿线孔。"
  },
  improvisedDipNet: {
    category: "打捞工具",
    source: "尼龙绳 + 断裂网框",
    useHint: "网口比罐子宽，网兜能承重。"
  },
  sealedFeedTin: {
    category: "密封容器",
    source: "启真湖水下打捞点",
    useHint: "罐盖边缘有缝，徒手打不开。"
  },
  fishFeedPellets: {
    category: "投喂材料",
    source: "密封饲料罐",
    useHint: "少量颗粒落水后，附近的鱼会游过来。"
  },
  smallCarp: {
    category: "渔获",
    source: "启真湖鱼群钓点",
    useHint: "黑天鹅一直盯着这条鱼。"
  },
  swanMagnet: {
    category: "磁吸附件",
    source: "启真湖黑天鹅",
    useHint: "磁扣后面留有穿线孔。"
  },
  magneticFishingRod: {
    category: "组合工具",
    source: "钓竿 + 天鹅磁铁",
    useHint: "线末端能吸住小金属件，纸本身不导磁。"
  },
  attendanceRecordPaper: {
    category: "签到材料",
    source: "教学楼公告栏前",
    useHint: "纸幅与签到槽相同，空栏还留着。"
  },
  oldClockHourHand: {
    category: "钟表部件",
    source: "面包店传送带边缘",
    useHint: "尾部方孔与大厅旧钟的轴头一致。"
  },
  clockPositioningPlate: {
    category: "钟表部件",
    source: "204 讲台抽屉",
    useHint: "盘边的缺口与旧钟轴座对应。"
  },
  shortPryBar: {
    category: "维修工具",
    source: "面包店后场",
    useHint: "扁头能插入薄金属盖板的缝。"
  },
  universalLubricatingOil: {
    category: "维修材料",
    source: "清洁车内侧",
    useHint: "适用于卡涩的轮轴和齿轮。"
  },
  finalMinute: {
    category: "钟表部件",
    source: "202 阶梯教室座椅间",
    useHint: "分针底部的接口仍完整。大厅旧钟缺的就是这一件。"
  }
};

function ItemInspectDialogBody({
  itemId,
  onClose,
  variant
}: {
  itemId: ItemId;
  onClose: () => void;
  variant: ItemInspectVariant;
}) {
  const closeButtonRef = useRef<HTMLButtonElement>(null);
  const dialogRef = useRef<HTMLElement>(null);
  const titleId = useId();
  const descId = useId();
  const metaId = useId();
  const entry = ITEM_INSPECT_META[itemId];
  const item = ITEM_META[itemId];
  const itemDocument = ITEM_CATALOG[itemId].document;
  const state = gameStore.getState();
  const identityReadable = selectIdentityReadable(state);
  const campusCardHolder = itemId === "campusCard" && identityReadable
    ? `${actOneContent.studentName} · ${actOneContent.studentId}`
    : null;
  const fluorescentOrder = variant === "rpg"
    && state.runtimeMode === "rpg"
    && state.rpgScene === "theater_interior"
    && state.theaterHunt.active
    && state.theaterHunt.phase === "program_search"
    && state.theaterHunt.mode === "dark"
    ? THEATER_PROGRAM_FLUORESCENT_ORDER[itemId] ?? null
    : null;

  useEffect(() => {
    const previousFocus = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    closeButtonRef.current?.focus();

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === "Tab") {
        const dialog = dialogRef.current;
        if (!dialog) return;
        const focusable = Array.from(dialog.querySelectorAll<HTMLElement>(
          'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
        )).filter((element) => element.getClientRects().length > 0);
        if (focusable.length === 0) {
          event.preventDefault();
          dialog.focus();
          return;
        }
        const currentIndex = focusable.indexOf(document.activeElement as HTMLElement);
        const nextIndex = event.shiftKey
          ? currentIndex <= 0 ? focusable.length - 1 : currentIndex - 1
          : currentIndex === -1 || currentIndex === focusable.length - 1 ? 0 : currentIndex + 1;
        event.preventDefault();
        focusable[nextIndex].focus();
        return;
      }
      if (event.key !== "Escape") {
        return;
      }
      event.preventDefault();
      onClose();
    }

    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
      previousFocus?.focus();
    };
  }, [onClose]);

  return (
    <div
      className={`item-inspect-backdrop item-inspect-backdrop--${variant}`}
      role="presentation"
      onClick={(event) => {
        if (event.target === event.currentTarget) {
          onClose();
        }
      }}
    >
      <section
        ref={dialogRef}
        className={`item-inspect-dialog item-inspect-dialog--${variant} ${itemId === "hairDryer" ? "item-inspect-dialog--large-preview" : ""}`.trim()}
        data-item-id={itemId}
        role="dialog"
        tabIndex={-1}
        aria-modal="true"
        aria-labelledby={titleId}
        aria-describedby={`${descId} ${metaId}`}
      >
        <div className="item-inspect-corner" aria-hidden="true">
          <i />
          <i />
          <i />
          <i />
        </div>
        <button
          ref={closeButtonRef}
          type="button"
          className="item-inspect-close"
          aria-label={`关闭${item.name}详情`}
          onClick={onClose}
        >
          ×
        </button>
        <header className="item-inspect-header">
          <span className="item-inspect-badge">{variant === "phone" ? "PHONE" : "RPG"}</span>
          <h2 id={titleId}>{item.name}</h2>
        </header>
        <div className="item-inspect-body">
          <div className="item-inspect-icon-frame" aria-hidden="true">
            <PixelIcon
              name={itemId}
              size={itemId === "hairDryer" ? (variant === "phone" ? 96 : 128) : (variant === "phone" ? 58 : 72)}
            />
          </div>
          <dl id={metaId} className="item-inspect-meta">
            <div className="item-inspect-row">
              <dt>分类</dt>
              <dd>{entry.category}</dd>
            </div>
            <div className="item-inspect-row">
              <dt>来源</dt>
              <dd>{entry.source}</dd>
            </div>
            {campusCardHolder ? (
              <div className="item-inspect-row">
                <dt>持卡人</dt>
                <dd>{campusCardHolder}</dd>
              </div>
            ) : null}
            <div className="item-inspect-row">
              <dt>简介</dt>
              <dd id={descId}>
                {item.desc}
                {fluorescentOrder ? (
                  <span className="item-inspect-fluorescent-order">顺序：{fluorescentOrder}</span>
                ) : null}
              </dd>
            </div>
            {entry.useHint ? (
              <div className="item-inspect-row">
                <dt>用途提示</dt>
                <dd>{entry.useHint}</dd>
              </div>
            ) : null}
          </dl>
        </div>
        {itemDocument ? (
          <article className="item-document" aria-label={`${item.name}正文`} tabIndex={0}>
            <header>
              <small>DOCUMENT</small>
              <h3>{itemDocument.heading}</h3>
            </header>
            <dl>
              {itemDocument.fields.map((field) => (
                <div key={field.label}>
                  <dt>{field.label}</dt>
                  <dd>{field.value}</dd>
                </div>
              ))}
            </dl>
            <section>
              {itemDocument.body.map((line) => <p key={line}>{line}</p>)}
            </section>
            {itemDocument.footer ? <footer>{itemDocument.footer}</footer> : null}
          </article>
        ) : null}
      </section>
    </div>
  );
}

export function ItemInspectDialog({
  open,
  itemId,
  variant = "phone",
  portalRoot,
  onClose
}: ItemInspectDialogProps) {
  if (!open || !itemId || typeof document === "undefined") {
    return null;
  }

  return createPortal(
    <ItemInspectDialogBody itemId={itemId} onClose={onClose} variant={variant} />,
    portalRoot ?? document.body
  );
}
