import 'dart:math';
import '../entities/game_state.dart';
import '../entities/gate_type.dart';
import '../entities/position.dart';
import '../entities/piece_type.dart';
import '../entities/piece.dart';
import '../entities/game_mode.dart';
import 'game_service.dart';

// ─── Quantum AI helpers (module-level) ───────────────────────────────────────

/// Abramowitz & Stegun 7.1.26 approximation of erf(x), max error < 1.5e-7.
double _erf(double x) {
  const p  = 0.3275911;
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  final sign = x < 0 ? -1.0 : 1.0;
  final ax = x.abs();
  final t = 1.0 / (1.0 + p * ax);
  final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-ax * ax);
  return sign * y;
}

/// Classical evaluation: (certain_mine − certain_opp) / 64.
double _classicalEval(GameState state, PlayerColor myColor) {
  var mine = 0;
  var opp  = 0;
  final board = state.board;
  for (int r = 0; r < board.rows; r++) {
    for (int c = 0; c < board.cols; c++) {
      final piece = board.getPiece(r, c);
      if (piece == null) continue;
      if (myColor == PlayerColor.white) {
        if (piece.type == PieceType.white) mine++;
        else if (piece.type == PieceType.black) opp++;
      } else {
        if (piece.type == PieceType.black) mine++;
        else if (piece.type == PieceType.white) opp++;
      }
    }
  }
  return (mine - opp) / 64.0;
}

/// Quantum P(win): Φ(mu / sqrt(n_gray)) mapped to [−1, 1].
/// mu = certain_mine − certain_opp; n_gray = count of superposition pieces.
/// Entangled pieces (WHITE_BLACK / BLACK_WHITE) contribute 0 to both.
double _probWinEval(GameState state, PlayerColor myColor) {
  var mine  = 0;
  var opp   = 0;
  var nGray = 0;
  final board = state.board;
  for (int r = 0; r < board.rows; r++) {
    for (int c = 0; c < board.cols; c++) {
      final piece = board.getPiece(r, c);
      if (piece == null) continue;
      switch (piece.type) {
        case PieceType.white:
          if (myColor == PlayerColor.white) mine++; else opp++;
        case PieceType.black:
          if (myColor == PlayerColor.black) mine++; else opp++;
        case PieceType.grayPlus:
        case PieceType.grayMinus:
          nGray++;
        case PieceType.blackWhite:
        case PieceType.whiteBlack:
          break; // entangled: net = 0
      }
    }
  }
  final mu    = (mine - opp).toDouble();
  final sigma = sqrt(max(1.0, nGray.toDouble()));
  final z     = mu / (sigma * sqrt(2.0));
  final prob  = (1.0 + _erf(z)) / 2.0;
  return 2.0 * prob - 1.0;
}

// ─────────────────────────────────────────────────────────────────────────────

/// AI行動
class AIAction {
  final GateType gate;
  final List<Position> positions;
  final double score;

  AIAction({
    required this.gate,
    required this.positions,
    this.score = 0.0,
  });
}

/// AIサービス
class AIService {
  final Random _random = Random();
  final GameService _gameService = GameService();

