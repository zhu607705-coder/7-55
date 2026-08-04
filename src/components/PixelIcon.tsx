import type { ItemId } from "../core/types";

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
  cafeteriaWages: {
    rows: [
      "..yyyyy..",
      ".ywwwwwy.",
      "ywyyyyywy",
      "ywykkkywy",
      "ywykykywy",
      "ywykkkywy",
      "ywyyyyywy",
      ".ywwwwwy.",
      "..yyyyy..",
      "........."
    ],
    palette: { y: "#d89f32", w: "#f7df8b", k: "#744f20" }
  },
  greaseTissue: {
    rows: [
      "..kkkk...",
      ".kwwwwk..",
      "kwwwwwwk.",
      "kwwyywwk.",
      "kwwyyywk.",
      "kwwwyywk.",
      ".kwwwwwk.",
      "..kwwwk..",
      "...kkk...",
      "........."
    ],
    palette: { k: "#c6bca5", w: "#f2ead8", y: "#9f7637" }
  },
  sparklingWater: {
    rows: [
      "...bbb...",
      "..bwwwb..",
      "..bcbwb..",
      ".bcccccb.",
      ".bcwcwcb.",
      ".bccbccb.",
      ".bcwcwcb.",
      ".bcccccb.",
      "..bbbbb..",
      "........."
    ],
    palette: { b: "#1d4f79", c: "#4ab9e9", w: "#e9fbff" }
  },
  lemonTea: {
    rows: [
      "...yyy...",
      "..ywwwy..",
      "..ywwwy..",
      ".ywwwwwy.",
      ".ywwywwy.",
      ".ywywywy.",
      ".ywwywwy.",
      ".ywwwwwy.",
      "..yyyyy..",
      "........."
    ],
    palette: { y: "#c99d2e", w: "#f4f2df" }
  },
  blackCoffee: {
    rows: [
      "...ggg...",
      "..gkkkg..",
      "..gkkkg..",
      ".gkkkkkg.",
      ".gkbkbkg.",
      ".gkkkkkg.",
      ".gkkkkkg.",
      ".gkkkkkg.",
      "..ggggg..",
      "........."
    ],
    palette: { g: "#59636a", k: "#171b1e", b: "#7a4a2a" }
  },
  badDrink: {
    rows: [
      "..wwwww..",
      ".w.....w.",
      ".w.....w.",
      ".wmmmmmw.",
      ".wmgmgmw.",
      ".wmmmmmw.",
      ".wmgmmmw.",
      ".wmmmmmw.",
      "..wwwww..",
      "........."
    ],
    palette: { w: "#bac5c5", m: "#736447", g: "#3e5548" }
  },
  dailySpecialSparklingWater: {
    rows: [
      "y..bbb..y",
      "..bwwwb...",
      "..bcbwb...",
      ".bcccccb..",
      ".bcwcwcb.y",
      ".bccbccb..",
      ".bcwcwcb..",
      ".bcccccb..",
      "y.bbbbb...",
      "........."
    ],
    palette: { b: "#173f6b", c: "#39c6ef", w: "#f0fdff", y: "#f2cf59" }
  },
  pickupTicket0755: {
    rows: [
      "kkkkkkkkk",
      "kwwwwwwwk",
      "kwbwbwbwk",
      "kwbbbwwwk",
      "kwbwbwbwk",
      "kwwwwwwwk",
      "kwyyyyywk",
      "kwwwwwwwk",
      "kkkkkkkkk",
      "........."
    ],
    palette: { k: "#26313b", w: "#f4eddb", b: "#3973b8", y: "#d8a64a" }
  },
  canteenRealBun: {
    rows: [".........", "...kkk...", "..kwwwk..", ".kwwywwk.", ".kwwwwwk.", ".kwwwwwk.", "..kkkkk..", ".........", ".........", "........."],
    palette: { k: "#5d4028", w: "#ead6a8", y: "#f6e6bf" }
  },
  canteenCluelessSoyMilk: {
    rows: ["..kkkk...", ".kwwwwk..", ".kwwwwk..", ".kwywwk..", ".kwywwk..", ".kwwwwk..", ".kwwwwk..", "..kkkk...", ".........", "........."],
    palette: { k: "#39434a", w: "#f3eee0", y: "#d9b84b" }
  },
  canteenEdgeEgg: {
    rows: [".........", "...kk....", "..kwwk...", ".kwwwwk..", ".kwwywwk.", ".kwwywwk.", "..kwwwk..", "...kkk...", ".........", "........."],
    palette: { k: "#6b5635", w: "#f6f0d7", y: "#e6a62f" }
  },
  canteenUselessCongee: {
    rows: [".........", ".kkkkkkk.", ".kwwwwwk.", "..kwwwk..", "..kwwwk..", "..kwwwk..", "...kkk...", "...sss...", ".........", "........."],
    palette: { k: "#45606a", w: "#f0ead7", s: "#a7d8df" }
  },
  theaterTicketHalfA: {
    rows: [
      "kkkkk....", "kwwww....", "kwrrr....", "kwwww....", "kwkkw....",
      "kwwww....", "kwyww....", "kwwww....", "kkkkk....", "........."
    ],
    palette: { k: "#442a2c", w: "#ead8ac", r: "#9b4048", y: "#d9a94a" }
  },
  theaterTicketHalfB: {
    rows: [
      "....kkkkk", "....wwwwk", "....bbbwk", "....wwwwk", "....wkkwk",
      "....wwwwk", "....wwywk", "....wwwwk", "....kkkkk", "........."
    ],
    palette: { k: "#26384a", w: "#dce9ec", b: "#3979a8", y: "#d9a94a" }
  },
  temporaryTheaterTicket: {
    rows: [
      "kkkkkkkkk", "kwwwwwwwk", "kwrrrbbwk", "kwwwwwwwk", "kwkkwkkwk",
      "kwwwwwwwk", "kwyyyyywk", "kwwwwwwwk", "kkkkkkkkk", "........."
    ],
    palette: { k: "#3a3030", w: "#efe1bd", r: "#9b4048", b: "#3979a8", y: "#d9a94a" }
  },
  theaterProgramOpening: {
    rows: [
      "kkkkkkkkk", "kwwwwwwwk", "kwrrrrrwk", "kwwwwwwwk", "kwkkkkkwk",
      "kwwwwwwwk", "kwkkkwwwk", "kwwwwwwwk", "kkkkkkkkk", "........."
    ],
    palette: { k: "#533237", w: "#efe3c7", r: "#a94b52" }
  },
  theaterProgramSpotlight: {
    rows: [
      "kkkkkkkkk", "kwwywwwwk", "kwwywwwwk", "kwwywwwwk", "kwyyywwwk",
      "kwwywwwwk", "kwkkkkkwk", "kwwwwwwwk", "kkkkkkkkk", "........."
    ],
    palette: { k: "#533237", w: "#efe3c7", y: "#e6bf5a" }
  },
  theaterProgramFinale: {
    rows: [
      "kkkkkkkkk", "kwrrwrrwk", "kwrrrrrwk", "kwwrrrwwk", "kwwwrwwwk",
      "kwwwwwwwk", "kwkkkkkwk", "kwwwwwwwk", "kkkkkkkkk", "........."
    ],
    palette: { k: "#533237", w: "#efe3c7", r: "#a94b52" }
  },
  spotlightRemote: {
    rows: [
      "..kkkkk..", ".kgggggk.", "kgyyyyggk", "kgggggggk", "kggbgbggk",
      "kgggggggk", ".kgggggk.", "..kgggk..", "...kkk...", "........."
    ],
    palette: { k: "#22272b", g: "#54636d", y: "#e5c95e", b: "#61c8e8" }
  },
  fluorescentBrush: {
    rows: [
      ".ccccccc.", ".cgggggc.", "..cgggc..", "...kkk...", "....kk...",
      "....kk...", "....kk...", "....kk...", "....kk...", "........."
    ],
    palette: { c: "#4dcbe8", g: "#b7f0c7", k: "#72533a" }
  },
  decoyPaper: {
    rows: [
      "..kkkk...", ".kwwwwk..", "kwwwwwwk.", "kwwkkwwk.", "kwwwwwwk.",
      "kwwkkwwk.", ".kwwwwwk.", "..kwwwk..", "...kkk...", "........."
    ],
    palette: { k: "#4b5054", w: "#e8e3d5" }
  },
  wetProgram: {
    rows: [
      "kkkkkkkkk", "kwwwwwwwk", "kwbbwwwwk", "kwbbbwwwk", "kwkkkkkwk",
      "kwwwwbbbk", "kwkkkbbbk", "kwwwwbbbk", "kkkkkkkkk", "........."
    ],
    palette: { k: "#39414a", w: "#e8dfc8", b: "#5598b8" }
  },
  bridgeKeyword: {
    rows: [
      ".........", "..kkkkk..", ".kgggggk.", "kgkgggkgk", "kkkkkkkkk",
      "...kkk...", "..kkkkk..", ".kk...kk.", ".........", "........."
    ],
    palette: { k: "#3f4b4d", g: "#86c6af" }
  },
  reflectionKeyword: {
    rows: [
      ".........", ".bbbbbbb.", "bbwwwwwbb", "bwwbbbwwb", "bwbwwwbwb",
      "bwwbbbwwb", "bbwwwwwbb", ".bbbbbbb.", ".........", "........."
    ],
    palette: { b: "#3b83a5", w: "#bfeaf0" }
  },
  lakeKeyword: {
    rows: [
      ".........", "..ggggg..", ".ggggggg.", "ggbbbbbgg", "gbbbbbbgg",
      "ggbbbbbg.", ".ggbbbg..", "..gggg...", ".........", "........."
    ],
    palette: { g: "#4f8b62", b: "#55a8c9" }
  },
  reflectionCoordinate: {
    rows: [
      "....y....", "...yyy...", "..yykyy..", ".yykkkyy.", "yykkkkkyy",
      ".yykkkyy.", "..yykyy..", "...yyy...", "....y....", "........."
    ],
    palette: { y: "#d6c66e", k: "#3e5f67" }
  },
  fishingRod: {
    rows: [
      ".......kk", "......kk.", ".....kk..", "....kk...", "...kk....",
      "..kk.....", ".kk......", "kk....h..", ".k...hh..", ".....h..."
    ],
    palette: { k: "#755234", h: "#52636a" }
  },
  rustedLockerKey: {
    rows: [
      "..rrrr...", ".ryyyr...", "ry...yr..", "ry...yr..", ".ryyyr...",
      "..rrr....", "...rrr...", "....rrrr.", "......rrr", "........."
    ],
    palette: { r: "#9a5934", y: "#d2a350" }
  },
  nylonCord: {
    rows: [
      "..nnnn...", ".nn..nn..", "nn....nn.", "nn.nnnnn.", "nn.nn.nn.",
      "nn....nn.", ".nn..nn..", "..nnnnnn.", ".....nn..", "......nn."
    ],
    palette: { n: "#d8d2bd" }
  },
  brokenNetFrame: {
    rows: [
      ".kkkkkkk.", "kk.n.n.kk", "k.n.n.n.k", "kn.n.n..k", "k.n.n....",
      "kn.n.n..k", "k.n.n.n.k", "kk.n.n.kk", ".kkkkkkk.", "....kk..."
    ],
    palette: { k: "#536165", n: "#9ba7a2" }
  },
  improvisedDipNet: {
    rows: [
      ".kkkkkkk.", "kkn.n.nkk", "kn.n.n.nk", "k.n.n.n.k", "kn.n.n.nk",
      "kkn.n.nkk", ".kkkkkkk.", "....kk...", "....kk...", "....kk..."
    ],
    palette: { k: "#59656a", n: "#d8d2bd" }
  },
  sealedFeedTin: {
    rows: [
      "..kkkkk..", ".kwwwwwk.", ".kgggggk.", ".kgpppgk.", ".kgggggk.",
      ".kgpppgk.", ".kgggggk.", ".kwwwwwk.", "..kkkkk..", "........."
    ],
    palette: { k: "#455158", w: "#c7d1d0", g: "#748b79", p: "#d0a24b" }
  },
  fishFeedPellets: {
    rows: [
      "...kkk...", "..kgggk..", ".kgggggk.", ".kgpgpgk.", "kgpgpgpgk",
      "kggpgpggk", "kgpgpgpgk", ".kgggggk.", "..kkkkk..", "........."
    ],
    palette: { k: "#5a4633", g: "#b79c69", p: "#6e4f31" }
  },
  smallCarp: {
    rows: [
      ".........", ".....o...", ".o..oooo.", "o.oooyyoo", ".oooyyyyo",
      "..ooyykyo", ".o..oooo.", ".....o...", ".........", "........."
    ],
    palette: { o: "#b85b35", y: "#e3a448", k: "#26333b" }
  },
  swanMagnet: {
    rows: [
      "rr.....bb", "rr.....bb", "rr.....bb", "rr.....bb", "rr.....bb",
      "rr.....bb", ".rr...bb.", "..rrrbb..", "...rbb...", "........."
    ],
    palette: { r: "#c64f4d", b: "#487db5" }
  },
  magneticFishingRod: {
    rows: [
      ".......kk", "......kk.", ".....kk..", "....kk...", "...kk....",
      "..kk.....", ".kk......", "kk....rb.", ".k...rrbb", ".....r..b"
    ],
    palette: { k: "#755234", r: "#c64f4d", b: "#487db5" }
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
  willowBranchPaddle: {
    rows: [
      "........g",
      ".......gg",
      "......gb.",
      ".....gb..",
      "....gb...",
      "...gb....",
      "..gb.....",
      ".bbb.....",
      "bbbb.....",
      ".bb......"
    ],
    palette: { b: "#765333", g: "#9fbe61" }
  },
  warningSignPaddle: {
    rows: [
      "...rr....",
      "..ryyr...",
      ".ryyyyr..",
      "ryyyyyyr.",
      "rrrrrrrr.",
      "....k....",
      "....k....",
      "....k....",
      "....k....",
      "...kkk..."
    ],
    palette: { r: "#bb3232", y: "#f4d85d", k: "#5c6469" }
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
  name: ItemId | "backpack" | "music" | "sun" | "willowBranchPaddle" | "warningSignPaddle";
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
  waterDrop: { name: "水滴", desc: "从早八雨里接住的一滴水。它看起来很普通，但已经比你更早起床。" },
  headphone: { name: "耳机", desc: "从控制中心掉下来的耳机。背面朝下，像一个不太情愿的小水瓢。" },
  wateredHeadphone: { name: "盛水的耳机", desc: "一只装了水的耳机。音质未知，灌溉能力暂时领先。" },
  reverseGear: { name: "反转齿轮", desc: "从设置里掉下来的齿轮。背面刻着 9，说明它一直有背着你生活。" },
  slashLine: { name: "斜线", desc: "朋友头像上掉下来的一撇。检测到未经授权的友情支援。" },
  towerKey: { name: "钥匙", desc: "斜线和齿轮拼成的钥匙。合法性很低，开锁欲很强。" },
  fertilizer: { name: "一袋肥料", desc: "钟楼里掉出来的肥料。不要问钟楼为什么会长出农业属性。" },
  campusCard: {
    name: "电子校园卡",
    desc: "证明你是你的卡。余额方面，它持保留意见。"
  },
  pushTriangle: { name: "三角形", desc: "从主页推送头像里抠下来的三角形。它还没想好自己是播放键还是箭头的一部分。" },
  weatherWater: { name: "天气水滴", desc: "从天气页面接到的一滴水。天气预报终于做了一件可以直接拿来用的事。" },
  mentorLine: { name: "竖线", desc: "从导师头像上滑落的一条竖线。它看起来很严肃，像一句还没发完的消息。" },
  rightArrow: { name: "右移箭头", desc: "能把什么东西往右移。它不解决问题，只负责让问题换个位置。" },
  gamepad: { name: "游戏手柄", desc: "CC98 二手市场六块钱成交。它让你终于可以操作自己，听起来很悲伤。" },
  occupancyNote: { name: "占座纸条", desc: "022 座位旁留下的一张纸条。它声称主人只离开三分钟，但纸张老化程度不支持这个说法。" },
  callNumber755: { name: "索书号 755", desc: "一串看起来属于书架、实际上更像咒语的编号。图书馆用它证明“你找不到”也是一种服务。" },
  archivedLeaveRule: { name: "旧离座规定", desc: "一份已经过期但仍然有效的规定。它最大的优点是没人敢确认它无效。" },
  itemRecognitionReport: { name: "物品识别报告", desc: "一份关于书包的严肃报告。结论是：它很沉重，但不是法律意义上的同学。" },
  bagNonPersonProof: { name: "书包非本人证明", desc: "一份郑重证明。它没有姓名，没有学号，但有很强的占用欲。" },
  seat022Receipt: { name: "022 座位小票", desc: "从桌下夹缝里推出的凭据。它皱得像经历过一次完整的期末周。" },
  libraryPresenceProof: { name: "本人来过证明", desc: "一张证明你来过的证明。它没有证明你为什么要来。" },
  seatReleasePass: { name: "离座清退 PASS", desc: "仅对非本人书包有效。如书包已进化为本人，请联系下一章。" },
  cafeteriaWages: { name: "餐盘回收费 2.00 元", desc: "你通过劳动获得的两块钱。听起来像人生开始出问题的地方。" },
  greaseTissue: { name: "油渍纸巾", desc: "擦过食堂桌面的纸巾。它现在拥有轻微的反光治理能力。" },
  sparklingWater: { name: "气泡水", desc: "看起来很清爽，实际上是队伍秩序的原材料。" },
  lemonTea: { name: "柠檬茶", desc: "瓶罐架残字写着它的颜色。请结合暗色观察确认配方位置。" },
  blackCoffee: { name: "黑咖啡", desc: "早八指定燃料。喝了也不一定清醒。" },
  badDrink: { name: "难喝饮料", desc: "不建议喝。喝完之后会理解早八，但不能推进剧情。" },
  dailySpecialSparklingWater: { name: "今日新品气泡水", desc: "它让队伍承认你存在，也能在守出口时制造两秒气泡。" },
  pickupTicket0755: { name: "0755 取餐号", desc: "一张从点餐机吐出来的小票。它证明你认真排过队，也认真被骗进流程。" },
  canteenRealBun: { name: "比较真实的包子", desc: "一份真的包子。过于真实，因此没有线索价值。" },
  canteenCluelessSoyMilk: { name: "没什么线索的豆浆", desc: "温度正常，味道正常，剧情价值也很稳定地接近零。" },
  canteenEdgeEgg: { name: "世界观边缘的鸡蛋", desc: "不要追问它和纸条之间的关系。" },
  canteenUselessCongee: { name: "很热但很没用的白粥", desc: "很热，但没有用。至少描述非常诚实。" },
  theaterTicketHalfA: { name: "半张剧院票根 A", desc: "它证明你的一半可以进场，另一半还在流程里。" },
  theaterTicketHalfB: { name: "半张剧院票根 B", desc: "来自一台失败的取票机。它至少努力过。" },
  temporaryTheaterTicket: { name: "临时观演票", desc: "两张半真半假的票根拼出来的票。剧院看了都沉默了一秒。" },
  theaterProgramOpening: { name: "节目单残页·开场", desc: "普通节目单，看起来很会假装正式。" },
  theaterProgramSpotlight: { name: "节目单残页·追光", desc: "普通节目单，看起来很会假装正式。" },
  theaterProgramFinale: { name: "节目单残页·谢幕", desc: "普通节目单，看起来很会假装正式。" },
  spotlightRemote: { name: "追光灯遥控器", desc: "能让舞台中央变亮。也能让逃避责任的纸条短暂接受审判。" },
  fluorescentBrush: { name: "荧光粉刷", desc: "刷过之后，连借口都会发光。" },
  decoyPaper: { name: "假纸条", desc: "长得很像目标，但态度没那么差。" },
  wetProgram: { name: "湿掉的节目单", desc: "纸条逃跑时留下的节目单，边角湿得很有方向感。" },
  bridgeKeyword: { name: "桥边", desc: "CC98 目击者留下的地点关键词。" },
  reflectionKeyword: { name: "倒影", desc: "馆藏系统留下的地点关键词。" },
  lakeKeyword: { name: "湖", desc: "微信消息留下的地点关键词。" },
  reflectionCoordinate: { name: "倒影坐标", desc: "两种观察模式共同确认的位置。" },
  fishingRod: { name: "钓竿", desc: "码头装备架上的基础钓竿，可安装诱饵或磁吸附件。" },
  rustedLockerKey: { name: "锈蚀柜钥匙", desc: "从湖中钓起的旧钥匙，表面锈迹与码头储物柜一致。" },
  nylonCord: { name: "尼龙绳", desc: "储物柜内的耐水尼龙绳，长度足够固定一圈网框。" },
  brokenNetFrame: { name: "断裂网框", desc: "从水下钓起的旧网框，网面已经脱落。" },
  improvisedDipNet: { name: "临时抄网", desc: "用尼龙绳修复的网框，可打捞钓钩无法稳定带回的物品。" },
  sealedFeedTin: { name: "密封饲料罐", desc: "从水中捞出的密封金属罐，内部有颗粒滚动声。" },
  fishFeedPellets: { name: "鱼食颗粒", desc: "密封罐中的鱼食，可用于吸引小型鱼群靠近。" },
  smallCarp: { name: "小鲤鱼", desc: "用鱼食引到钓点的小鲤鱼，暂时保持活性。" },
  swanMagnet: { name: "天鹅磁铁", desc: "黑天鹅带回的小型磁铁，可固定到钓竿末端。" },
  magneticFishingRod: { name: "磁吸钓竿", desc: "安装磁吸附件的钓竿，可接近夹在金属结构上的纸张。" }
};
