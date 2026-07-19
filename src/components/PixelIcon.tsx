import type { ItemId } from "../core/types";
import actOneContent from "../data/act-one-bootstrap.content.json";

/**
 * 字符画 → SVG 像素图标。
 * 每个图标是一组字符串行，字符映射到调色板颜色，"." 为透明。
 */
type PixelMap = { rows: string[]; palette: Record<string, string> };

const ICONS: Record<string, PixelMap> = {
  waterDrop: {
    rows: [
      "....b....",
      "....b....",
      "...bwb...",
      "..bwwlb..",
      ".bwwllb..",
      ".bwlllb..",
      "bwllllsb.",
      "bwlllssb.",
      ".bllssb..",
      "..bbbb..."
    ],
    palette: { b: "#1d3f8f", w: "#cfe8ff", l: "#6aa8df", s: "#4d7ed9" }
  },
  headphone: {
    // 背面朝下的耳机：倒 U 形，像个小水瓢
    rows: [
      "k.......k",
      "kk.....kk",
      "gkk...kkg",
      "ggk...kgg",
      "ggk...kgg",
      ".kk...kk.",
      ".k.....k.",
      ".kkkkkkk.",
      "..kkkkk..",
      "........."
    ],
    palette: { k: "#222322", g: "#c85454" }
  },
  wateredHeadphone: {
    // 盛了水的耳机
    rows: [
      "k.......k",
      "kk.....kk",
      "gkk.b.kkg",
      "ggk.w.kgg",
      "ggkblbkgg",
      ".kkblbkk.",
      ".k.blb.k.",
      ".kkkkkkk.",
      "..kkkkk..",
      "........."
    ],
    palette: { k: "#222322", g: "#c85454", b: "#1d3f8f", l: "#6aa8df", w: "#cfe8ff" }
  },
  reverseGear: {
    rows: [
      "..g..g...",
      ".ggggggg.",
      "g.ggggg.g",
      ".gg...gg.",
      "ggg.y.ggg",
      ".gg...gg.",
      "g.ggggg.g",
      ".ggggggg.",
      "..g..g...",
      "........."
    ],
    palette: { g: "#777989", y: "#f5c542" }
  },
  slashLine: {
    rows: [
      ".......ii",
      "......ii.",
      ".....ii..",
      "....ii...",
      "...ii....",
      "..ii.....",
      ".ii......",
      "ii.......",
      "i........",
      "........."
    ],
    palette: { i: "#31435f" }
  },
  towerKey: {
    // 齿轮是柄，斜线是杆
    rows: [
      ".gg......",
      "gyyg.....",
      "gy.yg....",
      "gyyg.....",
      ".gg.i....",
      "....ii...",
      ".....ii..",
      "......iii",
      ".......ii",
      "........."
    ],
    palette: { g: "#777989", y: "#f5c542", i: "#31435f" }
  },
  fertilizer: {
    rows: [
      "...pp....",
      "..pggp...",
      ".bbbbbb..",
      ".buubbb..",
      "bbubbubb.",
      "bbbbbbbb.",
      "bbubbubb.",
      "bbbbbbbb.",
      ".bbbbbb..",
      "........."
    ],
    palette: { b: "#a2793f", u: "#7c5a2a", p: "#61b58c", g: "#4c8f66" }
  },
  campusCard: {
    rows: [
      "bbbbbbbbb",
      "bwwwwwwwb",
      "bwpppwwwb",
      "bwpppwwwb",
      "bwwwwwwwb",
      "bkkkkkkkb",
      "bwkwkwkwb",
      "bkkkkkkkb",
      "bbbbbbbbb",
      "........."
    ],
    palette: { b: "#185ba8", w: "#f3f7f5", p: "#71b6a0", k: "#26313b" }
  },
  pushTriangle: {
    rows: [
      ".........",
      "..r......",
      "..rr.....",
      "..rrr....",
      "..rrrr...",
      "..rrr....",
      "..rr.....",
      "..r......",
      ".........",
      "........."
    ],
    palette: { r: "#d84545" }
  },
  weatherWater: {
    rows: [
      "....c....",
      "...ccc...",
      "...cwc...",
      "..cwwwc..",
      "..cwlwc..",
      ".cwwllwc.",
      ".cwwllwc.",
      "..clllc..",
      "...ccc...",
      "........."
    ],
    palette: { c: "#1d6ea3", w: "#d9f4ff", l: "#63b9dd" }
  },
  mentorLine: {
    rows: [
      "....k....",
      "....k....",
      "....k....",
      "....k....",
      "....k....",
      "....k....",
      "....k....",
      "....k....",
      "....k....",
      "........."
    ],
    palette: { k: "#33425f" }
  },
  rightArrow: {
    rows: [
      ".........",
      ".....r...",
      "......r..",
      "kkkkkkkr.",
      "kkkkkkkkr",
      "kkkkkkkr.",
      "......r..",
      ".....r...",
      ".........",
      "........."
    ],
    palette: { k: "#33425f", r: "#d84545" }
  },
  gamepad: {
    rows: [
      ".........",
      "..kkkkk..",
      ".kgggggk.",
      "kgggggggk",
      "kgkkggygk",
      "kggkggygg",
      ".kgggggk.",
      ".kk...kk.",
      "k.......k",
      "........."
    ],
    palette: { k: "#1b2430", g: "#4774b8", y: "#f0d54e" }
  },
  occupancyNote: {
    rows: [
      "kkkkkkkkk",
      "kwwwwwwwk",
      "kwwkkkwwk",
      "kwwwwwwwk",
      "kwwkkwwwk",
      "kwwwwwffk",
      "kwwwwfffk",
      "kwwfffffk",
      "kkkkkkkkk",
      "........."
    ],
    palette: { k: "#27313d", w: "#f1ead7", f: "#c7b58c" }
  },
  callNumber755: {
    rows: [
      "bbbbbbbbb",
      "bwwwwwwwb",
      "bwkkwkkwb",
      "bwwkwkwwb",
      "bwkkwkkwb",
      "bwwwwwwwb",
      "bwywyywwb",
      "bwwwwwwwb",
      "bbbbbbbbb",
      "........."
    ],
    palette: { b: "#1f5ea8", w: "#f6f0dc", k: "#26313b", y: "#e5b64e" }
  },
  archivedLeaveRule: {
    rows: [
      "..kkkk...",
      ".kyyyyyk.",
      "kyyrrryyk",
      "kyyyyyyyk",
      "kyykkkyyk",
      "kyyyyyyyk",
      "kyykkkyyk",
      ".kyyyyyk.",
      "..kkkk...",
      "........."
    ],
    palette: { k: "#463728", y: "#d8bd79", r: "#a64d3d" }
  },
  itemRecognitionReport: {
    rows: [
      "..kkkk...",
      ".kbbbbk..",
      "kkkkkkkk.",
      "kwwwwwwk.",
      "kwggwwwk.",
      "kwgwwwwk.",
      "kwwkkwwk.",
      "kwwwwwwk.",
      "kkkkkkkk.",
      "........."
    ],
    palette: { k: "#25313b", b: "#4e79ae", w: "#f2eddd", g: "#5f9b66" }
  },
  bagNonPersonProof: {
    rows: [
      "kkkkkkkk.",
      "kwwwwwwk.",
      "kwkkkkwk.",
      "kwkyykwk.",
      "kwkkkkwk.",
      "kwwwrrwk.",
      "kwwrrrwk.",
      "kwwwrrwk.",
      "kkkkkkkk.",
      "........."
    ],
    palette: { k: "#27313d", w: "#f4efdf", y: "#c98a43", r: "#b94747" }
  },
  seat022Receipt: {
    rows: [
      ".kkkkkkk.",
      "kwwwwwwwk",
      "kwkkwkkwk",
      "kwkwkwkwk",
      "kwkkwkkwk",
      "kwwwwwwwk",
      "kwbbbbbwk",
      "kwwwwwwwk",
      ".kkkkkkk.",
      "........."
    ],
    palette: { k: "#26313b", w: "#f4eddb", b: "#3973b8" }
  },
  libraryPresenceProof: {
    rows: [
      "...bbb...",
      "..bwwwb..",
      ".bwgggwb.",
      ".bwgkgwb.",
      ".bwgggwb.",
      "..bwwwb..",
      "...bwb...",
      "...bwb...",
      "..bbbbb..",
      "........."
    ],
    palette: { b: "#1f5ea8", w: "#f2f2e9", g: "#65a96e", k: "#25313b" }
  },
  seatReleasePass: {
    rows: [
      "ggggggggg",
      "gwwwwwwwg",
      "gwkkwkwgg",
      "gwkwkwkwg",
      "gwkkwkwgg",
      "gwwwwwwwg",
      "gwywywywg",
      "gwwwwwwwg",
      "ggggggggg",
      "........."
    ],
    palette: { g: "#3d8d5d", w: "#f4f0dd", k: "#23313a", y: "#e8c45b" }
  },
  backpack: {
    rows: [
      "..kkkk...",
      ".k....k..",
      "kkkkkkkk.",
      "kbbbbbbk.",
      "kbbbbbbk.",
      "kbkkkkbk.",
      "kbbyybbk.",
      "kbbbbbbk.",
      "kkkkkkkk.",
      "........."
    ],
    palette: { k: "#222322", b: "#c8863f", y: "#f5c542" }
  },
  music: {
    rows: [
      "....kkkk.",
      "....k..k.",
      "....k..k.",
      "....k..k.",
      "....k..k.",
      ".kk.k.kkk",
      "kkkk..kkk",
      "kkkk..kkk",
      ".kk....k.",
      "........."
    ],
    palette: { k: "#222322" }
  },
  sun: {
    rows: [
      "....y....",
      ".y..y..y.",
      "..yyyyy..",
      ".yywwwyy.",
      "yyywwwyyy",
      ".yywwwyy.",
      "..yyyyy..",
      ".y..y..y.",
      "....y....",
      "........."
    ],
    palette: { y: "#f5c542", w: "#fff3c2" }
  }
};

