import { useEffect, useRef, useState } from "react";
import type { SceneRouter } from "../../../core/SceneRouter";
import type {
  LibraryFinalsAuditValues,
  LibraryFinalsPhase,
  LibraryFinalsPuzzleState,
  LibraryLocationId
} from "../../../core/types";
import { kit } from "../../../modules/GameKit";

interface RouteAuditPanelProps {
  phase: LibraryFinalsPhase;
  puzzle: LibraryFinalsPuzzleState;
  router: Pick<SceneRouter, "goTo">;
}

type AuditField = keyof LibraryFinalsAuditValues;

const DEFAULT_VALUES: LibraryFinalsAuditValues = {
  arrivalMinutes: 5,
  publicNoticeFloor: 45,
  proofCount: 1
};

const CONTROLS: Array<{
  field: AuditField;
  label: string;
  unit: string;
  min: number;
  max: number;
  stateKey: "auditArrivalMinutes" | "auditPublicNoticeFloor" | "auditProofCount";
}> = [
  { field: "arrivalMinutes", label: "到座耗时", unit: "分钟", min: 0, max: 12, stateKey: "auditArrivalMinutes" },
  { field: "publicNoticeFloor", label: "公示编号", unit: "号", min: 1, max: 63, stateKey: "auditPublicNoticeFloor" },
  { field: "proofCount", label: "证明数量", unit: "项", min: 1, max: 5, stateKey: "auditProofCount" }
];

const LOCATION_LABELS: Record<LibraryLocationId, string> = {
  entrance: "图书馆入口",
  seat_022: "022",
  front_desk: "前台",
  lost_found: "失物招领",
  catalog_terminal: "馆藏检索",
  printer: "打印机",
  shelf_755: "书架背面"
};

function currentValues(puzzle: LibraryFinalsPuzzleState): LibraryFinalsAuditValues {
  return {
    arrivalMinutes: puzzle.auditArrivalMinutes || DEFAULT_VALUES.arrivalMinutes,
    publicNoticeFloor: puzzle.auditPublicNoticeFloor || DEFAULT_VALUES.publicNoticeFloor,
    proofCount: puzzle.auditProofCount || DEFAULT_VALUES.proofCount
  };
}

function rejectionHint(attempt: number): string {
  if (attempt <= 1) {
    return "至少一个字段与已保存的来源不一致。";
  }
  if (attempt === 2) {
    return "三个字段要分别核对三种来源，不能用路线长度互相推算。";
  }
  return "回到入馆记录、CC98 公示和旧版规则，逐项查看对应字段。";
}

