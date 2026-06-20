# StudyLog

教科ごとの勉強時間と、教科内タスクごとの実績時間を記録する SwiftUI / SwiftData 製の iOS アプリです。

## v0.1 の範囲

- 教科追加・編集・アーカイブ
- 教科一覧・教科詳細
- タスク追加・編集・完了・削除
- ストップウォッチ式の勉強タイマー
- タスクに紐づく勉強時間の自動集計
- 手動記録
- 今日・今週・累計の集計
- GitHub Actions で unsigned IPA を artifact 出力

## ビルド

Xcode 15 以上、iOS 17 以上を想定しています。

    xcodebuild \
      -project StudyLog.xcodeproj \
      -scheme StudyLog \
      -configuration Debug \
      -destination 'platform=iOS Simulator,name=iPhone 15' \
      build

未署名 IPA は GitHub Actions の Build Unsigned IPA ワークフローで生成します。

## 注意

生成される unsigned IPA は、そのまま通常の iPhone へインストールするものではありません。後から署名するための素材として扱います。
