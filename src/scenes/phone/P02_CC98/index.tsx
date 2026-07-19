import { useEffect, useMemo, useState } from "react";
import defaultPostData from "../../../data/cc98.posts.json";
import libraryFinalsContent from "../../../data/library-finals.content.json";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { LibraryEvidenceId } from "../../../core/types";
import { selectFeatureAccess } from "../../../core/FeatureAccess";
import actOneContent from "../../../data/act-one-bootstrap.content.json";
import { getActiveDeveloperCheckpoint, getDeveloperCc98Mode } from "../../../modules/DeveloperChannel";
import { kit } from "../../../modules/GameKit";
import { playSfx } from "../../../modules/Sfx";
import { Ac01FilterPuzzle } from "./Ac01FilterPuzzle";
import { ControlExchangePuzzle } from "./ControlExchangePuzzle";
import { Cc98ThreadPage } from "./ThreadPage";
import { TopTenRisePuzzle } from "./TopTenRisePuzzle";
import "../../../styles/library-v2-phone.css";

type AvatarVariant = "warrior" | "blonde" | "anonymous";

interface Cc98Post {
  id: string;
  author: string;
  avatar: AvatarVariant;
  rank: string;
  board: string;
  title: string;
  replies: string;
  views: string;
  time: string;
  body: string;
  threadOperation?: { user: string; action: string; reason: string };
  threadMetrics?: { favorites: string; likes: string; dislikes: string };
  threadReplies?: Array<{
    personaId: string;
    time: string;
    floor: string;
    role?: string;
    text: string;
    image?: "cc98_forum_treasure";
    caption?: string;
    likes: string;
    dislikes: string;
  }>;
}

type EditablePostKey = "author" | "rank" | "board" | "title" | "replies" | "views" | "time" | "body";

const STORAGE_KEY = "seven-fifty-five.cc98-posts.v2";
const QUEST_STORAGE_KEY = "seven-fifty-five.cc98-quest-post-overrides.v1";
const DEFAULT_POSTS = defaultPostData as Cc98Post[];
const ACT_ONE_EXCHANGE_POST = actOneContent.cc98ExchangePost as Cc98Post;
const investigationPostContent = libraryFinalsContent.cc98.post;
const INVESTIGATION_POST: Cc98Post = {
  id: investigationPostContent.id,
  author: investigationPostContent.author,
  avatar: investigationPostContent.avatar as AvatarVariant,
  rank: "04",
  board: investigationPostContent.board,
  title: investigationPostContent.title,
  replies: investigationPostContent.replies,
  views: investigationPostContent.views,
  time: investigationPostContent.time,
  body: investigationPostContent.body
};
const INVESTIGATION_SEARCH_RESULTS = [
  { id: "seat-022-backpack", title: INVESTIGATION_POST.title, floors: "23 楼", body: INVESTIGATION_POST.body, rejection: null },
  { id: "seat-022-old-source", title: "【求助】022 座位今日临时离开", floors: "12 楼", body: "来源为今日新帖，没有旧版离座规定的引用。", rejection: "来源不匹配：这是今日新帖，纸条引用的是旧版公开记录。" },
  { id: "seat-022-wrong-time", title: "【记录】二南 022 晚间使用情况", floors: "31 楼", body: "发布时间为当日 22:40，早于纸条中的本次离座事件。", rejection: "时间不匹配：这条记录早于本次 022 占用事件。" },
  { id: "seat-022-missing-attachment", title: "【闲聊】二楼南区今天还有位置吗", floors: "18 楼", body: "正文提到 022，附件区为空。", rejection: "附件不匹配：这条帖子没有纸条对应的离座凭据。" }
] as const;
const QUEST_POST_IDS = new Set([ACT_ONE_EXCHANGE_POST.id, INVESTIGATION_POST.id]);
const TOP_TABS = ["今日", "发现", "本周", "本月", "往年今日", "活动"];
const BOTTOM_TABS = [
  { label: "热门", icon: "◉" },
  { label: "新帖", icon: "✿" },
  { label: "关注", icon: "♡" },
  { label: "版面", icon: "▦" },
  { label: "我", icon: "◎" }
];

