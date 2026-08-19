import { useState } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import type {
  ChapterThreeInterludeDecoyId,
  ChapterThreeInterludeEvidenceId
} from "../../../core/types";
import { kit } from "../../../modules/GameKit";
import type { ChapterThreeInterludeDecoyReasonId } from "../../../modules/ChapterThreePhoneInterludeController";

const EVIDENCE: ReadonlyArray<{
  id: ChapterThreeInterludeEvidenceId;
  slot: string;
  label: string;
  source: string;
}> = [
  { id: "journal_start", slot: "A", label: "22:37:05", source: "CC98 划船记录" },
  { id: "photo_direction", slot: "B", label: "向东离岸", source: "恢复照片" },
  { id: "network_destination", slot: "C", label: "AP-DYP-A1-03", source: "通知与网络记录" },
  { id: "broadcast_end", slot: "D", label: "22:45:00", source: "录音片段" }
];

const DECOYS: ReadonlyArray<{ id: ChapterThreeInterludeDecoyId; label: string; reason: string }> = [
  { id: "canteen_0755", label: "食堂 0755", reason: "这是取餐号，不是夜间时间" },
  { id: "theater_0832", label: "剧场 08:32", reason: "抢票时间，早于本次划船记录" },
  { id: "status_clock_075523", label: "状态栏 07:55:23", reason: "系统时间已被篡改，标记为不可信" }
];

const DECOY_REASONS: ReadonlyArray<{ id: ChapterThreeInterludeDecoyReasonId; label: string }> = [
  { id: "number_not_time", label: "这是编号，不是本段记录的时间" },
  { id: "earlier_independent_event", label: "这是更早的独立事件" },
  { id: "frozen_local_clock", label: "这是本机冻结值，不能代表实际时间" }
];

