-- Authing is the only login authority. Keep old contributions, revoke old sessions.
DELETE FROM sessions;
ALTER TABLE members DROP COLUMN password_hash;
ALTER TABLE members ADD COLUMN progress_order integer NOT NULL DEFAULT 0 CHECK (progress_order >= 0);
CREATE TABLE external_identities (
  id uuid PRIMARY KEY,
  member_id uuid NOT NULL UNIQUE REFERENCES members(id),
  issuer text NOT NULL,
  subject text NOT NULL,
  UNIQUE (issuer, subject)
);
ALTER TABLE sessions ADD COLUMN identity_id uuid NOT NULL REFERENCES external_identities(id);
CREATE TABLE auth_transactions (
  state_hash text PRIMARY KEY,
  browser_hash text NOT NULL,
  verifier text NOT NULL,
  nonce text NOT NULL,
  return_to text NOT NULL,
  issuer text NOT NULL,
  client_id text NOT NULL,
  expires_at timestamptz NOT NULL
);
CREATE INDEX auth_transactions_expiry_idx ON auth_transactions(expires_at);
ALTER TABLE ideas DROP CONSTRAINT ideas_title_check;
ALTER TABLE ideas DROP CONSTRAINT ideas_body_check;
ALTER TABLE ideas ADD CHECK (length(title) BETWEEN 1 AND 100);
ALTER TABLE ideas ADD CHECK (length(body) BETWEEN 1 AND 10000);
ALTER TABLE ideas ADD COLUMN channel text NOT NULL DEFAULT 'story' CHECK (channel IN ('chapter','feedback','story'));
ALTER TABLE ideas ADD COLUMN anonymous boolean NOT NULL DEFAULT false;
ALTER TABLE ideas ADD COLUMN status text NOT NULL DEFAULT 'received' CHECK (status IN ('received','discussion','production','playable','published','closed'));
ALTER TABLE ideas ADD COLUMN revision integer NOT NULL DEFAULT 0;
ALTER TABLE ideas ADD COLUMN terms_version text;
-- Legacy entries do not acquire permission through migration.
ALTER TABLE ideas ADD COLUMN adaptation_consent boolean NOT NULL DEFAULT false;
ALTER TABLE ideas ADD COLUMN credit_mode text NOT NULL DEFAULT 'anonymous' CHECK (credit_mode IN ('anonymous','nickname','custom'));
ALTER TABLE ideas ADD COLUMN credit_name text NOT NULL DEFAULT '' CHECK (length(credit_name) <= 40);
ALTER TABLE ideas ADD COLUMN hidden_at timestamptz;
ALTER TABLE ideas ADD COLUMN production_started_at timestamptz;
CREATE INDEX ideas_queue_idx ON ideas(status, created_at DESC) WHERE deleted_at IS NULL;
CREATE TABLE idea_updates (
  id uuid PRIMARY KEY,
  idea_id uuid NOT NULL REFERENCES ideas(id),
  operator_id uuid NOT NULL REFERENCES members(id),
  status text NOT NULL CHECK (status IN ('received','discussion','production','playable','published','closed')),
  note text NOT NULL CHECK (length(note) BETWEEN 1 AND 3000),
  play_url text,
  version text,
  credit text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idea_updates_timeline_idx ON idea_updates(idea_id, created_at, id);
CREATE TABLE operator_audit (
  id uuid PRIMARY KEY,
  idea_id uuid NOT NULL REFERENCES ideas(id),
  operator_id uuid NOT NULL REFERENCES members(id),
  action text NOT NULL,
  reason text NOT NULL CHECK (length(reason) BETWEEN 1 AND 1000),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE permission_events (
  id uuid PRIMARY KEY,
  idea_id uuid NOT NULL REFERENCES ideas(id),
  author_id uuid NOT NULL REFERENCES members(id),
  adaptation_consent boolean NOT NULL,
  credit_mode text NOT NULL,
  credit_name text NOT NULL,
  terms_version text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
