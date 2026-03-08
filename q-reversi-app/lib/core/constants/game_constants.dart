/// ゲーム定数
class GameConstants {
  // 盤面サイズ
  static const int defaultBoardSize = 8;
  static const int study1BoardSize = 1;
  static const int study2BoardRows = 1;
  static const int study2BoardCols = 2;
  static const int study3BoardRows = 1;
  static const int study3BoardCols = 4;
  
  // 初期配置
  static const int piecesPerType = 16; // 8×8の場合、各タイプ16個
  
  // クールタイム
  static const Map<String, int> gateCooldowns = {
    'H': 2,
    'X': 6,
    'Y': 6,
    'Z': 0,
    'CNOT': 3,
    'SWAP': 3,
  };
  
  // VSモードのターン制限オプション
  static const List<int> vsModeTurnOptions = [20, 30, 40, 50, 60];
  static const int defaultVsModeTurns = 20;
  
  // 色定義（量子・宇宙テーマ）
  static const int primaryPurple = 0xFF6B46C1;
  static const int cyan = 0xFF06B6D4;
  static const int neonBlue = 0xFF3B82F6;
  static const int purple = 0xFFA855F7;
  static const int pink = 0xFFEC4899;
  static const int gold = 0xFFFBBF24;
  static const int white = 0xFFFFFFFF;
  static const int black = 0xFF1A1F3A;
  static const int darkGray = 0xFF4A5568;
  
  // 背景グラデーション
  static const int bgDark1 = 0xFF0A0E27;
  static const int bgDark2 = 0xFF1A1F3A;
  static const int bgDark3 = 0xFF000000;
}

