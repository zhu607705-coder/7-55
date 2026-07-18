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
  campusCard: { name: "电子校园卡", desc: `${actOneContent.studentName} · ${actOneContent.studentId}。` },
  pushTriangle: { name: "三角形", desc: "从主页推送头像里抠下来的三角形。" },
  weatherWater: { name: "天气水滴", desc: "从天气页面接到的另一滴水。" },
  mentorLine: { name: "竖线", desc: "从导师头像上滑落的一条竖线。" },
  rightArrow: { name: "右移箭头", desc: "由三角形与竖线拼成，箭头朝右。" },
  gamepad: { name: "游戏手柄", desc: "CC98 二手市场，六块钱成交。" },
  occupancyNote: { name: "占座纸条", desc: "022 座位旁留下的一张纸条。" },
  callNumber755: { name: "索书号 755", desc: "一串写成 I247.55 / 755 的馆藏编号。" },
  archivedLeaveRule: { name: "旧离座规定", desc: "从 755 书架夹层取出的旧版规定。" },
  itemRecognitionReport: { name: "物品识别报告", desc: "照片识别生成的书包报告，右下角仍是空白。" },
  bagNonPersonProof: { name: "书包非本人证明", desc: "失物招领机器盖章确认：书包不等于本人。" },
  seat022Receipt: { name: "022 座位小票", desc: "从 022 桌面夹缝里取出的座位凭据。" },
  libraryPresenceProof: { name: "本人来过证明", desc: "浙大体艺根据图书馆访问记录生成的证明。" },
  seatReleasePass: { name: "离座清退 PASS", desc: "恢复申请签发的临时处置凭证。" }
};
