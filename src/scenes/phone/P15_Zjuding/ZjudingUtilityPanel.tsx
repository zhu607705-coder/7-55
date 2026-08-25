import { useMemo, useState, type ReactNode } from "react";
import {
  PhoneAppBottomNav,
  PhoneAppFeedback,
  PhoneAppHeader,
  PhoneListRow
} from "../../../components/PhoneAppUi";
import type { FeatureAccess, GameState, ItemId, ZjudingPage } from "../../../core/types";
import {
  ZJUDING_APP_REGISTRY,
  isZjudingAppAvailable,
  type ZjudingAppAccessContext,
  type ZjudingAppId,
  type ZjudingUtilityPanelId
} from "./ZjudingAppRegistry";

export type ZjudingBottomTabId = "home" | "contacts" | "workbench" | "messages" | "profile";

interface DepartmentContact {
  id: string;
  label: string;
  phone: string;
}

interface ZjudingUtilityPanelProps {
  panel: ZjudingUtilityPanelId;
  state: GameState;
  access: FeatureAccess;
  identityReadable: boolean;
  studentName: string;
  studentId: string;
  departments: readonly DepartmentContact[];
  onBack: () => void;
  onBottomNavigate: (tab: ZjudingBottomTabId) => void;
  onOpenApp: (appId: ZjudingAppId) => void;
  onOpenPage: (page: ZjudingPage) => void;
  onOpenCampusMap: () => void;
  onOpenCampusCard: () => void;
  onInspectItem: (itemId: ItemId) => void;
}

interface VisitorDraft {
  visitorName: string;
  visitDate: string;
  purpose: string;
}

interface FeedbackDraft {
  category: string;
  content: string;
}

const VISITOR_DRAFT_STORAGE_KEY = "seven-fifty-five:zjuding:visitor-preview-draft:v1";
const FEEDBACK_DRAFT_STORAGE_KEY = "seven-fifty-five:zjuding:feedback-draft:v1";

const EMPTY_VISITOR_DRAFT: VisitorDraft = {
  visitorName: "",
  visitDate: "",
  purpose: "校园参观"
};

const EMPTY_FEEDBACK_DRAFT: FeedbackDraft = {
  category: "功能建议",
  content: ""
};

const PANEL_TITLES: Record<ZjudingUtilityPanelId, string> = {
  smart_classroom: "智云课堂",
  network_account: "网络账户",
  logistics: "后勤服务",
  lost_found: "失物招领",
  visitor_preview: "访客预约预览",
  language_cards: "慧学外语",
  feedback_draft: "意见草稿",
  all_apps: "全部应用",
  contacts: "通讯录",
  messages: "消息",
  profile: "我的"
};

const BOTTOM_TABS: ReadonlyArray<{ id: ZjudingBottomTabId; label: string; icon: string }> = [
  { id: "home", label: "首页", icon: "⌂" },
  { id: "contacts", label: "通讯录", icon: "◉" },
  { id: "workbench", label: "工作台", icon: "▦" },
  { id: "messages", label: "消息", icon: "✦" },
  { id: "profile", label: "我的", icon: "◎" }
];

const COURSE_CARDS = [
  { id: "chemical-engineering", title: "化学工程基础", time: "周一 08:00", room: "北教学区 A-204", note: "课程资料已缓存在本机。" },
  { id: "data-methods", title: "数据方法与 AI4S", time: "周三 13:15", room: "线上课堂", note: "最近一次课件仅供预览。" },
  { id: "laboratory-safety", title: "实验室安全", time: "周五 10:00", room: "东教学区 3-106", note: "安全提醒已读取，不产生签到记录。" }
] as const;

const LANGUAGE_CARDS = [
  { id: "wayfinding", front: "wayfinding", back: "导向；路径识别", example: "Wayfinding signs connect the lobby and classrooms." },
  { id: "reflection", front: "reflection", back: "倒影；反射", example: "The reflection appears below the bridge." },
  { id: "maintenance", front: "maintenance", back: "维修；保养", example: "The maintenance cart is parked by the service door." }
] as const;

