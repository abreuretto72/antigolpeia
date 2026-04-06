import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/whitelist_item.dart';

/// Resultado tipado do pre-check da Whitelist.
class GuardResult {
  final bool isTrusted;
  final WhitelistItem? matchedContact;

  const GuardResult({required this.isTrusted, this.matchedContact});

  static const GuardResult unknown = GuardResult(isTrusted: false);
}

/// Filtro prioritário — roda ANTES de qualquer API ou fuzzy matching.
/// Se o número estiver na Whitelist, retorna Verde instantaneamente.
class GuardService {
  static const String _boxName = 'antigolpeia_whitelist';

  Box<WhitelistItem> get _box => Hive.box<WhitelistItem>(_boxName);

  // ---------------------------------------------------------------------------
  // Verificação
  // ---------------------------------------------------------------------------

  /// Verifica se [phone] é um contato confiável (por número).
  /// Normaliza antes de comparar — match cross-platform Android/iOS.
  GuardResult check(String phone) {
    final normalized = _normalize(phone);
    if (normalized.isEmpty) return GuardResult.unknown;
    for (final item in _box.values) {
      if (_normalize(item.phoneNumber) == normalized) {
        return GuardResult(isTrusted: true, matchedContact: item);
      }
    }
    return GuardResult.unknown;
  }

  /// Verifica se [name] corresponde a um contato confiável (por nome).
  /// Usado pelo monitor de WhatsApp/Gmail, que recebe o nome do remetente
  /// pela notificação — não o número de telefone.
  /// Faz match exato case-insensitive.
  GuardResult checkByName(String name) {
    final normalized = name.toLowerCase().trim();
    if (normalized.isEmpty) return GuardResult.unknown;
    for (final item in _box.values) {
      if (item.name.toLowerCase().trim() == normalized) {
        return GuardResult(isTrusted: true, matchedContact: item);
      }
    }
    return GuardResult.unknown;
  }

  // ---------------------------------------------------------------------------
  // Gestão
  // ---------------------------------------------------------------------------

  Future<void> add(String phone, String name) async {
    final normalized = _normalize(phone);
    // Evitar duplicatas
    if (check(normalized).isTrusted) return;

    await _box.add(WhitelistItem(
      phoneNumber: normalized,
      name: name,
      addedAt: DateTime.now(),
    ));
  }

  Future<void> remove(WhitelistItem item) => item.delete();

  List<WhitelistItem> getAll() => _box.values.toList();

  // ---------------------------------------------------------------------------
  // Inicialização
  // ---------------------------------------------------------------------------

  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<WhitelistItem>(_boxName);
    }
    debugPrint('[GuardService] Whitelist carregada: ${Hive.box<WhitelistItem>(_boxName).length} contatos.');
  }

  // ---------------------------------------------------------------------------
  // Util
  // ---------------------------------------------------------------------------

  /// Normaliza para apenas dígitos e remove o DDI +55 quando presente.
  ///
  /// Android retorna `(11) 9xxxx-xxxx` → `119xxxxxxxx`
  /// iOS retorna `+55 11 9xxxx-xxxx` → `119xxxxxxxx`
  /// Ambos produzem o mesmo resultado, garantindo match cross-platform.
  String _normalize(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    // Número brasileiro com DDI: 55 + DDD (2) + número (8 ou 9) = 12 ou 13 dígitos
    if ((digits.length == 12 || digits.length == 13) &&
        digits.startsWith('55')) {
      return digits.substring(2);
    }
    return digits;
  }
}
