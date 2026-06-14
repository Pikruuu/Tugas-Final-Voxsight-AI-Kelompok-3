CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE accounts (
    id_akun         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    username        VARCHAR(50)  NOT NULL UNIQUE,
    email           VARCHAR(255) NOT NULL UNIQUE,
    password        VARCHAR(255) NOT NULL,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE users (
    id_user         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    id_akun         UUID         NOT NULL UNIQUE REFERENCES accounts(id_akun) ON DELETE CASCADE,
    nama_lengkap    VARCHAR(150) NOT NULL,
    nomor_handphone VARCHAR(20),
    alamat          TEXT,
    updated_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE devices (
    id_device       UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    id_akun         UUID         NOT NULL REFERENCES accounts(id_akun) ON DELETE CASCADE,
    is_active       BOOLEAN      NOT NULL DEFAULT FALSE,
    registered_at   TIMESTAMP    NOT NULL DEFAULT NOW(),
    last_seen       TIMESTAMP
);

CREATE TABLE device_cameras (
    id_camera       UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    id_device       UUID         NOT NULL REFERENCES devices(id_device) ON DELETE CASCADE,
    fps             NUMERIC(6,2),
    values_focus    NUMERIC(5,2) CHECK (values_focus BETWEEN 0 AND 100),
    value_clarity   NUMERIC(5,2) CHECK (value_clarity BETWEEN 0 AND 100),
    latency         NUMERIC(8,2),
    stream_url      TEXT,
    is_streaming    BOOLEAN      NOT NULL DEFAULT FALSE,
    recorded_at     TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE device_locations (
    id_lokasi       UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    id_device       UUID         NOT NULL REFERENCES devices(id_device) ON DELETE CASCADE,
    latitude        DECIMAL(10,7) NOT NULL,
    longitude       DECIMAL(10,7) NOT NULL,
    recorded_at     TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE monitoring (
    id_monitoring   UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    id_device       UUID         NOT NULL REFERENCES devices(id_device) ON DELETE CASCADE,
    suhu_cpu        NUMERIC(5,2),
    suhu_camera     NUMERIC(5,2),
    battery         NUMERIC(5,2) CHECK (battery BETWEEN 0 AND 100),
    paket_data      NUMERIC(10,2),
    internet_active BOOLEAN      NOT NULL DEFAULT FALSE,
    recorded_at     TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE password_reset_tokens (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    id_akun         UUID         NOT NULL REFERENCES accounts(id_akun) ON DELETE CASCADE,
    otp             VARCHAR(6)   NOT NULL,
    expires_at      TIMESTAMP    NOT NULL,
    used            BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE alerts (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    id_device       UUID         NOT NULL REFERENCES devices(id_device) ON DELETE CASCADE,
    alert_type      VARCHAR(50)  NOT NULL,
    severity        VARCHAR(20)  NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    message         TEXT,
    is_read         BOOLEAN      NOT NULL DEFAULT FALSE,
    triggered_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_devices_id_akun                ON devices(id_akun);
CREATE INDEX idx_device_cameras_id_device        ON device_cameras(id_device);
CREATE INDEX idx_device_cameras_recorded_at      ON device_cameras(recorded_at DESC);
CREATE INDEX idx_device_locations_id_device      ON device_locations(id_device);
CREATE INDEX idx_device_locations_recorded_at    ON device_locations(recorded_at DESC);
CREATE INDEX idx_monitoring_id_device            ON monitoring(id_device);
CREATE INDEX idx_monitoring_recorded_at          ON monitoring(recorded_at DESC);
CREATE INDEX idx_alerts_id_device                ON alerts(id_device);
CREATE INDEX idx_alerts_is_read                  ON alerts(is_read) WHERE is_read = FALSE;
CREATE INDEX idx_alerts_triggered_at             ON alerts(triggered_at DESC);
CREATE INDEX idx_password_reset_tokens_id_akun   ON password_reset_tokens(id_akun);

CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at_accounts
    BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

CREATE TRIGGER set_updated_at_users
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();