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
    intro: "耳机背面的空腔里留着一小份水，液体没有继续渗出。"
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
    intro: "三份材料已经换成临时处置权限，凭证对应基础馆二层南区 022。"
  },
  cafeteriaWages: {
    category: "餐盘回收费 2.00 元",
    source: "餐盘回收",
    intro: "收回三只目标餐盘得到的两元钱，可支付一次扫码骑车。"
  },
  greaseTissue: {
    category: "油渍纸巾",
    source: "食堂桌面",
    intro: "收餐口阿姨给的油渍纸巾，可擦掉车锁和海报玻璃上的反光。"
  },
  sparklingWater: {
    category: "调配原料 · 蓝色",
    source: "食堂饮料区",
    intro: "蓝色饮料原料。与黑咖啡、柠檬茶按货架顺序调配。"
  },
  lemonTea: {
    category: "调配原料 · 白色",
    source: "食堂饮料区",
    intro: "白色饮料原料。查看货架颜色顺序后放进混合台。"
  },
  blackCoffee: {
    category: "调配原料 · 黑色",
    source: "食堂饮料区",
    intro: "黑色饮料原料。按货架顺序放进混合台。"
  },
  badDrink: {
    category: "失败饮品",
    source: "食堂混合台",
    intro: "混错顺序得到的饮料。可以喝掉，不能推进任务。",
    useHint: "在食堂 RPG 中拖到自己身上可以喝掉。"
  },
  dailySpecialSparklingWater: {
    category: "今日新品",
    source: "食堂混合台",
    intro: "拖到第三窗口宣传板的空杯位。守出口时可在地面留两秒减速气泡。",
    useHint: "先拖到第三个餐口宣传板空杯位；守出口时可再拖进食堂地面减速纸条。"
  },
  pickupTicket0755: {
    category: "0755 取餐号",
    source: "点餐机",
    intro: "点餐机打印的取餐小票。切到深色模式，交给 3 号窗口残影阿姨。"
  },
  canteenRealBun: { category: "食堂彩蛋", source: "1号取餐窗口", intro: "从窗口领到的包子。正常，且没有纸条线索。" },
  canteenCluelessSoyMilk: { category: "食堂彩蛋", source: "2号取餐窗口", intro: "从窗口领到的豆浆。此时没有其他用途。" },
  canteenEdgeEgg: { category: "食堂彩蛋", source: "4号取餐窗口", intro: "从窗口领到的鸡蛋。此时没有其他用途。" },
  canteenUselessCongee: { category: "食堂彩蛋", source: "5号取餐窗口", intro: "从窗口领到的白粥。烫手，且没有其他用途。" },
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
    useHint: "可安装到钓竿上作为诱饵，装饵成功后会消耗"
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
  },
  fishingRod: {
    category: "湖面工具",
    source: "启真湖码头装备架",
    intro: "竿梢保留了附件连接位。先在深色观察中记录目标，再在浅色操作中抛竿。",
    useHint: "可安装诱饵、钓取水面物品，或与磁铁组合"
  },
  rustedLockerKey: {
    category: "解锁工具",
    source: "启真湖开放水域钓点",
    intro: "钥匙表面的锈蚀和码头储物柜锁孔一致。",
    useHint: "靠近码头储物柜后拖入锁孔"
  },
  nylonCord: {
    category: "修复材料",
    source: "启真湖码头储物柜",
    intro: "耐水绳结仍然完整，长度适合重新固定一圈网框。",
    useHint: "与缺少网面的框架组合"
  },
  brokenNetFrame: {
    category: "修复材料",
    source: "启真湖开放水域钓点",
    intro: "框架仍可承重，固定网面的绳索已经脱落。",
    useHint: "与耐水绳索组合"
  },
  improvisedDipNet: {
    category: "打捞工具",
    source: "尼龙绳 + 断裂网框",
    intro: "网框已经恢复封闭，可承托钓钩难以稳定带回的物品。",
    useHint: "在浅色操作中拖向已观察的水下罐体"
  },
  sealedFeedTin: {
    category: "密封容器",
    source: "启真湖水下打捞点",
    intro: "罐盖仍然密封，摇动时能听到细小颗粒碰撞。",
    useHint: "返回安全位置后打开罐盖"
  },
  fishFeedPellets: {
    category: "投喂材料",
    source: "密封饲料罐",
    intro: "颗粒遇水后会缓慢下沉，可让鱼群在短时间内集中。",
    useHint: "在已观察的鱼群位置使用"
  },
  smallCarp: {
    category: "活体诱导物",
    source: "启真湖鱼群钓点",
    intro: "小鲤鱼仍有活性，需要尽快完成当前湖区操作。",
    useHint: "靠近黑天鹅后进行投喂"
  },
  swanMagnet: {
    category: "磁吸附件",
    source: "启真湖黑天鹅",
    intro: "小型磁铁的固定环与钓竿末端尺寸一致。",
    useHint: "与基础钓竿组合"
  },
  magneticFishingRod: {
    category: "组合工具",
    source: "钓竿 + 天鹅磁铁",
    intro: "磁吸附件可接近金属夹具，同时保留钓竿的距离优势。",
    useHint: "用于捕获被夹住的纸张；返航完成后附件会损坏"
  },
  attendanceRecordPaper: {
    category: "签到材料",
    source: "教学楼公告栏前",
    intro: "这张纸先把你引回了楼里，最后也得由你把它送回签到口。",
    useHint: "晨间签到阶段拖向签到纸槽"
  },
  oldClockHourHand: {
    category: "钟表部件",
    source: "面包店传送带边缘",
    intro: "真正能推进时间的不是灯光，而是停带后露出来的这根旧钟时针。",
    useHint: "返回一楼旧钟，将它拖向时针插槽"
  },
  clockPositioningPlate: {
    category: "钟表部件",
    source: "204 讲台抽屉",
    intro: "它不是普通零件，而是让旧钟重新对准正确结构的定位盘。",
    useHint: "返回一楼旧钟，将它拖向定位盘插槽"
  },
  shortPryBar: {
    category: "维修工具",
    source: "面包店后场",
    intro: "长度不大，刚好适合翘开清洁车轮罩。",
    useHint: "拖向清洁车轮罩"
  },
  universalLubricatingOil: {
    category: "维修材料",
    source: "清洁车内侧",
    intro: "先用它让清洁车恢复，再把剩下的半瓶交给旧钟齿轮。",
    useHint: "先拖向清洁车轮，再拖向旧钟齿轮"
  },
  finalMinute: {
    category: "时间碎片",
    source: "202 阶梯教室投影",
    intro: "这是一段被偷走的最后一分钟。它只能回到旧钟分针端点。",
    useHint: "拖向旧钟分针端点，恢复 07:55"
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
