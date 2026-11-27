import { useCallback, useEffect, useRef, useState } from "react";
import { type Idea, type User } from "@755/contracts";
import { Dialog } from "../components/Dialog";
import { Icon } from "../components/Icon";
import { api, ApiError, messageOf, type IdeaList } from "../lib/api";
import {
  ComposeForm,
  ProfileForm,
  ModerationForm,
} from "../features/community/Forms";
import {
  CATEGORIES,
  date,
  emptyDraft,
  entryDraft,
  readDraft,
  saveDraft,
  clearDraft,
  saveIntent,
  takeIntent,
  errorMessages,
  type Intent,
  type Draft,
} from "../features/community/model";

import { Comments, clearCommentDrafts } from "../features/community/Comments";

type Modal = "auth" | "compose" | "profile" | "detail" | null;
type AuthConfig = {
  provider: "authing";
  configured: boolean;
  gameUrl: string | null;
};
type Section = "community" | "suggestions";
const currentSection = (): Section => {
  const params = new URLSearchParams(location.search);
  return params.get("view") === "suggestions" ||
    params.get("entry") === "suggestion"
    ? "suggestions"
    : "community";
};
const currentIdea = () => new URLSearchParams(location.search).get("idea");
const count = (value: number) => new Intl.NumberFormat("zh-CN").format(value);

