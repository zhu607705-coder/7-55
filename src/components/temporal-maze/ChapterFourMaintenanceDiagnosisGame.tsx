import { useEffect, useRef, useState } from "react";
import type {
  ChapterFourMaintenanceCauseId,
  ChapterFourMaintenanceDiagnosisAnswers,
  ChapterFourMaintenanceSymptomId
} from "../../modules/ChapterFourTemporalMazeController";

const SYMPTOMS: ReadonlyArray<{ id: ChapterFourMaintenanceSymptomId; title: string; observation: string }> = [
  { id: "wheel_sound", title: "车轮声音", observation: "推车起步时轮罩先响，车轮随后才停。" },
  { id: "clock_jam", title: "旧钟卡滞", observation: "秒轮到同一齿位会回弹，拨动后仍重复。" },
  { id: "oil_trace", title: "油迹", observation: "轮轴边只有干涸油圈，地面没有新鲜滴落。" }
];

const CAUSES: ReadonlyArray<{ id: ChapterFourMaintenanceCauseId; label: string }> = [
  { id: "latch", label: "卡扣" },
  { id: "oil_shortage", label: "缺油" },
  { id: "gear_offset", label: "齿轮偏位" },
  { id: "power_loss", label: "供电中断" },
  { id: "foreign_object", label: "异物堵塞" }
];

export function ChapterFourMaintenanceDiagnosisGame({
  pending,
  feedback,
  onSubmit,
  onClose
}: {
  pending: boolean;
  feedback: string | null;
  onSubmit: (answers: ChapterFourMaintenanceDiagnosisAnswers) => void;
  onClose: () => void;
}) {
  const firstSelectRef = useRef<HTMLSelectElement>(null);
  const [answers, setAnswers] = useState<Partial<ChapterFourMaintenanceDiagnosisAnswers>>({});
  const complete = SYMPTOMS.every(({ id }) => Boolean(answers[id]));

  useEffect(() => { firstSelectRef.current?.focus(); }, []);

  return (
    <div className="chapter4-maintenance-diagnosis-overlay" role="dialog" aria-modal="true" aria-labelledby="chapter4-maintenance-diagnosis-title">
      <section className="chapter4-maintenance-diagnosis">
        <header>
          <p>22:45 · 维修记录</p>
          <h2 id="chapter4-maintenance-diagnosis-title">根据三处现象判断故障原因</h2>
          <span>每项现象选择一个原因，提交前可以改选。</span>
        </header>
        <div className="chapter4-maintenance-diagnosis__observations">
          {SYMPTOMS.map((symptom, index) => (
            <label key={symptom.id}>
              <strong>{symptom.title}</strong>
              <span>{symptom.observation}</span>
              <select
                ref={index === 0 ? firstSelectRef : undefined}
                value={answers[symptom.id] ?? ""}
                disabled={pending}
                onChange={(event) => setAnswers((current) => ({
                  ...current,
                  [symptom.id]: event.target.value as ChapterFourMaintenanceCauseId
                }))}
              >
                <option value="">选择原因</option>
                {CAUSES.map((cause) => <option key={cause.id} value={cause.id}>{cause.label}</option>)}
              </select>
            </label>
          ))}
        </div>
        {feedback ? <p className="chapter4-maintenance-diagnosis__feedback" role="status">{feedback}</p> : null}
        <footer>
          <button type="button" className="is-secondary" disabled={pending} onClick={onClose}>返回现场</button>
          <button type="button" disabled={!complete || pending} onClick={() => onSubmit(answers as ChapterFourMaintenanceDiagnosisAnswers)}>
            {pending ? "正在核对…" : "提交诊断"}
          </button>
        </footer>
      </section>
    </div>
  );
}