const LOST_FOUND_ITEMS: ReadonlyArray<{ id: ItemId; label: string; source: string }> = [
  { id: "itemRecognitionReport", label: "书包物品识别报告", source: "照片·本机识别" },
  { id: "bagNonPersonProof", label: "书包非本人证明", source: "图书馆前台" },
  { id: "seat022Receipt", label: "022 座位小票", source: "基础馆二层南区" },
  { id: "libraryPresenceProof", label: "本人到馆证明", source: "浙大体艺·到馆记录" }
];

function readSessionDraft<T>(key: string, fallback: T): T {
  if (typeof window === "undefined") return fallback;
  try {
    const raw = window.sessionStorage.getItem(key);
    if (!raw) return fallback;
    const value = JSON.parse(raw) as unknown;
    return value && typeof value === "object" ? { ...fallback, ...value } : fallback;
  } catch {
    return fallback;
  }
}

function writeSessionDraft(key: string, value: unknown): boolean {
  if (typeof window === "undefined") return false;
  try {
    window.sessionStorage.setItem(key, JSON.stringify(value));
    return true;
  } catch {
    return false;
  }
}

function clearSessionDraft(key: string): void {
  if (typeof window === "undefined") return;
  try {
    window.sessionStorage.removeItem(key);
  } catch {
    // A blocked session store must not prevent local form cleanup.
  }
}

function activeTabForPanel(panel: ZjudingUtilityPanelId): ZjudingBottomTabId {
  if (panel === "contacts") return "contacts";
  if (panel === "messages") return "messages";
  if (panel === "profile") return "profile";
  return "workbench";
}

function UtilityAppIcon({ symbol, tone, badge }: { symbol: string; tone: string; badge?: string }) {
  return (
    <span className={`zju-pixel-icon tone-${tone}`} aria-hidden="true">
      <i>{symbol}</i>
      {badge ? <b>{badge}</b> : null}
    </span>
  );
}

function UtilityFeedback({ children }: { children: ReactNode }) {
  return <PhoneAppFeedback className="zju-utility-feedback">{children}</PhoneAppFeedback>;
}

