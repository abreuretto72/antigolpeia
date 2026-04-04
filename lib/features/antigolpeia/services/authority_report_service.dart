import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/authority_report_model.dart';
import 'ai_dataset_service.dart';

enum ReportStatus { sent, duplicate, authError, networkError }

class ReportResult {
  final ReportStatus status;
  final String? message;
  const ReportResult(this.status, [this.message]);
}

class AuthorityReportService {
  static const _boxName = 'authority_reports';
  final _client = Supabase.instance.client;
  final _dataset = AiDatasetService();

  static Future<void> initialize() async {
    await Hive.openBox<AuthorityReportModel>(_boxName);
  }

  Future<ReportResult> submitToAuthorities({
    required String rawPhone,
    required String rawMessage,
    required int ipqsScore,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      return const ReportResult(ReportStatus.authError, 'Sessão expirada.');
    }

    final cleaned = _dataset.sanitize(rawMessage);
    final phone = _sanitizePhone(rawPhone);
    final victimId = session.user.id;
    final now = DateTime.now();

    // Dedup: same offender + same victim in last 24h
    final box = Hive.box<AuthorityReportModel>(_boxName);
    final cutoff = now.subtract(const Duration(hours: 24)).millisecondsSinceEpoch;
    final isDuplicate = box.values.any((r) =>
        r.offenderPhone == phone &&
        r.victimId == victimId &&
        r.timestampMs >= cutoff);

    if (isDuplicate) {
      return const ReportResult(
          ReportStatus.duplicate, 'Denúncia idêntica enviada nas últimas 24h.');
    }

    try {
      await _client.from('authority_reports').insert({
        'offender_phone': phone,
        'cleaned_message': cleaned,
        'ipqs_score': ipqsScore,
        'victim_id': victimId,
        'created_at': now.toIso8601String(),
      });

      // Cache locally for dedup
      await box.add(AuthorityReportModel(
        offenderPhone: phone,
        cleanedMessage: cleaned,
        ipqsScore: ipqsScore,
        timestampMs: now.millisecondsSinceEpoch,
        victimId: victimId,
      ));

      return const ReportResult(ReportStatus.sent);
    } on AuthException {
      return const ReportResult(ReportStatus.authError, 'Sessão expirada.');
    } catch (e) {
      return ReportResult(ReportStatus.networkError, e.toString());
    }
  }

  String _sanitizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^\d+]'), '');
}
