import { useEffect, useRef, useState } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import type { ChapterThreeInterludeVoiceClipId } from "../../../core/types";
import { kit } from "../../../modules/GameKit";

const CLIPS: ReadonlyArray<{
  id: ChapterThreeInterludeVoiceClipId;
  code: string;
  time: string;
  clue: string;
  cueId: string;
  waveform: readonly number[];
}> = [
  { id: "broadcast", code: "CLIP 3A", time: "22:45:00", clue: "电子广播尾音", cueId: "chapter35_voice_audition_broadcast", waveform: [2, 4, 7, 10, 5, 8, 3, 2] },
  { id: "stone", code: "CLIP 91", time: "--:--:--", clue: "船底短暂擦过硬质岸线", cueId: "chapter35_voice_audition_stone", waveform: [3, 8, 4, 3, 9, 4, 2, 1] },
  { id: "lake", code: "CLIP D7", time: "22:37:05", clue: "近处水声和左右桨声", cueId: "chapter35_voice_audition_lake", waveform: [2, 3, 4, 6, 4, 3, 5, 2] },
  { id: "lobby", code: "CLIP 4C", time: "--:--:--", clue: "玻璃门开启后出现大厅回声", cueId: "chapter35_voice_audition_lobby", waveform: [2, 6, 9, 6, 2, 7, 5, 2] }
];

export function VoiceMemosScene({ state, router, events }: SceneComponentProps) {
  const [order, setOrder] = useState<ChapterThreeInterludeVoiceClipId[]>(
    () => state.chapterThreeInterlude.voiceClipOrder
  );
  const [playing, setPlaying] = useState<ChapterThreeInterludeVoiceClipId | null>(null);
  const [heard, setHeard] = useState<ChapterThreeInterludeVoiceClipId[]>([]);
  const [feedback, setFeedback] = useState("");
  const playTimerRef = useRef<number | null>(null);

  useEffect(() => {
    const stopPreview = () => {
      if (playTimerRef.current !== null) window.clearTimeout(playTimerRef.current);
      playTimerRef.current = null;
      setPlaying(null);
    };
    const handleVisibility = () => {
      if (document.hidden) stopPreview();
    };
    document.addEventListener("visibilitychange", handleVisibility);
    return () => {
      document.removeEventListener("visibilitychange", handleVisibility);
      stopPreview();
    };
  }, []);

  function addClip(id: ChapterThreeInterludeVoiceClipId) {
    if (order.includes(id)) return;
    setOrder((current) => [...current, id]);
    setFeedback("");
  }

  function auditionClip(clip: typeof CLIPS[number]) {
    if (playTimerRef.current !== null) window.clearTimeout(playTimerRef.current);
    setPlaying(clip.id);
    setHeard((current) => current.includes(clip.id) ? current : [...current, clip.id]);
    events.emit(clip.cueId, { clipId: clip.id });
    playTimerRef.current = window.setTimeout(() => {
      setPlaying((current) => current === clip.id ? null : current);
      playTimerRef.current = null;
    }, 1200);
  }

  function submit() {
    const result = kit.chapterThreeInterlude.submitVoiceSequence(order);
    setFeedback(result === "accepted"
      ? "录音顺序已确认，广播在 22:45:00 结束。"
      : result === "locked"
        ? "先完成 CC98 记录收尾。"
        : "声场变化不连续。湖面之后应先经过石岸，再进入大厅。"
    );
  }

  return (
    <section className="voice-memos-scene app-screen" aria-label="语音备忘录">
      <header className="interlude-app-header">
        <PhoneNavButton kind="exit" label="退出语音备忘录" onClick={() => router.goTo("timeline_recovery")} />
        <div><small>VOICE MEMOS</small><h1>语音备忘录</h1></div>
        <span>{order.length}/4</span>
      </header>
      <main className="interlude-scroll">
        <section className="voice-order-strip" aria-label="当前录音顺序">
          {order.length ? order.map((id, index) => {
            const clip = CLIPS.find((item) => item.id === id)!;
            return <span key={id}><b>{index + 1}</b>{clip.code}</span>;
          }) : <p>先试听，再按发生顺序加入。</p>}
        </section>

        <section className="voice-clip-list">
          {CLIPS.map((clip) => {
            const listened = heard.includes(clip.id);
            const selected = order.includes(clip.id);
            return (
            <article
              key={clip.id}
              className={`${playing === clip.id ? "is-playing" : ""} ${selected ? "is-selected" : ""}`.trim()}
            >
              <button type="button" className="voice-play-dot" aria-label={`试听 ${clip.code}`} onClick={() => auditionClip(clip)}>
                {playing === clip.id ? "■" : "▶"}
              </button>
              <div><strong>{clip.code}</strong><small>{listened ? `${clip.clue} · ${clip.time}` : "未试听"}</small></div>
              <span className="voice-wave" aria-hidden="true">
                {clip.waveform.map((height, index) => <i key={index} style={{ height: `${height * 2}px` }} />)}
              </span>
              <button
                type="button"
                className="voice-add-button"
                disabled={selected || !listened}
                onClick={() => addClip(clip.id)}
              >{selected ? "已加入" : "加入顺序"}</button>
            </article>
          );})}
        </section>

        <div className="voice-actions">
          <button type="button" onClick={() => { setOrder([]); setFeedback(""); }}>清空顺序</button>
          <button type="button" onClick={submit}>核对录音</button>
        </div>
        {feedback ? <p className="interlude-feedback" role="status">{feedback}</p> : null}
      </main>
    </section>
  );
}
