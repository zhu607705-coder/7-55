import { useEffect, useId, useRef } from "react";
import { createPortal } from "react-dom";
import type { ItemId } from "../core/types";
import { ITEM_CATALOG } from "../data/itemCatalog";
import { ITEM_META, PixelIcon } from "./PixelIcon";

type ItemInspectVariant = "phone" | "rpg";

interface ItemInspectEntry {
  category: string;
  source: string;
  intro: string;
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
    intro: "证明你是你的卡。余额方面，它持保留意见。"
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
    intro: "能把什么东西往右移。它不解决问题，只负责让问题换个位置。"
  },
  gamepad: {
    category: "控制设备",
    source: "CC98 二手市场",
    intro: "二手市场六块钱购入。它让你终于可以操作自己，听起来很悲伤。"
  },
  occupancyNote: {
    category: "调查证据",
    source: "图书馆 022 座位旁",
    intro: "022 座位旁留下的一张纸条。它声称主人只离开三分钟，但纸张老化程度不支持这个说法。"
  },
  callNumber755: {
    category: "检索线索",
    source: "浙大钉馆藏检索结果",
    intro: "一串看起来属于书架、实际上更像咒语的编号。图书馆用它证明“你找不到”也是一种服务。"
  },
  archivedLeaveRule: {
    category: "公开证据",
    source: "图书馆 755 书架夹层",
    intro: "一份已经过期但仍然有效的规则。它最大的优点是没人敢确认它无效。"
  },
  itemRecognitionReport: {
    category: "机器报告",
    source: "照片识别结果",
    intro: "它很沉重，但不是法律意义上的同学。"
  },
  bagNonPersonProof: {
    category: "认证证明",
    source: "失物身份登记机盖章",
    intro: "一份郑重证明。它没有姓名，没有学号，但有很强的占用欲。"
  },
  seat022Receipt: {
    category: "座位凭据",
    source: "022 桌面夹缝",
    intro: "从桌下夹缝里推出的凭据。它皱得像经历过一次完整的期末周。"
  },
  libraryPresenceProof: {
    category: "到场证明",
    source: "浙大体艺访问记录",
    intro: "一张证明你来过的证明。它没有证明你为什么要来。"
  },
  seatReleasePass: {
    category: "执行凭证",
    source: "022 恢复申请签发",
    intro: "仅对非本人书包有效。如书包已进化为本人，请联系下一章。"
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
  const titleId = useId();
  const descId = useId();
  const metaId = useId();
  const entry = ITEM_INSPECT_META[itemId];
  const item = ITEM_META[itemId];
  const itemDocument = ITEM_CATALOG[itemId].document;

  useEffect(() => {
    const previousFocus = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    closeButtonRef.current?.focus();

    function handleKeyDown(event: KeyboardEvent) {
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
        className={`item-inspect-dialog item-inspect-dialog--${variant}`}
        role="dialog"
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
          <p id={descId}>{item.desc}</p>
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
            <div className="item-inspect-row">
              <dt>简介</dt>
              <dd>{entry.intro}</dd>
            </div>
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
