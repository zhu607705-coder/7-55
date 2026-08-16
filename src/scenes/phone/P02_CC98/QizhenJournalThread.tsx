import { useEffect, useMemo, useRef, useState } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import { QizhenRecipeFrame } from "../../../components/QizhenRecipeFrame";
import qizhenContent from "../../../data/chapter3-qizhen-lake.content.json";
import personaData from "../../../data/cc98.thread-personas.json";
import type {
  QizhenPhotoRecord,
  QizhenPhotoSpotId
} from "../../../core/types";
import type { QizhenJournalThreadView } from "../../../modules/QizhenJournalModel";

/* ===== view 投影与文案来源 =====
   view 来自 QizhenJournalModel.projectJournalThread(纯函数,刷新/筛选不改楼层):
   status / archived / title / board / mainPhoto / mainCaption / statusText /
   replies[{ id, kind, floor, personaId, text, photo, likes }] /
   pendingDraft / unpublishedSpotIds。
   楼主回复的正文由投影写入 reply.text(补拍 caption),照片在 reply.photo。
   其余用户可见文字取自 content JSON 的 journal.thread 节(逐字键名钉死)与
   journal.spotNames;结构未就位时归一为空串,组件不自行编造。楼层号等数字除外。
   publishing 为组件内瞬时态:点击发布主帖后置位防连点(重复提交由 controller
   幂等键兜底),view 刷新或网络错误模态出现时复位。 */

export interface QizhenJournalThreadProps {
  view: QizhenJournalThreadView;
  canPublishMain: boolean;
  publishableSpotIds: QizhenPhotoSpotId[];
  networkError: boolean;
  onPublishMain: () => void;
  onPublishReply: (spotId: QizhenPhotoSpotId) => void;
  onOpenControlCenter: () => void;
  onReturnToLake: () => void;
  onKeepEditing: () => void;
  onBack: () => void;
}

interface JournalThreadNetworkCopy {
  title: string;
  body: string;
  openControlCenter: string;
  returnToLake: string;
  keepEditing: string;
}

interface JournalThreadCopy {
  board: string;
  authorRole: string;
  draftBadge: string;
  publishMain: string;
  publishing: string;
  publishReply: string;
  ownerOnly: string;
  showAll: string;
  continueSupplement: string;
  returnToLake: string;
  archivedNotice: string;
  mainPhotoAlt: string;
  replyPhotoAlt: string;
  networkError: JournalThreadNetworkCopy;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function asString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function readStringMap(value: unknown): Record<string, string> {
  const record = asRecord(value);
  if (!record) {
    return {};
  }
  const map: Record<string, string> = {};
  for (const [key, entry] of Object.entries(record)) {
    if (typeof entry === "string") {
      map[key] = entry;
    }
  }
  return map;
}

const THREAD_COPY_KEYS = [
  "board",
  "authorRole",
  "draftBadge",
  "publishMain",
  "publishing",
  "publishReply",
  "ownerOnly",
  "showAll",
  "continueSupplement",
  "returnToLake",
  "archivedNotice",
  "mainPhotoAlt",
  "replyPhotoAlt"
] as const;

const NETWORK_ERROR_KEYS = [
  "title",
  "body",
  "openControlCenter",
  "returnToLake",
  "keepEditing"
] as const;

function readThreadCopy(): JournalThreadCopy {
  const journal = asRecord((qizhenContent as { journal?: unknown }).journal);
  const thread = asRecord(journal?.thread);
  const network = asRecord(thread?.networkError);
  const copy = {} as Record<(typeof THREAD_COPY_KEYS)[number], string>;
  for (const key of THREAD_COPY_KEYS) {
    copy[key] = asString(thread?.[key]);
  }
  const networkError = {} as Record<(typeof NETWORK_ERROR_KEYS)[number], string>;
  for (const key of NETWORK_ERROR_KEYS) {
    networkError[key] = asString(network?.[key]);
  }
  return { ...copy, networkError };
}

const THREAD_COPY = readThreadCopy();
const SPOT_NAMES = readStringMap(
  asRecord((qizhenContent as { journal?: unknown }).journal)?.spotNames
);

const personas = new Map(personaData.map((persona) => [persona.id, persona]));

/** CC98 原生观感的启真湖记录单帖页;发帖/补充事务全部由宿主回调驱动。 */
export function QizhenJournalThread(props: QizhenJournalThreadProps) {
  const {
    view,
    canPublishMain,
    publishableSpotIds,
    networkError,
    onPublishMain,
    onPublishReply,
    onOpenControlCenter,
    onReturnToLake,
    onKeepEditing,
    onBack
  } = props;
  const copy = THREAD_COPY;
  const board = view.board !== "" ? view.board : copy.board;
  const archived = view.archived;
  const isMainDraft = view.status === "main_draft";
  const isOpen = view.status === "open";

  /* 「只看楼主」是纯显示过滤:只隐藏路人楼层,楼层号与顺序保持不变。 */
  const [ownerOnly, setOwnerOnly] = useState(false);
  /* 照片详情浮层:与楼层共用 recipe 重建,关闭后楼层内容原样保留。 */
  const [detailPhoto, setDetailPhoto] = useState<QizhenPhotoRecord | null>(null);
  /* 发布主帖的瞬时防连点状态;真正去重由 controller 幂等键负责。 */
  const [publishing, setPublishing] = useState(false);
  const detailCloseRef = useRef<HTMLButtonElement>(null);
  const keepEditingRef = useRef<HTMLButtonElement>(null);

  const replies = useMemo(
    () => [...view.replies].sort((a, b) => a.floor - b.floor),
    [view.replies]
  );
  const visibleReplies = ownerOnly
    ? replies.filter((reply) => reply.kind === "owner")
    : replies;

  useEffect(() => {
    setPublishing(false);
  }, [view]);

  useEffect(() => {
    if (networkError) {
      setPublishing(false);
    }
  }, [networkError]);

  useEffect(() => {
    if (!networkError && detailPhoto === null) {
      return;
    }
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key !== "Escape") {
        return;
      }
      event.preventDefault();
      /* Esc 优先关闭网络错误模态(继续编辑),其次关闭照片详情浮层。 */
      if (networkError) {
        onKeepEditing();
      } else {
        setDetailPhoto(null);
      }
    }
    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, [networkError, detailPhoto, onKeepEditing]);