function cloneDefaults() {
  return DEFAULT_POSTS.filter((post) => !QUEST_POST_IDS.has(post.id)).map((post) => ({ ...post }));
}

function loadPosts() {
  if (typeof window === "undefined") {
    return cloneDefaults();
  }
  try {
    const saved = window.localStorage.getItem(STORAGE_KEY);
    if (!saved) {
      return cloneDefaults();
    }
    const parsed = JSON.parse(saved) as unknown;
    if (!Array.isArray(parsed) || !parsed.length) {
      return cloneDefaults();
    }
    const defaultsById = new Map(DEFAULT_POSTS.map((post) => [post.id, post]));
    return (parsed as Cc98Post[])
      .filter((post) => !QUEST_POST_IDS.has(post.id))
      .map((post) => {
        const defaults = defaultsById.get(post.id);
        return {
          ...defaults,
          ...post,
          // Replies are authored game content, while the post body remains player-editable.
          threadReplies: defaults?.threadReplies ?? post.threadReplies
        };
      });
  } catch {
    return cloneDefaults();
  }
}

function loadQuestPostOverrides(): Record<string, Partial<Cc98Post>> {
  if (typeof window === "undefined") {
    return {};
  }
  try {
    const saved = JSON.parse(window.localStorage.getItem(QUEST_STORAGE_KEY) ?? "{}");
    if (typeof saved !== "object" || saved === null || Array.isArray(saved)) {
      return {};
    }
    return Object.fromEntries(
      Object.entries(saved).filter(([id, value]) => QUEST_POST_IDS.has(id) && typeof value === "object" && value !== null)
    ) as Record<string, Partial<Cc98Post>>;
  } catch {
    return {};
  }
}

function EditableText({
  value,
  editing,
  className,
  onCommit
}: {
  value: string;
  editing: boolean;
  className: string;
  onCommit: (value: string) => void;
}) {
  return (
    <span
      className={`${className} ${editing ? "is-editable" : ""}`.trim()}
      contentEditable={editing}
      suppressContentEditableWarning
      onPointerDown={(event) => editing && event.stopPropagation()}
      onBlur={(event) => onCommit(event.currentTarget.textContent?.trim() || value)}
    >
      {value}
    </span>
  );
}

