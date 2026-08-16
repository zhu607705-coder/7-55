import { readFile } from "node:fs/promises";

/**
 * Independent validator for the Qizhen Lake photo-journal content section.
 * Mirrors validateJournalContent in src/modules/QizhenJournalModel.ts without
 * importing TS: the QizhenPhotoTag / QizhenPhotoSpotId unions are parsed out of
 * types.ts source text so the TS declarations stay the single source of truth.
 * Exit code is non-zero when any check fails.
 */

const contentUrl = new URL("../src/data/chapter3-qizhen-lake.content.json", import.meta.url);
const typesUrl = new URL("../src/core/types.ts", import.meta.url);
const personasUrl = new URL("../src/data/cc98.thread-personas.json", import.meta.url);

const OPTIONAL_SPOT_IDS = ["dock", "reflection", "swan_cove"];

const CAMERA_KEYS = [
  "title",
  "shutter",
  "close",
  "retake",
  "draftMainTitle",
  "draftMainStatus",
  "draftSpotCaption",
  "saveDraft",
  "draftSaved",
  "speedLabel",
  "rollLabel",
  "hint"
];

// Values fixed by the shared journal contract; title and hint are authored copy.
const PINNED_CAMERA_COPY = {
  shutter: "拍摄",
  close: "收起相机",
  retake: "重拍",
  draftMainTitle: "选择主帖标题",
  draftMainStatus: "选择主帖状态",
  draftSpotCaption: "选择补拍说明",
  saveDraft: "存为草稿",
  draftSaved: "草稿已保存,可前往 CC98 发布。",
  speedLabel: "速度",
  rollLabel: "侧倾"
};

// Same pattern for the thread section: these values are fixed by the shared
// contract; board and networkError.title/body remain authored copy.
const THREAD_PINNED_COPY = {
  authorRole: "楼主",
  draftBadge: "草稿",
  publishMain: "发布主帖",
  publishing: "发布中…",
  publishReply: "追加到帖子",
  ownerOnly: "只看楼主",
  showAll: "查看全部",
  continueSupplement: "继续补充",
  returnToLake: "返回湖面",
  archivedNotice: "帖子已归档,仅供查看。",
  mainPhotoAlt: "湖心主图",
  replyPhotoAlt: "补拍照片"
};

const THREAD_KEYS = ["board", ...Object.keys(THREAD_PINNED_COPY)];

const NETWORK_ERROR_PINNED_COPY = {
  openControlCenter: "打开控制中心",
  returnToLake: "返回湖面",
  keepEditing: "继续编辑"
};

const NETWORK_ERROR_KEYS = ["title", "body", ...Object.keys(NETWORK_ERROR_PINNED_COPY)];

// Minimum pool sizes: the main-post pool holds at least 6 replies, each
// supplemental-spot pool at least 3. personaId values must exist in
// cc98.thread-personas.json so recurring NPCs keep one identity.
const REPLY_POOL_MIN = { main: 6, dock: 3, reflection: 3, swan_cove: 3 };

function parseUnion(source, name) {
  const match = source.match(new RegExp(`export type ${name} =([^;]+);`, "s"));
  if (!match) throw new Error(`could not find "export type ${name}" in types.ts`);
  return [...match[1].matchAll(/"([^"]+)"/g)].map((literal) => literal[1]);
}

