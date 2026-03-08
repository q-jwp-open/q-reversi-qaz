/// ゲームモード
enum GameMode {
  challenge,    // チャレンジモード
  vs,           // VSモード
  freeRun,      // フリーランモード
  study,        // スタディモード
  professional, // プロフェッショナルモード（将来拡張）
}

/// VSモードの種類
enum VsMode {
  human,  // 対人戦
  cpu,    // 対CPU戦
}

/// スタディモードの種類
enum StudyMode {
  study1,  // 1ビットゲート学習
  study2,  // 2ビットゲート学習
  study3,  // 量子アルゴリズム実装
}

/// AI難易度
enum AIDifficulty {
  beginner,     // 初級
  intermediate, // 中級
  advanced,     // 上級
  quantum,      // 量子AI (4-ply minimax with P(win) terminal)
}

/// プレイヤーの色
enum PlayerColor {
  white,  // 白
  black,  // 黒
}

