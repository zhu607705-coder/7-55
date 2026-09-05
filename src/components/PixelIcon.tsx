import type { ItemId } from "../core/types";
import itemConfig from "../data/items.config.json";
import decoyPaperIconUrl from "../assets/rpg/theater/generated/icons/item_decoy_paper.png";
import fluorescentBrushIconUrl from "../assets/rpg/theater/generated/icons/item_fluorescent_brush.png";
import spotlightRemoteIconUrl from "../assets/rpg/theater/generated/icons/item_spotlight_remote.png";
import temporaryTheaterTicketIconUrl from "../assets/rpg/theater/generated/icons/item_temporary_theater_ticket.png";
import theaterProgramFinaleIconUrl from "../assets/rpg/theater/generated/icons/item_theater_program_finale.png";
import theaterProgramOpeningIconUrl from "../assets/rpg/theater/generated/icons/item_theater_program_opening.png";
import theaterProgramSpotlightIconUrl from "../assets/rpg/theater/generated/icons/item_theater_program_spotlight.png";
import theaterTicketHalfAIconUrl from "../assets/rpg/theater/generated/icons/item_theater_ticket_half_a.png";
import theaterTicketHalfBIconUrl from "../assets/rpg/theater/generated/icons/item_theater_ticket_half_b.png";
import wetProgramIconUrl from "../assets/rpg/theater/generated/icons/item_wet_program.png";
import hairDryerIconUrl from "../assets/rpg/props/items/hair_dryer_generated_v01.png";

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
  attendanceRecordPaper: {
    rows: [
      ".kkkkkkk.", ".kwwwwwk.", ".kwgggwk.", ".kwwwwwk.", ".kwgggwk.",
      ".kwwwwwk.", ".kwg..wk.", ".kwwwwwk.", ".kkkkkkk.", "........."
    ],
    palette: { k: "#4b5054", w: "#e7dfcf", g: "#87928c" }
  },
  oldClockHourHand: {
    rows: [
      "....yy...", "...yyyy..", "..yykyyy.", ".yykkkkyy", "....kk...",
      "....kk...", "....kk...", "....kk...", "...kkkk..", "........."
    ],
    palette: { y: "#d8b45a", k: "#515860" }
  },
  clockPositioningPlate: {
    rows: [
      "..kkkkk..", ".kkyyykk.", "kkykkkykk", "kyk...kyk", "kyk.k.kyk",
      "kyk...kyk", "kkykkkykk", ".kkyyykk.", "..kkkkk..", "........."
    ],
    palette: { k: "#4b5054", y: "#ccb15b" }
  },
  shortPryBar: {
    rows: [
      ".........", ".......kk", "......kk.", ".....kk..", "..kkkk...", ".kkk.....",
      ".kk......", ".kk......", ".kk......", "........."
    ],
    palette: { k: "#6d737b" }
  },
  universalLubricatingOil: {
    rows: [
      "...kkk...", "..kgggk..", ".kgggggk.", ".kgwwwgk.", ".kgwwwgk.",
      ".kgggggk.", "..kgggk..", "...k.k...", "...k.k...", "........."
    ],
    palette: { k: "#4d5158", g: "#7c9b5f", w: "#d8d2bd" }
  },
  finalMinute: {
    rows: [
      ".......y.", "......yy.", ".....yy..", "....yy...", "...yy....",
      "..yyy....", ".yky.....", "ykyky....", ".kyk.....", "..k......"
    ],
    palette: { k: "#4b3a24", y: "#d6a94e" }
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

const THEATER_RASTER_ICONS: Partial<Record<ItemId, string>> = {
  hairDryer: hairDryerIconUrl,
  theaterTicketHalfA: theaterTicketHalfAIconUrl,
  theaterTicketHalfB: theaterTicketHalfBIconUrl,
  temporaryTheaterTicket: temporaryTheaterTicketIconUrl,
  theaterProgramOpening: theaterProgramOpeningIconUrl,
  theaterProgramSpotlight: theaterProgramSpotlightIconUrl,
  theaterProgramFinale: theaterProgramFinaleIconUrl,
  spotlightRemote: spotlightRemoteIconUrl,
  fluorescentBrush: fluorescentBrushIconUrl,
  decoyPaper: decoyPaperIconUrl,
  wetProgram: wetProgramIconUrl
};

export function PixelIcon({ name, size = 36, className }: PixelIconProps) {
  const rasterIcon = THEATER_RASTER_ICONS[name as ItemId];
  if (rasterIcon) {
    return (
      <img
        className={className}
        src={rasterIcon}
        width={size}
        height={size}
        alt=""
        aria-hidden="true"
        draggable={false}
        style={{ imageRendering: "pixelated", objectFit: "contain" }}
      />
    );
  }
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

// Both inventory docks and item details use the same authored copy.
export const ITEM_META = Object.fromEntries(
  itemConfig.map(({ id, name, desc }) => [id, { name, desc }])
) as Record<ItemId, { name: string; desc: string }>;