/** 后期体艺只认证已收集的路线证据，不再控制 RPG 移动。 */
export function RouteAuditPanel({ phase, puzzle, router }: RouteAuditPanelProps) {
  const [visibleAttempt, setVisibleAttempt] = useState<number | null>(null);
  const [motion, setMotion] = useState<"idle" | "rejected" | "approved">("idle");
  const [steppingField, setSteppingField] = useState<AuditField | null>(null);
  const motionTimerRef = useRef<number | null>(null);
  const stepTimerRef = useRef<number | null>(null);
  const values = currentValues(puzzle);
  const recordedRoute = puzzle.libraryVisitedPoints.map((point) => LOCATION_LABELS[point]);
  const sourceReady = puzzle.entranceRecordRead && puzzle.investigationOpened && puzzle.archivedRuleRead;
  const passed = puzzle.presenceProofCollected;
  const attempt = Math.max(puzzle.auditAttemptCount, visibleAttempt ?? 0);

  function step(field: AuditField, value: number) {
    setVisibleAttempt(null);
    setMotion("idle");
    setSteppingField(field);
    if (stepTimerRef.current !== null) window.clearTimeout(stepTimerRef.current);
    stepTimerRef.current = window.setTimeout(() => {
      stepTimerRef.current = null;
      setSteppingField(null);
    }, 260);
    kit.libraryFinals.setAuditValue(field, value);
  }

  function submit() {
    if (!sourceReady || phase !== "evidence_gathering") {
      return;
    }
    const accepted = kit.libraryFinals.submitAudit(values);
    setMotion(accepted ? "approved" : "rejected");
    if (motionTimerRef.current !== null) window.clearTimeout(motionTimerRef.current);
    motionTimerRef.current = window.setTimeout(() => {
      motionTimerRef.current = null;
      setMotion("idle");
    }, accepted ? 1320 : 820);
    if (accepted) {
      setVisibleAttempt(null);
      return;
    }
    setVisibleAttempt(puzzle.auditAttemptCount + 1);
  }

  useEffect(() => () => {
    if (motionTimerRef.current !== null) window.clearTimeout(motionTimerRef.current);
    if (stepTimerRef.current !== null) window.clearTimeout(stepTimerRef.current);
  }, []);

  return (
    <section
      className={`tiyi-audit-panel tiyi-audit-v2 ${passed ? "is-passed" : ""} ${motion === "rejected" ? "is-audit-rollback" : ""} ${motion === "approved" ? "is-audit-approved" : ""}`.trim()}
      aria-label="本人来过证明补录单"
    >
      {motion !== "idle" ? <i className="tiyi-audit-sweep" aria-hidden="true" /> : null}
      <header>
        <div>
          <strong>{passed ? "补录成功" : "本人来过证明补录单"}</strong>
          <span>{passed ? "系统已承认你确实来过图书馆" : "状态：待补录 · 路线真实，但字段不像真的"}</span>
        </div>
        <b>{passed ? "已认证" : "V0.22"}</b>
      </header>

      <section className="tiyi-recorded-route" aria-label="已记录的图书馆路线">
        <strong>检测到室内异常锻炼路线</strong>
        <div>
          <span>寝室</span>
          {recordedRoute.map((label, index) => (
            <span key={`${label}-${index}`}>{label}</span>
          ))}
        </div>
      </section>

      <section className="tiyi-audit-sources" aria-label="审核依据">
        <article className={puzzle.entranceRecordRead ? "is-ready" : ""}>
          <span>01</span>
          <div><strong>入馆记录</strong><small>{puzzle.entranceRecordRead ? "来源已读取 · 可用于补录" : "来源未读取"}</small></div>
        </article>
        <article className={puzzle.investigationOpened ? "is-ready" : ""}>
          <span>02</span>
          <div><strong>CC98 公示</strong><small>{puzzle.investigationOpened ? "来源已建立 · 可用于补录" : "来源未建立"}</small></div>
        </article>
        <article className={puzzle.archivedRuleRead ? "is-ready" : ""}>
          <span>03</span>
          <div><strong>旧版规则</strong><small>{puzzle.archivedRuleRead ? "内容已阅读 · 可用于补录" : "规则尚未读完"}</small></div>
        </article>
      </section>

      {!passed ? (
        <>
          <div className="tiyi-audit-steppers">
            {CONTROLS.map((control) => {
              const value = values[control.field];
              return (
                <section className={steppingField === control.field ? "is-stepping" : ""} key={control.field} aria-label={control.label}>
                  <span>{control.label}</span>
                  <div>
                    <button type="button" aria-label={`${control.label}减一`} disabled={value <= control.min} onClick={() => step(control.field, value - 1)}>−</button>
                    <strong key={`${control.field}-${value}`}>{value}<small>{control.unit}</small></strong>
                    <button type="button" aria-label={`${control.label}加一`} disabled={value >= control.max} onClick={() => step(control.field, value + 1)}>+</button>
                  </div>
                </section>
              );
            })}
          </div>
          <button type="button" className="tiyi-audit-submit" disabled={!sourceReady || phase !== "evidence_gathering"} onClick={submit}>提交补录</button>
          <p aria-live="polite">
            {!sourceReady
              ? "三份依据还没有齐全，表格拒绝替你编事实。"
              : attempt > 0
                ? rejectionHint(attempt)
                : "三项字段分别对应三份已保存的证据。"}
          </p>
        </>
      ) : (
        <section className="tiyi-presence-proof-result">
          <i className="tiyi-proof-stamp" aria-hidden="true">已认证</i>
          <strong>本人来过证明</strong>
          <p>一张证明你来过的证明。它没有证明你为什么要来。</p>
          <dl aria-label="已验证补录值">
            <div><dt>到座耗时</dt><dd>{puzzle.auditArrivalMinutes} 分钟</dd></div>
            <div><dt>公示编号</dt><dd>{puzzle.auditPublicNoticeFloor}</dd></div>
            <div><dt>证明数量</dt><dd>{puzzle.auditProofCount} 项</dd></div>
          </dl>
          <button type="button" className="tiyi-audit-return" onClick={() => router.goTo("phone_home")}>返回手机主页</button>
        </section>
      )}
    </section>
  );
}
