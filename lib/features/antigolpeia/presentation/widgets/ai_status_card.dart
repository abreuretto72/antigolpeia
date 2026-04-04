import 'package:flutter/material.dart';
import '../../../../features/antigolpe/constants/antigolpe_constants.dart';
import '../../services/ai_dataset_service.dart';

enum AiCardState { scanning, confirmed, idle }

/// Card de status da IA AntiGolpeia.
/// Ergonomia SM A256E: usa SingleChildScrollView para nunca invadir o rodapé.
class AiStatusCard extends StatefulWidget {
  final String content;
  final String inputType;
  final int fraudScore;
  final bool simSwapStatus;
  final bool isVoip;
  final VoidCallback? onContribute;

  const AiStatusCard({
    super.key,
    required this.content,
    required this.inputType,
    required this.fraudScore,
    required this.simSwapStatus,
    required this.isVoip,
    this.onContribute,
  });

  @override
  State<AiStatusCard> createState() => _AiStatusCardState();
}

class _AiStatusCardState extends State<AiStatusCard> {
  AiCardState _state = AiCardState.idle;
  bool _isAlreadyKnown = false;
  bool _contributed = false;
  String? _errorMessage;

  final _service = AiDatasetService();

  // Strings de L10n via constantes centralizadas (zero hardcoded inline)
  static const _keyScanning = AntiGolpeConstants.keyIaScanning;
  static const _keyConfirmed = AntiGolpeConstants.keyIaConfirmed;
  static const _keyContribute = AntiGolpeConstants.keyIaContribute;

  Future<void> _contribute(int label) async {
    setState(() {
      _state = AiCardState.scanning;
      _errorMessage = null;
    });

    final result = await _service.submitToAiBase(FraudReport(
      content: widget.content,
      inputType: widget.inputType,
      ipqsFraudScore: widget.fraudScore,
      simSwapStatus: widget.simSwapStatus,
      isVoip: widget.isVoip,
      userConfirmation: label,
    ));

    if (!mounted) return;

    setState(() {
      if (result.success) {
        _state = AiCardState.confirmed;
        _isAlreadyKnown = result.wasAlreadyKnown;
        _contributed = true;
      } else {
        _state = AiCardState.idle;
        _errorMessage = result.error;
      }
    });

    widget.onContribute?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor().withValues(alpha: 0.12),
        border: Border.all(color: _cardColor(), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildBody(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AntiGolpeConstants.colorRisk, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _cardColor() {
    return switch (_state) {
      AiCardState.scanning => AntiGolpeConstants.colorSafe,
      AiCardState.confirmed => _isAlreadyKnown
          ? AntiGolpeConstants.colorRisk
          : AntiGolpeConstants.colorSafe,
      AiCardState.idle => AntiGolpeConstants.colorAudit,
    };
  }

  Widget _buildHeader() {
    final (icon, label) = switch (_state) {
      AiCardState.scanning => (Icons.radar, _keyScanning),
      AiCardState.confirmed => _isAlreadyKnown
          ? (Icons.warning_amber_rounded, _keyConfirmed)
          : (Icons.check_circle_outline, _keyConfirmed),
      AiCardState.idle => (Icons.people_alt_outlined, _keyContribute),
    };

    return Row(
      children: [
        Icon(icon, color: _cardColor(), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: _cardColor(),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        if (_state == AiCardState.scanning)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AntiGolpeConstants.colorSafe,
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_state == AiCardState.scanning) {
      return const SizedBox.shrink();
    }

    if (_contributed) {
      return Text(
        _isAlreadyKnown
            ? 'Padrão já registrado na base comunitária. Obrigado!'
            : 'Contribuição enviada. A IA ficou mais forte!',
        style: const TextStyle(fontSize: 14, height: 1.4),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Este conteúdo é um golpe?',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'É GOLPE',
                color: AntiGolpeConstants.colorRisk,
                onPressed: () => _contribute(1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: 'É SEGURO',
                color: AntiGolpeConstants.colorSafe,
                onPressed: () => _contribute(0),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 10),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      child: Text(label),
    );
  }
}
