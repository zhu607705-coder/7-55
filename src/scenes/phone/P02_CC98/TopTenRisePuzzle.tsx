import { useEffect, useRef, useState } from "react";
import type {
  LibraryEvidenceId,
  LibraryFinalsBdReplyId,
  LibraryFinalsPhase
} from "../../../core/types";
import type { EventBus } from "../../../core/EventBus";
import libraryFinalsContent from "../../../data/library-finals.content.json";
import { kit } from "../../../modules/GameKit";
import { isLibraryEvidenceId, isLibraryFinalsBdReplyId } from "../../../modules/library-finals/puzzleRules";

interface TopTenRisePuzzleProps {
  appliedReplyIds: LibraryFinalsBdReplyId[];
  bdCount: 0 | 1 | 2 | 3;
  phase: LibraryFinalsPhase;
  ownedEvidenceIds: LibraryEvidenceId[];
  uploadedEvidenceIds: LibraryEvidenceId[];
  preBdBriefingSeen: boolean;
  events?: EventBus;
  showUploader?: boolean;
  showBd?: boolean;
}

const EVIDENCE: Array<{ id: LibraryEvidenceId; label: string; source: string }> =
  libraryFinalsContent.cc98.evidenceSlots.flatMap((slot) => (
    isLibraryEvidenceId(slot.id)
      ? [{ id: slot.id, label: slot.label, source: slot.source }]
      : []
  ));

type ReplyOption = {
  key: "A" | "B" | "C" | "D" | "E";
  author: string;
  text: string;
  requirement: string;
  replyId?: LibraryFinalsBdReplyId;
  rejection?: string;
};

const REPLIES: ReplyOption[] = libraryFinalsContent.cc98.bdOptions.map((option) => ({
  key: option.key as ReplyOption["key"],
  author: option.author,
  text: option.text,
  requirement: option.requirement,
  replyId: option.valid && isLibraryFinalsBdReplyId(option.id) ? option.id : undefined,
  rejection: option.rejection ?? undefined
}));

