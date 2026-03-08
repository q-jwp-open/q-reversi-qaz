import 'package:flutter/material.dart';
import '../../domain/entities/gate_type.dart';
import '../theme/app_theme.dart';

/// ゲートボタン
class GateButton extends StatelessWidget {
  final GateType gate;
  final bool isEnabled;
  final bool isSelected;
  final int? cooldown;
  final VoidCallback? onTap;
  final bool isReadOnly; // 読み取り専用（相手のゲート表示用）
  
  const GateButton({
    super.key,
    required this.gate,
    this.isEnabled = true,
    this.isSelected = false,
    this.cooldown,
    this.onTap,
    this.isReadOnly = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: (isEnabled && !isReadOnly) ? onTap : null,
      style: AppTheme.getGateButtonStyle(gate, isEnabled, isSelected, isReadOnly),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: gate.isTwoBitGate
                    ? Transform.translate(
                        offset: const Offset(-10, 0), // 左に8ピクセルオフセット
                        child: Text(
                          gate.displayName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: false,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Text(
                        gate.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: false,
                        textAlign: TextAlign.center,
                      ),
              ),
              if (cooldown != null && cooldown! > 0)
                Text(
                  '$cooldown',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
            ],
          );
        },
      ),
    );
    
    // 読み取り専用の場合は半透明にする
    if (isReadOnly) {
      return Opacity(
        opacity: 0.6,
        child: button,
      );
    }
    
    return button;
  }
}

