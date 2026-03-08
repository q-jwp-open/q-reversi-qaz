import 'package:flutter/material.dart';
import '../../../domain/entities/gate_type.dart';
import '../../../domain/entities/piece_type.dart';
import '../piece_widget.dart';
import '../../../domain/entities/piece.dart';
import '../../../domain/entities/position.dart';

/// ゲート変換図ウィジェット
class TutorialGateTransformationWidget extends StatefulWidget {
  final Map<String, dynamic>? data;

  const TutorialGateTransformationWidget({
    super.key,
    this.data,
  });

  @override
  State<TutorialGateTransformationWidget> createState() =>
      _TutorialGateTransformationWidgetState();
}

class _TutorialGateTransformationWidgetState
    extends State<TutorialGateTransformationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gateStr = widget.data?['gate'] as String?;
    if (gateStr == null) {
      return const SizedBox.shrink();
    }

    final gate = _parseGate(gateStr);
    if (gate == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _buildTransformations(gate),
      ),
    );
  }

  List<Widget> _buildTransformations(GateType gate) {
    final transformations = <Widget>[];

    switch (gate) {
      case GateType.x:
        transformations.addAll([
          _buildTransformation(
            const Piece(id: '1', type: PieceType.white, position: Position(0, 0)),
            gate,
            const Piece(id: '1', type: PieceType.black, position: Position(0, 0)),
          ),
          _buildTransformation(
            const Piece(id: '2', type: PieceType.black, position: Position(0, 0)),
            gate,
            const Piece(id: '2', type: PieceType.white, position: Position(0, 0)),
          ),
          const SizedBox(height: 16),
          _buildTransformation(
            const Piece(id: '3', type: PieceType.grayPlus, position: Position(0, 0)),
            gate,
            const Piece(id: '3', type: PieceType.grayPlus, position: Position(0, 0)),
            showChange: false,
          ),
        ]);
        break;

      case GateType.h:
        transformations.addAll([
          _buildTransformation(
            const Piece(id: '1', type: PieceType.white, position: Position(0, 0)),
            gate,
            const Piece(id: '1', type: PieceType.grayPlus, position: Position(0, 0)),
          ),
          _buildTransformation(
            const Piece(id: '2', type: PieceType.black, position: Position(0, 0)),
            gate,
            const Piece(id: '2', type: PieceType.grayMinus, position: Position(0, 0)),
          ),
          const SizedBox(height: 16),
          _buildTransformation(
            const Piece(id: '3', type: PieceType.grayPlus, position: Position(0, 0)),
            gate,
            const Piece(id: '3', type: PieceType.white, position: Position(0, 0)),
          ),
          _buildTransformation(
            const Piece(id: '4', type: PieceType.grayMinus, position: Position(0, 0)),
            gate,
            const Piece(id: '4', type: PieceType.black, position: Position(0, 0)),
          ),
        ]);
        break;

      case GateType.z:
        transformations.addAll([
          _buildTransformation(
            const Piece(id: '1', type: PieceType.grayPlus, position: Position(0, 0)),
            gate,
            const Piece(id: '1', type: PieceType.grayMinus, position: Position(0, 0)),
          ),
          _buildTransformation(
            const Piece(id: '2', type: PieceType.grayMinus, position: Position(0, 0)),
            gate,
            const Piece(id: '2', type: PieceType.grayPlus, position: Position(0, 0)),
          ),
          const SizedBox(height: 16),
          _buildTransformation(
            const Piece(id: '3', type: PieceType.white, position: Position(0, 0)),
            gate,
            const Piece(id: '3', type: PieceType.white, position: Position(0, 0)),
            showChange: false,
          ),
          _buildTransformation(
            const Piece(id: '4', type: PieceType.black, position: Position(0, 0)),
            gate,
            const Piece(id: '4', type: PieceType.black, position: Position(0, 0)),
            showChange: false,
          ),
        ]);
        break;

      case GateType.y:
        transformations.addAll([
          _buildTransformation(
            const Piece(id: '1', type: PieceType.white, position: Position(0, 0)),
            gate,
            const Piece(id: '1', type: PieceType.black, position: Position(0, 0)),
          ),
          _buildTransformation(
            const Piece(id: '2', type: PieceType.black, position: Position(0, 0)),
            gate,
            const Piece(id: '2', type: PieceType.white, position: Position(0, 0)),
          ),
          const SizedBox(height: 16),
          _buildTransformation(
            const Piece(id: '3', type: PieceType.grayPlus, position: Position(0, 0)),
            gate,
            const Piece(id: '3', type: PieceType.grayMinus, position: Position(0, 0)),
          ),
          _buildTransformation(
            const Piece(id: '4', type: PieceType.grayMinus, position: Position(0, 0)),
            gate,
            const Piece(id: '4', type: PieceType.grayPlus, position: Position(0, 0)),
          ),
        ]);
        break;

      case GateType.cnot:
        // CNOTゲートの変換図（基本パターン）
        final mode = widget.data?['mode'] as String? ?? 'basic';
        if (mode == 'basic') {
          transformations.addAll([
            _buildCnotTransformation(
              const Piece(id: 'c1', type: PieceType.black, position: Position(0, 0)),
              const Piece(id: 't1', type: PieceType.white, position: Position(0, 1)),
              const Piece(id: 'c1', type: PieceType.black, position: Position(0, 0)),
              const Piece(id: 't1', type: PieceType.black, position: Position(0, 1)),
            ),
            _buildCnotTransformation(
              const Piece(id: 'c2', type: PieceType.white, position: Position(0, 0)),
              const Piece(id: 't2', type: PieceType.white, position: Position(0, 1)),
              const Piece(id: 'c2', type: PieceType.white, position: Position(0, 0)),
              const Piece(id: 't2', type: PieceType.white, position: Position(0, 1)),
              showChange: false,
            ),
          ]);
        }
        break;

      case GateType.swap:
        // SWAPゲートはアニメーションで表示
        break;
    }

    return transformations;
  }

  Widget _buildTransformation(
    Piece before,
    GateType gate,
    Piece after, {
    bool showChange = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50), // 緑色の盤面背景
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFF4CAF50), // 緑色の枠線
                width: 3,
              ),
            ),
            child: Center(
              child: PieceWidget(piece: before, size: 35),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getGateColor(gate).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getGateColor(gate),
                width: 2,
              ),
            ),
            child: Text(
              gate.displayName,
              style: TextStyle(
                color: _getGateColor(gate),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: showChange ? 1.0 : 0.5,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50), // 緑色の盤面背景
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF4CAF50), // 緑色の枠線
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: PieceWidget(
                      piece: after,
                      size: 35,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCnotTransformation(
    Piece controlBefore,
    Piece targetBefore,
    Piece controlAfter,
    Piece targetAfter, {
    bool showChange = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  const Text(
                    'C',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50), // 緑色の盤面背景
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF4CAF50), // 緑色の枠線
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: PieceWidget(piece: controlBefore, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  const Text(
                    'T',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50), // 緑色の盤面背景
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF4CAF50), // 緑色の枠線
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: PieceWidget(piece: targetBefore, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B46C1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6B46C1),
                    width: 2,
                  ),
                ),
                child: const Text(
                  'CNOT',
                  style: TextStyle(
                    color: Color(0xFF6B46C1),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  const Text(
                    'C',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: showChange ? 1.0 : 0.5,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50), // 緑色の盤面背景
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF4CAF50), // 緑色の枠線
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: PieceWidget(
                              piece: controlAfter,
                              size: 28,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  const Text(
                    'T',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: showChange ? 1.0 : 0.5,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50), // 緑色の盤面背景
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF4CAF50), // 緑色の枠線
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: PieceWidget(
                              piece: targetAfter,
                              size: 28,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getGateColor(GateType gate) {
    switch (gate) {
      case GateType.x:
        return const Color(0xFF6B46C1); // 紫
      case GateType.h:
        return const Color(0xFF06B6D4); // シアン
      case GateType.y:
      case GateType.z:
        return const Color(0xFFEC4899); // ピンク
      case GateType.cnot:
        return const Color(0xFF6B46C1); // 紫
      case GateType.swap:
        return const Color(0xFF6B46C1); // 紫
    }
  }

  GateType? _parseGate(String gateStr) {
    switch (gateStr.toLowerCase()) {
      case 'x':
        return GateType.x;
      case 'h':
        return GateType.h;
      case 'y':
        return GateType.y;
      case 'z':
        return GateType.z;
      case 'cnot':
        return GateType.cnot;
      case 'swap':
        return GateType.swap;
      default:
        return null;
    }
  }
}

