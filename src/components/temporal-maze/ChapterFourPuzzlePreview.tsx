import { useId, type CSSProperties } from "react";
import type { ChapterFourInsertedPuzzleId, ChapterFourPowerEdgeId } from "../../modules/ChapterFourInsertedPuzzleModel";
import { CHAPTER_FOUR_DEVICE_REGISTRATION } from "../../modules/ChapterFourInsertedPuzzleModel";

export interface ChapterFourPuzzlePreviewState {
  dutyOrder: string[];
  archiveYearBand: string;
  archiveFloor: string;
  archivePurpose: string;
  mediaAlignment: { xOffset: number; yOffset: number; rotationQuarterTurns: number };
  calibration: { horizontal: number; vertical: number; pressure: number };
  powerEdges: ChapterFourPowerEdgeId[];
  evacuationOrder: string[];
}

const LABELS: Record<string, string> = {
  classroom_104: "104 教室", classroom_105: "105 教室", main_elevator: "主电梯",
  lecture_202_door: "202 教室门口", east_corridor: "东侧走廊",
  transport_core: "交通核心", main_stair_down: "主楼梯下行口",
  attendance: "考勤", wayfinding: "入口导视", maintenance: "维修"
};
const NODES: Record<string, { x: number; y: number; label: string }> = {
  hall: { x: 150, y: 42, label: "大厅" },
  west_corridor: { x: 60, y: 112, label: "西侧走廊" },
  east_corridor: { x: 240, y: 112, label: "东侧走廊" },
  bakery_back_area: { x: 75, y: 220, label: "后区" },
  classroom_zone: { x: 225, y: 220, label: "教室区" }
};
const EDGES: ChapterFourPowerEdgeId[] = [
  "hall__west_corridor", "hall__east_corridor", "west_corridor__bakery_back_area",
  "east_corridor__classroom_zone", "bakery_back_area__classroom_zone",
  "west_corridor__east_corridor", "hall__classroom_zone"
];
const shifted = (x: number, y: number): CSSProperties => ({ transform: `translate(${x}px, ${y}px)` });
const signed = (value: number) => value > 0 ? `+${value}` : `${value}`;
const FILM_LANDMARKS = "M-42 12V-15H-25V12 M-9 15V7H-1V-1H7V-9H15 M29 -15V15M36 -15V15M43 -15V15";
const CONTACTS = [[-24, -17], [24, -17], [0, 19]];

