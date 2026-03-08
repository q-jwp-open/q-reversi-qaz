import '../entities/game_state.dart';
import '../entities/gate_type.dart';
import '../entities/position.dart';
import '../entities/forbidden_area.dart';
import '../entities/player.dart';
import '../entities/piece_type.dart';
import '../entities/piece.dart';
import '../entities/game_mode.dart';
import 'gate_service.dart';

/// ゲームサービス
class GameService {
  final GateService _gateService = GateService();
  
  /// ゲートを適用（完全な処理）
  GameState applyGateWithFullLogic(
    GameState gameState,
    GateType gate,
    List<Position> targetPositions,
  ) {
    final currentPlayer = gameState.getCurrentPlayer();
    if (currentPlayer == null) return gameState;
    
    // クールタイムチェック（フリーランモードとチャレンジモードではスキップ）
    if (gameState.gameMode != GameMode.freeRun && 
        gameState.gameMode != GameMode.challenge && 
        !currentPlayer.canUseGate(gate)) {
      return gameState; // エラー: クールタイム中
    }
    
    // 禁止領域チェック（1ビットゲートのみ適用、フリーランモードとチャレンジモードではスキップ）
    if (gate.isOneBitGate && 
        gameState.gameMode != GameMode.freeRun && 
        gameState.gameMode != GameMode.challenge) {
      final opponent = gameState.getOpponentPlayer();
      if (opponent != null) {
        final opponentForbiddenAreas = gameState.getForbiddenAreas(opponent.id);
        for (final area in opponentForbiddenAreas) {
          if (_isTargetForbidden(area, gate, targetPositions)) {
            return gameState; // エラー: 禁止領域
          }
        }
      }
    }
    
    // エンタングルメントチェック（仕様: エンタングルされた駒にはゲート操作不可）
    // ただし、1ビットゲートの場合は適用範囲が止まるか、その駒のみスキップされる
    // 2ビットゲートの場合は完全に適用不可
    if (gate.isTwoBitGate) {
      for (final position in targetPositions) {
        final piece = gameState.board.getPiece(position.row, position.col);
        if (piece != null && piece.isEntangled) {
          return gameState; // エラー: エンタングル状態（2ビットゲートは完全に適用不可）
        }
      }
    }
    // 1ビットゲートの場合は、GateService内で適切に処理される
    
    // ゲートを適用
    var newState = _gateService.applyGate(gameState, gate, targetPositions);
    
    // クールタイムを更新（フリーランモードとチャレンジモードではクールタイムを設定しない）
    final updatedPlayer = (gameState.gameMode == GameMode.freeRun || gameState.gameMode == GameMode.challenge)
        ? currentPlayer
        : currentPlayer.useGate(gate);
    final newPlayers = Map<int, Player>.from(newState.players);
    newPlayers[currentPlayer.id] = updatedPlayer;
    
    // フリーランモードまたはチャレンジモードの場合はターンを進めるが、プレイヤーは変更しない
    if (gameState.gameMode == GameMode.freeRun || gameState.gameMode == GameMode.challenge) {
      // クールタイムを減少（自分のクールタイムを減少）
      final decreasedPlayer = updatedPlayer.decreaseCooldowns();
      newPlayers[currentPlayer.id] = decreasedPlayer;
      
      return newState.copyWith(
        players: newPlayers,
        turnCount: newState.turnCount + 1,
        // チャレンジモードとフリーランモードではcurrentPlayerを変更しない
        currentPlayer: gameState.currentPlayer,
      );
    }
    
    // 禁止領域を設定（仕様: 相手の次のターンのみ有効）
    final forbiddenArea = _createForbiddenArea(gate, targetPositions);
    final newForbiddenAreas = Map<int, List<ForbiddenArea>>.from(newState.forbiddenAreas);
    final opponentId = newState.currentPlayer == 1 ? 2 : 1;
    
    // 現在のプレイヤーの禁止領域をクリア（自分のターンが終了したら）
    newForbiddenAreas[currentPlayer.id] = [];
    
    // 相手の禁止領域を設定
    newForbiddenAreas[opponentId] = [forbiddenArea];
    
    // 2ビットゲートが適用された場合、位置を記録（次のターンのプレイヤーに設定）
    final newLastTwoBitGatePositions = Map<int, List<Position>>.from(newState.lastTwoBitGatePositions);
    if (gate.isTwoBitGate && targetPositions.length == 2) {
      // 現在のプレイヤーの記録をクリア
      newLastTwoBitGatePositions[currentPlayer.id] = [];
      // 次のターンのプレイヤー（相手）に記録
      newLastTwoBitGatePositions[opponentId] = List.from(targetPositions);
    } else {
      // 1ビットゲートの場合は、現在のプレイヤーの記録をクリア
      newLastTwoBitGatePositions[currentPlayer.id] = [];
    }
    
    // ターンを進める
    final nextPlayer = newState.currentPlayer == 1 ? 2 : 1;
    final nextPlayerObj = newPlayers[nextPlayer];
    if (nextPlayerObj != null) {
      // 相手のクールタイムを減少
      newPlayers[nextPlayer] = nextPlayerObj.decreaseCooldowns();
    }
    
    // 禁止領域は次のターンのプレイヤー（opponentId）に設定されているので、
    // そのまま使用する（クリアしない）
    
    return newState.copyWith(
      players: newPlayers,
      forbiddenAreas: newForbiddenAreas,
      lastTwoBitGatePositions: newLastTwoBitGatePositions,
      currentPlayer: nextPlayer,
      turnCount: newState.turnCount + 1,
    );
  }
  
