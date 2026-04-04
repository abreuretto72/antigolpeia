import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/blacklist_item.dart';
import 'ai_dataset_service.dart';

class BlockEngineService {
  static const String _boxName = 'antigolpeia_blacklist';

  Box<BlacklistItem> get _box => Hive.box<BlacklistItem>(_boxName);

  // ---------------------------------------------------------------------------
  // Verificação
  // ---------------------------------------------------------------------------

  bool isBlacklisted(String phone) {
    final normalized = _normalize(phone);
    return _box.values.any((item) => _normalize(item.phoneNumber) == normalized);
  }

  // ---------------------------------------------------------------------------
  // Bloqueio
  // ---------------------------------------------------------------------------

  /// Registra o número localmente e notifica o AiDatasetService para
  /// marcar o padrão como fraude confirmada na base comunitária.
  Future<void> executeBlock(String phone, String reason, String content) async {
    final normalized = _normalize(phone);
    if (isBlacklisted(normalized)) return;

    await _box.add(BlacklistItem(
      phoneNumber: normalized,
      reason: reason,
      blockedAt: DateTime.now(),
    ));

    // Contribui com o padrão como fraude confirmada (label 1)
    try {
      await AiDatasetService().submitToAiBase(FraudReport(
        content: content,
        inputType: 'block_action',
        ipqsFraudScore: 100,
        simSwapStatus: false,
        isVoip: false,
        userConfirmation: 1,
      ));
    } catch (e) {
      debugPrint('[BlockEngine] Erro ao submeter padrão: $e');
    }

    debugPrint('[BlockEngine] Número bloqueado: $normalized — $reason');
  }

  Future<void> unblock(BlacklistItem item) => item.delete();

  List<BlacklistItem> getAll() => _box.values.toList();

  // ---------------------------------------------------------------------------
  // Inicialização
  // ---------------------------------------------------------------------------

  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<BlacklistItem>(_boxName);
    }
  }

  String _normalize(String phone) =>
      phone.replaceAll(RegExp(r'[\s\-().+]'), '');
}
