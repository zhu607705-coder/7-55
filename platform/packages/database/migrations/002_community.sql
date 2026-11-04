CREATE TABLE members (
  id uuid PRIMARY KEY,
  username text NOT NULL UNIQUE CHECK (username ~ '^[a-z0-9_]{3,24}$'),
  nickname text NOT NULL CHECK (length(nickname) BETWEEN 1 AND 24),
  password_hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE sessions (
  token_hash text PRIMARY KEY CHECK (token_hash ~ '^[a-f0-9]{64}$'),
  member_id uuid NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX sessions_member_idx ON sessions(member_id);
CREATE INDEX sessions_expiry_idx ON sessions(expires_at);
CREATE TABLE ideas (
  id uuid PRIMARY KEY,
  author_id uuid NOT NULL REFERENCES members(id),
  chapter_id text NOT NULL REFERENCES chapters(id),
  title text NOT NULL CHECK (length(title) BETWEEN 4 AND 100),
  body text NOT NULL CHECK (length(body) BETWEEN 10 AND 10000),
  category text NOT NULL CHECK (category IN ('story', 'gameplay', 'experience')),
  spoiler boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);
CREATE INDEX ideas_visible_idx ON ideas(created_at DESC, id DESC) WHERE deleted_at IS NULL;
CREATE INDEX ideas_chapter_idx ON ideas(chapter_id) WHERE deleted_at IS NULL;
CREATE INDEX ideas_author_idx ON ideas(author_id) WHERE deleted_at IS NULL;
CREATE TABLE idea_likes (
  idea_id uuid NOT NULL REFERENCES ideas(id) ON DELETE CASCADE,
  member_id uuid NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (idea_id, member_id)
);
CREATE TABLE idea_ratings (
  idea_id uuid NOT NULL REFERENCES ideas(id) ON DELETE CASCADE,
  member_id uuid NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  score smallint NOT NULL CHECK (score BETWEEN 1 AND 5),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (idea_id, member_id)
);
-- Atomic per-identity windows persist across restarts and multiple API processes.
-- Keys contain SHA-256 digests, never raw IPs or usernames.
CREATE TABLE request_limits (
  key text PRIMARY KEY,
  hits integer NOT NULL CHECK (hits > 0),
  expires_at timestamptz NOT NULL
);
CREATE INDEX request_limits_expiry_idx ON request_limits(expires_at);
