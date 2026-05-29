# 後端工程師 TASK

## 專案設定

- [x] 建立 FastAPI 專案。
- [x] 建立虛擬環境。
- [x] 建立 requirements 管理方式。
- [x]設定 `.env` 讀取。
- [x] 設定 PostgreSQL 連線。
- [ ] 設定 Alembic。
- [ ] 建立統一錯誤格式。

## 帳號與授權

- [x] 建立 users model。
- [ ] 建立 users migration。
- [x] 實作密碼 hash。
- [x] 實作 `POST /auth/register`。
- [x] 實作 `POST /auth/login`。
- [x] 實作 JWT token。
- [ ] 實作 `GET /auth/me`。
- [x] 保護需要登入的 API。

## 旅程資料

- [ ] 建立 trips model。
- [ ] 建立 gps_points model。
- [ ] 建立 trips / gps_points migration。
- [ ] 實作 `POST /trips/start`。
- [ ] 實作 `POST /trips/{trip_id}/points`。
- [ ] 實作 `POST /trips/{trip_id}/end`。
- [ ] 實作 `GET /trips`。
- [ ] 實作 `GET /trips/{trip_id}`。
- [ ] 實作 `DELETE /trips/{trip_id}`。
- [ ] 確保使用者只能讀寫自己的旅程。

## 計算邏輯

- [ ] 過濾 GPS 飄移點。
- [ ] 計算旅程距離。
- [ ] 計算旅程時間。
- [ ] 建立 `carbon_factors` model。
- [ ] 建立 `carbon_factors` migration。
- [ ] 支援捷運、公車、步行、腳踏車、其他、不確定。
- [ ] 步行與腳踏車先視為 0 直接碳排。
- [ ] 以機車作為 MVP 減碳基準。
- [ ] `其他` / `不確定` 不計入正式減碳成果或標記待確認。

## 統計與回饋

- [ ] 實作 `GET /carbon/summary`。
- [ ] 實作 `GET /carbon/daily`。
- [ ] 實作 `GET /carbon/monthly`。
- [ ] 實作 `GET /visual-state` 初版。

## 測試與文件

- [ ] 撰寫 Auth API 測試。
- [ ] 撰寫 Trips API 測試。
- [ ] 撰寫距離計算測試。
- [ ] 撰寫碳排計算測試。
- [x] 整理 OpenAPI 文件。
- [ ] 查證碳排係數候選來源。
- [x] 查證 Google Maps Platform 成本與限制。
- [ ] 查證 TDX 與台北交通資料來源。
