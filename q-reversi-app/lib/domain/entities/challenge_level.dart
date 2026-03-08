import 'package:equatable/equatable.dart';
import 'board.dart';
import 'gate_type.dart';

/// チャレンジレベル
class ChallengeLevel extends Equatable {
  final int level;
  final int optimalTurns;
  final List<GateType> availableGates;
  final VictoryCondition victoryCondition;
  final Board initialBoard;
  final String comment;

  const ChallengeLevel({
    required this.level,
    required this.optimalTurns,
    required this.availableGates,
    required this.victoryCondition,
    required this.initialBoard,
    required this.comment,
  });

  /// ステージ番号を取得（30レベルごと）
  int get stageNumber => ((level - 1) ~/ 30) + 1;

  /// ステージ内のレベル番号（1-30）
  int get levelInStage => ((level - 1) % 30) + 1;

  @override
  List<Object?> get props => [
        level,
        optimalTurns,
        availableGates,
        victoryCondition,
        initialBoard,
        comment,
      ];
}

/// 勝利条件
enum VictoryCondition {
  allWhite,
  allBlack,
}

extension VictoryConditionExtension on VictoryCondition {
  static VictoryCondition? fromString(String str) {
    final normalized = str.trim().toLowerCase();
    if (normalized.contains('all white') || normalized == 'all white') {
      return VictoryCondition.allWhite;
    }
    if (normalized.contains('all black') || normalized == 'all black') {
      return VictoryCondition.allBlack;
    }
    return null;
  }

  String get displayName {
    switch (this) {
      case VictoryCondition.allWhite:
        return 'すべて白にする';
      case VictoryCondition.allBlack:
        return 'すべて黒にする';
    }
  }
}