interface PixelIconProps {
  name: ItemId | "backpack" | "music" | "sun";
  size?: number;
  className?: string;
}

export function PixelIcon({ name, size = 36, className }: PixelIconProps) {
  const icon = ICONS[name];
  if (!icon) {
    return null;
  }

  const rows = icon.rows;
  const cols = rows[0].length;
  const cell = 1;

  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox={`0 0 ${cols * cell} ${rows.length * cell}`}
      shapeRendering="crispEdges"
      aria-hidden="true"
    >
      {rows.flatMap((row, y) =>
        row.split("").map((ch, x) => {
          const color = icon.palette[ch];
          if (!color) {
            return null;
          }
          return <rect key={`${x}-${y}`} x={x * cell} y={y * cell} width={cell} height={cell} fill={color} />;
        })
      )}
    </svg>
  );
}

export const ITEM_META: Record<ItemId, { name: string; desc: string }> = {
  waterDrop: { name: "水滴", desc: "从早八雨里接住的一滴水。" },
  headphone: { name: "耳机", desc: "背面朝下，像个小水瓢。" },
  wateredHeadphone: { name: "盛水的耳机", desc: "晃一晃，里面有水声。" },
  reverseGear: { name: "反转齿轮", desc: "背面刻着 9 的齿轮。" },
  slashLine: { name: "斜线", desc: "朋友头像上掉下来的一撇。" },
  towerKey: { name: "钥匙", desc: "斜线与齿轮的组合体。" },
  fertilizer: { name: "一袋肥料", desc: "钟楼特产。" },
  campusCard: { name: "校园卡", desc: "证明你是你的卡。余额方面，它持保留意见。" },
  pushTriangle: { name: "三角形", desc: "从主页推送头像里抠下来的三角形。" },
  weatherWater: { name: "天气水滴", desc: "从天气页面接到的另一滴水。" },
  mentorLine: { name: "竖线", desc: "从导师头像上滑落的一条竖线。" },
  rightArrow: { name: "右向箭头", desc: "能把什么东西往右移。它不解决问题，只负责让问题换个位置。" },
  gamepad: { name: "游戏手柄", desc: "二手市场六块钱购入。它让你终于可以操作自己，听起来很悲伤。" },
  occupancyNote: { name: "占座纸条", desc: "022 座位旁留下的一张纸条。它声称主人只离开三分钟，但纸张老化程度不支持这个说法。" },
  callNumber755: { name: "索书号 755", desc: "一串看起来属于书架、实际上更像咒语的编号。图书馆用它证明“你找不到”也是一种服务。" },
  archivedLeaveRule: { name: "旧版离座规则", desc: "一份已经过期但仍然有效的规则。它最大的优点是没人敢确认它无效。" },
  itemRecognitionReport: { name: "物品识别报告", desc: "它很沉重，但不是法律意义上的同学。" },
  bagNonPersonProof: { name: "书包非本人证明", desc: "一份郑重证明。它没有姓名，没有学号，但有很强的占用欲。" },
  seat022Receipt: { name: "022 座位小票", desc: "从桌下夹缝里推出的凭据。它皱得像经历过一次完整的期末周。" },
  libraryPresenceProof: { name: "本人来过证明", desc: "一张证明你来过的证明。它没有证明你为什么要来。" },
  seatReleasePass: { name: "解除占座 PASS", desc: "仅对非本人书包有效。如书包已进化为本人，请联系下一章。" }
};
