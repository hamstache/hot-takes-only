-- Hot Takes Only — Initial Schema
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New Query)

-- ─── Tables ────────────────────────────────────────────────────────────────

CREATE TABLE rooms (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            TEXT UNIQUE NOT NULL,
    status          TEXT NOT NULL DEFAULT 'waiting',
    current_round   INT  NOT NULL DEFAULT 0,
    judge_index     INT  NOT NULL DEFAULT 0,
    black_card_index INT NOT NULL DEFAULT 0,
    max_rounds      INT  NOT NULL DEFAULT 5,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE players (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id       UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    display_name  TEXT NOT NULL,
    score         INT  NOT NULL DEFAULT 0,
    is_host       BOOLEAN NOT NULL DEFAULT FALSE,
    hand_indices  INTEGER[] NOT NULL DEFAULT '{}',
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE submissions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id       UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    player_id     UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    round_number  INT  NOT NULL,
    card_index    INT  NOT NULL,
    is_winner     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (room_id, player_id, round_number)
);

-- ─── Indexes ───────────────────────────────────────────────────────────────

CREATE INDEX idx_players_room_id ON players(room_id);
CREATE INDEX idx_submissions_room_id ON submissions(room_id);
CREATE INDEX idx_submissions_round ON submissions(room_id, round_number);

-- ─── Row Level Security ────────────────────────────────────────────────────
-- Prototype policy: open access. Tighten per-player in production.

ALTER TABLE rooms       ENABLE ROW LEVEL SECURITY;
ALTER TABLE players     ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rooms_all"       ON rooms       FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "players_all"     ON players     FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "submissions_all" ON submissions FOR ALL USING (true) WITH CHECK (true);

-- ─── Realtime ──────────────────────────────────────────────────────────────
-- Enable postgres_changes for all three tables.
-- Requires: Supabase Dashboard → Database → Replication → supabase_realtime publication

ALTER PUBLICATION supabase_realtime ADD TABLE rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE players;
ALTER PUBLICATION supabase_realtime ADD TABLE submissions;

-- ─── Helper Function ───────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION generate_room_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    code  TEXT := '';
    i     INT;
BEGIN
    FOR i IN 1..6 LOOP
        code := code || substr(chars, floor(random() * length(chars) + 1)::INT, 1);
    END LOOP;
    RETURN code;
END;
$$;
