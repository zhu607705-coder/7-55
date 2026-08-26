import { useEffect, useMemo, useState } from "react";
import defaultPostData from "../../../data/cc98.posts.json";
import chapterFourCc98Content from "../../../data/chapter4-cc98.content.json";
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
import {
  CHAPTER_FOUR_CC98_FACT_IDS,
  selectChapterFourCc98Projection
} from "../../../modules/ChapterFourCc98Model";
import { Ac01FilterPuzzle } from "./Ac01FilterPuzzle";
import { ControlExchangePuzzle } from "./ControlExchangePuzzle";
import { Cc98ThreadPage } from "./ThreadPage";
import { TheaterTicketCommission } from "./TheaterTicketCommission";
import { TopTenRisePuzzle } from "./TopTenRisePuzzle";
import { UnifiedIdentityLogin } from "./UnifiedIdentityLogin";
import type { AvatarVariant, Cc98Post } from "./cc98Types";
import "../../../styles/library-v2-phone.css";

type EditablePostKey = "author" | "rank" | "board" | "title" | "replies" | "views" | "time" | "body";

const STORAGE_KEY = "seven-fifty-five.cc98-posts.v2";
const QUEST_STORAGE_KEY = "seven-fifty-five.cc98-quest-post-overrides.v1";
const CHAPTER_FOUR_STUDY_LEGACY_POST_ID = "p03";
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
const chapterFourStudyPostContent = chapterFourCc98Content.mainPost;
const CHAPTER_FOUR_STUDY_POST: Cc98Post = {
  id: chapterFourStudyPostContent.id,
  author: chapterFourStudyPostContent.author,
  avatar: chapterFourStudyPostContent.avatar as AvatarVariant,
  rank: chapterFourStudyPostContent.rank,
  board: chapterFourCc98Content.board,
  title: chapterFourStudyPostContent.title,
  replies: String(chapterFourCc98Content.replies.length),
  views: "2908",
  time: chapterFourStudyPostContent.time,
  body: chapterFourStudyPostContent.body,
  threadReplies: chapterFourCc98Content.replies.map((reply, index) => ({
    personaId: [
      "socket-observer",
      "late-printer",
      "socket-observer",
      "wild-auditor",
      "qiushi-rider",
      "yuquan-wind"
    ][index] ?? "socket-observer",
    time: `今天 ${reply.time}`,
    floor: reply.floor,
    role: reply.role,
    text: reply.text,
    likes: String([18, 11, 23, 16, 27, 31][index] ?? 8),
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
  CHAPTER_FOUR_STUDY_POST.id,
  theaterTicketCommissionContent.id
]);
const TOP_TABS = ["今日", "发现", "本周", "本月", "往年今日", "活动"];
const BOTTOM_TABS = [
  { id: "hot", label: "热门", icon: "◉" },
  { id: "new", label: "新帖", icon: "✿" },
  { id: "followed", label: "关注", icon: "♡" },
  { id: "boards", label: "版面", icon: "▦" },
  { id: "profile", label: "我", icon: "◎" }
] as const;
type Cc98BottomTabId = typeof BOTTOM_TABS[number]["id"];

const DEFAULT_FOLLOWED_BOARDS = ["校园生活", "学习天地", "交通出行", "开怀一笑"];
const PREFERRED_BOARD_ORDER = [
  "校园生活",
  "交通出行",
  "学习天地",
  "手机服务",
  "图书馆",
  "自习室",
  "食堂",
  "打印服务",
  "校园卡",
  "失物招领",
  "二手市场",
  "开怀一笑"
];
const BOARD_DESCRIPTIONS: Record<string, string> = {
  "校园生活": "校内日常、天气和临时消息",
  "交通出行": "步行、骑行和校内出行",
  "学习天地": "资料、课程和复习讨论",
  "手机服务": "电话卡、网络和通讯服务",
  "图书馆": "馆内规则、座位和设备",
  "自习室": "自习地点与安静程度",
  "食堂": "窗口、排队和座位",
  "打印服务": "打印、复印和取件",
  "校园卡": "校园卡使用和服务记录",
  "失物招领": "遗失物和失物信息",
  "二手市场": "闲置物品与当面交易提醒",
  "开怀一笑": "轻松话题和校园小事"
};

function postFreshness(post: Cc98Post) {
  if (post.time === "刚刚") return Number.MAX_SAFE_INTEGER;
  const match = post.time.match(/(\d{1,2}):(\d{2})/);
  if (!match) return 0;
  return Number(match[1]) * 60 + Number(match[2]);
}

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
    const savedPosts = (parsed as Cc98Post[]).filter((post) => !QUEST_POST_IDS.has(post.id));
    const savedById = new Map(savedPosts.map((post) => [post.id, post]));
    const mergedDefaults = cloneDefaults().map((defaults) => {
      const savedPost = savedById.get(defaults.id);
      return savedPost ? {
        ...defaults,
        ...savedPost,
        // Replies are authored game content, while the post body remains player-editable.
        threadReplies: defaults.threadReplies ?? savedPost.threadReplies
      } : defaults;
    });
    const defaultIds = new Set(DEFAULT_POSTS.map((post) => post.id));
    return [
      ...mergedDefaults,
      ...savedPosts.filter((post) => !defaultIds.has(post.id))
    ];
  } catch {
    return cloneDefaults();
  }
}

