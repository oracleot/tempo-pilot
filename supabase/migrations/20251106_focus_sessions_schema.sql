-- Create focus_sessions table to store synced Pomodoro sessions per user
CREATE TABLE IF NOT EXISTS focus_sessions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  planned_duration_minutes INTEGER NOT NULL,
  actual_duration_minutes INTEGER,
  session_type TEXT NOT NULL DEFAULT 'pomodoro',
  completed BOOLEAN NOT NULL DEFAULT FALSE,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Indexes to support sync windows and tombstone sweeps
CREATE INDEX IF NOT EXISTS idx_focus_sessions_user_updated_at
  ON focus_sessions (user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_focus_sessions_user_deleted_at
  ON focus_sessions (user_id, deleted_at)
  WHERE deleted_at IS NOT NULL;

-- Ensure updated_at reflects latest write
DROP TRIGGER IF EXISTS update_focus_sessions_updated_at ON focus_sessions;
CREATE TRIGGER update_focus_sessions_updated_at
  BEFORE UPDATE ON focus_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable row level security
ALTER TABLE focus_sessions ENABLE ROW LEVEL SECURITY;

-- RLS policies guard access per user
DROP POLICY IF EXISTS "Users can select own focus sessions" ON focus_sessions;
CREATE POLICY "Users can select own focus sessions"
  ON focus_sessions FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own focus sessions" ON focus_sessions;
CREATE POLICY "Users can insert own focus sessions"
  ON focus_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own focus sessions" ON focus_sessions;
CREATE POLICY "Users can update own focus sessions"
  ON focus_sessions FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own focus sessions" ON focus_sessions;
CREATE POLICY "Users can delete own focus sessions"
  ON focus_sessions FOR DELETE
  USING (auth.uid() = user_id);

COMMENT ON TABLE focus_sessions IS 'Pomodoro focus session records synced per user with LWW + tombstones.';
COMMENT ON COLUMN focus_sessions.metadata IS 'Optional client-provided metadata (string keys) kept per user.';
