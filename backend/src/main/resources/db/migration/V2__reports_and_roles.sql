-- ============================================================
-- V2: sistema de reportes, votación de admins y auditoría
-- ============================================================

-- Reportes de posts o canales
CREATE TABLE reports (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    target_type  VARCHAR(20)  NOT NULL CHECK (target_type IN ('POST', 'CHANNEL')),
    target_id    UUID         NOT NULL,
    reporter_id  UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason       VARCHAR(50)  NOT NULL,
    details      VARCHAR(500),
    status       VARCHAR(30)  NOT NULL DEFAULT 'PENDING',
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    resolved_at  TIMESTAMPTZ,
    resolved_by  UUID REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE (target_type, target_id, reporter_id)
);

CREATE INDEX idx_reports_status     ON reports(status);
CREATE INDEX idx_reports_target     ON reports(target_type, target_id);
CREATE INDEX idx_reports_created    ON reports(created_at DESC);

-- Votos de admins sobre reportes
CREATE TABLE report_votes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id   UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    admin_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    decision    VARCHAR(20) NOT NULL CHECK (decision IN ('KEEP', 'DELETE')),
    comment     VARCHAR(500),
    voted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (report_id, admin_id)
);

CREATE INDEX idx_votes_report ON report_votes(report_id);

-- Log de acciones administrativas
CREATE TABLE admin_action_log (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action       VARCHAR(50) NOT NULL,
    target_type  VARCHAR(20),
    target_id    UUID,
    details      VARCHAR(500),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_admin ON admin_action_log(admin_id, created_at DESC);
CREATE INDEX idx_audit_created ON admin_action_log(created_at DESC);