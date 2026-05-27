# 低碳通勤紀錄與遊戲化回饋 App

這是一個以「北科大學生在台北地區的日常通勤」為第一版情境的低碳通勤紀錄 App。專案目標是讓使用者透過手機記錄自己的移動路線，了解每次通勤的距離、時間與減碳成果，並逐步把這些成果轉換成可視化、遊戲化的回饋。

目前專案仍在規劃階段。本 README 的主要用途是提供給組員與未來接手開發的人，讓大家快速理解產品方向、MVP 範圍、預定技術棧、資料流，以及實作前仍需查證的項目。

## 建置與驗證方式

目前 repo 仍以規劃文件為主，正式 Flutter App 與 FastAPI 程式碼尚未建立。以下指令是後續建立 `frontend/` 與 `backend/` 專案後的標準建置流程，PM 與接手者可用來確認環境是否可跑。

### 環境需求

- Flutter SDK
- Dart SDK，通常隨 Flutter 安裝
- Python 3.11 以上
- PostgreSQL
- Google Maps Platform API key

### 後端建置

後端預計放在 `backend/`，使用 Python FastAPI。

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
```

啟動後端開發伺服器：

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

驗證方式：

- 開啟 `http://127.0.0.1:8000/docs`，確認 FastAPI Swagger 文件可正常顯示。
- 若有測試，執行：

```powershell
.\.venv\Scripts\python.exe -m pytest
```

### 前端建置

前端預計放在 `frontend/`，使用 Flutter。

先確認 Flutter 環境：

```powershell
flutter doctor
flutter devices
```

安裝前端套件：

```powershell
cd frontend
flutter pub get
Copy-Item .env.example .env
```

啟動 App：

```powershell
flutter run
```

建置 Android APK：

```powershell
flutter build apk
```

驗證方式：

- `flutter doctor` 沒有關鍵錯誤。
- `flutter devices` 能看到模擬器或實機。
- `flutter run` 能啟動 App。
- 若有測試，執行：

```powershell
flutter test
```

### 注意事項

- `.env` 不可提交到 repo，只能提交 `.env.example`。
- 前端 Google Maps key 需要限制 Android package name、SHA-1 或 iOS bundle id。
- 後端 Google Maps key 需要限制伺服器來源或 IP。
- 若尚未建立正式程式碼，以上指令中的 `requirements.txt`、`pubspec.yaml`、`app.main` 會等到工程專案初始化後才存在。

## 產品定位

本專案的第一版定位是：

> 給北科大學生使用的低碳通勤紀錄與遊戲化回饋 App。

MVP 會先從台北地區通勤情境切入，優先支援捷運、公車、步行與腳踏車。火車、高鐵、跨縣市移動，以及更完整的動森式玩法，先列為後續擴充。

長期願景不是只服務北科大，也不是只服務學生族群。未來可以逐步擴展成面向全台使用者的低碳移動紀錄與生活回饋平台。

## MVP 範圍

第一版只聚焦在最小可行產品，避免一開始把交通判斷、完整遊戲系統、社群競賽與行為驗證全部做進來。

MVP 需要完成：

- 密碼登入。
- 手動開始與結束一次旅程。
- 結束旅程時由使用者手動選擇交通方式。
- 取得手機 GPS 座標。
- 在 App 中顯示 Google Map 與旅程路線。
- 將 GPS 座標、時間戳記與速度等資料送到後端。
- 後端儲存旅程與 GPS 點。
- 後端計算單次旅程的距離與時間。
- 以前端顯示單次旅程結果。
- 根據機車作為比較基準，估算單次旅程的減碳量。
- 支援刪除單次旅程。

MVP 不承諾自動精準判斷交通工具。第一版以使用者手動選擇交通方式為主，後端簡單規則判斷為輔；若資料不足，標記為 `unknown` 或 `needs_review`。

## 隱私與安全原則

本專案會處理 GPS 軌跡，因此隱私設計必須從第一版就納入。

定位資料收集原則：

- App 只會在使用者明確開始旅程紀錄後收集定位資料。
- 使用者結束旅程後，App 應停止收集該次旅程定位資料。
- 若未來支援背景定位，必須清楚提示用途、收集頻率、保存方式與關閉方式。
- 不應在使用者未啟動旅程紀錄時進行無限制位置追蹤。

安全與資料保護原則：

- 明確告知使用者定位資料的用途。
- 只收集完成旅程紀錄與減碳計算所需的位置資料。
- 使用 HTTPS 傳輸資料。
- 使用 token 保護 API。
- 後端必須檢查使用者只能存取自己的資料。
- MVP 至少支援刪除單次旅程。
- 刪除帳號與所有個人資料需要保留設計空間；若時程允許可放入 MVP 後段，否則列入第 2 階段。
- Google Maps API key 與後端密鑰不可寫死在公開程式碼中。