export function ZjudingUtilityPanel({
  panel,
  state,
  access,
  identityReadable,
  studentName,
  studentId,
  departments,
  onBack,
  onBottomNavigate,
  onOpenApp,
  onOpenPage,
  onOpenCampusMap,
  onOpenCampusCard,
  onInspectItem
}: ZjudingUtilityPanelProps) {
  const [selectedCourseId, setSelectedCourseId] = useState<string | null>(null);
  const [selectedLanguageCardId, setSelectedLanguageCardId] = useState<string | null>(null);
  const [networkDetailVisible, setNetworkDetailVisible] = useState(false);
  const [visitorDraft, setVisitorDraft] = useState<VisitorDraft>(() => (
    readSessionDraft(VISITOR_DRAFT_STORAGE_KEY, EMPTY_VISITOR_DRAFT)
  ));
  const [visitorFeedback, setVisitorFeedback] = useState("");
  const [visitorPreviewVisible, setVisitorPreviewVisible] = useState(false);
  const [feedbackDraft, setFeedbackDraft] = useState<FeedbackDraft>(() => (
    readSessionDraft(FEEDBACK_DRAFT_STORAGE_KEY, EMPTY_FEEDBACK_DRAFT)
  ));
  const [feedbackStatus, setFeedbackStatus] = useState("");

  const appAccessContext: ZjudingAppAccessContext = {
    identityReadable,
    fullCampusMap: access.fullCampusMap,
    library: access.library
  };
  const activeBottomTab = activeTabForPanel(panel);
  const acquiredLostFoundItems = LOST_FOUND_ITEMS.filter((item) => state.items[item.id]);
  const networkLabel = state.networkMode === "campus_wifi"
    ? "校园网已连接"
    : state.networkMode === "cellular"
      ? "当前使用移动数据"
      : "当前处于离线状态";

  const messages = useMemo(() => {
    const rows: Array<{
      id: string;
      title: string;
      detail: string;
      actionLabel?: string;
      action?: "library" | "campus_map" | "campus_card";
    }> = [
      {
        id: "network",
        title: "校园网状态",
        detail: networkLabel
      }
    ];
    if (identityReadable) {
      rows.push({
        id: "identity",
        title: "校园身份已读取",
        detail: `${studentName}·${studentId}`,
        actionLabel: "查看校园卡",
        action: "campus_card"
      });
    }
    if (state.ui.librarySeatReserved) {
      rows.push({
        id: "reservation",
        title: "图书馆座位预约",
        detail: `已预约 ${state.ui.librarySelectedSeat ?? "022"} 号座位`,
        actionLabel: "查看图书馆",
        action: "library"
      });
    } else if (access.library) {
      rows.push({
        id: "library-open",
        title: "图书馆服务已开放",
        detail: "当前可用功能以图书馆首页实际状态为准。",
        actionLabel: "打开图书馆",
        action: "library"
      });
    }
    if (state.qizhenLake.active && state.qizhenLake.phase === "location_search") {
      rows.push({
        id: "qizhen-location",
        title: "地点记录待核验",
        detail: `校园地图已接入 ${state.qizhenLake.mapClueIds.length}/3 条公开线索。`,
        actionLabel: "打开地图",
        action: "campus_map"
      });
    }
    if (state.chapterThreeInterlude.recoveryOpened && !state.chapterThreeInterlude.completed) {
      rows.push({
        id: "interlude-network",
        title: "未同步记录",
        detail: state.chapterThreeInterlude.networkRecordRead
          ? "设备接入记录已保存。"
          : "设备接入记录仍待核验。"
      });
    }
    return rows;
  }, [
    access.library,
    identityReadable,
    networkLabel,
    state.chapterThreeInterlude.completed,
    state.chapterThreeInterlude.networkRecordRead,
    state.chapterThreeInterlude.recoveryOpened,
    state.qizhenLake.active,
    state.qizhenLake.mapClueIds.length,
    state.qizhenLake.phase,
    state.ui.librarySeatReserved,
    state.ui.librarySelectedSeat,
    studentId,
    studentName
  ]);

  function saveVisitorDraft() {
    if (!visitorDraft.visitorName.trim() || !visitorDraft.visitDate.trim()) {
      setVisitorFeedback("请填写访客姓名和到访日期，再生成本机预览。");
      setVisitorPreviewVisible(false);
      return;
    }
    const stored = writeSessionDraft(VISITOR_DRAFT_STORAGE_KEY, visitorDraft);
    setVisitorPreviewVisible(true);
    setVisitorFeedback(stored
      ? "预览草稿已保存到本次会话，没有提交到校务系统。"
      : "已生成本机预览，当前浏览器不允许保存会话草稿。");
  }

  function clearVisitorDraft() {
    clearSessionDraft(VISITOR_DRAFT_STORAGE_KEY);
    setVisitorDraft(EMPTY_VISITOR_DRAFT);
    setVisitorPreviewVisible(false);
    setVisitorFeedback("访客预览草稿已清空。");
  }

  function saveFeedbackDraft() {
    if (!feedbackDraft.content.trim()) {
      setFeedbackStatus("请先填写意见内容。");
      return;
    }
    const stored = writeSessionDraft(FEEDBACK_DRAFT_STORAGE_KEY, feedbackDraft);
    setFeedbackStatus(stored
      ? "意见已保存为本次会话草稿，尚未正式提交。"
      : "已保留在当前页面，当前浏览器不允许保存会话草稿。");
  }

  function clearFeedbackDraft() {
    clearSessionDraft(FEEDBACK_DRAFT_STORAGE_KEY);
    setFeedbackDraft(EMPTY_FEEDBACK_DRAFT);
    setFeedbackStatus("意见草稿已清空。");
  }

  function runMessageAction(action: "library" | "campus_map" | "campus_card") {
    if (action === "library") {
      onOpenPage("library");
    } else if (action === "campus_map") {
      onOpenCampusMap();
    } else {
      onOpenCampusCard();
    }
  }

  let body: ReactNode;

  if (panel === "smart_classroom") {
    body = (
      <>
        <section className="zju-utility-summary">
          <small>本机课程预览</small>
          <strong>{COURSE_CARDS.length} 门课程</strong>
          <p>查看课程日程和缓存说明，不产生签到或成绩记录。</p>
        </section>
        <section className="zju-utility-list" aria-label="课程列表">
          {COURSE_CARDS.map((course) => {
            const selected = selectedCourseId === course.id;
            return (
              <article key={course.id} className={selected ? "is-selected" : ""}>
                <div><small>{course.time}</small><strong>{course.title}</strong><span>{course.room}</span></div>
                <button type="button" onClick={() => setSelectedCourseId(selected ? null : course.id)}>
                  {selected ? "收起" : "查看"}
                </button>
                {selected ? <p>{course.note}</p> : null}
              </article>
            );
          })}
        </section>
      </>
    );
  } else if (panel === "network_account") {
    body = (
      <>
        <section className="zju-utility-summary is-network">
          <small>当前连接</small>
          <strong>{networkLabel}</strong>
          <p>页面只读取本机网络状态，不扣费、不充值、不生成账单。</p>
        </section>
        <section className="zju-utility-card-grid">
          <article><small>校园网</small><strong>{state.networkMode === "campus_wifi" ? "可用" : "未连接"}</strong><span>浙大钉与 CC98 需要校园网。</span></article>
          <article><small>移动数据</small><strong>{state.networkMode === "cellular" ? "使用中" : "备用"}</strong><span>浙大体艺的网络规则与浙大钉不同。</span></article>
        </section>
        <button type="button" className="zju-utility-primary" onClick={() => setNetworkDetailVisible((value) => !value)}>
          {networkDetailVisible ? "收起连接说明" : "查看连接说明"}
        </button>
        {networkDetailVisible ? (
          <UtilityFeedback>如需切换网络，请返回手机控制中心。本页不会自动修改网络模式。</UtilityFeedback>
        ) : null}
      </>
    );
  } else if (panel === "logistics") {
    body = (
      <>
        <section className="zju-utility-summary">
          <small>校园服务聚合</small>
          <strong>后勤状态台</strong>
          <p>所有条目只读取已开放的本地功能，未提交任何报修工单。</p>
        </section>
        <section className="zju-utility-service-list">
          <article><div><strong>网络服务</strong><span>{networkLabel}</span></div><button type="button" onClick={() => onOpenApp("network_account")}>查看</button></article>
          <article><div><strong>图书馆服务</strong><span>{access.library ? "已开放" : "当前阶段未开放"}</span></div>{access.library ? <button type="button" onClick={() => onOpenPage("library")}>进入</button> : <em>未开放</em>}</article>
          <article><div><strong>校园导航</strong><span>{access.fullCampusMap ? "已开放" : "当前阶段未开放"}</span></div>{access.fullCampusMap ? <button type="button" onClick={onOpenCampusMap}>进入</button> : <em>未开放</em>}</article>
          <article><div><strong>服务联络</strong><span>{access.departmentDirectory ? "部门黄页可用" : "公共联络表可查看"}</span></div><button type="button" onClick={() => onBottomNavigate("contacts")}>查看</button></article>
        </section>
      </>
    );
  } else if (panel === "lost_found") {
    body = (
      <>
        <section className="zju-utility-summary">
          <small>仅显示已公开记录</small>
          <strong>{acquiredLostFoundItems.length} 份本机档案</strong>
          <p>查看档案不会生成证明、改变物品或推进图书馆进度。</p>
        </section>
        {acquiredLostFoundItems.length ? (
          <section className="zju-utility-list" aria-label="已公开失物档案">
            {acquiredLostFoundItems.map((item) => (
              <article key={item.id}>
                <div><small>{item.source}</small><strong>{item.label}</strong><span>本机已取得</span></div>
                <button type="button" onClick={() => onInspectItem(item.id)}>查看</button>
              </article>
            ))}
          </section>
        ) : (
          <section className="zju-utility-empty"><strong>暂无已公开档案</strong><p>后续只会在相关记录真正取得后显示。</p></section>
        )}
      </>
    );
  } else if (panel === "visitor_preview") {
    body = (
      <>
        <section className="zju-utility-summary">
          <small>本机预览工具</small>
          <strong>访客信息草稿</strong>
          <p>草稿仅保存在当前浏览器会话，不代表正式入校申请。</p>
        </section>
        <section className="zju-utility-form" aria-label="访客预览草稿">
          <label><span>访客姓名</span><input value={visitorDraft.visitorName} onChange={(event) => setVisitorDraft((draft) => ({ ...draft, visitorName: event.target.value.slice(0, 24) }))} placeholder="用于本机预览" /></label>
          <label><span>到访日期</span><input value={visitorDraft.visitDate} onChange={(event) => setVisitorDraft((draft) => ({ ...draft, visitDate: event.target.value.slice(0, 24) }))} placeholder="例如：08月24日" /></label>
          <label><span>到访用途</span><select value={visitorDraft.purpose} onChange={(event) => setVisitorDraft((draft) => ({ ...draft, purpose: event.target.value }))}><option>校园参观</option><option>学术交流</option><option>亲友来访</option></select></label>
          <div className="zju-utility-form-actions"><button type="button" onClick={clearVisitorDraft}>清空</button><button type="button" className="primary" onClick={saveVisitorDraft}>保存预览草稿</button></div>
        </section>
        {visitorPreviewVisible ? <section className="zju-utility-preview"><small>未提交·本机预览</small><strong>{visitorDraft.visitorName}</strong><p>{visitorDraft.visitDate}·{visitorDraft.purpose}</p></section> : null}
        {visitorFeedback ? <UtilityFeedback>{visitorFeedback}</UtilityFeedback> : null}
      </>
    );
  } else if (panel === "language_cards") {
    body = (
      <>
        <section className="zju-utility-summary">
          <small>本地微卡片</small>
          <strong>校园场景外语</strong>
          <p>点击卡片查看中文释义与场景例句。</p>
        </section>
        <section className="zju-language-grid" aria-label="外语卡片">
          {LANGUAGE_CARDS.map((card) => {
            const selected = selectedLanguageCardId === card.id;
            return (
              <button key={card.id} type="button" className={selected ? "is-revealed" : ""} aria-pressed={selected} onClick={() => setSelectedLanguageCardId(selected ? null : card.id)}>
                <small>{selected ? card.back : "点击查看释义"}</small>
                <strong>{card.front}</strong>
                <span>{selected ? card.example : "EN / ZH"}</span>
              </button>
            );
          })}
        </section>
      </>
    );
  } else if (panel === "feedback_draft") {
    body = (
      <>
        <section className="zju-utility-summary">
          <small>会话级本地草稿</small>
          <strong>意见箱</strong>
          <p>本 Demo 只保存草稿，不会将内容发送给真实部门或网络服务。</p>
        </section>
        <section className="zju-utility-form" aria-label="意见草稿">
          <label><span>分类</span><select value={feedbackDraft.category} onChange={(event) => setFeedbackDraft((draft) => ({ ...draft, category: event.target.value }))}><option>功能建议</option><option>交互问题</option><option>内容校对</option></select></label>
          <label><span>草稿内容</span><textarea value={feedbackDraft.content} onChange={(event) => setFeedbackDraft((draft) => ({ ...draft, content: event.target.value.slice(0, 500) }))} placeholder="写下希望保留的意见草稿" /><small>{feedbackDraft.content.length}/500</small></label>
          <div className="zju-utility-form-actions"><button type="button" onClick={clearFeedbackDraft}>清空</button><button type="button" className="primary" onClick={saveFeedbackDraft}>保存本机草稿</button></div>
        </section>
        {feedbackStatus ? <UtilityFeedback>{feedbackStatus}</UtilityFeedback> : null}
      </>
    );
  } else if (panel === "all_apps") {
    const categories: ReadonlyArray<{ id: ZjudingAppDefinitionCategory; label: string }> = [
      { id: "learning", label: "学习" },
      { id: "campus", label: "校园" },
      { id: "service", label: "服务" },
      { id: "library", label: "图书馆" }
    ];
    body = (
      <>
        <section className="zju-utility-summary">
          <small>统一应用目录</small>
          <strong>工作台</strong>
          <p>应用状态与首页、搜索完全一致。未开放项保留原名称与静态图标。</p>
        </section>
        {categories.map((category) => (
          <section className="zju-utility-app-section" key={category.id}>
            <h2>{category.label}</h2>
            <div className="zju-utility-app-grid">
              {ZJUDING_APP_REGISTRY.filter((app) => app.category === category.id && app.id !== "all_apps").map((app) => {
                const available = isZjudingAppAvailable(app, appAccessContext);
                return available ? (
                  <button key={app.id} type="button" onClick={() => onOpenApp(app.id)}>
                    <UtilityAppIcon symbol={app.icon} tone={app.tone} badge={app.badge} />
                    <span>{app.label}</span>
                  </button>
                ) : (
                  <span key={app.id} className="zju-static-app zju-locked-icon-slot" aria-hidden="true">
                    <UtilityAppIcon symbol={app.icon} tone={app.tone} />
                    <span className="zju-locked-label">{app.label}</span>
                  </span>
                );
              })}
            </div>
          </section>
        ))}
      </>
    );
  } else if (panel === "contacts") {
    body = (
      <>
        <section className="zju-utility-summary">
          <small>校园公开联络表</small>
          <strong>{departments.length} 个服务联络点</strong>
          <p>号码来自当前游戏内容，页面不会直接拨号。</p>
        </section>
        <section className="zju-utility-contact-list" aria-label="部门联系方式">
          {departments.map((department) => (
            <article key={department.id}><span aria-hidden="true">☎</span><div><strong>{department.label}</strong><small>{department.phone}</small></div></article>
          ))}
        </section>
        {access.departmentDirectory ? <button type="button" className="zju-utility-primary" onClick={() => onOpenPage("directory")}>打开部门黄页</button> : <UtilityFeedback>部门黄页会在剧情恢复校园身份后开放。</UtilityFeedback>}
      </>
    );
  } else if (panel === "messages") {
    body = (
      <>
        <section className="zju-utility-summary">
          <small>当前已公开状态</small>
          <strong>{messages.length} 条消息</strong>
          <p>只聚合已发生的网络、身份、预约和记录状态。</p>
        </section>
        <section className="zju-utility-message-list" aria-label="消息列表">
          {messages.map((message) => message.action && message.actionLabel ? (
            <PhoneListRow
              key={message.id}
              title={message.title}
              description={message.detail}
              leading="✦"
              trailing={message.actionLabel}
              onClick={() => runMessageAction(message.action!)}
            />
          ) : (
            <article key={message.id} className="zju-utility-message-static">
              <span className="phone-list-row__leading" aria-hidden="true">✦</span>
              <span className="phone-list-row__copy">
                <strong>{message.title}</strong>
                <small>{message.detail}</small>
              </span>
              <span className="phone-list-row__trailing">已读</span>
            </article>
          ))}
        </section>
      </>
    );
  } else {
    body = (
      <>
        <section className="zju-utility-profile-card">
          <span aria-hidden="true">{identityReadable ? "ZJU" : "?"}</span>
          <div><small>校园身份</small><strong>{identityReadable ? studentName : "身份未读取"}</strong><p>{identityReadable ? studentId : "取得电子校园卡后显示"}</p></div>
        </section>
        <section className="zju-utility-service-list">
          <article><div><strong>当前网络</strong><span>{networkLabel}</span></div><button type="button" onClick={() => onOpenApp("network_account")}>详情</button></article>
          <article><div><strong>电子校园卡</strong><span>{identityReadable ? "已读取" : "未读取"}</span></div>{identityReadable ? <button type="button" onClick={onOpenCampusCard}>查看</button> : <em>未开放</em>}</article>
          <article><div><strong>图书馆预约</strong><span>{state.ui.librarySeatReserved ? `座位 ${state.ui.librarySelectedSeat ?? "022"}` : "当前无预约"}</span></div>{access.library ? <button type="button" onClick={() => onOpenPage("library")}>查看</button> : <em>未开放</em>}</article>
          <article><div><strong>账号安全</strong><span>本 Demo 不发送账号请求</span></div><em>只读</em></article>
        </section>
      </>
    );
  }

  return (
    <section className="app-screen zju-native-page zju-utility-page" aria-label={PANEL_TITLES[panel]}>
      <PhoneAppHeader
        className="zju-native-header"
        title={PANEL_TITLES[panel]}
        navigation={{ kind: "back", label: `返回，离开${PANEL_TITLES[panel]}`, onClick: onBack }}
        end={<span className="zju-native-more zju-locked-control-icon" aria-hidden="true">•••</span>}
      />
      <main className="zju-utility-content">{body}</main>
      <PhoneAppBottomNav
        className="zju-native-bottom-nav"
        label="浙大钉导航"
        items={BOTTOM_TABS.map((tab) => ({ id: tab.id, label: tab.label, icon: tab.icon }))}
        activeId={activeBottomTab}
        onSelect={(tab) => onBottomNavigate(tab as ZjudingBottomTabId)}
      />
    </section>
  );
}

type ZjudingAppDefinitionCategory = "learning" | "campus" | "service" | "library";
