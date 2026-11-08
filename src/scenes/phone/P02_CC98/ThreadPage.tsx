import type { ReactNode } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import forumTreasureUrl from "../../../assets/ui/cc98_forum_treasure.png";
import personaData from "../../../data/cc98.thread-personas.json";
import fallbackReplies from "../../../data/cc98.fallback-replies.json";
import type { ThreadPost, ThreadReply } from "./cc98Types";

interface Cc98ThreadPageProps {
  post: ThreadPost;
  onBack: () => void;
  interactiveContent?: ReactNode;
  beforeRepliesContent?: ReactNode;
  afterRepliesContent?: ReactNode;
  showBdContent?: boolean;
  locked?: boolean;
  showLibraryAdminReply?: boolean;
}

const thread = {
  appTitle: "CC98小程序",
  hotBadge: "热门",
  mainTime: "今天 08:22",
  ownerRole: "楼主",
  mainFloor: "1楼",
  operation: {
    user: "纸飞机维修员",
    action: "增加论坛经验 755",
    reason: "帖子成功把常识送进流程"
  },
  metrics: {
    views: "7550",
    favorites: "22",
    likes: "98",
    dislikes: "3"
  },
  replyTitle: "热门回复",
  replyFilter: "只看楼主",
  pagination: "1/11"
};

const personas = new Map(personaData.map((persona) => [persona.id, persona]));

function buildFallbackReplies(post: ThreadPost): ThreadReply[] {
  let seed = 0;
  for (const character of post.id ?? post.title) {
    seed += character.codePointAt(0)!;
  }
  return Array.from({ length: 2 + seed % 3 }, (_, index) => ({
    ...fallbackReplies[(seed + index * 5) % fallbackReplies.length],
    time: post.time,
    floor: `${index + 2}楼`,
    likes: "0",
    dislikes: "0"
  }));
}

/** 普通帖子保持独立论坛详情外观；剧情调查内容由交互区提供。 */
export function Cc98ThreadPage({
  post,
  onBack,
  interactiveContent,
  beforeRepliesContent,
  afterRepliesContent,
  showBdContent = false,
  locked = false,
  showLibraryAdminReply = false
}: Cc98ThreadPageProps) {
  const operation = post.threadOperation ?? thread.operation;
  const metrics = {
    views: post.views ?? thread.metrics.views,
    favorites: post.threadMetrics?.favorites ?? thread.metrics.favorites,
    likes: post.threadMetrics?.likes ?? thread.metrics.likes,
    dislikes: post.threadMetrics?.dislikes ?? thread.metrics.dislikes
  };
  const comments = (post.threadReplies ?? buildFallbackReplies(post))
    .filter((comment) => showBdContent || !comment.image);

  return (
    <section className="cc98-thread-page" aria-label={`CC98帖子：${post.title}`}>
      <header className="cc98-thread-header">
        <PhoneNavButton kind="back" label="返回热门话题" onClick={onBack} />
        <h1>{thread.appTitle}</h1>
        <div className="cc98-thread-capsule">
          <span aria-hidden="true">•••</span>
          <i aria-hidden="true" />
          <span aria-hidden="true">−</span>
          <i aria-hidden="true" />
          <PhoneNavButton
            kind="close"
            className="cc98-thread-close"
            label="退出帖子，返回热门话题"
            title="退出帖子"
            onClick={onBack}
            glyph={<b aria-hidden="true" />}
          />
        </div>
      </header>

      <main className="cc98-thread-scroll">
        {locked ? (
          <div className="cc98-thread-lock-notice" role="status">已锁定无法回复</div>
        ) : null}

        <header className="cc98-thread-title">
          <span>{thread.hotBadge}</span>
          <h2>{post.title}</h2>
        </header>

        <article className={`cc98-thread-card is-owner ${interactiveContent || beforeRepliesContent || afterRepliesContent ? "is-investigation-owner" : ""}`.trim()}>
          <header className="cc98-floor-header">
            <span className="cc98-thread-avatar anonymous" aria-hidden="true" />
            <div>
              <strong>{post.author}</strong>
              <small>{thread.mainTime}</small>
            </div>
            <em>{thread.ownerRole}</em>
            <b>{thread.mainFloor}</b>
          </header>
          <p>{post.body}</p>
          {!interactiveContent && !beforeRepliesContent && !afterRepliesContent ? (
            <dl className="cc98-operation-log">
              <div>
                <dt>用户</dt>
                <dd>{operation.user}</dd>
              </div>
              <div>
                <dt>操作</dt>
                <dd>{operation.action}</dd>
              </div>
              <div>
                <dt>理由</dt>
                <dd>{operation.reason}</dd>
              </div>
            </dl>
          ) : null}
          <footer className="cc98-thread-metrics" aria-hidden="true">
            <span>⚙ 操作</span>
            <span>↶ 回复</span>
            <span>◉ {metrics.views}</span>
            <span>☆ {metrics.favorites}</span>
            <span>♧ {metrics.likes}</span>
            <span>♢ {metrics.dislikes}</span>
          </footer>
        </article>

        {beforeRepliesContent}

        {interactiveContent ? (
          <>
            {interactiveContent}
            {showLibraryAdminReply ? (
              <article className="cc98-thread-card is-library-admin">
                <header className="cc98-floor-header">
                  <span className="cc98-thread-avatar persona-library-admin" aria-hidden="true" />
                  <div>
                    <strong>图书管理员</strong>
                    <small>今天 08:55</small>
                  </div>
                  <em>管理员</em>
                  <b>24楼</b>
                </header>
                <p>您好已收到您的问题反馈，请前往图书馆程序进行系统申诉。</p>
              </article>
            ) : null}
          </>
        ) : (
          <>
            <section className="cc98-reply-filter" aria-label="回复筛选">
              <strong>{thread.replyTitle}</strong>
              <span>xxx</span>
            </section>

            {comments.map((comment, index) => {
              const persona = personas.get(comment.personaId);
              const owner = comment.personaId === "thread-owner";
              const anonymousOwner = owner && post.author === "匿名用户";
              const author = owner ? post.author : comment.author ?? persona?.nickname ?? `匿名用户${index + 1}`;
              return (
              <article key={`${comment.personaId}-${comment.floor}`} className="cc98-thread-card">
                <header className="cc98-floor-header">
                  <span className={`cc98-thread-avatar persona-${persona?.avatar ?? "anonymous"}`} aria-hidden="true" />
                  <div>
                    <strong>{anonymousOwner ? "匿名楼主" : author}</strong>
                    <small>{comment.time}</small>
                  </div>
                  {!anonymousOwner && (owner || comment.role) ? <em>{owner ? "楼主" : comment.role}</em> : null}
                  <b>{comment.floor}</b>
                </header>
                <p>{comment.text}</p>
                {comment.image === "cc98_forum_treasure" ? (
                  <figure className="cc98-forum-treasure">
                    <img src={forumTreasureUrl} alt="CC98 bd 表情包" />
                    <figcaption>{comment.caption}</figcaption>
                  </figure>
                ) : null}
                <footer className="cc98-thread-metrics compact" aria-hidden="true">
                  <span>⚙ 操作</span>
                  <span>↶ 回复</span>
                  <span>♧ {comment.likes}</span>
                  <span>♢ {comment.dislikes}</span>
                </footer>
              </article>
              );
            })}
            {afterRepliesContent}

            <footer className="cc98-thread-pagination" aria-hidden="true">
              <span>xxx</span><strong>xxx</strong><em>xxx</em><strong>xxx</strong><b>xxx</b>
            </footer>
          </>
        )}
      </main>
    </section>
  );
}