## 預定技術棧

核心技術棧預定如下：

- 前端：Flutter
- 後端：Python FastAPI
- 資料庫：PostgreSQL
- 地圖服務：Google Maps Platform

其他套件先視為候選，實作前仍需依專案需求擇一或調整。

### Flutter 候選套件

- `geolocator`：取得 GPS 位置與處理定位狀態。
- `permission_handler`：處理定位權限。
- `google_maps_flutter`：在 App 中顯示 Google Map。
- `dio` 或 `http`：呼叫後端 API，需擇一。
- `flutter_secure_storage`：安全儲存 token。
- `provider`、`riverpod` 或 `bloc`：狀態管理，需擇一。
- `fl_chart`：顯示碳足跡與減碳統計圖表。
- `rive` 或 `lottie`：未來用於角色或視覺回饋動畫。

### FastAPI 候選套件

- `fastapi`：建立 Python API。
- `uvicorn`：啟動 API server。
- `pydantic`：定義 request / response 資料格式。
- `sqlalchemy` 或 `sqlmodel`：資料庫 ORM，需擇一。
- `alembic`：資料庫 migration。
- `psycopg2-binary` 或 `asyncpg`：PostgreSQL 連線。
- `python-dotenv`：讀取環境變數。
- `requests` 或 `httpx`：呼叫 Google Maps API，需擇一。
- `geopy`：計算地理距離。
- `pandas`：整理與分析軌跡資料，可視需求導入。

## 系統資料流

```text
Flutter App
  |
  | 1. 使用者登入
  | 2. 使用者手動開始旅程
  | 3. 取得 GPS 座標並顯示 Google Map
  | 4. 上傳旅程座標與時間資料
  v
FastAPI Server
  |
  | 5. 儲存旅程與 GPS 點
  | 6. 清理與計算距離、時間
  | 7. 根據交通方式與機車基準估算減碳量
  v
PostgreSQL
  |
  | 8. 儲存使用者、旅程、座標與減碳結果
  v
Flutter App
  |
  | 9. 顯示單次旅程結果與初步視覺回饋
```

## 核心功能規劃

### 1. 使用者帳號

MVP 先做一般密碼登入，不在第一版串接校務系統。

需要做到：

- 使用者註冊。
- 使用者登入。
- 取得目前登入使用者資料。
- 儲存使用者基本資料。
- 預留學生身分或學校資訊欄位，但不作為 MVP 的使用資格限制。

未來可考慮：

- 學校信箱驗證。
- Google 登入。
- 校方帳號或 SSO 整合。
- 擴展到非學生使用者。

### 2. 旅程紀錄

MVP 的旅程紀錄採手動開始與手動結束。

需要做到：

- 使用者按下開始後建立一筆旅程。
- 旅程進行中每 10 到 15 秒記錄一次 GPS 點，或使用者移動超過約 20 到 30 公尺才記錄一次。
- GPS 記錄策略可同時採用時間門檻與距離門檻。
- MVP 先固定這一組 GPS 記錄規則，不依交通方式動態調整。
- 上傳座標、時間戳記、速度等資料。
- 使用者按下結束後停止收集該次旅程資料。
- 使用者結束旅程時選擇交通方式。
- 後端計算距離與時間。
- 前端顯示單次旅程結果。
- 使用者可刪除單次旅程。

需要注意：

- Android 與 iOS 都需要設定定位權限。
- MVP 不支援背景定位；只有在驗證使用者常常忘記保持 App 開啟、導致旅程資料不完整後，才列入後續版本。
- 若未來支援背景定位，必須先完成隱私提示、權限流程、電量策略與關閉方式設計。
- 後端需要清理飄移點與瞬間跳點。
- 實機測試後，再評估是否依交通方式或場景調整 GPS 更新頻率。

### 3. 地圖與台北通勤情境

MVP 以台北地區日常通勤為主要場景。

優先支援：

- 捷運。
- 公車。
- 步行。
- 腳踏車。

後續支援：

- 火車。
- 高鐵。
- 跨縣市移動。
- 更完整的大眾運輸路線比對。

可能需要的 Google API：

- Maps SDK for Android。
- Maps SDK for iOS。
- Directions API。
- Distance Matrix API。
- Geocoding API。
- Places API。

Google Maps API key 需要依使用位置分開管理。前端 key 應限制 Android package name、SHA-1 或 iOS bundle id；後端 key 應透過環境變數管理，並限制伺服器來源。

成本控管原則：

