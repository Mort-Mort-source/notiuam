CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(180) NOT NULL UNIQUE,
    password_hash   VARCHAR(100) NOT NULL,
    display_name    VARCHAR(120) NOT NULL,
    role            VARCHAR(20)  NOT NULL,
    enabled         BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ
);

CREATE TABLE channels (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         VARCHAR(120) NOT NULL,
    description  VARCHAR(500),
    category     VARCHAR(30)  NOT NULL,
    owner_id     UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_public    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_channels_public    ON channels(is_public);
CREATE INDEX idx_channels_category  ON channels(category);
CREATE INDEX idx_channels_owner     ON channels(owner_id);

CREATE TABLE posts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_id  UUID          NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    author_id   UUID          NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    content     VARCHAR(2000) NOT NULL,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_posts_channel_created ON posts(channel_id, created_at DESC);

CREATE TABLE subscriptions (
    user_id        UUID        NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    channel_id     UUID        NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    subscribed_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, channel_id)
);

CREATE INDEX idx_subs_channel ON subscriptions(channel_id);