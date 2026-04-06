import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/antigolpeia/services/ai_dataset_service.dart';
import '../features/antigolpeia/services/ia_inference_service.dart';

class ApiService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> analyzeContent(
    String type,
    String content, {
    bool skipSave = false,
  }) async {
    // ── Camada 1: inferência local ──────────────────────────────────────────
    // Consulta o cache de padrões comunitários antes de qualquer chamada de API.
    // Grátis, offline, resposta instantânea no SM-A256E.
    try {
      final inference = IaInferenceService().checkLocalPatterns(content);
      if (inference.isFraudPattern && inference.matchedPattern != null) {
        final pattern = inference.matchedPattern!;
        final confidence = (inference.similarity * 100).round();

        debugPrint(
          '[ApiService] Cache hit — similaridade $confidence% '
          'com padrão ${pattern.patternHash.substring(0, 8)}',
        );

        return {
          'risco': pattern.fraudScore,
          'classificacao': pattern.classification,
          'tipo_golpe': 'Padrão de golpe conhecido',
          'explicacao':
              'Esta mensagem é similar a um golpe já confirmado pela '
              'comunidade AntiGolpeia ($confidence% de similaridade). '
              'Outros usuários já reportaram este tipo de fraude.',
          'sinais_alerta': [
            'Padrão comunitário confirmado ($confidence% similaridade)',
          ],
          'acao_imediata':
              'Não responda e não clique em links. '
              'Este golpe já foi reportado por outros usuários.',
          'nivel_urgencia': pattern.fraudScore >= 80
              ? 'extremo'
              : pattern.fraudScore >= 60
                  ? 'alto'
                  : 'medio',
          'confianca': confidence,
          'golpe_conhecido': true,
          '_source': 'local_inference',
        };
      }
    } catch (e) {
      // Cache inacessível (ex: primeiro boot) — continua para a API.
      debugPrint('[ApiService] Inferência local ignorada: $e');
    }

    // ── Camada 2: Claude Haiku via Edge Function ────────────────────────────
    try {
      final response = await _supabase.functions.invoke(
        'analyze',
        body: {'input_type': type, 'content': content, 'skip_save': skipSave},
      );

      if (response.status == 200 && response.data is Map) {
        final result = Map<String, dynamic>.from(
            response.data as Map<String, dynamic>);

        // ── Camada 3: alimenta o dataset comunitário ────────────────────────
        // Padrões com risco >= 70 confirmados pela IA vão para o Supabase
        // e para o cache local — ficam disponíveis para todos os usuários.
        final risk = (result['risco'] as num? ?? 0).toInt();
        if (!skipSave && risk >= 70) {
          AiDatasetService()
              .submitToAiBase(FraudReport(
                content: content,
                inputType: type,
                ipqsFraudScore: risk,
                simSwapStatus: false,
                isVoip: false,
                userConfirmation: 1,
              ))
              .ignore(); // fire-and-forget — não bloqueia a resposta
        }

        return result;
      } else if (response.status == 403 &&
          response.data?['error'] == 'PAYWALL_TRIGGER') {
        throw Exception('PAYWALL_TRIGGER');
      } else {
        debugPrint('[ApiService] Falha ao analisar: status=${response.status}');
        throw Exception(
            'Não foi possível analisar. Verifique sua conexão e tente novamente.');
      }
    } on FunctionException catch (e) {
      if (e.details != null && (e.details as Map)['error'] == 'PAYWALL_TRIGGER') {
        throw Exception('PAYWALL_TRIGGER');
      }
      debugPrint('[ApiService] FunctionException: ${e.status}');
      rethrow;
    } catch (e) {
      debugPrint('[ApiService] Erro: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final response = await _supabase
          .from('analyses')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[ApiService] getHistory erro: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAlerts() async {
    try {
      final response = await _supabase
          .from('alerts')
          .select()
          .order('created_at', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[ApiService] getAlerts erro: $e');
      return [];
    }
  }
}
