import { useState } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import type {
  ChapterThreeInterludeDecoyId,
  ChapterThreeInterludeEvidenceId,
  SceneId
} from "../../../core/types";
import {
  chapterThreeInterludePublicContent,
  chapterThreeInterludeValidationContract,
  type ChapterThreeInterludeDecoyReasonId,
  type ChapterThreeInterludeDestinationCandidateId
} from "../../../data/chapter3InterludeContent";
import { selectChapterThreeInterludeViewModel } from "../../../modules/ChapterThreeInterludeModel";
import { kit } from "../../../modules/GameKit";

const DECOY_RESULT_COPY: Readonly<Record<ChapterThreeInterludeDecoyId, string>> = {
  canteen_0755: "0755 是取餐编号，不能作为夜间时间。",
  theater_0832: "08:32 来自更早的独立抢票记录。",
  status_clock_075523: "07:55:23 是未同步的本机时钟值。"
};

const DECOY_REASONS: ReadonlyArray<{ id: ChapterThreeInterludeDecoyReasonId; label: string }> = [
  { id: "number_not_time", label: "这是编号，不是本段记录的时间" },
  { id: "earlier_independent_event", label: "这是更早的独立事件" },
  { id: "frozen_local_clock", label: "这是本机冻结值，不能代表实际时间" }
];

const EVIDENCE_ROUTE: Readonly<Record<ChapterThreeInterludeEvidenceId, SceneId>> = {
  journal_start: "cc98",
  photo_direction: "photos",
  network_destination: "zjuding",
  broadcast_end: "voice_memos"
};

