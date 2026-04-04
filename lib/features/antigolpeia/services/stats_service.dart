import 'package:supabase_flutter/supabase_flutter.dart';

/// Agregado de estatísticas derivado da tabela `analyses` no Supabase.
class DashboardStats {
  final int totalBlocked;
  final int totalSafe;
  final int totalSuspicious;
  final int smsFraud;
  final int whatsappFraud;
  final int emailFraud;
  final int efficiencyPct;

  const DashboardStats({
    required this.totalBlocked,
    required this.totalSafe,
    required this.totalSuspicious,
    required this.smsFraud,
    required this.whatsappFraud,
    required this.emailFraud,
    required this.efficiencyPct,
  });

  int get total => totalBlocked + totalSafe + totalSuspicious;

  static const DashboardStats empty = DashboardStats(
    totalBlocked: 0,
    totalSafe: 0,
    totalSuspicious: 0,
    smsFraud: 0,
    whatsappFraud: 0,
    emailFraud: 0,
    efficiencyPct: 0,
  );
}

class StatsService {
  final _supabase = Supabase.instance.client;

  Future<DashboardStats> getDashboardStats() async {
    final rows = await _supabase
        .from('analyses')
        .select('classification, input_type');

    if (rows.isEmpty) return DashboardStats.empty;

    int blocked = 0, safe = 0, suspicious = 0;
    int sms = 0, whatsapp = 0, email = 0;

    for (final row in rows) {
      final classification = row['classification']?.toString() ?? '';
      final type = row['input_type']?.toString() ?? '';

      switch (classification.toLowerCase()) {
        case 'golpe':
          blocked++;
          switch (type.toLowerCase()) {
            case 'sms':
              sms++;
            case 'whatsapp':
              whatsapp++;
            case 'email':
              email++;
          }
        case 'suspeito':
          suspicious++;
        default:
          safe++;
      }
    }

    final total = blocked + safe + suspicious;
    final efficiency = total == 0 ? 0 : ((safe + suspicious) / total * 100).round();

    return DashboardStats(
      totalBlocked: blocked,
      totalSafe: safe,
      totalSuspicious: suspicious,
      smsFraud: sms,
      whatsappFraud: whatsapp,
      emailFraud: email,
      efficiencyPct: efficiency,
    );
  }
}
