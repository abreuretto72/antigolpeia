import 'package:supabase_flutter/supabase_flutter.dart';

/// Verifica SIM Swap via Edge Function Supabase.
/// As credenciais Twilio ficam exclusivamente no servidor — nunca no cliente.
class TwilioService {
  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>> checkSimSwap(String phone) async {
    try {
      final response = await _client.functions.invoke(
        'check-sim-swap',
        body: {'phone': phone},
      );

      if (response.status == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': data['success'] ?? false,
          'isSwapped': data['isSwapped'] ?? false,
          'last_swap': data['last_swap'],
          'error': data['error'],
        };
      }

      return {
        'success': false,
        'error': 'Status ${response.status}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
