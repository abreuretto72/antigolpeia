import 'package:hive_flutter/hive_flutter.dart';
import '../core/utils/similarity_engine.dart';
import '../data/models/fraud_pattern_model.dart';

/// Resultado tipado do pre-check local.
class InferenceResult {
  final bool isFraudPattern;
  final double similarity;
  final FraudPatternModel? matchedPattern;

  const InferenceResult({
    required this.isFraudPattern,
    required this.similarity,
    this.matchedPattern,
  });

  static const InferenceResult safe = InferenceResult(
    isFraudPattern: false,
    similarity: 0.0,
  );
}

/// Motor de inferência local — roda ANTES de qualquer chamada a APIs externas.
/// Consulta o cache Hive por padrões similares para economizar créditos.
class IaInferenceService {
  static const String _boxName = 'fraud_patterns';

  /// Limiar de similaridade para considerar golpe confirmado.
  static const double _threshold = 0.85;

  /// Máximo de caracteres a comparar (desempenho no SM A256E).
  static const int _maxChars = 200;

  Box<FraudPatternModel> get _box => Hive.box<FraudPatternModel>(_boxName);

  /// Verifica o cache local por similaridade antes de consumir APIs externas.
  ///
  /// Retorna [InferenceResult.safe] se nenhum padrão similar for encontrado.
  InferenceResult checkLocalPatterns(String incomingText) {
    final probe = SimilarityEngine.normalize(
      incomingText.length > _maxChars
          ? incomingText.substring(0, _maxChars)
          : incomingText,
    );

    FraudPatternModel? best;
    double bestScore = 0.0;

    for (final pattern in _box.values) {
      if (!pattern.userConfirmed) continue;

      final candidate = pattern.sanitizedContent.length > _maxChars
          ? pattern.sanitizedContent.substring(0, _maxChars)
          : pattern.sanitizedContent;

      final score = SimilarityEngine.compare(probe, candidate);
      if (score > bestScore) {
        bestScore = score;
        best = pattern;
      }
    }

    return bestScore >= _threshold
        ? InferenceResult(
            isFraudPattern: true,
            similarity: bestScore,
            matchedPattern: best,
          )
        : InferenceResult(isFraudPattern: false, similarity: bestScore);
  }
}
