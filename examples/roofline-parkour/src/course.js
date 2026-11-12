export const LANES = [-2.48, 0, 2.48];
export const HALF_WIDTH = 4.15;
export const FINISH = 658;
const FULL_DECK = { x: 0, half: HALF_WIDTH };

export const SECTIONS = [
  { name: '机房屋顶', start: 3, speed: 8.8 },
  { name: '沿海风廊', start: 108, speed: 9.9 },
  { name: '塔前屋顶', start: 228, speed: 10.9 },
  { name: '中继天桥', start: 382, speed: 11.2 },
  { name: '天线检修台', start: 520, speed: 11.8 },
];

export const MODES = {
  standard: { label: '标准', speed: 1, coyote: .10, buffer: .14, vaultWindow: 2.3, slide: .78 },
  challenge: { label: '挑战', speed: 1.16, coyote: .065, buffer: .10, vaultWindow: 1.95, slide: .64 },
};

export const GAPS = [
  { start: 37, end: 40.6 },
  { start: 82, end: 86.5 },
  { start: 136, end: 149, wall: { side: 1, start: 126, release: 149.3, end: 151.4 } },
  { start: 177, end: 182.2 },
  { start: 209, end: 214.5 },
  { start: 260, end: 273.5, wall: { side: -1, start: 251, release: 273.8, end: 276 } },
  { start: 302, end: 308.2 },
  { start: 336, end: 341.5 },
  { start: 362, end: 368.2 },
  { start: 416, end: 421.8 },
  { start: 464, end: 478, wall: { side: 1, start: 454, release: 478.35, end: 480.8 } },
  { start: 571, end: 577.2 },
  { start: 620, end: 626.4 },
];

export const RAMPS = [
  { start: 393, end: 407, height: 1.15 },
  { start: 524, end: 537, height: 2.55 },
];

export const BRIDGES = [
  { start: 407, end: 416, x: 0, half: 1.04 },
  { start: 540, end: 551.8, x: LANES[2], half: 1.00 },
];

function feature(type, start, width, x = 0, span = 8.3) {
  return { type, start, end: start + width, x, span };
}

export const OBSTACLES = [
  feature('hurdle', 22, .86),
  feature('beam', 57, 1.45),
  feature('hurdle', 70, .76),
  feature('barrier', 96, 2.3, -1.38, 5.54),
  feature('hurdle', 119, .82),
  feature('beam', 163, 1.65),
  feature('barrier', 190, 2, 1.38, 5.54),
  feature('hurdle', 198, .96),
  feature('beam', 219, 1.46),
  feature('hurdle', 242, .95),
  feature('beam', 285, 1.5),
  feature('hurdle', 293, 1.02),
  feature('beam', 315, 1.56),
  feature('barrier', 324, 2.45, -1.38, 5.54),
  feature('hurdle', 351, 1.04),
  feature('beam', 375.5, 1.5),
  feature('beam', 433, 1.55),
  feature('hurdle', 443, .98),
  feature('beam', 492, 1.6),
  feature('barrier', 506, 2.7, -1.38, 5.54),
  feature('beam', 558, 1.55),
  feature('hurdle', 586, .94),
  feature('beam', 598, 1.55),
  feature('barrier', 608, 2.4, 1.38, 5.54),
  feature('beam', 636, 1.50),
  feature('hurdle', 647, 1.08),
];

export const WALLS = GAPS.flatMap(gap => gap.wall ? [{ ...gap.wall, gap }] : []);
export const FEATURES = [
  ...OBSTACLES.map(item => ({ ...item, at: item.start })),
  ...GAPS.map(item => ({ ...item, at: item.wall?.start ?? item.start, type: item.wall ? 'wall' : 'gap' })),
  ...BRIDGES.map(item => ({ ...item, at: item.start, type: 'bridge' })),
].sort((a, b) => a.at - b.at);

export function elevationAt(distance) {
  let height = 0;
  for (const ramp of RAMPS) {
    if (distance < ramp.start) break;
    if (distance < ramp.end) return height + (ramp.height - height) * (distance - ramp.start) / (ramp.end - ramp.start);
    height = ramp.height;
  }
  return height;
}

export function deckAt(distance) {
  if (GAPS.some(gap => distance > gap.start && distance < gap.end)) return null;
  return BRIDGES.find(bridge => distance >= bridge.start && distance < bridge.end) ?? FULL_DECK;
}

export function floorAt(distance, x) {
  const deck = deckAt(distance);
  return deck && Math.abs(x - deck.x) <= deck.half ? elevationAt(distance) : null;
}

export function sectionAt(distance) {
  for (let i = SECTIONS.length - 1; i > 0; i--) {
    if (distance >= SECTIONS[i].start) return i;
  }
  return 0;
}

export function adjacentToWall(x, wall) {
  return wall.side * x >= 1.55;
}
