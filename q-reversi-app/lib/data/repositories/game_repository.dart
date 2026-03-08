import '../../domain/entities/game_state.dart';

/// ゲームリポジトリ（簡略版）
class GameRepository {
  /// ゲーム状態を保存
  Future<void> saveGameState(GameState gameState) async {
    // TODO: SQLiteに保存
  }
  
  /// ゲーム状態を読み込み
  Future<GameState?> loadGameState() async {
    // TODO: SQLiteから読み込み
    return null;
  }
  
  /// ゲーム状態を削除
  Future<void> deleteGameState() async {
    // TODO: SQLiteから削除
  }
}

