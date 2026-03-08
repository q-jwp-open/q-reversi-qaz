import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../piece_widget.dart';
import '../../../domain/entities/piece.dart';
import '../../../domain/entities/piece_type.dart';
import '../../../domain/entities/position.dart';

/// コイントスアニメーション
class TutorialCoinFlipAnimation extends StatefulWidget {
  const TutorialCoinFlipAnimation({super.key});

  @override
  State<TutorialCoinFlipAnimation> createState() =>
      _TutorialCoinFlipAnimationState();
}

class _TutorialCoinFlipAnimationState extends State<TutorialCoinFlipAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
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
        animation: _rotationAnimation,
        builder: (context, child) {
          final rotation = _rotationAnimation.value * 2 * math.pi;
          final showWhite = (rotation / math.pi).floor() % 2 == 0;
          
          return Transform.rotate(
            angle: rotation,
            child: Container(
              width: 80,
              height: 80,
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
                    type: showWhite ? PieceType.white : PieceType.black,
                    position: const Position(0, 0),
                  ),
                  size: 56, // 80 * 0.7
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

