import { useEffect, useMemo, useState } from "react";
import defaultPostData from "../../../data/cc98.posts.json";
import theaterContent from "../../../data/chapter3-theater.content.json";
import libraryFinalsContent from "../../../data/library-finals.content.json";
import qizhenContent from "../../../data/chapter3-qizhen-lake.content.json";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { LibraryEvidenceId, TheaterTicketCommissionPhase } from "../../../core/types";
import { selectFeatureAccess } from "../../../core/FeatureAccess";
import actOneContent from "../../../data/act-one-bootstrap.content.json";
import { getActiveDeveloperCheckpoint, getDeveloperCc98Mode } from "../../../modules/DeveloperChannel";
import { kit } from "../../../modules/GameKit";
import { consumeCc98ThreadIntent } from "../../../modules/NavIntent";
import { playSfx } from "../../../modules/Sfx";
import { Ac01FilterPuzzle } from "./Ac01FilterPuzzle";
import { ControlExchangePuzzle } from "./ControlExchangePuzzle";
import { Cc98ThreadPage } from "./ThreadPage";
import { TheaterTicketCommission } from "./TheaterTicketCommission";
import { TopTenRisePuzzle } from "./TopTenRisePuzzle";
import type { AvatarVariant, Cc98Post } from "./cc98Types";
import "../../../styles/library-v2-phone.css";

type EditablePostKey = "author" | "rank" | "board" | "title" | "replies" | "views" | "time" | "body";

const STORAGE_KEY = "seven-fifty-five.cc98-posts.v2";
const QUEST_STORAGE_KEY = "seven-fifty-five.cc98-quest-post-overrides.v1";
const NETWORK_LOAD_DELAY_MS = 700;
const NETWORK_REJECT_DELAY_MS = 1600;
const NETWORK_CRASH_DELAY_MS = 620;
const DEFAULT_POSTS = defaultPostData as Cc98Post[];
const ACT_ONE_EXCHANGE_POST = actOneContent.cc98ExchangePost as Cc98Post;
const investigationPostContent = libraryFinalsContent.cc98.post;
const BD_PASSWORD_REPLY_COUNT = libraryFinalsContent.cc98.bdPassword.posts.length;
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
const QIZHEN_WITNESS_POST: Cc98Post = {
  id: "qizhen-wet-paper-witness",
  author: "匿名用户",
  avatar: "anonymous",
  rank: "12",
  board: "校园生活",
  title: qizhenContent.locationSearch.cc98.title,
  replies: "3",
  views: "755",
  time: "刚刚",
  body: "如题。",
  threadReplies: qizhenContent.locationSearch.cc98.replies.map((reply, index) => ({
    personaId: ["late-printer", "yuquan-wind", "anonymous-user"][index] ?? "anonymous-user",
    time: `今天 09:${String(12 + index * 2).padStart(2, "0")}`,
    floor: `${[3, 8, 14][index]}楼`,
    text: reply.replace(/^\d+楼：/, ""),
    likes: String([7, 4, 14][index]),
    dislikes: "0"
  }))
};
const theaterTicketCommissionContent = theaterContent.cc98TicketCommission;

