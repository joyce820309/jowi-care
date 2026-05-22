# Jowi Care — 開發啟動文件
> 雙貓健康管理 App｜Flutter + Supabase

---

## 專案概覽

| 項目 | 內容 |
|------|------|
| 專案名稱 | `jowi-care` |
| App 顯示名稱 | Jowi Care |
| Flutter package | `com.yourname.jowicare` |
| GitHub Repo | `jowi-care` |
| Supabase 專案 | `jowi-care` |
| 開發工具 | VS Code + Flutter extension |
| 後端 | Supabase（PostgreSQL + Auth + Realtime） |
| 推播通知 | OneSignal（免費方案） |
| 目標平台 | iOS（iPhone）、macOS（MacBook） |
| 開發環境 | Windows 日常開發 / MacBook 負責 iOS build |
| 手機安裝方式 | USB 線直接安裝（初期）→ AltStore 自動續簽（穩定後） |

---

## 使用者情境

- 飼主兩人（你與另一半），共用同一份資料，即時同步
- 兩隻貓：**Joy**、**Wiki**（合稱 **Jowi**）
- 使用裝置：iPhone、MacBook

---

## 核心功能需求

### 1. 貓咪基本資料
- 名字、品種、生日、性別、結紮狀態、晶片號碼
- 大頭照上傳

### 2. 體重紀錄
- 手動輸入體重（kg）
- 折線圖顯示成長趨勢（依時間軸）
- 支援單貓查看 / 雙貓比較

### 3. 飲食偏好管理
- 記錄每隻貓「喜歡」或「不喜歡」的飼料、罐頭
- 標記為「共同喜好」或「個別喜好」
- 備註欄（例如：「Wiki 只吃湯汁」）

### 4. 食品資料庫 + 營養計算機
- 模糊搜尋商品名稱（支援中英文半形輸入）
- 手動新增商品（品牌、品名、口味、成分）
- 自動計算：
  - **熱量**（kcal/100g）
  - **鈣磷比**（Ca : P）
  - **碳水乾物比**（%DM）
  - **蛋白質乾物比**（%DM）
  - **脂肪乾物比**（%DM）
- 計算公式（乾物比）：
  ```
  乾物比(%) = 成分(%) ÷ (100 - 水分%) × 100
  ```
更多公式請參考 formula.md

### 5. 醫療紀錄
- 就診日期、診所、獸醫師
- 診斷、處置、用藥（藥名、劑量、療程天數）
- 疫苗紀錄（疫苗名稱、施打日、下次預約日）
- 附件上傳（檢查報告圖片 / PDF）

### 6. 提醒系統（推播通知）
- 每日換水提醒（可設定時間）
- 定期健檢提醒（可設定間隔，例如每 6 個月）
- 疫苗到期提醒
- 自訂提醒（名稱 + 日期 + 重複週期）

### 7. 多人共編
- 使用 Supabase Auth（Google / Apple 登入）
- 邀請另一半加入同一個「家庭帳號」
- 所有資料即時同步（Supabase Realtime）

---

## 資料庫結構（Supabase / PostgreSQL）