export function TimelineRecoveryScene({ state, router }: SceneComponentProps) {
  const interlude = state.chapterThreeInterlude;
  const viewModel = selectChapterThreeInterludeViewModel(state);
  const [feedback, setFeedback] = useState("");

  const allEvidenceReady = viewModel.evidenceProgress.completed === viewModel.evidenceProgress.total;
  const allDecoysRejected = chapterThreeInterludePublicContent.oldTimeCandidates
    .every(({ id }) => interlude.rejectedDecoyIds.includes(id));
  const destinationVerified = interlude.destinationId === chapterThreeInterludeValidationContract.destinationId;

  function openRecovery() {
    const result = kit.chapterThreeInterlude.beginRecovery();
    setFeedback(result === "accepted" ? "恢复工具已打开。" : "当前无法恢复这段记录。");
  }

  function openEvidenceSource(id: ChapterThreeInterludeEvidenceId) {
    if (id === "network_destination") kit.flags.setUi("zjudingPage", "hub");
    router.goTo(EVIDENCE_ROUTE[id]);
  }

  function verifyDestination(candidateId: ChapterThreeInterludeDestinationCandidateId) {
    const result = kit.chapterThreeInterlude.verifyDestination(candidateId);
    if (result === "accepted") {
      setFeedback("地点与四项证据一致，恢复结果已确认。");
      return;
    }
    if (result === "locked") {
      setFeedback("先完成四类证据与旧时间核验。");
      return;
    }
    if (candidateId === chapterThreeInterludeValidationContract.destinationId) {
      setFeedback("当前证据还不足以确认这个地点。");
      return;
    }
    setFeedback(chapterThreeInterludePublicContent.destinationConflictCopy[candidateId]);
  }

  function startReplay() {
    const result = kit.chapterThreeInterlude.startRecoveredReplay();
    if (result !== "accepted") setFeedback("恢复回放尚未解锁。");
  }

  function rejectDecoy(decoyId: ChapterThreeInterludeDecoyId, reasonId: ChapterThreeInterludeDecoyReasonId) {
    const result = kit.chapterThreeInterlude.rejectDecoy(decoyId, reasonId);
    setFeedback(result === "accepted" || result === "already_complete"
      ? DECOY_RESULT_COPY[decoyId]
      : result === "incorrect"
        ? "这条理由与记录来源不匹配。"
        : "四项证据还没收齐。"
    );
  }

  return (
    <section className="timeline-recovery-scene app-screen" aria-label="未同步记录恢复">
      <header className="interlude-app-header">
        <PhoneNavButton
          kind="exit"
          label="退出记录恢复，返回手机主页"
          onClick={() => router.goTo("phone_home")}
        />
        <div><small>RECOVERY 03.5</small><h1>{viewModel.title}</h1></div>
        <span>{viewModel.notificationTimeLabel}</span>
      </header>

      <main className="interlude-scroll">
        {interlude.phase === "reboot" && !interlude.recoveryOpened ? (
          <section className="interlude-reboot-card">
            <span className="interlude-reboot-wave" aria-hidden="true"><i /><i /><i /><i /></span>
            <h2>检测到 7 分 55 秒未同步记录</h2>
            <p>启真湖的离开记录仍在，后面的去向没有写入。手机时钟与带来源的记录不一致，不能直接采用。</p>
            <dl className="interlude-reboot-diagnostics">
              <div><dt>媒体缓存</dt><dd>7 帧</dd></div>
              <div><dt>短会话</dt><dd>3 条</dd></div>
              <div><dt>通知归档</dt><dd>12 条</dd></div>
              <div><dt>时间索引</dt><dd>异常</dd></div>
            </dl>
            <div className="interlude-reboot-dialogue">
              <p><b>林星宇</b>我离开湖边以后，去了哪里？</p>
              <p><b>系统</b>先从能够核对来源的记录开始。</p>
            </div>
            <button type="button" onClick={openRecovery}>打开恢复工具</button>
          </section>
        ) : null}

        {interlude.recoveryOpened ? (
          <>
            <section className="interlude-window-card" aria-label="待核验时间窗">
              <span>{chapterThreeInterludePublicContent.timeWindowLabel}</span>
              <strong>
                <b className={viewModel.timeWindow.startResolved ? "is-restored" : ""}>{viewModel.timeWindow.startLabel}</b>
                <i aria-hidden="true">—</i>
                <b className={viewModel.timeWindow.endResolved ? "is-restored" : ""}>{viewModel.timeWindow.endLabel}</b>
              </strong>
              <small>左右边界分别由原始证据恢复</small>
            </section>

            <p className="interlude-derived-reasoning" role="status">{viewModel.derivedReasoning}</p>

            <section className="interlude-evidence-grid" aria-label={`恢复证据 ${viewModel.evidenceProgress.completed}/${viewModel.evidenceProgress.total}`}>
              {chapterThreeInterludeValidationContract.evidenceOrder.map((id, index) => {
                const entry = chapterThreeInterludePublicContent.evidence[id];
                const collected = interlude.evidenceIds.includes(id);
                return (
                  <details key={id} className={collected ? "is-collected" : ""}>
                    <summary>
                      <b>{index + 1}</b>
                      <span><strong>{collected ? entry.timeLabel : "待恢复"}</strong><small>{entry.label}</small></span>
                      <em>{collected ? "已记录" : "未完成"}</em>
                    </summary>
                    <p>{collected ? entry.summary : "打开对应来源，完成当前证据核验。"}</p>
                    <button type="button" onClick={() => openEvidenceSource(id)}>{collected ? "重新打开来源" : "打开证据来源"}</button>
                  </details>
                );
              })}
            </section>

            {!interlude.evidenceIds.includes("journal_start") ? (
              <section className="interlude-next-action">
                <h2>先恢复时间窗起点</h2>
                <p>划船帖的最后一条回复保留了带来源的离湖时间。</p>
                <button type="button" onClick={() => router.goTo("cc98")}>去 CC98 收尾</button>
              </section>
            ) : (
              <nav className="interlude-source-links" aria-label="证据来源">
                <button type="button" onClick={() => router.goTo("photos")}>恢复照片</button>
                <button type="button" onClick={() => router.goTo("voice_memos")}>整理录音</button>
                <button type="button" onClick={() => router.goTo("wechat")}>查看微信</button>
                <button type="button" onClick={() => openEvidenceSource("network_destination")}>核对网络</button>
              </nav>
            )}

            {allEvidenceReady ? (
              <section className="interlude-decoy-panel">
                <header><h2>排除旧时间</h2><span>{interlude.rejectedDecoyIds.length}/3</span></header>
                {chapterThreeInterludePublicContent.oldTimeCandidates.map((decoy) => {
                  const rejected = interlude.rejectedDecoyIds.includes(decoy.id);
                  return (
                    <article key={decoy.id} className={rejected ? "is-rejected" : ""}>
                      <header><strong>{decoy.label}</strong><small>{rejected ? "已排除" : "选择排除理由"}</small></header>
                      {rejected ? <p>{DECOY_RESULT_COPY[decoy.id]}</p> : (
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

            {viewModel.autoTimelineRows.length ? (
              <section className="interlude-timeline-panel" aria-label="自动恢复时间线">
                <header><h2>自动恢复的时间线</h2><span>4/4</span></header>
                <ol className="interlude-auto-timeline">
                  {viewModel.autoTimelineRows.map((entry) => (
                    <li key={entry.id}>
                      <b>{entry.timeLabel}</b>
                      <span><strong>{entry.label}</strong><small>{entry.summary}</small></span>
                    </li>
                  ))}
                </ol>
              </section>
            ) : null}

            {viewModel.destinationSelectionUnlocked ? (
              <section className="interlude-destination-panel">
                <h2>选择最终地点</h2>
                <p>选择唯一能够同时解释时间窗、移动过程、入口变化和网络短会话的地点。</p>
                {viewModel.destinationCandidates.map((candidate) => (
                  <button key={candidate.id} type="button" onClick={() => verifyDestination(candidate.id)}>
                    {candidate.label}
                  </button>
                ))}
              </section>
            ) : null}

            {destinationVerified ? (
              <section className="interlude-replay-card">
                <span>RECOVERED</span>
                <h2>路径记录已恢复</h2>
                <p>回放会从启真湖最后一帧开始，并在已确认地点结束。</p>
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
