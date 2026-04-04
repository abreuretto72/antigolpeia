import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../main.dart';
import '../../../pages/result_page.dart';
import '../../antigolpe/constants/antigolpe_constants.dart';
import 'block_engine_service.dart';

/// Dispara alertas visuais + hápticos quando a IA detecta fraude de alto risco.
/// Não depende de awesome_notifications — usa overlay in-app para zero setup.
class AlertDispatcher {
  static final _blockEngine = BlockEngineService();

  /// Alerta completo: haptic staccato + banner modal vermelho.
  /// Só exibe se o app estiver em foreground (navigatorKey.currentContext != null).
  static Future<void> triggerFraudAlert({
    required String sender,
    required String content,
    required double riskLevel,
    required String fraudType,
    required Map<String, dynamic> analysisResult,
  }) async {
    _hapticWarning();

    final context = navigatorKey.currentContext;
    if (context == null) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) => _FraudAlertDialog(
        sender: sender,
        content: content,
        riskLevel: riskLevel,
        fraudType: fraudType,
        analysisResult: analysisResult,
      ),
    );
  }

  static void _hapticWarning() {
    HapticFeedback.heavyImpact();
    Future.delayed(
      const Duration(milliseconds: 120),
      HapticFeedback.heavyImpact,
    );
    Future.delayed(
      const Duration(milliseconds: 240),
      HapticFeedback.heavyImpact,
    );
  }
}

class _FraudAlertDialog extends StatelessWidget {
  final String sender;
  final String content;
  final double riskLevel;
  final String fraudType;
  final Map<String, dynamic> analysisResult;

  const _FraudAlertDialog({
    required this.sender,
    required this.content,
    required this.riskLevel,
    required this.fraudType,
    required this.analysisResult,
  });

  String _maskSender(String s) {
    if (s.length <= 6) return s;
    return '${s.substring(0, s.length - 4)}****';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AntiGolpeConstants.colorRisk, width: 2),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AntiGolpeConstants.colorRisk, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'ALERTA DE GOLPE!',
                    style: TextStyle(
                      color: AntiGolpeConstants.colorRisk,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Remetente
              _InfoRow(label: 'Remetente:', value: _maskSender(sender)),
              const SizedBox(height: 8),

              // Análise IA
              _InfoRow(
                label: 'Análise IA:',
                value: '${riskLevel.toStringAsFixed(0)}% Risco ($fraudType)',
                valueColor: AntiGolpeConstants.colorRisk,
              ),
              const SizedBox(height: 24),

              // Ações
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AntiGolpeConstants.colorRisk,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        await AlertDispatcher._blockEngine.executeBlock(
                          sender,
                          fraudType,
                          content,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text(
                        'BLOQUEAR',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('É SEGURO'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Ver detalhes completos
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResultPage(result: analysisResult),
                      ),
                    );
                  },
                  child: const Text('Ver análise completa'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 15, height: 1.4),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(color: Colors.grey),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
