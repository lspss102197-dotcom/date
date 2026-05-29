# 前端工程師 TASK

## 專案設定

- [x] 建立 Flutter 專案。
- [x] 設定資料夾結構。
- [x] 設定環境變數讀取。
- [x] 設定 API client。
- [x] 設定 token 儲存。
- [x] 決定並導入狀態管理工具。

## 帳號功能

- [ ] 建立登入頁。
- [ ] 建立註冊頁。
- [ ] 串接 `POST /auth/login`。
- [ ] 串接 `POST /auth/register`。
- [ ] 串接 `GET /auth/me`。
- [ ] 處理登入失敗與 token 過期。

## 旅程功能

- [ ] 建立首頁或旅程入口。
- [ ] 建立開始旅程按鈕。
- [ ] 串接 `POST /trips/start`。
- [ ] 請求 GPS 權限。
- [ ] 顯示定位權限狀態。
- [ ] 旅程中每 10 到 15 秒或移動 20 到 30 公尺收集 GPS 點。
- [ ] 串接 `POST /trips/{trip_id}/points`。
- [ ] 建立結束旅程流程。
- [ ] 結束旅程時選擇交通方式。
- [ ] 串接 `POST /trips/{trip_id}/end`。

## 地圖與結果

- [x] 設定 Google Maps。
- [x] 顯示使用者目前位置。
- [ ] 顯示旅程路線。
- [ ] 建立單次旅程結果頁。
- [ ] 顯示距離、時間、交通方式、碳排與減碳量。
- [ ] 串接 `GET /trips/{trip_id}`。
- [ ] 串接 `DELETE /trips/{trip_id}`。
- [ ] 顯示累積減碳摘要。

## 視覺與品質

- [ ] 套用設計師提供的色彩與元件規格。
- [ ] 建立 loading 狀態。
- [ ] 建立 error 狀態。
- [ ] 建立 empty state。
- [ ] 完成台北 / 校園綠化最小視覺回饋。
- [ ] Android 實機測試。
- [ ] 紀錄 GPS 測試結果。
