import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> analyzeContent(String type, String content, {bool skipSave = false}) async {
    try {
      final response = await _supabase.functions.invoke(
        'analyze',
        body: {'input_type': type, 'content': content, 'skip_save': skipSave},
      );

      if (response.status == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else if (response.status == 403 && response.data?['error'] == 'PAYWALL_TRIGGER') {
        throw Exception('PAYWALL_TRIGGER');
      } else {
        debugPrint('[ApiService] Falha ao analisar: status=${response.status}');
        throw Exception('Não foi possível analisar. Verifique sua conexão e tente novamente.');
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
    final response = await _supabase
        .from('analyses')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAlerts() async {
    final response = await _supabase
        .from('alerts')
        .select()
        .order('created_at', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }
}
