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
  const [activeSymptom, setActiveSymptom] = useState<ChapterFourMaintenanceSymptomId>("wheel_sound");
  const [replay, setReplay] = useState(0);
  const active = SYMPTOMS.find(({ id }) => id === activeSymptom)!;
  const complete = SYMPTOMS.every(({ id }) => Boolean(answers[id]));

  useEffect(() => { firstSelectRef.current?.focus(); }, []);

  return (
    <div className="rpg-overlay-layer chapter4-maintenance-diagnosis-overlay" role="dialog" aria-modal="true" aria-labelledby="chapter4-maintenance-diagnosis-title">
      <section className="chapter4-maintenance-diagnosis">
        <header>
          <p>22:45 · 维修记录</p>
          <h2 id="chapter4-maintenance-diagnosis-title">先查故障，再填报修单</h2>
          <span>每种现象选一个原因。写错还能改，总比再报一次强。</span>
        </header>
        <div className="chapter4-maintenance-diagnosis__body">
          <figure className="puzzle-preview maintenance-preview" data-symptom={activeSymptom}>
            <figcaption>故障近景 · {active.title}</figcaption>
            <svg viewBox="0 0 300 220" role="img" aria-label={active.observation} key={`${activeSymptom}-${replay}`}>
              {activeSymptom === "clock_jam" ? <>
                <path d="M35 54H264V189H35Z" fill="#34464a" stroke="#8eaaa1" strokeWidth="4" />
                <g transform="translate(143 122)"><g className="maintenance-preview__jam">
                  {Array.from({ length: 12 }, (_, i) => <rect key={i} x="-6" y="-60" width="12" height="16" fill="#d0b778" transform={`rotate(${i * 30})`} />)}
                  <circle r="47" fill="#938363" stroke="#e5cd92" strokeWidth="4" /><path d="M0 -36V36M-36 0H36" stroke="#e5cd92" strokeWidth="7" /><circle r="10" fill="#223943" />
                </g></g>
                <path d="M208 104L198 122L208 140" fill="none" stroke="#ffce76" strokeWidth="4" />
                <text x="26" y="30">同一齿位反复回弹</text>
              </> : <>
                <path d="M42 38H243V108H42Z" fill="#465b5a" stroke="#8eaaa1" strokeWidth="4" />
                <g transform="translate(148 147)"><g className={activeSymptom === "wheel_sound" ? "maintenance-preview__wheel" : ""}>
                  <circle r="45" fill="#14252c" stroke="#91a7a0" strokeWidth="10" /><path d="M0 -38V38M-38 0H38" stroke="#91a7a0" strokeWidth="5" />
                </g></g>
                {activeSymptom === "wheel_sound" ? <g className="maintenance-preview__cover"><path d="M89 142V118Q148 66 207 118V142" fill="none" stroke="#d7bc78" strokeWidth="10" /><path d="M222 96L232 86M229 115H245" stroke="#ffce76" strokeWidth="3" /></g> : <>
                  <circle cx="148" cy="147" r="13" fill="#a77c45" /><circle cx="148" cy="147" r="22" fill="none" stroke="#bc9655" strokeWidth="3" strokeDasharray="7 5" />
                  <path d="M174 143H245" stroke="#f2cc7f" strokeWidth="2" /><text x="186" y="131">干涸油圈</text>
                </>}
                <path d="M32 202H271" stroke="#748880" strokeWidth="3" />
                <text x="25" y="25">{activeSymptom === "wheel_sound" ? "轮罩先响 → 车轮停住" : "地面无新鲜滴落"}</text>
              </>}
            </svg>
            <output className="puzzle-preview__readout" aria-live="polite">当前推测：{CAUSES.find(({ id }) => id === answers[activeSymptom])?.label ?? "尚未选择"} · 提交后核对</output>
            <button type="button" disabled={pending} onClick={() => setReplay(value => value + 1)}>重看故障现象</button>
          </figure>
        <div className="chapter4-maintenance-diagnosis__observations">
          {SYMPTOMS.map((symptom, index) => (
            <label key={symptom.id} className={activeSymptom === symptom.id ? "is-active" : ""}>
              <strong>{symptom.title}</strong>
              <span>{symptom.observation}</span>
              <select
                ref={index === 0 ? firstSelectRef : undefined}
                value={answers[symptom.id] ?? ""}
                disabled={pending}
                onFocus={() => setActiveSymptom(symptom.id)}
                onChange={(event) => { setActiveSymptom(symptom.id); setAnswers((current) => ({
                  ...current,
                  [symptom.id]: event.target.value as ChapterFourMaintenanceCauseId
                })); }}
              >
                <option value="">选择原因</option>
                {CAUSES.map((cause) => <option key={cause.id} value={cause.id}>{cause.label}</option>)}
              </select>
            </label>
          ))}
        </div>
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