export function TimelineRecoveryScene({ state, router }: SceneComponentProps) {
  const interlude = state.chapterThreeInterlude;
  const [timelineDraft, setTimelineDraft] = useState<ChapterThreeInterludeEvidenceId[]>(
    () => interlude.timelineOrder
  );
  const [feedback, setFeedback] = useState("");

  function openRecovery() {
    const result = kit.chapterThreeInterlude.beginRecovery();
    setFeedback(result === "accepted" ? "恢复工具已打开。先把划船记录收尾。" : "当前无法恢复这段记录。");
  }

  function addTimelineEntry(id: ChapterThreeInterludeEvidenceId) {
    if (timelineDraft.includes(id)) return;
    setTimelineDraft((current) => [...current, id]);
    setFeedback("");
  }

  function submitTimeline() {
    const result = kit.chapterThreeInterlude.assembleTimeline(timelineDraft);
    setFeedback(result === "accepted"
      ? "时间窗已收窄到 22:37:05—22:45:00。继续确认目的地。"
      : result === "locked"
        ? "四项证据和三条旧时间还没有处理完。"
        : "顺序对不上。先确认记录开始、移动方向、网络位置和广播结束。"
    );
  }

  function verifyDestination(explanationId: "a" | "b" | "c") {
    const result = kit.chapterThreeInterlude.verifyDestination("duan_yongping_a1", explanationId);
    setFeedback(result === "accepted"
      ? "目的地已确认：段永平教学楼 A 楼一层。"
      : "这条解释缺少时间和网络位置的共同支持。"
    );
  }

  function startReplay() {
    const result = kit.chapterThreeInterlude.startRecoveredReplay();
    if (result !== "accepted") setFeedback("恢复回放尚未解锁。");
  }

  function rejectDecoy(decoyId: ChapterThreeInterludeDecoyId, reasonId: ChapterThreeInterludeDecoyReasonId) {
    const result = kit.chapterThreeInterlude.rejectDecoy(decoyId, reasonId);
    const decoy = DECOYS.find((entry) => entry.id === decoyId)!;
    setFeedback(result === "accepted" || result === "already_complete"
      ? `${decoy.label}：${decoy.reason}。`
      : result === "incorrect"
        ? "这条理由解释不了它为什么不能进入时间线。"
        : "四项证据还没收齐。"
    );
  }

  const allEvidenceReady = EVIDENCE.every(({ id }) => interlude.evidenceIds.includes(id));
  const allDecoysRejected = DECOYS.every(({ id }) => interlude.rejectedDecoyIds.includes(id));
  const timelineVerified = allEvidenceReady
    && allDecoysRejected
    && interlude.statusClockMarkedUntrusted
    && EVIDENCE.every((entry, index) => interlude.timelineOrder[index] === entry.id);
  const destinationVerified = interlude.destinationId === "duan_yongping_a1";

  return (
    <section className="timeline-recovery-scene app-screen" aria-label="未同步记录恢复">
      <header className="interlude-app-header">
        <PhoneNavButton
          kind="exit"
          label="退出记录恢复，返回手机主页"
          onClick={() => router.goTo("phone_home")}
        />
        <div><small>RECOVERY 03.5</small><h1>未同步的七分五十五秒</h1></div>
        <span aria-hidden="true">22:45</span>
      </header>

      <main className="interlude-scroll">
        {interlude.phase === "reboot" && !interlude.recoveryOpened ? (
          <section className="interlude-reboot-card">
            <span className="interlude-reboot-wave" aria-hidden="true"><i /><i /><i /><i /></span>
            <h2>检测到 7 分 55 秒未同步记录</h2>
            <p>启真湖的离开记录还在，后面的去向没有写进去。手机右上角停在 07:55:23，这个时间不能直接采用。</p>
            <dl className="interlude-reboot-diagnostics">
              <div><dt>媒体缓存</dt><dd>7 帧</dd></div>
              <div><dt>短会话</dt><dd>3 条</dd></div>
              <div><dt>通知归档</dt><dd>12 条</dd></div>
              <div><dt>时间索引</dt><dd>异常</dd></div>
            </dl>
            <div className="interlude-reboot-dialogue">
              <p><b>林星宇</b>我离开湖边以后，去了哪里？</p>
              <p><b>系统</b>先从还能核对来源的记录开始。</p>
            </div>
            <button type="button" onClick={openRecovery}>打开恢复工具</button>
          </section>
        ) : null}

        {interlude.recoveryOpened ? (
          <>
            <section className="interlude-window-card">
              <span>待核验时间窗</span>
              <strong>22:37:05 — 22:45:00</strong>
              <small>证据完整后才会确认目的地</small>
            </section>

            <section className="interlude-evidence-grid" aria-label="恢复证据">
              {EVIDENCE.map((entry) => {
                const collected = interlude.evidenceIds.includes(entry.id);
                return (
                  <article key={entry.id} className={collected ? "is-collected" : ""}>
                    <b>{entry.slot}</b>
                    <div><strong>{collected ? entry.label : "待恢复"}</strong><small>{entry.source}</small></div>
                    <span>{collected ? "已记录" : "未完成"}</span>
                  </article>
                );
              })}
            </section>

            {!interlude.evidenceIds.includes("journal_start") ? (
              <section className="interlude-next-action">
                <h2>先确认记录起点</h2>
                <p>划船帖的最后一条回复保留了离湖时间。</p>
                <button type="button" onClick={() => router.goTo("cc98")}>去 CC98 收尾</button>
              </section>
            ) : (
              <nav className="interlude-source-links" aria-label="证据来源">
                <button type="button" onClick={() => router.goTo("photos")}>恢复照片</button>
                <button type="button" onClick={() => router.goTo("voice_memos")}>整理录音</button>
                <button type="button" onClick={() => router.goTo("wechat")}>查看微信通知</button>
                <button type="button" onClick={() => {
                  kit.flags.setUi("zjudingPage", "hub");
                  router.goTo("zjuding");
                }}>核对网络记录</button>
              </nav>
            )}

            {allEvidenceReady ? (
              <section className="interlude-decoy-panel">
                <header><h2>排除旧时间</h2><span>{interlude.rejectedDecoyIds.length}/3</span></header>
                {DECOYS.map((decoy) => {
                  const rejected = interlude.rejectedDecoyIds.includes(decoy.id);
                  return (
                    <article key={decoy.id} className={rejected ? "is-rejected" : ""}>
                      <header><strong>{decoy.label}</strong><small>{rejected ? "已排除" : "选择排除理由"}</small></header>
                      {rejected ? <p>{decoy.reason}</p> : (
                        <div className="interlude-decoy-reasons">
                          {DECOY_REASONS.map((reason) => (
                            <button
                              key={reason.id}
                              type="button"
                              onClick={() => rejectDecoy(decoy.id, reason.id)}
                            >{reason.label}</button>
                          ))}
                        </div>
                      )}
                    </article>
                  );
                })}
              </section>
            ) : null}

            {allEvidenceReady && allDecoysRejected ? (
              <section className="interlude-timeline-panel">
                <header><h2>按发生顺序排列</h2><button type="button" onClick={() => setTimelineDraft([])}>重排</button></header>
                <div className="interlude-timeline-draft">
                  {timelineDraft.length ? timelineDraft.map((id, index) => {
                    const entry = EVIDENCE.find((item) => item.id === id)!;
                    return <span key={id}><b>{index + 1}</b>{entry.slot} · {entry.source}</span>;
                  }) : <p>依次点选四张证据卡。</p>}
                </div>
                <div className="interlude-timeline-options">
                  {EVIDENCE.map((entry) => (
                    <button
                      key={entry.id}
                      type="button"
                      disabled={timelineDraft.includes(entry.id)}
                      onClick={() => addTimelineEntry(entry.id)}
                    >{entry.slot}</button>
                  ))}
                </div>
                <button type="button" className="interlude-primary-action" onClick={submitTimeline}>核对时间线</button>
              </section>
            ) : null}

            {timelineVerified && !destinationVerified ? (
              <section className="interlude-destination-panel">
                <h2>目的地：段永平教学楼 A 楼一层</h2>
                <p>选择能够同时解释时间、移动方向和网络记录的一项。</p>
                <button type="button" onClick={() => verifyDestination("a")}>A　状态栏显示 07:55，所以回到了早晨</button>
                <button type="button" onClick={() => verifyDestination("b")}>B　剧场抢票时间最接近，目的地仍是剧场</button>
                <button type="button" onClick={() => verifyDestination("c")}>C　22:45 前连接教学楼 A1 接入点，录音末段出现大厅广播</button>
              </section>
            ) : null}

            {destinationVerified ? (
              <section className="interlude-replay-card">
                <span>RECOVERED</span>
                <h2>路径记录已恢复</h2>
                <p>回放会从启真湖最后一帧开始，并在段永平教学楼 A 楼一层结束。</p>
                <button type="button" onClick={startReplay}>播放恢复回放</button>
              </section>
            ) : null}
          </>
        ) : null}

        {feedback ? <p className="interlude-feedback" role="status">{feedback}</p> : null}
      </main>
    </section>
  );
}
