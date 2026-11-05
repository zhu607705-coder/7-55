import { useState, type FormEvent, type ReactNode } from "react";
import {
  type Chapter,
  type Idea,
  type User,
  type updateSchema,
} from "@755/contracts";
import { api, messageOf } from "../../lib/api";
import {
  CHANNELS,
  STATUSES,
  CATEGORIES,
  type Draft,
  type Status,
} from "./model";

type Credit = Draft["credit"];
export function CreditFields({
  value,
  onChange,
  disabled = false,
}: {
  value: Credit;
  onChange: (value: Credit) => void;
  disabled?: boolean;
}) {
  return (
    <label>
      游戏署名
      <select
        value={value.mode}
        disabled={disabled}
        onChange={(event) =>
          onChange({ ...value, mode: event.target.value as Credit["mode"] })
        }
      >
        <option value="anonymous">不公开署名</option>
        <option value="nickname">用平台昵称署名</option>
        <option value="custom">另填署名</option>
      </select>
      {value.mode === "custom" && (
        <input
          required
          maxLength={40}
          value={value.name}
          disabled={disabled}
          onChange={(event) => onChange({ ...value, name: event.target.value })}
          placeholder="希望出现在游戏致谢里的名字"
        />
      )}
    </label>
  );
}
export function ComposeForm({
  draft,
  onChange,
  chapters,
  user,
  busy,
  onSubmit,
  onProfile,
}: {
  draft: Draft;
  onChange: (draft: Draft) => void;
  chapters: Chapter[];
  user: User | null;
  busy: boolean;
  onSubmit: () => Promise<void>;
  onProfile: () => void;
}) {
  const [error, setError] = useState("");
  const update = <K extends keyof Draft>(key: K, value: Draft[K]) =>
    onChange({ ...draft, [key]: value });
  const isChapter = draft.channel === "chapter";
  const options = chapters.filter(
    (chapter) =>
      !isChapter ||
      (chapter.kind === "chapter" &&
        (user?.progressOrder ?? 0) >= chapter.sortOrder),
  );
  return (
    <>
      <div className="compose-heading">
        <h2>{CHANNELS[draft.channel]}</h2>
        <p>
          {draft.channel === "feedback"
            ? "还没通关也能反馈。描述卡在哪里、用了什么设备，会更容易定位问题。"
            : draft.channel === "chapter"
              ? "讨论本章。涉及谜底或结局请标记剧透。"
              : "写一段经历，或一个玩法点子。"}
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
        <div className="entry-tabs">
          {Object.entries(CHANNELS).map(([key, label]) => (
            <button
              type="button"
              key={key}
              disabled={busy}
              className={draft.channel === key ? "selected" : ""}
              onClick={() =>
                onChange({
                  ...draft,
                  channel: key as Draft["channel"],
                  chapterId:
                    key === "chapter"
                      ? (options.find((chapter) => chapter.kind === "chapter")
                          ?.id ?? "chapter-1")
                      : draft.chapterId,
                  category: key === "feedback" ? "experience" : "story",
                })
              }
            >
              {label}
            </button>
          ))}
        </div>
        <label>
          写下你想说的
          <span className="field-help">一句话起，最多 10,000 字</span>
          <textarea
            required
            minLength={1}
            maxLength={10000}
            rows={5}
            disabled={busy}
            value={draft.body}
            onChange={(event) => update("body", event.target.value)}
            placeholder={
              draft.channel === "feedback"
                ? "例如：手机上在教学楼门口转了好几圈，不知道该点哪里。"
                : "例如：刚考完试，自行车却怎么也骑不出教学楼。"
            }
          />
        </label>
        <div className="form-columns">
          <label>
            关联章节
            <select
              required
              value={draft.chapterId}
              disabled={busy || !options.length}
              onChange={(event) => update("chapterId", event.target.value)}
            >
              {!options.some((chapter) => chapter.id === draft.chapterId) && (
                <option value="">请选择章节</option>
              )}
              {options.map((chapter) => (
                <option key={chapter.id} value={chapter.id}>
                  {chapter.title}
                </option>
              ))}
            </select>
          </label>
          <label>
            投稿类型
            <select
              disabled={busy}
              value={draft.category}
              onChange={(event) =>
                update("category", event.target.value as Draft["category"])
              }
            >
              {Object.entries(CATEGORIES).map(([key, label]) => (
                <option key={key} value={key}>
                  {label}
                </option>
              ))}
            </select>
          </label>
        </div>
        {isChapter && (!user || !options.length) && (
          <div className="inline-notice">
            本章说需要登录后设置阅读进度。卡点反馈不要求通关。
            <button type="button" className="text-button" onClick={onProfile}>
              设置阅读进度 →
            </button>
          </div>
        )}
        <details className="optional-fields">
          <summary>补充标题（选填）</summary>
          <label>
            标题
            <input
              maxLength={100}
              value={draft.title}
              disabled={busy}
              onChange={(event) => update("title", event.target.value)}
              placeholder="不填时用正文开头作标题"
            />
          </label>
        </details>
        <label className="checkbox-field">
          <input
            type="checkbox"
            checked={draft.spoiler}
            disabled={busy}
            onChange={(event) => update("spoiler", event.target.checked)}
          />
          <span>
            <strong>包含谜底、关键道具或结局</strong>
            <small>标题和正文默认隐藏，读者主动展开后才会加载。</small>
          </span>
        </label>
        <label className="checkbox-field">
          <input
            type="checkbox"
            checked={draft.anonymous}
            disabled={busy}
            onChange={(event) => update("anonymous", event.target.checked)}
          />
          <span>
            <strong>对外匿名投稿</strong>
            <small>
              其他玩家只看到“匿名同学”；平台保留账号关联以便你管理投稿。
            </small>
          </span>
        </label>
        <details className="optional-fields">
          <summary>改编授权与游戏署名（可先不授权）</summary>
          <p className="form-note">
            没有授权的经历仍可收录和讨论，运营不能将它推进游戏制作。
          </p>
          <label className="checkbox-field">
            <input
              type="checkbox"
              checked={draft.adaptationConsent}
              disabled={busy}
              onChange={(event) =>
                update("adaptationConsent", event.target.checked)
              }
            />
            <span>
              <strong>同意本项目将这份投稿改编进游戏</strong>
              <small>
                非独占，仅限本校园游戏项目的制作、试玩和发布；原文权利仍归你，不包含公开真实身份或单独宣传使用。
              </small>
            </span>
          </label>
          <CreditFields
            value={draft.credit}
            onChange={(credit) => update("credit", credit)}
            disabled={busy}
          />
        </details>
        <label className="checkbox-field">
          <input
            type="checkbox"
            required
            checked={draft.accepted}
            disabled={busy}
            onChange={(event) => update("accepted", event.target.checked)}
          />
          <span>
            <strong>我确认可以公开这段内容</strong>
            <small>
              涉及他人已匿名化或获得同意；允许平台展示投稿并由团队评估，未进入制作前可随时撤稿。改编与署名按上面的单独选择处理。
            </small>
          </span>
        </label>
        {error && (
          <p className="form-error" role="alert">
            {error}
          </p>
        )}
        <div className="compose-footer">
          <p>
            草稿在当前标签页保留 2 小时。
            <br />
            已收录表示收到，不代表已经入选。
          </p>
          <button
            className="button button-green"
            disabled={busy || !chapters.length}
            type="submit"
          >
            {busy ? "正在保存…" : user ? "提交投稿" : "登录后提交 →"}
          </button>
        </div>
      </form>
    </>
  );
}
export function ActionForm({
  children,
  onSubmit,
  label,
}: {
  children: ReactNode;
  onSubmit: () => Promise<void>;
  label: string;
}) {
  const [busy, setBusy] = useState(false),
    [error, setError] = useState("");
  const submit = (event: FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setError("");
    void onSubmit()
      .catch((error) => setError(messageOf(error)))
      .finally(() => setBusy(false));
  };
  return (
    <form className="form-stack" onSubmit={submit}>
      <fieldset disabled={busy} className="plain-fieldset">
        {children}
      </fieldset>
      {error && (
        <p className="form-error" role="alert">
          {error}
        </p>
      )}
      <button className="button button-green" disabled={busy}>
        {busy ? "正在保存…" : label}
      </button>
    </form>
  );
}
export function ProfileForm({
  user,
  chapters,
  onSaved,
}: {
  user: User;
  chapters: Chapter[];
  onSaved: (user: User) => void;
}) {
  const [nickname, setNickname] = useState(user.nickname),
    [chapterId, setChapterId] = useState(
      chapters.find(
        (c) => c.kind === "chapter" && c.sortOrder === user.progressOrder,
      )?.id ?? "",
    );
  return (
    <>
      <div className="compose-heading">
        <h2>你的公开名片</h2>
        <p>登录凭据由 Authing 管理，这里只设置昵称和防剧透偏好。</p>
      </div>
      <ActionForm
        label="保存名片与阅读进度"
        onSubmit={async () => {
          const result = await api<{ user: User }>("/profile", {
            method: "PUT",
            body: JSON.stringify({ nickname, chapterId: chapterId || null }),
          });
          onSaved(result.user);
        }}
      >
        <label>
          公开昵称
          <input
            required
            minLength={1}
            maxLength={24}
            value={nickname}
            onChange={(event) => setNickname(event.target.value)}
          />
        </label>
        <label>
          我已玩到
          <select
            value={chapterId}
            onChange={(event) => setChapterId(event.target.value)}
          >
            <option value="">还没开始 / 暂不看本章说</option>
            {chapters
              .filter((c) => c.kind === "chapter")
              .map((c) => (
                <option key={c.id} value={c.id}>
                  {c.title}
                </option>
              ))}
          </select>
        </label>
        <p className="form-note">
          由你主动设置，只控制本章说的可见范围，不代表游戏通关，也不发放成就。卡点反馈与故事分享不受这个进度限制。
        </p>
      </ActionForm>
    </>
  );
}
export function PermissionForm({
  idea,
  onSaved,
}: {
  idea: Idea;
  onSaved: (idea: Idea) => void;
}) {
  const [consent, setConsent] = useState(idea.adaptationConsent ?? false),
    [credit, setCredit] = useState(
      idea.credit ?? { mode: "anonymous" as const, name: "" },
    );
  return (
    <details className="optional-fields">
      <summary>管理改编授权与署名</summary>
      <ActionForm
        label="保存授权选择"
        onSubmit={async () => {
          const result = await api<{ idea: Idea }>(
            `/ideas/${idea.id}/permissions`,
            {
              method: "PUT",
              body: JSON.stringify({ adaptationConsent: consent, credit }),
            },
          );
          onSaved(result.idea);
        }}
      >
        <label className="checkbox-field">
          <input
            type="checkbox"
            checked={consent}
            disabled={!idea.canWithdraw}
            onChange={(event) => setConsent(event.target.checked)}
          />
          <span>
            允许本项目非独占改编、试玩和发布这份投稿；原文权利仍归我。
          </span>
        </label>
        <CreditFields value={credit} onChange={setCredit} />
        <p className="form-note">
          进入制作后，授权变更需要与团队协商。修改署名将同步更新平台上已有的署名记录，已发布游戏需由团队另行更新。
        </p>
      </ActionForm>
    </details>
  );
}
export function OperatorForm({
  idea,
  onSaved,
  onModerated,
}: {
  idea: Idea;
  onSaved: (idea: Idea) => void;
  onModerated: () => void;
}) {
  const [status, setStatus] = useState<Status>(idea.status),
    [note, setNote] = useState(""),
    [playUrl, setPlayUrl] = useState(""),
    [version, setVersion] = useState(""),
    [reason, setReason] = useState(""),
    [spoiler, setSpoiler] = useState(idea.spoiler);
  return (
    <section className="operator-box">
      <h3>运营处理 · 仅运营账号可见</h3>
      <p className="form-note">
        原作者{idea.adaptationConsent ? "已确认改编授权" : "尚未确认改编授权"}
        。每次进展会公开显示在这份投稿下方。
      </p>
      <ActionForm
        label="发布处理进展"
        onSubmit={async () => {
          const result = await api<{ idea: Idea }>(
            `/operator/ideas/${idea.id}/updates`,
            {
              method: "POST",
              body: JSON.stringify({
                expectedRevision: idea.revision,
                status,
                note,
                spoiler,
                playUrl: playUrl.trim() || null,
                version: version.trim() || null,
              }),
            },
          );
          setNote("");
          onSaved(result.idea);
        }}
      >
        <label>
          下一步状态
          <select
            value={status}
            onChange={(event) => setStatus(event.target.value as Status)}
          >
            {Object.entries(STATUSES).map(([key, label]) => (
              <option key={key} value={key}>
                {label}
              </option>
            ))}
          </select>
        </label>
        <label>
          给投稿者的回复
          <textarea
            required
            maxLength={3000}
            value={note}
            onChange={(event) => setNote(event.target.value)}
            placeholder="说明具体处理了什么、为什么采用或暂缓，以及下一步安排。"
          />
        </label>
        <label className="checkbox-field">
          <input
            type="checkbox"
            checked={spoiler}
            disabled={idea.spoiler}
            onChange={(event) => setSpoiler(event.target.checked)}
          />
          <span>回复或投稿涉及谜底，标记为剧透后再公开</span>
        </label>
        <label>
          试玩 / 发布链接
          <input
            type="url"
            required={status === "playable" || status === "published"}
            value={playUrl}
            onChange={(event) => setPlayUrl(event.target.value)}
            placeholder="https://…"
          />
        </label>
        <label>
          版本说明
          <input
            maxLength={80}
            required={status === "playable" || status === "published"}
            value={version}
            onChange={(event) => setVersion(event.target.value)}
            placeholder="例如：0.2 试玩版 · 图书馆支线"
          />
        </label>
      </ActionForm>
      <details className="optional-fields">
        <summary>
          {idea.moderated
            ? "恢复被隐藏的投稿"
            : "隐藏涉及隐私或不适宜公开的投稿"}
        </summary>
        <ActionForm
          label={idea.moderated ? "恢复公开" : "隐藏投稿"}
          onSubmit={async () => {
            await api(`/operator/ideas/${idea.id}/moderation`, {
              method: "PUT",
              body: JSON.stringify({ hidden: !idea.moderated, reason }),
            });
            onModerated();
          }}
        >
          <label>
            处理原因
            <textarea
              required
              maxLength={1000}
              value={reason}
              onChange={(event) => setReason(event.target.value)}
            />
          </label>
          <p className="form-note">
            隐藏后其他玩家无法浏览、搜索或互动；处理原因仅保存在运营审计记录中。
          </p>
        </ActionForm>
      </details>
    </section>
  );
}