export function App() {
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
  const [section, setSection] = useState<Section>(currentSection);
  const [sort, setSort] = useState<"new" | "likes">(
      currentSection() === "suggestions" ? "likes" : "new",
    ),
    [search, setSearch] = useState(""),
    [query, setQuery] = useState(""),
    [page, setPage] = useState(1);
  const [feed, setFeed] = useState<IdeaList | null>(null),
    [feedLoading, setFeedLoading] = useState(true),
    [feedError, setFeedError] = useState("");
  const [rankings, setRankings] = useState<Idea[] | null>(null);
  const [rankState, setRankState] = useState<"loading" | "ready" | "error">(
    "loading",
  );
  const [detailId, setDetailId] = useState<string | null>(currentIdea),
    [detail, setDetail] = useState<Idea | null>(null),
    [detailError, setDetailError] = useState(""),
    [detailLoading, setDetailLoading] = useState(false),
    [revealed, setRevealed] = useState(false);
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
        setRevealed(false);
        setModal((current) =>
          current === "profile" || current === "auth" ? null : current,
        );
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
      if (document.hidden || pending || mutating.current || timer !== undefined)
        return;
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
          if (event.data === "changed" && !pending && !mutating.current)
            void loadSession();
        };
      }
    } catch {
      /* Some private browser policies disable cross-tab channels. */
    }
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
      history.replaceState(
        {},
        "",
        `/${params.size ? "?" + params : ""}${location.hash}`,
      );
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
      } else if (next.kind === "comment") {
        openIdea(next.id);
      } else if (next.kind === "like" || next.kind === "rating") {
        void reactTo(next);
      }
    }
  }, [sessionState, user]);
  useEffect(() => {
    let active = true;
    const key = JSON.stringify([
      section,
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
    params.set("section", section);
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
  }, [section, query, page, sort, mode, user, revision]);
  useEffect(() => {
    if (section !== "suggestions") return;
    let active = true;
    setRankState("loading");
    void api<IdeaList>("/ideas?section=suggestions&sort=likes")
      .then((result) => {
        if (active) {
          setRankings(result.items.slice(0, 5));
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
  }, [revision, user, section]);
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
    }
    detailLoadKey.current = key;
    setDetailError("");
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
    return () => {
      active = false;
    };
  }, [detailId, revealed, user, revision]);
  useEffect(() => {
    const pop = () => {
      setDetailId(currentIdea());
      setModal(currentIdea() ? "detail" : null);
      setRevealed(false);
      setSection(currentSection());
      setSort(currentSection() === "suggestions" ? "likes" : "new");
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

  function openIdea(id: string, nextSection = section) {
    setDetailId(id);
    setDetail(null);
    setDetailLoading(true);
    setRevealed(false);
    setConfirmWithdraw(false);
    setShareUrl("");
    setModal("detail");
    const url = new URL(location.href);
    url.searchParams.delete("entry");
    url.searchParams.set("view", nextSection);
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
          returnTo: detailId
            ? `/?idea=${detailId}&view=${section}`
            : `/?view=${section}`,
        }),
      });
      location.assign(result.url);
    } catch (error) {
      notify(messageOf(error), true);
      setPending(null);
    }
  }
  function compose() {
    const nextChannel = section === "suggestions" ? "suggestion" : "post";
    setDraft((value) => ({
      ...(value.channel === nextChannel ? value : readDraft(nextChannel)),
      channel: nextChannel,
      chapterId: "general",
    }));
    setModal("compose");
  }
  async function reactTo(action: Extract<Intent, { kind: "like" | "rating" }>) {
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
      const votedIdea =
        detail?.id === action.id
          ? detail
          : feed?.items.find((item) => item.id === action.id);
      const suggestion = votedIdea?.channel === "suggestion";
      notify(
        action.kind === "like"
          ? action.value
            ? suggestion
              ? "投票已计入排行。"
              : "已点赞。"
            : suggestion
              ? "已取消投票。"
              : "已取消点赞。"
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
    if (!draft.body.trim()) throw new Error("先写下内容吧。");
    if (
      draft.channel === "suggestion" &&
      (draft.title.trim().length < 4 || draft.body.trim().length < 10)
    )
      throw new Error("建议标题至少 4 字，详情至少 10 字。");
    if (!user) {
      authenticate({ kind: "compose" });
      return;
    }
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
      clearDraft(input.channel);
      setDraft({ ...emptyDraft, channel: input.channel });
      setMode("mine");
      setSection(
        result.idea.channel === "suggestion" ? "suggestions" : "community",
      );
      setSearch("");
      setQuery("");
      setSort("new");
      setPage(1);
      refresh();
      openIdea(
        result.idea.id,
        result.idea.channel === "suggestion" ? "suggestions" : "community",
      );
      notify(
        result.idea.channel === "suggestion"
          ? "建议已发布，大家可以来投票了。"
          : "帖子已发布。",
      );
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
      clearCommentDrafts();
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
    const url = `${location.origin}/?idea=${detail.id}&view=${detail.channel === "suggestion" ? "suggestions" : "community"}`;
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
    setSearch("");
    setQuery("");
    setPage(1);
  }
  function switchSection(next: Section) {
    setSection(next);
    clearFilters();
    setSort(next === "suggestions" ? "likes" : "new");
    const url = new URL(location.href);
    url.searchParams.set("view", next);
    url.searchParams.delete("entry");
    history.pushState({}, "", url);
  }
  const isSuggestions = section === "suggestions";
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
        跳到帖子列表
      </a>
      <header className="site-header">
        <div className="header-inner">
          <a href="/" className="brand" aria-label="7:55 共创平台首页">
            <span className="brand-clock">
              7<span>:</span>55
            </span>
            <span className="brand-divider" />
            <span className="brand-title">共创平台</span>
          </a>
          <nav className="main-nav" aria-label="主导航">
            {config?.gameUrl && <a href={config.gameUrl}>试玩游戏 ↗</a>}
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
                    <button
                      onClick={() => {
                        clearFilters();
                        setMode("mine");
                        setAccountOpen(false);
                        document.getElementById("board")?.scrollIntoView();
                      }}
                    >
                      我发布的内容
                    </button>
                    <button
                      onClick={() => {
                        setModal("profile");
                        setAccountOpen(false);
                      }}
                    >
                      修改昵称
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
                        内容管理
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
                <Icon name="user" size={14} />
                登录 / 注册
              </button>
            )}
          </div>
        </div>
      </header>
      <main>
        <section className="hero hero-compact" aria-labelledby="hero-title">
          <img
            className="hero-landscape"
            src="/art/campus-night.png"
            alt="《7:55》像素校园夜景，湖畔灯光亮起。"
          />
          <div className="hero-shade" />
          <div className="hero-content">
            <h1 id="hero-title">
              玩完了，<span>来聊聊。</span>
            </h1>
            <p>聊游戏感受，也把你想玩的新模式、新剧情告诉我们。</p>
          </div>
        </section>
        <section className="community-shell" id="board" aria-label="共创平台">
          <div className="primary-entrances" role="group" aria-label="选择板块">
            <button
              className={`entrance ${!isSuggestions ? "selected" : ""}`}
              aria-pressed={!isSuggestions}
              onClick={() => switchSection("community")}
            >
              <Icon name="chat" size={30} />
              <span>
                <strong>玩家社区</strong>
                <small>发帖、评论、点赞</small>
              </span>
              <Icon name="arrow" size={18} />
            </button>
            <button
              className={`entrance ${isSuggestions ? "selected" : ""}`}
              aria-pressed={isSuggestions}
              onClick={() => switchSection("suggestions")}
            >
              <Icon name="note" size={30} />
              <span>
                <strong>建议投递</strong>
                <small>提建议，投票看排行</small>
              </span>
              <Icon name="arrow" size={18} />
            </button>
          </div>
          <div className="board-heading">
            <div>
              <h2>
                {mode === "mine"
                  ? isSuggestions
                    ? "我的建议"
                    : "我的帖子"
                  : mode === "operator"
                    ? "内容管理"
                    : isSuggestions
                      ? "你想让游戏多点什么？"
                      : "大家都在聊"}
              </h2>
              <p>
                {isSuggestions
                  ? "主创团队会参考票数排行，与同学进一步讨论。"
                  : "喜欢的片段、通关的感受，或者一句吐槽。"}
              </p>
            </div>
            <button className="button button-green" onClick={compose}>
              <Icon name="plus" size={16} />
              {isSuggestions ? "投递建议" : "发个帖子"}
            </button>
          </div>
          <div
            className={`content-layout ${isSuggestions ? "with-ranking" : ""}`}
          >
            <div className="feed-column">
              <div className="feed-tools">
                <div
                  className="sort-tabs"
                  role="group"
                  aria-label={isSuggestions ? "建议排序" : "帖子排序"}
                >
                  {(isSuggestions
                    ? [
                        ["likes", "投票排行"],
                        ["new", "最新建议"],
                      ]
                    : [
                        ["new", "最新帖子"],
                        ["likes", "热门帖子"],
                      ]
                  ).map(([key, label]) => (
                    <button
                      key={key}
                      className={sort === key ? "selected" : ""}
                      aria-pressed={sort === key}
                      onClick={() => {
                        setSort(key as "likes" | "new");
                        setPage(1);
                      }}
                    >
                      {label}
                    </button>
                  ))}
                </div>
                <label className="search-box">
                  <Icon name="search" size={14} />
                  <span className="sr-only">
                    {isSuggestions ? "搜索建议" : "搜索帖子"}
                  </span>
                  <input
                    type="search"
                    maxLength={100}
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    placeholder={isSuggestions ? "搜索建议" : "搜索帖子"}
                  />
                </label>
              </div>
              {mode !== "public" && (
                <div className="feed-scope">
                  <span>
                    {mode === "mine"
                      ? "只看自己发布的内容"
                      : "管理视图包含被隐藏的内容"}
                  </span>
                  <button className="text-button" onClick={clearFilters}>
                    返回全部
                  </button>
                </div>
              )}
              {feedLoading ? (
                <div className="loading-panel" role="status">
                  <span className="pixel-loader" />
                  <p>正在加载{isSuggestions ? "建议" : "帖子"}…</p>
                </div>
              ) : feedError ? (
                <div className="empty-panel" role="alert">
                  <h3>暂时没有加载出来</h3>
                  <p>{feedError}</p>
                  <button className="button button-outline" onClick={refresh}>
                    重新加载
                  </button>
                </div>
              ) : feed?.items.length ? (
                <div className="feed">
                  {feed.items.map((idea, index) => (
                    <IdeaCard
                      key={idea.id}
                      idea={idea}
                      rank={
                        isSuggestions && sort === "likes"
                          ? (page - 1) * 12 + index + 1
                          : null
                      }
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
                  ))}
                </div>
              ) : (
                <div className="empty-panel clean-empty">
                  <Icon name={isSuggestions ? "note" : "chat"} size={40} />
                  <h3>
                    {query
                      ? "没有找到匹配的内容"
                      : mode === "mine"
                        ? "你还没有在这里发布内容"
                        : isSuggestions
                          ? "第一份建议，从你开始"
                          : "还没有帖子，来开个话题吧"}
                  </h3>
                  <p>
                    {query
                      ? "换个关键词试试。"
                      : isSuggestions
                        ? "一个新模式、一段新剧情，都值得认真写下来。"
                        : "聊聊《7:55》里让你印象最深的地方。"}
                  </p>
                  {query && (
                    <button
                      className="text-button"
                      onClick={() => {
                        setSearch("");
                        setQuery("");
                      }}
                    >
                      清除搜索
                    </button>
                  )}
                </div>
              )}
              {feed && feed.total > 12 && !feedLoading && !feedError && (
                <nav className="pagination" aria-label="内容分页">
                  <button
                    className="button button-outline"
                    disabled={page === 1}
                    onClick={() => setPage(page - 1)}
                  >
                    上一页
                  </button>
                  <span>
                    {page} / {Math.ceil(feed.total / 12)}
                  </span>
                  <button
                    className="button button-outline"
                    disabled={page * 12 >= feed.total}
                    onClick={() => setPage(page + 1)}
                  >
                    下一页
                  </button>
                </nav>
              )}
            </div>
            {isSuggestions && (
              <aside
                className="suggestion-ranking"
                aria-labelledby="ranking-title"
              >
                <h3 id="ranking-title">
                  <Icon name="flag" size={18} /> 建议排行榜
                </h3>
                <p className="ranking-subtitle">按票数排序 · 前 5 名</p>
                {rankState === "loading" ? (
                  <p className="rank-empty" role="status">
                    正在更新排行…
                  </p>
                ) : rankState === "error" ? (
                  <div className="rank-empty">
                    <p>排行暂时没加载出来。</p>
                    <button className="text-button" onClick={refresh}>
                      重新加载
                    </button>
                  </div>
                ) : rankings?.length ? (
                  <ol className="rank-list">
                    {rankings.map((idea, index) => (
                      <li key={idea.id}>
                        <span className="rank-number">{index + 1}</span>
                        <button onClick={() => openIdea(idea.id)}>
                          <strong>{idea.title}</strong>
                          <small>{idea.likeCount} 票</small>
                        </button>
                      </li>
                    ))}
                  </ol>
                ) : (
                  <p className="rank-empty">
                    还没有建议，投递后就会出现在这里。
                  </p>
                )}
                <p className="rank-footnote">
                  每个账号每份建议可投 1 票，也可以取消。
                </p>
              </aside>
            )}
          </div>
        </section>
      </main>
      <footer className="site-footer">
        <span>
          <strong>7:55</strong> 共创平台
        </span>
        <p>游客可浏览，登录后发帖、评论和投票。</p>
        {config?.gameUrl && (
          <a className="footer-game-link" href={config.gameUrl}>
            返回游戏 ↗
          </a>
        )}
      </footer>
      {notice && !modal && (
        <div
          className={`toast ${notice.error ? "error" : ""}`}
          role={notice.error ? "alert" : "status"}
        >
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
            <h2>登录 / 注册</h2>
            <p>与游戏共用一个账号，登录后自动返回。</p>
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
              <p>
                {authState === "loading"
                  ? "正在读取登录配置…"
                  : "登录服务暂时无法使用，可以先浏览，草稿会保留在当前标签页。"}
              </p>
              <button
                className="text-button"
                onClick={() => void loadSession()}
              >
                重新检查
              </button>
            </div>
          )}
        </Dialog>
      )}
      {modal === "compose" && (
        <Dialog
          title={draft.channel === "suggestion" ? "建议投递" : "发布帖子"}
          wide
          onClose={closeModal}
        >
          {inlineNotice}
          <ComposeForm
            draft={draft}
            onChange={setDraft}
            user={user}
            busy={pending === "publish"}
            onSubmit={publish}
          />
        </Dialog>
      )}
      {modal === "profile" && user && (
        <Dialog title="修改昵称" onClose={closeModal}>
          {inlineNotice}
          <ProfileForm
            key={user.id}
            user={user}
            onSaved={(next) => {
              setUser(next);
              setModal(null);
              refresh();
              notify("昵称已保存。");
            }}
          />
        </Dialog>
      )}
      {modal === "detail" && (
        <Dialog
          title={detail?.channel === "suggestion" ? "建议详情" : "帖子详情"}
          wide
          onClose={closeModal}
        >
          {inlineNotice}
          {detailLoading ? (
            <div className="loading-panel" role="status">
              正在加载内容…
            </div>
          ) : detailError ? (
            <div className="empty-panel" role="alert">
              <h3>暂时无法查看</h3>
              <p>{detailError}</p>
              <button className="button button-outline" onClick={closeModal}>
                返回列表
              </button>
            </div>
          ) : (
            detail && (
              <article className="idea-detail">
                <div className="idea-tags">
                  <span className="tag tag-green">
                    {detail.channel === "suggestion"
                      ? CATEGORIES[detail.category]
                      : "玩家社区"}
                  </span>
                  {detail.spoiler && (
                    <span className="tag tag-spoiler">含剧透</span>
                  )}
                  {detail.moderated && (
                    <span className="tag tag-spoiler">已隐藏</span>
                  )}
                </div>
                <h2>{detail.title}</h2>
                <div className="author-line">
                  <span className="avatar">
                    {detail.author.nickname.slice(0, 1)}
                  </span>
                  <strong>{detail.author.nickname}</strong>
                  <span>
                    {date(detail.createdAt)}
                    {detail.isOwner ? " · 我发布的" : ""}
                  </span>
                </div>
                {detail.contentHidden ? (
                  <div className="spoiler-curtain">
                    <h3>内容包含剧情细节</h3>
                    <p>展开后会显示正文和评论。</p>
                    <button
                      className="button button-outline"
                      onClick={() => setRevealed(true)}
                    >
                      展开剧透内容
                    </button>
                  </div>
                ) : (
                  <div className="idea-body">{detail.body}</div>
                )}
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
                    <Icon
                      name={detail.channel === "suggestion" ? "up" : "heart"}
                      size={16}
                    />
                    {detail.channel === "suggestion"
                      ? detail.myLiked
                        ? "已投票"
                        : "投一票"
                      : detail.myLiked
                        ? "已点赞"
                        : "点赞"}{" "}
                    · {detail.likeCount}
                    {detail.channel === "suggestion" ? " 票" : ""}
                  </button>
                  <button
                    className="button button-outline"
                    onClick={() => void share()}
                  >
                    <Icon name="share" size={14} />
                    分享
                  </button>
                  {detail.canWithdraw && (
                    <button
                      className="text-button danger"
                      onClick={() => setConfirmWithdraw(!confirmWithdraw)}
                    >
                      撤回
                    </button>
                  )}
                </div>
                {detail.channel === "suggestion" && (
                  <p className="form-note">
                    主创团队会参考票数排行，与作者进一步讨论。
                  </p>
                )}
                {shareUrl && (
                  <label className="share-fallback">
                    分享链接
                    <input
                      readOnly
                      value={shareUrl}
                      onFocus={(e) => e.target.select()}
                    />
                  </label>
                )}
                {confirmWithdraw && (
                  <div className="delete-confirm" role="alert">
                    <p>撤回后，这条内容及评论将停止公开，并退出排行。</p>
                    <div>
                      <button
                        className="button button-danger"
                        disabled={Boolean(pending)}
                        onClick={() => void withdraw()}
                      >
                        {pending === "withdraw" ? "正在撤回…" : "确认撤回"}
                      </button>
                      <button
                        className="button button-outline"
                        onClick={() => setConfirmWithdraw(false)}
                      >
                        取消
                      </button>
                    </div>
                  </div>
                )}
                {!detail.contentHidden && (
                  <Comments
                    key={detail.id + (user?.id ?? "guest")}
                    idea={detail}
                    user={user}
                    revealed={revealed}
                    onLogin={() =>
                      authenticate({ kind: "comment", id: detail.id })
                    }
                    onChanged={refresh}
                  />
                )}
                {user?.isOperator && (
                  <ModerationForm
                    key={detail.id + String(detail.revision)}
                    idea={detail}
                    onSaved={() => {
                      refresh();
                      notify("公开状态已更新。");
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
  rank,
  pending,
  onOpen,
  onLike,
}: {
  idea: Idea;
  rank: number | null;
  pending: boolean;
  onOpen: () => void;
  onLike: () => void;
}) {
  const suggestion = idea.channel === "suggestion";
  return (
    <article
      className={`idea-card ${suggestion ? "suggestion-card" : "post-card"}`}
    >
      {suggestion && (
        <button
          className={`vote-button ${idea.myLiked ? "liked" : ""}`}
          disabled={pending || idea.moderated}
          aria-label={`${idea.myLiked ? "取消投票" : "投票"}：${idea.title}`}
          aria-pressed={idea.myLiked}
          onClick={onLike}
        >
          <Icon name="up" size={20} />
          <strong>{count(idea.likeCount)}</strong>
          <small>
            {pending ? "保存中" : idea.myLiked ? "已投票" : "投一票"}
          </small>
        </button>
      )}
      <div className="card-main">
        <div className="idea-tags">
          {suggestion && (
            <span className="category-label">{CATEGORIES[idea.category]}</span>
          )}
          {rank !== null && <span className="card-rank">第 {rank} 名</span>}
          {idea.spoiler && <span className="tag tag-spoiler">含剧透</span>}
          {idea.moderated && <span className="tag tag-spoiler">已隐藏</span>}
        </div>
        <button className="idea-title" onClick={onOpen}>
          {idea.title}
        </button>
        <p
          className={`idea-excerpt ${idea.contentHidden ? "spoiler-preview" : ""}`}
        >
          {idea.contentHidden ? "包含剧情细节，打开后可选择展开。" : idea.body}
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
            <time className="card-date">{date(idea.createdAt)}</time>
          </span>
          <div className="post-actions">
            <button className="comment-link" onClick={onOpen}>
              <Icon name="chat" size={15} />
              {idea.commentCount} 条评论
            </button>
            {!suggestion && (
              <button
                className={`post-like ${idea.myLiked ? "liked" : ""}`}
                aria-label={`${idea.myLiked ? "取消点赞" : "点赞"}：${idea.title}`}
                aria-pressed={idea.myLiked}
                disabled={pending || idea.moderated}
                onClick={onLike}
              >
                <Icon name="heart" size={15} />
                {idea.likeCount}
              </button>
            )}
          </div>
        </div>
      </div>
    </article>
  );
}
