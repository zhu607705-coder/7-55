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
  intro: string;
  useHint?: string;
}

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
    intro: "一滴不够浇花。某件翻到背面的随身设备，刚好留着一个空腔。"
  },
  headphone: {
    category: "容器素材",
    source: "控制中心音乐模块",
    intro: "正面负责声音，背面留着凹处。那一点空位还没有装东西。"
  },
  wateredHeadphone: {
    category: "合成道具",
    source: "耳机 + 水滴",
    intro: "液体和容器已经齐了。接下来找一株始终没开花的植物。"
  },
  reverseGear: {
    category: "机械素材",
    source: "主屏设置齿轮背面",
    intro: "数字藏在背面，齿形留在边缘。若再接上一段斜线，轮廓会更完整。"
  },
  slashLine: {
    category: "图形素材",
    source: "朋友头像掉落的一撇",
    intro: "单独看只是一撇。某个带齿的圆形部件缺少一段细长结构。"
  },
  towerKey: {
    category: "解锁工具",
    source: "斜线 + 反转齿轮",
    intro: "轮廓已经完整。主屏高处有一处尺寸相近、一直没有作用的圆孔。"
  },
  fertilizer: {
    category: "植物材料",
    source: "塔楼机关奖励",
    intro: "水、光、土壤养分，顺序可以不同，三项都要留下痕迹。"
  },
  campusCard: {
    category: "身份凭证",
    source: "寝室右侧书桌 / 电子校园卡",
    intro: "姓名和学号用于身份核验；余额与校园服务会在后续流程中继续使用。"
  },
  pushTriangle: {
    category: "图形素材",
    source: "主页推送头像",
    intro: "尖端已经给出方向，尾部仍少一条笔直的结构。"
  },
  weatherWater: {
    category: "功能材料",
    source: "天气页面",
    intro: "水量很少，浇花显得勉强。某张头像边缘的连接处只需要一点湿润。"
  },
  mentorLine: {
    category: "图形素材",
    source: "导师头像掉落的一竖",
    intro: "长度和方向都合适；某个只有尖端的图形还缺它。"
  },
  rightArrow: {
    category: "位移工具",
    source: "三角形 + 竖线",
    intro: "它只规定向右，不规定对象。写着数的、夹在缝里的，都属于可尝试范围。"
  },
  gamepad: {
    category: "控制设备",
    source: "CC98 二手市场",
    intro: "自动行走解决了会不会走；四个方向才能决定往哪里走。"
  },
  occupancyNote: {
    category: "调查证据",
    source: "图书馆 022 座位旁",
    intro: "纸上写了离开时长和占位理由。原句放进公开讨论区，更容易找到相同说法。"
  },
  callNumber755: {
    category: "检索线索",
    source: "浙大钉馆藏检索结果",
    intro: "这串数字不回答问题，只标记位置。书架边缘会出现同样的编号。"
  },
  archivedLeaveRule: {
    category: "公开证据",
    source: "图书馆 755 书架夹层",
    intro: "发布日期很旧，适用范围仍值得核对。公开讨论需要能查到出处的文字。"
  },
  itemRecognitionReport: {
    category: "机器报告",
    source: "照片识别结果",
    intro: "它确认了画面里的物品，身份一栏仍为空。校园里有个地方专门补这一栏。"
  },
  bagNonPersonProof: {
    category: "认证证明",
    source: "物品身份盖章机",
    intro: "一条错误等号已经被排除，座位归属仍未说明。单独提交会缺少另外两类材料。"
  },
  seat022Receipt: {
    category: "座位凭据",
    source: "022 桌面夹缝",
    intro: "编号能对应座位，时间要与另一份到场记录互相核对。"
  },
  libraryPresenceProof: {
    category: "到场证明",
    source: "浙大体艺访问记录",
    intro: "它只回答人是否到过那里，座位归属还要交给另一张凭据。"
  },
  seatReleasePass: {
    category: "执行凭证",
    source: "022 恢复申请签发",
    intro: "材料已经换成临时处置权限。回到那件长期占着位置、现场却找不到主人的物品旁。"
  },
  cafeteriaWages: {
    category: "餐盘回收费 2.00 元",
    source: "餐盘回收",
    intro: "你通过劳动获得的两块钱。听起来像人生开始出问题的地方。"
  },
  greaseTissue: {
    category: "油渍纸巾",
    source: "食堂桌面",
    intro: "擦过食堂桌面的纸巾。它现在拥有轻微的反光治理能力。"
  },
  pickupTicket0755: {
    category: "0755 取餐号",
    source: "点餐机",
    intro: "一张从点餐机吐出来的小票。它证明纸条曾经认真地排过队。"
  },
  theaterTicketHalfA: {
    category: "半张剧院票根 A",
    source: "剧院海报栏",
    intro: "它证明你的一半可以进场，另一半还在流程里。"
  },
  theaterTicketHalfB: {
    category: "半张剧院票根 B",
    source: "剧院取票机",
    intro: "来自一台失败的取票机。它至少努力过。"
  },
  temporaryTheaterTicket: {
    category: "临时观演票",
    source: "两张半票根",
    intro: "两张半真半假的票根拼出来的票。剧院看了都沉默了一秒。"
  },
  theaterProgramOpening: {
    category: "节目单残页",
    source: "剧院座席",
    intro: "普通节目单，看起来很会假装正式。"
  },
  theaterProgramSpotlight: {
    category: "节目单残页",
    source: "剧院座席",
    intro: "普通节目单，看起来很会假装正式。"
  },
  theaterProgramFinale: {
    category: "节目单残页",
    source: "剧院座席",
    intro: "普通节目单，看起来很会假装正式。"
  },
  spotlightRemote: {
    category: "追光灯遥控器",
    source: "剧院灯控台",
    intro: "能让舞台中央变亮。也能让逃避责任的纸条短暂接受审判。"
  },
  fluorescentBrush: {
    category: "荧光粉刷",
    source: "后台道具箱",
    intro: "刷过之后，连借口都会发光。"
  },
  decoyPaper: {
    category: "假纸条",
    source: "剧院追光灯下",
    intro: "长得很像目标，但态度没那么差。",
    useHint: "可以制造一次错误目标"
  },
  wetProgram: {
    category: "湿掉的节目单",
    source: "剧院舞台",
    intro: "纸条逃跑时留下的节目单，边角湿得很有方向感。"
  },
  bridgeKeyword: {
    category: "地点关键词",
    source: "CC98 目击回复",
    intro: "目击者只确认了桥附近，仍不足以确定具体地点。"
  },
  reflectionKeyword: {
    category: "地点关键词",
    source: "图书馆馆藏状态",
    intro: "异常页码只出现在水面反射区域。"
  },
  lakeKeyword: {
    category: "地点关键词",
    source: "微信朋友消息",
    intro: "群聊只留下了一个不完整的湖名。"
  },
  reflectionCoordinate: {
    category: "场景坐标",
    source: "启真湖指示牌",
    intro: "深浅两种观察结果共同指向右侧路灯杆。"
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
  const identityReadable = selectIdentityReadable(gameStore.getState());
  const campusCardHolder = itemId === "campusCard" && identityReadable
    ? `${actOneContent.studentName} · ${actOneContent.studentId}`
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
        className={`item-inspect-dialog item-inspect-dialog--${variant}`}
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
            <PixelIcon name={itemId} size={variant === "phone" ? 58 : 72} />
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
              <dd id={descId}>{item.desc}</dd>
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
