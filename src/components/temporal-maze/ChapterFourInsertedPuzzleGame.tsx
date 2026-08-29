import { useEffect, useMemo, useRef, useState } from "react";
import {
  CHAPTER_FOUR_INSERTED_PUZZLES,
  type ChapterFourArchiveFloorId,
  type ChapterFourArchivePurposeId,
  type ChapterFourArchiveYearBandId,
  type ChapterFourDutyBoardCardId,
  type ChapterFourEvacuationSegmentId,
  type ChapterFourInsertedPuzzleAnswer,
  type ChapterFourInsertedPuzzleId,
  type ChapterFourPowerEdgeId
} from "../../modules/ChapterFourInsertedPuzzleModel";
import { CHAPTER_FOUR_INSERTED_PUZZLE_ASSET_BY_ID } from "../../scenes/rpg/ChapterFourInsertedPuzzleAssets";

const DUTY_LABELS: Readonly<Record<ChapterFourDutyBoardCardId, string>> = {
  classroom_104: "104 教室",
  classroom_105: "105 教室",
  main_elevator: "主电梯"
};

const EVACUATION_LABELS: Readonly<Record<ChapterFourEvacuationSegmentId, string>> = {
  open_study: "开放自习区",
  east_corridor: "东侧走廊",
  classroom_threshold: "教室门槛",
  lecture_202_exit: "202 出口"
};

const POWER_EDGE_LABELS: Readonly<Record<ChapterFourPowerEdgeId, string>> = {
  hall__west_corridor: "大厅 — 西侧走廊",
  hall__east_corridor: "大厅 — 东侧走廊",
  west_corridor__bakery_back_area: "西侧走廊 — 后区",
  east_corridor__classroom_zone: "东侧走廊 — 教室区",
  bakery_back_area__classroom_zone: "后区 — 教室区",
  west_corridor__east_corridor: "西侧走廊 — 东侧走廊",
  hall__classroom_zone: "大厅 — 教室区"
};

const POWER_EDGE_IDS = Object.freeze(Object.keys(POWER_EDGE_LABELS) as ChapterFourPowerEdgeId[]);

interface ChapterFourInsertedPuzzleGameProps {
  puzzleId: ChapterFourInsertedPuzzleId;
  mode: "light" | "dark";
  completed: boolean;
  prerequisiteReady: boolean;
  pending: boolean;
  feedback: string | null;
  onSubmit: (answer: ChapterFourInsertedPuzzleAnswer) => void;
  onClose: () => void;
}

