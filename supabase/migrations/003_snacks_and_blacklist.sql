-- ============================================================
-- Jowi Care — Snacks & Blacklist
-- ============================================================

-- 零食資料表
CREATE TABLE snacks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    UUID REFERENCES households(id) ON DELETE CASCADE,
  brand           TEXT,
  name            TEXT NOT NULL,
  expires_at      DATE,
  liked_by        TEXT[] DEFAULT '{}',   -- e.g. ['Joy','Wiki']
  note            TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- 黑名單資料表
CREATE TABLE blacklist (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    UUID REFERENCES households(id) ON DELETE CASCADE,
  brand           TEXT,
  name            TEXT NOT NULL,
  reason          TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE snacks    ENABLE ROW LEVEL SECURITY;
ALTER TABLE blacklist ENABLE ROW LEVEL SECURITY;

CREATE POLICY "snacks_all" ON snacks
  FOR ALL USING (household_id = my_household_id());

CREATE POLICY "blacklist_all" ON blacklist
  FOR ALL USING (household_id = my_household_id());
