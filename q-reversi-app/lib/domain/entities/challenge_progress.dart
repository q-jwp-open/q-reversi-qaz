import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// チャレンジ進捗
class ChallengeProgress extends Equatable {
  final int level;
  final bool isCompleted;
  final int stars; // 0-3
  final int turnsUsed;

  const ChallengeProgress({
    required this.level,
    this.isCompleted = false,
    this.stars = 0,
    this.turnsUsed = 0,
  });

  ChallengeProgress copyWith({
    int? level,
    bool? isCompleted,
    int? stars,
    int? turnsUsed,
  }) {
    return ChallengeProgress(
      level: level ?? this.level,
      isCompleted: isCompleted ?? this.isCompleted,
      stars: stars ?? this.stars,
      turnsUsed: turnsUsed ?? this.turnsUsed,
    );
  }

  @override
  List<Object?> get props => [level, isCompleted, stars, turnsUsed];
}

/// チャレンジ進捗管理
class ChallengeProgressManager {
  final Map<int, ChallengeProgress> _progress;

  ChallengeProgressManager(this._progress);

  /// レベルが完了しているか
  bool isLevelCompleted(int level) {
    return _progress[level]?.isCompleted ?? false;
  }

  /// レベルがアンロックされているか
  bool isLevelUnlocked(int level) {
    // デバッグモード（評価時）では全レベルをアンロック
    if (kDebugMode) return true;
    
    if (level == 1) return true;
    // 前のレベルが完了している必要がある
    return isLevelCompleted(level - 1);
  }

  /// ステージがアンロックされているか
  bool isStageUnlocked(int stageNumber) {
    // デバッグモード（評価時）では全ステージをアンロック
    if (kDebugMode) return true;
    
    if (stageNumber == 1) return true;
    // 前のステージのすべてのレベルが完了している必要がある
    final previousStageStart = (stageNumber - 2) * 30 + 1;
    final previousStageEnd = (stageNumber - 1) * 30;
    for (int level = previousStageStart; level <= previousStageEnd; level++) {
      if (!isLevelCompleted(level)) {
        return false;
      }
    }
    return true;
  }

  /// ステージ内の完了レベル数
  int getCompletedLevelsInStage(int stageNumber) {
    final stageStart = (stageNumber - 1) * 30 + 1;
    final stageEnd = stageNumber * 30;
    int count = 0;
    for (int level = stageStart; level <= stageEnd; level++) {
      if (isLevelCompleted(level)) {
        count++;
      }
    }
    return count;
  }

  /// ステージ内の全レベルが★3つか
  bool isStagePerfect(int stageNumber) {
    final stageStart = (stageNumber - 1) * 30 + 1;
    final stageEnd = stageNumber * 30;
    for (int level = stageStart; level <= stageEnd; level++) {
      final progress = _progress[level];
      if (progress == null || !progress.isCompleted || progress.stars != 3) {
        return false;
      }
    }
    return true;
  }

  /// 進捗を更新
  ChallengeProgressManager updateProgress(ChallengeProgress progress) {
    final newProgress = Map<int, ChallengeProgress>.from(_progress);
    newProgress[progress.level] = progress;
    return ChallengeProgressManager(newProgress);
  }

  /// すべての進捗を取得
  Map<int, ChallengeProgress> get allProgress => Map.unmodifiable(_progress);
}