export function ChapterFourInsertedPuzzleGame({
  puzzleId,
  mode,
  completed,
  prerequisiteReady,
  pending,
  feedback,
  onSubmit,
  onClose
}: ChapterFourInsertedPuzzleGameProps) {
  const definition = CHAPTER_FOUR_INSERTED_PUZZLES[puzzleId];
  const asset = CHAPTER_FOUR_INSERTED_PUZZLE_ASSET_BY_ID[puzzleId];
  const closeRef = useRef<HTMLButtonElement>(null);
  const [dutyOrder, setDutyOrder] = useState<ChapterFourDutyBoardCardId[]>([
    "main_elevator", "classroom_104", "classroom_105"
  ]);
  const [archiveYearBand, setArchiveYearBand] = useState<ChapterFourArchiveYearBandId | "">("");
  const [archiveFloor, setArchiveFloor] = useState<ChapterFourArchiveFloorId | "">("");
  const [archivePurpose, setArchivePurpose] = useState<ChapterFourArchivePurposeId | "">("");
  const [mediaAlignment, setMediaAlignment] = useState({ xOffset: 0, yOffset: 0, rotationQuarterTurns: 0 });
  const [calibration, setCalibration] = useState({ horizontal: 0, vertical: 0, pressure: 0 });
  const [powerEdges, setPowerEdges] = useState<ChapterFourPowerEdgeId[]>([]);
  const [evacuationOrder, setEvacuationOrder] = useState<ChapterFourEvacuationSegmentId[]>([
    "classroom_threshold", "open_study", "lecture_202_exit", "east_corridor"
  ]);

  useEffect(() => {
    const frame = window.requestAnimationFrame(() => closeRef.current?.focus());
    return () => window.cancelAnimationFrame(frame);
  }, [puzzleId, mode]);

  const answer = useMemo<ChapterFourInsertedPuzzleAnswer | null>(() => {
    switch (puzzleId) {
      case "duty_board":
        return { puzzleId, order: dutyOrder };
      case "archive_index":
        return archiveYearBand && archiveFloor && archivePurpose
          ? { puzzleId, yearBand: archiveYearBand, floor: archiveFloor, purpose: archivePurpose }
          : null;
      case "media_alignment":
        return { puzzleId, ...mediaAlignment };
      case "positioning_calibration":
        return { puzzleId, ...calibration };
      case "power_topology":
        return powerEdges.length === 5 ? { puzzleId, edgeIds: powerEdges } : null;
      case "evacuation_route":
        return { puzzleId, order: evacuationOrder };
    }
  }, [archiveFloor, archivePurpose, archiveYearBand, calibration, dutyOrder, evacuationOrder,
    mediaAlignment, powerEdges, puzzleId]);

  const observationOnly = mode === "dark";
  const operationLocked = !prerequisiteReady && puzzleId === "media_alignment";

  return (
    <div
      className={`chapter4-inserted-puzzle-overlay is-${mode}`}
      role="dialog"
      aria-modal="true"
      aria-labelledby="chapter4-inserted-puzzle-title"
      onKeyDown={(event) => {
        if (event.key === "Escape" && !pending) {
          event.preventDefault();
          onClose();
        }
      }}
    >
      <section className="chapter4-inserted-puzzle" data-puzzle-id={puzzleId}>
        <header className="chapter4-inserted-puzzle__header">
          <div>
            <p>{definition.locationLabel} · {mode === "dark" ? "深色观察" : "浅色操作"}</p>
            <h2 id="chapter4-inserted-puzzle-title">{definition.title}</h2>
          </div>
          <button ref={closeRef} type="button" disabled={pending} onClick={onClose} aria-label="返回现场">×</button>
        </header>

        <div className="chapter4-inserted-puzzle__body">
          <figure className="chapter4-inserted-puzzle__asset">
            <img src={asset.url} alt={`${definition.locationLabel}的${definition.title}装置`} draggable={false} />
            <figcaption>{observationOnly ? "观察残留痕迹" : "调整当前装置"}</figcaption>
          </figure>

          <div className="chapter4-inserted-puzzle__workspace">
            <p className="chapter4-inserted-puzzle__prompt">
              {observationOnly ? definition.darkPrompt : definition.lightPrompt}
            </p>

            {completed ? (
              <div className="chapter4-inserted-puzzle__complete" role="status">
                <strong>记录完成</strong>
                <span>{definition.successText}</span>
              </div>
            ) : operationLocked ? (
              <div className="chapter4-inserted-puzzle__locked" role="status">
                <strong>缺少可校准底片</strong>
                <span>先在 301 的胶片索引中取出旧导视胶片；两处调查仍可按任意顺序打开查看。</span>
              </div>
            ) : observationOnly ? (
              <ObservationTrace puzzleId={puzzleId} />
            ) : (
              <PuzzleControls
                puzzleId={puzzleId}
                pending={pending}
                dutyOrder={dutyOrder}
                setDutyOrder={setDutyOrder}
                archiveYearBand={archiveYearBand}
                setArchiveYearBand={setArchiveYearBand}
                archiveFloor={archiveFloor}
                setArchiveFloor={setArchiveFloor}
                archivePurpose={archivePurpose}
                setArchivePurpose={setArchivePurpose}
                mediaAlignment={mediaAlignment}
                setMediaAlignment={setMediaAlignment}
                calibration={calibration}
                setCalibration={setCalibration}
                powerEdges={powerEdges}
                setPowerEdges={setPowerEdges}
                evacuationOrder={evacuationOrder}
                setEvacuationOrder={setEvacuationOrder}
              />
            )}

            {feedback ? <p className="chapter4-inserted-puzzle__feedback" role="status">{feedback}</p> : null}
          </div>
        </div>

        <footer className="chapter4-inserted-puzzle__footer">
          <span>{observationOnly ? "线索会保留在本次调查记录中；关闭后可直接切换模式。" : "当前装置允许反复调整，提交失败不会重置。"}</span>
          {completed || observationOnly || operationLocked ? (
            <button type="button" disabled={pending} onClick={onClose}>返回现场</button>
          ) : (
            <button type="button" disabled={pending || answer === null} onClick={() => answer && onSubmit(answer)}>
              {pending ? "正在核对…" : "提交结果"}
            </button>
          )}
        </footer>
      </section>
    </div>
  );
}

