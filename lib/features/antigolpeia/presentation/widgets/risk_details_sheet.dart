import 'package:flutter/material.dart';
import '../../../antigolpe/constants/antigolpe_constants.dart';
import '../../services/ai_engine_logic.dart';

/// Bottom sheet com os motivos do risco calculado pela IA.
/// Ergonomia SM A256E: DraggableScrollableSheet + SingleChildScrollView.
class RiskDetailsSheet extends StatelessWidget {
  final double risk;
  final List<RiskReason> reasons;

  const RiskDetailsSheet({
    super.key,
    required this.risk,
    required this.reasons,
  });

  static void show(
    BuildContext context, {
    required double risk,
    required List<RiskReason> reasons,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        builder: (_, controller) => RiskDetailsSheet(
          risk: risk,
          reasons: reasons,
          key: const Key('risk_details_sheet'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = risk >= 70
        ? AntiGolpeConstants.colorRisk
        : risk >= 40
            ? Colors.orange
            : AntiGolpeConstants.colorSafe;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            AntiGolpeConstants.keyAiAnalysis, // substituir por l10n quando ativo
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const Divider(height: 28),
          ...reasons.map((r) => _ReasonTile(reason: r)),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Risco Total: ${risk.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final RiskReason reason;

  const _ReasonTile({required this.reason});

  static const _iconMap = <String, IconData>{
    'router': Icons.router,
    'link': Icons.link,
    'group': Icons.group,
    'pattern': Icons.pattern,
  };

  @override
  Widget build(BuildContext context) {
    final color = reason.active
        ? AntiGolpeConstants.colorRisk
        : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(_iconMap[reason.icon] ?? Icons.info_outline, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              reason.key, // Substituir por AppLocalizations.of(context) quando l10n ativo
              style: TextStyle(
                fontSize: 15,
                color: reason.active ? null : Colors.grey,
                decoration: reason.active ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          Icon(
            reason.active ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
            size: 18,
          ),
        ],
      ),
    );
  }
}
