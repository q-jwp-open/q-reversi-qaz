import 'package:equatable/equatable.dart';
import 'game_mode.dart';
import 'gate_type.dart';
import 'forbidden_area.dart';

/// プレイヤー
class Player extends Equatable {
  final int id;
  final PlayerColor color;
  final Map<GateType, int> cooldowns; // ゲートタイプ -> 残りクールタイム
  final ForbiddenArea? lastAppliedArea;
  final bool isAI;
  final AIDifficulty? aiDifficulty;
  
  const Player({
    required this.id,
    required this.color,
    this.cooldowns = const {},
    this.lastAppliedArea,
    this.isAI = false,
    this.aiDifficulty,
  });
  
  Player copyWith({
    int? id,
    PlayerColor? color,
    Map<GateType, int>? cooldowns,
    ForbiddenArea? lastAppliedArea,
    bool? isAI,
    AIDifficulty? aiDifficulty,
  }) {
    return Player(
      id: id ?? this.id,
      color: color ?? this.color,
      cooldowns: cooldowns ?? this.cooldowns,
      lastAppliedArea: lastAppliedArea ?? this.lastAppliedArea,
      isAI: isAI ?? this.isAI,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
    );
  }
  
  /// クールタイムを1ターン減少
  Player decreaseCooldowns() {
    final newCooldowns = <GateType, int>{};
    for (final entry in cooldowns.entries) {
      if (entry.value > 0) {
        newCooldowns[entry.key] = entry.value - 1;
      }
    }
    return copyWith(cooldowns: newCooldowns);
  }
  
  /// ゲートを使用（クールタイムを設定）
  Player useGate(GateType gate) {
    final newCooldowns = Map<GateType, int>.from(cooldowns);
    newCooldowns[gate] = gate.cooldown;
    return copyWith(cooldowns: newCooldowns);
  }
  
  /// ゲートが使用可能か
  bool canUseGate(GateType gate) {
    return (cooldowns[gate] ?? 0) == 0;
  }
  
  @override
  List<Object?> get props => [
    id,
    color,
    cooldowns,
    lastAppliedArea,
    isAI,
    aiDifficulty,
  ];
}

