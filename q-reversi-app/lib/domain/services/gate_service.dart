import '../entities/piece_type.dart';
import '../entities/gate_type.dart';
import '../entities/position.dart';
import '../entities/board.dart';
import '../entities/player.dart';
import '../entities/game_state.dart';
import '../entities/entangled_pair.dart';
import '../entities/game_mode.dart';
import '../entities/piece.dart';
import '../entities/forbidden_area.dart';
import 'dart:math';

/// 量子ゲートサービス
class GateService {
  final Random _random = Random();
  
  /// ゲートを適用
  GameState applyGate(
    GameState gameState,
    GateType gate,
    List<Position> targetPositions,
  ) {
    if (gate.isOneBitGate) {
      return _applyOneBitGate(gameState, gate, targetPositions);
    } else {
      return _applyTwoBitGate(gameState, gate, targetPositions);
    }
  }
  
  /// 1ビットゲートを適用
  GameState _applyOneBitGate(
    GameState gameState,
    GateType gate,
    List<Position> positions,
  ) {
    var newBoard = gameState.board;
    final currentPlayer = gameState.getCurrentPlayer();
    if (currentPlayer == null) return gameState;
    
    // 禁止領域を取得（1ビットゲートのみ適用）
    final forbiddenAreas = gameState.getForbiddenAreas(currentPlayer.id);
    
    // 位置が禁止領域かどうかをチェック（1ビットゲートのみ）
    bool isPositionForbidden(Position position) {
      for (final area in forbiddenAreas) {
        if (area.type == ForbiddenAreaType.row && area.row == position.row) {
          return true;
        }
        if (area.type == ForbiddenAreaType.column && area.column == position.col) {
          return true;
        }
        if (area.type == ForbiddenAreaType.fourPieces && area.positions != null) {
          if (area.positions!.any((p) => p == position)) {
            return true;
          }
        }
      }
      return false;
    }
    
    // 仕様: 縦横1列にゲートを適用した場合、エンタングルした駒でゲート適用範囲は止まる
    // 4マス四方範囲にゲートを適用した中にエンタングルした駒が存在した場合、エンタングルされた駒のみゲートが適用されない
    final isRowOrColumn = positions.length == 8; // 行または列
    
    for (final position in positions) {
      final piece = newBoard.getPiece(position.row, position.col);
      if (piece == null) continue;
      
      // 禁止領域の処理（1ビットゲートのみ）
      // 禁止領域の駒は、行/列選択時も4マス選択時も、その駒のみスキップして次の駒に進む
      if (isPositionForbidden(position)) {
        continue; // 禁止領域の駒のみスキップ
      }
      
      // エンタングル状態の処理
      if (piece.isEntangled) {
        if (isRowOrColumn) {
          // 行/列選択の場合: エンタングルした駒でゲート適用範囲は止まる
          break;
        } else {
          // 4マス選択の場合: エンタングルされた駒のみゲートが適用されない（スキップ）
          continue;
        }
      }
      
      final newType = _applyOneBitGateToPiece(piece.type, gate, currentPlayer.color);
      final newPiece = piece.copyWith(type: newType);
      newBoard = newBoard.setPiece(position.row, position.col, newPiece);
    }
    
    return gameState.copyWith(board: newBoard);
  }
  
  /// 1ビットゲートを駒に適用
  PieceType _applyOneBitGateToPiece(
    PieceType pieceType,
    GateType gate,
    PlayerColor playerColor,
  ) {
    switch (gate) {
      case GateType.x:
        // Xゲート: 白と黒を入れ替える
        if (pieceType == PieceType.white) return PieceType.black;
        if (pieceType == PieceType.black) return PieceType.white;
        return pieceType;
        
      case GateType.h:
        // Hゲート: グレープラスと白、グレーマイナスと黒を入れ替える
        if (pieceType == PieceType.grayPlus) return PieceType.white;
        if (pieceType == PieceType.white) return PieceType.grayPlus;
        if (pieceType == PieceType.grayMinus) return PieceType.black;
        if (pieceType == PieceType.black) return PieceType.grayMinus;
        return pieceType;
        
      case GateType.y:
        // Yゲート: 白と黒を入れ替える、グレープラスとグレーマイナスを入れ替える
        if (pieceType == PieceType.white) return PieceType.black;
        if (pieceType == PieceType.black) return PieceType.white;
        if (pieceType == PieceType.grayPlus) return PieceType.grayMinus;
        if (pieceType == PieceType.grayMinus) return PieceType.grayPlus;
        return pieceType;
        
      case GateType.z:
        // Zゲート: グレープラスとグレーマイナスを入れ替える
        if (pieceType == PieceType.grayPlus) return PieceType.grayMinus;
        if (pieceType == PieceType.grayMinus) return PieceType.grayPlus;
        return pieceType;
        
      default:
        return pieceType;
    }
  }
  
