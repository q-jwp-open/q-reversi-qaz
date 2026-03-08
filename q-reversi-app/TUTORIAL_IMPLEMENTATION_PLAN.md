# チュートリアル実装計画

## 実装の進め方

### フェーズ1: 基本構造の作成（優先度: 高）

#### 1.1 チュートリアル画面の作成
- **ファイル**: `lib/presentation/screens/tutorial_screen.dart`
- **内容**:
  - 全画面表示（ダイアログではない）
  - PageViewでページ間のスワイプ対応
  - 各ページ内のスライドもPageViewで実装
  - 進捗表示（ページ番号、スライドドット）
  - ナビゲーションボタン（前へ・次へ・スキップ）

#### 1.2 エンティティの拡張
- **ファイル**: `lib/domain/entities/tutorial_content.dart`
- **変更点**:
  - スライド分割に対応（`List<TutorialSlide>`を追加）
  - 視覚要素の型を追加（画像、アニメーション、図解など）
  - ページタイプの追加（Welcome、基本操作、概念説明、ゲート説明など）

#### 1.3 サービスの拡張
- **ファイル**: `lib/domain/services/tutorial_service.dart`
- **変更点**:
  - `getFullTutorial()`メソッドを追加（全14ページのコンテンツ）
  - 各ページのコンテンツを仕様書に基づいて実装
  - スライド分割の情報を含める

### フェーズ2: ゲームモード選択画面への統合（優先度: 高）

#### 2.1 チュートリアルボタンの追加
- **ファイル**: `lib/presentation/screens/game_mode_selection_screen.dart`
- **変更点**:
  - ListViewの先頭に「チュートリアル」カードを追加
  - タップでTutorialScreenに遷移

### フェーズ3: 視覚要素の実装（優先度: 中）

#### 3.1 各ページタイプのウィジェット作成
- **ファイル**: `lib/presentation/widgets/tutorial/`
  - `tutorial_welcome_page.dart` - ページ0
  - `tutorial_operation_page.dart` - ページ1
  - `tutorial_concept_page.dart` - ページ2-4（概念説明）
  - `tutorial_gate_page.dart` - ページ5-9（ゲート説明）
  - `tutorial_cnot_page.dart` - ページ10-12（CNOTゲート）
  - `tutorial_finish_page.dart` - ページ13

#### 3.2 アニメーション実装
- **ファイル**: `lib/presentation/widgets/tutorial/animations/`
  - `gate_transformation_animation.dart` - ゲート変換アニメーション
  - `measurement_animation.dart` - 測定アニメーション
  - `operation_demo_animation.dart` - 基本操作デモ（既存を拡張）

#### 3.3 図解ウィジェット
- **ファイル**: `lib/presentation/widgets/tutorial/diagrams/`
  - `bit_comparison_diagram.dart` - 通常/量子コンピュータ比較
  - `gate_diagram.dart` - ゲート変換図
  - `entanglement_diagram.dart` - エンタングルメント図

### フェーズ4: スワイプ分割の実装（優先度: 中）

#### 4.1 スライド管理
- 各ページでスライド数を管理
- PageViewでスライド間のスワイプを実装
- スライドドットインジケーターを実装

#### 4.2 ナビゲーション制御
- ページ間の移動
- スライド間の移動
- 最後のスライドで次のページへ進む

### フェーズ5: 細かい調整（優先度: 低）

#### 5.1 アニメーションの調整
- 速度の統一
- エフェクトの追加（グロー、パーティクルなど）

#### 5.2 UI/UXの改善
- 色の統一
- フォントサイズの調整
- レスポンシブ対応

## 実装の順序

1. **まず実装すべきもの**:
   - TutorialScreenの基本構造
   - ゲームモード選択画面へのボタン追加
   - ページ0（Welcome）の実装（テキストのみでも可）

2. **次に実装すべきもの**:
   - ページ1-4の基本実装（テキスト + 簡単な図解）
   - スワイプ分割の基本機能
   - ナビゲーションボタン

3. **その後実装すべきもの**:
   - ゲート説明ページ（ページ5-9）の詳細実装
   - CNOTゲートページ（ページ10-12）の詳細実装
   - アニメーションの実装

4. **最後に調整すべきもの**:
   - 視覚効果の追加
   - アニメーションの細かい調整
   - UI/UXの改善

## 技術的な注意点

1. **PageViewのネスト**:
   - 外側のPageView: ページ間の移動
   - 内側のPageView: スライド間の移動
   - スワイプの方向を適切に制御

2. **状態管理**:
   - 現在のページ番号
   - 現在のスライド番号（各ページごと）
   - 進捗の保存（オプション）

3. **パフォーマンス**:
   - 画像の遅延読み込み
   - アニメーションの最適化
   - 不要な再描画の防止

## ファイル構成

```
lib/
├── domain/
│   ├── entities/
│   │   └── tutorial_content.dart (拡張)
│   └── services/
│       └── tutorial_service.dart (拡張)
└── presentation/
    ├── screens/
    │   ├── tutorial_screen.dart (新規)
    │   └── game_mode_selection_screen.dart (修正)
    └── widgets/
        └── tutorial/
            ├── tutorial_welcome_page.dart (新規)
            ├── tutorial_operation_page.dart (新規)
            ├── tutorial_concept_page.dart (新規)
            ├── tutorial_gate_page.dart (新規)
            ├── tutorial_cnot_page.dart (新規)
            ├── tutorial_finish_page.dart (新規)
            ├── animations/
            │   ├── gate_transformation_animation.dart (新規)
            │   ├── measurement_animation.dart (新規)
            │   └── operation_demo_animation.dart (既存を拡張)
            └── diagrams/
                ├── bit_comparison_diagram.dart (新規)
                ├── gate_diagram.dart (新規)
                └── entanglement_diagram.dart (新規)
```


