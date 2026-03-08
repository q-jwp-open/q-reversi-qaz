import 'package:flutter/foundation.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/gate_type.dart';
import '../../domain/entities/position.dart';
import '../../domain/entities/game_mode.dart';
import '../../domain/services/game_service.dart';
import '../../domain/services/measurement_service.dart';
import '../../domain/services/ai_service.dart';

/// ゲームプロバイダー
class GameProvider extends ChangeNotifier {
  static const int _maxHistoryLength = 60;
  
  GameState _gameState;
  final GameService _gameService = GameService();
  final MeasurementService _measurementService = MeasurementService();
  final AIService _aiService = AIService();
  bool _isProcessing = false;
  String? _errorMessage;
  final List<GameState> _history = [];
  
  GameProvider(this._gameState);
  
  GameState get gameState => _gameState;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get canUndo =>
      _gameState.gameMode == GameMode.freeRun &&
      _history.isNotEmpty &&
      !_isProcessing;
  
  /// ゲートを適用
  Future<bool> applyGate(
    GateType gate,
    List<Position> targetPositions,
  ) async {
    if (_isProcessing) return false;
    
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // 適用前の状態を保存
      final previousState = _gameState;
      final previousTurnCount = _gameState.turnCount;
      final previousCurrentPlayer = _gameState.currentPlayer;
      final isFreeRunMode = _gameState.gameMode == GameMode.freeRun;
      
      _gameState = _gameService.applyGateWithFullLogic(
        _gameState,
        gate,
        targetPositions,
      );
      
      // 状態が変更されていない場合（禁止領域やエンタングル状態のチェックで失敗した場合）
      // フリーランモードではturnCountが増えなければ失敗
      // VSモードではturnCountが増えない、かつcurrentPlayerが変わらない場合は失敗
      bool isFailed = false;
      if (isFreeRunMode) {
        // フリーランモード: turnCountが増えなければ失敗
        isFailed = _gameState.turnCount == previousTurnCount;
      } else {
        // VSモード: turnCountが増えない、かつcurrentPlayerが変わらない場合は失敗
        isFailed = _gameState.turnCount == previousTurnCount && 
                   _gameState.currentPlayer == previousCurrentPlayer;
      }
      
      if (isFailed) {
        _errorMessage = 'ゲートを適用できませんでした（禁止領域またはエンタングル状態のため）';
        _isProcessing = false;
        notifyListeners();
        return false;
      }
      
      // フリーランモードの場合のみ、ゲート適用前の状態を履歴に保存
      if (isFreeRunMode) {
        _addHistory(previousState);
      }
      
      // CPUのターンの場合
      if (_gameState.gameMode == GameMode.vs &&
          _gameState.getCurrentPlayer()?.isAI == true) {
        await _processAITurn();
      }
      
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }
  
  /// 測定操作
  void measure() {
    // 測定時は履歴をクリア（これ以降は手を戻せない）
    _history.clear();
    _gameState = _measurementService.measure(_gameState);
    notifyListeners();
  }
  
  /// AIのターンを処理
  Future<void> _processAITurn() async {
    final currentPlayer = _gameState.getCurrentPlayer();
    if (currentPlayer == null || !currentPlayer.isAI) return;
    
    final difficulty = currentPlayer.aiDifficulty ?? AIDifficulty.beginner;
    final action = await _aiService.think(_gameState, difficulty);
    
    _gameState = _gameService.applyGateWithFullLogic(
      _gameState,
      action.gate,
      action.positions,
    );
  }
  
  /// ゲームをリセット
  void reset() {
    // リセット時は履歴をクリア
    _history.clear();
    _gameState = _gameService.createInitialBoard(_gameState);
    notifyListeners();
  }
  
  /// 指定された状態にリセット（チャレンジモード用）
  void resetToState(GameState newState) {
    // リセット時は履歴をクリア
    _history.clear();
    _isProcessing = false;
    _errorMessage = null;
    _gameState = newState;
    notifyListeners();
  }
  
  /// 盤面をすべて白にする
  void setAllPiecesWhite() {
    // 盤面一括変更時は履歴をクリア
    _history.clear();
    _gameState = _gameService.setAllPiecesToColor(_gameState, true);
    notifyListeners();
  }
  
  /// 盤面をすべて黒にする
  void setAllPiecesBlack() {
    // 盤面一括変更時は履歴をクリア
    _history.clear();
    _gameState = _gameService.setAllPiecesToColor(_gameState, false);
    notifyListeners();
  }
  
  /// エラーをクリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 1手戻す（フリーランモード専用）
  void undo() {
    if (!canUndo) return;
    if (_history.isEmpty) return;
    
    _isProcessing = false;
    _errorMessage = null;
    _gameState = _history.removeLast();
    notifyListeners();
  }
  
  /// 履歴に状態を追加（最大60手まで）
  void _addHistory(GameState state) {
    _history.add(state);
    if (_history.length > _maxHistoryLength) {
      _history.removeAt(0);
    }
  }
}

