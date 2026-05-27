# 設計師 README

本資料夾給 PM 與設計師了解 MVP 階段需要交付的產品設計、視覺方向、設計工具與四週工作分配。

## 角色目標

設計師負責定義使用者流程、畫面架構與視覺語言，讓低碳通勤紀錄不是只有數字，而是能用台北 / 校園綠化與植物成長的方式，讓使用者理解自己的減碳成果。

## 資料夾結構

目前 `design/` 先放設計工作文件；正式開始設計交付後，請依下列結構整理：

```text
design/
├─ README.md
├─ TASK.md
├─ assets/
│  ├─ icons/
│  ├─ illustrations/
│  ├─ animations/
│  └─ exports/
├─ wireframes/
│  ├─ auth/
│  ├─ trips/
│  └─ visual_state/
├─ mockups/
│  ├─ auth/
│  ├─ trips/
│  └─ visual_state/
└─ specs/
   ├─ screens.md
   ├─ components.md
   ├─ design_tokens.md
   └─ handoff_notes.md
```

資料夾用途：

- `assets/icons/`：icon 與小型符號。
- `assets/illustrations/`：植物、校園、城市綠化等插圖。
- `assets/animations/`：Rive、Lottie 或動畫參考。
- `assets/exports/`：交付給前端使用的最終輸出檔。
- `wireframes/`：低保真流程與畫面。
- `mockups/`：高保真畫面。
- `specs/`：畫面規格、元件規格、design tokens 與交付說明。

## 命名規範

設計命名需要和前端畫面 class、後端 API resource 對齊。設計稿不要只用「頁面 1」「新版首頁」這類無法追蹤的名稱。

### Figma 頁面命名

Figma page 建議固定：

- `00_Flow`
- `01_Wireframe`
- `02_UI`
- `03_Components`
- `04_Assets`
- `05_Handoff`

### 畫面命名

Frame 名稱使用英文 `PascalCase`，必要時後面加狀態：

- `LoginScreen`
- `RegisterScreen`
- `HomeScreen`
- `TripTrackingScreen`
- `TransportSelectScreen`
- `TripResultScreen`
- `TripListScreen`
- `TripDetailScreen`
- `TripResultScreen_Empty`
- `TripResultScreen_Error`
- `TripTrackingScreen_Loading`

前端 class 名稱需照這些畫面名稱建立，避免設計與工程對不上。

### 元件命名

Figma component 使用階層式命名：

- `Button/Primary/Default`
- `Button/Primary/Disabled`
- `Input/Text/Default`
- `Card/TripSummary/Default`
- `Badge/CarbonSaved/Default`
- `Map/TripMarker/Start`
- `Map/TripMarker/End`

### 設計資產命名

輸出給前端的 asset 檔案使用 `lower_snake_case`。

格式：

```text
功能_內容_狀態.ext
```

範例：

- `trip_marker_start.svg`
- `trip_marker_end.svg`
- `plant_growth_level_1.png`
- `plant_growth_level_2.png`
- `carbon_badge_saved_10kg.svg`
- `visual_state_campus_clean_1.png`

### 設計規格用詞

請固定使用以下產品詞，不要混用同義詞：

- 使用者：`user`
- 旅程：`trip`
- GPS 點：`gps_point`
- 交通方式：`transport_type`
- 碳排：`carbon_emission`
- 減碳量：`carbon_saved`
- 視覺回饋：`visual_state`

若設計稿需要新增名詞，先寫進 `specs/handoff_notes.md`，再和 PM、前後端確認。

## 預期成果

MVP 需要交付：

- 使用者流程圖。
- App 資訊架構。
- Wireframe。
- 主要畫面高保真設計。
- 基礎 design system。
- 台北 / 校園綠化視覺方向。
- 植物成長作為最小可做回饋元素。
- loading、error、empty state。
- 交付給前端的元件規格與圖像資產。

## 使用語言與工具

設計師主要不需要寫程式，但需要用前後端都看得懂的產品語言描述畫面、狀態與資料需求。

建議工具：

- Figma：畫面、元件、prototype。
- FigJam：流程圖、使用者旅程。
- Markdown：整理交付規格。
- PNG / SVG：輸出圖像資產。

交付時建議使用的描述語言：

- 畫面名稱。
- 使用者目的。
- 入口與出口。
- 需要顯示的資料。
- 操作按鈕。
- loading 狀態。
- error 狀態。
- empty state。
- 與 API 的資料關係。

## MVP 畫面範圍

需要設計：

- 開場或登入入口。
- 註冊頁。
- 登入頁。
- 首頁 / 儀表板。
- 開始旅程畫面。
- 旅程進行中畫面。
- 定位權限提示。
- 交通方式選擇畫面。
- 單次旅程結果頁。
- 旅程列表。
- 旅程詳細頁。
- 刪除旅程確認。
- 最小視覺回饋區塊。

## 視覺方向

MVP 先採「台北 / 校園綠化」作為主視覺，不一開始承諾完整動森式玩法。

建議方向：

- 清楚、親切、可信任。
- 綠化城市與校園角落。
- 植物成長作為減碳回饋。
- 使用者能快速看懂距離、時間、交通方式與減碳量。
- 避免讓畫面太像遊戲而犧牲旅程紀錄的清楚度。

## 四週工作分配

### 第 1 週：需求整理與流程

- 整理 MVP 使用者流程。
- 定義主要畫面清單。
- 畫出旅程紀錄流程圖。
- 與 PM 確認 MVP 範圍。
- 與工程師確認資料需求。

### 第 2 週：Wireframe 與資訊架構

- 完成登入、首頁、旅程中、結果頁 wireframe。
- 設計交通方式選擇流程。
- 設計定位權限與錯誤狀態。
- 與前後端確認 API 回傳資料是否足夠。

### 第 3 週：高保真與 Design System

- 完成主要畫面高保真設計。
- 定義色彩、字體、間距、按鈕、卡片、表單、圖表樣式。
- 設計植物成長或校園綠化最小視覺回饋。
- 輸出前端需要的圖像資產。

### 第 4 週：交付、驗收與修正

- 整理畫面規格。
- 標註元件狀態。
- 補齊 loading、error、empty state。
- 協助前端還原畫面。
- 參與整合驗收。

## 未來成果

- 完整台北 / 校園綠化主畫面。
- 島嶼視覺系統。
- 角色養成。
- 每日任務與徽章。
- 排行榜與社群競賽畫面。
- 環保杯、環保餐具驗證流程。
