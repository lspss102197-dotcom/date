# ERROR Report

## 檢查時間

2026-05-28

## 檢查範圍

- Flutter 專案建立狀態
- README.md 要求的資料夾結構
- Flutter analyzer
- Flutter widget test

## 結果

目前沒有發現 Dart / Flutter 編譯或靜態分析錯誤。

- `flutter analyze`: 通過，No issues found
- `flutter test`: 通過，All tests passed
- `README.md`: 存在
- `TASK.md`: 存在
- `.env.example`: 存在
- `pubspec.yaml`: 存在
- `lib/main.dart`: 存在

## 已修正的專案設定缺口

README.md 要求的下列資料夾原本不存在，已補齊：

- `lib/app/`
- `lib/core/`
- `lib/features/auth/`
- `lib/features/trips/`
- `lib/features/carbon/`
- `lib/features/visual_state/`
- `lib/shared/`
- `assets/icons/`
- `assets/images/`
- `assets/animations/`
- `test/features/`
- `test/shared/`

空資料夾使用 `.gitkeep` 保留。

## 注意事項

README.md 與 TASK.md 在 PowerShell 輸出中顯示為亂碼，可能是終端機編碼與檔案編碼不一致。這不影響 Flutter analyzer 或 test，但若內容本身需要人工閱讀，建議之後確認檔案實際編碼。

## 2026-05-29 Google Maps API 測試

Google Maps 基本功能已在 Android emulator 驗證可見，`TASK.md` 已勾選「設定 Google Maps」。

檢查結果：

- `.env.example` 已有 `GOOGLE_MAPS_ANDROID_API_KEY` 與 `GOOGLE_MAPS_IOS_API_KEY`。
- 已加入 `google_maps_flutter`。
- `lib/main.dart` 已改為基本 `GoogleMap` 畫面，固定顯示台北市區地圖。
- Android `AndroidManifest.xml` 已加入 Google Maps API key。
- iOS `AppDelegate.swift` 已加入 Google Maps API key 設定。
- `flutter analyze`: 通過，No issues found。
- `flutter test`: 通過，All tests passed。
- `flutter build web`: 通過。
- `flutter build apk --debug`: 通過。
- Android emulator `emulator-5554` 實際啟動畫面後，可看到 Google Map。

注意：Web 版有載入 `GoogleMap` widget，但目前使用 Android key 載入 Maps JavaScript API 時，Google 回傳「這個網頁並未正確載入 Google 地圖」。若之後需要 Web 版也可見，需另外提供可用於 Web 的 Maps JavaScript API key，並允許本機來源，例如 `http://127.0.0.1:*`。