- MVP 先把 Google Maps 用途限制在地圖顯示與必要路線輔助。
- 不要每個 GPS 點都呼叫 Directions API 或 Distance Matrix API。
- 後端距離優先用 GPS 點自行計算。
- Google API 只在需要輔助判斷、路線修正或地圖顯示時呼叫。
- Google Cloud 需要設定 API key 來源限制、用量上限與帳單警示。
- 開發前需要查證當下 Google Maps Platform 價格、免費額度、用量上限設定方式與帳單警示設定方式；README 不寫死價格。

台北交通資料待查來源：

- 台北市資料大平台。
- 政府資料開放平台。
- 交通部運輸資料流通服務平台 TDX。

優先查找資料：

- 捷運站點。
- 公車站牌。
- 公車路線。
- YouBike 站點。

這些資料主要用於第二階段交通判斷與路線比對，不要求 MVP 第一版一定整合。

### 4. 交通方式判斷

MVP 不承諾自動精準判斷交通方式。第一版採「使用者手動選擇為主、後端簡單規則判斷為輔」。

使用者結束旅程時可選：

- 捷運。
- 公車。
- 步行。
- 腳踏車。
- 其他。
- 不確定。

後端可以根據速度、距離與時間做初步檢查，用於異常提示或可信度參考；若無法判斷，標記為未知或待確認。

第二階段再強化：

- 清理 GPS 飄移資料。
- 根據速度分段判斷步行、腳踏車、大眾運輸或未知。
- 比對是否接近捷運站、公車站或公共運輸路線。
- 判斷是否出現步行到站、搭乘、下車步行的模式。
- 對每次旅程產生可信度分數。

### 5. 碳排與減碳計算

MVP 先用「機車」作為主要比較基準，估算使用者改搭大眾運輸、步行或腳踏車所節省的碳排。

計算概念：

```text
碳排放量 = 移動距離 km x 該交通方式每公里碳排係數

減碳量 = 機車基準碳排放量 - 實際交通方式碳排放量
```

需要做到：

- 建立 `carbon_factors` 設定表或設定檔集中管理碳排係數，避免寫死在程式裡。
- 根據旅程距離計算碳排放量。
- 以機車作為 MVP 的基準交通方式。
- 捷運、公車、步行與腳踏車使用不同碳排係數。
- 步行與腳踏車在 MVP 可先視為 0 直接碳排。
- 「其他」或「不確定」先不計入正式減碳成果，或標記為待確認。
- 儲存單次旅程碳排與減碳結果。
- 前端顯示使用者看得懂的減碳成果。

資料來源要求：

- 碳排係數需引用公開可信來源，優先採用台灣官方資料。
- 若某些交通方式沒有直接可用的台灣資料，可使用國際公開資料作為暫代，並在資料中標記為 `暫用係數`。
- 每份係數需要記錄來源、版本、單位與更新日期。
- 未來是否改成汽車、機車或平均通勤方式作為基準。

待查候選來源：

- 環境部公開資料。
- 交通部公開資料。
- 台北市政府資料開放平台。
- 台北捷運或公共運輸相關公開資料。
- 國際公開資料，僅作為台灣資料不足時的暫用來源。

### 6. 遊戲化與視覺回饋

第一版先採「台北 / 校園綠化」作為主視覺，植物成長作為最小可做的回饋元素；不承諾完整動森式玩法。

MVP 可做：

- 顯示單次旅程減碳量。
- 顯示累積減碳量。
- 顯示簡單徽章或階段狀態。
- 將減碳成果轉換成植物成長、綠色校園或城市角落逐步變乾淨的狀態。

後續可擴充：

- 台北地區或校園場景成長。
- 島嶼場景。
- 角色養成。
- 每日任務。
- 每週挑戰。
- 好友互動。
- 系所或社群排行榜。
- 更接近動森式的生活化、可愛、收集與經營玩法。

## 初版資料庫草案

以下為規劃階段草案，實作前可依 API 與 ORM 設計調整。

### users

- `id`
- `account`
- `password_hash`
- `name`
- `student_id`
- `school_name`
- `created_at`
- `updated_at`

### trips

- `id`
- `user_id`
- `started_at`
- `ended_at`
- `distance_km`
- `duration_seconds`
- `transport_type`
- `confidence_score`
- `carbon_emission`
- `carbon_saved`
- `region`
- `city`
- `created_at`

### gps_points

- `id`
- `trip_id`
- `latitude`
- `longitude`
- `speed`
- `recorded_at`

### user_rewards

- `id`
- `user_id`
- `reward_type`
- `reward_value`
- `unlocked_at`

### eco_actions

後續擴充用，MVP 可先不做。

