# Flutterコマンドが認識されない場合の対処法

## 問題
```
flutter : 用語 'flutter' は、コマンドレット、関数、スクリプト ファイル、または操作可能なプログラムの名前として認識されません。
```

## 原因
Flutter SDKがインストールされていないか、環境変数PATHに追加されていません。

## 解決方法

### ステップ1: Flutter SDKがインストールされているか確認

Flutter SDKは通常、以下のような場所にインストールされます：
- `C:\src\flutter`
- `C:\flutter`
- `C:\Users\YourName\flutter`
- その他の任意の場所

### ステップ2: Flutter SDKをインストール（まだの場合）

1. **Flutter公式サイトからダウンロード**
   - https://flutter.dev/docs/get-started/install/windows
   - 「Download Flutter SDK」をクリック
   - ZIPファイルをダウンロード

2. **ZIPファイルを展開**
   - 推奨場所: `C:\src\flutter`
   - または任意の場所（パスにスペースや特殊文字がない場所）

3. **環境変数PATHに追加**

   **方法A: GUIで設定（推奨）**
   
   1. Windowsキーを押して「環境変数」と検索
   2. 「環境変数を編集」を選択
   3. 「ユーザー環境変数」の「Path」を選択
   4. 「編集」をクリック
   5. 「新規」をクリック
   6. Flutter SDKの`bin`フォルダのパスを入力（例: `C:\src\flutter\bin`）
   7. 「OK」をクリックしてすべてのダイアログを閉じる

   **方法B: PowerShellで一時的に設定（現在のセッションのみ）**
   
   ```powershell
   $env:PATH += ";C:\src\flutter\bin"
   ```
   
   （`C:\src\flutter\bin`は実際のFlutter SDKのパスに置き換えてください）

4. **PowerShellを再起動**
   - 環境変数の変更を反映するため、PowerShellを閉じて再度開く

### ステップ3: 動作確認

新しいPowerShellウィンドウで：

```powershell
flutter --version
```

Flutterのバージョンが表示されれば成功です。

### ステップ4: Flutter Doctorで環境をチェック

```powershell
flutter doctor
```

このコマンドで、開発環境の状態を確認できます。

## よくある問題

### 問題1: Flutter SDKのパスがわからない

PowerShellで以下を実行して、Flutter SDKがインストールされているか確認：

```powershell
Get-ChildItem -Path C:\ -Filter flutter -Recurse -Directory -ErrorAction SilentlyContinue | Select-Object FullName
```

### 問題2: 環境変数を設定したが、まだ認識されない

1. **PowerShellを完全に閉じて再度開く**
   - 環境変数の変更は、新しいプロセスでのみ有効です

2. **システムを再起動**
   - 場合によっては、システム再起動が必要です

3. **環境変数の設定を再確認**
   - 正しいパスが設定されているか確認
   - `bin`フォルダまでのパスが正しいか確認（例: `C:\src\flutter\bin`）

### 問題3: 複数のFlutter SDKがインストールされている

最新の安定版（Stable）を使用することを推奨します。

## 次のステップ

Flutter SDKが正しくインストールされ、認識されるようになったら：

```powershell
# プロジェクトディレクトリに移動（既にいる場合は不要）
cd C:\Users\sken1\Documents\NEDO\q_reversi\q-reversi-app

# Flutterプロジェクトを初期化
flutter create .

# 依存関係をインストール
flutter pub get

# アプリを実行
flutter run
```

## 参考リンク

- Flutter公式インストールガイド: https://flutter.dev/docs/get-started/install/windows
- Flutter公式ドキュメント: https://flutter.dev/docs

