import 'package:flutter/material.dart';
import '../../constants/antigolpe_constants.dart';

Widget buildAnalysisTile(String phone, bool isFraud) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(
          isFraud ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
          color: isFraud ? AntiGolpeConstants.colorRisk : AntiGolpeConstants.colorSafe,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(phone, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                isFraud ? 'Troca de chip detectada (Risco)' : 'Chip verificado e seguro', 
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
