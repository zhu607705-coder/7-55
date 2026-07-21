import { useEffect, useRef, useState } from "react";
import type { SceneRouter } from "../../../core/SceneRouter";
import type {
  LibraryFinalsAuditValues,
  LibraryFinalsPhase,
  LibraryFinalsPuzzleState,
  LibraryLocationId
} from "../../../core/types";
import { ITEM_CATALOG } from "../../../data/itemCatalog";
import libraryFinalsContent from "../../../data/library-finals.content.json";
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
  sourceIndex: "01" | "02" | "03";
  sourceHint: string;
}> = [
  {
    field: "arrivalMinutes",
    label: "到座耗时",
    unit: "分钟",
    min: 0,
    max: 12,
    stateKey: "auditArrivalMinutes",
    sourceIndex: "01",
    sourceHint: "入口小屏 · 计算时间差"
  },
  {
    field: "publicNoticeFloor",
    label: "公示编号",
    unit: "号",
    min: 1,
    max: 63,
    stateKey: "auditPublicNoticeFloor",
    sourceIndex: "02",
    sourceHint: "CC98 楼主编辑 · 读取编号"
  },
  {
    field: "proofCount",
    label: "证明数量",
    unit: "项",
    min: 1,
    max: 5,
    stateKey: "auditProofCount",
    sourceIndex: "03",
    sourceHint: "旧版规则 · 统计类别"
  }
];

const PUBLIC_NOTICE_NUMBER = libraryFinalsContent.cc98.post.publicNoticeFloor;
const RULE_REQUIREMENTS = ITEM_CATALOG.archivedLeaveRule.document?.body.filter((line) => /^[一二三]、/.test(line)) ?? [];

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
    return "逐项核对：入口小屏算时间差，CC98 楼主编辑读编号，旧版规则统计证明类别。";
  }
  if (attempt === 2) {
    return "入馆记录看两次时间；23 是 CC98 回复楼层；证明数量来自旧版规则正文。";
  }
  return "仍有字段与材料原文不一致。请按每张材料卡右侧标出的字段重新核对。";
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
        <div className="tiyi-audit-heading">
          <strong className="tiyi-audit-title">{passed ? "补录成功" : "本人来过证明补录单"}</strong>
          <span className="tiyi-audit-status">{passed ? "系统已承认你确实来过图书馆" : "待补录 · 先核对下方三项调查材料"}</span>
        </div>
        <span className="tiyi-audit-form-code">{passed ? "已认证" : "表单 022"}</span>
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

      <section className="tiyi-audit-guide" aria-label="补录方法">
        <strong>三项材料从哪里取得</strong>
        <ul>
          <li><span>01 图书馆入口小屏</span><em>填写到座耗时</em></li>
          <li><span>02 CC98 调查帖楼主编辑</span><em>填写公示编号</em></li>
          <li><span>03 二楼南区 755 书架旧版规则</span><em>填写证明数量</em></li>
        </ul>
        <small>三项材料可按任意顺序收集；取得后，下方会显示可核对的原文。</small>
      </section>

      <section className="tiyi-audit-sources" aria-label="审核依据">
        <article id="tiyi-audit-source-01" className={puzzle.entranceRecordRead ? "is-ready" : ""}>
          <span>01</span>
          <div>
            <strong>图书馆入口小屏 <em>填：到座耗时</em></strong>
            {puzzle.entranceRecordRead ? (
              <>
                <small className="tiyi-audit-source-evidence"><b>07:55</b> 主馆入口 <i>→</i> <b>08:02</b> 二楼南区 022</small>
                <small>填写两次记录的分钟差</small>
              </>
            ) : <small>未取得 · 回到基础图书馆入口，查看门禁记录小屏</small>}
          </div>
        </article>
        <article id="tiyi-audit-source-02" className={puzzle.investigationOpened ? "is-ready" : ""}>
          <span>02</span>
          <div>
            <strong>CC98 调查帖 · 23 楼楼主编辑 <em>填：公示编号</em></strong>
            {puzzle.investigationOpened ? (
              <>
                <small className="tiyi-audit-source-evidence">楼主编辑原文：旧申请统一挂在 <b>公示编号 {PUBLIC_NOTICE_NUMBER}</b></small>
                <small>23 是回复楼层；填写原文中的公示编号</small>
              </>
            ) : <small>未取得 · 在 022 座位拿到占座纸条，用它打开 CC98 调查帖</small>}
          </div>
        </article>
        <article id="tiyi-audit-source-03" className={puzzle.archivedRuleRead ? "is-ready" : ""}>
          <span>03</span>
          <div>
            <strong>《旧版临时离座恢复规定》 <em>填：证明数量</em></strong>
            {puzzle.archivedRuleRead ? (
              <>
                <small className="tiyi-audit-rule-evidence">
                  {RULE_REQUIREMENTS.map((requirement) => <span key={requirement}>{requirement.replace(/^[一二三]、/, "").replace(/；$/, "")}</span>)}
                </small>
                <small>填写规则列出的证明类别数量</small>
              </>
            ) : <small>未取得 · 在二楼南区 755 书架使用“索书号 755”，取得并阅读规则</small>}
          </div>
        </article>
      </section>

      {!passed ? (
        <>
          <div className="tiyi-audit-steppers">
            {CONTROLS.map((control) => {
              const value = values[control.field];
              return (
                <section
                  className={steppingField === control.field ? "is-stepping" : ""}
                  key={control.field}
                  aria-label={control.label}
                  aria-describedby={`tiyi-audit-source-${control.sourceIndex}`}
                >
                  <span>{control.label}<small>来源 {control.sourceIndex} · {control.sourceHint}</small></span>
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
              ? "三项材料均取得后可提交；收集顺序不限。"
              : attempt > 0
                ? rejectionHint(attempt)
                : "三项材料原文已齐，可以逐项填写。"}
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
