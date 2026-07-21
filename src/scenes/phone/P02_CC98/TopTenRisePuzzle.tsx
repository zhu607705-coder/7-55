import { useEffect, useRef, useState } from "react";
import type {
  LibraryEvidenceId,
  LibraryFinalsBdPostId,
  LibraryFinalsPhase
} from "../../../core/types";
import type { EventBus } from "../../../core/EventBus";
import libraryFinalsContent from "../../../data/library-finals.content.json";
import { kit } from "../../../modules/GameKit";
import { isLibraryEvidenceId, isLibraryFinalsBdPostId } from "../../../modules/library-finals/puzzleRules";

interface TopTenRisePuzzleProps {
  selectedPostIds: LibraryFinalsBdPostId[];
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

type BdPasswordPost = {
  id: LibraryFinalsBdPostId;
  floor: number;
  digit: string;
  author: string;
  text: string;
};

const BD_PASSWORD = libraryFinalsContent.cc98.bdPassword;
const BD_POSTS: BdPasswordPost[] = BD_PASSWORD.posts.flatMap((post) => (
  isLibraryFinalsBdPostId(post.id)
    ? [{ id: post.id, floor: post.floor, digit: post.digit, author: post.author, text: post.text }]
    : []
));
const BD_DIGIT_BY_POST = new Map(BD_POSTS.map((post) => [post.id, post.digit]));

/** 证据上传和 BD 口令只调用领域命令；选择、排名与解锁由控制器完成。 */
export function TopTenRisePuzzle({
  selectedPostIds,
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
  const [passwordInvalid, setPasswordInvalid] = useState(false);
  const previousUploadedRef = useRef(uploadedEvidenceIds);
  const previousBdCountRef = useRef(bdCount);
  const passwordPanelRef = useRef<HTMLElement>(null);
  const uploadTimerRef = useRef<number | null>(null);
  const rankTimerRef = useRef<number | null>(null);
  const topTenTimerRef = useRef<number | null>(null);
  const invalidTimerRef = useRef<number | null>(null);
  const allUploaded = uploadedEvidenceIds.length === EVIDENCE.length;
  const solved = phase === "top_ten_reached" || bdCount >= 3;
  const rank = solved ? "01" : "04";
  const passwordFull = selectedPostIds.length === 4;

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

  function selectPost(post: BdPasswordPost) {
    setFeedback("");
    if (!kit.libraryFinals.selectBdPost(post.id)) {
      if (!passwordFull) setFeedback("当前阶段不能选入这条回复。");
    }
  }

  function submitPassword() {
    setFeedback("");
    if (kit.libraryFinals.submitBdPassword()) {
      return;
    }
    setPasswordInvalid(true);
    if (invalidTimerRef.current !== null) window.clearTimeout(invalidTimerRef.current);
    invalidTimerRef.current = window.setTimeout(() => {
      invalidTimerRef.current = null;
      setPasswordInvalid(false);
    }, 620);
  }

  function undoPost() {
    setFeedback("");
    kit.libraryFinals.undoBdPost();
  }

  function clearPassword() {
    setFeedback("");
    kit.libraryFinals.clearBdPassword();
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
          <span>{phase === "bd_briefing" ? "等待说明" : allUploaded ? "可生成口令" : "待补齐"}</span>
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

      {showBd && preBdBriefingSeen ? <section className="cc98-rank-status" aria-live="polite">
        <span>当前排名</span>
        <strong key={rank}>{rank}</strong>
        <p>{solved ? "十大第一" : allUploaded ? "完成 BD 四位口令" : "请先上传四项证据"}</p>
        {topTenBurst ? <i className="cc98-rank-burst" aria-hidden="true"><b /><b /><b /><b /><b /><b /></i> : null}
      </section> : null}

      {showBd && preBdBriefingSeen ? <section ref={passwordPanelRef} className={`cc98-bd-password ${passwordInvalid ? "is-invalid" : ""}`.trim()} aria-label="BD四位热度口令">
        <header>
          <div><strong>{BD_PASSWORD.title}</strong><small>{BD_PASSWORD.meaning}</small></div>
          <b>{selectedPostIds.length}/4</b>
        </header>
        <p className="cc98-bd-password-prompt">{BD_PASSWORD.prompt}</p>
        <ol className="cc98-bd-clues" aria-label="口令顺序提示">
          {BD_PASSWORD.clues.map((clue) => (
            <li key={clue.index}><b>{clue.index}</b><span>{clue.label}<small>{clue.instruction}</small></span></li>
          ))}
        </ol>
        <div className="cc98-bd-code" aria-label={`当前口令 ${selectedPostIds.map((id) => BD_DIGIT_BY_POST.get(id)).join("") || "空"}`} aria-live="polite">
          {[0, 1, 2, 3].map((index) => <span key={`${index}-${selectedPostIds[index] ?? "empty"}`}>{selectedPostIds[index] ? BD_DIGIT_BY_POST.get(selectedPostIds[index]) : "·"}</span>)}
        </div>
        <div className="cc98-bd-password-actions">
          <button type="button" disabled={selectedPostIds.length === 0 || solved} onClick={undoPost}>撤回一位</button>
          <button type="button" disabled={selectedPostIds.length === 0 || solved} onClick={clearPassword}>清空</button>
          <button type="button" disabled={!passwordFull || solved} onClick={submitPassword}>{solved ? "已通过" : "提交口令"}</button>
        </div>
      </section> : null}

      {showBd && preBdBriefingSeen ? <div className="cc98-bd-replies cc98-bd-number-posts" aria-label="数字候选回复">
        {BD_POSTS.map((post) => {
          const selectedIndex = selectedPostIds.indexOf(post.id);
          const selected = selectedIndex >= 0;
          return (
            <article key={post.id} className={selected ? "is-applied" : ""}>
              <header><strong>{post.floor} 楼 · {post.author}</strong><span>{selected ? `口令第 ${selectedIndex + 1} 位` : "数字回复"}</span></header>
              <p>{post.text}</p>
              <b className="cc98-bd-post-digit" aria-label={`数字 ${post.digit}`}>{post.digit}</b>
              <button
                type="button"
                disabled={selected || passwordFull || solved}
                aria-label={`对 ${post.floor} 楼回复 bd，选入数字 ${post.digit}`}
                onClick={() => selectPost(post)}
              >
                {selected ? `第 ${selectedIndex + 1} 位` : "bd 选入"}
              </button>
            </article>
          );
        })}
      </div> : null}

      {showBd && preBdBriefingSeen && solved ? (
        <p className="cc98-top-ten-complete">排名更新为 01。查看图书管理员的回复。</p>
      ) : null}
      {feedback ? <p className="cc98-bd-feedback" aria-live="polite">{feedback}</p> : null}
    </section>
  );
}