function ObservationTrace({ puzzleId }: { puzzleId: ChapterFourInsertedPuzzleId }) {
  const traces: Readonly<Record<ChapterFourInsertedPuzzleId, readonly string[]>> = {
    duty_board: ["104：旧夹痕", "105：中段夹痕", "主电梯：最新夹痕"],
    archive_index: ["年代：九十年代末", "楼层：A3", "用途：入口导视"],
    media_alignment: ["横向：右移 2 格", "纵向：上移 1 格", "方向：顺时针 90°"],
    positioning_calibration: ["横向：−2", "纵向：+1", "压力：3 档"],
    power_topology: ["大厅分别连接两侧走廊", "两侧走廊分别连向两个末端区", "两个末端区互相连接"],
    evacuation_route: ["起点：开放自习区", "中段：东侧走廊、教室门槛", "终点：202 出口"]
  };
  return (
    <ol className="chapter4-inserted-puzzle__traces">
      {traces[puzzleId].map((trace) => <li key={trace}>{trace}</li>)}
    </ol>
  );
}

interface PuzzleControlsProps {
  puzzleId: ChapterFourInsertedPuzzleId;
  pending: boolean;
  dutyOrder: ChapterFourDutyBoardCardId[];
  setDutyOrder: (value: ChapterFourDutyBoardCardId[]) => void;
  archiveYearBand: ChapterFourArchiveYearBandId | "";
  setArchiveYearBand: (value: ChapterFourArchiveYearBandId | "") => void;
  archiveFloor: ChapterFourArchiveFloorId | "";
  setArchiveFloor: (value: ChapterFourArchiveFloorId | "") => void;
  archivePurpose: ChapterFourArchivePurposeId | "";
  setArchivePurpose: (value: ChapterFourArchivePurposeId | "") => void;
  mediaAlignment: { xOffset: number; yOffset: number; rotationQuarterTurns: number };
  setMediaAlignment: (value: { xOffset: number; yOffset: number; rotationQuarterTurns: number }) => void;
  calibration: { horizontal: number; vertical: number; pressure: number };
  setCalibration: (value: { horizontal: number; vertical: number; pressure: number }) => void;
  powerEdges: ChapterFourPowerEdgeId[];
  setPowerEdges: (value: ChapterFourPowerEdgeId[]) => void;
  evacuationOrder: ChapterFourEvacuationSegmentId[];
  setEvacuationOrder: (value: ChapterFourEvacuationSegmentId[]) => void;
}

