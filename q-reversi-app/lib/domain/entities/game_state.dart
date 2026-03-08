import 'package:equatable/equatable.dart';
import 'board.dart';
import 'player.dart';
import 'game_mode.dart';
import 'entangled_pair.dart';
import 'forbidden_area.dart';
import 'position.dart';

/// ゲーム状態
class GameState extends Equatable {
  final Board board;
  final int currentPlayer; // 1 or 2
  final int turnCount;
  final int maxTurns;
  final GameMode gameMode;
  final VsMode? vsMode;
  final Map<int, Player> players; // プレイヤーID -> プレイヤー
  final Map<int, List<ForbiddenArea>> forbiddenAreas; // プレイヤーID -> 禁止領域リスト
  final List<EntangledPair> entangledPairs;
  final Map<int, List<Position>> lastTwoBitGatePositions; // プレイヤーID -> 最後に適用された2ビットゲートの位置リスト
  
  const GameState({
    required this.board,
    this.currentPlayer = 1,
    this.turnCount = 0,
    this.maxTurns = 20,
    required this.gameMode,
    this.vsMode,
    this.players = const {},
    this.forbiddenAreas = const {},
    this.entangledPairs = const [],
    this.lastTwoBitGatePositions = const {},
  });
  
  GameState copyWith({
    Board? board,
    int? currentPlayer,
    int? turnCount,
    int? maxTurns,
    GameMode? gameMode,
    VsMode? vsMode,
    Map<int, Player>? players,
    Map<int, List<ForbiddenArea>>? forbiddenAreas,
    List<EntangledPair>? entangledPairs,
    Map<int, List<Position>>? lastTwoBitGatePositions,
  }) {
    return GameState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      turnCount: turnCount ?? this.turnCount,
      maxTurns: maxTurns ?? this.maxTurns,
      gameMode: gameMode ?? this.gameMode,
      vsMode: vsMode ?? this.vsMode,
      players: players ?? this.players,
      forbiddenAreas: forbiddenAreas ?? this.forbiddenAreas,
      entangledPairs: entangledPairs ?? this.entangledPairs,
      lastTwoBitGatePositions: lastTwoBitGatePositions ?? this.lastTwoBitGatePositions,
    );
  }
  
  /// プレイヤーの最後に適用された2ビットゲートの位置を取得
  List<Position> getLastTwoBitGatePositions(int playerId) {
    return lastTwoBitGatePositions[playerId] ?? [];
  }
  
  /// 現在のプレイヤーを取得
  Player? getCurrentPlayer() {
    return players[currentPlayer];
  }
  
  /// 相手プレイヤーを取得
  Player? getOpponentPlayer() {
    final opponentId = currentPlayer == 1 ? 2 : 1;
    return players[opponentId];
  }
  
  /// プレイヤーの禁止領域を取得
  List<ForbiddenArea> getForbiddenAreas(int playerId) {
    return forbiddenAreas[playerId] ?? [];
  }
  
  /// エンタングルペアを取得
  EntangledPair? getEntangledPair(String pairId) {
    try {
      return entangledPairs.firstWhere((p) => p.id == pairId);
    } catch (e) {
      return null;
    }
  }
  
  /// ゲーム終了かどうか
  ///
  /// フリーランモードではターン制限による終了は行わない
  bool get isGameOver {
    if (gameMode == GameMode.freeRun) {
      return false;
    }
    return turnCount >= maxTurns;
  }
  
  @override
  List<Object?> get props => [
    board,
    currentPlayer,
    turnCount,
    maxTurns,
    gameMode,
    vsMode,
    players,
    forbiddenAreas,
    entangledPairs,
    lastTwoBitGatePositions,
  ];
}