const CHAPTER_FOUR_STUDY_FACTS = [
  {
    id: CHAPTER_FOUR_CC98_FACT_IDS.courseYearIndex,
    title: "课程与年份入口",
    detail: "先选课程，再按年份进入资料目录。"
  },
  {
    id: CHAPTER_FOUR_CC98_FACT_IDS.archivedDiscussion,
    title: "旧自习讨论",
    detail: "旧帖能核对座位与插座记录，但日期可能已经过期。"
  },
  {
    id: CHAPTER_FOUR_CC98_FACT_IDS.fieldCheckRequired,
    title: "今晚仍要现场核验",
    detail: "A2 的门牌、房间和通道以今晚实际情况为准。"
  },
  {
    id: "homepage_recommendation",
    title: "首页推荐顺序",
    detail: "推荐位会变化，无法作为资料目录。"
  },
  {
    id: "copy_old_route",
    title: "直接照抄旧路线",
    detail: "旧路线没有记录今晚的封闭入口。"
  }
] as const;

function ChapterFourStudyIndexImport({ imported }: { imported: boolean }) {
  const [selectedFactIds, setSelectedFactIds] = useState<string[]>([]);
  const [feedback, setFeedback] = useState(imported ? chapterFourCc98Content.import.duplicate : "");

  function toggleFact(id: string) {
    if (imported) return;
    setSelectedFactIds((current) => current.includes(id)
      ? current.filter((factId) => factId !== id)
      : current.length >= 3
        ? [current[1], current[2], id]
        : [...current, id]
    );
    setFeedback("");
  }

  function importStudyIndex() {
    const result = kit.chapterFour.importCc98StudyIndex(selectedFactIds);
    setFeedback(result === "accepted"
      ? chapterFourCc98Content.import.success
      : result === "already_complete"
        ? chapterFourCc98Content.import.duplicate
        : result === "incorrect"
          ? "这三项里混进了今晚无法使用的信息。再看一遍帖子和回复。"
          : result === "locked"
            ? chapterFourCc98Content.import.notAtChapter
            : chapterFourCc98Content.import.locked
    );
    if (result === "accepted") {
      playSfx("07_");
      kit.flags.toast("学习天地资料索引已导入自习群。", "task");
    }
  }

  return (
    <section className="cc98-study-import" aria-label="筛选并导入学习天地资料">
      <header>
        <small>导入前核对</small>
        <strong>选出今晚还能使用的三项信息</strong>
      </header>
      <div className="cc98-study-facts">
        {CHAPTER_FOUR_STUDY_FACTS.map((fact) => {
          const selected = selectedFactIds.includes(fact.id);
          return (
            <button
              key={fact.id}
              type="button"
              className={selected ? "is-selected" : ""}
              aria-pressed={selected}
              disabled={imported}
              onClick={() => toggleFact(fact.id)}
            >
              <span aria-hidden="true">{selected ? "■" : "□"}</span>
              <span><b>{fact.title}</b><small>{fact.detail}</small></span>
            </button>
          );
        })}
      </div>
      <button
        type="button"
        className="cc98-study-import-action"
        disabled={imported || selectedFactIds.length !== 3}
        onClick={importStudyIndex}
      >
        {imported ? "已导入麦斯威夜间自习群" : chapterFourCc98Content.import.buttonLabel}
      </button>
      {feedback ? <p role="status">{feedback}</p> : null}
    </section>
  );
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

function InterludeJournalCloseout({
  router
}: Pick<SceneComponentProps, "router">) {
  const [feedback, setFeedback] = useState("");
  const [summaryChoice, setSummaryChoice] = useState<"safe_return" | "details_withheld">("details_withheld");

  function closeThread() {
    const result = kit.chapterThreeInterlude.completeJournalCloseout(summaryChoice);
    if (result === "accepted" || result === "already_complete") {
      router.goTo("timeline_recovery");
      return;
    }
    setFeedback("恢复工具尚未建立这条记录。");
  }

  return (
    <section className="cc98-scene interlude-journal-closeout" aria-label="启真湖划船记录收尾">
      <header className="cc98-header">
        <PhoneNavButton
          kind="exit"
          className="cc98-back"
          label="退出帖子，返回记录恢复"
          onClick={() => router.goTo("timeline_recovery")}
        />
        <h1>CC98小程序</h1>
        <span className="cc98-header-placeholder" aria-hidden="true">•••</span>
      </header>
      <main className="interlude-journal-thread">
        <article>
          <header><span className="interlude-journal-avatar" aria-hidden="true">舟</span><div><strong>林星宇</strong><small>楼主 · 22:37</small></div></header>
          <h2>启真湖划船记录｜风景很好，返程提前了</h2>
          <p>从小码头下水。湖面比岸边安静，风从剧场方向过来。最后一张照片没同步上来，我先回岸上整理。</p>
          <figure><div className="interlude-journal-lake" aria-hidden="true"><i /><i /><i /></div><figcaption>启真湖 · 22:37:05</figcaption></figure>
        </article>
        <section className="interlude-journal-replies">
          <p><b>2楼</b> 晚上水面反光挺亮，靠岸别太快。</p>
          <p><b>3楼</b> 最后一张图像是朝东边拍的。</p>
        </section>
        <fieldset className="interlude-journal-choice">
          <legend>本次记录准备结束，选择楼主的最后一条回复。</legend>
          <label className={summaryChoice === "safe_return" ? "is-selected" : ""}>
            <input
              type="radio"
              name="qizhen-summary"
              checked={summaryChoice === "safe_return"}
              onChange={() => setSummaryChoice("safe_return")}
            />
            <strong>安全返航</strong>
            <span>船和人都回来了。湖上的事先记到这里，剩下的等我整理。</span>
          </label>
          <label className={summaryChoice === "details_withheld" ? "is-selected" : ""}>
            <input
              type="radio"
              name="qizhen-summary"
              checked={summaryChoice === "details_withheld"}
              onChange={() => setSummaryChoice("details_withheld")}
            />
            <strong>细节暂不公开</strong>
            <span>最后一段发生了点不适合写进划船记录的事。人已上岸，其他细节暂时保留。</span>
          </label>
        </fieldset>
        <button type="button" className="interlude-primary-action" onClick={closeThread}>发布收尾并保存时间</button>
        {feedback ? <p className="interlude-feedback" role="status">{feedback}</p> : null}
      </main>
    </section>
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
  const [activeBottomTab, setActiveBottomTab] = useState<Cc98BottomTabId>("hot");
  const [selectedBoard, setSelectedBoard] = useState<string | null>(null);
  const [followedBoards, setFollowedBoards] = useState<string[]>(DEFAULT_FOLLOWED_BOARDS);
  const [readPostIds, setReadPostIds] = useState<string[]>([]);
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
  const chapterFourCc98 = selectChapterFourCc98Projection(state);
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
    if (chapterFourCc98.visible) {
      next.push(withOverride(CHAPTER_FOUR_STUDY_POST));
    }
    return next;
  }, [chapterFourCc98.visible, exchangeVisible, finalsPuzzle.bdCount, finalsPuzzle.preBdBriefingSeen, investigationVisible, qizhenSearchReady, qizhenSearchVisible, questPostOverrides, state.qizhenLake.bridgeClueFound, theaterTicketClaimedWave, theaterTicketCommissionPhase, theaterTicketCommissionVisible]);
  const openPost = useMemo(
    () => questPosts.find((post) => post.id === openPostId) ?? posts.find((post) => post.id === openPostId) ?? null,
    [openPostId, posts, questPosts]
  );
  const openPostIsInvestigation = openPost?.id === INVESTIGATION_POST.id;
  const openPostIsExchange = openPost?.id === ACT_ONE_EXCHANGE_POST.id;
  const openPostIsQizhen = openPost?.id === QIZHEN_WITNESS_POST.id;
  const openPostIsTheaterTicket = openPost?.id === theaterTicketCommissionContent.id;
  const openPostIsChapterFourStudy = openPost?.id === CHAPTER_FOUR_STUDY_POST.id;
  const visiblePosts = useMemo(() => {
    return [...questPosts, ...posts];
  }, [posts, questPosts]);
  const boardEntries = useMemo(() => {
    const postCounts = new Map<string, number>();
    visiblePosts.forEach((post) => postCounts.set(post.board, (postCounts.get(post.board) ?? 0) + 1));
    return [...postCounts.entries()]
      .sort(([left], [right]) => {
        const leftOrder = PREFERRED_BOARD_ORDER.indexOf(left);
        const rightOrder = PREFERRED_BOARD_ORDER.indexOf(right);
        const normalizedLeft = leftOrder === -1 ? PREFERRED_BOARD_ORDER.length : leftOrder;
        const normalizedRight = rightOrder === -1 ? PREFERRED_BOARD_ORDER.length : rightOrder;
        return normalizedLeft - normalizedRight || left.localeCompare(right, "zh-CN");
      })
      .map(([board, postCount]) => ({
        board,
        postCount,
        description: BOARD_DESCRIPTIONS[board] ?? "校内讨论和临时信息"
      }));
  }, [visiblePosts]);
  const activeNavigationTab: Cc98BottomTabId = selectedBoard ? "boards" : activeBottomTab;
  const feedPosts = useMemo(() => {
    const boardFiltered = selectedBoard
      ? visiblePosts.filter((post) => post.board === selectedBoard)
      : visiblePosts;
    if (activeNavigationTab === "new") {
      return [...boardFiltered].sort((left, right) => postFreshness(right) - postFreshness(left));
    }
    if (activeNavigationTab === "followed") {
      return boardFiltered.filter((post) => followedBoards.includes(post.board));
    }
    return boardFiltered;
  }, [activeNavigationTab, followedBoards, selectedBoard, visiblePosts]);
  const recentPosts = useMemo(() => {
    const postsById = new Map(visiblePosts.map((post) => [post.id, post]));
    return readPostIds.flatMap((postId) => {
      const post = postsById.get(postId);
      return post ? [post] : [];
    });
  }, [readPostIds, visiblePosts]);

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

  if (!state.actOne.cc98Login.authenticated) {
    return <UnifiedIdentityLogin state={state} onExit={() => router.goTo("phone_home")} />;
  }

  if (
    state.chapterThreeInterlude.recoveryOpened
    && !state.chapterThreeInterlude.evidenceIds.includes("journal_start")
  ) {
    return <InterludeJournalCloseout router={router} />;
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
    const resolvedPostId =
      id === CHAPTER_FOUR_STUDY_LEGACY_POST_ID && chapterFourCc98.visible
        ? CHAPTER_FOUR_STUDY_POST.id
        : id;
    setReadPostIds((current) => [
      resolvedPostId,
      ...current.filter((postId) => postId !== resolvedPostId)
    ].slice(0, 8));
    setOpenPostId(resolvedPostId);
  }

  function selectBottomTab(tabId: Cc98BottomTabId) {
    setActiveBottomTab(tabId);
    setSelectedBoard(null);
    setOpenPostId(null);
    setMenuOpen(false);
    setEditing(false);
  }

  function openBoard(board: string) {
    setActiveBottomTab("boards");
    setSelectedBoard(board);
    setOpenPostId(null);
    setMenuOpen(false);
    setEditing(false);
  }

  function toggleFollowedBoard(board: string) {
    setFollowedBoards((current) => current.includes(board)
      ? current.filter((entry) => entry !== board)
      : [...current, board]
    );
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
        {TOP_TABS.slice(1).map((tab) => <span key={tab}>{tab}</span>)}
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

      {activeNavigationTab === "boards" && !selectedBoard ? (
        <section className="cc98-board-directory" aria-label="CC98版面目录">
          <header className="cc98-directory-heading">
            <div>
              <strong>全部版面</strong>
              <span>选择一个版面查看帖子</span>
            </div>
            <b>{boardEntries.length} 个</b>
          </header>
          <div className="cc98-board-grid">
            {boardEntries.map(({ board, postCount, description }) => {
              const followed = followedBoards.includes(board);
              return (
                <article className="cc98-board-card" key={board}>
                  <button
                    type="button"
                    className="cc98-board-open"
                    aria-label={`进入${board}版面，共${postCount}帖`}
                    onClick={() => openBoard(board)}
                  >
                    <span aria-hidden="true">▦</span>
                    <strong>{board}</strong>
                    <small>{description}</small>
                    <em>{postCount} 帖</em>
                  </button>
                  <button
                    type="button"
                    className={`cc98-board-follow ${followed ? "is-followed" : ""}`.trim()}
                    aria-pressed={followed}
                    aria-label={followed ? `取消关注${board}` : `关注${board}`}
                    onClick={() => toggleFollowedBoard(board)}
                  >
                    {followed ? "已关注" : "关注"}
                  </button>
                </article>
              );
            })}
          </div>
        </section>
      ) : activeNavigationTab === "profile" ? (
        <section className="cc98-profile" aria-label="CC98我的页面">
          <header className="cc98-directory-heading">
            <div>
              <strong>我的浏览</strong>
              <span>本次打开过的帖子会留在这里</span>
            </div>
            <b>{recentPosts.length} 条</b>
          </header>
          <dl className="cc98-profile-summary">
            <div><dt>关注版面</dt><dd>{followedBoards.length} 个</dd></div>
            <div><dt>浏览记录</dt><dd>{recentPosts.length} 条</dd></div>
          </dl>
          {recentPosts.length ? (
            <div className="cc98-recent-posts" aria-label="最近浏览">
              {recentPosts.map((post) => (
                <button type="button" key={post.id} onClick={() => openPostDetails(post.id)}>
                  <span>{post.board}</span>
                  <strong>{post.title}</strong>
                  <small>{post.author} · {post.time}</small>
                </button>
              ))}
            </div>
          ) : <p className="cc98-empty">还没有浏览记录。打开一篇帖子后会出现在这里。</p>}
        </section>
      ) : (
        <main className={`cc98-feed ${editing ? "is-editing" : ""}`} aria-label="CC98帖子列表">
          {selectedBoard || activeNavigationTab === "new" || activeNavigationTab === "followed" ? (
            <header className="cc98-feed-heading">
              {selectedBoard ? (
                <button type="button" onClick={() => setSelectedBoard(null)}>‹ 全部版面</button>
              ) : null}
              <div>
                <strong>{selectedBoard ?? (activeNavigationTab === "new" ? "新帖" : "关注的版面")}</strong>
                <span>{selectedBoard ? "本版面当前可见帖子" : activeNavigationTab === "new" ? "按发布时间排列" : "可在版面页调整关注"}</span>
              </div>
              <b>{feedPosts.length} 帖</b>
            </header>
          ) : null}
          {feedPosts.length ? feedPosts.map((post) => {
            const isQuestPost = QUEST_POST_IDS.has(post.id);
            const linksToChapterFourStudy = chapterFourCc98.visible && post.id === CHAPTER_FOUR_STUDY_LEGACY_POST_ID;
            const isEditablePost = editing;
            return (
            <article
              key={post.id}
              className={`cc98-post ${isQuestPost ? "is-quest-post" : ""} ${linksToChapterFourStudy ? "is-study-entry" : ""}`.trim()}
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
              {linksToChapterFourStudy && !isEditablePost ? (
                <span className="cc98-study-entry-badge">
                  {chapterFourCc98.imported ? "已导入自习群" : "可导入自习群"}
                </span>
              ) : null}
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
          }) : <p className="cc98-empty">这个版面暂时没有可显示的帖子。</p>}
        </main>
      )}

      <nav className="cc98-bottom-nav" aria-label="CC98主导航">
        {BOTTOM_TABS.map((tab) => (
          <button
            type="button"
            key={tab.id}
            className={activeNavigationTab === tab.id ? "is-active" : ""}
            aria-current={activeNavigationTab === tab.id ? "page" : undefined}
            onClick={() => selectBottomTab(tab.id)}
          >
            <i aria-hidden="true">{tab.icon}</i><b>{tab.label}</b>
          </button>
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
          ) : openPostIsChapterFourStudy ? (
            <ChapterFourStudyIndexImport imported={chapterFourCc98.imported} />
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
