# Flutter SDK インストールガイド（Windows版）

## ステップ1: Flutter SDKのインストール

### 方法1: 公式サイトからダウンロード（推奨）

1. **Flutter公式サイトにアクセス**
   - https://flutter.dev/docs/get-started/install/windows

2. **Flutter SDKをダウンロード**
   - 「Download Flutter SDK」ボタンをクリック
   - 最新の安定版（Stable）をダウンロード
   - ZIPファイルがダウンロードされます（例: `flutter_windows_3.x.x-stable.zip`）

3. **ZIPファイルを展開**
   - ダウンロードしたZIPファイルを展開
   - 推奨場所: `C:\src\flutter`（任意の場所でも可）
   - **重要**: パスにスペースや特殊文字が含まれない場所を選択してください

4. **環境変数PATHに追加**
   - Windowsキーを押して「環境変数」と検索
   - 「環境変数を編集」を選択
   - 「ユーザー環境変数」または「システム環境変数」の「Path」を選択
   - 「新規」をクリック
   - Flutter SDKのパスを追加（例: `C:\src\flutter\bin`）
   - 「OK」をクリックしてすべてのダイアログを閉じる

5. **コマンドプロンプトまたはPowerShellを再起動**
   - 環境変数の変更を反映するため、開いているターミナルを閉じて再度開く

### 方法2: Gitを使用（開発者向け）

```bash
git clone https://github.com/flutter/flutter.git -b stable
```

その後、環境変数PATHに`flutter\bin`を追加してください。

## ステップ2: Flutterの動作確認

新しいコマンドプロンプトまたはPowerShellを開いて、以下を実行：

```bash
flutter --version
```

Flutterのバージョンが表示されれば、インストール成功です。

## ステップ3: Flutter Doctorで環境をチェック

```bash
flutter doctor
```

このコマンドで、開発環境の状態を確認できます。

### 必要なツール

- ✅ **Flutter SDK**: インストール済み
- ⚠️ **Android Studio**: Android開発用（推奨）
- ⚠️ **Visual Studio**: Windows開発用（オプション）
- ⚠️ **VS Code**: エディタ（オプション、推奨）

### Android Studioのインストール（Android開発用）

1. **Android Studioをダウンロード**
   - https://developer.android.com/studio
   - インストーラーをダウンロードして実行

2. **Android Studioのセットアップ**
   - インストールウィザードに従ってインストール
   - 「More Actions」→「SDK Manager」でAndroid SDKをインストール
   - 「More Actions」→「AVD Manager」でAndroidエミュレータを作成

3. **Flutterプラグインのインストール**
   - Android Studioを起動
   - 「File」→「Settings」→「Plugins」
   - 「Flutter」と「Dart」プラグインを検索してインストール

## ステップ4: プロジェクトのセットアップ

### 1. プロジェクトディレクトリに移動

```bash
cd C:\Users\sken1\Documents\NEDO\q_reversi\q-reversi-app
```

### 2. Flutterプロジェクトの初期化

```bash
flutter create .
```

このコマンドで、Android/iOS/Webの設定ファイルが生成されます。
既存のファイルは上書きされないため、安全に実行できます。

### 3. 依存関係のインストール

```bash
flutter pub get
```

このコマンドで、`pubspec.yaml`に記載されている依存パッケージがインストールされます。

## ステップ5: アプリの実行

### Androidエミュレータで実行

1. **エミュレータを起動**
   - Android Studioを起動
   - 「More Actions」→「AVD Manager」
   - エミュレータを選択して「▶」ボタンをクリック

2. **アプリを実行**
   ```bash
   flutter run
   ```

### 実機で実行（Android）

1. **USBデバッグを有効化**
   - スマートフォンの「設定」→「開発者向けオプション」→「USBデバッグ」を有効化

2. **USBケーブルで接続**
   - スマートフォンをPCにUSBケーブルで接続

3. **アプリを実行**
   ```bash
   flutter run
   ```

### Webブラウザで実行

```bash
flutter run -d chrome
```

または

```bash
flutter run -d edge
```

### iOSシミュレータで実行（Macのみ）

```bash
flutter run
```

## トラブルシューティング

### エラー: "flutter: command not found"

**原因**: PATH環境変数が正しく設定されていない

**解決方法**:
1. Flutter SDKのパスを確認（例: `C:\src\flutter\bin`）
2. 環境変数PATHに追加されているか確認
3. コマンドプロンプト/PowerShellを再起動

### エラー: "No devices found"

**原因**: エミュレータまたは実機が接続されていない

**解決方法**:
- Androidエミュレータを起動する
- または、実機をUSB接続する
- または、Webブラウザで実行: `flutter run -d chrome`

### エラー: "Android SDK not found"

**原因**: Android SDKがインストールされていない

**解決方法**:
1. Android Studioをインストール
2. Android Studioで「SDK Manager」を開く
3. Android SDKをインストール
4. 環境変数ANDROID_HOMEを設定（例: `C:\Users\YourName\AppData\Local\Android\Sdk`）

### エラー: "PlatformException" または "MissingPluginException"

**解決方法**:
```bash
flutter clean
flutter pub get
flutter run
```

### エラー: "Gradle build failed"

**解決方法**:
```bash
cd android
gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

## 開発のヒント

### ホットリロード
アプリ実行中に、コードを変更して保存すると、自動的に変更が反映されます（ホットリロード）。
- `r`キー: ホットリロード
- `R`キー: ホットリスタート（完全再起動）
- `q`キー: アプリを終了

### デバッグモード
```bash
flutter run --debug
```

### リリースモード（パフォーマンス最適化）
```bash
flutter run --release
```

### ビルドのみ（実行しない）
```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS（Macのみ）
flutter build ios

# Web
flutter build web
```

## 次のステップ

1. ✅ Flutter SDKのインストール
2. ✅ プロジェクトのセットアップ
3. ✅ アプリの実行
4. 🎮 ゲームをプレイ！

## 参考リンク

- Flutter公式ドキュメント: https://flutter.dev/docs
- Flutter公式GitHub: https://github.com/flutter/flutter
- Dart公式サイト: https://dart.dev