function createTheaterTicketCommissionPost(
  phase: TheaterTicketCommissionPhase,
  claimedWave: 1 | 2 | null
): Cc98Post {
  const threadReplies: NonNullable<Cc98Post["threadReplies"]> = [
    {
      personaId: "late-printer",
      time: "今天 08:29",
      floor: "2楼",
      text: theaterTicketCommissionContent.initialReply,
      likes: "12",
      dislikes: "0"
    }
  ];
  if (phase === "accepted" || phase === "first_wave_failed" || phase === "delivered") {
    threadReplies.push({
      personaId: "qiushi-rider",
      time: "今天 08:30",
      floor: "3楼",
      role: "玩家",
      text: theaterTicketCommissionContent.acceptedReply,
      likes: "7",
      dislikes: "0"
    });
  }
  if (phase === "first_wave_failed" || (phase === "delivered" && claimedWave !== 1)) {
    threadReplies.push({
      personaId: "socket-observer",
      time: "今天 08:31",
      floor: "4楼",
      role: "网络提示",
      text: theaterTicketCommissionContent.firstWaveReply,
      likes: "32",
      dislikes: "0"
    });
  }
  if (phase === "delivered") {
    threadReplies.push({
      personaId: "wild-auditor",
      time: "今天 08:32",
      floor: "5楼",
      role: "系统回执",
      text: claimedWave === 1
        ? theaterTicketCommissionContent.deliveredFirstWaveReply
        : theaterTicketCommissionContent.deliveredReply,
      likes: "55",
      dislikes: "0"
    });
  }
  return {
    id: theaterTicketCommissionContent.id,
    author: theaterTicketCommissionContent.author,
    avatar: "warrior",
    rank: theaterTicketCommissionContent.rank,
    board: theaterTicketCommissionContent.board,
    title: theaterTicketCommissionContent.title,
    replies: String(threadReplies.length),
    views: theaterTicketCommissionContent.views,
    time: theaterTicketCommissionContent.time,
    body: theaterTicketCommissionContent.body,
    threadReplies
  };
}
const INVESTIGATION_SEARCH_RESULTS = [
  { id: "seat-022-backpack", title: INVESTIGATION_POST.title, floors: "23 楼", body: INVESTIGATION_POST.body, rejection: null },
  { id: "seat-022-old-source", title: "【求助】022 座位今日临时离开", floors: "12 楼", body: "来源为今日新帖，没有旧版离座规定的引用。", rejection: "来源不匹配：这是今日新帖，纸条引用的是旧版公开记录。" },
  { id: "seat-022-wrong-time", title: "【记录】二南 022 晚间使用情况", floors: "31 楼", body: "发布时间为当日 22:40，早于纸条中的本次离座事件。", rejection: "时间不匹配：这条记录早于本次 022 占用事件。" },
  { id: "seat-022-missing-attachment", title: "【闲聊】二楼南区今天还有位置吗", floors: "18 楼", body: "正文提到 022，附件区为空。", rejection: "附件不匹配：这条帖子没有纸条对应的离座凭据。" }
] as const;
const QUEST_POST_IDS = new Set([
  ACT_ONE_EXCHANGE_POST.id,
  INVESTIGATION_POST.id,
  QIZHEN_WITNESS_POST.id,
  theaterTicketCommissionContent.id
]);
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
  const [requestedThreadId] = useState(() => consumeCc98ThreadIntent());
  const ticketPortalCellularAccess = state.networkMode === "cellular"
    && ["accepted", "first_wave_failed", "delivered"].includes(
      state.theaterHunt.cc98TicketCommissionPhase
    );
  const [entryAccessAllowed] = useState(() => {
    if (kit.network.canOpenCc98()) return true;
    return ticketPortalCellularAccess;
  });
  const [networkPhase, setNetworkPhase] = useState<"loading" | "ready" | "crashing">("loading");
  const [posts, setPosts] = useState<Cc98Post[]>(loadPosts);
  const [questPostOverrides, setQuestPostOverrides] = useState<Record<string, Partial<Cc98Post>>>(loadQuestPostOverrides);
  const [editing, setEditing] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [openPostId, setOpenPostId] = useState<string | null>(() => {
    if (requestedThreadId) return requestedThreadId;
    if (ticketPortalCellularAccess) return theaterTicketCommissionContent.id;
    const mode = getDeveloperCc98Mode();
    if (mode === "exchange") return ACT_ONE_EXCHANGE_POST.id;
    if (mode === "investigation") return INVESTIGATION_POST.id;
    if (mode === "theater_ticket") return theaterTicketCommissionContent.id;
    return null;
  });
  const [investigationFeedback, setInvestigationFeedback] = useState("");
  const [investigationSearchReady, setInvestigationSearchReady] = useState(false);
  const [qizhenSearchReady, setQizhenSearchReady] = useState(() => state.qizhenLake.bridgeClueFound);
  const finalsPhase = state.ui.libraryFinalsPhase;
  const finalsPuzzle = state.ui.libraryFinalsPuzzle;
  const access = selectFeatureAccess(state);
  const developerEditingEnabled = getActiveDeveloperCheckpoint() !== null;
  const exchangeVisible = ["movement_required", "reservation_briefing_required", "reservation_required", "movement_ready"].includes(state.actOne.phase);
  const investigationVisible = finalsPuzzle.investigationOpened;
  const noteSearchVisible = finalsPhase === "evidence_gathering" && finalsPuzzle.occupancyNoteCollected && !investigationVisible;
  const qizhenSearchVisible = state.qizhenLake.active && state.qizhenLake.phase === "location_search";
  const theaterTicketCommissionPhase = state.theaterHunt.cc98TicketCommissionPhase;
  const theaterTicketClaimedWave = state.theaterHunt.cc98TicketClaimedWave;
  const theaterTicketCommissionVisible = theaterTicketCommissionPhase !== "locked";
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
      if (event.payload?.item === "occupancyNote") {
        setInvestigationSearchReady(true);
        setInvestigationFeedback("纸条已读取。请核对搜索结果的来源、时间和附件。");
        return;
      }
      if (event.payload?.item === "wetProgram" && qizhenSearchVisible) {
        setQizhenSearchReady(true);
        setInvestigationFeedback("湿纸特征已加入搜索。找到一条刚发布的目击帖。");
      }
    });
  }, [events, qizhenSearchVisible]);

  const questPosts = useMemo(() => {
    const next: Cc98Post[] = [];
    const withOverride = (post: Cc98Post): Cc98Post => ({ ...post, ...questPostOverrides[post.id], id: post.id, avatar: post.avatar });
    if (exchangeVisible) {
      next.push(withOverride(ACT_ONE_EXCHANGE_POST));
    }
    if (investigationVisible) {
      next.push({
        ...withOverride(INVESTIGATION_POST),
        rank: finalsPuzzle.bdCount >= 3 ? "01" : "04",
        replies: finalsPuzzle.preBdBriefingSeen || finalsPuzzle.bdCount >= 3
          ? String(Number(INVESTIGATION_POST.replies) + BD_PASSWORD_REPLY_COUNT)
          : INVESTIGATION_POST.replies
      });
    }
    if (theaterTicketCommissionVisible) {
      next.push(withOverride(createTheaterTicketCommissionPost(theaterTicketCommissionPhase, theaterTicketClaimedWave)));
    }
    if (qizhenSearchVisible && (qizhenSearchReady || state.qizhenLake.bridgeClueFound)) {
      next.push(withOverride(QIZHEN_WITNESS_POST));
    }
    return next;
  }, [exchangeVisible, finalsPuzzle.bdCount, finalsPuzzle.preBdBriefingSeen, investigationVisible, qizhenSearchReady, qizhenSearchVisible, questPostOverrides, state.qizhenLake.bridgeClueFound, theaterTicketClaimedWave, theaterTicketCommissionPhase, theaterTicketCommissionVisible]);
  const openPost = useMemo(
    () => questPosts.find((post) => post.id === openPostId) ?? posts.find((post) => post.id === openPostId) ?? null,
    [openPostId, posts, questPosts]
  );
  const openPostIsInvestigation = openPost?.id === INVESTIGATION_POST.id;
  const openPostIsExchange = openPost?.id === ACT_ONE_EXCHANGE_POST.id;
  const openPostIsQizhen = openPost?.id === QIZHEN_WITNESS_POST.id;
  const openPostIsTheaterTicket = openPost?.id === theaterTicketCommissionContent.id;
  const visiblePosts = useMemo(() => {
    return [...questPosts, ...posts];
  }, [posts, questPosts]);

  useEffect(() => {
    let exitTimer: number | null = null;
    const gateTimer = window.setTimeout(() => {
      if (entryAccessAllowed) {
        setNetworkPhase("ready");
        return;
      }
      setNetworkPhase("crashing");
      playSfx("12_");
      events.emit("cc98_network_rejected", { requiredNetwork: "campus_wifi" });
      kit.flags.toast("CC98 仅支持校园网。请切换后重新进入。", "system");
      exitTimer = window.setTimeout(() => router.goTo("phone_home"), NETWORK_CRASH_DELAY_MS);
    }, entryAccessAllowed ? NETWORK_LOAD_DELAY_MS : NETWORK_REJECT_DELAY_MS);

    return () => {
      window.clearTimeout(gateTimer);
      if (exitTimer !== null) window.clearTimeout(exitTimer);
    };
  }, [entryAccessAllowed, events, router]);

  if (networkPhase !== "ready") {
    return (
      <section
        className={`app-screen cc98-network-gate ${networkPhase === "crashing" ? "is-crashing" : ""}`.trim()}
        aria-label="CC98 校园网验证"
      >
        <div className="cc98-network-card" role="status" aria-live="polite">
          <span className="cc98-network-logo" aria-hidden="true">CC98</span>
          <strong>{networkPhase === "crashing" ? "网络验证失败" : "校内访问验证"}</strong>
          <p>{entryAccessAllowed
            ? ticketPortalCellularAccess ? "正在恢复手机票务页面" : "正在连接校园网服务"
            : "正在检查 ZJUWLAN"}</p>
          <span className="cc98-network-dots" aria-hidden="true"><i /><i /><i /></span>
        </div>
        <button type="button" className="app-exit px-btn paper" onClick={() => router.goTo("phone_home")}>退出</button>
      </section>
    );
  }

  function searchWithOccupancyNote() {
    setInvestigationFeedback("");
    if (!state.items.occupancyNote) {
      return;
    }
    setInvestigationSearchReady(true);
    setInvestigationFeedback("找到 4 条候选记录。");
  }

  function searchWithWetProgram() {
    setInvestigationFeedback("");
    if (!state.items.wetProgram) {
      setInvestigationFeedback("需要能说明纸张状态的实物线索。");
      return;
    }
    setQizhenSearchReady(true);
    setInvestigationFeedback("找到 1 条刚发布的目击帖。");
  }

  function collectBridgeKeyword() {
    if (!kit.qizhenLake.collectBridgeClue()) {
      setInvestigationFeedback("当前无法记录这条目击信息。");
      return;
    }
    setInvestigationFeedback(`${qizhenContent.locationSearch.cc98.system}\n${qizhenContent.locationSearch.cc98.player}`);
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
    <section className={`cc98-scene ${noteSearchVisible || qizhenSearchVisible ? "has-search" : ""}`.trim()} aria-label="CC98热门话题">
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

      {qizhenSearchVisible ? (
        <section className="cc98-search-panel cc98-qizhen-search" aria-label="湿纸目击搜索">
          <header className="cc98-search-heading"><strong>目击搜索</strong><span>可接收道具</span></header>
          <label className="cc98-search-row" data-drop-target="cc98_search">
            <span className="cc98-search-icon" aria-hidden="true" />
            <input
              aria-label="湿纸目击搜索内容"
              readOnly
              value={state.items.wetProgram ? "剧院门口 湿纸" : ""}
              placeholder="把湿掉的节目单拖到这里"
            />
            <button type="button" onClick={searchWithWetProgram}>搜索</button>
          </label>
          <p className="cc98-search-feedback" aria-live="polite">
            {investigationFeedback || "先用实物特征建立目击范围。"}
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
                campusCardCents={state.wallet.campusCardCents}
                purchased={state.actOne.gamepadPurchased}
              />
            ) : openPostIsInvestigation ? (
              <>
                <Ac01FilterPuzzle
                  optionalAc01Floors={finalsPuzzle.optionalAc01Floors}
                  showBdContent={access.cc98Bd}
                />
                <TopTenRisePuzzle
                  selectedPostIds={finalsPuzzle.bdSelectedPostIds}
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
          beforeRepliesContent={openPostIsTheaterTicket && theaterTicketCommissionPhase !== "locked" ? (
            <TheaterTicketCommission
              phase={theaterTicketCommissionPhase}
              networkMode={state.networkMode}
              claimedWave={theaterTicketClaimedWave}
              ticketCodeRead={state.theaterHunt.ticketCodeRead}
            />
          ) : undefined}
          afterRepliesContent={openPostIsQizhen ? (
            <section className="cc98-qizhen-keyword" aria-label="提取目击关键词">
              <strong>目击信息可归纳为一个地点关键词</strong>
              <button type="button" onClick={collectBridgeKeyword} disabled={state.qizhenLake.bridgeClueFound}>
                {state.qizhenLake.bridgeClueFound ? "已取得：桥边" : "记录关键词：桥边"}
              </button>
              {state.qizhenLake.bridgeClueFound ? (
                <p>{qizhenContent.locationSearch.cc98.system}<br />{qizhenContent.locationSearch.cc98.player}</p>
              ) : null}
            </section>
          ) : undefined}
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