export function Cc98Scene({ state, router, events }: SceneComponentProps) {
  const [posts, setPosts] = useState<Cc98Post[]>(loadPosts);
  const [questPostOverrides, setQuestPostOverrides] = useState<Record<string, Partial<Cc98Post>>>(loadQuestPostOverrides);
  const [editing, setEditing] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [openPostId, setOpenPostId] = useState<string | null>(() => {
    const mode = getDeveloperCc98Mode();
    if (mode === "exchange") return ACT_ONE_EXCHANGE_POST.id;
    if (mode === "investigation") return INVESTIGATION_POST.id;
    return null;
  });
  const [investigationFeedback, setInvestigationFeedback] = useState("");
  const [investigationSearchReady, setInvestigationSearchReady] = useState(false);
  const finalsPhase = state.ui.libraryFinalsPhase;
  const finalsPuzzle = state.ui.libraryFinalsPuzzle;
  const access = selectFeatureAccess(state);
  const developerEditingEnabled = getActiveDeveloperCheckpoint() !== null;
  const exchangeVisible = ["movement_required", "reservation_briefing_required", "reservation_required", "movement_ready"].includes(state.actOne.phase);
  const investigationVisible = finalsPuzzle.investigationOpened;
  const noteSearchVisible = finalsPhase === "evidence_gathering" && finalsPuzzle.occupancyNoteCollected && !investigationVisible;
  const ownedEvidenceIds = useMemo(() => {
    const owned: LibraryEvidenceId[] = [];
    if (state.items.archivedLeaveRule) owned.push("archived_leave_rule");
    if (state.items.bagNonPersonProof) owned.push("bag_non_person_proof");
    if (state.items.seat022Receipt) owned.push("seat_022_receipt");
    if (state.items.libraryPresenceProof) owned.push("library_presence_proof");
    return owned;
  }, [
    state.items.archivedLeaveRule,
    state.items.bagNonPersonProof,
    state.items.libraryPresenceProof,
    state.items.seat022Receipt
  ]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "item_dropped" || event.payload?.target !== "cc98_search") return;
      if (event.payload?.item !== "occupancyNote") {
        setInvestigationFeedback("搜索框只识别与 022 占座直接相关的纸条。");
        return;
      }
      setInvestigationSearchReady(true);
      setInvestigationFeedback("纸条已读取。请核对搜索结果的来源、时间和附件。");
    });
  }, [events]);

  const questPosts = useMemo(() => {
    const next: Cc98Post[] = [];
    const withOverride = (post: Cc98Post): Cc98Post => ({ ...post, ...questPostOverrides[post.id], id: post.id, avatar: post.avatar });
    if (exchangeVisible) {
      next.push(withOverride(ACT_ONE_EXCHANGE_POST));
    }
    if (investigationVisible) {
      next.push({
        ...withOverride(INVESTIGATION_POST),
        rank: String(Math.max(1, 4 - finalsPuzzle.bdCount)).padStart(2, "0")
      });
    }
    return next;
  }, [exchangeVisible, finalsPuzzle.bdCount, investigationVisible, questPostOverrides]);
  const openPost = useMemo(
    () => questPosts.find((post) => post.id === openPostId) ?? posts.find((post) => post.id === openPostId) ?? null,
    [openPostId, posts, questPosts]
  );
  const openPostIsInvestigation = openPost?.id === INVESTIGATION_POST.id;
  const openPostIsExchange = openPost?.id === ACT_ONE_EXCHANGE_POST.id;
  const visiblePosts = useMemo(() => {
    return [...questPosts, ...posts];
  }, [posts, questPosts]);

  function searchWithOccupancyNote() {
    setInvestigationFeedback("");
    if (!state.items.occupancyNote) {
      setInvestigationFeedback("请先把 022 旁边的占座纸条带到搜索框。");
      return;
    }
    setInvestigationSearchReady(true);
    setInvestigationFeedback("找到 4 条候选记录。只有一条同时匹配来源、时间和附件。");
  }

  function selectInvestigationResult(result: typeof INVESTIGATION_SEARCH_RESULTS[number]) {
    if (result.rejection) {
      playSfx("03_");
      setInvestigationFeedback(result.rejection);
      return;
    }
    if (!kit.libraryFinals.openInvestigation()) {
      setInvestigationFeedback("这条 23 楼记录尚未满足调查门槛。");
      return;
    }
    setOpenPostId(INVESTIGATION_POST.id);
  }
  function updatePost(id: string, key: EditablePostKey, value: string) {
    if (QUEST_POST_IDS.has(id)) {
      setQuestPostOverrides((current) => ({
        ...current,
        [id]: { ...current[id], [key]: value }
      }));
      return;
    }
    setPosts((current) => current.map((post) => (post.id === id ? { ...post, [key]: value } : post)));
  }

  function savePosts() {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(posts.filter((post) => !QUEST_POST_IDS.has(post.id))));
    window.localStorage.setItem(QUEST_STORAGE_KEY, JSON.stringify(questPostOverrides));
    setEditing(false);
    playSfx("01_");
    kit.flags.toast("CC98 帖子已保存到本机。", "task");
  }

  function toggleEditing() {
    if (editing) {
      savePosts();
      return;
    }
    setMenuOpen(false);
    setEditing(true);
    playSfx("02_");
  }

  function openPostDetails(id: string) {
    setOpenPostId(id);
  }

  function resetPosts() {
    const next = cloneDefaults();
    setPosts(next);
    setQuestPostOverrides({});
    window.localStorage.removeItem(STORAGE_KEY);
    window.localStorage.removeItem(QUEST_STORAGE_KEY);
    setMenuOpen(false);
    setEditing(false);
    kit.flags.toast("CC98 帖子已恢复为默认内容。", "system");
  }

  return (
    <section className={`cc98-scene ${noteSearchVisible ? "has-search" : ""}`.trim()} aria-label="CC98热门话题">
      <header className="cc98-header">
        <PhoneNavButton
          kind="exit"
          className="cc98-back"
          label="退出 CC98，返回手机主页"
          onClick={() => router.goTo("phone_home")}
        />
        <h1>热门话题</h1>
        {developerEditingEnabled ? <div className="cc98-tools" aria-label="开发者帖子维护">
          <button type="button" aria-label="CC98更多菜单" title="更多" onClick={() => setMenuOpen((value) => !value)}>
            •••
          </button>
          <button type="button" aria-label={editing ? "保存帖子" : "编辑帖子"} title={editing ? "保存帖子" : "编辑帖子"} onClick={toggleEditing}>
            {editing ? "保存" : "编辑"}
          </button>
        </div> : <span className="cc98-header-placeholder cc98-locked-icon" aria-hidden="true">•••</span>}
      </header>

      {menuOpen ? (
        <div className="cc98-menu" role="menu">
          <button type="button" role="menuitem" onClick={resetPosts}>
            恢复默认帖子
          </button>
          <button type="button" role="menuitem" onClick={() => setMenuOpen(false)}>
            关闭菜单
          </button>
        </div>
      ) : null}

      <nav className="cc98-top-tabs" aria-label="热门话题时间筛选">
        <span className="is-active" aria-current="page">今日</span>
        {TOP_TABS.slice(1).map((tab) => <span key={tab} className="cc98-static-xxx">xxx</span>)}
      </nav>

      {noteSearchVisible ? (
        <section className="cc98-search-panel cc98-occupancy-search" aria-label="CC98占座调查搜索">
          <header className="cc98-search-heading"><strong>资料搜索</strong><span>可接收道具</span></header>
          <label className="cc98-search-row" data-drop-target="cc98_search">
            <span className="cc98-search-icon" aria-hidden="true" />
            <input
              aria-label="CC98 搜索内容"
              readOnly
              value={state.items.occupancyNote ? "022 占座纸条" : ""}
              placeholder="把占座纸条拖到这里"
            />
            <button type="button" onClick={searchWithOccupancyNote}>搜索</button>
          </label>
          <div className="cc98-search-results" aria-label="搜索结果">
            {investigationSearchReady ? (
              INVESTIGATION_SEARCH_RESULTS.map((result) => (
                <button key={result.id} type="button" className="cc98-search-result" onClick={() => selectInvestigationResult(result)}>
                  <header>
                    <strong className="cc98-search-result-title">{result.title}</strong>
                    <span className="cc98-search-result-floor">{result.floors}</span>
                  </header>
                  <span className="cc98-search-result-body">{result.body}</span>
                </button>
              ))
            ) : (
              <p className="cc98-search-empty">拖入纸条或点击搜索后显示候选记录。</p>
            )}
          </div>
          <p className="cc98-search-feedback" aria-live="polite">
            {investigationFeedback || "论坛会根据纸条内容建立 23 楼调查索引。"}
          </p>
        </section>
      ) : null}

      <main className={`cc98-feed ${editing ? "is-editing" : ""}`} aria-label="CC98帖子列表">
        {visiblePosts.map((post) => {
          const isQuestPost = QUEST_POST_IDS.has(post.id);
          const isEditablePost = editing;
          return (
          <article
            key={post.id}
            className={`cc98-post ${isQuestPost ? "is-quest-post" : ""}`.trim()}
            role={isEditablePost ? undefined : "button"}
            tabIndex={isEditablePost ? undefined : 0}
            onClick={() => !editing && openPostDetails(post.id)}
            onKeyDown={(event) => {
              if (!editing && (event.key === "Enter" || event.key === " ")) {
                if (event.key === " ") {
                  event.preventDefault();
                }
                openPostDetails(post.id);
              }
            }}
          >
            <div className="cc98-post-top">
              <span className={`cc98-avatar ${post.avatar}`} aria-hidden="true">
                <i />
              </span>
              <EditableText value={post.author} editing={isEditablePost} className="cc98-author" onCommit={(value) => updatePost(post.id, "author", value)} />
              <span className={`cc98-rank rank-${post.rank}`}>{post.rank}</span>
              <EditableText value={post.board} editing={isEditablePost} className="cc98-board" onCommit={(value) => updatePost(post.id, "board", value)} />
            </div>
            <EditableText value={post.title} editing={isEditablePost} className="cc98-title" onCommit={(value) => updatePost(post.id, "title", value)} />
            <div className="cc98-meta">
              <span>
                <EditableText value={post.replies} editing={isEditablePost} className="cc98-meta-value" onCommit={(value) => updatePost(post.id, "replies", value)} /> 回复 ·{" "}
                <EditableText value={post.views} editing={isEditablePost} className="cc98-meta-value" onCommit={(value) => updatePost(post.id, "views", value)} /> 浏览
              </span>
              <EditableText value={post.time} editing={isEditablePost} className="cc98-time" onCommit={(value) => updatePost(post.id, "time", value)} />
            </div>
            {isEditablePost ? (
              <button
                type="button"
                className="cc98-edit-body"
                onClick={(event) => {
                  event.stopPropagation();
                  setOpenPostId(post.id);
                }}
              >
                正文
              </button>
            ) : null}
          </article>
          );
        })}
      </main>

      <nav className="cc98-bottom-nav cc98-bottom-static" aria-label="CC98主导航">
        {BOTTOM_TABS.map((tab) => (
          <span key={tab.label} data-locked-icon={tab.label} aria-hidden="true">
            <i>{tab.icon}</i><b>{tab.label}</b>
          </span>
        ))}
      </nav>

      {openPost && !editing ? (
        <Cc98ThreadPage
          post={openPost}
          onBack={() => setOpenPostId(null)}
          interactiveContent={
            openPostIsExchange ? (
              <ControlExchangePuzzle
                router={router}
                balanceShifted={state.actOne.balanceShifted}
                purchased={state.actOne.gamepadPurchased}
              />
            ) : openPostIsInvestigation ? (
              <>
                <Ac01FilterPuzzle
                  optionalAc01Floors={finalsPuzzle.optionalAc01Floors}
                  showBdContent={access.cc98Bd}
                />
                <TopTenRisePuzzle
                  appliedReplyIds={finalsPuzzle.appliedBdReplyIds}
                  bdCount={finalsPuzzle.bdCount}
                  phase={finalsPhase}
                  ownedEvidenceIds={ownedEvidenceIds}
                  uploadedEvidenceIds={finalsPuzzle.cc98UploadedEvidenceIds}
                  preBdBriefingSeen={finalsPuzzle.preBdBriefingSeen}
                  events={events}
                  showUploader={access.cc98OwnerUpload}
                  showBd={access.cc98Bd}
                />
              </>
            ) : undefined
          }
          showBdContent={openPostIsInvestigation && access.cc98Bd}
          locked={openPostIsInvestigation && finalsPuzzle.bdCount >= 3}
          showLibraryAdminReply={openPostIsInvestigation && finalsPuzzle.bdCount >= 3}
        />
      ) : null}

      {openPost && editing ? (
        <div className="cc98-detail-layer" role="presentation" onPointerDown={() => setOpenPostId(null)}>
          <article className="cc98-detail" role="dialog" aria-modal="true" aria-label={openPost.title} onPointerDown={(event) => event.stopPropagation()}>
            <header>
              <strong>{openPost.author}</strong>
              <PhoneNavButton kind="close" label="关闭帖子编辑" onClick={() => setOpenPostId(null)} />
            </header>
            <h2>{openPost.title}</h2>
            <textarea value={openPost.body} onChange={(event) => updatePost(openPost.id, "body", event.target.value)} />
            <footer>{openPost.board} · {openPost.time}</footer>
          </article>
        </div>
      ) : null}
    </section>
  );
}
