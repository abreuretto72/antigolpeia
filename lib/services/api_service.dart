import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> analyzeContent(String type, String content, {bool skipSave = false}) async {
    debugPrint('[API LOG] =======================================');
    debugPrint('[API LOG] Iniciando analyzeContent (Private: $skipSave)');
    debugPrint('[API LOG] Type: $type, Content length: ${content.length}');
    
    try {
      final response = await _supabase.functions.invoke(
        'analyze',
        body: {'input_type': type, 'content': content, 'skip_save': skipSave},
      );
      
      debugPrint('[API LOG] Status: ${response.status}');
      debugPrint('[API LOG] Data: ${response.data}');

      if (response.status == 200 && response.data != null) {
        debugPrint('[API LOG] Sucesso! Retornando resultado.');
        return response.data as Map<String, dynamic>;
      } else if (response.status == 403 && response.data?['error'] == 'PAYWALL_TRIGGER') {
        debugPrint('[API LOG] PAYWALL_TRIGGER interceptado!');
        throw Exception('PAYWALL_TRIGGER');
      } else {
        final errMsg = response.data?['error'] ?? 'Erro desconhecido (status ${response.status})';
        debugPrint('[API LOG] Erro da function: $errMsg');
        throw Exception(errMsg);
      }
    } on FunctionException catch (e) {
      debugPrint('[API LOG] FunctionException: ${e.status} / details: ${e.details} / reason: ${e.reasonPhrase}');
      if (e.details != null && (e.details as Map)['error'] == 'PAYWALL_TRIGGER') {
        throw Exception('PAYWALL_TRIGGER');
      }
      rethrow;
    } catch (e) {
      debugPrint('[API LOG] Erro generico: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    debugPrint('[API LOG] Buscando historico...');
    final response = await _supabase
        .from('analyses')
        .select()
        .order('created_at', ascending: false);
    debugPrint('[API LOG] Historico: ${response.length} registros.');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAlerts() async {
    debugPrint('[API LOG] Buscando alertas...');
    final response = await _supabase
        .from('alerts')
        .select()
        .order('created_at', ascending: false)
        .limit(10);
    debugPrint('[API LOG] Alertas: ${response.length} registros.');
    return List<Map<String, dynamic>>.from(response);
  }
}
