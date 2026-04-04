import 'package:flutter/material.dart';
import '../../../../features/antigolpe/constants/antigolpe_constants.dart';
import '../../services/authority_report_service.dart';

class ReportAuthorityCard extends StatefulWidget {
  final String rawPhone;
  final String rawMessage;
  final int ipqsScore;

  const ReportAuthorityCard({
    super.key,
    required this.rawPhone,
    required this.rawMessage,
    required this.ipqsScore,
  });

  @override
  State<ReportAuthorityCard> createState() => _ReportAuthorityCardState();
}

class _ReportAuthorityCardState extends State<ReportAuthorityCard> {
  final _service = AuthorityReportService();
  bool _loading = false;
  ReportStatus? _lastStatus;

  Future<void> _submit() async {
    setState(() => _loading = true);
    final result = await _service.submitToAuthorities(
      rawPhone: widget.rawPhone,
      rawMessage: widget.rawMessage,
      ipqsScore: widget.ipqsScore,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _lastStatus = result.status;
    });
    _showFeedback(result);
  }

  void _showFeedback(ReportResult result) {
    final (msg, color) = switch (result.status) {
      ReportStatus.sent     => ('Denúncia enviada! Obrigado por ajudar a proteger outras pessoas.', AntiGolpeConstants.colorSafe),
      ReportStatus.duplicate => (result.message ?? 'Essa denúncia já foi registrada hoje.', Colors.orange),
      ReportStatus.authError => (result.message ?? 'Você precisa estar conectado para denunciar.', AntiGolpeConstants.colorRisk),
      ReportStatus.networkError => (result.message ?? 'Não conseguimos enviar. Verifique sua conexão.', AntiGolpeConstants.colorRisk),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alreadySent = _lastStatus == ReportStatus.sent ||
        _lastStatus == ReportStatus.duplicate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AntiGolpeConstants.colorSafe.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AntiGolpeConstants.colorSafe.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.gavel_rounded,
            color: AntiGolpeConstants.colorSafe,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AntiGolpeConstants.keyReportTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  AntiGolpeConstants.keyReportSubtitle,
                  style: TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          alreadySent
              ? const Icon(Icons.check_circle,
                  color: AntiGolpeConstants.colorSafe, size: 24)
              : _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: _submit,
                      style: TextButton.styleFrom(
                        backgroundColor: AntiGolpeConstants.colorSafe,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'DENUNCIAR',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
        ],
      ),
    );
  }
}
