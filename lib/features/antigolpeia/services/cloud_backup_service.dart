import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/whitelist_item.dart';
import '../data/models/blacklist_item.dart';

class BackupResult {
  final bool success;
  final String? error;
  final DateTime? syncedAt;

  const BackupResult({required this.success, this.error, this.syncedAt});
}

/// Backup criptografado das Whitelist e Blacklist via Supabase RLS.
/// O dado do usuário nunca é visível por outros — auth.uid() = id na política.
class CloudBackupService {
  static const String _table = 'backups';

  final _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  // ---------------------------------------------------------------------------
  // Backup — upload
  // ---------------------------------------------------------------------------

  Future<BackupResult> runBackup() async {
    final uid = _userId;
    if (uid == null) {
      return const BackupResult(success: false, error: 'antigolpeia_auth_error');
    }

    final whitelist = Hive.box<WhitelistItem>('antigolpeia_whitelist')
        .values
        .map((e) => {'num': e.phoneNumber, 'name': e.name})
        .toList();

    final blacklist = Hive.box<BlacklistItem>('antigolpeia_blacklist')
        .values
        .map((e) => {'num': e.phoneNumber, 'reason': e.reason})
        .toList();

    try {
      await _client.from(_table).upsert({
        'id': uid,
        'whitelist': whitelist,
        'blacklist': blacklist,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('[Backup] Upload concluído. W:${whitelist.length} B:${blacklist.length}');
      return BackupResult(success: true, syncedAt: DateTime.now());
    } catch (e) {
      debugPrint('[Backup] Erro no upload: $e');
      return BackupResult(success: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Restauração — download
  // ---------------------------------------------------------------------------

  Future<BackupResult> runRestore() async {
    final uid = _userId;
    if (uid == null) {
      return const BackupResult(success: false, error: 'antigolpeia_auth_error');
    }

    try {
      final row = await _client
          .from(_table)
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (row == null) {
        return const BackupResult(success: false, error: 'antigolpeia_backup_not_found');
      }

      final wBox = Hive.box<WhitelistItem>('antigolpeia_whitelist');
      final bBox = Hive.box<BlacklistItem>('antigolpeia_blacklist');

      await wBox.clear();
      for (final item in (row['whitelist'] as List)) {
        await wBox.add(WhitelistItem(
          phoneNumber: item['num'] as String,
          name: item['name'] as String,
          addedAt: DateTime.now(),
        ));
      }

      await bBox.clear();
      for (final item in (row['blacklist'] as List)) {
        await bBox.add(BlacklistItem(
          phoneNumber: item['num'] as String,
          reason: item['reason'] as String,
          blockedAt: DateTime.now(),
        ));
      }

      debugPrint('[Backup] Restauração concluída. W:${wBox.length} B:${bBox.length}');
      return BackupResult(success: true, syncedAt: DateTime.now());
    } catch (e) {
      debugPrint('[Backup] Erro na restauração: $e');
      return BackupResult(success: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------------

  Future<DateTime?> lastSyncAt() async {
    final uid = _userId;
    if (uid == null) return null;
    try {
      final row = await _client
          .from(_table)
          .select('updated_at')
          .eq('id', uid)
          .maybeSingle();
      if (row == null) return null;
      return DateTime.tryParse(row['updated_at'] as String);
    } catch (_) {
      return null;
    }
  }
}
