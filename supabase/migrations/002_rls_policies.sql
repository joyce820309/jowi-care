-- ============================================================
-- Jowi Care — Row Level Security Policies
-- ============================================================

ALTER TABLE households          ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE cats                ENABLE ROW LEVEL SECURITY;
ALTER TABLE weight_records      ENABLE ROW LEVEL SECURITY;
ALTER TABLE foods               ENABLE ROW LEVEL SECURITY;
ALTER TABLE cat_food_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_records     ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications         ENABLE ROW LEVEL SECURITY;
ALTER TABLE vaccinations        ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders           ENABLE ROW LEVEL SECURITY;

-- Helper: 取得目前使用者的 household_id
CREATE OR REPLACE FUNCTION my_household_id()
RETURNS UUID LANGUAGE SQL STABLE AS $$
  SELECT household_id FROM profiles WHERE id = auth.uid()
$$;

-- households: 只能看到自己的家庭
CREATE POLICY "households_select" ON households
  FOR SELECT USING (id = my_household_id());

CREATE POLICY "households_insert" ON households
  FOR INSERT WITH CHECK (true);

-- profiles: 只能看到同家庭的成員
CREATE POLICY "profiles_select" ON profiles
  FOR SELECT USING (household_id = my_household_id());

CREATE POLICY "profiles_upsert" ON profiles
  FOR ALL USING (id = auth.uid());

-- cats: 同家庭可讀寫
CREATE POLICY "cats_all" ON cats
  FOR ALL USING (household_id = my_household_id());

-- weight_records: 透過 cat 的 household 驗證
CREATE POLICY "weight_records_all" ON weight_records
  FOR ALL USING (
    cat_id IN (SELECT id FROM cats WHERE household_id = my_household_id())
  );

-- foods: 同家庭可讀寫
CREATE POLICY "foods_all" ON foods
  FOR ALL USING (household_id = my_household_id());

-- cat_food_preferences
CREATE POLICY "cat_food_preferences_all" ON cat_food_preferences
  FOR ALL USING (
    cat_id IN (SELECT id FROM cats WHERE household_id = my_household_id())
  );

-- medical_records
CREATE POLICY "medical_records_all" ON medical_records
  FOR ALL USING (
    cat_id IN (SELECT id FROM cats WHERE household_id = my_household_id())
  );

-- medications: 透過 medical_record 驗證
CREATE POLICY "medications_all" ON medications
  FOR ALL USING (
    medical_record_id IN (
      SELECT mr.id FROM medical_records mr
      JOIN cats c ON c.id = mr.cat_id
      WHERE c.household_id = my_household_id()
    )
  );

-- vaccinations
CREATE POLICY "vaccinations_all" ON vaccinations
  FOR ALL USING (
    cat_id IN (SELECT id FROM cats WHERE household_id = my_household_id())
  );

-- reminders
CREATE POLICY "reminders_all" ON reminders
  FOR ALL USING (household_id = my_household_id());