- `id`
- `user_id`
- `action_type`
- `status`
- `evidence_url`
- `created_at`
- `verified_at`

### carbon_factors

碳排係數集中管理用，避免把係數寫死在程式碼中。

- `id`
- `transport_type`
- `emission_factor`
- `unit`
- `source_name`
- `source_url`
- `source_version`
- `effective_from`
- `created_at`

### transport_data_sources

未來全台擴展用，MVP 可先只預留設計。

- `id`
- `city`
- `region`
- `source_name`
- `source_url`
- `source_version`
- `created_at`

## 初版 API 草案

以下 endpoint 是規劃草案，實作時可依前後端需求調整命名與 response 格式。

### Auth

- `POST /auth/register`：註冊。
- `POST /auth/login`：登入。
- `GET /auth/me`：取得目前使用者資料。

### Trips

- `POST /trips/start`：開始一次旅程。
- `POST /trips/{trip_id}/points`：上傳 GPS 座標。
- `POST /trips/{trip_id}/end`：結束旅程並觸發距離、時間與減碳計算。
- `GET /trips`：取得旅程列表。
- `GET /trips/{trip_id}`：取得單次旅程詳細資料。
- `DELETE /trips/{trip_id}`：刪除單次旅程。

### Carbon

- `GET /carbon/summary`：取得使用者總減碳量。
- `GET /carbon/daily`：取得每日統計。
- `GET /carbon/monthly`：取得每月統計。

### Rewards

- `GET /rewards`：取得獎勵與徽章。
- `GET /visual-state`：取得前端視覺化狀態，例如植物成長階段、校園或島嶼等級。

### Eco Actions

後續擴充用，MVP 可先不做。

- `POST /eco-actions`：新增環保行為紀錄。
- `POST /eco-actions/{action_id}/evidence`：上傳驗證資料。
- `GET /eco-actions`：取得環保行為列表。

## Roadmap

### 第 1 階段：MVP 旅程紀錄與減碳結果

- Flutter App 基本頁面。
- 密碼登入。
- 手動開始與結束旅程。
- GPS 座標取得與上傳。
- 旅程中每 10 到 15 秒或移動 20 到 30 公尺記錄一次 GPS 點。
- Google Map 顯示。
- 結束旅程時手動選擇交通方式。
- FastAPI 接收與儲存旅程資料。
- PostgreSQL 儲存使用者、旅程與 GPS 點。
- 計算單次旅程距離、時間與減碳量。
- 前端顯示單次旅程結果。
- 刪除單次旅程。

### 第 2 階段：交通方式判斷與碳排準確度

- GPS 飄移資料清理。
- 速度與距離規則判斷。
- 捷運站、公車站或路線比對。
- 建立可信度分數。
- 校正交通工具碳排係數。
- 確認碳排係數資料來源。
- 刪除帳號與所有個人資料。

### 第 3 階段：遊戲化視覺回饋

- 累積減碳成果。
- 台北 / 校園綠化主視覺。
- 植物成長狀態。
- 徽章與成就。
- 每日任務與每週挑戰。
- 更完整的台北地區視覺主題。
- 島嶼與動森式玩法雛形。

### 第 4 階段：社群與競賽

- 好友系統。
- 排行榜。
- 系所、班級或社群競賽。
- 活動任務。

### 第 5 階段：更多低碳行為驗證與全台擴展

- 環保杯紀錄。
- 環保餐具紀錄。
- QR Code 驗證。
- 照片上傳或人工審核。
- AI 圖像辨識驗證。
- 全台交通情境支援。

## 環境變數草案

後端建議使用 `.env` 管理設定。

```env
DATABASE_URL=postgresql://user:password@localhost:5432/carbon_app
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
JWT_SECRET_KEY=your_secret_key
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
```

前端不應把敏感金鑰直接寫進公開 repo。Google Maps App key 需要依 Android / iOS 平台設定限制。

## 仍需查證或補充

以下不是產品方向問題，而是實作前需要查資料或測試後才能補齊的任務：

- 查證台灣官方碳排係數來源，優先確認環境部、交通部、台北市政府資料開放平台、台北捷運或公共運輸相關公開資料是否可用。
- 若台灣資料不足，查找國際公開資料作為暫用來源，並在 `carbon_factors` 中標記為 `暫用係數`。
- 查證 Google Maps Platform 當下價格、免費額度、用量上限設定方式與帳單警示設定方式。
- 查證台北市資料大平台、政府資料開放平台與 TDX 是否提供捷運站點、公車站牌、公車路線與 YouBike 站點資料。
- 實機測試 GPS 固定規則，也就是 10 到 15 秒或 20 到 30 公尺，確認是否足以支援步行、公車、捷運與腳踏車情境。
