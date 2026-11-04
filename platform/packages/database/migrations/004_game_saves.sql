CREATE TABLE game_save_snapshots (
  id uuid PRIMARY KEY,
  member_id uuid NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  bundle jsonb NOT NULL,
  digest text NOT NULL CHECK (digest ~ '^[a-f0-9]{64}$'),
  source_version integer NOT NULL,
  bytes integer NOT NULL CHECK (bytes > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX game_save_snapshots_owner ON game_save_snapshots(member_id);
CREATE TABLE game_save_heads (
  member_id uuid PRIMARY KEY REFERENCES members(id) ON DELETE CASCADE,
  revision bigint NOT NULL DEFAULT 0 CHECK (revision >= 0),
  current_id uuid REFERENCES game_save_snapshots(id),
  previous_id uuid REFERENCES game_save_snapshots(id),
  before_restart_id uuid REFERENCES game_save_snapshots(id)
);
CREATE TABLE game_save_assets (
  member_id uuid NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  sha text NOT NULL CHECK (sha ~ '^[a-f0-9]{64}$'),
  data bytea NOT NULL CHECK (octet_length(data) <= 12582912),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (member_id,sha)
);
CREATE TABLE game_save_operations (
  member_id uuid NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  operation_id uuid NOT NULL,
  request_digest text NOT NULL,
  result jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (member_id,operation_id)
);