/** 证据上传和 bd 只调用领域命令；排名、道具与解锁由控制器完成。 */
export function TopTenRisePuzzle({
  appliedReplyIds,
  bdCount,
  phase,
  ownedEvidenceIds,
  uploadedEvidenceIds,
  preBdBriefingSeen,
  events,
  showUploader = true,
  showBd = uploadedEvidenceIds.length === EVIDENCE.length
}: TopTenRisePuzzleProps) {
  const [feedback, setFeedback] = useState("");
  const [draggedItem, setDraggedItem] = useState("");
  const [uploadAnimatingId, setUploadAnimatingId] = useState<LibraryEvidenceId | null>(null);
  const [rankAnimating, setRankAnimating] = useState(false);
  const [topTenBurst, setTopTenBurst] = useState(false);
  const [invalidReplyKey, setInvalidReplyKey] = useState<ReplyOption["key"] | null>(null);
  const [briefingLine, setBriefingLine] = useState(0);
  const previousUploadedRef = useRef(uploadedEvidenceIds);
  const previousBdCountRef = useRef(bdCount);
  const uploadTimerRef = useRef<number | null>(null);
  const rankTimerRef = useRef<number | null>(null);
  const topTenTimerRef = useRef<number | null>(null);
  const invalidTimerRef = useRef<number | null>(null);
  const allUploaded = uploadedEvidenceIds.length === EVIDENCE.length;
  const rank = String(4 - bdCount).padStart(2, "0");
  const briefingLines = [
    "四份证据都公开了，但帖子的流量还不够。",
    "只选能被现有证据支持的回复。三类证明各对应一条有效回复。",
    "完成三次有效 bd，把排名从 04 推进到 01。"
  ];

  useEffect(() => {
    const previous = previousUploadedRef.current;
    previousUploadedRef.current = uploadedEvidenceIds;
    const uploaded = uploadedEvidenceIds.find((id) => !previous.includes(id));
    if (!uploaded) return;

    setUploadAnimatingId(uploaded);
    if (uploadTimerRef.current !== null) window.clearTimeout(uploadTimerRef.current);
    uploadTimerRef.current = window.setTimeout(() => {
      uploadTimerRef.current = null;
      setUploadAnimatingId(null);
    }, 760);
  }, [uploadedEvidenceIds]);

  useEffect(() => {
    const previous = previousBdCountRef.current;
    previousBdCountRef.current = bdCount;
    if (bdCount <= previous) return;

    setRankAnimating(true);
    if (rankTimerRef.current !== null) window.clearTimeout(rankTimerRef.current);
    rankTimerRef.current = window.setTimeout(() => {
      rankTimerRef.current = null;
      setRankAnimating(false);
    }, 620);

    if (phase === "top_ten_reached" || bdCount === 3) {
      setTopTenBurst(true);
      if (topTenTimerRef.current !== null) window.clearTimeout(topTenTimerRef.current);
      topTenTimerRef.current = window.setTimeout(() => {
        topTenTimerRef.current = null;
        setTopTenBurst(false);
      }, 1180);
    }
  }, [bdCount, phase]);

  useEffect(() => () => {
    [uploadTimerRef, rankTimerRef, topTenTimerRef, invalidTimerRef].forEach((timerRef) => {
      if (timerRef.current !== null) window.clearTimeout(timerRef.current);
    });
  }, []);

  useEffect(() => {
    if (!events) return undefined;
    return events.subscribe((event) => {
    if (event.name === "inventory_drag_started") {
      setDraggedItem(String(event.payload?.itemId ?? ""));
      return;
    }
    if (event.name === "inventory_drag_ended") {
      setDraggedItem("");
      return;
    }
    if (event.name !== "item_dropped") return;
    const target = String(event.payload?.target ?? "");
    if (!target.startsWith("cc98-upload:")) return;
    const evidenceId = target.slice("cc98-upload:".length);
    const item = String(event.payload?.item ?? "");
    const expectedItem: Record<LibraryEvidenceId, string> = {
      archived_leave_rule: "archivedLeaveRule",
      bag_non_person_proof: "bagNonPersonProof",
      seat_022_receipt: "seat022Receipt",
      library_presence_proof: "libraryPresenceProof"
    };
    if (!isLibraryEvidenceId(evidenceId) || expectedItem[evidenceId] !== item) {
      setFeedback("这个槽位需要对应名称的纸质材料。");
      return;
    }
      upload(evidenceId);
    });
  }, [events, uploadedEvidenceIds]);

  function upload(evidenceId: LibraryEvidenceId) {
    setFeedback("");
    if (!kit.libraryFinals.uploadEvidence(evidenceId)) {
      setFeedback("这份材料还没有形成可核对的道具。");
    }
  }

  function apply(reply: ReplyOption) {
    if (!reply.replyId) {
      showInvalidReply(reply.key);
      setFeedback(reply.rejection ?? "该回复没有形成证据闭环。");
      return;
    }
    setFeedback("");
    if (!kit.libraryFinals.applyBd(reply.replyId)) {
      showInvalidReply(reply.key);
      setFeedback(allUploaded ? "这条回复已处理，或当前排名阶段不接受它。" : "四项证据传齐后才能 bd。");
    }
  }

  function showInvalidReply(key: ReplyOption["key"]) {
    setInvalidReplyKey(key);
    if (invalidTimerRef.current !== null) window.clearTimeout(invalidTimerRef.current);
    invalidTimerRef.current = window.setTimeout(() => {
      invalidTimerRef.current = null;
      setInvalidReplyKey(null);
    }, 460);
  }

  function advanceBriefing() {
    if (briefingLine < briefingLines.length - 1) {
      setBriefingLine((current) => current + 1);
      return;
    }
    kit.libraryFinals.completePreBdBriefing();
  }

  return (
    <section
      className={`cc98-top-ten-puzzle cc98-evidence-puzzle ${phase === "top_ten_reached" ? "is-top-ten" : ""} ${rankAnimating ? "is-rank-rising" : ""} ${topTenBurst ? "is-top-ten-burst" : ""}`.trim()}
      aria-label="CC98证据与十大排名"
    >
      {showUploader ? <section className="cc98-evidence-uploader" aria-label="楼主证据上传区">
        <header>
          <div>
            <strong>楼主编辑：上传证据</strong>
            <small>证据完整度：{uploadedEvidenceIds.length}/4</small>
          </div>
          <span>{allUploaded ? "可进入 bd" : "待补齐"}</span>
        </header>
        <div>
          {EVIDENCE.map((evidence) => {
            const owned = ownedEvidenceIds.includes(evidence.id);
            const uploaded = uploadedEvidenceIds.includes(evidence.id);
            return (
              <article
                key={evidence.id}
                className={`${uploaded ? "is-uploaded" : ""} ${uploadAnimatingId === evidence.id ? "is-uploading" : ""} ${draggedItem && (
                  (evidence.id === "archived_leave_rule" && draggedItem === "archivedLeaveRule")
                  || (evidence.id === "bag_non_person_proof" && draggedItem === "bagNonPersonProof")
                  || (evidence.id === "seat_022_receipt" && draggedItem === "seat022Receipt")
                  || (evidence.id === "library_presence_proof" && draggedItem === "libraryPresenceProof")
                ) ? "is-compatible-drop" : draggedItem ? "is-incompatible-drop" : ""}`.trim()}
                data-drop-target={`cc98-upload:${evidence.id}`}
              >
                <span aria-hidden="true">{uploaded ? "✓" : "▣"}</span>
                {uploadAnimatingId === evidence.id ? <i className="cc98-upload-scan" aria-hidden="true" /> : null}
                <div><strong>{evidence.label}</strong><small>{evidence.source}</small></div>
                <button type="button" disabled={!owned || uploaded || phase !== "evidence_gathering"} onClick={() => upload(evidence.id)}>
                  {uploaded ? "已上传" : owned ? "上传" : "未获得"}
                </button>
              </article>
            );
          })}
        </div>
      </section> : null}

      {showBd && allUploaded && !preBdBriefingSeen ? (
        <section className="cc98-pre-bd-dialogue" role="dialog" aria-label="系统 bd 前说明">
          <span aria-hidden="true">求</span>
          <div>
            <small>系统 · {briefingLine + 1}/{briefingLines.length}</small>
            <p>{briefingLines[briefingLine]}</p>
          </div>
          <button type="button" onClick={advanceBriefing}>{briefingLine === briefingLines.length - 1 ? "开始 bd" : "继续"}</button>
        </section>
      ) : null}

      {showBd && preBdBriefingSeen ? <section className="cc98-rank-status" aria-live="polite">
        <span>当前排名</span>
        <strong key={rank}>{rank}</strong>
        <p>{phase === "top_ten_reached" ? "十大第一" : allUploaded ? "选择有效回复 bd" : "请先上传四项证据"}</p>
        {topTenBurst ? <i className="cc98-rank-burst" aria-hidden="true"><b /><b /><b /><b /><b /><b /></i> : null}
      </section> : null}

      {showBd && preBdBriefingSeen ? <div className="cc98-bd-replies" aria-label="bd回复列表">
        {REPLIES.map((reply) => {
          const applied = reply.replyId ? appliedReplyIds.includes(reply.replyId) : false;
          return (
            <article key={reply.key} className={`${applied ? "is-applied" : ""} ${invalidReplyKey === reply.key ? "is-invalid" : ""}`.trim()}>
              <header><strong>{reply.key} · {reply.author}</strong><span>{reply.requirement}</span></header>
              <p>{reply.text}</p>
              <button
                type="button"
                disabled={applied || phase === "top_ten_reached"}
                aria-label={`对 ${reply.key} 回复 bd`}
                onClick={() => apply(reply)}
              >
                {applied ? "已 bd" : "bd"}
              </button>
            </article>
          );
        })}
      </div> : null}

      {showBd && preBdBriefingSeen && phase === "top_ten_reached" ? (
        <p className="cc98-top-ten-complete">排名 01。图书馆 App 已放出 022 恢复申请入口。</p>
      ) : null}
      {feedback ? <p className="cc98-bd-feedback" aria-live="polite">{feedback}</p> : null}
    </section>
  );
}