function PuzzleControls(props: PuzzleControlsProps) {
  switch (props.puzzleId) {
    case "duty_board":
      return <OrderControls order={props.dutyOrder} labels={DUTY_LABELS} disabled={props.pending} onChange={props.setDutyOrder} />;
    case "archive_index":
      return (
        <div className="chapter4-inserted-puzzle__selects">
          <label>年代<select value={props.archiveYearBand} disabled={props.pending} onChange={(event) => props.setArchiveYearBand(event.target.value as ChapterFourArchiveYearBandId | "")}>
            <option value="">选择范围</option><option value="1977_1984">1977–1984</option><option value="1985_1990">1985–1990</option><option value="1991_1998">1991–1998</option>
          </select></label>
          <label>楼层<select value={props.archiveFloor} disabled={props.pending} onChange={(event) => props.setArchiveFloor(event.target.value as ChapterFourArchiveFloorId | "")}>
            <option value="">选择楼层</option><option value="A1">A1</option><option value="A2">A2</option><option value="A3">A3</option>
          </select></label>
          <label>用途<select value={props.archivePurpose} disabled={props.pending} onChange={(event) => props.setArchivePurpose(event.target.value as ChapterFourArchivePurposeId | "")}>
            <option value="">选择用途</option><option value="attendance">考勤</option><option value="wayfinding">入口导视</option><option value="maintenance">维修</option>
          </select></label>
        </div>
      );
    case "media_alignment":
      return <AxisControls values={props.mediaAlignment} labels={{ xOffset: "水平", yOffset: "垂直", rotationQuarterTurns: "旋转" }} ranges={{ xOffset: [-3, 3], yOffset: [-3, 3], rotationQuarterTurns: [0, 3] }} rotationKey="rotationQuarterTurns" disabled={props.pending} onChange={props.setMediaAlignment} />;
    case "positioning_calibration":
      return <AxisControls values={props.calibration} labels={{ horizontal: "横向", vertical: "纵向", pressure: "压力" }} ranges={{ horizontal: [-3, 3], vertical: [-3, 3], pressure: [0, 4] }} disabled={props.pending} onChange={props.setCalibration} />;
    case "power_topology":
      return (
        <div className="chapter4-inserted-puzzle__edges" role="group" aria-label="五区连线选择">
          {POWER_EDGE_IDS.map((edgeId) => {
            const selected = props.powerEdges.includes(edgeId);
            return <button key={edgeId} type="button" aria-pressed={selected} className={selected ? "is-selected" : ""} disabled={props.pending || (!selected && props.powerEdges.length >= 5)} onClick={() => props.setPowerEdges(selected ? props.powerEdges.filter((item) => item !== edgeId) : [...props.powerEdges, edgeId])}>{POWER_EDGE_LABELS[edgeId]}</button>;
          })}
          <small>已保留 {props.powerEdges.length} / 5 条</small>
        </div>
      );
    case "evacuation_route":
      return <OrderControls order={props.evacuationOrder} labels={EVACUATION_LABELS} disabled={props.pending} onChange={props.setEvacuationOrder} />;
  }
}

function OrderControls<T extends string>({ order, labels, disabled, onChange }: {
  order: T[];
  labels: Readonly<Record<T, string>>;
  disabled: boolean;
  onChange: (value: T[]) => void;
}) {
  function move(index: number, delta: number) {
    const nextIndex = index + delta;
    if (nextIndex < 0 || nextIndex >= order.length) return;
    const next = [...order];
    [next[index], next[nextIndex]] = [next[nextIndex], next[index]];
    onChange(next);
  }
  return (
    <ol className="chapter4-inserted-puzzle__order">
      {order.map((id, index) => (
        <li key={id}>
          <span>{index + 1}</span><strong>{labels[id]}</strong>
          <button type="button" aria-label={`${labels[id]}前移`} disabled={disabled || index === 0} onClick={() => move(index, -1)}>←</button>
          <button type="button" aria-label={`${labels[id]}后移`} disabled={disabled || index === order.length - 1} onClick={() => move(index, 1)}>→</button>
        </li>
      ))}
    </ol>
  );
}

function AxisControls<T extends Record<string, number>>({ values, labels, ranges, rotationKey, disabled, onChange }: {
  values: T;
  labels: Readonly<Record<keyof T, string>>;
  ranges: Readonly<Record<keyof T, readonly [number, number]>>;
  rotationKey?: keyof T;
  disabled: boolean;
  onChange: (value: T) => void;
}) {
  return (
    <div className="chapter4-inserted-puzzle__axes">
      {(Object.keys(values) as Array<keyof T>).map((key) => {
        const [min, max] = ranges[key];
        const display = key === rotationKey ? `${values[key] * 90}°` : `${values[key] > 0 ? "+" : ""}${values[key]}`;
        return (
          <label key={String(key)}>
            <span>{labels[key]}</span>
            <button type="button" disabled={disabled || values[key] <= min} onClick={() => onChange({ ...values, [key]: values[key] - 1 })}>−</button>
            <output>{display}</output>
            <button type="button" disabled={disabled || values[key] >= max} onClick={() => onChange({ ...values, [key]: values[key] + 1 })}>＋</button>
          </label>
        );
      })}
    </div>
  );
}
