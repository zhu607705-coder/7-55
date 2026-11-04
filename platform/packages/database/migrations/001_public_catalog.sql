CREATE TABLE chapters (
  id text PRIMARY KEY CHECK (id ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  title text NOT NULL CHECK (length(title) BETWEEN 1 AND 80),
  description text NOT NULL DEFAULT '' CHECK (length(description) <= 500),
  sort_order integer NOT NULL CHECK (sort_order >= 0),
  kind text NOT NULL CHECK (kind IN ('chapter', 'future', 'general')),
  is_public boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Public discussion scopes, not release claims or source story exports.
INSERT INTO chapters (id, title, description, sort_order, kind, is_public) VALUES
  ('chapter-1', '第一章', '围绕第一章的故事与体验交流。', 10, 'chapter', true),
  ('chapter-2', '第二章', '围绕第二章的故事与体验交流。', 20, 'chapter', true),
  ('chapter-3', '第三章', '围绕第三章的故事与体验交流。', 30, 'chapter', true),
  ('chapter-3-5', '章节间奏', '围绕第三章与第四章之间的体验交流。', 35, 'chapter', true),
  ('chapter-4', '第四章', '围绕第四章的故事与体验交流。', 40, 'chapter', true),
  ('future', '后续章节', '分享你希望在接下来的故事里遇见什么。', 50, 'future', true),
  ('general', '整体体验', '讨论操作、阅读和跨章节的体验。', 60, 'general', true);
