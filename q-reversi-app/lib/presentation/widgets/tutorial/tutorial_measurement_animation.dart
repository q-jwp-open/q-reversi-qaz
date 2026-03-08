import 'package:flutter/material.dart';
import 'dart:math';
import '../piece_widget.dart';
import '../../../domain/entities/piece.dart';
import '../../../domain/entities/piece_type.dart';
import '../../../domain/entities/position.dart';

/// 測定アニメーション
class TutorialMeasurementAnimation extends StatefulWidget {
  final bool showProbability;

  const TutorialMeasurementAnimation({
    super.key,
    this.showProbability = false,
  });

  @override
  State<TutorialMeasurementAnimation> createState() =>
      _TutorialMeasurementAnimationState();
}

class _TutorialMeasurementAnimationState
    extends State<TutorialMeasurementAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeAnimation;
  final PieceType _currentType = PieceType.grayPlus;
  PieceType? _measuredType;
  int _measurementCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.3, curve: Curves.elasticIn),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _measurementCount++;
              // 交互に白と黒を表示
              _measuredType = _measurementCount % 2 == 0
                  ? PieceType.white
                  : PieceType.black;
            });
            _controller.reset();
            _controller.forward();
          }
        });
      }
    });

    _controller.forward();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  sin(_shakeAnimation.value * 2 * pi) * 10,
                  0,
                ),
                child: Opacity(
                  opacity: _measuredType == null ? 1.0 : _fadeAnimation.value,
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
                          type: _measuredType ?? _currentType,
                          position: const Position(0, 0),
                        ),
                        size: 56, // 80 * 0.7
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.showProbability) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      alignment: Alignment.centerRight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '50% : 50%',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

