import 'package:flutter/material.dart';
import '../../../antigolpe/constants/antigolpe_constants.dart';

/// Banner de alerta exibido quando a IA local detecta golpe por similaridade.
/// Ergonomia SM A256E: SingleChildScrollView horizontal para textos longos.
class IaAlertBanner extends StatelessWidget {
  final double similarity;

  const IaAlertBanner({super.key, required this.similarity});

  @override
  Widget build(BuildContext context) {
    final pct = (similarity * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: AntiGolpeConstants.colorRisk,
        borderRadius: BorderRadius.circular(30),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              '${AntiGolpeConstants.keyIaPatternMatch} ($pct% similar)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
