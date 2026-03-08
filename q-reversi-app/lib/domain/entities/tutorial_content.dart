import 'gate_type.dart';

/// チュートリアルコンテンツ（既存のチャレンジモード用）
class TutorialContent {
  final String id;
  final String title;
  final String description;
  final TutorialType type;
  final GateType? gate; // ゲート説明の場合
  final List<String>? bulletPoints; // 箇条書き
  final TutorialAnimation? animation; // アニメーション説明

  const TutorialContent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.gate,
    this.bulletPoints,
    this.animation,
  });
}

/// チュートリアルページ（全画面チュートリアル用）
class TutorialPage {
  final int pageNumber;
  final String pageId;
  final String pageTitle;
  final List<TutorialSlide> slides; // スライド分割対応

  const TutorialPage({
    required this.pageNumber,
    required this.pageId,
    required this.pageTitle,
    required this.slides,
  });
}

/// チュートリアルスライド
class TutorialSlide {
  final String slideId;
  final String? slideTitle;
  final List<String> texts; // テキスト（複数行対応）
  final TutorialVisualElement? visualElement; // 視覚要素

  const TutorialSlide({
    required this.slideId,
    this.slideTitle,
    required this.texts,
    this.visualElement,
  });
}

/// 視覚要素の種類
enum VisualElementType {
  image,           // 画像
  animation,       // アニメーション
  video,           // 動画
  diagram,         // 図解
  comparison,      // 比較図
  transformation,  // 変換図
  board,           // 盤面表示
  gateList,         // ゲート一覧
}

/// 視覚要素
class TutorialVisualElement {
  final VisualElementType type;
  final Map<String, dynamic>? data; // 視覚要素固有のデータ

  const TutorialVisualElement({
    required this.type,
    this.data,
  });
}

/// チュートリアルタイプ
enum TutorialType {
  concept,      // 概念説明
  gateExplain,  // ゲート説明
  operation,    // 操作説明
}

/// チュートリアルアニメーション
class TutorialAnimation {
  final AnimationType type;
  final Duration duration;
  final Map<String, dynamic>? data; // アニメーション固有のデータ

  const TutorialAnimation({
    required this.type,
    required this.duration,
    this.data,
  });
}

/// アニメーションタイプ
enum AnimationType {
  operationDemo, // 操作デモ（ゲート選択→列選択→4マス選択→適用）
}

