import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../piece_widget.dart';
import '../../../domain/entities/piece.dart';
import '../../../domain/entities/piece_type.dart';
import '../../../domain/entities/position.dart';

/// SWAPゲートアニメーション
class TutorialSwapAnimation extends StatefulWidget {
  const TutorialSwapAnimation({super.key});

  @override
  State<TutorialSwapAnimation> createState() => _TutorialSwapAnimationState();
}

class _TutorialSwapAnimationState extends State<TutorialSwapAnimation>
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final leftX = 100 - 50 * math.cos(angle);
          final rightX = 100 + 50 * math.cos(angle);
          
          return SizedBox(
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 左の駒
                Positioned(
                  left: leftX,
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
                        piece: Piece(
                          id: '1',
                          type: _animation.value < 0.5
                              ? PieceType.white
                              : PieceType.black,
                          position: const Position(0, 0),
                        ),
                        size: 35,
                      ),
                    ),
                  ),
                ),
                // 中央のゲートアイコン
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B46C1).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF6B46C1),
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    'SWAP',
                    style: TextStyle(
                      color: Color(0xFF6B46C1),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 右の駒
                Positioned(
                  right: rightX,
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
                        piece: Piece(
                          id: '2',
                          type: _animation.value < 0.5
                              ? PieceType.black
                              : PieceType.white,
                          position: const Position(0, 0),
                        ),
                        size: 35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

