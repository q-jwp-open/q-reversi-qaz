import 'package:flutter/foundation.dart';
import '../../domain/entities/challenge_progress.dart';
import '../../domain/services/challenge_progress_service.dart';

/// チャレンジ進捗の単一の正（メモリ）と永続化を束ねる
class ChallengeProgressNotifier extends ChangeNotifier {
  ChallengeProgressNotifier({ChallengeProgressService? service})
      : _service = service ?? ChallengeProgressService();

  final ChallengeProgressService _service;
  ChallengeProgressManager _manager = ChallengeProgressManager({});

  ChallengeProgressManager get progress => _manager;

  /// ストレージから読み込み、購読者に通知
  Future<void> hydrate() async {
    _manager = await _service.loadProgress();
    notifyListeners();
  }

  /// レベルクリアを保存し、メモリを更新して通知
  Future<void> completeLevel(
    int level,
    int turnsUsed,
    int optimalTurns,
  ) async {
    _manager = await _service.completeLevel(level, turnsUsed, optimalTurns);
    notifyListeners();
  }
}
