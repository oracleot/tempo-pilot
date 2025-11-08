-- AI Chat Infrastructure: feature flags, ai_messages table
-- Migration for Week 5 AI Chat MVP
-- Assumes profiles table exists (from 20241105_create_profiles.sql)

-- 1. Create feature_flags table
CREATE TABLE IF NOT EXISTS feature_flags (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  audience JSONB,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default AI chat feature flag
INSERT INTO feature_flags (key, value, description)
VALUES ('ai_chat_enabled', 'true'::jsonb, 'Enable AI chat for tester cohort')
ON CONFLICT (key) DO NOTHING;

-- Insert other feature flags mentioned in architecture
INSERT INTO feature_flags (key, value, description) VALUES
  ('push_notifications_enabled', 'false'::jsonb, 'Enable push notifications for testers'),
  ('calendar_suggestions_enabled', 'false'::jsonb, 'Enable calendar-based suggestions'),
  ('debug_telemetry', 'false'::jsonb, 'Enable debug telemetry for internal users')
ON CONFLICT (key) DO NOTHING;

-- 2. Create ai_messages table for usage logging
CREATE TABLE IF NOT EXISTS ai_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN ('plan', 'replan', 'reflect')),
  tokens_in INT NOT NULL CHECK (tokens_in >= 0),
  tokens_out INT NOT NULL CHECK (tokens_out >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_ai_messages_user_created 
  ON ai_messages(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ai_messages_created 
  ON ai_messages(created_at DESC);

-- Enable RLS on ai_messages
ALTER TABLE ai_messages ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only read their own ai_messages
DROP POLICY IF EXISTS "Users can read own ai_messages" ON ai_messages;
CREATE POLICY "Users can read own ai_messages"
  ON ai_messages FOR SELECT
  USING (auth.uid() = user_id);

-- Service role can insert (for Edge Function logging)
-- No explicit policy needed as service role bypasses RLS

-- 3. Create devices table for push notifications (future use)
CREATE TABLE IF NOT EXISTS devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  fcm_token TEXT,
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, fcm_token)
);

CREATE INDEX IF NOT EXISTS idx_devices_user 
  ON devices(user_id);

ALTER TABLE devices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own devices" ON devices;
CREATE POLICY "Users can manage own devices"
  ON devices FOR ALL
  USING (auth.uid() = user_id);

-- 4. Create daily_metrics table for insights (future use)
CREATE TABLE IF NOT EXISTS daily_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  day DATE NOT NULL,
  focus_minutes INT DEFAULT 0,
  pomodoros INT DEFAULT 0,
  cap_hits INT DEFAULT 0,
  notif_taps INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, day)
);

CREATE INDEX IF NOT EXISTS idx_daily_metrics_user_day 
  ON daily_metrics(user_id, day DESC);

ALTER TABLE daily_metrics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own daily_metrics" ON daily_metrics;
CREATE POLICY "Users can read own daily_metrics"
  ON daily_metrics FOR SELECT
  USING (auth.uid() = user_id);

-- 5. Update trigger function (if not already exists from profiles migration)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_feature_flags_updated_at ON feature_flags;
CREATE TRIGGER update_feature_flags_updated_at
  BEFORE UPDATE ON feature_flags
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_daily_metrics_updated_at ON daily_metrics;
CREATE TRIGGER update_daily_metrics_updated_at
  BEFORE UPDATE ON daily_metrics
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 6. Add comments for documentation

COMMENT ON TABLE feature_flags IS 'Feature flags for progressive rollout and A/B testing';
COMMENT ON TABLE ai_messages IS 'AI usage logs (token counts only, no content) for quota enforcement';
COMMENT ON TABLE devices IS 'Device registration for push notifications';
COMMENT ON TABLE daily_metrics IS 'Daily aggregated metrics for insights screen';

COMMENT ON COLUMN ai_messages.kind IS 'Type of AI request: plan (initial), replan (adjust), reflect (review)';
