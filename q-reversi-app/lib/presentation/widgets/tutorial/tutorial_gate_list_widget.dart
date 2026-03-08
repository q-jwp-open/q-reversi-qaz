import 'package:flutter/material.dart';
import '../../../domain/entities/gate_type.dart';
import '../gate_button.dart';

/// ゲート一覧ウィジェット
class TutorialGateListWidget extends StatelessWidget {
  const TutorialGateListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: GateType.values.map((gate) {
          return GateButton(
            gate: gate,
            isEnabled: false,
            isReadOnly: true,
          );
        }).toList(),
      ),
    );
  }
}


