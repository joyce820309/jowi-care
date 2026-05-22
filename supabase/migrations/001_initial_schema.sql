-- ============================================================
-- Jowi Care — Initial Schema
-- ============================================================

-- 家庭帳號
CREATE TABLE households (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- 使用者（對應 Supabase Auth）
CREATE TABLE profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users,
  household_id  UUID REFERENCES households(id),
  display_name  TEXT,
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- 貓咪基本資料
CREATE TABLE cats (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id  UUID REFERENCES households(id),
  name          TEXT NOT NULL,
  breed         TEXT,
  birthday      DATE,
  gender        TEXT CHECK (gender IN ('male', 'female')),
  is_neutered   BOOLEAN DEFAULT false,
  chip_number   TEXT,
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- 體重紀錄
CREATE TABLE weight_records (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cat_id      UUID REFERENCES cats(id) ON DELETE CASCADE,
  weight_kg   NUMERIC(4,2) NOT NULL,
  recorded_at DATE NOT NULL,
  note        TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- 食品資料庫
CREATE TABLE foods (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id      UUID REFERENCES households(id),
  brand             TEXT,
  name              TEXT NOT NULL,
  flavor            TEXT,
  food_type         TEXT CHECK (food_type IN ('dry', 'wet', 'freeze_dried', 'treat')),
  moisture_pct      NUMERIC(5,2),
  protein_pct       NUMERIC(5,2),
  fat_pct           NUMERIC(5,2),
  carbs_pct         NUMERIC(5,2),
  ash_pct           NUMERIC(5,2),
  calcium_pct       NUMERIC(5,2),
  phosphorus_pct    NUMERIC(5,2),
  calories_per_100g NUMERIC(6,1),
  ca_p_ratio        NUMERIC(5,2) GENERATED ALWAYS AS (
                      CASE WHEN phosphorus_pct > 0
                      THEN ROUND(calcium_pct / phosphorus_pct, 2)
                      ELSE NULL END
                    ) STORED,
  carbs_dm_pct      NUMERIC(5,2) GENERATED ALWAYS AS (
                      CASE WHEN moisture_pct < 100
                      THEN ROUND(carbs_pct / (100 - moisture_pct) * 100, 2)
                      ELSE NULL END
                    ) STORED,
  note              TEXT,
  created_at        TIMESTAMPTZ DEFAULT now()
);

-- 貓咪飲食偏好
CREATE TABLE cat_food_preferences (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cat_id      UUID REFERENCES cats(id) ON DELETE CASCADE,
  food_id     UUID REFERENCES foods(id) ON DELETE CASCADE,
  preference  TEXT CHECK (preference IN ('love', 'like', 'neutral', 'dislike')),
  note        TEXT,
  created_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE(cat_id, food_id)
);

-- 醫療紀錄
CREATE TABLE medical_records (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cat_id      UUID REFERENCES cats(id) ON DELETE CASCADE,
  visited_at  DATE NOT NULL,
  clinic_name TEXT,
  vet_name    TEXT,
  diagnosis   TEXT,
  treatment   TEXT,
  note        TEXT,
  attachments TEXT[],
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- 用藥紀錄
CREATE TABLE medications (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  medical_record_id UUID REFERENCES medical_records(id) ON DELETE CASCADE,
  name              TEXT NOT NULL,
  dosage            TEXT,
  duration_days     INTEGER,
  note              TEXT
);

-- 疫苗紀錄
CREATE TABLE vaccinations (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cat_id        UUID REFERENCES cats(id) ON DELETE CASCADE,
  vaccine_name  TEXT NOT NULL,
  vaccinated_at DATE NOT NULL,
  next_due_at   DATE,
  clinic_name   TEXT,
  note          TEXT,
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- 提醒設定
CREATE TABLE reminders (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    UUID REFERENCES households(id),
  cat_id          UUID REFERENCES cats(id),
  title           TEXT NOT NULL,
  reminder_type   TEXT CHECK (reminder_type IN ('water', 'checkup', 'vaccine', 'custom')),
  remind_at       TIME,
  repeat_interval INTEGER,
  next_remind_at  TIMESTAMPTZ,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now()
);
