# Q-Reversi App

量子コンピューティングの原理を活用した、オセロ風のボードゲームアプリです。

## 機能

- **VSモード**: 対人戦・対CPU戦（3段階の難易度）
- **フリーランモード**: 自由にゲートを演算可能
- **チャレンジモード**: 特定の量子状態を作るミッション（準備中）
- **スタディモード**: 量子コンピューティングを学習（準備中）

## 技術スタック

- Flutter 3.0+
- Dart 3.0+
- Provider（状態管理）
- SQLite（データ永続化、準備中）

## プロジェクト構造

```
lib/
├── core/
│   └── constants/        # 定数定義
├── domain/
│   ├── entities/        # エンティティ（Piece, Board, GameState等）
│   └── services/        # ビジネスロジック（GateService, GameService, AIService等）
├── data/
│   └── repositories/     # データリポジトリ
└── presentation/
    ├── providers/        # 状態管理（Provider）
    ├── screens/          # 画面
    ├── widgets/          # 再利用可能なウィジェット
    └── theme/            # テーマ定義
```

## セットアップ

### 前提条件

- Flutter SDK 3.0以上
- Dart 3.0以上

### インストール手順

詳細なインストール手順は [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md) を参照してください。

#### クイックスタート

1. **Flutter SDKをインストール**
   - https://flutter.dev/docs/get-started/install/windows
   - 環境変数PATHに`flutter\bin`を追加

2. **Flutterの動作確認**
   ```bash
   flutter --version
   flutter doctor
   ```

3. **プロジェクトのセットアップ**
   ```bash
   # プロジェクトディレクトリに移動
   cd C:\Users\sken1\Documents\NEDO\q_reversi\q-reversi-app
   
   # Flutterプロジェクトを初期化（プラットフォーム設定ファイルを生成）
   flutter create .
   
   # 依存関係をインストール
   flutter pub get
   ```

4. **アプリを実行**
   ```bash
   # Android/iOS
   flutter run
   
   # Webブラウザ
   flutter run -d chrome
   ```

## ゲームルール

### 量子ゲート

- **Hゲート**: グレープラスと白、グレーマイナスと黒を入れ替える
- **Xゲート**: 白と黒を入れ替える
- **Yゲート**: 白と黒、グレープラスとグレーマイナスを入れ替える
- **Zゲート**: グレープラスとグレーマイナスを入れ替える
- **CNOTゲート**: 制御NOTゲート（エンタングル状態を生成可能）
- **SWAPゲート**: 2駒を入れ替える

### クールタイム

各ゲートにはクールタイムがあります:
- H: 2ターン
- X/Y: 6ターン
- Z: 0ターン
- CNOT/SWAP: 3ターン

### エンタングルメント

CNOTゲートを使用すると、特定の条件でエンタングル状態を生成できます。エンタングルされた駒にはゲート操作ができません。

## ライセンス

このプロジェクトは設計書に基づいて実装されています。

