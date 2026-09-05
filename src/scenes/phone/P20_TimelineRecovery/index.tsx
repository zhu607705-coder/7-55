import { useState } from "react";
import { InvestigationRing } from "../../../components/InvestigationRing";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import type { ChapterThreeInterludeDecoyId } from "../../../core/types";
import {
  chapterThreeInterludePublicContent,
  chapterThreeInterludeValidationContract,
  type ChapterThreeInterludeDecoyReasonId,
  type ChapterThreeInterludeDestinationCandidateId
} from "../../../data/chapter3InterludeContent";
import {
  selectChapterThreeInterludeViewModel,
  type ChapterThreeInterludeParallelBranchView
} from "../../../modules/ChapterThreeInterludeModel";
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

const NETWORK_RECORD_LABELS = {
  record_qizhen_dock: "22:44:12 · 启真湖小码头",
  record_theater_hall: "22:44:31 · 剧场前厅",
  record_library_south: "22:43:11 · 基础图书馆南侧",
  record_0755: "22:44:57 · 北教学区 A 区"
} as const;

const RESTORED_BRANCH_DETAIL = {
  photos: chapterThreeInterludePublicContent.evidence.photo_direction.timeLabel,
  voice: chapterThreeInterludePublicContent.evidence.broadcast_end.timeLabel,
  messages: "通知与路线已核验",
  network: chapterThreeInterludePublicContent.evidence.network_destination.timeLabel
} satisfies Record<ChapterThreeInterludeParallelBranchView["id"], string>;

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

  function openParallelBranch(branchId: (typeof viewModel.parallelBranches)[number]["id"]) {
    const branch = viewModel.parallelBranches.find((candidate) => candidate.id === branchId);
    if (!branch) return;
    if (branchId === "network") kit.flags.setUi("zjudingPage", "hub");
    router.goTo(branch.recommendedScene);
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
      setFeedback(interlude.networkRecordId && interlude.networkRecordId !== "record_0755"
        ? "保存的接入记录对不上这个地点，再看一遍网络记录。"
        : "当前证据还不足以确认这个地点。"
      );
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
              <p><b>系统</b>照片、录音、消息都存了，就是没记清你去了哪。先看还能读出的。</p>
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
              <small>对照离湖时刻和最后一段录音，查清这段时间发生了什么。</small>
            </section>

            <p className="interlude-derived-reasoning" role="status">{viewModel.derivedReasoning}</p>

            {!interlude.evidenceIds.includes("journal_start") ? (
              <section className="interlude-next-action">
                <h2>先查离湖时间</h2>
                <p>划船帖的最后一条回复保留了带来源的离湖时间。</p>
                <button type="button" onClick={() => router.goTo("cc98")}>查看划船帖</button>
              </section>
            ) : (
              <InvestigationRing
                ariaLabel={`四类证据并行恢复，已完成 ${viewModel.branchProgress.completed} 项，共 ${viewModel.branchProgress.total} 项`}
                eyebrow="EVIDENCE LOOP"
                title="留下了哪些记录"
                completed={viewModel.branchProgress.completed}
                total={viewModel.branchProgress.total}
                centerLabel="已查记录"
                hint="先看哪项都行，查过的会记在这里"
                nodes={viewModel.parallelBranches.map((branch) => ({
                  id: branch.id,
                  label: branch.label,
                  detail: branch.completed ? RESTORED_BRANCH_DETAIL[branch.id] : "点击进入来源",
                  statusLabel: branch.completed ? "已恢复" : "待恢复",
                  state: branch.completed ? "complete" : "ready"
                }))}
                onActivate={openParallelBranch}
              />
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

            {allEvidenceReady ? (
              <section className="interlude-timeline-panel" aria-label="证据矩阵">
                <header><h2>把记录对一对</h2><span>四处来源</span></header>
                <ol className="interlude-auto-timeline">
                  <li><b>离湖</b><span><strong>CC98 × 照片</strong><small>同一移动过程，方向连续。</small></span></li>
                  <li><b>末段</b><span><strong>录音 × 网络</strong><small>室内广播、三秒陌生设备与候选地点需要同时成立。</small></span></li>
                  <li><b>候选</b><span><strong>已保存接入记录</strong><small>{interlude.networkRecordId ? NETWORK_RECORD_LABELS[interlude.networkRecordId] : "尚未保存"}</small></span></li>
                </ol>
              </section>
            ) : null}

            {viewModel.destinationSelectionUnlocked ? (
              <section className="interlude-destination-panel">
                <h2>选择最终地点</h2>
                <p>哪个地方能对上时间、沿途声音、入口变化和网络记录？</p>
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
