import { useCallback, useEffect, useRef, useState } from "react";
import {
  type Chapter,
  type Idea,
  type User,
  type updateSchema,
} from "@755/contracts";
import { Dialog } from "../components/Dialog";
import { Icon } from "../components/Icon";
import { useChapters } from "../features/chapters/useChapters";
import {
  api,
  ApiError,
  messageOf,
  type IdeaList,
  type Stats,
} from "../lib/api";
import {
  ComposeForm,
  ProfileForm,
  PermissionForm,
  OperatorForm,
} from "../features/community/Forms";
import {
  CHANNELS,
  STATUSES,
  CATEGORIES,
  date,
  emptyDraft,
  entryDraft,
  saveDraft,
  clearDraft,
  saveIntent,
  takeIntent,
  errorMessages,
  type Channel,
  type Status,
  type Intent,
  type Draft,
} from "../features/community/model";

type Modal = "auth" | "compose" | "profile" | "detail" | null;
type AuthConfig = {
  provider: "authing";
  configured: boolean;
  gameUrl: string | null;
};
type Update = ReturnType<typeof updateSchema.parse>;
const currentIdea = () => new URLSearchParams(location.search).get("idea");
const count = (value: number) => new Intl.NumberFormat("zh-CN").format(value);

export function App() {
  const { state: chapters, retry: retryChapters } = useChapters();
  const chapterItems = chapters.status === "ready" ? chapters.items : [];
  const chapterName = (id: string) =>
    chapterItems.find((chapter) => chapter.id === id)?.title ?? "章节讨论";
  const [user, setUser] = useState<User | null>(null),
    [sessionState, setSessionState] = useState<"loading" | "ready" | "error">(
      "loading",
    );
  const [config, setConfig] = useState<AuthConfig | null>(null);
  const [authState, setAuthState] = useState<"loading" | "ready" | "error">(
    "loading",
  );
  const [modal, setModal] = useState<Modal>(
    currentIdea()
      ? "detail"
      : new URLSearchParams(location.search).has("entry")
        ? "compose"
        : null,
  );
  const [draft, setDraft] = useState<Draft>(entryDraft),
    [intent, setIntent] = useState<Intent>({ kind: "none" });
  const [mode, setMode] = useState<"public" | "mine" | "operator">("public");
  const [channel, setChannel] = useState<Channel | "">(""),
    [chapterId, setChapterId] = useState(""),
    [status, setStatus] = useState<Status | "">("");
  const [sort, setSort] = useState<"new" | "likes" | "rating">("new"),
    [search, setSearch] = useState(""),
    [query, setQuery] = useState(""),
    [page, setPage] = useState(1);
  const [feed, setFeed] = useState<IdeaList | null>(null),
    [feedLoading, setFeedLoading] = useState(true),
    [feedError, setFeedError] = useState("");
  const [stats, setStats] = useState<Stats | null>(null),
    [rankings, setRankings] = useState<Idea[] | null>(null),
    [rankSort, setRankSort] = useState<"likes" | "rating">("likes");
  const [rankState, setRankState] = useState<"loading" | "ready" | "error">(
    "loading",
  );
  const [detailId, setDetailId] = useState<string | null>(currentIdea),
    [detail, setDetail] = useState<Idea | null>(null),
    [detailError, setDetailError] = useState(""),
    [detailLoading, setDetailLoading] = useState(false),
    [revealed, setRevealed] = useState(false);
  const [updates, setUpdates] = useState<Update[] | null>(null),
    [updatesError, setUpdatesError] = useState("");
  const [revision, setRevision] = useState(0),
    [pending, setPending] = useState<string | null>(null),
    [accountOpen, setAccountOpen] = useState(false),
    [confirmWithdraw, setConfirmWithdraw] = useState(false),
    [shareUrl, setShareUrl] = useState("");
  const [notice, setNotice] = useState<{ text: string; error: boolean } | null>(
    null,
  );
  const resumed = useRef(false),
    requestGeneration = useRef(0),
    mutating = useRef(false);
  const sessionUserId = useRef<string | null>(null);
  const sessionChannel = useRef<BroadcastChannel | null>(null);
  const detailLoadKey = useRef("");
  const feedLoadKey = useRef("");
  const refresh = () => setRevision((value) => value + 1);
  const notify = (text: string, error = false) => setNotice({ text, error });
  const loadSession = useCallback(async () => {
    const generation = ++requestGeneration.current;
    setSessionState("loading");
    setAuthState("loading");
    const results = await Promise.allSettled([
      api<{ user: User | null }>("/session"),
      api<AuthConfig>("/auth/config"),
    ]);
    if (generation !== requestGeneration.current) return;
    const [session, auth] = results;
    if (session.status === "fulfilled") {
      const nextId = session.value.user?.id ?? null;
      if (nextId !== sessionUserId.current) {
        sessionUserId.current = nextId;
        sessionChannel.current?.postMessage("changed");
        setMode("public");
        setAccountOpen(false);
        setFeed(null);
        setDetail(null);
        setUpdates(null);
        setRevealed(false);
        setModal((current) => current === "profile" || current === "auth" ? null : current);
      }
      setUser(session.value.user);
      setSessionState("ready");
    } else setSessionState("error");
    if (auth.status === "fulfilled") {
      setConfig(auth.value);
      setAuthState("ready");
    } else setAuthState("error");
  }, []);
  useEffect(() => {
    void loadSession();
  }, [loadSession]);
  useEffect(() => {
    let timer: number | undefined;
    const resume = () => {
      if (document.hidden || pending || mutating.current || timer !== undefined) return;
      timer = window.setTimeout(() => {
        timer = undefined;
        if (!document.hidden && !mutating.current) void loadSession();
      }, 0);
    };
    window.addEventListener("focus", resume);
    document.addEventListener("visibilitychange", resume);
    // Notifications carry no identity. Every receiver checks the server again.
    // Older browsers retain the focus/visibility fallback above.
    let channel: BroadcastChannel | null = null;
    try {
      if (typeof BroadcastChannel !== "undefined") {
        channel = new BroadcastChannel("755-player-session");
        sessionChannel.current = channel;
        channel.onmessage = (event) => {
          if (event.data === "changed" && !pending && !mutating.current) void loadSession();
        };
      }
    } catch { /* Some private browser policies disable cross-tab channels. */ }
    return () => {
      if (timer !== undefined) window.clearTimeout(timer);
      window.removeEventListener("focus", resume);
      document.removeEventListener("visibilitychange", resume);
      channel?.close();
      if (sessionChannel.current === channel) sessionChannel.current = null;
    };
  }, [loadSession, pending]);
  useEffect(() => {
    saveDraft(draft);
  }, [draft]);
  useEffect(() => {
    const timer = setTimeout(() => {
      setQuery(search.trim());
      setPage(1);
    }, 300);
    return () => clearTimeout(timer);
  }, [search]);
  useEffect(() => {
    if (sessionState !== "ready" || resumed.current) return;
    resumed.current = true;
    const params = new URLSearchParams(location.search),
      error = params.get("authError");
    const requestedLogin = params.get("account") === "login";
    if (requestedLogin) {
      params.delete("account");
      history.replaceState({}, "", `/${params.size ? "?" + params : ""}${location.hash}`);
    }
    const next = takeIntent();
    if (error) {
      notify(errorMessages[error] ?? errorMessages.failed!, true);
      params.delete("authError");
      history.replaceState(
        {},
        "",
        `/${params.size ? "?" + params : ""}${location.hash}`,
      );
      return;
    }
    if (requestedLogin && !user) setModal("auth");
    if (user && next) {
      if (next.kind === "compose") setModal("compose");
      else if (next.kind === "profile") setModal("profile");
      else if (next.kind === "mine") {
        setMode("mine");
        setPage(1);
      } else if (next.kind === "like" || next.kind === "rating") {
        void reactTo(next);
      }
    }
  }, [sessionState, user]);
  useEffect(() => {
    let active = true;
    const key = JSON.stringify([
      channel,
      chapterId,
      status,
      query,
      page,
      sort,
      mode,
      user?.id,
      user?.progressOrder,
      user?.isOperator,
    ]);
    if (feedLoadKey.current !== key || !feed) setFeedLoading(true);
    feedLoadKey.current = key;
    setFeedError("");
    const params = new URLSearchParams({ sort, page: String(page) });
    if (channel) params.set("channel", channel);
    if (chapterId) params.set("chapterId", chapterId);
    if (status) params.set("status", status);
    if (query) params.set("q", query);
    if (mode === "mine" && user) params.set("mine", "true");
    const path =
      mode === "operator" && user?.isOperator ? "/operator/ideas" : "/ideas";
    void api<IdeaList>(`${path}?${params}`)
      .then((result) => {
        if (active) setFeed(result);
      })
      .catch((error) => {
        if (active) {
          setFeedError(messageOf(error));
          if (error instanceof ApiError && error.status === 401) {
            setUser(null);
            setMode("public");
          }
        }
      })
      .finally(() => {
        if (active) setFeedLoading(false);
      });
    return () => {
      active = false;
    };
  }, [channel, chapterId, status, query, page, sort, mode, user, revision]);
  useEffect(() => {
    let active = true;
    void api<Stats>("/stats")
      .then((result) => {
        if (active) setStats(result);
      })
      .catch(() => {
        if (active) setStats(null);
      });
    setRankings(null);
    setRankState("loading");
    void api<IdeaList>(`/ideas?sort=${rankSort}&channel=story`)
      .then((result) => {
        if (active) {
          setRankings(result.items.slice(0, 3));
          setRankState("ready");
        }
      })
      .catch(() => {
        if (active) {
          setRankings(null);
          setRankState("error");
        }
      });
    return () => {
      active = false;
    };
  }, [revision, user, rankSort]);
  useEffect(() => {
    if (!detailId) {
      detailLoadKey.current = "";
      return;
    }
    let active = true;
    const key = JSON.stringify([
      detailId,
      revealed,
      user?.id,
      user?.progressOrder,
      user?.isOperator,
    ]);
    if (detailLoadKey.current !== key) {
      setDetailLoading(true);
      setUpdates(null);
    }
    detailLoadKey.current = key;
    setDetailError("");
    setUpdatesError("");
    const suffix = revealed ? "?reveal=true" : "";
    void api<{ idea: Idea }>(`/ideas/${detailId}${suffix}`)
      .then((result) => {
        if (active) setDetail(result.idea);
      })
      .catch((error) => {
        if (active) {
          setDetail(null);
          setDetailError(messageOf(error));
        }
      })
      .finally(() => {
        if (active) setDetailLoading(false);
      });
    void api<{ items: Update[] }>(`/ideas/${detailId}/updates${suffix}`)
      .then((result) => {
        if (active) setUpdates(result.items);
      })
      .catch((error) => {
        if (active) {
          setUpdates(null);
          setUpdatesError(messageOf(error));
        }
      });
    return () => {
      active = false;
    };
  }, [detailId, revealed, user, revision]);
  useEffect(() => {
    const pop = () => {
      setDetailId(currentIdea());
      setModal(currentIdea() ? "detail" : null);
      setRevealed(false);
    };
    window.addEventListener("popstate", pop);
    return () => window.removeEventListener("popstate", pop);
  }, []);
  useEffect(() => {
    if (!notice) return;
    const timer = setTimeout(() => setNotice(null), 8500);
    return () => clearTimeout(timer);
  }, [notice]);
  useEffect(() => {
    if (!accountOpen) return;
    const close = (event: MouseEvent) => {
      if (!(event.target as HTMLElement).closest(".header-account"))
        setAccountOpen(false);
    };
    document.addEventListener("click", close);
    return () => document.removeEventListener("click", close);
  }, [accountOpen]);

  function openIdea(id: string) {
    setDetailId(id);
    setDetail(null);
    setDetailLoading(true);
    setUpdates(null);
    setRevealed(false);
    setConfirmWithdraw(false);
    setShareUrl("");
    setModal("detail");
    const url = new URL(location.href);
    url.searchParams.delete("entry");
    url.searchParams.set("idea", id);
    history.pushState({}, "", url);
  }
  function closeModal() {
    if (pending) return;
    if (modal === "detail") {
      setDetailId(null);
      const url = new URL(location.href);
      url.searchParams.delete("idea");
      history.replaceState({}, "", url);
    }
    setModal(null);
  }
  function authenticate(next: Intent = { kind: "none" }) {
    setIntent(next);
    setModal("auth");
    setAccountOpen(false);
  }
  async function startLogin() {
    setPending("login");
    saveDraft(draft);
    saveIntent(intent);
    try {
      const result = await api<{ url: string }>("/auth/start", {
        method: "POST",
        body: JSON.stringify({
          returnTo: detailId ? `/?idea=${detailId}` : "/",
        }),
      });
      location.assign(result.url);
    } catch (error) {
      notify(messageOf(error), true);
      setPending(null);
    }
  }
  function compose(nextChannel: Channel = channel || "story") {
    setDraft((value) => ({
      ...value,
      channel: nextChannel,
      category: nextChannel === "feedback" ? "experience" : value.category,
      chapterId: chapterId || value.chapterId,
    }));
    setModal("compose");
  }
  async function reactTo(action: Extract<Intent, { id: string }>) {
    if (mutating.current) return;
    if (!user) {
      authenticate(action);
      return;
    }
    mutating.current = true;
    setPending(action.id);
    try {
      await api(`/ideas/${action.id}/${action.kind}`, {
        method: "PUT",
        body: JSON.stringify(
          action.kind === "like"
            ? { liked: action.value }
            : { score: action.value },
        ),
      });
      refresh();
      notify(
        action.kind === "like"
          ? action.value
            ? "已记下你的支持。"
            : "已取消支持。"
          : action.value === null
            ? "评分已撤回。"
            : `已记下你的 ${action.value} 星评分。`,
      );
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) {
        setUser(null);
        authenticate(action);
      } else notify(messageOf(error), true);
    } finally {
      mutating.current = false;
      setPending(null);
    }
  }
  async function publish() {
    if (!draft.accepted) throw new Error("请先确认投稿的公开范围。");
    if (!draft.body.trim()) throw new Error("先写投稿吧。");
    if (!user) {
      authenticate({ kind: "compose" });
      return;
    }
    if (!chapterItems.some((chapter) => chapter.id === draft.chapterId))
      throw new Error("请选择关联章节。");
    const { accepted, ...input } = draft;
    setPending("publish");
    try {
      const result = await api<{ idea: Idea }>("/ideas", {
        method: "POST",
        body: JSON.stringify({
          ...input,
          title:
            input.title.trim() ||
            Array.from(input.body.trim()).slice(0, 40).join(""),
        }),
      });
      clearDraft();
      setDraft({ ...emptyDraft });
      setMode("mine");
      setChannel("");
      setChapterId("");
      setStatus("");
      setSearch("");
      setQuery("");
      setSort("new");
      setPage(1);
      refresh();
      openIdea(result.idea.id);
      notify("投稿已收录。后续进展会更新在这张卡片下方。");
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) {
        setUser(null);
        authenticate({ kind: "compose" });
        notify("登录已过期，草稿已保留。", true);
      } else throw error;
    } finally {
      setPending(null);
    }
  }
  async function logout() {
    setPending("logout");
    try {
      const result = await api<{ ok: true; redirectUrl: string | null }>(
        "/auth/logout",
        { method: "POST", body: "{}" },
      );
      requestGeneration.current++;
      sessionUserId.current = null;
      sessionChannel.current?.postMessage("changed");
      setUser(null);
      setMode("public");
      setAccountOpen(false);
      setModal(null);
      takeIntent();
      clearDraft();
      setDraft({ ...emptyDraft });
      refresh();
      if (result.redirectUrl) location.assign(result.redirectUrl);
      else notify("已退出登录。");
    } catch (error) {
      notify(messageOf(error), true);
    } finally {
      setPending(null);
    }
  }
  async function withdraw() {
    if (!detail) return;
    setPending("withdraw");
    try {
      await api(`/ideas/${detail.id}`, { method: "DELETE", body: "{}" });
      setPending(null);
      closeDetail();
      refresh();
      notify("投稿已撤回，其他玩家无法再查看。");
    } catch (error) {
      notify(messageOf(error), true);
    } finally {
      setPending(null);
    }
  }
  function closeDetail() {
    const url = new URL(location.href);
    url.searchParams.delete("idea");
    history.replaceState({}, "", url);
    setDetailId(null);
    setModal(null);
  }
  async function share() {
    if (!detail) return;
    const url = `${location.origin}/?idea=${detail.id}`;
    setShareUrl(url);
    try {
      await navigator.clipboard.writeText(url);
      notify("链接已复制。");
    } catch {
      /* The visible field supports manual copying. */
    }
  }
  function clearFilters() {
    setMode("public");
    setChannel("");
    setChapterId("");
    setStatus("");
    setSearch("");
    setQuery("");
    setPage(1);
  }
  const inlineNotice = notice && (
    <div
      className={`inline-notice ${notice.error ? "error" : ""}`}
      role={notice.error ? "alert" : "status"}
    >
      {notice.text}
    </div>
  );

  return (
    <>
      <a className="skip-link" href="#board">
        跳到共创广场
      </a>
      <header className="site-header">
        <div className="header-inner">
          <a href="/" className="brand" aria-label="7:55 共创平台首页">
            <span className="brand-clock">
              7<span>:</span>55
            </span>
            <span className="brand-divider" />
            <span className="brand-title">
              共创平台<small>7:55 COMMUNITY</small>
            </span>
          </a>
          <nav className="main-nav" aria-label="主导航">
            <a className="active" href="#board">
              <Icon name="note" size={14} /> 共创广场
            </a>
            <a href="#ranking">
              <Icon name="flag" size={14} /> 人气榜
            </a>
            {config?.gameUrl && (
              <a
                href={config.gameUrl}
                target="_blank"
                rel="noopener noreferrer"
              >
                试玩游戏 ↗
              </a>
            )}
          </nav>
          <div className="header-account">
            {sessionState === "loading" ? (
              <span className="session-label">正在连接…</span>
            ) : sessionState === "error" ? (
              <button
                className="button button-outline light"
                onClick={() => void loadSession()}
              >
                重连账号
              </button>
            ) : user ? (
              <>
                <button
                  className="account-button"
                  aria-expanded={accountOpen}
                  aria-controls="account-menu"
                  onClick={() => setAccountOpen(!accountOpen)}
                >
                  <span className="avatar small">
                    {user.nickname.slice(0, 1)}
                  </span>
                  <span className="nickname">{user.nickname}</span> ▾
                </button>
                {accountOpen && (
                  <div className="account-menu pixel-panel" id="account-menu">
                    <strong>{user.nickname}</strong>
                    <small>我的账号</small>
                    <button
                      onClick={() => {
                        clearFilters();
                        setMode("mine");
                        setPage(1);
                        setAccountOpen(false);
                        document.getElementById("board")?.scrollIntoView();
                      }}
                    >
                      我的投稿
                    </button>
                    <button
                      onClick={() => {
                        setModal("profile");
                        setAccountOpen(false);
                      }}
                    >
                      昵称与阅读进度
                    </button>
                    {user.isOperator && (
                      <button
                        onClick={() => {
                          clearFilters();
                          setMode("operator");
                          setAccountOpen(false);
                          document.getElementById("board")?.scrollIntoView();
                        }}
                      >
                        运营工作台
                      </button>
                    )}
                    <button
                      disabled={Boolean(pending)}
                      onClick={() => void logout()}
                    >
                      退出登录
                    </button>
                  </div>
                )}
              </>
            ) : (
              <button
                className="button button-yellow login-button"
                onClick={() => authenticate()}
              >
                <Icon name="user" size={14} /> 登录 / 注册
              </button>
            )}
          </div>
        </div>
      </header>
      <main>
        <section className="hero" aria-labelledby="hero-title">
          <img
            className="hero-landscape"
            src="/art/campus-night.png"
            alt="《7:55》像素校园夜景，湖畔灯光亮起。"
          />
          <div className="hero-shade" />
          <div className="hero-content">
            <h1 id="hero-title">
              把校园小事，
              <br />
              <span>做进游戏。</span>
            </h1>
            <p>
              分享经历，反馈卡点。
              <br />
              在原帖查看回复和制作进度。
            </p>
            <button
              className="button button-yellow hero-cta"
              onClick={() => compose("story")}
            >
              <Icon name="plus" size={16} /> 写投稿{" "}
              <Icon name="arrow" size={16} />
            </button>
            {config?.gameUrl && (
              <a className="hero-game-link" href={config.gameUrl}>试玩游戏 ↗</a>
            )}
          </div>
          <div className="scene-caption">
            <span>
              <span className="scene-dot" /> 浙大校园 · 7:55
            </span>
            <span>19:55</span>
          </div>
        </section>
        <div className="world-status">
          <div className="world-status-inner">
            <span className="world-intro">
              <Icon name="spark" size={16} />{" "}
              校园公告栏
            </span>
            <div className="stats">
              <span>
                <strong>{stats ? count(stats.ideaCount) : "—"}</strong>{" "}
                篇投稿
              </span>
              <span>
                <strong>{stats ? count(stats.memberCount) : "—"}</strong>{" "}
                位玩家
              </span>
              <span>
                <strong>{stats ? count(stats.likeCount) : "—"}</strong> 个赞
              </span>
            </div>
          </div>
        </div>
        <section className="entry-strip" aria-label="参与方式">
          {(
            [
              ["chapter", "本章说", "聊剧情，注意剧透"],
              ["feedback", "反馈卡点", "描述问题和设备"],
              ["story", "分享经历", "经历或玩法点子"],
            ] as const
          ).map(([key, title, copy]) => (
            <button
              key={key}
              className={`entry-card entry-${key}`}
              onClick={() => compose(key)}
            >
              <span>
                <strong>{title}</strong>
                <small>{copy}</small>
              </span>
              <span aria-hidden="true">↗</span>
            </button>
          ))}
        </section>
        <section
          className="board-shell"
          id="board"
          aria-labelledby="board-title"
        >
          <div className="section-heading">
            <div>
              <h2 id="board-title">
                {mode === "operator"
                  ? "运营工作台"
                  : mode === "mine"
                    ? "我的投稿"
                    : "投稿广场"}
                <span className="heading-square" />
              </h2>
            </div>
            <p className="section-subtitle">
              查看回复与制作进度。
            </p>
            <button
              className="button button-green board-compose"
              onClick={() => compose()}
            >
              <Icon name="plus" size={14} /> 写投稿
            </button>
          </div>
          <div className="board-layout">
            <aside className="chapter-sidebar">
              <div className="sidebar-heading">
                <Icon name="note" size={16} />
                <h3>讨论范围</h3>
              </div>
              <button
                className={`chapter-choice ${!chapterId ? "selected" : ""}`}
                onClick={() => {
                  setChapterId("");
                  setPage(1);
                }}
              >
                <span className="chapter-glyph">∞</span>
                <span>全部章节</span>
              </button>
              {chapters.status === "loading" ? (
                <p className="sidebar-note">章节加载中…</p>
              ) : chapters.status === "error" ? (
                <button className="text-button" onClick={retryChapters}>
                  重新加载章节
                </button>
              ) : (
                chapterItems.map((chapter, index) => (
                  <button
                    key={chapter.id}
                    className={`chapter-choice ${chapterId === chapter.id ? "selected" : ""}`}
                    aria-pressed={chapterId === chapter.id}
                    onClick={() => {
                      setChapterId(chapter.id);
                      setPage(1);
                    }}
                  >
                    <span className="chapter-glyph">
                      {chapter.kind === "future"
                        ? "?"
                        : chapter.kind === "general"
                          ? "∞"
                          : String(index + 1).padStart(2, "0")}
                    </span>
                    <span>{chapter.title}</span>
                    <span className="choice-arrow">›</span>
                  </button>
                ))
              )}
              <div className="sidebar-separator" />
              <button
                className={`chapter-choice ${mode === "mine" ? "selected" : ""}`}
                onClick={() => {
                  if (!user) authenticate({ kind: "mine" });
                  else {
                    clearFilters();
                    setMode("mine");
                  }
                }}
              >
                <Icon name="user" size={16} /> 我的投稿
              </button>
              {user?.isOperator && (
                <button
                  className={`chapter-choice ${mode === "operator" ? "selected" : ""}`}
                  onClick={() => {
                    clearFilters();
                    setMode("operator");
                  }}
                >
                  <Icon name="flag" size={16} /> 运营工作台
                </button>
              )}
              <div className="sidebar-note chapter-tip">
                <span className="tiny-label">防剧透偏好</span>
                <p>
                  {user?.progressOrder
                    ? "已按你设置的阅读进度加载本章说。"
                    : "尚未设置阅读进度，本章说暂不加载。"}
                  <br />
                  卡点反馈不要求通关。
                </p>
                <button
                  className="text-button"
                  onClick={() =>
                    user
                      ? setModal("profile")
                      : authenticate({ kind: "profile" })
                  }
                >
                  设置阅读进度 →
                </button>
              </div>
            </aside>
            <div className="feed-column">
              <div
                className="channel-tabs"
                role="group"
                aria-label="投稿入口筛选"
              >
                {[["", "全部"], ...Object.entries(CHANNELS)].map(
                  ([key, label]) => (
                    <button
                      key={key}
                      aria-pressed={channel === key}
                      className={channel === key ? "selected" : ""}
                      onClick={() => {
                        setChannel(key as Channel | "");
                        setPage(1);
                      }}
                    >
                      {label}
                    </button>
                  ),
                )}
              </div>
              <div className="feed-tools">
                <div className="sort-tabs" role="group" aria-label="投稿排序">
                  {(
                    [
                      ["new", "最新投稿"],
                      ["likes", "最多支持"],
                      ["rating", "最高评分"],
                    ] as const
                  ).map(([key, label]) => (
                    <button
                      key={key}
                      className={sort === key ? "selected" : ""}
                      onClick={() => {
                        setSort(key);
                        setPage(1);
                      }}
                    >
                      {label}
                    </button>
                  ))}
                </div>
                <label className="search-box">
                  <Icon name="search" size={14} />
                  <span className="sr-only">搜索投稿</span>
                  <input
                    type="search"
                    maxLength={100}
                    value={search}
                    onChange={(event) => setSearch(event.target.value)}
                    placeholder="搜索投稿"
                  />
                </label>
              </div>
              <div className="queue-filter">
                <label>
                  处理进度{" "}
                  <select
                    aria-label="处理进度筛选"
                    value={status}
                    onChange={(event) => {
                      setStatus(event.target.value as Status | "");
                      setPage(1);
                    }}
                  >
                    <option value="">全部状态</option>
                    {Object.entries(STATUSES).map(([key, label]) => (
                      <option key={key} value={key}>
                        {label}
                      </option>
                    ))}
                  </select>
                </label>
                {(chapterId ||
                  channel ||
                  query ||
                  status ||
                  mode !== "public") && (
                  <button className="text-button" onClick={clearFilters}>
                    清除筛选 ×
                  </button>
                )}
              </div>
              {channel === "chapter" && (
                <div className="inline-notice">
                  本章说只加载你已设置进度内的章节。
                  {!user && "请登录并设置阅读进度。"}
                </div>
              )}
              <div className="feed-meta">
                <span>
                  {chapterId ? chapterName(chapterId) : "全部讨论范围"} ·{" "}
                  {mode === "operator"
                    ? "含已隐藏投稿"
                    : "公开内容与自己的投稿"}
                </span>
                <span>
                  {feedLoading ? "读取中…" : feed ? `${feed.total} 份投稿` : ""}
                </span>
              </div>
              <div className="feed">
                {feedLoading ? (
                  <div className="loading-panel" role="status">
                    <span className="pixel-loader" />
                    <p>正在翻开大家的便签…</p>
                  </div>
                ) : feedError ? (
                  <div className="empty-panel pixel-panel" role="alert">
                    <h3>投稿暂时没连上</h3>
                    <p>{feedError}</p>
                    <button className="button button-green" onClick={refresh}>
                      重新加载
                    </button>
                  </div>
                ) : feed?.items.length ? (
                  feed.items.map((idea, index) => (
                    <IdeaCard
                      key={idea.id}
                      idea={idea}
                      chapter={chapterName(idea.chapterId)}
                      rank={sort === "new" ? null : (page - 1) * 12 + index + 1}
                      pending={pending === idea.id}
                      onOpen={() => openIdea(idea.id)}
                      onLike={() =>
                        void reactTo({
                          kind: "like",
                          id: idea.id,
                          value: !idea.myLiked,
                        })
                      }
                    />
                  ))
                ) : (
                  <div className="empty-panel pixel-panel">
                    <div className="empty-envelope">
                      <Icon name="note" size={38} />
                      <span>+</span>
                    </div>

                    <h3>
                      {channel === "chapter" && !user?.progressOrder
                        ? "先设置阅读进度，再看本章说"
                        : "这里还没有投稿。"}
                    </h3>
                    <p>
                      {query
                        ? "换个关键词，或看看其他章节。"
                        : "分享一段经历，或反馈一个问题。"}
                    </p>
                    <button
                      className="button button-green"
                      onClick={() => compose()}
                    >
                      写投稿
                    </button>
                  </div>
                )}
              </div>
              {feed && feed.total > 12 && !feedLoading && !feedError && (
                <nav className="pagination" aria-label="投稿分页">
                  <button
                    className="button button-outline"
                    disabled={page === 1}
                    onClick={() => setPage(page - 1)}
                  >
                    ← 上一页
                  </button>
                  <span>
                    {page} / {Math.ceil(feed.total / 12)}
                  </span>
                  <button
                    className="button button-outline"
                    disabled={page * 12 >= feed.total}
                    onClick={() => setPage(page + 1)}
                  >
                    下一页 →
                  </button>
                </nav>
              )}
            </div>
            <aside className="right-sidebar">
              <section className="rank-panel pixel-panel" id="ranking">
                <div className="panel-title">
                  <Icon name="flag" size={16} />
                  <h3>灵感风向标</h3>
                  <span className="tiny-label">TOP 3</span>
                </div>
                <div className="rank-tabs">
                  <button
                    className={rankSort === "likes" ? "selected" : ""}
                    onClick={() => setRankSort("likes")}
                  >
                    最多支持
                  </button>
                  <button
                    className={rankSort === "rating" ? "selected" : ""}
                    onClick={() => setRankSort("rating")}
                  >
                    最高评分
                  </button>
                </div>
                {rankState === "loading" ? (
                  <div className="rank-empty" role="status">
                    正在更新榜单…
                  </div>
                ) : rankings?.length ? (
                  <ol className="rank-list">
                    {rankings.map((idea, index) => (
                      <li key={idea.id}>
                        <span className="rank-number">0{index + 1}</span>
                        <button onClick={() => openIdea(idea.id)}>
                          <strong>{idea.title}</strong>
                          <small>
                            {rankSort === "likes"
                              ? `${idea.likeCount} 个赞`
                              : `${idea.ratingAverage?.toFixed(1) ?? "—"} 分 · ${idea.ratingCount} 人评分`}
                          </small>
                        </button>
                      </li>
                    ))}
                  </ol>
                ) : (
                  <div className="rank-empty">
                    <Icon name="star" size={24} />
                    <p>
                      {rankings
                        ? "还没有故事投稿。"
                        : "榜单暂时无法读取。"}
                    </p>
                    {!rankings && (
                      <button className="text-button" onClick={refresh}>
                        重新加载
                      </button>
                    )}
                  </div>
                )}
                <p className="rank-footnote">
                  点赞供选题参考，不代表一定采用。
                </p>
              </section>

            </aside>
          </div>
        </section>

      </main>
      <footer className="site-footer">
        <span>
          <strong>7:55</strong> 校园共创平台
        </span>
        <p>游客可浏览 · 投稿与互动时登录 · 不要求手机号或学号</p>
        <a href="#board">回到广场 ↑</a>
      </footer>
      {notice && !modal && (
        <div
          className={`toast ${notice.error ? "error" : ""}`}
          role={notice.error ? "alert" : "status"}
        >
          <span>{notice.error ? "!" : "✓"}</span>
          {notice.text}
          <button aria-label="关闭提示" onClick={() => setNotice(null)}>
            ×
          </button>
        </div>
      )}
      {modal === "auth" && (
        <Dialog title="玩家账号" onClose={closeModal}>
          {inlineNotice}
          <div className="auth-heading">
            <span className="auth-pixel-avatar">
              <Icon name="user" size={30} />
            </span>
            <h2>登录 / 注册</h2>
            <p>
              与游戏共用一个账号，登录后自动返回。
            </p>
          </div>
          {authState === "ready" && config?.configured ? (
            <button
              className="button button-green full-width"
              disabled={Boolean(pending)}
              onClick={() => void startLogin()}
            >
              {pending === "login" ? "正在前往登录页…" : "继续登录"}
            </button>
          ) : (
            <div className="inline-notice">
              {authState === "loading"
                ? "正在读取登录服务配置…"
                : authState === "error"
                  ? "登录服务信息未能加载，请重新检查。"
                  : config
                    ? "登录服务尚未配置。现在可以先浏览，写好的内容会留在当前标签页。"
                    : "登录服务信息未能加载，请重新检查。"}
              <button
                className="text-button"
                onClick={() => void loadSession()}
              >
                重新检查
              </button>
            </div>
          )}
          <p className="form-note">
            无需手机号或学号。登录由 Authing 提供，投稿草稿仅留在当前标签页。
          </p>
        </Dialog>
      )}
      {modal === "compose" && (
        <Dialog title="写投稿" wide onClose={closeModal}>
          {inlineNotice}
          <ComposeForm
            draft={draft}
            onChange={setDraft}
            chapters={chapterItems}
            user={user}
            busy={pending === "publish"}
            onSubmit={publish}
            onProfile={() =>
              user ? setModal("profile") : authenticate({ kind: "profile" })
            }
          />
        </Dialog>
      )}
      {modal === "profile" && user && (
        <Dialog title="昵称与阅读进度" onClose={closeModal}>
          {inlineNotice}
          {!chapterItems.length ? (
            <p>
              章节目录暂未就绪。
              <button className="text-button" onClick={retryChapters}>
                重新加载
              </button>
            </p>
          ) : (
            <ProfileForm
              key={user.id + String(user.progressOrder)}
              user={user}
              chapters={chapterItems}
              onSaved={(next) => {
                setUser(next);
                setModal(null);
                refresh();
                notify("名片已保存。本章说已按你的阅读进度更新。");
              }}
            />
          )}
        </Dialog>
      )}
      {modal === "detail" && (
        <Dialog title="投稿详情" wide onClose={closeModal}>
          {inlineNotice}
          {detailLoading ? (
            <div className="loading-panel" role="status">
              <span className="pixel-loader" />
              正在翻开这份投稿…
            </div>
          ) : detailError ? (
            <div className="empty-panel" role="alert">
              <h3>暂时无法查看</h3>
              <p>{detailError}</p>
              <p>本章说需要在阅读进度内；已撤回或被隐藏的内容也不会公开。</p>
              <button className="button button-outline" onClick={closeModal}>
                返回广场
              </button>
            </div>
          ) : (
            detail && (
              <article className="idea-detail">
                <div className="idea-tags">
                  <span className="tag tag-green">
                    {chapterName(detail.chapterId)}
                  </span>
                  <span className="tag">{CHANNELS[detail.channel]}</span>
                  <span className={`tag status-${detail.status}`}>
                    {STATUSES[detail.status]}
                  </span>
                  {detail.moderated && (
                    <span className="tag tag-spoiler">已隐藏</span>
                  )}
                  {detail.spoiler && (
                    <span className="tag tag-spoiler">含剧透</span>
                  )}
                </div>
                <h2>{detail.title}</h2>
                <div className="author-line">
                  <span className="avatar">
                    {detail.author.nickname.slice(0, 1)}
                  </span>
                  <strong>{detail.author.nickname}</strong>
                  <span>
                    · {date(detail.createdAt)}
                    {detail.isOwner ? " · 我的投稿" : ""}
                  </span>
                </div>
                {detail.contentHidden ? (
                  <div className="spoiler-curtain">
                    <span>!</span>
                    <h3>这张便签含有剧情细节</h3>
                    <p>内容与处理回复尚未加载，确定想看再展开。</p>
                    <button
                      className="button button-outline"
                      onClick={() => setRevealed(true)}
                    >
                      我已了解，加载内容
                    </button>
                  </div>
                ) : (
                  <>
                    <div className="idea-body">{detail.body}</div>
                    <section
                      className="progress-timeline"
                      aria-label="投稿处理进展"
                    >
                      <h3>处理进度</h3>
                      <ol>
                        <li>
                          <span className="timeline-dot" />
                          <time>{date(detail.createdAt)}</time>
                          <strong>已收录</strong>
                          <p>等待团队查看，尚未采用。</p>
                        </li>
                        {updates?.map((update) => (
                          <li key={update.id}>
                            <span className="timeline-dot" />
                            <time>{date(update.createdAt)}</time>
                            <strong>
                              {STATUSES[update.status]} · 项目团队回复
                            </strong>
                            <p>{update.note}</p>
                            {update.version && (
                              <span className="tag">{update.version}</span>
                            )}
                            {update.playUrl && (
                              <a
                                className="button button-green timeline-link"
                                href={update.playUrl}
                                target="_blank"
                                rel="noopener noreferrer"
                              >
                                {update.status === "published"
                                  ? "查看发布版本"
                                  : "打开试玩"}{" "}
                                ↗
                              </a>
                            )}
                            {update.credit && (
                              <small>作者确认署名：{update.credit}</small>
                            )}
                          </li>
                        ))}
                      </ol>
                      {updatesError && (
                        <p className="form-error">
                          处理记录暂时没连上：{updatesError}
                          <button className="text-button" onClick={refresh}>
                            重试
                          </button>
                        </p>
                      )}
                    </section>
                  </>
                )}
                <section className="rating-area" aria-labelledby="rating-title">
                  <div>
                    <h3 id="rating-title">
                      {detail.channel === "feedback"
                        ? "这条反馈对你有帮助吗？"
                        : "你有多期待这个想法？"}
                    </h3>
                    <p>
                      {detail.ratingCount
                        ? `${detail.ratingAverage?.toFixed(1)} 分 · ${detail.ratingCount} 人评分`
                        : "还没有评分。每人可评分一次，之后也能修改。"}
                    </p>
                  </div>
                  <div className="rating-controls">
                    <div
                      className="stars"
                      role="group"
                      aria-label="为投稿评分，1 到 5 星"
                    >
                      {[1, 2, 3, 4, 5].map((score) => (
                        <button
                          key={score}
                          className={
                            (detail.myRating ?? 0) >= score ? "filled" : ""
                          }
                          aria-label={`${score} 星`}
                          aria-pressed={detail.myRating === score}
                          disabled={Boolean(pending) || detail.moderated}
                          onClick={() =>
                            void reactTo({
                              kind: "rating",
                              id: detail.id,
                              value: score,
                            })
                          }
                        >
                          <Icon name="star" size={26} />
                        </button>
                      ))}
                    </div>
                    {detail.myRating !== null && (
                      <button
                        className="text-button"
                        disabled={Boolean(pending)}
                        onClick={() =>
                          void reactTo({
                            kind: "rating",
                            id: detail.id,
                            value: null,
                          })
                        }
                      >
                        已评 {detail.myRating} 星 · 撤回
                      </button>
                    )}
                  </div>
                </section>
                <div className="detail-actions">
                  <button
                    className={`button ${detail.myLiked ? "button-liked" : "button-green"}`}
                    aria-pressed={detail.myLiked}
                    disabled={Boolean(pending) || detail.moderated}
                    onClick={() =>
                      void reactTo({
                        kind: "like",
                        id: detail.id,
                        value: !detail.myLiked,
                      })
                    }
                  >
                    <Icon name="heart" size={16} />
                    {detail.myLiked ? "已支持" : "支持这份投稿"}{" "}
                    <span>{detail.likeCount}</span>
                  </button>
                  <button
                    className="button button-outline"
                    onClick={() => void share()}
                  >
                    <Icon name="share" size={14} /> 分享
                  </button>
                  {detail.canWithdraw && (
                    <button
                      className="text-button danger"
                      onClick={() => setConfirmWithdraw(!confirmWithdraw)}
                    >
                      撤回投稿
                    </button>
                  )}
                </div>
                {shareUrl && (
                  <label className="share-fallback">
                    分享链接
                    <input
                      readOnly
                      value={shareUrl}
                      onFocus={(event) => event.target.select()}
                    />
                  </label>
                )}
                {confirmWithdraw && (
                  <div className="delete-confirm" role="alert">
                    <p>
                      确定撤回？投稿将停止公开，点赞与评分也不再计入榜单。平台保留内部处理记录。
                    </p>
                    <div>
                      <button
                        className="button button-danger"
                        disabled={Boolean(pending)}
                        onClick={() => void withdraw()}
                      >
                        {pending === "withdraw" ? "正在撤回…" : "确认撤稿"}
                      </button>
                      <button
                        className="button button-outline"
                        onClick={() => setConfirmWithdraw(false)}
                      >
                        保留投稿
                      </button>
                    </div>
                  </div>
                )}
                {detail.isOwner && (
                  <PermissionForm
                    key={detail.id + String(detail.revision)}
                    idea={detail}
                    onSaved={() => {
                      refresh();
                      notify("授权与署名选择已保存。");
                    }}
                  />
                )}
                {detail.isOwner && !detail.canWithdraw && (
                  <p className="form-note">
                    投稿已进入制作或发布阶段，如需撤稿或调整授权，请在项目团队的沟通渠道联系运营同学协商。
                  </p>
                )}
                {user?.isOperator && (
                  <OperatorForm
                    key={detail.id + String(detail.revision)}
                    idea={detail}
                    onSaved={() => {
                      refresh();
                      notify("处理进展已更新到原投稿。");
                    }}
                    onModerated={() => {
                      refresh();
                      notify("投稿可见范围已更新。");
                    }}
                  />
                )}
              </article>
            )
          )}
        </Dialog>
      )}
    </>
  );
}