  /// 2ビットゲートを適用
  GameState _applyTwoBitGate(
    GameState gameState,
    GateType gate,
    List<Position> positions,
  ) {
    if (positions.length != 2) return gameState;
    
    final pos1 = positions[0];
    final pos2 = positions[1];
    
    if (!pos1.isAdjacent(pos2)) return gameState;
    
    var newBoard = gameState.board;
    final currentPlayer = gameState.getCurrentPlayer();
    if (currentPlayer == null) return gameState;
    
    final piece1 = newBoard.getPiece(pos1.row, pos1.col);
    final piece2 = newBoard.getPiece(pos2.row, pos2.col);
    
    if (piece1 == null || piece2 == null) return gameState;
    if (piece1.isEntangled || piece2.isEntangled) return gameState;
    
    // 2ビットゲートでは禁止領域チェックは行わない（禁止領域は1ビットゲートのみ適用）
    
    if (gate == GateType.swap) {
      // SWAPゲート: 2駒を入れ替える
      final newPiece1 = piece1.copyWith(position: pos2);
      final newPiece2 = piece2.copyWith(position: pos1);
      newBoard = newBoard.setPiece(pos1.row, pos1.col, newPiece2);
      newBoard = newBoard.setPiece(pos2.row, pos2.col, newPiece1);
    } else if (gate == GateType.cnot) {
      // CNOTゲート
      final result = _applyCNOT(piece1, piece2, currentPlayer.color, gameState);
      newBoard = newBoard.setPiece(pos1.row, pos1.col, result.piece1);
      newBoard = newBoard.setPiece(pos2.row, pos2.col, result.piece2);
      
      // エンタングル状態が生成された場合
      if (result.entangledPairId != null) {
        final newPairs = List<EntangledPair>.from(gameState.entangledPairs);
        newPairs.add(EntangledPair(
          id: result.entangledPairId!,
          position1: pos1,
          position2: pos2,
        ));
        return gameState.copyWith(
          board: newBoard,
          entangledPairs: newPairs,
        );
      }
    }
    
    return gameState.copyWith(board: newBoard);
  }
  
  /// CNOTゲートを適用
  _CNOTResult _applyCNOT(
    Piece piece1,
    Piece piece2,
    PlayerColor playerColor,
    GameState gameState,
  ) {
    final isVsMode = gameState.gameMode == GameMode.vs;
    
    // VSモードの場合、作用を逆にする（相手の色の時に反転）
    if (isVsMode) {
      // 一つ目が相手の手番の色の場合、二つ目の駒にXを作用させる
      if ((playerColor == PlayerColor.white && piece1.type == PieceType.black) ||
          (playerColor == PlayerColor.black && piece1.type == PieceType.white)) {
        final newType2 = _applyOneBitGateToPiece(piece2.type, GateType.x, playerColor);
        return _CNOTResult(
          piece1: piece1,
          piece2: piece2.copyWith(type: newType2),
        );
      }
      
      // 一つ目が自分の手番の色の場合、変化なし
      if ((playerColor == PlayerColor.white && piece1.type == PieceType.white) ||
          (playerColor == PlayerColor.black && piece1.type == PieceType.black)) {
        return _CNOTResult(piece1: piece1, piece2: piece2);
      }
    } else {
      // 通常モード: 一つ目が自分の手番の色の場合、二つ目の駒にXを作用させる
      if ((playerColor == PlayerColor.white && piece1.type == PieceType.white) ||
          (playerColor == PlayerColor.black && piece1.type == PieceType.black)) {
        final newType2 = _applyOneBitGateToPiece(piece2.type, GateType.x, playerColor);
        return _CNOTResult(
          piece1: piece1,
          piece2: piece2.copyWith(type: newType2),
        );
      }
      
      // 一つ目が相手の手番の色の場合、変化なし
      if ((playerColor == PlayerColor.white && piece1.type == PieceType.black) ||
          (playerColor == PlayerColor.black && piece1.type == PieceType.white)) {
        return _CNOTResult(piece1: piece1, piece2: piece2);
      }
    }
    
    // グレー駒の場合
    if (piece1.type == PieceType.grayPlus || piece1.type == PieceType.grayMinus) {
      return _applyCNOTWithGray(piece1, piece2, playerColor, isVsMode);
    }
    
    return _CNOTResult(piece1: piece1, piece2: piece2);
  }
  