```sql
-- 家庭帳號
households (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
)

-- 使用者（對應 Supabase Auth）
profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users,
  household_id  UUID REFERENCES households(id),
  display_name  TEXT,
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ DEFAULT now()
)

-- 貓咪基本資料
cats (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id  UUID REFERENCES households(id),
  name          TEXT NOT NULL,            -- 'Joy' | 'Wiki'
  breed         TEXT,
  birthday      DATE,
  gender        TEXT CHECK (gender IN ('male', 'female')),
  is_neutered   BOOLEAN DEFAULT false,
  chip_number   TEXT,
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ DEFAULT now()
)

-- 體重紀錄
weight_records (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cat_id      UUID REFERENCES cats(id),
  weight_kg   NUMERIC(4,2) NOT NULL,
  recorded_at DATE NOT NULL,
  note        TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
)

-- 食品資料庫
foods (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    UUID REFERENCES households(id),
  brand           TEXT,
  name            TEXT NOT NULL,
  flavor          TEXT,
  food_type       TEXT CHECK (food_type IN ('dry', 'wet', 'freeze_dried', 'treat')),
  -- 成分（每 100g 為基準）
  moisture_pct    NUMERIC(5,2),   -- 水分 %
  protein_pct     NUMERIC(5,2),   -- 蛋白質 %
  fat_pct         NUMERIC(5,2),   -- 脂肪 %
  carbs_pct       NUMERIC(5,2),   -- 碳水化合物 %
  ash_pct         NUMERIC(5,2),   -- 粗灰分 %
  calcium_pct     NUMERIC(5,2),   -- 鈣 %
  phosphorus_pct  NUMERIC(5,2),   -- 磷 %
  calories_per_100g NUMERIC(6,1), -- 熱量 kcal
  -- 計算欄（Generated Column）
  ca_p_ratio      NUMERIC(5,2) GENERATED ALWAYS AS
                    (CASE WHEN phosphorus_pct > 0
                     THEN ROUND(calcium_pct / phosphorus_pct, 2)
                     ELSE NULL END) STORED,
  carbs_dm_pct    NUMERIC(5,2) GENERATED ALWAYS AS
                    (CASE WHEN moisture_pct < 100
                     THEN ROUND(carbs_pct / (100 - moisture_pct) * 100, 2)
                     ELSE NULL END) STORED,
  note            TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
)

-- 貓咪飲食偏好
cat_food_preferences (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cat_id      UUID REFERENCES cats(id),
  food_id     UUID REFERENCES foods(id),
  preference  TEXT CHECK (preference IN ('love', 'like', 'neutral', 'dislike')),
  note        TEXT,                       -- '只吃湯汁'
  created_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE(cat_id, food_id)
)

-- 醫療紀錄
medical_records (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cat_id        UUID REFERENCES cats(id),
  visited_at    DATE NOT NULL,
  clinic_name   TEXT,
  vet_name      TEXT,
  diagnosis     TEXT,
  treatment     TEXT,
  note          TEXT,
  attachments   TEXT[],                   -- Supabase Storage URLs
  created_at    TIMESTAMPTZ DEFAULT now()
)

-- 用藥紀錄
medications (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  medical_record_id UUID REFERENCES medical_records(id),
  name              TEXT NOT NULL,
  dosage            TEXT,
  duration_days     INTEGER,
  note              TEXT
)

-- 疫苗紀錄
vaccinations (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cat_id        UUID REFERENCES cats(id),
  vaccine_name  TEXT NOT NULL,
  vaccinated_at DATE NOT NULL,
  next_due_at   DATE,
  clinic_name   TEXT,
  note          TEXT,
  created_at    TIMESTAMPTZ DEFAULT now()
)

-- 提醒設定
reminders (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    UUID REFERENCES households(id),
  cat_id          UUID REFERENCES cats(id),  -- NULL = 全家共用
  title           TEXT NOT NULL,
  reminder_type   TEXT CHECK (reminder_type IN
                    ('water', 'checkup', 'vaccine', 'custom')),
  remind_at       TIME,                       -- 每日提醒時間
  repeat_interval INTEGER,                    -- 重複天數（null = 不重複）
  next_remind_at  TIMESTAMPTZ,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now()
)
```

---

## 主題色系

App 支援兩套主題，使用者可在設定頁切換。

### 主題一：奶茶暖沙 · Warm Sand

```dart
// lib/theme/warm_sand.dart
const warmSand = {
  'background':  '#F5F0E8',  // 主背景
  'surface':     '#E8DDD0',  // 卡片 / 次要背景
  'primary':     '#C4A882',  // 主色調（按鈕、強調）
  'secondary':   '#9BAF9B',  // 輔色（標籤、成功狀態）
  'text':        '#3D3028',  // 主要文字
  'textMuted':   '#6B5C4E',  // 次要文字
  'border':      '#D5C8BA',  // 邊框
  'pillFood':    '#E8DDD0',  // 飲食標籤底色
  'pillFoodTxt': '#6B5C4E',  // 飲食標籤文字
  'pillTag':     '#D8E8D8',  // 功能標籤底色
  'pillTagTxt':  '#4A6B4A',  // 功能標籤文字
  'avatarBg':    '#E8DDD0',  // 頭像背景
  'avatarTxt':   '#6B5C4E',  // 頭像文字
};
```

