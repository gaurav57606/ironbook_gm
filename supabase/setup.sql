-- Supabase Monitoring Setup SQL
-- Architecture: Append-only, RLS-protected, Insert-only access.

-- 1. Tables Creation

-- Archive for user registration events
CREATE TABLE IF NOT EXISTS users_archive (
    id BIGSERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    email TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Archive for membership lifecycle events (creation/renewal)
CREATE TABLE IF NOT EXISTS memberships_archive (
    id BIGSERIAL PRIMARY KEY,
    member_id TEXT NOT NULL,
    plan_name TEXT,
    price NUMERIC(12, 2),
    event_type TEXT, -- 'created' or 'renewed'
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Archive for all payment transactions
CREATE TABLE IF NOT EXISTS payments_archive (
    id BIGSERIAL PRIMARY KEY,
    transaction_id TEXT NOT NULL,
    amount NUMERIC(12, 2),
    method TEXT,
    status TEXT, -- 'success' or 'failed'
    error_message TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- General activity logs for non-critical events
CREATE TABLE IF NOT EXISTS activity_logs (
    id BIGSERIAL PRIMARY KEY,
    event_name TEXT NOT NULL,
    payload JSONB DEFAULT '{}'::jsonb,
    severity TEXT DEFAULT 'info',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Audit logs for sensitive system actions
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    action TEXT NOT NULL,
    actor TEXT,
    details JSONB DEFAULT '{}'::jsonb,
    ip_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Indexes for Performance

CREATE INDEX IF NOT EXISTS idx_users_archive_user_id ON users_archive(user_id);
CREATE INDEX IF NOT EXISTS idx_memberships_archive_member_id ON memberships_archive(member_id);
CREATE INDEX IF NOT EXISTS idx_payments_archive_transaction_id ON payments_archive(transaction_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_event_name ON activity_logs(event_name);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);

-- 3. Row Level Security (RLS) Setup

ALTER TABLE users_archive ENABLE ROW LEVEL SECURITY;
ALTER TABLE memberships_archive ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments_archive ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- 4. Insert-Only Policies for Anon Users
-- Access restricted to INSERT only. SELECT/UPDATE/DELETE are forbidden for anon.

CREATE POLICY "Allow anon insert only" ON users_archive
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anon insert only" ON memberships_archive
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anon insert only" ON payments_archive
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anon insert only" ON activity_logs
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anon insert only" ON audit_logs
    FOR INSERT WITH CHECK (true);

-- No SELECT policies for anon ensures data privacy from client-side.
-- Admin dashboard access should use service_role or authenticated role with specific policies.