  /// ターゲットが禁止領域かどうか
  bool _isTargetForbidden(
    ForbiddenArea area,
    GateType gate,
    List<Position> targetPositions,
  ) {
    if (gate.isOneBitGate) {
      if (area.type == ForbiddenAreaType.row && targetPositions.isNotEmpty) {
        return area.row == targetPositions.first.row;
      }
      if (area.type == ForbiddenAreaType.column && targetPositions.isNotEmpty) {
        return area.column == targetPositions.first.col;
      }
      if (area.type == ForbiddenAreaType.fourPieces) {
        return area.isFourPiecesForbidden(targetPositions);
      }
    }
    return false;
  }
  
  /// 禁止領域を作成
  ForbiddenArea _createForbiddenArea(
    GateType gate,
    List<Position> targetPositions,
  ) {
    if (gate.isOneBitGate) {
      if (targetPositions.length == 8) {
        // 行または列
        if (targetPositions.every((p) => p.row == targetPositions.first.row)) {
          return ForbiddenArea.row(targetPositions.first.row);
        }
        if (targetPositions.every((p) => p.col == targetPositions.first.col)) {
          return ForbiddenArea.column(targetPositions.first.col);
        }
      }
      if (targetPositions.length == 4) {
        // 4マス選択
        return ForbiddenArea.fourPieces(targetPositions);
      }
    }
    // 2ビットゲートには禁止領域なし
    return ForbiddenArea.fourPieces(const []);
  }
  
  /// 初期盤面を生成（ランダム、各タイプ25%）
  GameState createInitialBoard(GameState gameState) {
    final board = gameState.board;
    final totalCells = board.rows * board.cols;
    final piecesPerType = totalCells ~/ 4; // 各タイプ25%
    
    // 各タイプ16個ずつ（8×8の場合）
    final types = [
      PieceType.white,
      PieceType.black,
      PieceType.grayPlus,
      PieceType.grayMinus,
    ];
    final allPositions = <Position>[];
    
    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        allPositions.add(Position(r, c));
      }
    }
    
    allPositions.shuffle();
    
    // 各タイプのリストを作成
    final typeList = <PieceType>[];
    for (int i = 0; i < types.length; i++) {
      for (int j = 0; j < piecesPerType; j++) {
        typeList.add(types[i]);
      }
    }
    // 残りのマス（割り切れない場合）をランダムに割り当て
    while (typeList.length < totalCells) {
      typeList.add(types[typeList.length % types.length]);
    }
    typeList.shuffle();
    
    var newBoard = board;
    for (int i = 0; i < allPositions.length && i < typeList.length; i++) {
      final position = allPositions[i];
      final type = typeList[i];
      final piece = Piece(
        id: 'piece_${position.row}_${position.col}',
        type: type,
        position: position,
      );
      newBoard = newBoard.setPiece(position.row, position.col, piece);
    }
    
    return gameState.copyWith(board: newBoard);
  }
  
  /// 盤面をすべて白または黒にする
  GameState setAllPiecesToColor(GameState gameState, bool isWhite) {
    final board = gameState.board;
    final pieceType = isWhite ? PieceType.white : PieceType.black;
    
    var newBoard = board;
    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        final position = Position(r, c);
        final piece = Piece(
          id: 'piece_${r}_$c',
          type: pieceType,
          position: position,
        );
        newBoard = newBoard.setPiece(r, c, piece);
      }
    }
    
    return gameState.copyWith(board: newBoard);
  }
}