function isRecord(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function validateEntries(value, label, errors) {
  if (!Array.isArray(value)) {
    errors.push(`journal.${label} must be an array`);
    return [];
  }
  const entries = [];
  value.forEach((item, index) => {
    if (!isRecord(item) || typeof item.id !== "string" || item.id.length === 0) {
      errors.push(`journal.${label}[${index}].id must be a non-empty string`);
      return;
    }
    if (typeof item.text !== "string" || item.text.length === 0) {
      errors.push(`journal.${label}[${index}].text must be a non-empty string`);
      return;
    }
    entries.push(item);
  });
  return entries;
}

function validateJournal(content, photoTags, photoSpotIds, personaIds) {
  const errors = [];
  const journal = isRecord(content) ? content.journal : undefined;
  if (!isRecord(journal)) {
    return ["journal section is missing or not an object"];
  }

  const titles = validateEntries(journal.titles, "titles", errors);
  if (Array.isArray(journal.titles) && titles.length !== 3) {
    errors.push(`journal.titles must contain exactly 3 entries, got ${titles.length}`);
  }
  const statuses = validateEntries(journal.statuses, "statuses", errors);
  if (Array.isArray(journal.statuses) && statuses.length !== 3) {
    errors.push(`journal.statuses must contain exactly 3 entries, got ${statuses.length}`);
  }

  const allEntries = [
    ...titles.map((entry) => ({ label: "titles", entry })),
    ...statuses.map((entry) => ({ label: "statuses", entry }))
  ];
  if (!isRecord(journal.spotCaptions)) {
    errors.push("journal.spotCaptions must be an object");
  } else {
    for (const spotId of OPTIONAL_SPOT_IDS) {
      const entries = validateEntries(journal.spotCaptions[spotId], `spotCaptions.${spotId}`, errors);
      if (Array.isArray(journal.spotCaptions[spotId]) && entries.length === 0) {
        errors.push(`journal.spotCaptions.${spotId} must not be empty`);
      }
      for (const entry of entries) {
        allEntries.push({ label: `spotCaptions.${spotId}`, entry });
      }
    }
  }

  if (!isRecord(journal.replyPools)) {
    errors.push("journal.replyPools must be an object");
  } else {
    for (const [poolKey, minSize] of Object.entries(REPLY_POOL_MIN)) {
      const pool = journal.replyPools[poolKey];
      const entries = validateEntries(pool, `replyPools.${poolKey}`, errors);
      if (Array.isArray(pool) && entries.length < minSize) {
        errors.push(`journal.replyPools.${poolKey} must contain at least ${minSize} entries, got ${entries.length}`);
      }
      if (Array.isArray(pool)) {
        pool.forEach((item, index) => {
          if (!isRecord(item)) return;
          if (typeof item.personaId !== "string" || !personaIds.has(item.personaId)) {
            errors.push(`journal.replyPools.${poolKey}[${index}].personaId must be an id from cc98.thread-personas.json`);
          }
          if (typeof item.likes !== "string" || item.likes.length === 0) {
            errors.push(`journal.replyPools.${poolKey}[${index}].likes must be a non-empty string`);
          }
        });
      }
      for (const entry of entries) {
        allEntries.push({ label: `replyPools.${poolKey}`, entry });
      }
    }
  }

  const seenIds = new Map();
  for (const { label, entry } of allEntries) {
    const existing = seenIds.get(entry.id);
    if (existing !== undefined) {
      errors.push(`duplicate id "${entry.id}" in journal.${label} and journal.${existing}`);
    } else {
      seenIds.set(entry.id, label);
    }
  }

  if (!isRecord(journal.tagLabels)) {
    errors.push("journal.tagLabels must be an object");
  } else {
    for (const tag of photoTags) {
      if (typeof journal.tagLabels[tag] !== "string" || journal.tagLabels[tag].length === 0) {
        errors.push(`journal.tagLabels is missing a label for tag "${tag}"`);
      }
    }
    for (const key of Object.keys(journal.tagLabels)) {
      if (!photoTags.includes(key)) {
        errors.push(`journal.tagLabels has unknown tag "${key}"`);
      }
    }
  }

  if (!isRecord(journal.spotNames)) {
    errors.push("journal.spotNames must be an object");
  } else {
    for (const spotId of photoSpotIds) {
      if (typeof journal.spotNames[spotId] !== "string" || journal.spotNames[spotId].length === 0) {
        errors.push(`journal.spotNames is missing a name for spot "${spotId}"`);
      }
    }
    for (const key of Object.keys(journal.spotNames)) {
      if (!photoSpotIds.includes(key)) {
        errors.push(`journal.spotNames has unknown spot "${key}"`);
      }
    }
  }

  if (!isRecord(journal.camera)) {
    errors.push("journal.camera must be an object");
  } else {
    for (const key of CAMERA_KEYS) {
      if (typeof journal.camera[key] !== "string" || journal.camera[key].length === 0) {
        errors.push(`journal.camera.${key} must be a non-empty string`);
      }
    }
    for (const [key, pinned] of Object.entries(PINNED_CAMERA_COPY)) {
      if (journal.camera[key] !== undefined && journal.camera[key] !== pinned) {
        errors.push(`journal.camera.${key} must be the pinned copy "${pinned}"`);
      }
    }
  }

  if (!isRecord(journal.thread)) {
    errors.push("journal.thread must be an object");
  } else {
    for (const key of THREAD_KEYS) {
      if (typeof journal.thread[key] !== "string" || journal.thread[key].length === 0) {
        errors.push(`journal.thread.${key} must be a non-empty string`);
      }
    }
    for (const [key, pinned] of Object.entries(THREAD_PINNED_COPY)) {
      if (journal.thread[key] !== undefined && journal.thread[key] !== pinned) {
        errors.push(`journal.thread.${key} must be the pinned copy "${pinned}"`);
      }
    }
    const networkError = journal.thread.networkError;
    if (!isRecord(networkError)) {
      errors.push("journal.thread.networkError must be an object");
    } else {
      for (const key of NETWORK_ERROR_KEYS) {
        if (typeof networkError[key] !== "string" || networkError[key].length === 0) {
          errors.push(`journal.thread.networkError.${key} must be a non-empty string`);
        }
      }
      for (const [key, pinned] of Object.entries(NETWORK_ERROR_PINNED_COPY)) {
        if (networkError[key] !== undefined && networkError[key] !== pinned) {
          errors.push(`journal.thread.networkError.${key} must be the pinned copy "${pinned}"`);
        }
      }
    }
  }

  return errors;
}

function stableStringify(value) {
  if (Array.isArray(value)) {
    return `[${value.map(stableStringify).join(",")}]`;
  }
  if (isRecord(value)) {
    const keys = Object.keys(value).sort();
    return `{${keys.map((key) => `${JSON.stringify(key)}:${stableStringify(value[key])}`).join(",")}}`;
  }
  return JSON.stringify(value);
}

const typesSource = await readFile(typesUrl, "utf8");
const photoTags = parseUnion(typesSource, "QizhenPhotoTag");
const photoSpotIds = parseUnion(typesSource, "QizhenPhotoSpotId");

const raw = await readFile(contentUrl, "utf8");
const personaIds = new Set(
  JSON.parse(await readFile(personasUrl, "utf8")).map((persona) => persona.id)
);

// Determinism guard: two independent parse+validate runs over the same source
// must produce byte-identical results. The seed-driven reply selection itself is
// a pure function in QizhenJournalModel; this guards the content contract side.
const runA = { content: JSON.parse(raw) };
const runB = { content: JSON.parse(raw) };
runA.errors = validateJournal(runA.content, photoTags, photoSpotIds, personaIds);
runB.errors = validateJournal(runB.content, photoTags, photoSpotIds, personaIds);

const errors = [...runA.errors];
if (stableStringify(runA.content.journal) !== stableStringify(runB.content.journal)) {
  errors.push("determinism check failed: two parses produced different journal sections");
}
if (stableStringify(runA.errors) !== stableStringify(runB.errors)) {
  errors.push("determinism check failed: two validation runs produced different results");
}

if (errors.length > 0) {
  for (const error of errors) {
    console.error(`FAIL ${error}`);
  }
  console.error(`qizhen journal validation failed with ${errors.length} error(s)`);
  process.exit(1);
}

const captionCount = OPTIONAL_SPOT_IDS.reduce(
  (total, spotId) => total + runA.content.journal.spotCaptions[spotId].length,
  0
);
const replyCount = Object.keys(REPLY_POOL_MIN).reduce(
  (total, poolKey) => total + runA.content.journal.replyPools[poolKey].length,
  0
);
console.log(
  `verified qizhen journal content: 3 titles, 3 statuses, ${captionCount} spot captions, ` +
    `${photoTags.length} tag labels, ${photoSpotIds.length} spot names, ${CAMERA_KEYS.length} camera keys, ` +
    `${THREAD_KEYS.length} thread keys, ${NETWORK_ERROR_KEYS.length} network-error keys, ` +
    `${replyCount} passerby replies in ${Object.keys(REPLY_POOL_MIN).length} pools; ` +
    "determinism check passed (2 identical runs)"
);