/** Read-only views of the same draft submitted by the controls. No success inference or story writes. */
export function ChapterFourPuzzlePreview({ puzzleId, state }: {
  puzzleId: ChapterFourInsertedPuzzleId;
  state: ChapterFourPuzzlePreviewState;
}) {
  const gridId = useId().replace(/:/g, "");
  let graphic;
  let caption;
  switch (puzzleId) {
    case "media_alignment": {
      const { xOffset, yOffset, rotationQuarterTurns } = state.mediaAlignment;
      const registration = CHAPTER_FOUR_DEVICE_REGISTRATION.media;
      caption = `横向 ${signed(xOffset)} 格 · 纵向 ${signed(yOffset)} 格 · 顺时针 ${rotationQuarterTurns * 90}°`;
      graphic = <>
        <defs><pattern id={gridId} width="20" height="20" patternUnits="userSpaceOnUse"><path d="M20 0H0V20" fill="none" stroke="#547077" strokeWidth="1" /></pattern></defs>
        <rect x="10" y="10" width="280" height="260" fill="#172e36" stroke="#81918a" strokeWidth="4" />
        <rect x="20" y="20" width="260" height="240" fill={`url(#${gridId})`} />
        <path d="M150 25V255M25 140H275" className="puzzle-preview__datum" />
        <path d="M35 40V30H45M255 30H265V40M35 240V250H45M255 250H265V240" className="puzzle-preview__datum" />
        <g transform="translate(150 140)">
          <g data-preview-part="film-position" className="puzzle-preview__moving" style={shifted(xOffset * 20, yOffset * 20)}>
            <g data-preview-part="film-rotation" className="puzzle-preview__moving" style={{ transform: `rotate(${rotationQuarterTurns * 90}deg)` }}>
              <rect x="-62" y="-37" width="124" height="74" fill="#80572d" fillOpacity=".55" stroke="#f2bb62" strokeWidth="3" />
              {[-50, -30, -10, 10, 30, 50].map(x => <g key={x}><rect x={x - 4} y="-31" width="8" height="5" fill="#182e36" /><rect x={x - 4} y="26" width="8" height="5" fill="#182e36" /></g>)}
              <path d={FILM_LANDMARKS} fill="none" stroke="#ffcf73" strokeWidth="4" />
              <path d="M-61 -36H-44V-20H-61Z" fill="#fff0bb" />
              <circle r="4" fill="#fff0bb" />
            </g>
          </g>
        </g>
        <g data-preview-part="film-reference" transform={`translate(${150 + registration.xOffset * 20} ${140 + registration.yOffset * 20}) rotate(${registration.rotationQuarterTurns * 90})`}>
          <path d={FILM_LANDMARKS} fill="none" stroke="#c0e0df" strokeWidth="2" strokeDasharray="3 3" />
        </g>
        <text x="30" y="45">金色胶片 / 浅色虚线参照</text><text x="30" y="231">入口 · 楼梯 · 荣誉墙</text><text x="30" y="249">一格 = 一次平移</text>
        <text x="257" y="133">+X</text><text x="156" y="253">+Y</text>
      </>;
      break;
    }
    case "positioning_calibration": {
      const { horizontal, vertical, pressure } = state.calibration;
      const registration = CHAPTER_FOUR_DEVICE_REGISTRATION.calibration;
      caption = `滑台 X ${signed(horizontal)} · Y ${signed(vertical)} · 压头 ${pressure} / 4 档`;
      graphic = <>
        <defs><pattern id={gridId} width="16" height="16" patternUnits="userSpaceOnUse"><path d="M16 0H0V16" fill="none" stroke="#547077" /></pattern></defs>
        <rect x="14" y="35" width="194" height="204" fill={`url(#${gridId})`} stroke="#86968c" strokeWidth="4" />
        <path d="M110 38V236M17 137H205" className="puzzle-preview__datum" />
        <text x="24" y="24">滑台俯视 · 一次一格</text>
        <g transform="translate(110 137)"><g data-preview-part="calibration-stage" className="puzzle-preview__moving" style={shifted(horizontal * 16, vertical * 16)}>
          <rect x="-39" y="-31" width="78" height="62" fill="#6b725e" fillOpacity=".6" stroke="#f2c26a" strokeWidth="3" />
          <circle r="15" fill="#203942" stroke="#fff0bb" strokeWidth="3" /><path d="M-24 0H24M0 -24V24" stroke="#fff0bb" strokeWidth="2" />
          {CONTACTS.map(([x, y]) => <circle key={`${x}-${y}`} cx={x} cy={y} r="4" fill="#ffce6d" />)}
        </g></g>
        <g data-preview-part="calibration-reference" transform={`translate(${110 + registration.horizontal * 16} ${137 + registration.vertical * 16})`}>
          {CONTACTS.map(([x, y]) => <circle key={`${x}-${y}`} cx={x} cy={y} r="7" fill="none" stroke="#c0e0df" strokeWidth="2" strokeDasharray="3 2" />)}
        </g>
        <text x="220" y="24">压头侧视</text>
        <path d="M247 47V190M217 204H281" stroke="#8d9f99" strokeWidth="6" />
        <rect x="223" y="191" width="49" height="12" fill="#acac8b" />
        <path d={`M214 ${89 + registration.pressure * 23}H275`} stroke="#c0e0df" strokeWidth="2" strokeDasharray="3 3" />
        <g data-preview-part="calibration-press" className="puzzle-preview__moving" style={shifted(0, pressure * 23)}><rect x="227" y="65" width="40" height="24" fill="#af8b49" stroke="#f2c26a" strokeWidth="3" /><path d="M237 90H257V98H237Z" fill="#f2c26a" /></g>
        {[0, 1, 2, 3, 4].map(n => <text key={n} x="282" y={90 + n * 23} className={n === pressure ? "puzzle-preview__accent" : ""}>{n}</text>)}
        <text x="22" y="260">左 −X / 右 +X · 上 −Y / 下 +Y</text>
      </>;
      break;
    }
    case "power_topology": {
      caption = `已接 ${state.powerEdges.length} / 5 条 · 实线为当前接线，虚线为未接`;
      graphic = <>
        {EDGES.map(id => {
          const [a, b] = id.split("__");
          return <line key={id} data-preview-edge={id} data-connected={state.powerEdges.includes(id)} x1={NODES[a].x} y1={NODES[a].y} x2={NODES[b].x} y2={NODES[b].y} className={state.powerEdges.includes(id) ? "puzzle-preview__wire is-connected" : "puzzle-preview__wire"} />;
        })}
        {Object.entries(NODES).map(([id, node]) => <g key={id}><rect x={node.x - 39} y={node.y - 15} width="78" height="30" fill="#19343d" stroke="#91a99f" strokeWidth="2" /><text x={node.x} y={node.y + 5} textAnchor="middle">{node.label}</text></g>)}
        <text x="150" y="265" textAnchor="middle">点同一条线路可拆下</text>
      </>;
      break;
    }
    case "archive_index": {
      const rows = [state.archiveYearBand.replace("_", "–"), state.archiveFloor, LABELS[state.archivePurpose]];
      caption = `索引卡已填写 ${rows.filter(Boolean).length} / 3 项`;
      graphic = <>
        <rect x="25" y="25" width="250" height="230" fill="#d7ccac" stroke="#ae9765" strokeWidth="4" />
        <text x="45" y="54" className="puzzle-preview__ink">档案抽屉 · 当前检索卡</text>
        {rows.map((value, i) => <g key={i} data-preview-index={i}><text x="46" y={95 + i * 63} className="puzzle-preview__ink">{["年代", "楼层", "用途"][i]}</text><rect x="94" y={75 + i * 63} width="156" height="34" fill={value ? "#b7b591" : "#e9dfc4"} /><text x="104" y={97 + i * 63} className="puzzle-preview__ink">{value || "尚未选择"}</text></g>)}
      </>;
      break;
    }
    default: {
      const order = puzzleId === "duty_board" ? state.dutyOrder : state.evacuationOrder;
      const gap = order.length === 3 ? 74 : 58;
      caption = order.map((id, i) => `${i + 1} ${LABELS[id]}`).join(" → ");
      graphic = <>
        <path d="M43 35V248" stroke="#94a393" strokeWidth="3" />
        {order.map((id, index) => <g key={id} data-preview-order={id} className="puzzle-preview__moving" style={shifted(0, index * gap)}>
          <rect x="63" y="27" width="215" height="44" fill="#6b654a" stroke="#e6c477" strokeWidth="2" />
          <circle cx="43" cy="49" r="13" fill="#e6c477" /><text x="43" y="54" textAnchor="middle" className="puzzle-preview__ink">{index + 1}</text>
          <text x="77" y="54">{LABELS[id]}</text>
        </g>)}
        <text x="150" y="272" textAnchor="middle">{puzzleId === "duty_board" ? "夹板顺序 · 从上到下" : "当前路线 · 按编号依次经过"}</text>
      </>;
    }
  }
  return <div className="puzzle-preview" data-preview-id={puzzleId}>
    <svg viewBox="0 0 300 280" role="img" aria-label={caption}>{graphic}</svg>
    <output className="puzzle-preview__readout" aria-live="polite">{caption}</output>
  </div>;
}
