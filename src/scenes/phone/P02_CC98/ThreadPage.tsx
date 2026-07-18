import type { ReactNode } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import forumTreasureUrl from "../../../assets/ui/cc98_forum_treasure.png";
import personaData from "../../../data/cc98.thread-personas.json";

interface ThreadReply {
  personaId: string;
  time: string;
  floor: string;
  role?: string;
  text: string;
  image?: string;
  caption?: string;
  likes: string;
  dislikes: string;
}

interface ThreadPost {
  author: string;
  title: string;
  body: string;
  board: string;
  time: string;
  avatar?: string;
  views?: string;
  threadOperation?: { user: string; action: string; reason: string };
  threadMetrics?: { favorites: string; likes: string; dislikes: string };
  threadReplies?: ThreadReply[];
}

interface Cc98ThreadPageProps {
  post: ThreadPost;
  onBack: () => void;
  interactiveContent?: ReactNode;
  showBdContent?: boolean;
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
  pagination: "1/11",
  comments: [
    {
      id: "ordinary-reply-2",
      author: "晚八点打印机",
      time: "今天 08:24",
      role: "2楼",
      floor: "2楼",
      text: "先 bd 留言。问题能不能解决不确定，队形必须先完整。",
      likes: "47",
      dislikes: "1"
    },
    {
      id: "ordinary-reply-3",
      author: "玉泉风很大",
      time: "今天 08:27",
      role: "3楼",
      floor: "3楼",
      text: "bd 图先补上，楼主今晚大概能收到一点抽象支援。",
      image: "cc98_forum_treasure",
      caption: "bd",
      likes: "98",
      dislikes: "0"
    }
  ]
} satisfies {
  appTitle: string;
  hotBadge: string;
  mainTime: string;
  ownerRole: string;
  mainFloor: string;
  operation: { user: string; action: string; reason: string };
  metrics: { views: string; favorites: string; likes: string; dislikes: string };
  replyTitle: string;
  replyFilter: string;
  pagination: string;
  comments: Array<{
    id: string;
    author: string;
    time: string;
    role?: string;
    floor: string;
    text: string;
    image?: "cc98_forum_treasure";
    caption?: string;
    likes: string;
    dislikes: string;
  }>;
};

const personas = new Map(personaData.map((persona) => [persona.id, persona]));

/** 普通帖子保持独立论坛详情外观；剧情调查内容由交互区提供。 */
export function Cc98ThreadPage({ post, onBack, interactiveContent, showBdContent = false }: Cc98ThreadPageProps) {
  const operation = post.threadOperation ?? thread.operation;
  const metrics = {
    views: post.views ?? thread.metrics.views,
    favorites: post.threadMetrics?.favorites ?? thread.metrics.favorites,
    likes: post.threadMetrics?.likes ?? thread.metrics.likes,
    dislikes: post.threadMetrics?.dislikes ?? thread.metrics.dislikes
  };
  const comments: ThreadReply[] = (post.threadReplies ?? thread.comments.map((comment, index) => ({
    time: comment.time,
    floor: comment.floor,
    role: comment.role,
    text: comment.text,
    image: comment.image,
    caption: comment.caption,
    likes: comment.likes,
    dislikes: comment.dislikes,
    personaId: index === 0 ? "late-printer" : "yuquan-wind"
  }))).filter((comment) => showBdContent || (!comment.image && !/\bbd\b/i.test(comment.text)));

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
        <header className="cc98-thread-title">
          <span>{thread.hotBadge}</span>
          <h2>{post.title}</h2>
        </header>

        <article className={`cc98-thread-card is-owner ${interactiveContent ? "is-investigation-owner" : ""}`.trim()}>
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
          {!interactiveContent ? (
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

        {interactiveContent ?? (
          <>
            <section className="cc98-reply-filter" aria-label="回复筛选">
              <strong>{thread.replyTitle}</strong>
              <span>xxx</span>
            </section>

            {comments.map((comment, index) => {
              const persona = personas.get(comment.personaId);
              return (
              <article key={`${comment.personaId}-${comment.floor}`} className="cc98-thread-card">
                <header className="cc98-floor-header">
                  <span className={`cc98-thread-avatar persona-${persona?.avatar ?? "anonymous"}`} aria-hidden="true" />
                  <div>
                    <strong>{persona?.nickname ?? `匿名用户${index + 1}`}</strong>
                    <small>{comment.time}</small>
                  </div>
                  {comment.role ? <em>{comment.role}</em> : null}
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

            <footer className="cc98-thread-pagination" aria-hidden="true">
              <span>xxx</span><strong>xxx</strong><em>xxx</em><strong>xxx</strong><b>xxx</b>
            </footer>
          </>
        )}
      </main>
    </section>
  );
}