  /// AIの思考
  Future<AIAction> think(
    GameState gameState,
    AIDifficulty difficulty,
  ) async {
    // 思考時間のシミュレーション
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1500)));

    final availableGates = _getAvailableGates(gameState);
    if (availableGates.isEmpty) {
      throw Exception('No available gates');
    }

    switch (difficulty) {
      case AIDifficulty.beginner:
        return _thinkBeginner(gameState, availableGates);
      case AIDifficulty.intermediate:
        return _thinkIntermediate(gameState, availableGates);
      case AIDifficulty.advanced:
        return _thinkAdvanced(gameState, availableGates);
      case AIDifficulty.quantum:
        return _thinkQuantum(gameState, availableGates);
    }
  }

  /// 初級AI（ランダム）
  AIAction _thinkBeginner(
    GameState gameState,
    List<GateType> availableGates,
  ) {
    final gate = availableGates[_random.nextInt(availableGates.length)];
    final target = _selectRandomTarget(gameState, gate);

    return AIAction(
      gate: gate,
      positions: target,
    );
  }

  /// 中級AI
  AIAction _thinkIntermediate(
    GameState gameState,
    List<GateType> availableGates,
  ) {
    final candidates = <AIAction>[];
    final currentPlayer = gameState.getCurrentPlayer();
    if (currentPlayer == null) {
      return _thinkBeginner(gameState, availableGates);
    }

    for (final gate in availableGates) {
      final targets = _getPossibleTargets(gameState, gate);

      for (final target in targets) {
        final simulatedState = _simulateGateApplication(
          gameState,
          gate,
          target,
        );

        final evaluation = _evaluateBoard(
          simulatedState,
          currentPlayer.color,
          AIDifficulty.intermediate,
        );

        candidates.add(AIAction(
          gate: gate,
          positions: target,
          score: evaluation,
        ));
      }
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    final topCandidates = candidates.take(3).toList();
    return topCandidates[_random.nextInt(topCandidates.length)];
  }

  /// 上級AI
  AIAction _thinkAdvanced(
    GameState gameState,
    List<GateType> availableGates,
  ) {
    final candidates = <AIAction>[];
    final currentPlayer = gameState.getCurrentPlayer();
    if (currentPlayer == null) {
      return _thinkBeginner(gameState, availableGates);
    }

    for (final gate in availableGates) {
      final targets = _getPossibleTargets(gameState, gate);

      for (final target in targets) {
        final simulatedState = _simulateGateApplication(
          gameState,
          gate,
          target,
        );

        final measurementScore = _predictMeasurementScore(
          simulatedState,
          currentPlayer.color,
        );

        final boardEvaluation = _evaluateBoard(
          simulatedState,
          currentPlayer.color,
          AIDifficulty.advanced,
        );

        final totalScore = measurementScore * 0.4 + boardEvaluation * 0.6;

        candidates.add(AIAction(
          gate: gate,
          positions: target,
          score: totalScore,
        ));
      }
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.first;
  }

  // ─── 量子AI (FourPlyMiniMaxQR port) ────────────────────────────────────────

  static const int _kQuantumK1 = 10; // depth-1 top candidates
  static const int _kQuantumK3 = 3;  // depth-3 top candidates

  /// 量子AI: 4-ply minimax with quantum P(win) terminal and pessimistic
  /// depth-4 tie-breaking (port of Python FourPlyMiniMaxQR).
  AIAction _thinkQuantum(
    GameState gameState,
    List<GateType> availableGates,
  ) {
    final currentPlayer = gameState.getCurrentPlayer();
    if (currentPlayer == null) return _thinkBeginner(gameState, availableGates);
    final myColor = currentPlayer.color;

    // Collect all (gate, positions) candidates for the AI at depth 1.
    final allActions = _getAllActionsForState(gameState);
    if (allActions.isEmpty) return _thinkBeginner(gameState, availableGates);

    // Score depth-1 states by classical eval and cache the resulting states.
    final depth1 = <({(GateType, List<Position>) action, GameState s1, double score})>[];
    for (final action in allActions) {
      final s1 = _tryApply(gameState, action.$1, action.$2);
      if (s1 == null) continue;
      depth1.add((action: action, s1: s1, score: _classicalEval(s1, myColor)));
    }
    if (depth1.isEmpty) return _thinkBeginner(gameState, availableGates);

    depth1.sort((a, b) => b.score.compareTo(a.score));
    final topK1 = depth1.take(_kQuantumK1).toList();

    // 4-ply minimax.
    var bestScore = double.negativeInfinity;
    var bestAction = topK1.first.action;

    for (final entry in topK1) {
      final score = _evalFromS2(entry.s1, myColor);
      if (score > bestScore) {
        bestScore = score;
        bestAction = entry.action;
      }
    }

    return AIAction(gate: bestAction.$1, positions: bestAction.$2, score: bestScore);
  }

  /// Depth 2 (greedy opp) → depth 3 (AI top-K3) → depth 4 (pessimistic opp).
  double _evalFromS2(GameState s1, PlayerColor myColor) {
    // Depth 2: opponent plays greedy (argmin classical eval for us).
    final opp1Actions = _getAllActionsForState(s1);
    GameState s2 = s1;
    if (opp1Actions.isNotEmpty) {
      var minScore = double.infinity;
      for (final a in opp1Actions) {
        final ns = _tryApply(s1, a.$1, a.$2);
        if (ns == null) continue;
        final sc = _classicalEval(ns, myColor);
        if (sc < minScore) { minScore = sc; s2 = ns; }
      }
    }

    // Depth 3: AI plays top-K3 by classical eval.
    final ai2Actions = _getAllActionsForState(s2);
    if (ai2Actions.isEmpty) return _probWinEval(s2, myColor);

    final depth3 = <({GameState s3, double score})>[];
    for (final a in ai2Actions) {
      final s3 = _tryApply(s2, a.$1, a.$2);
      if (s3 == null) continue;
      depth3.add((s3: s3, score: _classicalEval(s3, myColor)));
    }
    if (depth3.isEmpty) return _probWinEval(s2, myColor);

    depth3.sort((a, b) => b.score.compareTo(a.score));
    final topK3 = depth3.take(_kQuantumK3).toList();

    var bestK3 = double.negativeInfinity;
    for (final entry in topK3) {
      final s3 = entry.s3;

      // Depth 4: pessimistic opponent — all tied min-classical moves, take min P(win).
      final opp2Actions = _getAllActionsForState(s3);
      double v;
      if (opp2Actions.isEmpty) {
        v = _probWinEval(s3, myColor);
      } else {
        final opp2States = <GameState>[];
        final opp2Scores = <double>[];
        var minClassical = double.infinity;
        for (final a in opp2Actions) {
          final ns = _tryApply(s3, a.$1, a.$2);
          if (ns == null) continue;
          final sc = _classicalEval(ns, myColor);
          opp2States.add(ns);
          opp2Scores.add(sc);
          if (sc < minClassical) minClassical = sc;
        }
        if (opp2States.isEmpty) {
          v = _probWinEval(s3, myColor);
        } else {
          var minPWin = double.infinity;
          for (int j = 0; j < opp2States.length; j++) {
            if ((opp2Scores[j] - minClassical).abs() < 1e-12) {
              final pw = _probWinEval(opp2States[j], myColor);
              if (pw < minPWin) minPWin = pw;
            }
          }
          v = minPWin.isInfinite ? _probWinEval(s3, myColor) : minPWin;
        }
      }

      if (v > bestK3) bestK3 = v;
    }
    return bestK3;
  }

  /// Returns all (gate, positions) pairs available to the current player in [state].
  List<(GateType, List<Position>)> _getAllActionsForState(GameState state) {
    final player = state.getCurrentPlayer();
    if (player == null) return [];
    final result = <(GateType, List<Position>)>[];
    for (final gate in GateType.values) {
      if (!player.canUseGate(gate)) continue;
      for (final positions in _getPossibleTargets(state, gate)) {
        result.add((gate, positions));
      }
    }
    return result;
  }

  /// Applies gate; returns null if the application was rejected (turnCount unchanged).
  GameState? _tryApply(GameState state, GateType gate, List<Position> positions) {
    final next = _simulateGateApplication(state, gate, positions);
    return next.turnCount > state.turnCount ? next : null;
  }

  // ─────────────────────────────────────────────────────────────────────────

  /// 使用可能なゲートを取得
  List<GateType> _getAvailableGates(GameState gameState) {
    final currentPlayer = gameState.getCurrentPlayer();
    if (currentPlayer == null) return [];

    return GateType.values.where((gate) {
      return currentPlayer.canUseGate(gate);
    }).toList();
  }

  /// 可能なターゲットを取得
  List<List<Position>> _getPossibleTargets(
    GameState gameState,
    GateType gate,
  ) {
    final targets = <List<Position>>[];
    final board = gameState.board;

    if (gate.isTwoBitGate) {
      // 2ビットゲート: 隣接する2マス
      for (int r = 0; r < board.rows; r++) {
        for (int c = 0; c < board.cols; c++) {
          final pos1 = Position(r, c);
          for (int dr = -1; dr <= 1; dr++) {
            for (int dc = -1; dc <= 1; dc++) {
              if (dr == 0 && dc == 0) continue;
              final r2 = r + dr;
              final c2 = c + dc;
              if (board.isValidPosition(r2, c2)) {
                final pos2 = Position(r2, c2);
                if (pos1.isAdjacent(pos2)) {
                  targets.add([pos1, pos2]);
                }
              }
            }
          }
        }
      }
    } else {
      // 1ビットゲート: 行/列または4マス
      // 行
      for (int r = 0; r < board.rows; r++) {
        final rowPositions = <Position>[];
        for (int c = 0; c < board.cols; c++) {
          rowPositions.add(Position(r, c));
        }
        targets.add(rowPositions);
      }
      // 列
      for (int c = 0; c < board.cols; c++) {
        final colPositions = <Position>[];
        for (int r = 0; r < board.rows; r++) {
          colPositions.add(Position(r, c));
        }
        targets.add(colPositions);
      }
      // 4マス（簡略化: 左上から順に）
      for (int r = 0; r < board.rows - 1; r++) {
        for (int c = 0; c < board.cols - 1; c++) {
          targets.add([
            Position(r, c),
            Position(r, c + 1),
            Position(r + 1, c),
            Position(r + 1, c + 1),
          ]);
        }
      }
    }

    return targets;
  }

  /// ランダムなターゲットを選択
  List<Position> _selectRandomTarget(
    GameState gameState,
    GateType gate,
  ) {
    final targets = _getPossibleTargets(gameState, gate);
    if (targets.isEmpty) return [];
    return targets[_random.nextInt(targets.length)];
  }

  /// ゲート適用をシミュレート
  GameState _simulateGateApplication(
    GameState gameState,
    GateType gate,
    List<Position> targetPositions,
  ) {
    // 簡略化: 実際の適用ロジックを呼び出す
    return _gameService.applyGateWithFullLogic(
      gameState,
      gate,
      targetPositions,
    );
  }

  /// 盤面を評価
  double _evaluateBoard(
    GameState gameState,
    PlayerColor myColor,
    AIDifficulty difficulty,
  ) {
    var myPieceScore = 0.0;
    var opponentPieceScore = 0.0;
    var entanglementScore = 0.0;
    var forbiddenAreaScore = 0.0;

    final board = gameState.board;
    final turnRatio = gameState.turnCount / gameState.maxTurns;

    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        final piece = board.getPiece(r, c);
        if (piece == null) continue;

        final position = Position(r, c);
        final isMyColor = _isMyColor(piece.type, myColor);

        if (isMyColor) {
          myPieceScore += _getPieceValue(piece.type, position, board.rows);
        } else if (_isOpponentColor(piece.type, myColor)) {
          opponentPieceScore += _getPieceValue(piece.type, position, board.rows);
        }

        if (piece.isEntangled && isMyColor) {
          entanglementScore += _getEntanglementValue(
            piece,
            gameState,
            myColor,
            difficulty,
            turnRatio,
          );
        }
      }
    }

    // 禁止領域の評価
    final opponent = gameState.getOpponentPlayer();
    if (opponent != null) {
      final opponentForbiddenAreas = gameState.getForbiddenAreas(opponent.id);
      forbiddenAreaScore = opponentForbiddenAreas.length * 0.1;
    }

    // 難易度に応じた重み
    double entanglementWeight = 0.5;
    if (difficulty == AIDifficulty.advanced) {
      entanglementWeight = 0.8;
    } else if (difficulty == AIDifficulty.intermediate) {
      entanglementWeight = 0.6;
    }

    return myPieceScore - opponentPieceScore * 0.8 +
        entanglementScore * entanglementWeight +
        forbiddenAreaScore * 0.3;
  }

  /// エンタングル評価
  double _getEntanglementValue(
    Piece piece,
    GameState gameState,
    PlayerColor myColor,
    AIDifficulty difficulty,
    double turnRatio,
  ) {
    if (difficulty == AIDifficulty.beginner) return 0.0;

    double baseValue = 0.3;

    if (difficulty == AIDifficulty.intermediate) {
      if (turnRatio >= 0.5) {
        baseValue = 0.5;
      }
    } else if (difficulty == AIDifficulty.advanced) {
      if (turnRatio >= 0.7) {
        baseValue = 1.0;
      } else if (turnRatio >= 0.5) {
        baseValue = 0.7;
      } else if (turnRatio >= 0.3) {
        baseValue = 0.5;
      }
    }

    return baseValue;
  }

  /// 駒の価値
  double _getPieceValue(PieceType type, Position position, int boardSize) {
    double value = 1.0;

    if (type.isDetermined) {
      value = 1.0;
    } else if (type.isSuperposition) {
      value = 0.5;
    }

    final centerDistance = position.distanceFromCenter(boardSize);
    value *= (1.0 - centerDistance * 0.1).clamp(0.0, 1.0);

    return value;
  }

  /// 測定予測スコア
  double _predictMeasurementScore(
    GameState gameState,
    PlayerColor myColor,
  ) {
    var myExpected = 0.0;
    var opponentExpected = 0.0;

    final board = gameState.board;
    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        final piece = board.getPiece(r, c);
        if (piece == null) continue;

        final (myProb, oppProb) = _getMeasurementProbability(piece.type, myColor);
        myExpected += myProb;
        opponentExpected += oppProb;
      }
    }

    return myExpected - opponentExpected;
  }

  /// 測定確率
  (double, double) _getMeasurementProbability(
    PieceType type,
    PlayerColor myColor,
  ) {
    switch (type) {
      case PieceType.white:
        return myColor == PlayerColor.white ? (1.0, 0.0) : (0.0, 1.0);
      case PieceType.black:
        return myColor == PlayerColor.black ? (1.0, 0.0) : (0.0, 1.0);
      case PieceType.grayPlus:
      case PieceType.grayMinus:
      case PieceType.blackWhite:
      case PieceType.whiteBlack:
        return (0.5, 0.5);
    }
  }

  /// 自分の色か
  bool _isMyColor(PieceType type, PlayerColor myColor) {
    if (myColor == PlayerColor.white) {
      return type == PieceType.white;
    } else {
      return type == PieceType.black;
    }
  }

  /// 相手の色か
  bool _isOpponentColor(PieceType type, PlayerColor myColor) {
    if (myColor == PlayerColor.white) {
      return type == PieceType.black;
    } else {
      return type == PieceType.white;
    }
  }
}
