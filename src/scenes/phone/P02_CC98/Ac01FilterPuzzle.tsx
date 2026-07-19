import { useMemo } from "react";
import forumTreasureUrl from "../../../assets/ui/cc98_forum_treasure.png";
import libraryFinalsContent from "../../../data/library-finals.content.json";
import { kit } from "../../../modules/GameKit";

interface Ac01FilterPuzzleProps {
  optionalAc01Floors: number[];
  showBdContent?: boolean;
}

interface FloorReply {
  floor: number;
  author: string;
  role: string;
  text: string;
  quote?: string;
  ac01?: boolean;
  media?: "cc98_forum_treasure";
  caption?: string;
}

const cc98Content = libraryFinalsContent.cc98;
const OPTIONAL_AC01_REPLIES = new Map<number, FloorReply>(
  cc98Content.optionalAc01Replies.map((reply) => [
    reply.floor,
    { ...reply, role: "水帖", ac01: true }
  ])
);
const STORY_REPLIES = new Map<number, FloorReply>(
  cc98Content.storyReplies.map((reply) => [
    reply.floor,
    {
      ...reply,
      media: "media" in reply && reply.media === "cc98_forum_treasure"
        ? "cc98_forum_treasure"
        : undefined,
      caption: "caption" in reply ? reply.caption : undefined
    }
  ])
);
const OPTIONAL_AC01_FLOORS = new Set(OPTIONAL_AC01_REPLIES.keys());
const FILLER_AUTHORS = cc98Content.fillerReplies.authors;
const FILLER_TEXT = cc98Content.fillerReplies.texts;

function buildFloors(): FloorReply[] {
  let fillerIndex = 0;
  return Array.from({ length: 23 }, (_, index) => {
    const floor = index + 1;
    const story = STORY_REPLIES.get(floor);
    if (story) return story;
    const optionalAc01 = OPTIONAL_AC01_REPLIES.get(floor);
    if (optionalAc01) return optionalAc01;
    return {
      floor,
      author: FILLER_AUTHORS[fillerIndex % FILLER_AUTHORS.length],
      role: "路过",
      text: FILLER_TEXT[fillerIndex++ % FILLER_TEXT.length]
    };
  });
}

/** 23 楼占座调查帖；5 条 ac01 只记录阅读，不参与通关校验。 */
export function Ac01FilterPuzzle({ optionalAc01Floors, showBdContent = false }: Ac01FilterPuzzleProps) {
  const floors = useMemo(buildFloors, []);

  return (
    <section className="cc98-investigation cc98-investigation-v2" aria-label="022占座调查帖回复">
      <header className="cc98-investigation-tools">
        <div>
          <strong>23 楼调查记录</strong>
          <p>关键线索分布在不同用户的回复和引用中。</p>
        </div>
        <span aria-live="polite">ac01 已读 {optionalAc01Floors.length}/5</span>
      </header>

      <div className="cc98-investigation-floors">
        {floors.map((reply) => {
          const bdHidden = !showBdContent && (reply.media === "cc98_forum_treasure" || /\bbd\b/i.test(reply.text));
          const optionalRead = optionalAc01Floors.includes(reply.floor);
          return (
            <article
              key={reply.floor}
              className={`cc98-investigation-floor ${STORY_REPLIES.has(reply.floor) ? "is-story-floor is-story-checked" : ""} ${reply.ac01 ? "is-ac01-floor" : ""}`.trim()}
              data-investigation-floor={reply.floor}
            >
              <header>
                <span className="cc98-thread-avatar anonymous" aria-hidden="true" />
                <div>
                  <strong>{bdHidden ? "xxx" : reply.author}</strong>
                  <small>08:{String((reply.floor * 7 + 3) % 60).padStart(2, "0")}</small>
                  <em>{bdHidden ? "xxx" : reply.role}</em>
                </div>
                <b>{reply.floor}楼</b>
              </header>
              {!bdHidden && reply.quote ? <blockquote>{reply.quote}</blockquote> : null}
              <p>{bdHidden ? "xxx" : reply.text}</p>
              {!bdHidden && reply.media === "cc98_forum_treasure" ? (
                <figure className="cc98-forum-treasure cc98-investigation-treasure">
                  <img src={forumTreasureUrl} alt="CC98 bd 表情包" />
                  <figcaption>{reply.caption ?? "bd"}</figcaption>
                </figure>
              ) : null}
              {reply.ac01 ? (
                <button
                  type="button"
                  className="cc98-ac01-read"
                  disabled={optionalRead}
                  onClick={() => kit.libraryFinals.inspectOptionalAc01(reply.floor)}
                >
                  {optionalRead ? "已记下这条水帖" : "读一下（可选）"}
                </button>
              ) : null}
            </article>
          );
        })}
      </div>

      <footer className="cc98-investigation-count">
        {OPTIONAL_AC01_FLOORS.size} 条 ac01 全部为可选内容；证据进度不会因此变化。
      </footer>
    </section>
  );
}
