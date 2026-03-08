import 'package:flutter/material.dart';
import '../../domain/entities/game_mode.dart';
import '../../core/constants/game_constants.dart';
import 'game_screen.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/player.dart';
import '../../domain/services/game_service.dart';

/// VSモード設定画面
class VsModeSetupScreen extends StatefulWidget {
  const VsModeSetupScreen({super.key});
  
  @override
  State<VsModeSetupScreen> createState() => _VsModeSetupScreenState();
}

class _VsModeSetupScreenState extends State<VsModeSetupScreen> {
  VsMode _vsMode = VsMode.human;
  AIDifficulty _aiDifficulty = AIDifficulty.beginner;
  int _maxTurns = GameConstants.defaultVsModeTurns;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'VSモード設定',
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
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '対戦モード',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              RadioListTile<VsMode>(
                title: const Text(
                  '対人戦',
                  style: TextStyle(color: Colors.white),
                ),
                value: VsMode.human,
                groupValue: _vsMode,
                onChanged: (value) {
                  setState(() => _vsMode = value!);
                },
              ),
              RadioListTile<VsMode>(
                title: const Text(
                  '対CPU戦',
                  style: TextStyle(color: Colors.white),
                ),
                value: VsMode.cpu,
                groupValue: _vsMode,
                onChanged: (value) {
                  setState(() => _vsMode = value!);
                },
              ),
              if (_vsMode == VsMode.cpu) ...[
                const SizedBox(height: 16),
                const Text(
                  'CPU難易度',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                RadioListTile<AIDifficulty>(
                  title: const Text(
                    '初級',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: AIDifficulty.beginner,
                  groupValue: _aiDifficulty,
                  onChanged: (value) {
                    setState(() => _aiDifficulty = value!);
                  },
                ),
                RadioListTile<AIDifficulty>(
                  title: const Text(
                    '中級',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: AIDifficulty.intermediate,
                  groupValue: _aiDifficulty,
                  onChanged: (value) {
                    setState(() => _aiDifficulty = value!);
                  },
                ),
                RadioListTile<AIDifficulty>(
                  title: const Text(
                    '上級',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: AIDifficulty.advanced,
                  groupValue: _aiDifficulty,
                  onChanged: (value) {
                    setState(() => _aiDifficulty = value!);
                  },
                ),
                RadioListTile<AIDifficulty>(
                  title: Row(
                    children: [
                      const Text(
                        '量子AI',
                        style: TextStyle(
                          color: Color(0xFF9B6DFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B46C1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'QAZ-QR',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text(
                    '量子力学的評価関数による4手先読み',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  value: AIDifficulty.quantum,
                  groupValue: _aiDifficulty,
                  onChanged: (value) {
                    setState(() => _aiDifficulty = value!);
                  },
                  activeColor: const Color(0xFF9B6DFF),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'ターン制限',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ...GameConstants.vsModeTurnOptions.map((turns) {
                return RadioListTile<int>(
                  title: Text(
                    '$turnsターン',
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: turns,
                  groupValue: _maxTurns,
                  onChanged: (value) {
                    setState(() => _maxTurns = value!);
                  },
                );
              }),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _startGame(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6B46C1),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'ゲーム開始',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _startGame(BuildContext context) {
    final board = Board.create8x8();
    
    const player1 = Player(
      id: 1,
      color: PlayerColor.white,
      isAI: false,
    );
    
    final player2 = Player(
      id: 2,
      color: PlayerColor.black,
      isAI: _vsMode == VsMode.cpu,
      aiDifficulty: _vsMode == VsMode.cpu ? _aiDifficulty : null,
    );
    
    final gameState = GameState(
      board: board,
      gameMode: GameMode.vs,
      vsMode: _vsMode,
      maxTurns: _maxTurns,
      currentPlayer: 1, // 白プレイヤー（player1）から開始
      players: {
        1: player1,
        2: player2,
      },
    );
    
    final gameService = GameService();
    final initializedState = gameService.createInitialBoard(gameState);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(gameState: initializedState),
      ),
    );
  }
}

