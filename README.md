# まいにち — 習慣記録アプリ

添付の目標設定・ホーム・設定画面をもとに作成した、日本語のFlutterアプリです。
白いカード、青いアクセント、丸みのある入力欄を採用しています。

## できること

- 初回の目標・毎日やること・通知時刻の登録
- 今日の実行を1日1回記録し、確認ダイアログから取り消し
- 連続日数、累計回数、達成率の集計
- 月間カレンダーで開始日から今日までの記録を追加・取り消し
- 目標と行動の編集、通知のオン・オフ、通知時刻の変更、テスト通知
- 端末への保存、再起動時の復元、日付変更時のホーム更新
- Android・iOS向けプロジェクトとブラウザ確認用Web版

初回はサンプルの目標と行動を編集できます。記録は0回から始まり、画像内の「12日・38回・92%」などの架空の実績は登録しません。

## 開発環境と起動

検証環境：Flutter 3.35.4 / Dart 3.9.2。依存パッケージは `pubspec.lock` で固定しています。
AndroidはAPI 24以降、iOSは13以降が対象です。

```sh
flutter pub get
flutter run
```

Android端末・エミュレーターを接続して実行します。iPhoneでの実行にはmacOS、Xcodeと署名の設定が必要です。Xcodeで `ios/Runner.xcworkspace` を開き、Signing & CapabilitiesのTeamと必要に応じてBundle Identifierを設定してください。

ブラウザで確認する場合：

```sh
flutter run -d chrome
```

ビルド済みWeb版をローカルで確認する場合（Node.jsが必要）：

```sh
flutter build web
node tool/serve-preview.mjs
```

`http://127.0.0.1:4173` を開きます。デスクトップでは画面を最大480pxに制限し、スマホと同じ配置で操作できます。ブラウザの保存先はオリジンごとに分かれます。

## Android APK

```sh
flutter build apk --debug
```

出力先：`build/app/outputs/flutter-apk/app-debug.apk`

これは動作確認用のデバッグ署名APKです。ストア配布時は `android/app/build.gradle.kts` のrelease署名を専用の署名鍵に変更し、アプリIDも確認してください。署名鍵や認証情報はこのリポジトリに含めていません。

## 記録と設定の仕様

- データはSharedPreferencesAsyncを通じて端末内へ保存します。アカウント登録やサーバーは不要です。
- 累計は開始日から今日までの実行日数です。1日に複数回は計上しません。
- 連続日数は今日の実行済み記録から遡って計算します。今日が未実行なら昨日までの連続を表示します。
- 達成率は「実行日数 ÷ 開始日から今日までの日数 × 100」を四捨五入します。
- 目標・行動を変更しても、開始日と過去の記録は引き継ぎます。
- 設定画面の変更は「保存」で反映されます。保存せずタブを移動した変更は破棄されます。
- 保存失敗時は画面の記録を確定せず、再試行できるメッセージを表示します。読み込み失敗時は保存済みデータを上書きしません。
- データのクラウド同期・エクスポートはありません。アプリの削除やブラウザのサイトデータ削除で記録が失われる場合があります。

## 通知

Android・iOSでは `flutter_local_notifications` を使用し、端末のタイムゾーンで毎日の通知を予約します。
初回保存や通知オンでOSの許可を要求し、拒否された場合は端末設定で許可する案内を表示します。
時刻変更時は既存の予約を置き換え、通知オフでは予約を解除します。Androidでは再起動後の予約復元用receiverも設定しています。

Androidは特別な正確なアラーム権限を要求せず、`inexactAllowWhileIdle` を使います。そのため、省電力機能などにより設定時刻より遅れる場合があります。iOSも集中モードなど端末側の設定が優先されます。

Web版は画面・保存機能の確認用です。OS通知の予約・送信は行わず、スマホ版で利用できる旨を表示します。

## 検証

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

11件の自動テストで、日付境界、連続記録、達成率、データ復元、不正データ、設定編集、時刻変更、記録取消、保存失敗時の再試行、320px幅のレイアウトなどを確認します。

Windows環境で静的解析・テスト・Android APK・Webビルドを確認し、ブラウザの390×844表示で初回設定、ホーム、記録、設定と再読み込み時のデータ保持を確認しています。
iOSビルド、Android/iPhone実機での通知受信・再起動後の配信・省電力時の配信は未検証です。

GitHub Actionsでも解析・テスト・Webビルド・AndroidデバッグAPK作成を実行する設定を追加しています。

## 構成

```text
lib/
  app.dart                   起動・保存・タブ・日付更新
  models/habit.dart          データモデルと集計
  services/                  保存とスマホ通知
  ui/                        画面とテーマ
assets/app-icon.svg          アプリアイコンのベクター原稿
test/                       モデル・画面操作テスト
tool/                       アイコン生成とプレビューサーバー
```

アイコンは `assets/app-icon.svg` と同じ図形を `tool/generate_icons.ps1` でPNGに描画しています。外部画像や添付画像そのものをアプリの画面背景として使用していません。

通知実装の参照：[flutter_local_notifications 19.5.0](https://pub.dev/packages/flutter_local_notifications/versions/19.5.0)、保存APIの参照：[shared_preferences](https://pub.dev/packages/shared_preferences)。
