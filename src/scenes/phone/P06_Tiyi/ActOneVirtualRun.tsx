import { useEffect, useState, type CSSProperties } from "react";

const RUN_TARGET_DISTANCE_KM = 3;
const RUN_TARGET_MINUTES = 10;

const RUN_FIXES = Object.freeze([
  { x: 50, y: 84, label: "南直道" },
  { x: 30, y: 80, label: "西南弯" },
  { x: 16, y: 65, label: "西弯道" },
  { x: 16, y: 40, label: "西北弯" },
  { x: 30, y: 23, label: "北直道西" },
  { x: 55, y: 18, label: "北直道东" },
  { x: 78, y: 28, label: "东北弯" },
  { x: 86, y: 50, label: "东弯道" },
  { x: 78, y: 73, label: "东南弯" },
  { x: 60, y: 83, label: "终点线" }
] as const);

interface ActOneVirtualRunProps {
  participantName: string;
  onClose: () => void;
  onComplete: () => boolean;
}

function formatRunTime(minutes: number): string {
  return `${String(minutes).padStart(2, "0")}:00`;
}

export function ActOneVirtualRun({ participantName, onClose, onComplete }: ActOneVirtualRunProps) {
  const [recordedFixes, setRecordedFixes] = useState(0);
  const [feedback, setFeedback] = useState("点击发光定位点，生成第 1 分钟的运动轨迹。");
  const [completed, setCompleted] = useState(false);

  const elapsedMinutes = Math.min(RUN_TARGET_MINUTES, recordedFixes);
  const distanceKm = Math.min(RUN_TARGET_DISTANCE_KM, recordedFixes * 0.3);
  const lapCount = recordedFixes * 0.75;
  const routeProgress = recordedFixes / RUN_FIXES.length;
  const runnerFix = RUN_FIXES[Math.max(0, Math.min(recordedFixes - 1, RUN_FIXES.length - 1))];

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key !== "Escape") return;
      event.preventDefault();
      onClose();
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [onClose]);

  useEffect(() => {
    const previousRender = window.render_game_to_text;
    const renderWithVirtualRun = () => {
      let base: Record<string, unknown> = {};
      try {
        base = JSON.parse(previousRender()) as Record<string, unknown>;
      } catch {
        base = {};
      }
      return JSON.stringify({
        ...base,
        tiyiVirtualRun: {
          coordinateSystem: "track percentages, origin at top-left, x right, y down",
          status: completed ? "complete" : recordedFixes === 0 ? "ready" : "running",
          participantName,
          recordedFixes,
          targetFixes: RUN_FIXES.length,
          elapsedMinutes,
          distanceKm: Number(distanceKm.toFixed(2)),
          pace: recordedFixes === 0 ? null : "03:20/km",
          lapCount: Number(lapCount.toFixed(2)),
          nextFix: completed ? null : recordedFixes + 1,
          feedback
        }
      });
    };
    window.render_game_to_text = renderWithVirtualRun;
    return () => {
      if (window.render_game_to_text === renderWithVirtualRun) {
        window.render_game_to_text = previousRender;
      }
    };
  }, [completed, distanceKm, elapsedMinutes, feedback, lapCount, participantName, recordedFixes]);

  function recordFix(index: number) {
    if (completed) return;
    if (index < recordedFixes) {
      setFeedback(`第 ${index + 1} 分钟已经记录。当前需要第 ${recordedFixes + 1} 个定位点。`);
      return;
    }
    if (index > recordedFixes) {
      setFeedback(`定位漂移：请先补齐第 ${recordedFixes + 1} 分钟。`);
      return;
    }

    const nextFixCount = recordedFixes + 1;
    setRecordedFixes(nextFixCount);
    if (nextFixCount < RUN_FIXES.length) {
      setFeedback(`第 ${nextFixCount} 分钟定位成功。继续戳中第 ${nextFixCount + 1} 个定位点。`);
      return;
    }

    if (!onComplete()) {
      setRecordedFixes(RUN_FIXES.length - 1);
      setFeedback("参加者身份失效。请退出后重新确认。");
      return;
    }
    setCompleted(true);
    setFeedback("10 分钟定位回放完成，3.00 公里锻炼记录已同步。");
  }

  return (
    <section
      className={`tiyi-virtual-run ${completed ? "is-complete" : ""}`}
      role="dialog"
      aria-modal="true"
      aria-label="课外锻炼虚拟定位"
      data-run-status={completed ? "complete" : recordedFixes === 0 ? "ready" : "running"}
      data-recorded-fixes={recordedFixes}
    >
      <header className="tiyi-virtual-run-header">
        <div>
          <span>VIRTUAL GPS · 紫云田径场</span>
          <strong>{completed ? "课外锻炼已同步" : "10 分钟跑完 3 km"}</strong>
        </div>
        <button type="button" onClick={onClose} aria-label={completed ? "返回体艺首页" : "退出本次定位"}>×</button>
      </header>

      <div className="tiyi-run-stat-grid" aria-label="本次锻炼数据">
        <section>
          <span>用时</span>
          <strong key={`time-${recordedFixes}`}>{formatRunTime(elapsedMinutes)}</strong>
        </section>
        <section>
          <span>距离</span>
          <strong key={`distance-${recordedFixes}`}>{distanceKm.toFixed(2)} <small>km</small></strong>
        </section>
        <section>
          <span>平均配速</span>
          <strong>{recordedFixes === 0 ? "--'--\"" : "03'20\""}</strong>
        </section>
      </div>

      <div className="tiyi-run-track-board">
        <svg className="tiyi-run-track-graphic" viewBox="0 0 340 330" aria-hidden="true">
          <rect x="8" y="8" width="324" height="314" rx="22" className="tiyi-run-campus-ground" />
          <path className="tiyi-run-track-outer" d="M95 274C38 274 38 56 95 56H245C302 56 302 274 245 274Z" />
          <path className="tiyi-run-track-lane" d="M95 274C38 274 38 56 95 56H245C302 56 302 274 245 274Z" />
          <path className="tiyi-run-track-centerline" d="M95 274C38 274 38 56 95 56H245C302 56 302 274 245 274Z" />
          <path
            className="tiyi-run-track-progress"
            d="M170 274H95C38 274 38 56 95 56H245C302 56 302 274 245 274H170"
            pathLength="1"
            style={{ "--run-progress": routeProgress } as CSSProperties}
          />
          <rect x="104" y="92" width="132" height="146" rx="6" className="tiyi-run-field" />
          <line x1="170" y1="92" x2="170" y2="238" className="tiyi-run-field-line" />
          <circle cx="170" cy="165" r="28" className="tiyi-run-field-line" />
          <path d="M151 251H189" className="tiyi-run-finish-line" />
          <text x="170" y="145" className="tiyi-run-field-title">ZJU SPORTS</text>
          <text x="170" y="165" className="tiyi-run-field-subtitle">虚拟轨迹回放</text>
          <text x="170" y="191" className="tiyi-run-lap-label">{lapCount.toFixed(2)} / 7.50 圈</text>
        </svg>

        <div
          className={`tiyi-run-runner ${recordedFixes > 0 ? "is-moving" : ""}`}
          style={{ "--runner-x": `${runnerFix.x}%`, "--runner-y": `${runnerFix.y}%` } as CSSProperties}
          aria-hidden="true"
        >
          <i className="head" />
          <i className="body" />
          <i className="leg left" />
          <i className="leg right" />
        </div>

        {RUN_FIXES.map((fix, index) => {
          const visited = index < recordedFixes;
          const target = index === recordedFixes && !completed;
          return (
            <button
              key={fix.label}
              type="button"
              className={`tiyi-run-fix ${visited ? "is-visited" : ""} ${target ? "is-target" : ""}`}
              style={{ "--fix-x": `${fix.x}%`, "--fix-y": `${fix.y}%` } as CSSProperties}
              aria-label={`第 ${index + 1} 分钟定位点：${fix.label}${visited ? "，已记录" : target ? "，当前目标" : "，尚未解锁"}`}
              aria-current={target ? "step" : undefined}
              aria-pressed={visited}
              onClick={() => recordFix(index)}
            >
              {visited ? "✓" : index + 1}
            </button>
          );
        })}

        <aside className="tiyi-run-gps-card" aria-label="定位状态">
          <span>GPS</span>
          <strong>{recordedFixes === 0 ? "等待首个点" : completed ? "轨迹锁定" : `精度 ±${Math.max(4, 13 - recordedFixes)} m`}</strong>
        </aside>
      </div>

      <footer className="tiyi-run-feedback">
        <p aria-live="polite">{feedback}</p>
        <small>{completed ? `${participantName} · 记录编号 PE-0755-3000` : "触屏点按发光目标；键盘使用 Tab 与 Enter / Space。"}</small>
      </footer>

      {completed ? (
        <section className="tiyi-run-completion" aria-label="课外锻炼完成">
          <span>TRACK ACCEPTED</span>
          <strong>10:00</strong>
          <b>3.00 KM · 03'20\" / KM</b>
          <p>十个定位点已完成，课外锻炼记录正式生效。</p>
          <button type="button" onClick={onClose}>返回体艺首页</button>
        </section>
      ) : null}
    </section>
  );
}
