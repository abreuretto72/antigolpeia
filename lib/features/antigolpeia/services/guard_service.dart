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

  /// Verifica se [phone] é um contato confiável.
  /// Normaliza o número antes de comparar (remove espaços, traços, parênteses).
  GuardResult check(String phone) {
    final normalized = _normalize(phone);
    for (final item in _box.values) {
      if (_normalize(item.phoneNumber) == normalized) {
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

  String _normalize(String phone) =>
      phone.replaceAll(RegExp(r'[\s\-().+]'), '');
}