  /// グレー駒を含むCNOTゲート
  _CNOTResult _applyCNOTWithGray(
    Piece piece1,
    Piece piece2,
    PlayerColor playerColor,
    bool isVsMode,
  ) {
    final pairId = 'entangled_${DateTime.now().millisecondsSinceEpoch}';
    
    // CNOTゲート詳細ルールに従って変換
    PieceType newType1;
    PieceType newType2;
    
    if (piece1.type == PieceType.grayPlus) {
      if (piece2.type == PieceType.grayPlus) {
        newType1 = PieceType.grayPlus;
        newType2 = PieceType.grayPlus;
      } else if (piece2.type == PieceType.grayMinus) {
        newType1 = PieceType.grayMinus;
        newType2 = PieceType.grayMinus;
      } else if (piece2.type == PieceType.white || piece2.type == PieceType.black) {
        // エンタングル状態を生成
        // VSモードの場合、作用を逆にする（相手の色の時にエンタングル）
        final isMyColor = (playerColor == PlayerColor.white && piece2.type == PieceType.white) ||
                          (playerColor == PlayerColor.black && piece2.type == PieceType.black);
        if (isVsMode) {
          // VSモード: 相手の色の時にエンタングル
          if (!isMyColor) {
            newType1 = PieceType.whiteBlack;
            newType2 = PieceType.blackWhite;
          } else {
            newType1 = PieceType.whiteBlack;
            newType2 = PieceType.whiteBlack;
          }
        } else {
          // 通常モード: 自分の色の時にエンタングル
          if (isMyColor) {
            newType1 = PieceType.whiteBlack;
            newType2 = PieceType.blackWhite;
          } else {
            newType1 = PieceType.whiteBlack;
            newType2 = PieceType.whiteBlack;
          }
        }
      } else {
        newType1 = piece1.type;
        newType2 = piece2.type;
      }
    } else if (piece1.type == PieceType.grayMinus) {
      if (piece2.type == PieceType.grayPlus) {
        newType1 = PieceType.grayMinus;
        newType2 = PieceType.grayMinus;
      } else if (piece2.type == PieceType.grayMinus) {
        newType1 = PieceType.grayPlus;
        newType2 = PieceType.grayMinus;
      } else if (piece2.type == PieceType.white || piece2.type == PieceType.black) {
        // エンタングル状態を生成
        // VSモードの場合、作用を逆にする（相手の色の時にエンタングル）
        final isMyColor = (playerColor == PlayerColor.white && piece2.type == PieceType.white) ||
                          (playerColor == PlayerColor.black && piece2.type == PieceType.black);
        if (isVsMode) {
          // VSモード: 相手の色の時にエンタングル
          if (!isMyColor) {
            newType1 = PieceType.blackWhite;
            newType2 = PieceType.whiteBlack;
          } else {
            newType1 = PieceType.blackWhite;
            newType2 = PieceType.blackWhite;
          }
        } else {
          // 通常モード: 自分の色の時にエンタングル
          if (isMyColor) {
            newType1 = PieceType.blackWhite;
            newType2 = PieceType.whiteBlack;
          } else {
            newType1 = PieceType.blackWhite;
            newType2 = PieceType.blackWhite;
          }
        }
      } else {
        newType1 = piece1.type;
        newType2 = piece2.type;
      }
    } else {
      newType1 = piece1.type;
      newType2 = piece2.type;
    }
    
    final newPiece1 = piece1.copyWith(
      type: newType1,
      entangledPairId: (newType1.isEntangled || newType2.isEntangled) ? pairId : null,
    );
    final newPiece2 = piece2.copyWith(
      type: newType2,
      entangledPairId: (newType1.isEntangled || newType2.isEntangled) ? pairId : null,
    );
    
    return _CNOTResult(
      piece1: newPiece1,
      piece2: newPiece2,
      entangledPairId: (newType1.isEntangled || newType2.isEntangled) ? pairId : null,
    );
  }
}

/// CNOTゲート適用結果
class _CNOTResult {
  final Piece piece1;
  final Piece piece2;
  final String? entangledPairId;
  
  _CNOTResult({
    required this.piece1,
    required this.piece2,
    this.entangledPairId,
  });
}