### 主題二：晨霧藍灰 · Mist Blue

```dart
// lib/theme/mist_blue.dart
const mistBlue = {
  'background':  '#F0F2F5',  // 主背景
  'surface':     '#DDE3EC',  // 卡片 / 次要背景
  'primary':     '#8AA5C2',  // 主色調（按鈕、強調）
  'secondary':   '#A8BAA8',  // 輔色（標籤、成功狀態）
  'text':        '#1E2D3D',  // 主要文字
  'textMuted':   '#3D4E5E',  // 次要文字
  'border':      '#C8D0DC',  // 邊框
  'pillFood':    '#DDE3EC',  // 飲食標籤底色
  'pillFoodTxt': '#3D4E5E',  // 飲食標籤文字
  'pillTag':     '#C8D8C8',  // 功能標籤底色
  'pillTagTxt':  '#3A5A3A',  // 功能標籤文字
  'avatarBg':    '#DDE3EC',  // 頭像背景
  'avatarTxt':   '#3D4E5E',  // 頭像文字
};
```

---

## 技術架構

```
jowi-care/
├── lib/
│   ├── main.dart
│   ├── theme/
│   │   ├── warm_sand.dart
│   │   └── mist_blue.dart
│   ├── models/          # Cat, Food, WeightRecord, MedicalRecord...
│   ├── services/
│   │   ├── supabase_service.dart
│   │   └── notification_service.dart   # OneSignal
│   ├── providers/       # Riverpod / Provider 狀態管理
│   └── screens/
│       ├── home/        # 首頁（今日提醒、兩貓概覽）
│       ├── cats/        # 貓咪詳細頁
│       ├── food/        # 食品資料庫 + 搜尋 + 計算機
│       ├── medical/     # 醫療紀錄
│       └── settings/    # 主題切換、提醒設定、帳號
├── supabase/
│   └── migrations/      # SQL 建表語法
└── pubspec.yaml
```

### 主要套件

```yaml
dependencies:
  supabase_flutter: ^2.x      # Supabase 官方 Flutter SDK
  riverpod / flutter_riverpod # 狀態管理（推薦）
  go_router:                  # 路由
  fl_chart:                   # 體重折線圖
  onesignal_flutter:          # 推播通知
  image_picker:               # 照片上傳
  fuzzy:                      # 本地模糊搜尋（補強 Supabase ILIKE）
  intl:                       # 日期格式化
```

---

## 食品模糊搜尋策略

```sql
-- Supabase 側：ILIKE 模糊搜尋（中英文皆支援）
SELECT * FROM foods
WHERE household_id = $1
  AND (
    name ILIKE '%' || $2 || '%'
    OR brand ILIKE '%' || $2 || '%'
    OR flavor ILIKE '%' || $2 || '%'
  )
ORDER BY name;
```

Flutter 側再用 `fuzzy` 套件對結果做二次排序，讓「最像」的排最前面。

---

## 開發順序建議

1. **環境建置**：Flutter SDK、VS Code 擴充、Supabase 帳號
2. **Supabase 建表**：依上方 SQL 建立所有 Table + RLS 政策
3. **Auth 流程**：Google / Apple 登入 + 建立 household
4. **貓咪主頁**：兩貓卡片、體重輸入、折線圖
5. **食品資料庫**：新增商品、搜尋、營養計算
6. **醫療紀錄**：就診、疫苗、附件上傳
7. **提醒系統**：OneSignal 整合、換水 / 健檢通知
8. **主題切換**：Warm Sand / Mist Blue
9. **iOS Build**：切換到 MacBook → `flutter run --release` → USB 線安裝到 iPhone
   - 初期：USB 接線安裝（免費 Apple ID 即可，7 天後需重裝）
   - 穩定後：改用 AltStore，Mac 在家開著，每 7 天 Wi-Fi 自動續簽
   - 出門用 5G 正常 CRUD，不影響 App 運作

---

*最後更新：初版啟動文件 | 貓咪：Joy & Wiki 🐱🐱*
