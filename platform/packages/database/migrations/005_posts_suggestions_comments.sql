-- Keep legacy posts, permissions and vote history. New entries have explicit channels.
ALTER TABLE ideas DROP CONSTRAINT ideas_channel_check;
ALTER TABLE ideas ADD CONSTRAINT ideas_channel_check
  CHECK (channel IN ('chapter','feedback','story','post','suggestion'));
CREATE TABLE idea_comments (
  id uuid PRIMARY KEY,
  idea_id uuid NOT NULL REFERENCES ideas(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES members(id),
  body text NOT NULL CHECK (length(btrim(body)) BETWEEN 1 AND 2000),
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);
CREATE INDEX idea_comments_visible_idx ON idea_comments(idea_id, created_at, id)
  WHERE deleted_at IS NULL;
