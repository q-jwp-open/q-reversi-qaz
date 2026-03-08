import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/challenge_level.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/gate_type.dart';
import '../../domain/entities/position.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/board.dart';
import '../../domain/services/challenge_game_service.dart';
import '../../domain/services/challenge_progress_service.dart';
import '../providers/game_provider.dart';
import '../widgets/board_widget.dart';
import '../widgets/gate_button.dart';

/// チャレンジゲーム画面
class ChallengeGameScreen extends StatefulWidget {
  final ChallengeLevel level;

  const ChallengeGameScreen({
    super.key,
    required this.level,
  });

  @override
  State<ChallengeGameScreen> createState() => _ChallengeGameScreenState();
}

class _ChallengeGameScreenState extends State<ChallengeGameScreen> {
  GateType? _selectedGate;
  List<Position> _selectedPositions = [];
  int? _selectedRow;
  int? _selectedColumn;
  String? _entangledErrorMessage;

  final ChallengeGameService _challengeService = ChallengeGameService();
  final ChallengeProgressService _progressService = ChallengeProgressService();

  @override
  Widget build(BuildContext context) {
    final gameState = _challengeService.createChallengeGameState(widget.level);

    return ChangeNotifierProvider(
      create: (_) => GameProvider(gameState),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'レベル ${widget.level.level}',
            style: const TextStyle(color: Colors.white),
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
          child: Consumer<GameProvider>(
            builder: (context, provider, _) {
              final state = provider.gameState;
              final currentPlayer = state.getCurrentPlayer();

              return SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // レベル情報
                            _buildLevelInfo(context, state),
                            
                            // ボード
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: constraints.maxHeight * 0.5,
                                maxWidth: constraints.maxWidth,
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: BoardWidget(
                                    board: state.board,
                                    selectedPositions: _selectedPositions,
                                    highlightedPositions: _getAdjacentPositions(state.board),
                                    lastTwoBitGatePositions: const [],
                                    enableRowColumnButtons: true,
                                    selectedGate: _selectedGate,
                                    selectedRows: _selectedRow != null
                                        ? {_selectedRow!: true}
                                        : {},
                                    selectedColumns: _selectedColumn != null
                                        ? {_selectedColumn!: true}
                                        : {},
                                    onPositionTap: (position) {
                                      _handleCellTap(context, provider, position.row, position.col);
                                    },
                                    onRowSelected: (row, side) {
                                      _handleRowButtonTap(context, provider, row);
                                    },
                                    onColumnSelected: (col, side) {
                                      _handleColumnButtonTap(context, provider, col);
                                    },
                                  ),
                                ),
                              ),
                            ),

                            // ゲート選択
                            _buildGateSelection(context, provider, currentPlayer),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLevelInfo(BuildContext context, GameState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.level.comment.isNotEmpty)
                  Text(
                    widget.level.comment,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (widget.level.comment.isNotEmpty) const SizedBox(height: 8),
                Text(
                  'ゴール: ${widget.level.victoryCondition.displayName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '最短ターン: ${widget.level.optimalTurns}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          // ターンカウントを右上に表示
          Text(
            'ターン: ${state.turnCount}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGateSelection(
    BuildContext context,
    GameProvider provider,
    Player? currentPlayer,
  ) {
    if (currentPlayer == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            '使用可能ゲート',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildGateButtons(widget.level.availableGates),
          const SizedBox(height: 16),
          if (_entangledErrorMessage != null)
            Text(
              _entangledErrorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          if (_entangledErrorMessage == null) ...[
            if (_selectedGate != null && _selectedGate!.isTwoBitGate)
              Text(
                _selectedPositions.isEmpty
                    ? '1マス目を選択してください'
                    : _selectedPositions.length == 1
                        ? '2マス目を選択してください'
                        : '2マス選択済み',
                style: const TextStyle(color: Colors.white70),
              ),
            if (_selectedGate != null && _selectedGate!.isOneBitGate)
              const Text(
                '行/列ボタンまたはマスを選択してください',
                style: TextStyle(color: Colors.white70),
              ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _canApplyGate()
                ? () => _applyGate(context, provider)
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: _canApplyGate()
                  ? const Color(0xFF4CAF50)
                  : Colors.grey.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'ゲートを適用',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _resetLevel(context, provider),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'リセット',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGateButtons(List<GateType> availableGates) {
    // 使用可能なゲートをカテゴリごとに分類
    final oneBitGates = availableGates.where((g) => g.isOneBitGate).toList();
    final twoBitGates = availableGates.where((g) => g.isTwoBitGate).toList();
    
    // 1ビットゲートをH, X, Y, Zの順に並べる
    final orderedOneBitGates = [
      if (oneBitGates.contains(GateType.h)) GateType.h,
      if (oneBitGates.contains(GateType.x)) GateType.x,
      if (oneBitGates.contains(GateType.y)) GateType.y,
      if (oneBitGates.contains(GateType.z)) GateType.z,
    ];
    
    // 2ビットゲートをCNOT, SWAPの順に並べる
    final orderedTwoBitGates = [
      if (twoBitGates.contains(GateType.cnot)) GateType.cnot,
      if (twoBitGates.contains(GateType.swap)) GateType.swap,
    ];
    
    return Column(
      children: [
        // 1行目：H, X
        if (orderedOneBitGates.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: orderedOneBitGates.take(2).map((gate) {
              final isSelected = _selectedGate == gate;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 60,
                  child: GateButton(
                    gate: gate,
                    isEnabled: true,
                    isSelected: isSelected,
                    onTap: () {
                      _handleGateSelection(gate);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        if (orderedOneBitGates.length > 2) const SizedBox(height: 8),
        // 2行目：Y, Z
        if (orderedOneBitGates.length > 2)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: orderedOneBitGates.skip(2).map((gate) {
              final isSelected = _selectedGate == gate;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 60,
                  child: GateButton(
                    gate: gate,
                    isEnabled: true,
                    isSelected: isSelected,
                    onTap: () {
                      _handleGateSelection(gate);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        if (orderedTwoBitGates.isNotEmpty) const SizedBox(height: 8),
        // 3行目：CNOT, SWAP
        if (orderedTwoBitGates.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: orderedTwoBitGates.map((gate) {
              final isSelected = _selectedGate == gate;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 60,
                  child: GateButton(
                    gate: gate,
                    isEnabled: true,
                    isSelected: isSelected,
                    onTap: () {
                      _handleGateSelection(gate);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _handleGateSelection(GateType gate) {
    setState(() {
      _selectedGate = gate;
      _entangledErrorMessage = null;
      // 2ビットゲートを選択したときのみ、駒の選択をリセット
      if (gate.isTwoBitGate) {
        _selectedPositions = [];
        _selectedRow = null;
        _selectedColumn = null;
      }
      // 1ビットゲートの場合は、既に選択されている駒の選択を保持
    });
  }

  void _handleCellTap(
    BuildContext context,
    GameProvider provider,
    int row,
    int col,
  ) {
    setState(() {
      _entangledErrorMessage = null;
    });

    if (_selectedGate != null && _selectedGate!.isTwoBitGate) {
      // 2ビットゲート選択中: 2マス選択（エンタングル駒は選択不可、隣接した駒のみ選択可能）
      final position = Position(row, col);
      final piece = provider.gameState.board.getPiece(row, col);
      if (piece != null && piece.isEntangled) {
        // エンタングル駒は選択不可
        setState(() {
          _entangledErrorMessage = 'エンタングル駒は選択できません';
        });
        return;
      }
      
      // エラーメッセージをクリア
      setState(() {
        _entangledErrorMessage = null;
      });
      
      if (_selectedPositions.isEmpty) {
        // 1つ目の位置を選択
        setState(() {
          _selectedPositions = [position];
        });
      } else if (_selectedPositions.length == 1) {
        // 2つ目の位置を選択（隣接チェック）
        final firstPosition = _selectedPositions.first;
        if (position.isAdjacent(firstPosition)) {
          setState(() {
            _selectedPositions.add(position);
          });
        } else {
          // 隣接していない場合は、新しい位置を1つ目として設定
          setState(() {
            _selectedPositions = [position];
            _entangledErrorMessage = '隣接した駒のみ選択できます';
          });
        }
      } else if (_selectedPositions.length == 2) {
        // 既に2マス選択済みの場合、最初の選択をクリアして新しい選択に置き換え
        setState(() {
          _selectedPositions = [position];
        });
      }
      _selectedRow = null;
      _selectedColumn = null;
    } else {
      // 1ビットゲートまたはゲート未選択: 1マス選択で4マス自動選択（エンタングル駒が含まれる場合は選択不可）
      // 行/列選択が既にある場合はクリアして4マス選択に切り替え
      if (_selectedRow != null || _selectedColumn != null) {
        setState(() {
          _selectedRow = null;
          _selectedColumn = null;
        });
      }
      
      // 4マス選択を自動生成
      final position = Position(row, col);
      final fourPieces = _getFourPieces(position, provider.gameState.board);
      
      // エンタングル駒が含まれているかチェック
      bool hasEntangled = false;
      for (final pos in fourPieces) {
        final piece = provider.gameState.board.getPiece(pos.row, pos.col);
        if (piece != null && piece.isEntangled) {
          hasEntangled = true;
          break;
        }
      }
      
      // エンタングル駒が含まれていない場合のみ選択
      if (!hasEntangled) {
        setState(() {
          _selectedPositions = fourPieces;
          _entangledErrorMessage = null;
        });
      } else {
        setState(() {
          _entangledErrorMessage = 'エンタングル駒を含む領域は選択できません';
        });
      }
    }
  }
  
  /// 4マス選択を取得（2x2の正方形）
  List<Position> _getFourPieces(Position position, Board board) {
    final positions = <Position>[];
    final row = position.row;
    final col = position.col;
    
    // 仕様: そのマス、及び右に1マス、下に1マス、右下に1マスの正方4マスを選択
    // 右端/下端を選択した場合は自動補正し、そこを含む4マスの選択とする
    
    // 基準位置を決定（右端/下端の場合は左/上にシフト）
    int baseRow = row;
    int baseCol = col;
    
    // 右端の場合、左に1マスシフト
    if (col == board.cols - 1 && board.cols > 1) {
      baseCol = col - 1;
    }
    
    // 下端の場合、上に1マスシフト
    if (row == board.rows - 1 && board.rows > 1) {
      baseRow = row - 1;
    }
    
    // 4マスを選択: baseRow, baseCol とその右、下、右下
    final positionsToAdd = [
      Position(baseRow, baseCol),
      Position(baseRow, baseCol + 1),
      Position(baseRow + 1, baseCol),
      Position(baseRow + 1, baseCol + 1),
    ];
    
    for (final pos in positionsToAdd) {
      if (board.isValidPosition(pos.row, pos.col)) {
        positions.add(pos);
      }
    }
    
    return positions;
  }

  void _handleRowButtonTap(
    BuildContext context,
    GameProvider provider,
    int row,
  ) {
    // 2ビットゲート選択時は行選択不可
    if (_selectedGate != null && _selectedGate!.isTwoBitGate) return;

    setState(() {
      _selectedRow = _selectedRow == row ? null : row;
      _selectedColumn = null;
      
      if (_selectedRow != null) {
        _selectedPositions = List.generate(8, (col) => Position(row, col));
      } else {
        _selectedPositions = [];
      }
      _entangledErrorMessage = null;
    });
  }

  void _handleColumnButtonTap(
    BuildContext context,
    GameProvider provider,
    int col,
  ) {
    // 2ビットゲート選択時は列選択不可
    if (_selectedGate != null && _selectedGate!.isTwoBitGate) return;

    setState(() {
      _selectedColumn = _selectedColumn == col ? null : col;
      _selectedRow = null;
      
      if (_selectedColumn != null) {
        _selectedPositions = List.generate(8, (row) => Position(row, col));
      } else {
        _selectedPositions = [];
      }
      _entangledErrorMessage = null;
    });
  }

  bool _canApplyGate() {
    if (_selectedGate == null) return false;
    if (_selectedPositions.isEmpty) return false;

    if (_selectedGate!.isTwoBitGate) {
      return _selectedPositions.length == 2;
    } else {
      return _selectedPositions.length == 1 || 
             _selectedPositions.length == 8 ||
             _selectedPositions.length == 4;
    }
  }

  void _applyGate(BuildContext context, GameProvider provider) async {
    if (!_canApplyGate()) return;

    final success = await provider.applyGate(_selectedGate!, _selectedPositions);
    
    if (!success) {
      setState(() {
        _entangledErrorMessage = provider.errorMessage ?? 'ゲートを適用できませんでした';
      });
      return;
    }

    final newState = provider.gameState;

    // 勝利条件をチェック
    final isVictory = _challengeService.checkVictoryCondition(
      newState,
      widget.level.victoryCondition,
    );

    if (isVictory) {
      await _handleVictory(context, newState);
    } else {
      // チャレンジモードでは、ゲート選択は保持し、選択位置のみクリア
      setState(() {
        _selectedPositions = [];
        _selectedRow = null;
        _selectedColumn = null;
        _entangledErrorMessage = null;
      });
    }
  }

  void _resetLevel(BuildContext context, GameProvider provider) {
    // 初期状態を再作成
    final initialGameState = _challengeService.createChallengeGameState(widget.level);
    
    // GameProviderの状態をリセット
    provider.resetToState(initialGameState);
    
    // UIの選択状態もリセット
    setState(() {
      _selectedGate = null;
      _selectedPositions = [];
      _selectedRow = null;
      _selectedColumn = null;
      _entangledErrorMessage = null;
    });
  }

  Future<void> _handleVictory(BuildContext context, GameState state) async {
    final turnsUsed = state.turnCount;
    final stars = _calculateStars(turnsUsed, widget.level.optimalTurns);

    // 進捗を保存
    final progressManager = await _progressService.loadProgress();
    await _progressService.completeLevel(
      progressManager,
      widget.level.level,
      turnsUsed,
      widget.level.optimalTurns,
    );

    if (mounted) {
      _showVictoryDialog(context, stars, turnsUsed);
    }
  }

  int _calculateStars(int turnsUsed, int optimalTurns) {
    if (turnsUsed <= optimalTurns) {
      return 3; // 最短ターンでクリア → 星3つ
    } else if (turnsUsed <= optimalTurns * 3) {
      return 2; // 最短ターンの3倍以内でクリア → 星2つ
    } else {
      return 1; // 3倍を超えたら → 星1つ
    }
  }

  void _showVictoryDialog(BuildContext context, int stars, int turnsUsed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          '🎉 レベルクリア！',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'レベル ${widget.level.level} をクリアしました！',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  color: index < stars ? Colors.amber : Colors.grey,
                  size: 32,
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              '使用ターン数: $turnsUsed',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((value) {
      if (value == true) {
        Navigator.of(context).pop(true);
      }
    });
  }

  /// 2ビットゲート選択時に、1つ目の位置に隣接する位置を取得
  List<Position> _getAdjacentPositions(Board board) {
    if (_selectedGate == null || !_selectedGate!.isTwoBitGate) {
      return [];
    }
    if (_selectedPositions.isEmpty) {
      return [];
    }
    
    final firstPosition = _selectedPositions.first;
    final adjacentPositions = <Position>[];
    
    // 隣接する8方向をチェック
    for (int rowOffset = -1; rowOffset <= 1; rowOffset++) {
      for (int colOffset = -1; colOffset <= 1; colOffset++) {
        if (rowOffset == 0 && colOffset == 0) continue; // 自分自身は除外
        
        final newRow = firstPosition.row + rowOffset;
        final newCol = firstPosition.col + colOffset;
        
        if (board.isValidPosition(newRow, newCol)) {
          final adjacentPos = Position(newRow, newCol);
          // 既に選択されている位置は除外
          if (!_selectedPositions.contains(adjacentPos)) {
            adjacentPositions.add(adjacentPos);
          }
        }
      }
    }
    
    return adjacentPositions;
  }
}

