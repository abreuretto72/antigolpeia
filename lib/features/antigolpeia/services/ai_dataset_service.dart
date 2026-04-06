import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/similarity_engine.dart';
import '../data/models/fraud_pattern_model.dart';

/// Resultado tipado da submissão à base comunitária.
class SubmitResult {
  final bool success;
  final bool wasAlreadyKnown;
  final String? error;

  const SubmitResult({
    required this.success,
    required this.wasAlreadyKnown,
    this.error,
  });
}

/// Payload de treino para a IA comunitária.
class FraudReport {
  final String content;
  final String inputType;
  final int ipqsFraudScore;
  final bool simSwapStatus;
  final bool isVoip;
  final int userConfirmation; // 0 = seguro, 1 = golpe

  const FraudReport({
    required this.content,
    required this.inputType,
    required this.ipqsFraudScore,
    required this.simSwapStatus,
    required this.isVoip,
    required this.userConfirmation,
  });
}

class AiDatasetService {
  static const String _boxName = 'fraud_patterns';
  static const String _supabaseTable = 'community_fraud_patterns';

  // Thresholds
  static const double _similarityThreshold = 0.80;
  static const int _fuzzyCompareMaxChars = 200;

  final _supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // LGPD — Higienização de texto
  // ---------------------------------------------------------------------------

  static final _phoneRegex = RegExp(
    r'(\+?55\s?)?(\(?\d{2}\)?\s?)?(\d{4,5}[-\s]?\d{4})',
  );
  static final _nameRegex = RegExp(
    r'\b[A-ZÁÉÍÓÚÀÂÃÊÔÕÇ][a-záéíóúàâãêôõç]+(?: [A-ZÁÉÍÓÚÀÂÃÊÔÕÇ][a-záéíóúàâãêôõç]+)+\b',
  );
  static final _cpfRegex = RegExp(r'\d{3}\.?\d{3}\.?\d{3}-?\d{2}');
  static final _emailRegex = RegExp(r'[\w.+-]+@[\w-]+\.[a-z]{2,}');

  /// Remove dados sensíveis antes de qualquer upload (LGPD Art. 46).
  String sanitize(String raw) {
    return raw
        .replaceAll(_phoneRegex, '[PHONE_MASK]')
        .replaceAll(_nameRegex, '[NAME_MASK]')
        .replaceAll(_cpfRegex, '[CPF_MASK]')
        .replaceAll(_emailRegex, '[EMAIL_MASK]');
  }

  String _sha256(String text) =>
      sha256.convert(utf8.encode(text)).toString();

  // ---------------------------------------------------------------------------
  // Cache local (Hive)
  // ---------------------------------------------------------------------------

  Box<FraudPatternModel> get _box =>
      Hive.box<FraudPatternModel>(_boxName);

  /// Busca padrão similar no cache antes de consumir APIs externas.
  /// Delega cálculo ao [SimilarityEngine] — fonte única de verdade.
  FraudPatternModel? findSimilarInCache(String sanitizedContent) {
    final probe = SimilarityEngine.normalize(
      sanitizedContent.length > _fuzzyCompareMaxChars
          ? sanitizedContent.substring(0, _fuzzyCompareMaxChars)
          : sanitizedContent,
    );

    FraudPatternModel? best;
    double bestScore = 0;

    for (final pattern in _box.values) {
      final candidate = pattern.sanitizedContent.length > _fuzzyCompareMaxChars
          ? pattern.sanitizedContent.substring(0, _fuzzyCompareMaxChars)
          : pattern.sanitizedContent;

      final score = SimilarityEngine.compare(probe, candidate);
      if (score > bestScore) {
        bestScore = score;
        best = pattern;
      }
    }

    return bestScore >= _similarityThreshold ? best : null;
  }

  /// Salva padrão confirmado no cache local.
  Future<void> cachePattern(FraudPatternModel pattern) async {
    await _box.put(pattern.patternHash, pattern);
  }

  /// Reconstrói o cache local a partir da base remota (Protocolo Master).
  Future<void> rebuildCacheFromRemote() async {
    try {
      final rows = await _supabase
          .from(_supabaseTable)
          .select()
          .eq('user_confirmation', 1)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(500);

      await _box.clear();

      for (final row in rows) {
        final model = FraudPatternModel(
          patternHash: row['pattern_hash'] as String,
          sanitizedContent: row['content_pattern'] as String,
          fraudScore: (row['fraud_score_aggregate'] as num).toInt(),
          classification: row['classification'] as String? ?? 'golpe',
          detectedAt: DateTime.parse(row['created_at'] as String),
          userConfirmed: true,
        );
        await _box.put(model.patternHash, model);
      }
      debugPrint('[AiDataset] Cache reconstruído: ${_box.length} padrões.');
    } catch (e) {
      debugPrint('[AiDataset] Erro ao reconstruir cache: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Submissão à base comunitária
  // ---------------------------------------------------------------------------

  /// Higieniza, verifica cache e envia o padrão à base de IA comunitária.
  Future<SubmitResult> submitToAiBase(FraudReport report) async {
    final sanitizedContent = sanitize(report.content);
    final patternHash = _sha256(sanitizedContent);

    // 1. Verificar cache local antes de qualquer requisição
    final cached = findSimilarInCache(sanitizedContent);
    if (cached != null) {
      debugPrint('[AiDataset] Padrão similar encontrado no cache: ${cached.patternHash}');
      return const SubmitResult(success: true, wasAlreadyKnown: true);
    }

    // 2. Enviar para Supabase via RPC (agrega contadores corretamente)
    try {
      await _supabase.rpc('upsert_fraud_pattern', params: {
        'p_pattern_hash':      patternHash,
        'p_content_pattern':   sanitizedContent,
        'p_input_type':        report.inputType,
        'p_ipqs_fraud_score':  report.ipqsFraudScore,
        'p_sim_swap_status':   report.simSwapStatus,
        'p_is_voip':           report.isVoip,
        'p_user_confirmation': report.userConfirmation,
      });

      // 3. Salvar no cache local se confirmado como golpe
      if (report.userConfirmation == 1) {
        await cachePattern(FraudPatternModel(
          patternHash: patternHash,
          sanitizedContent: sanitizedContent,
          fraudScore: report.ipqsFraudScore,
          classification: 'golpe',
          detectedAt: DateTime.now(),
          userConfirmed: true,
        ));
      }

      return const SubmitResult(success: true, wasAlreadyKnown: false);
    } catch (e) {
      debugPrint('[AiDataset] Erro no submit: $e');
      return SubmitResult(success: false, wasAlreadyKnown: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Inicialização
  // ---------------------------------------------------------------------------

  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<FraudPatternModel>(_boxName);
    }
    // Se box vazio, reconstruir a partir do remoto (Protocolo Master)
    final box = Hive.box<FraudPatternModel>(_boxName);
    if (box.isEmpty) {
      await AiDatasetService().rebuildCacheFromRemote();
    }
  }
}