function IdeaCard({
  idea,
  chapter,
  rank,
  pending,
  onOpen,
  onLike,
}: {
  idea: Idea;
  chapter: string;
  rank: number | null;
  pending: boolean;
  onOpen: () => void;
  onLike: () => void;
}) {
  return (
    <article className="idea-card pixel-panel">
      <div className="card-main">
        <div className="idea-tags">
          <span className="tag tag-green">{chapter}</span>
          <span className="category-label">{CHANNELS[idea.channel]}</span>
          <span className={`tag status-${idea.status}`}>
            {STATUSES[idea.status]}
          </span>
          {idea.spoiler && <span className="tag tag-spoiler">含剧透</span>}
          {idea.moderated && <span className="tag tag-spoiler">已隐藏</span>}
          {rank !== null && (
            <span className={`card-rank ${rank <= 3 ? "top" : ""}`}>
              #{String(rank).padStart(2, "0")}
            </span>
          )}
        </div>
        <button className="idea-title" onClick={onOpen}>
          {idea.title}
        </button>
        <p
          className={`idea-excerpt ${idea.contentHidden ? "spoiler-preview" : ""}`}
        >
          {idea.contentHidden
            ? "含剧情细节，打开后可自行选择加载。"
            : idea.body}
        </p>
        <div className="card-footer">
          <span className="author-line">
            <span className="avatar small">
              {idea.author.nickname.slice(0, 1)}
            </span>
            <span>
              {idea.author.nickname}
              {idea.isOwner ? " · 我" : ""}
            </span>
            <span className="card-date">· {date(idea.createdAt)}</span>
          </span>
          <button
            className="rating-summary"
            onClick={onOpen}
            aria-label={`评分 ${idea.ratingAverage?.toFixed(1) ?? "暂无"}，打开详情`}
          >
            <Icon name="star" size={13} />
            <strong>{idea.ratingAverage?.toFixed(1) ?? "—"}</strong>
            <span>{idea.ratingCount ? `(${idea.ratingCount})` : "待评分"}</span>
          </button>
        </div>
      </div>
      <button
        className={`vote-button ${idea.myLiked ? "liked" : ""}`}
        disabled={pending || idea.moderated}
        aria-label={`${idea.myLiked ? "取消支持" : "支持"}：${idea.title}`}
        aria-pressed={idea.myLiked}
        onClick={onLike}
      >
        <Icon name="heart" size={18} />
        <strong>{count(idea.likeCount)}</strong>
        <small>{pending ? "保存中" : idea.myLiked ? "已支持" : "支持"}</small>
      </button>
    </article>
  );
}
