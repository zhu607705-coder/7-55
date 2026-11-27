import { useState } from "react";
import type { Idea, User } from "@755/contracts";
import { api, messageOf } from "../../lib/api";
import { CATEGORIES, type Draft } from "./model";

export function ComposeForm({
  draft,
  onChange,
  user,
  busy,
  onSubmit,
}: {
  draft: Draft;
  onChange: (draft: Draft) => void;
  user: User | null;
  busy: boolean;
  onSubmit: () => Promise<void>;
}) {
  const [error, setError] = useState("");
  const suggestion = draft.channel === "suggestion";
  const update = <K extends keyof Draft>(key: K, value: Draft[K]) =>
    onChange({ ...draft, [key]: value });
  return (
    <>
      <div className="compose-heading">
        <h2>{suggestion ? "投递一份建议" : "发个帖子"}</h2>
        <p>
          {suggestion
            ? "想加一个模式，还是一段剧情？把想法写具体，大家一起投票。"
            : "好玩的瞬间、通关感受、想吐槽的地方，都可以聊。"}
        </p>
      </div>
      <form
        className="form-stack"
        onSubmit={(event) => {
          event.preventDefault();
          setError("");
          void onSubmit().catch((error) => setError(messageOf(error)));
        }}
      >
        <label>
          {suggestion ? "建议标题" : "标题（选填）"}
          <input
            required={suggestion}
            minLength={suggestion ? 4 : undefined}
            maxLength={100}
            value={draft.title}
            disabled={busy}
            onChange={(e) => update("title", e.target.value)}
            placeholder={
              suggestion
                ? "例如：增加一个双人合作解谜模式"
                : "用一句话说说你想聊什么"
            }
          />
        </label>
        {suggestion && (
          <label>
            建议类型
            <select
              value={draft.category}
              disabled={busy}
              onChange={(e) =>
                update("category", e.target.value as Draft["category"])
              }
            >
              {Object.entries(CATEGORIES).map(([key, label]) => (
                <option key={key} value={key}>
                  {label}
                </option>
              ))}
            </select>
          </label>
        )}
        <label>
          {suggestion ? "建议详情" : "帖子内容"}
          <span className="field-help">
            {suggestion
              ? "说明想增加什么、为什么，以及你设想的玩法或故事。至少 10 字。"
              : "最多 10,000 字。"}
          </span>
          <textarea
            required
            minLength={suggestion ? 10 : 1}
            maxLength={10000}
            rows={suggestion ? 7 : 5}
            value={draft.body}
            disabled={busy}
            onChange={(e) => update("body", e.target.value)}
            placeholder={
              suggestion
                ? "我希望增加……\n这样可以……\n具体可以这样设计……"
                : "这次玩《7:55》，我最想说的是……"
            }
          />
        </label>
        <div className="compose-options">
          <label className="checkbox-field">
            <input
              type="checkbox"
              checked={draft.spoiler}
              disabled={busy}
              onChange={(e) => update("spoiler", e.target.checked)}
            />
            <span>包含剧透，展开后再显示内容</span>
          </label>
          {!suggestion && (
            <label className="checkbox-field">
              <input
                type="checkbox"
                checked={draft.anonymous}
                disabled={busy}
                onChange={(e) => update("anonymous", e.target.checked)}
              />
              <span>匿名发布</span>
            </label>
          )}
        </div>
        <label className="checkbox-field">
          <input
            type="checkbox"
            required
            checked={draft.accepted}
            disabled={busy}
            onChange={(e) => update("accepted", e.target.checked)}
          />
          <span>
            我确认这段内容可以公开，涉及他人的信息已取得同意或作匿名处理。
          </span>
        </label>
        {suggestion && (
          <p className="form-note">
            投递后进入建议列表，玩家可以投票。主创团队会参考排行，与作者进一步讨论；改编和署名届时另行沟通。
          </p>
        )}
        {error && (
          <p className="form-error" role="alert">
            {error}
          </p>
        )}
        <div className="compose-footer">
          <span className="form-note">草稿在当前标签页保留 2 小时。</span>
          <button className="button button-green" disabled={busy} type="submit">
            {busy
              ? "正在发布…"
              : !user
                ? "登录后" + (suggestion ? "投递" : "发布")
                : suggestion
                  ? "提交建议"
                  : "发布帖子"}
          </button>
        </div>
      </form>
    </>
  );
}

export function ProfileForm({
  user,
  onSaved,
}: {
  user: User;
  onSaved: (user: User) => void;
}) {
  const [nickname, setNickname] = useState(user.nickname);
  const [busy, setBusy] = useState(false),
    [error, setError] = useState("");
  return (
    <form
      className="form-stack"
      onSubmit={(e) => {
        e.preventDefault();
        setBusy(true);
        setError("");
        void api<{ user: User }>("/profile", {
          method: "PUT",
          body: JSON.stringify({
            nickname,
          }),
        })
          .then((r) => onSaved(r.user))
          .catch((e) => setError(messageOf(e)))
          .finally(() => setBusy(false));
      }}
    >
      <div className="compose-heading">
        <h2>修改昵称</h2>
        <p>发帖、评论和投递建议时，其他玩家会看到这个名字。</p>
      </div>
      <label>
        公开昵称
        <input
          required
          minLength={1}
          maxLength={24}
          value={nickname}
          disabled={busy}
          onChange={(e) => setNickname(e.target.value)}
        />
      </label>
      {error && (
        <p role="alert" className="form-error">
          {error}
        </p>
      )}
      <button className="button button-green" disabled={busy}>
        {busy ? "正在保存…" : "保存昵称"}
      </button>
    </form>
  );
}

export function ModerationForm({
  idea,
  onSaved,
}: {
  idea: Idea;
  onSaved: () => void;
}) {
  const [reason, setReason] = useState("");
  const [busy, setBusy] = useState(false),
    [error, setError] = useState("");
  return (
    <details className="optional-fields">
      <summary>内容管理</summary>
      <form
        className="form-stack"
        onSubmit={(e) => {
          e.preventDefault();
          setBusy(true);
          setError("");
          void api(`/operator/ideas/${idea.id}/moderation`, {
            method: "PUT",
            body: JSON.stringify({ hidden: !idea.moderated, reason }),
          })
            .then(onSaved)
            .catch((e) => setError(messageOf(e)))
            .finally(() => setBusy(false));
        }}
      >
        <label>
          内部处理原因
          <input
            required
            maxLength={1000}
            value={reason}
            disabled={busy}
            onChange={(e) => setReason(e.target.value)}
          />
        </label>
        {error && (
          <p className="form-error" role="alert">
            {error}
          </p>
        )}
        <button className="button button-outline" disabled={busy}>
          {idea.moderated ? "恢复公开" : "隐藏这条内容"}
        </button>
      </form>
    </details>
  );
}
