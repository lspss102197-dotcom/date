# 前端工程師 README

本資料夾給 PM 與前端工程師了解 Flutter App 在 MVP 階段要交付的成果、使用技術、安裝套件與四週工作分配。

## 角色目標

前端工程師負責把低碳通勤 App 做成可操作的手機介面，讓使用者可以登入、開始旅程、看到地圖與路線、結束旅程、選擇交通方式，並查看單次旅程距離、時間與減碳結果。

## 資料夾結構

目前 `frontend/` 先放前端工作文件；正式建立 Flutter 專案後，請依下列結構整理：

```text
frontend/
├─ README.md
├─ TASK.md
├─ .env.example
├─ pubspec.yaml
├─ lib/
│  ├─ main.dart
│  ├─ app/
│  ├─ core/
│  ├─ features/
│  │  ├─ auth/
│  │  ├─ trips/
│  │  ├─ carbon/
│  │  └─ visual_state/
│  └─ shared/
├─ assets/
│  ├─ icons/
│  ├─ images/
│  └─ animations/
└─ test/
   ├─ features/
   └─ shared/
```

資料夾用途：

- `lib/app/`：App 啟動、路由、主題與全域設定。
- `lib/core/`：API client、環境變數、錯誤處理、token 儲存。
- `lib/features/auth/`：登入、註冊、目前使用者。
- `lib/features/trips/`：開始旅程、GPS 點上傳、結束旅程、旅程列表與結果。
- `lib/features/carbon/`：減碳摘要與圖表。
- `lib/features/visual_state/`：植物成長、校園綠化等視覺回饋。
- `lib/shared/`：跨功能共用元件、格式化工具與 UI helper。
- `assets/`：前端實際使用的 icon、圖片與動畫素材。

## 命名規範

前端命名需和後端 API、設計稿畫面名稱對齊，避免同一個功能出現多組名稱。

### 共同功能名稱

以下名稱請固定使用：

| 中文概念 | 前端 feature | API resource | 設計畫面前綴 |
| --- | --- | --- | --- |
| 使用者帳號 | `auth` | `/auth` | `Auth` |
| 旅程 | `trips` | `/trips` | `Trip` |
| GPS 點 | `gps_points` | `gps_points` | `GpsPoint` |
| 碳排與減碳 | `carbon` | `/carbon` | `Carbon` |
| 視覺回饋 | `visual_state` | `/visual-state` | `VisualState` |

### Dart 與檔案命名

- Dart 檔案使用 `snake_case`：`trip_result_screen.dart`。
- Dart class / widget 使用 `PascalCase`：`TripResultScreen`。
- Dart 變數與方法使用 `camelCase`：`startTrip()`、`carbonSaved`。
- Feature 資料夾使用英文小寫與底線：`visual_state/`。
- UI 顯示文字可用中文，但 code identifier 一律用英文。
- 不使用縮寫，除非是固定詞：`gps`、`api`、`jwt`。

### 畫面名稱對齊

前端畫面 class 名稱需和設計稿 frame 名稱一致：

- `LoginScreen`
- `RegisterScreen`
- `HomeScreen`
- `TripTrackingScreen`
- `TransportSelectScreen`
- `TripResultScreen`
- `TripListScreen`
- `TripDetailScreen`

### API 與 JSON 命名

- API path 以後端文件為準：`/trips/{trip_id}/points`。
- JSON key 使用後端的 `snake_case`：`carbon_saved`、`transport_type`。
- Dart model 可以使用 `camelCase`，但序列化時需明確對應 `snake_case`。
- 前端不可自行改 API 欄位名稱；需要改名時要同步更新後端與設計規格。

### 資產命名

- asset 檔案使用 `lower_snake_case`。
- 格式：`功能_內容_狀態.ext`。
- 範例：`trip_marker_start.svg`、`plant_growth_level_1.png`、`carbon_badge_saved_10kg.svg`。

## 預期成果

MVP 需要交付：

- Flutter App 基本專案架構。
- 登入、註冊與 token 儲存流程。
- 首頁或儀表板。
- 手動開始與結束旅程流程。
- GPS 權限請求與定位狀態提示。
- 旅程中 GPS 點收集與上傳。
- Google Map 顯示目前位置與旅程路線。
- 結束旅程時選擇交通方式。
- 單次旅程結果頁，顯示距離、時間、交通方式、碳排與減碳量。
- 刪除單次旅程的操作入口。
- 台北 / 校園綠化方向的最小視覺回饋。

## 使用語言與框架

- 語言：Dart
- 框架：Flutter
- 目標平台：Android 優先，iOS 保留相容性
- 狀態管理：建議先從 `riverpod` 或 `provider` 擇一，MVP 不同時混用多套

## 建議安裝套件

```bash
flutter pub add geolocator
flutter pub add permission_handler
flutter pub add google_maps_flutter
flutter pub add dio
flutter pub add flutter_secure_storage
flutter pub add flutter_dotenv
flutter pub add fl_chart
```

後續若要加入動畫，可再評估：

```bash
flutter pub add rive
flutter pub add lottie
```

## 環境變數

前端建議使用 `.env` 管理非敏感設定，例如 API base URL。Google Maps App key 仍需依 Android / iOS 平台設定限制，不應直接提交正式 key。

範例請看 [.env.example](./.env.example)。

## API 協作需求

前端需要後端提供：

- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`
- `POST /trips/start`
- `POST /trips/{trip_id}/points`
- `POST /trips/{trip_id}/end`
- `GET /trips`
- `GET /trips/{trip_id}`
- `DELETE /trips/{trip_id}`
- `GET /carbon/summary`
- `GET /visual-state`

## 四週工作分配

### 第 1 週：專案骨架與登入

- 建立 Flutter 專案架構。
- 設定路由、主題、環境變數讀取。
- 完成登入、註冊 UI。
- 串接登入 API mock 或後端初版 API。
- 儲存 token。

### 第 2 週：旅程紀錄與定位

- 完成 GPS 權限流程。
- 完成開始旅程、旅程中定位、結束旅程流程。
- 依規則每 10 到 15 秒或移動 20 到 30 公尺收集 GPS 點。
- 將 GPS 點送到後端。

### 第 3 週：地圖與結果頁

- 串接 Google Map。
- 顯示目前位置與旅程路線。
- 結束旅程時讓使用者選擇交通方式。
- 顯示單次旅程距離、時間、碳排與減碳量。
- 加入刪除單次旅程操作。

### 第 4 週：整合、測試與視覺回饋

- 與後端完成 API 整合。
- 處理 loading、error、empty state。
- 完成台北 / 校園綠化的最小視覺回饋。
- 實機測試 GPS 收集規則。
- 整理已知問題與下階段建議。

## 未來成果

- 更完整的台北 / 校園綠化主畫面。
- 每日任務與徽章。
- 累積減碳圖表。
- 島嶼與動森式玩法。
- 好友、排行榜與社群競賽。
