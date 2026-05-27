# 後端工程師 README

本資料夾給 PM 與後端工程師了解 FastAPI 後端在 MVP 階段要交付的成果、使用技術、安裝套件與四週工作分配。

## 角色目標

後端工程師負責建立 API、資料庫與旅程計算邏輯，讓前端能完成登入、旅程紀錄、GPS 點上傳、距離時間計算、碳排與減碳量估算，以及刪除單次旅程。

## 資料夾結構

目前 `backend/` 先放後端工作文件；正式建立 FastAPI 專案後，請依下列結構整理：

```text
backend/
├─ README.md
├─ TASK.md
├─ .env.example
├─ requirements.txt
├─ alembic.ini
├─ app/
│  ├─ main.py
│  ├─ core/
│  │  ├─ config.py
│  │  ├─ security.py
│  │  └─ database.py
│  ├─ models/
│  ├─ schemas/
│  ├─ api/
│  │  └─ routes/
│  ├─ services/
│  └─ tests/
├─ migrations/
└─ tests/
```

資料夾用途：

- `app/main.py`：FastAPI app 入口。
- `app/core/`：設定、資料庫連線、JWT 與安全工具。
- `app/models/`：ORM models。
- `app/schemas/`：Pydantic request / response schemas。
- `app/api/routes/`：API route handlers。
- `app/services/`：旅程計算、碳排計算、GPS 清理等商業邏輯。
- `migrations/`：Alembic migration。
- `tests/`：API、service 與計算邏輯測試。

## 命名規範

後端命名是前端與設計的共同資料來源；API、資料表、JSON 欄位與文件需使用同一組詞。

### 共同功能名稱

以下名稱請固定使用：

| 中文概念 | API resource | 資料表 / model | 前端 feature |
| --- | --- | --- | --- |
| 使用者帳號 | `/auth` | `users` | `auth` |
| 旅程 | `/trips` | `trips` | `trips` |
| GPS 點 | `/trips/{trip_id}/points` | `gps_points` | `gps_points` |
| 碳排與減碳 | `/carbon` | `carbon_factors` | `carbon` |
| 視覺回饋 | `/visual-state` | `user_rewards` | `visual_state` |

### Python 與資料庫命名

- Python 檔案與模組使用 `snake_case`：`trip_service.py`。
- Python class 使用 `PascalCase`：`TripService`、`TripRead`。
- Python 變數與函式使用 `snake_case`：`calculate_distance_km()`。
- 資料表使用複數 `snake_case`：`gps_points`、`carbon_factors`。
- 資料欄位使用 `snake_case`：`carbon_saved`、`transport_type`。
- Enum value 使用小寫 `snake_case`：`suspected_public_transport`。

### API 命名

- API resource 使用複數：`/trips`。
- 巢狀資源使用父子關係：`/trips/{trip_id}/points`。
- path parameter 使用 `snake_case`：`{trip_id}`。
- HTTP method 表達動作，不在 path 加動詞，既有 MVP 例外為 `/trips/start` 與 `/trips/{trip_id}/end`。
- Response JSON key 一律使用 `snake_case`。
- 錯誤回應格式需固定，不讓前端每支 API 特判。

### 跨角色固定欄位

以下欄位名稱不可各自改名：

- `trip_id`
- `started_at`
- `ended_at`
- `distance_km`
- `duration_seconds`
- `transport_type`
- `confidence_score`
- `carbon_emission`
- `carbon_saved`
- `visual_state`

若要改名，需同步更新 backend schema、frontend model、design specs 與根 README。

## 預期成果

MVP 需要交付：

- FastAPI 專案架構。
- PostgreSQL 資料庫 schema 與 migration。
- 使用者註冊、登入與 JWT 驗證。
- 旅程開始、GPS 點上傳、旅程結束、旅程查詢與刪除。
- GPS 點距離與時間計算。
- 基於使用者選擇交通方式的碳排與減碳量估算。
- `carbon_factors` 係數管理設計。
- API 文件與錯誤格式。
- 基本單元測試與整合測試。

## 使用語言與框架

- 語言：Python 3.11 以上
- API 框架：FastAPI
- 資料庫：PostgreSQL
- ORM：建議 `SQLAlchemy` 或 `SQLModel` 擇一
- Migration：Alembic
- 驗證：JWT bearer token

## 建議安裝套件

```bash
python -m venv .venv
.venv\Scripts\python.exe -m pip install fastapi uvicorn pydantic sqlalchemy alembic psycopg2-binary python-dotenv python-jose passlib[bcrypt] geopy httpx pytest
```

若採 async PostgreSQL，可評估改用：

```bash
.venv\Scripts\python.exe -m pip install asyncpg
```

## 環境變數

後端需要 `.env` 管理資料庫、JWT 與 Google Maps key。正式密鑰不可提交到 repo。

範例請看 [.env.example](./.env.example)。

## API 交付範圍

### Auth

- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`

### Trips

- `POST /trips/start`
- `POST /trips/{trip_id}/points`
- `POST /trips/{trip_id}/end`
- `GET /trips`
- `GET /trips/{trip_id}`
- `DELETE /trips/{trip_id}`

### Carbon

- `GET /carbon/summary`
- `GET /carbon/daily`
- `GET /carbon/monthly`

### Rewards

- `GET /visual-state`

## 四週工作分配

### 第 1 週：後端骨架與帳號

- 建立 FastAPI 專案架構。
- 設定 PostgreSQL 連線。
- 建立 Alembic migration。
- 完成 users schema。
- 完成註冊、登入、JWT 驗證。

### 第 2 週：旅程與 GPS 點

- 完成 trips 與 gps_points schema。
- 完成旅程開始 API。
- 完成 GPS 點上傳 API。
- 完成旅程結束 API。
- 完成旅程列表與單次旅程查詢。

### 第 3 週：距離、時間與碳排計算

- 清理不合理 GPS 點。
- 計算旅程距離與時間。
- 建立 carbon_factors schema。
- 以機車作為 MVP 基準計算減碳量。
- 處理 `其他` / `不確定` 不計入正式成果或標記待確認。

### 第 4 週：整合、刪除與測試

- 完成刪除單次旅程 API。
- 完成 carbon summary API。
- 完成 visual-state API 初版。
- 補 API 測試。
- 與前端完成整合測試。
- 整理 API 文件與待查資料來源。

## 未來成果

- 交通方式自動判斷。
- 捷運站、公車站牌、公車路線與 YouBike 站點資料整合。
- 背景定位支援前的資料保護設計。
- 刪除帳號與所有個人資料。
- 全台城市與交通資料來源管理。
