import { useEffect, useState } from "react";
import type { Idea, User, commentsSchema } from "@755/contracts";
import { api, ApiError, messageOf } from "../../lib/api";
import { date } from "./model";
type CommentsPage = ReturnType<typeof commentsSchema.parse>;
const keyFor = (id: string) => "755-comment-draft-" + id;
export function clearCommentDrafts() {
  try {
    Object.keys(sessionStorage)
      .filter((key) => key.startsWith("755-comment-draft-"))
      .forEach((key) => sessionStorage.removeItem(key));
  } catch {}
}
export function Comments({
  idea,
  user,
  revealed,
  onLogin,
  onChanged,
}: {
  idea: Idea;
  user: User | null;
  revealed: boolean;
  onLogin: () => void;
  onChanged: () => void;
}) {
  const [body, setBody] = useState(() => {
    try {
      const saved = JSON.parse(
        sessionStorage.getItem(keyFor(idea.id)) ?? "null",
      );
      return saved &&
        saved.expires > Date.now() &&
        (!saved.owner || saved.owner === user?.id) &&
        typeof saved.body === "string"
        ? saved.body
        : "";
    } catch {
      return "";
    }
  });
  const [data, setData] = useState<CommentsPage | null>(null),
    [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true),
    [error, setError] = useState("");
  const [submitError, setSubmitError] = useState(""),
    [busy, setBusy] = useState(false);
  const [revision, setRevision] = useState(0),
    [deleteId, setDeleteId] = useState<string | null>(null);
  useEffect(() => {
    try {
      if (body)
        sessionStorage.setItem(
          keyFor(idea.id),
          JSON.stringify({
            body,
            owner: user?.id ?? null,
            expires: Date.now() + 2 * 60 * 60 * 1000,
          }),
        );
      else sessionStorage.removeItem(keyFor(idea.id));
    } catch {}
  }, [body, idea.id, user?.id]);
  useEffect(() => {
    let active = true;
    setLoading(true);
    setError("");
    void api<CommentsPage>(
      `/ideas/${idea.id}/comments?page=${page}&reveal=${revealed}`,
    )
      .then((result) => {
        if (active) setData(result);
      })
      .catch((e) => {
        if (active) setError(messageOf(e));
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [idea.id, user?.id, revealed, page, revision]);
  async function send() {
    if (!user) {
      onLogin();
      return;
    }
    if (!body.trim() || busy) return;
    setBusy(true);
    setSubmitError("");
    try {
      await api(`/ideas/${idea.id}/comments`, {
        method: "POST",
        body: JSON.stringify({ body }),
      });
      setBody("");
      setPage(Math.ceil(((data?.total ?? 0) + 1) / 30));
      setRevision((n) => n + 1);
      onChanged();
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) onLogin();
      else setSubmitError(messageOf(e));
    } finally {
      setBusy(false);
    }
  }
  async function remove(id: string) {
    setBusy(true);
    setSubmitError("");
    try {
      await api(`/ideas/${idea.id}/comments/${id}`, {
        method: "DELETE",
        body: "{}",
      });
      setDeleteId(null);
      setPage(
        Math.max(1, Math.min(page, Math.ceil(((data?.total ?? 1) - 1) / 30))),
      );
      setRevision((n) => n + 1);
      onChanged();
    } catch (e) {
      setSubmitError(messageOf(e));
    } finally {
      setBusy(false);
    }
  }
  return (
    <section className="comments" aria-labelledby="comments-title">
      <h3 id="comments-title">
        评论 <span>{data?.total ?? idea.commentCount}</span>
      </h3>
      {loading ? (
        <p role="status" className="comment-state">
          正在加载评论…
        </p>
      ) : error ? (
        <div role="alert" className="comment-state">
          <p>{error}</p>
          <button
            className="text-button"
            onClick={() => setRevision((n) => n + 1)}
          >
            重新加载
          </button>
        </div>
      ) : data?.items.length ? (
        <ol className="comment-list">
          {data.items.map((comment) => (
            <li key={comment.id}>
              <div className="comment-meta">
                <strong>{comment.author.nickname}</strong>
                <time>{date(comment.createdAt)}</time>
                {comment.canDelete && (
                  <button
                    className="text-button"
                    disabled={busy}
                    onClick={() => setDeleteId(comment.id)}
                  >
                    删除
                  </button>
                )}
              </div>
              <p className="comment-body">{comment.body}</p>
              {deleteId === comment.id && (
                <div className="comment-delete">
                  <span>删除这条评论？</span>
                  <button
                    className="text-button danger"
                    disabled={busy}
                    onClick={() => void remove(comment.id)}
                  >
                    确认删除
                  </button>
                  <button
                    className="text-button"
                    disabled={busy}
                    onClick={() => setDeleteId(null)}
                  >
                    取消
                  </button>
                </div>
              )}
            </li>
          ))}
        </ol>
      ) : (
        <p className="comment-state">还没有评论，说说你的想法吧。</p>
      )}
      {data && data.total > 30 && (
        <nav className="pagination" aria-label="评论分页">
          <button
            className="text-button"
            disabled={page === 1 || loading}
            onClick={() => setPage(page - 1)}
          >
            上一页
          </button>
          <span>
            {page} / {Math.ceil(data.total / 30)}
          </span>
          <button
            className="text-button"
            disabled={page * 30 >= data.total || loading}
            onClick={() => setPage(page + 1)}
          >
            下一页
          </button>
        </nav>
      )}
      {idea.moderated ? (
        <p className="form-note">这条内容已隐藏，暂时不能评论。</p>
      ) : (
        <form
          className="comment-form"
          onSubmit={(e) => {
            e.preventDefault();
            void send();
          }}
        >
          <label htmlFor="comment-body">
            {user ? "写评论" : "先写下想法，登录后发送"}
          </label>
          <textarea
            id="comment-body"
            required
            maxLength={2000}
            rows={3}
            value={body}
            disabled={busy}
            onChange={(e) => setBody(e.target.value)}
            placeholder="说说你的感受，或者接着聊聊这个想法。"
          />
          <div className="comment-form-footer">
            <span>
              {idea.anonymous && idea.isOwner
                ? "以匿名作者身份评论"
                : user
                  ? `以 ${user.nickname} 的身份评论`
                  : "与游戏共用一个账号"}
            </span>
            <button className="button button-green" disabled={busy}>
              {busy ? "正在发送…" : user ? "发送评论" : "登录后评论"}
            </button>
          </div>
        </form>
      )}
      {submitError && (
        <p className="form-error" role="alert">
          {submitError}
        </p>
      )}
    </section>
  );
}
