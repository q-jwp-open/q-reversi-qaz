import 'package:flutter/material.dart';
import '../../domain/entities/challenge_level.dart';
import '../../domain/entities/challenge_progress.dart';
import '../../domain/services/challenge_level_loader.dart';
import '../../domain/services/challenge_progress_service.dart';
import 'challenge_game_screen.dart';

/// チャレンジレベル選択画面
class ChallengeLevelSelectionScreen extends StatefulWidget {
  const ChallengeLevelSelectionScreen({super.key});

  @override
  State<ChallengeLevelSelectionScreen> createState() => _ChallengeLevelSelectionScreenState();
}

class _ChallengeLevelSelectionScreenState extends State<ChallengeLevelSelectionScreen> {
  final ChallengeLevelLoader _loader = ChallengeLevelLoader();
  final ChallengeProgressService _progressService = ChallengeProgressService();
  
  List<ChallengeLevel> _levels = [];
  ChallengeProgressManager? _progressManager;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final levels = await _loader.loadAllLevels();
      final progressManager = await _progressService.loadProgress();
      
      setState(() {
        _levels = levels;
        _progressManager = progressManager;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'チャレンジモード',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'エラーが発生しました',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_levels.isEmpty) {
      return const Center(
        child: Text(
          'レベルが見つかりません',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // ステージごとにグループ化
    final Map<int, List<ChallengeLevel>> stages = {};
    for (final level in _levels) {
      final stage = level.stageNumber;
      stages.putIfAbsent(stage, () => []).add(level);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stages.length,
      itemBuilder: (context, index) {
        final stageNumber = index + 1;
        final stageLevels = stages[stageNumber] ?? [];
        return _buildStageCard(stageNumber, stageLevels);
      },
    );
  }

  Widget _buildStageCard(int stageNumber, List<ChallengeLevel> levels) {
    final isUnlocked = _progressManager?.isStageUnlocked(stageNumber) ?? (stageNumber == 1);
    final completedCount = _progressManager?.getCompletedLevelsInStage(stageNumber) ?? 0;
    final isPerfect = _progressManager?.isStagePerfect(stageNumber) ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1A1F3A).withOpacity(0.8),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              'ステージ $stageNumber',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (isPerfect)
              const Icon(Icons.verified, color: Colors.amber, size: 20),
          ],
        ),
        subtitle: Text(
          '$completedCount / ${levels.length} クリア',
          style: const TextStyle(color: Colors.white70),
        ),
        leading: Icon(
          isUnlocked ? Icons.lock_open : Icons.lock,
          color: isUnlocked ? Colors.green : Colors.grey,
        ),
        backgroundColor: const Color(0xFF1A1F3A).withOpacity(0.5),
        collapsedBackgroundColor: const Color(0xFF1A1F3A).withOpacity(0.5),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 画面サイズに応じて列数を計算
                // 最小サイズ: 60px（スター3つ + レベル番号 + パディング）
                // 最大サイズ: 80px
                const maxCellSize = 80.0;
                const spacing = 6.0;
                const padding = 32.0; // 左右のパディング
                
                final availableWidth = constraints.maxWidth - padding;
                final crossAxisCount = (availableWidth / (maxCellSize + spacing)).floor().clamp(4, 10);
                
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: levels.length,
                  itemBuilder: (context, index) {
                    final level = levels[index];
                    return _buildLevelButton(level);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelButton(ChallengeLevel level) {
    final isUnlocked = _progressManager?.isLevelUnlocked(level.level) ?? (level.level == 1);
    final progress = _progressManager?.allProgress[level.level];
    final isCompleted = progress?.isCompleted ?? false;
    final stars = progress?.stars ?? 0;

    return GestureDetector(
      onTap: isUnlocked
          ? () => _startLevel(level)
          : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? (isCompleted
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF4A5568),
                        Color(0xFF2D3748),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2D3748),
                        Color(0xFF1A202C),
                      ],
                    ))
              : null,
          color: isUnlocked ? null : const Color(0xFF1A202C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked
                ? (isCompleted
                    ? Colors.green.withOpacity(0.6)
                    : Colors.blue.withOpacity(0.6))
                : Colors.grey.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: (isCompleted ? Colors.green : Colors.blue)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // メインコンテンツ
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // レベル番号
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${level.level}',
                      style: TextStyle(
                        color: isUnlocked
                            ? (isCompleted ? Colors.white : Colors.white)
                            : Colors.grey.withOpacity(0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // スター表示（完了時のみ）
                  if (isCompleted && stars > 0) ...[
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Icon(
                              index < stars ? Icons.star : Icons.star_border,
                              size: 12,
                              color: index < stars
                                  ? Colors.amber
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ロックアイコン（右上に配置）
            if (!isUnlocked)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.grey,
                    size: 12,
                  ),
                ),
              ),
            // 完了バッジ（左上に配置）
            if (isCompleted && isUnlocked)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _startLevel(ChallengeLevel level) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeGameScreen(level: level),
      ),
    );

    // レベルクリア後に進捗を更新
    if (result == true) {
      await _loadData();
    }
  }
}

