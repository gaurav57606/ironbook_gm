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

CREATE TABLE IF NOT EXISTS gym_owners (
    uid              TEXT         PRIMARY KEY,
    gym_name         TEXT         NOT NULL DEFAULT 'Unknown Gym',
    owner_name       TEXT,
    phone            TEXT,
    email            TEXT,
    address          TEXT,
    registered_at    TIMESTAMPTZ  DEFAULT NOW(),
    last_seen_at     TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gym_members (
    member_id        TEXT         NOT NULL,
    owner_uid        TEXT         NOT NULL REFERENCES gym_owners(uid)
                                  ON DELETE RESTRICT DEFERRABLE INITIALLY DEFERRED,
    name             TEXT         NOT NULL DEFAULT 'Unknown Member',
    phone            TEXT,
    gender           TEXT,
    age              INTEGER,
    plan_name        TEXT,
    join_date        TIMESTAMPTZ,
    expiry_date      TIMESTAMPTZ,
    last_updated_at  TIMESTAMPTZ  DEFAULT NOW(),
    PRIMARY KEY (member_id, owner_uid)
);

CREATE TABLE IF NOT EXISTS payment_events (
    event_id          TEXT         PRIMARY KEY,
    owner_uid         TEXT         NOT NULL,
    member_id         TEXT,
    member_name       TEXT,
    event_type        TEXT         DEFAULT 'paymentRecorded',
    plan_name         TEXT,
    amount            NUMERIC(12,2),
    payment_mode      TEXT,
    join_date         TIMESTAMPTZ,
    new_expiry_date   TIMESTAMPTZ,
    device_timestamp  TIMESTAMPTZ  DEFAULT NOW()
);

-- 2. Indexes for Performance

CREATE INDEX IF NOT EXISTS idx_users_archive_user_id ON users_archive(user_id);
CREATE INDEX IF NOT EXISTS idx_memberships_archive_member_id ON memberships_archive(member_id);
CREATE INDEX IF NOT EXISTS idx_payments_archive_transaction_id ON payments_archive(transaction_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_event_name ON activity_logs(event_name);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);

CREATE INDEX IF NOT EXISTS idx_gym_members_owner_uid     ON gym_members(owner_uid);
CREATE INDEX IF NOT EXISTS idx_gym_members_expiry        ON gym_members(expiry_date);
CREATE INDEX IF NOT EXISTS idx_payment_events_owner_uid  ON payment_events(owner_uid);
CREATE INDEX IF NOT EXISTS idx_payment_events_member_id  ON payment_events(member_id);
CREATE INDEX IF NOT EXISTS idx_payment_events_ts         ON payment_events(device_timestamp DESC);

-- 3. Row Level Security (RLS) Setup

ALTER TABLE users_archive ENABLE ROW LEVEL SECURITY;
ALTER TABLE memberships_archive ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments_archive ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE gym_owners    ENABLE ROW LEVEL SECURITY;
ALTER TABLE gym_members   ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_events ENABLE ROW LEVEL SECURITY;

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

-- gym_owners: upsert requires both INSERT and UPDATE policies
CREATE POLICY "anon_insert_gym_owners"
    ON gym_owners FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_update_gym_owners"
    ON gym_owners FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- gym_members: upsert requires both INSERT and UPDATE policies
CREATE POLICY "anon_insert_gym_members"
    ON gym_members FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_update_gym_members"
    ON gym_members FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- payment_events: append-only, INSERT only
CREATE POLICY "anon_insert_payment_events"
    ON payment_events FOR INSERT TO anon WITH CHECK (true);

-- No SELECT policies for anon ensures data privacy from client-side.
-- Admin dashboard access should use service_role or authenticated role with specific policies.