  useEffect(() => {
    if (networkError) {
      keepEditingRef.current?.focus();
    }
  }, [networkError]);

  useEffect(() => {
    if (detailPhoto !== null) {
      detailCloseRef.current?.focus();
    }
  }, [detailPhoto]);

  const handlePublishMain = () => {
    setPublishing(true);
    onPublishMain();
  };

  return (
    <section
      aria-label={`${board}:${view.title}`}
      className="cc98-thread-page cc98-journal-thread"
    >
      <header className="cc98-thread-header">
        <PhoneNavButton kind="back" label={board} onClick={onBack} />
        <h1>{board}</h1>
        <div className="cc98-thread-capsule">
          <span aria-hidden="true">•••</span>
          <i aria-hidden="true" />
          <span aria-hidden="true">−</span>
          <i aria-hidden="true" />
          <PhoneNavButton
            className="cc98-thread-close"
            glyph={<b aria-hidden="true" />}
            kind="close"
            label={board}
            onClick={onBack}
            title={board}
          />
        </div>
      </header>

      <main className="cc98-thread-scroll">
        {archived ? (
          <div className="cc98-thread-lock-notice" role="status">
            {copy.archivedNotice}
          </div>
        ) : null}

        <header className="cc98-thread-title">
          <span>{board}</span>
          <h2>
            {view.title}
            {isMainDraft ? (
              <i className="cc98-journal-draft-badge">{copy.draftBadge}</i>
            ) : null}
          </h2>
        </header>

        <article className="cc98-thread-card is-owner cc98-journal-main">
          <header className="cc98-floor-header">
            <span className="cc98-thread-avatar anonymous" aria-hidden="true" />
            <div>
              <strong>{copy.authorRole}</strong>
            </div>
            <em>{copy.authorRole}</em>
            <b>1楼</b>
          </header>
          {view.mainPhoto ? (
            <figure className="cc98-journal-photo">
              <QizhenRecipeFrame
                alt={copy.mainPhotoAlt}
                recipe={view.mainPhoto.recipe}
                variant="full"
              />
            </figure>
          ) : null}
          {view.mainCaption ? <p>{view.mainCaption}</p> : null}
          <footer className="cc98-journal-status" role="status">
            {view.statusText}
          </footer>
        </article>

        <div className="cc98-reply-filter cc98-journal-filter">
          <button
            aria-pressed={ownerOnly}
            className={ownerOnly ? "is-active" : ""}
            onClick={() => setOwnerOnly(true)}
            type="button"
          >
            {copy.ownerOnly}
          </button>
          <button
            aria-pressed={!ownerOnly}
            className={ownerOnly ? "" : "is-active"}
            onClick={() => setOwnerOnly(false)}
            type="button"
          >
            {copy.showAll}
          </button>
        </div>

        {visibleReplies.map((reply) => {
          if (reply.kind === "owner") {
            return (
              <article
                className="cc98-thread-card is-owner cc98-journal-owner-reply"
                key={reply.id}
              >
                <header className="cc98-floor-header">
                  <span className="cc98-thread-avatar anonymous" aria-hidden="true" />
                  <div>
                    <strong>{copy.authorRole}</strong>
                  </div>
                  <em>{copy.authorRole}</em>
                  <b>{reply.floor}楼</b>
                </header>
                {reply.text ? <p>{reply.text}</p> : null}
                {reply.photo ? (
                  <button
                    aria-label={copy.replyPhotoAlt}
                    className="cc98-journal-photo-thumb"
                    onClick={() => setDetailPhoto(reply.photo)}
                    type="button"
                  >
                    <QizhenRecipeFrame recipe={reply.photo.recipe} variant="thumb" />
                  </button>
                ) : null}
              </article>
            );
          }
          const persona = personas.get(reply.personaId ?? "");
          return (
            <article className="cc98-thread-card" key={reply.id}>
              <header className="cc98-floor-header">
                <span
                  aria-hidden="true"
                  className={`cc98-thread-avatar persona-${persona?.avatar ?? "anonymous"}`}
                />
                <div>
                  <strong>{persona?.nickname ?? reply.personaId ?? ""}</strong>
                </div>
                <b>{reply.floor}楼</b>
              </header>
              {reply.text ? <p>{reply.text}</p> : null}
              <footer aria-hidden="true" className="cc98-thread-metrics compact">
                <span>♧ {reply.likes}</span>
              </footer>
            </article>
          );
        })}

        {!archived && isMainDraft && canPublishMain ? (
          <section className="cc98-journal-actions">
            <button
              className="cc98-journal-primary"
              disabled={publishing}
              onClick={handlePublishMain}
              type="button"
            >
              {publishing ? copy.publishing : copy.publishMain}
            </button>
          </section>
        ) : null}

        {!archived && isOpen && publishableSpotIds.length > 0 ? (
          <section className="cc98-journal-pending-list">
            {publishableSpotIds.map((spotId) => {
              /* 投影只携带当前 pendingDraft 的 recipe;其余已拍未发布地点
                 暂无 recipe 源,卡片退化为地点名 + 追加钮,不编造画面。 */
              const pendingPhoto =
                view.pendingDraft !== null && view.pendingDraft.photo.spotId === spotId
                  ? view.pendingDraft.photo
                  : null;
              return (
                <article
                  className="cc98-thread-card cc98-journal-pending-card"
                  key={spotId}
                >
                  <header className="cc98-journal-pending-head">
                    <i className="cc98-journal-draft-badge">{copy.draftBadge}</i>
                    <strong>{SPOT_NAMES[spotId] ?? ""}</strong>
                  </header>
                  {pendingPhoto ? (
                    <div className="cc98-journal-pending-photo">
                      <QizhenRecipeFrame
                        alt={copy.replyPhotoAlt}
                        recipe={pendingPhoto.recipe}
                        variant="thumb"
                      />
                    </div>
                  ) : null}
                  <button
                    className="cc98-journal-primary"
                    onClick={() => onPublishReply(spotId)}
                    type="button"
                  >
                    {copy.publishReply}
                  </button>
                </article>
              );
            })}
          </section>
        ) : null}

        {!archived && isOpen ? (
          <section className="cc98-journal-actions">
            <button
              className="cc98-journal-secondary"
              onClick={onReturnToLake}
              type="button"
            >
              {copy.continueSupplement}
            </button>
          </section>
        ) : null}
      </main>

      <footer className="cc98-journal-footer-bar">
        <button
          className="cc98-journal-secondary"
          onClick={onReturnToLake}
          type="button"
        >
          {copy.returnToLake}
        </button>
      </footer>

      {detailPhoto ? (
        <div
          className="cc98-journal-lightbox"
          onClick={() => setDetailPhoto(null)}
          role="presentation"
        >
          <div
            aria-label={copy.replyPhotoAlt}
            aria-modal="true"
            className="cc98-journal-lightbox-dialog"
            onClick={(event) => event.stopPropagation()}
            role="dialog"
          >
            <QizhenRecipeFrame
              alt={copy.replyPhotoAlt}
              recipe={detailPhoto.recipe}
              variant="full"
            />
            <button
              aria-label="×"
              className="cc98-journal-lightbox-close"
              onClick={() => setDetailPhoto(null)}
              ref={detailCloseRef}
              type="button"
            >
              ×
            </button>
          </div>
        </div>
      ) : null}

      {networkError ? (
        <div
          aria-label={copy.networkError.title}
          aria-modal="true"
          className="cc98-journal-network"
          role="alertdialog"
        >
          <div className="cc98-journal-network-dialog">
            <h3>{copy.networkError.title}</h3>
            <p>{copy.networkError.body}</p>
            <div className="cc98-journal-network-actions">
              <button
                className="cc98-journal-primary"
                onClick={onOpenControlCenter}
                type="button"
              >
                {copy.networkError.openControlCenter}
              </button>
              <button
                className="cc98-journal-secondary"
                onClick={onReturnToLake}
                type="button"
              >
                {copy.networkError.returnToLake}
              </button>
              <button
                className="cc98-journal-secondary"
                onClick={onKeepEditing}
                ref={keepEditingRef}
                type="button"
              >
                {copy.networkError.keepEditing}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </section>
  );
}
